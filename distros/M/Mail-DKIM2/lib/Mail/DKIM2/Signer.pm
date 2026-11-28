package Mail::DKIM2::Signer;
use strict;
use warnings;

our $VERSION = '0.36';

use base 'Mail::DKIM2::HeaderParser';
use MIME::Base64 qw(encode_base64);
use Carp;
use Scalar::Util ();

use Mail::DKIM2::Address ();
use Mail::DKIM2::Common qw(chain_length_error);
use Mail::DKIM2::Canon qw(build_signing_input);
use Mail::DKIM2::Key qw(load_private_key signature_algorithm signature_algorithm_for_key);
use Mail::DKIM2::Chain;
use Mail::DKIM2::Signature;
use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::HeaderPlan;

sub known_options {
    return qw(Domain Selector KeyFile Key Algorithm MailFrom RcptTo
              Nonce Flags Exploded Timestamp NextDomain ParentFromCallback
              PolicyCallback Resolver);
}

sub init {
    my $self = shift;
    $self->SUPER::init;
    croak "Domain required" unless $self->{Domain};
    croak "Selector required" unless $self->{Selector};
    croak "KeyFile or Key required" unless $self->{KeyFile} || $self->{Key};

    if ($self->{KeyFile} && !$self->{Key}) {
        $self->{Key} = load_private_key($self->{KeyFile});
    }

    # The algorithm is the key's unless the caller names one; a name this
    # library does not implement, or one the key cannot sign with, is a
    # mistake in the call -- never a signature labelled as something it is
    # not, or an exception from inside CLOSE.
    $self->{Algorithm} ||= signature_algorithm_for_key($self->{Key}) || 'rsa-sha256';
    my $alg = signature_algorithm($self->{Algorithm})
        or croak "unsupported Algorithm $self->{Algorithm}";
    croak "Algorithm $self->{Algorithm} needs a $alg->{key_class} key"
        unless Scalar::Util::blessed($self->{Key}) && $self->{Key}->isa($alg->{key_class});
    $self->{_alg} = $alg;
    $self->{_chain} = Mail::DKIM2::Chain->new;
}

sub handle_header {
    my ($self, $field_name, $contents, $line) = @_;
    $self->{_chain}->add_field($field_name, $contents, $line);
}

# The message's Message-Instance and DKIM2-Signature fields, numbered
# (Mail::DKIM2::Chain). Complete once the header block has been read.
sub chain { return $_[0]->{_chain} }

sub finish_header {
    my $self = shift;

    my $chain  = $self->{_chain};
    my $next_i = ($chain->top_signature_number // 0) + 1;

    # A chain no verifier can number is a PERMERROR to all of them, and so
    # is one a signature would take past the limit: do not sign over it.
    # Whether the chain is otherwise worth extending -- its signatures, its
    # instances against the content -- is Mail::DKIM2::Gate's to decide.
    # A line that is not a field is in no header hash (HeaderParser).
    my $error = ($self->malformed_header ? 'malformed header field' : undef)
        // $chain->numbering_error
        // chain_length_error({ 'dkim2-signature' => $next_i });
    # A signature names the Message-Instance it covers in m=, and a verifier
    # rejects one that names none (tag=m missing), so a message with no
    # instance cannot be signed: compute one first (dkim2sign does).
    $error //= 'no Message-Instance field to sign over' unless $chain->instance_numbers;
    # -09 section 3.2: a Signer MUST use an RSA key of at least 1024 bits,
    # and every verifier calls a shorter one "too short".
    if (my $min = $self->{_alg}{min_bits}) {
        $error //= "signing key is shorter than $min bits"
            if $self->{Key}->size * 8 < $min;
    }
    # -09 sections 11 and 12.4: a hop that originates the message, or whose
    # instances changed From, signs with a d= the From is Authentic for.
    # -09 contract E3.4: d= may also be below the From domain when the
    # caller says this d= may sign for it (ParentFromCallback), or, as an
    # explicit opt-in, when that domain's Domain Policy Record allows it.
    # Without either the upward case is refused: no live DNS by default.
    if (!$error && $self->_from_must_match) {
        my $e = Mail::DKIM2::Address::from_pair_error($self->{Domain},
            sub { $self->_parent_policy(@_) },
            map { $_->[1] } grep { lc $_->[0] eq 'from' }
            @{ Mail::DKIM2::HeaderPlan::fields($self->{headers}) });
        $error = "From header field is not Authentic for d=$self->{Domain}" if $e;
    }
    if ($error) {
        # A protocol outcome, not a programming error: reported through
        # result/details like the Verifier's, so a streaming host is not
        # handed an exception from inside PRINT. The body is discarded.
        $self->{result}  = 'fail';
        $self->{details} = $error;
        $self->stop;
        return;
    }
    $self->{_mi_version} = $chain->top_instance;
    $self->{_timestamp}  = $self->{Timestamp} || time();
    $self->{_next_i} = $next_i;
    $self->{_signature} = $self->_new_signature($self->{RcptTo});
    # Section 12.8 signs the Message-Instance and DKIM2-Signature fields
    # alone, so the body is not kept.
    $self->{_body_sink} = sub {};
}

# The signature object for this hop with rt= set to $rcpt (an arrayref, or
# undef for none). -09 §12.3: when NextDomain is set this is an
# imaginary forwarding hop -- emit nd= and omit mf=/rt= (Signature->new
# enforces the exclusion).
#
# f= (-09 section 12.5): "exploded" MUST be set by a hop sending the message
# to more than one address and MUST NOT be set at i=1. So it is set when
# i > 1 and the caller asked for it (Exploded, or "exploded" among its
# Flags) or rt= holds more than one address, and dropped at i=1 whatever
# the caller said. Built afresh for each recipient set, since the flag
# depends on rt=.
sub _new_signature {
    my ($self, $rcpt) = @_;
    my $i = $self->{_next_i};
    my @rcpt = !defined $rcpt ? () : ref $rcpt eq 'ARRAY' ? @$rcpt : ($rcpt);
    my @flags = grep { $_ ne 'exploded' } @{ $self->{Flags} || [] };
    my $asked = $self->{Exploded}
             || grep { $_ eq 'exploded' } @{ $self->{Flags} || [] };
    push @flags, 'exploded'
        if $i > 1 && ($asked || (!$self->{NextDomain} && @rcpt > 1));
    return Mail::DKIM2::Signature->new(
        Sequence   => $i,
        Version    => $self->{_mi_version} || undef,
        Timestamp  => $self->{_timestamp},
        Domain     => $self->{Domain},
        ($self->{NextDomain}
            ? (NextDomain => $self->{NextDomain})
            : (MailFrom => $self->{MailFrom},
               (defined $rcpt ? (RcptTo => \@rcpt) : ()))),
        Signatures => [[ $self->{Selector}, $self->{Algorithm}, '' ]],
        ($self->{Nonce} ? (Nonce => $self->{Nonce}) : ()),
        (@flags ? (Flags => \@flags) : ()),
    );
}

# For from_pair_error: whether this d= may make a From in parent domain
# $dom Authentic ('open') or not ('strict').
sub _parent_policy {
    my ($self, $dom) = @_;
    if (my $cb = $self->{ParentFromCallback}) {
        return $cb->($dom, $self) ? 'open' : 'strict';
    }
    return 'strict' unless $self->{PolicyCallback} || $self->{Resolver};
    my ($p) = Mail::DKIM2::Key::policy_from_source($dom,
        $self->{PolicyCallback}, sub { $self->_resolver }, $self);
    return $p;
}

# fetch_domain_policy($domain): the TXT records at _domainkey.$domain
# through the Resolver, as Mail::DKIM2::Verifier's: for a PolicyCallback
# to fall back to.
sub fetch_domain_policy {
    my ($self, $dom) = @_;
    return Mail::DKIM2::Key::query_domain_policy($self->_resolver, $dom);
}

# The Resolver for the Domain Policy Record lookup: the caller's, else a
# default Net::DNS::Resolver, made only when a lookup is needed.
sub _resolver {
    my ($self) = @_;
    return $self->{Resolver} //= do {
        require Net::DNS::Resolver;
        Net::DNS::Resolver->new;
    };
}

# True when this signature answers for the From the message carries: there
# is no signature yet (this hop is i=1), or a Message-Instance no existing
# signature covers (m= above every signature's m=) has a header Recipe that
# names From -- this hop, or a list manager on its host, changed it. One
# that does not parse is left to the verifiers (and Mail::DKIM2::Gate),
# which refuse it: the Signer checks only what it needs to sign.
sub _from_must_match {
    my ($self) = @_;
    my $chain = $self->{_chain};
    return 1 unless $chain->signature_numbers;
    return $chain->instances_changing('From', $chain->covered_m) ? 1 : 0;
}

sub finish_body {
    my $self = shift;
    $self->_compute_signature;
    $self->{result} = 'signed';
}

# Re-sign the same message for a different envelope recipient, returning the
# folded DKIM2-Signature header to prepend for that recipient.
#
# This is the cheap half of signing. §12.8 signs solely the Message-Instance and
# DKIM2-Signature header fields, so everything expensive -- the body hash and
# the hash of every other header field -- lives in the Message-Instance and is
# identical for every recipient. Only rt= changes, so an additional recipient
# costs one signature over a few hundred bytes rather than another pass over
# the message.
#
# Feed the message through PRINT/CLOSE once, then call this per recipient:
#
#     $signer->PRINT($message); $signer->CLOSE;   # once
#     for my $rcpt (@rcpts) {
#         my $header = $signer->sign_for_recipient($rcpt);
#     }
#
# Takes one address or an arrayref of them. Not usable on a signature carrying
# nd=, which excludes rt= by §10.7; Signature::rcpt_to croaks in that case.
sub sign_for_recipient {
    my ($self, $rcpt) = @_;
    croak "sign_for_recipient: no signature: " . ($self->{details} // 'CLOSE has not run')
        unless $self->{_signature};
    croak "cannot set rt= on a signature carrying nd= (-09 §10.7)"
        if $self->{NextDomain};
    my @list = ref $rcpt eq 'ARRAY' ? @$rcpt : ($rcpt);
    croak "rcpt_to requires at least one recipient" unless @list;
    $self->{_signature} = $self->_new_signature(\@list);
    $self->_compute_signature;
    $self->{result} = 'signed';
    return $self->as_string;
}

sub _compute_signature {
    my $self = shift;

    my $signature = $self->{_signature};
    my $chain     = $self->{_chain};

    # Reset s= to the empty placeholder before building the signing input.
    # Without this a second call would sign an input containing the FIRST
    # call's signature bytes, which no verifier can reproduce -- the signing
    # input must always carry an empty s= value (§12.8).
    $signature->set_tag('s', join(':', $self->{Selector}, $self->{Algorithm}, ''));

    my $signing_input = build_signing_input(
        instances  => [ map { $chain->instance_field($_) } $chain->instance_numbers ],
        signatures => [ map { $chain->signature_field($_) } $chain->signature_numbers ],
        signing    => $signature->as_folded_string,    # as it will be sent
    );

    my $sig_raw = $self->{_alg}{sign}->($self->{Key}, $signing_input);
    my $signb64 = encode_base64($sig_raw, '');

    # Update the signature object with the actual signature
    # Format: sel:alg:sig
    $signature->set_tag('s', join(':', $self->{Selector}, $self->{Algorithm}, $signb64));
}

sub signature {
    my $self = shift;
    return $self->{_signature};
}

# No signature (before CLOSE, or a refused message) croaks: an empty string
# prepended to the message by a caller that did not check result() is a
# blank line that ends its header block.
sub as_string {
    my $self = shift;
    croak 'no signature: ' . ($self->{details} // 'the message has not been signed') . "\n"
        unless $self->{_signature};
    return $self->{_signature}->as_folded_string();
}

# undef until CLOSE; then 'signed', or 'fail' with the reason in details().
sub result {
    my $self = shift;
    return $self->{result};
}

sub details {
    my $self = shift;
    return $self->{details};
}

sub result_detail {
    my $self = shift;
    my $result = $self->result // return;
    return $self->{details} ? "$result ($self->{details})" : $result;
}

1;

__END__

=encoding utf8

=head1 NAME

Mail::DKIM2::Signer - Sign a message with a DKIM2-Signature header

=head1 SYNOPSIS

    use Mail::DKIM2::Signer;

    # A signature covers a Message-Instance, so a message that has none yet
    # gets one first (an originating hop: m=1).
    use Mail::DKIM2::MessageInstance;
    unless ($message =~ /^Message-Instance:/mi) {
        my $mi = Mail::DKIM2::MessageInstance->calculate($message);
        $message = $mi->as_header . "\r\n" . $message;
    }

    my $signer = Mail::DKIM2::Signer->new(
        Domain   => 'example.com',
        Selector => 'sel1',
        KeyFile  => '/etc/dkim2/sel1.pem',
        MailFrom => '<sender@example.com>',
        RcptTo   => ['<recipient@example.net>'],
    );

    # One shot ...
    $signer->load($message);
    # ... or streaming, with CRLF line endings
    $signer->PRINT($chunk) for @chunks;
    $signer->CLOSE;

    die $signer->result_detail unless $signer->result eq 'signed';
    my $header = $signer->as_string;    # "DKIM2-Signature: i=1; ..." (folded)

    # The same message to several envelope recipients: one pass, one cheap
    # signature per recipient.
    for my $rcpt (@rcpts) {
        my $header = $signer->sign_for_recipient($rcpt);
    }

=head1 DESCRIPTION

Adds a DKIM2-Signature header for this hop. The message must already carry
the Message-Instance header this hop wants to sign over (see
L<Mail::DKIM2::MessageInstance>; a message with none is a C<fail>); the
Signer reads the existing
Message-Instance and DKIM2-Signature headers, chooses the next C<i=>, builds
the signing input of -09 section 12.8, and signs it. It does not alter
the message: the caller prepends the header C<as_string> returns.

Nothing it signs is in the body (section 12.8), so the body is discarded as
it arrives, and a caller holding the message in a file may feed it the
header block alone.

Extends L<Mail::DKIM2::HeaderParser>, which provides C<PRINT>, C<CLOSE>,
C<load> and the tie interface.

This module implements draft-ietf-dkim-dkim2-spec-09; see L<Mail::DKIM2/STATUS>
for what that means for the wire format and the API, and
L<Mail::DKIM2/CONVENTIONS> for the option, input and error conventions every
module here follows.

=head1 CONSTRUCTOR

=head2 new(%options)

Required:

=over 4

=item Domain

The signing domain, the C<d=> tag.

=item Selector

The selector of the key, published at C<< <Selector>._domainkey.<Domain> >>.

=item Key or KeyFile

The private key as a L<Crypt::PK::RSA> or L<Crypt::PK::Ed25519> object, or
the path of a PEM file holding one (loaded with
L<Mail::DKIM2::Key/load_private_key>).

=back

Optional:

=over 4

=item Algorithm

C<rsa-sha256> or C<ed25519-sha256>. Defaults to the one the key signs with
(since 0.31; before, to C<rsa-sha256> whatever the key). Any other name, or
one that is not the key's, croaks.

=item MailFrom

The envelope sender of this hop, recorded in C<mf=>. Bare addresses are
bracketed; C<< '<>' >> or undef records the null sender.

=item RcptTo

An arrayref of this hop's envelope recipients, recorded in C<rt=>.

=item NextDomain

The C<d=> of the hop that will sign next, recorded in C<nd=> for an
imaginary forwarding hop (-09 section 12.3). Excludes C<MailFrom> and
C<RcptTo>.

=item Timestamp

The C<t=> value; defaults to now. Fix it for reproducible test output.

=item Nonce

The C<n=> value, at most 64 characters.

=item Flags

An arrayref of C<f=> flags, such as C<feedback>. An C<exploded> among
them is a request for the flag, as C<Exploded> is.

=item Exploded

True when this hop sends the message to more than one address, as a list
manager does (-09 section 12.5). The signature then carries the
C<exploded> flag, which it also gets whenever C<rt=> holds more than one
address. Never at C<i=1>: there the flag, requested this way or in
C<Flags>, is dropped.

=item ParentFromCallback

Whether this C<Domain> may make a From in a parent domain Authentic (-09
sections 7.1 item 4 and 11.1, contract E3.4; new in 0.29). Called as
C<< ($from_domain, $signer) >>, with the From domain as a lowercased
A-label, only when a hop that must make From Authentic signs with a C<d=>
below the From domain; true signs, false refuses. Answer it from
configuration or a database: the operator knows its own domains' policy, so
the Signer makes no DNS lookup for this unless asked to (below). Without
this option, C<PolicyCallback> or C<Resolver>, such a message is refused.

=item PolicyCallback, Resolver

An explicit opt-in to the Domain Policy Record lookup (-09 section 3.8)
instead of C<ParentFromCallback>, for a caller that wants it: the record of
the From domain is looked up, as for L<Mail::DKIM2::Verifier>, from
C<PolicyCallback> (C<< ($domain, $signer) >>, returning the TXT strings or
dying with C<TEMPERROR:>) or through C<Resolver>, and anything but a record
that allows subdomains refuses. Ignored when C<ParentFromCallback> is given.
C<< $signer->fetch_domain_policy($domain) >> is the default lookup, for a
callback to fall back to.

=back

An option not listed here croaks.

=head1 METHODS

=head2 PRINT($bytes), CLOSE(), load($input)

Feed the message; see L<Mail::DKIM2::HeaderParser>.

=head2 fetch_domain_policy($domain)

The default Domain Policy Record lookup (the TXT records at
C<< _domainkey.<domain> >> through C<Resolver>, an arrayref; dies with
C<TEMPERROR:> on a failure), for a C<PolicyCallback> to fall back to. New in
0.29.

=head2 result()

Undef until C<CLOSE>; then C<'signed'>, or C<'fail'> when the message
cannot be signed: no Message-Instance to sign over, an RSA key shorter than
1024 bits (-09 section 3.2; since 0.31), a chain already at the
length limit, a DKIM2-Signature with a missing or malformed C<i=> (or one
that does not parse), an C<i=> or C<m=> that is not a chain number (see
L<Mail::DKIM2::Common/"chain_number_error($field, $tag, $n)">), or a
repeated C<i=> or C<m=>; or, when the message has no DKIM2-Signature yet or
a Message-Instance no signature covers changed From, a From that is not
Authentic for C<Domain> (-09 sections 11 and 12.4: exactly one From field
holding one mailbox whose domain is C<Domain> or below it, or above it when
C<ParentFromCallback> allows that), with details
C<From header field is not Authentic for d=E<lt>DomainE<gt>>.
L</"details()"> says which. A failure is a result, not
an exception: C<PRINT> and C<CLOSE> return normally.

=head2 details()

The reason for a C<'fail'> result, or undef.

=head2 result_detail()

C<result> and C<details> together, e.g. C<"fail (PERMERROR ...)">.

=head2 as_string()

The complete C<DKIM2-Signature: ...> header, folded for insertion.

Croaks C<no signature: REASON> when there is no signature: before
C<CLOSE>, or when C<result> is C<fail> (REASON is C<details>). Check
C<result> first. (Before 0.24 it returned the empty string, which a caller
that prepended it unchecked turned into a blank line ending the message's
header block.)

=head2 chain()

The message's L<Mail::DKIM2::Chain>: the Message-Instance and
DKIM2-Signature fields it arrived with, by number. New in 0.31.

=head2 signature()

The L<Mail::DKIM2::Signature> object, available after C<CLOSE>.

=head2 sign_for_recipient($rcpt)

Re-signs for a different envelope recipient (one address or an arrayref of
them) and returns the folded header. -09 section 12.8 signs only the
Message-Instance and DKIM2-Signature fields, so the body and header hashes
in the Message-Instance are the same for every recipient and only C<rt=>
changes; an extra recipient costs one signature over a few hundred bytes,
not another pass over the message. Feed the message once, then call this
per recipient. Croaks on a signature carrying C<nd=>, which excludes
C<rt=>.

=head1 AUTHOR

Bron Gondwana E<lt>brong@fastmailteam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025-2026 Fastmail Pty Ltd.  This is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut

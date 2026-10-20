package Mail::DKIM2::Signer;
use strict;
use warnings;

our $VERSION = '0.25';

use base 'Mail::DKIM2::HeaderParser';
use Crypt::Digest::SHA256 qw(sha256);
use MIME::Base64 qw(encode_base64 decode_base64);
use Carp;

use Mail::DKIM2::Common qw(
    dkim2_canonicalize_header
    build_signing_input
    extract_mi_version
    load_private_key
    MAX_CHAIN_LENGTH
    chain_length_error
    duplicate_number_error
    valid_sequence
    unkeyable_signature_error
    chain_number_error
    mi_version_tag
    from_authentic
);
use Mail::DKIM2::Signature;
use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::HeaderPlan;

sub known_options {
    return qw(Domain Selector KeyFile Key Algorithm MailFrom RcptTo
              Nonce Flags Exploded Timestamp NextDomain);
}

sub init {
    my $self = shift;
    $self->SUPER::init;
    croak "Domain required" unless $self->{Domain};
    croak "Selector required" unless $self->{Selector};
    croak "KeyFile or Key required" unless $self->{KeyFile} || $self->{Key};

    $self->{Algorithm} ||= 'rsa-sha256';

    if ($self->{KeyFile} && !$self->{Key}) {
        $self->{Key} = load_private_key($self->{KeyFile});
    }
}

sub finish_header {
    my $self = shift;

    # Extract existing MI and DKIM2-Signature headers from the parsed headers
    my @mi_headers;
    my @dk2_headers;
    my $unkeyable;
    my $range;

    for my $header (@{$self->{headers}}) {
        if ($header =~ /^Message-Instance:/i) {
            my ($val) = $header =~ /^Message-Instance:\s*(.*)/is;
            $val =~ s/\r\n$//;
            my $v = extract_mi_version($val);
            # Not a chain number: a PERMERROR to every verifier.
            if (my $e = chain_number_error('Message-Instance', 'm', mi_version_tag($val))) {
                $range //= $e;
                next;
            }
            push @mi_headers, { v => $v, raw => $header } if $v;
        }
        elsif ($header =~ /^DKIM2-Signature:/i) {
            my ($val) = $header =~ /^DKIM2-Signature:\s*(.*)/is;
            $val =~ s/\r\n$//;
            my $sig = eval { Mail::DKIM2::Signature->parse($val) };
            die $@ if ref $@;
            # One no verifier can key (no parse, no valid i=) makes the
            # chain a PERMERROR, so do not sign over it.
            my $e = $sig && valid_sequence($sig->sequence)
                && (chain_number_error('DKIM2-Signature', 'i', $sig->sequence)
                    // chain_number_error('DKIM2-Signature', 'm', $sig->version, $sig->sequence));
            if ($e) {
                $range //= $e;
            }
            elsif ($sig && valid_sequence($sig->sequence)) {
                push @dk2_headers, { i => $sig->sequence, raw => $header, sig => $sig };
            } else {
                $unkeyable = unkeyable_signature_error($val);
            }
        }
    }

    # Sort by index
    @mi_headers  = sort { $a->{v} <=> $b->{v} } @mi_headers;
    @dk2_headers = sort { $a->{i} <=> $b->{i} } @dk2_headers;

    # Determine next i= value
    my $next_i = @dk2_headers ? $dk2_headers[-1]{i} + 1 : 1;

    # A signature that would take the chain past the limit is one every
    # verifier refuses, so do not make it.
    my %counts = (
        'message-instance' => scalar @mi_headers,
        'dkim2-signature'  => $next_i,
    );
    my $error = chain_length_error(\%counts)
        // $unkeyable
        // $range
        // duplicate_number_error('Message-Instance', 'm',
               map { $_->{v} } @mi_headers)
        // duplicate_number_error('DKIM2-Signature', 'i',
               map { $_->{i} } @dk2_headers);
    # A signature names the Message-Instance it covers in m=, and a verifier
    # rejects one that names none (tag=m missing), so a message with no
    # instance cannot be signed: compute one first (dkim2sign does).
    $error //= 'no Message-Instance field to sign over' unless @mi_headers;
    # -07 sections 11 and 12.4: a hop that originates the message, or whose
    # instances changed From, signs with a d= the From is Authentic for.
    $error //= "From header field is not Authentic for d=$self->{Domain}"
        if $self->_from_must_match(\@mi_headers, \@dk2_headers)
        && !from_authentic($self->{Domain},
               map { $_->[1] } grep { lc $_->[0] eq 'from' }
               @{ Mail::DKIM2::HeaderPlan::fields($self->{headers}) });
    if ($error) {
        # A protocol outcome, not a programming error: reported through
        # result/details like the Verifier's, so a streaming host is not
        # handed an exception from inside PRINT. The body is discarded.
        $self->{result}  = 'fail';
        $self->{details} = $error;
        $self->stop;
        return;
    }
    # Determine highest MI version
    my $mi_version = @mi_headers ? $mi_headers[-1]{v} : 0;

    $self->{_mi_version} = $mi_version;
    $self->{_timestamp}  = $self->{Timestamp} || time();
    $self->{_mi_headers} = \@mi_headers;
    $self->{_dk2_headers} = \@dk2_headers;
    $self->{_next_i} = $next_i;
    $self->{_signature} = $self->_new_signature($self->{RcptTo});
}

# The signature object for this hop with rt= set to $rcpt (an arrayref, or
# undef for none). -07 §12.3: when NextDomain is set this is an
# imaginary forwarding hop -- emit nd= and omit mf=/rt= (Signature->new
# enforces the exclusion).
#
# f= (-07 section 12.5): "exploded" MUST be set by a hop sending the message
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

# True when this signature answers for the From the message carries: there
# is no signature yet (this hop is i=1), or a Message-Instance no existing
# signature covers (m= above every signature's m=) has a header Recipe that
# names From -- this hop, or a list manager on its host, changed it. One
# that does not parse is left to the verifiers (and Mail::DKIM2::Gate),
# which refuse it: the Signer checks only what it needs to sign.
sub _from_must_match {
    my ($self, $mi_headers, $dk2_headers) = @_;
    return 1 unless @$dk2_headers;
    my $covered = 0;
    for my $d (@$dk2_headers) {
        my $m = $d->{sig}->version // 0;
        $covered = 0 + $m if $m =~ /\A[0-9]+\z/ && $m > $covered;
    }
    for my $mi (grep { $_->{v} > $covered } @$mi_headers) {
        (my $value = $mi->{raw}) =~ s/\A[^:]*:\s*//;
        my $obj = eval { Mail::DKIM2::MessageInstance->parse($value) };
        die $@ if ref $@;
        next unless $obj;
        my $rh = $obj->get_tag('rh');
        return 1 if $rh && exists $rh->{from};
    }
    return 0;
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
    croak "cannot set rt= on a signature carrying nd= (-07 §10.7)"
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

    my $signature    = $self->{_signature};
    my @mi_headers   = @{$self->{_mi_headers}};
    my @dk2_headers  = @{$self->{_dk2_headers}};

    # Reset s= to the empty placeholder before building the signing input.
    # Without this a second call would sign an input containing the FIRST
    # call's signature bytes, which no verifier can reproduce -- the signing
    # input must always carry an empty s= value (§12.8).
    $signature->set_tag('s', join(':', $self->{Selector}, $self->{Algorithm}, ''));

    # Include the new signature as the signing_i entry
    my $next_i = $self->{_next_i};
    my @all_dk2 = (@dk2_headers, { i => $next_i, sig => $signature });

    # Fold before signing: the fold positions become part of what gets
    # canonicalized and signed.
    my $folded_header = $signature->as_folded_string_without_data();

    my $signing_input = build_signing_input(
        mi_headers     => \@mi_headers,
        dk2_headers    => \@all_dk2,
        signing_i      => $next_i,
        signature      => $signature,
        signing_header => $folded_header,
    );

    # Sign the signing input
    my $key = $self->{Key};
    my $alg = $self->{Algorithm} || 'rsa-sha256';
    my $sig_raw;
    if ($alg =~ /^ed25519/) {
        # Ed25519-SHA256: hash first, then sign the digest
        my $digest = sha256($signing_input);
        $sig_raw = $key->sign_message($digest);
    } else {
        # RSA-SHA256: sign_message handles hashing internally
        $sig_raw = $key->sign_message($signing_input, 'SHA256', 'v1.5');
    }
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
    use Mail::DKIM2::Common qw(fold_header);
    unless ($message =~ /^Message-Instance:/mi) {
        my $mi = Mail::DKIM2::MessageInstance->calculate($message);
        $message = fold_header('Message-Instance: ' . $mi->as_string) . "\r\n" . $message;
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
the signing input of -07 section 10.5, and signs it. It does not alter
the message: the caller prepends the header C<as_string> returns.

Extends L<Mail::DKIM2::HeaderParser>, which provides C<PRINT>, C<CLOSE>,
C<load> and the tie interface.

This module implements draft-ietf-dkim-dkim2-spec-07; see L<Mail::DKIM2/STATUS>
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
L<Mail::DKIM2::Common/load_private_key>).

=back

Optional:

=over 4

=item Algorithm

C<rsa-sha256> (the default) or C<ed25519-sha256>.

=item MailFrom

The envelope sender of this hop, recorded in C<mf=>. Bare addresses are
bracketed; C<< '<>' >> or undef records the null sender.

=item RcptTo

An arrayref of this hop's envelope recipients, recorded in C<rt=>.

=item NextDomain

The C<d=> of the hop that will sign next, recorded in C<nd=> for an
imaginary forwarding hop (-07 section 12.3). Excludes C<MailFrom> and
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
manager does (-07 section 12.5). The signature then carries the
C<exploded> flag, which it also gets whenever C<rt=> holds more than one
address. Never at C<i=1>: there the flag, requested this way or in
C<Flags>, is dropped.

=back

An option not listed here croaks.

=head1 METHODS

=head2 PRINT($bytes), CLOSE(), load($input)

Feed the message; see L<Mail::DKIM2::HeaderParser>.

=head2 result()

Undef until C<CLOSE>; then C<'signed'>, or C<'fail'> when the message
cannot be signed: no Message-Instance to sign over, a chain already at the
length limit, a DKIM2-Signature with a missing or malformed C<i=> (or one
that does not parse), an C<i=> or C<m=> that is not a chain number (see
L<Mail::DKIM2::Common/"chain_number_error($field, $tag, $n)">), or a
repeated C<i=> or C<m=>; or, when the message has no DKIM2-Signature yet or
a Message-Instance no signature covers changed From, a From that is not
Authentic for C<Domain> (-07 sections 11 and 12.4: exactly one From field
holding one mailbox whose domain is C<Domain> or below it), with details
C<From header field is not Authentic for d=E<lt>DomainE<gt>>.
L</"details()"> says which. A failure is a result, not
an exception: C<PRINT> and C<CLOSE> return normally.

=head2 details()

The reason for a C<'fail'> result, or undef.

=head2 result_detail()

C<result> and C<details> together, e.g. C<"fail (PERMERROR ...)">.

=head2 as_string()

The complete C<DKIM2-Signature: ...> header, folded for insertion. The
folding is part of what was signed and must not be changed.

Croaks C<no signature: REASON> when there is no signature: before
C<CLOSE>, or when C<result> is C<fail> (REASON is C<details>). Check
C<result> first. (Before 0.24 it returned the empty string, which a caller
that prepended it unchecked turned into a blank line ending the message's
header block.)

=head2 signature()

The L<Mail::DKIM2::Signature> object, available after C<CLOSE>.

=head2 sign_for_recipient($rcpt)

Re-signs for a different envelope recipient (one address or an arrayref of
them) and returns the folded header. -07 section 12.8 signs only the
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

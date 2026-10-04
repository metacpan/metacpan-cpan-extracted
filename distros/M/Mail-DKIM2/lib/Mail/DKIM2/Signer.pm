package Mail::DKIM2::Signer;
use strict;
use warnings;

our $VERSION = '0.10';

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
);
use Mail::DKIM2::Signature;
use Mail::DKIM2::MessageInstance;

sub known_options {
    return qw(Domain Selector KeyFile Key Algorithm MailFrom RcptTo
              Nonce Flags Timestamp NextDomain);
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

    for my $header (@{$self->{headers}}) {
        if ($header =~ /^Message-Instance:/i) {
            my ($val) = $header =~ /^Message-Instance:\s*(.*)/is;
            $val =~ s/\r\n$//;
            my $v = extract_mi_version($val);
            push @mi_headers, { v => $v, raw => $header } if $v;
        }
        elsif ($header =~ /^DKIM2-Signature:/i) {
            my ($val) = $header =~ /^DKIM2-Signature:\s*(.*)/is;
            $val =~ s/\r\n$//;
            my $sig = eval { Mail::DKIM2::Signature->parse($val) };
            die $@ if ref $@;
            if ($sig && $sig->sequence) {
                push @dk2_headers, { i => $sig->sequence, raw => $header, sig => $sig };
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
        // duplicate_number_error('Message-Instance', 'm',
               map { $_->{v} } @mi_headers)
        // duplicate_number_error('DKIM2-Signature', 'i',
               map { $_->{i} } @dk2_headers);
    # A signature names the Message-Instance it covers in m=, and a verifier
    # rejects one that names none (tag=m missing), so a message with no
    # instance cannot be signed: compute one first (dkim2sign does).
    $error //= 'no Message-Instance field to sign over' unless @mi_headers;
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

    # Build initial signature items as [selector, algorithm, value] arrays
    my @sig_items;
    push @sig_items, [
        $self->{Selector},
        $self->{Algorithm},
        '',
    ];

    # Create the signature object
    # draft-06 §9.3: when NextDomain is set this is an imaginary forwarding
    # hop — emit nd= and omit mf=/rt= (Signature->new enforces the exclusion).
    my $signature = Mail::DKIM2::Signature->new(
        Sequence   => $next_i,
        Version    => $mi_version || undef,
        Timestamp  => $self->{Timestamp} || time(),
        Domain     => $self->{Domain},
        ($self->{NextDomain}
            ? (NextDomain => $self->{NextDomain})
            : (MailFrom => $self->{MailFrom}, RcptTo => $self->{RcptTo})),
        Signatures => \@sig_items,
        ($self->{Nonce} ? (Nonce => $self->{Nonce}) : ()),
        ($self->{Flags} ? (Flags => $self->{Flags}) : ()),
    );

    $self->{_signature} = $signature;
    $self->{_mi_headers} = \@mi_headers;
    $self->{_dk2_headers} = \@dk2_headers;
    $self->{_next_i} = $next_i;
}

sub finish_body {
    my $self = shift;
    $self->_compute_signature;
    $self->{result} = 'signed';
}

# Re-sign the same message for a different envelope recipient, returning the
# folded DKIM2-Signature header to prepend for that recipient.
#
# This is the cheap half of signing. §9.6 signs solely the Message-Instance and
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
# nd=, which excludes rt= by §8.7; Signature::rcpt_to croaks in that case.
sub sign_for_recipient {
    my ($self, $rcpt) = @_;
    croak "sign_for_recipient: no signature: " . ($self->{details} // 'CLOSE has not run')
        unless $self->{_signature};
    $self->{_signature}->rcpt_to($rcpt);
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
    # input must always carry an empty s= value (§9.6).
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

sub as_string {
    my $self = shift;
    return '' unless $self->{_signature};
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
the signing input of spec-06 section 8.5, and signs it. It does not alter
the message: the caller prepends the header C<as_string> returns.

Extends L<Mail::DKIM2::HeaderParser>, which provides C<PRINT>, C<CLOSE>,
C<load> and the tie interface.

This module implements draft-ietf-dkim-dkim2-spec-06; see L<Mail::DKIM2/STATUS>
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
imaginary forwarding hop (spec-06 section 9.3). Excludes C<MailFrom> and
C<RcptTo>.

=item Timestamp

The C<t=> value; defaults to now. Fix it for reproducible test output.

=item Nonce

The C<n=> value, at most 64 characters.

=item Flags

An arrayref of C<f=> flags, such as C<donotmodify>.

=back

An option not listed here croaks.

=head1 METHODS

=head2 PRINT($bytes), CLOSE(), load($input)

Feed the message; see L<Mail::DKIM2::HeaderParser>.

=head2 result()

Undef until C<CLOSE>; then C<'signed'>, or C<'fail'> when the message
cannot be signed (no Message-Instance to sign over, a chain already at the
length limit, or a repeated C<i=> or C<m=>). A failure is a result, not an exception: C<PRINT> and
C<CLOSE> return normally.

=head2 details()

The reason for a C<'fail'> result, or undef.

=head2 result_detail()

C<result> and C<details> together, e.g. C<"fail (PERMERROR ...)">.

=head2 as_string()

The complete C<DKIM2-Signature: ...> header, folded for insertion, or the
empty string if there is no signature. The folding is part of what was
signed and must not be changed.

=head2 signature()

The L<Mail::DKIM2::Signature> object, available after C<CLOSE>.

=head2 sign_for_recipient($rcpt)

Re-signs for a different envelope recipient (one address or an arrayref of
them) and returns the folded header. Spec-06 section 9.6 signs only the
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

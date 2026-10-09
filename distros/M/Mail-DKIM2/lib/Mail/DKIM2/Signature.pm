package Mail::DKIM2::Signature;
use strict;
use warnings;

our $VERSION = '0.17';

use MIME::Base64 qw(encode_base64 decode_base64);
use Carp;

use Mail::DKIM2::Common qw(encode_tag_json decode_tag_json fold_header to_rfc5321_path);

use base 'Mail::DKIM2::TagValueList';

# Indices into the 3-element signature item arrays [selector, algorithm, value]
use constant SIG_SELECTOR  => 0;
use constant SIG_ALGORITHM => 1;
use constant SIG_VALUE     => 2;

# --- Construction ---

sub new {
    my ($class, %args) = @_;

    my $self = $class->SUPER::new();
    bless $self, $class;

    $self->set_tag('i', $args{Sequence})  if defined $args{Sequence};
    $self->set_tag('m', $args{Version})   if defined $args{Version};
    $self->set_tag('t', $args{Timestamp}) if defined $args{Timestamp};
    $self->set_tag('d', $args{Domain})    if defined $args{Domain};
    # nd= (draft-06 §8.7) replaces mf=/rt= for an imaginary forwarding hop.
    $self->set_tag('nd', $args{NextDomain}) if defined $args{NextDomain};
    $self->set_tag('n', $args{Nonce})     if defined $args{Nonce};

    if (defined $args{Flags}) {
        $self->set_tag('f', join(',', @{$args{Flags}}));
    }

    # mf= and rt= are base64-encoded SMTP addresses; mutually exclusive with nd=
    if (!defined $args{NextDomain}) {
        if (defined $args{MailFrom}) {
            $self->set_tag('mf', encode_base64(to_rfc5321_path($args{MailFrom}), ''));
        }
        if (defined $args{RcptTo}) {
            my @encoded = map { encode_base64(to_rfc5321_path($_), '') } @{$args{RcptTo}};
            $self->set_tag('rt', join(',', @encoded));
        }
    }

    if (defined $args{Signatures}) {
        # Encode as sel:alg:sig,sel2:alg2:sig2,...
        my @parts;
        for my $item (@{$args{Signatures}}) {
            push @parts, join(':', @$item);
        }
        $self->set_tag('s', join(',', @parts));
    }

    return $self;
}

# --- Parse from header line ---

sub parse {
    my ($class, $header_line) = @_;
    # Strip "DKIM2-Signature:" prefix if present
    $header_line =~ s/^\s*DKIM2-Signature:\s*//i;
    my $self = $class->SUPER::parse($header_line);
    bless $self, ref($class) || $class;
    return $self;
}

# --- Tag accessors ---

sub sequence {
    my $self = shift;
    if (@_) { $self->set_tag('i', shift) }
    return $self->get_tag('i');
}

sub version {
    my $self = shift;
    if (@_) { $self->set_tag('m', shift) }
    return $self->get_tag('m');
}

sub timestamp {
    my $self = shift;
    if (@_) { $self->set_tag('t', shift) }
    return $self->get_tag('t');
}

sub domain {
    my $self = shift;
    if (@_) { $self->set_tag('d', shift) }
    return $self->get_tag('d');
}

# nd= the domain that signs the next DKIM2-Signature (draft-06 §8.7). Present
# only for an imaginary forwarding hop, where it replaces mf=/rt=.
sub next_domain {
    my $self = shift;
    if (@_) { $self->set_tag('nd', shift) }
    return $self->get_tag('nd');
}

sub nonce {
    my $self = shift;
    if (@_) {
        my $val = shift;
        Carp::croak "nonce must not exceed 64 characters" if length($val) > 64;
        $self->set_tag('n', $val);
    }
    return $self->get_tag('n');
}

# spec-06 §2.12: folding whitespace may appear anywhere inside a tag value and
# "MUST be ignored when the value is used".  DKIM2 tag values are base64,
# tokens, digits or domains and never carry significant internal whitespace, so
# any WSP present came from a fold.  TagValueList::parse only trims the ends of
# the whole value, which leaves a fold inside a comma-separated list glued to
# the item that follows it -- so strip per item, before splitting on ':'.
sub _strip_fws {
    my ($v) = @_;
    return $v unless defined $v;
    $v =~ s/[ \t\r\n]//g;
    return $v;
}

# f= is a comma-separated list of flags (§8.6). Get as an arrayref, or set
# from one.
sub flags {
    my $self = shift;
    if (@_) {
        my $list = shift;
        $self->set_tag('f', join(',', ref $list eq 'ARRAY' ? @$list : ($list)));
    }
    my $f = $self->get_tag('f');
    return unless defined $f;
    return [grep { length } map { _strip_fws($_) } split /,/, $f];
}

sub signatures_data {
    my $self = shift;
    my $s = $self->get_tag('s');
    return unless defined $s && length $s;
    # Parse sel:alg:sig,sel2:alg2:sig2,...
    #
    # Strip FWS from each item *before* splitting on ':'.  A fold landing right
    # after the comma would otherwise become part of the next item's Selector,
    # sending the public-key lookup out for "\tsel2._domainkey.example.com"
    # (SERVFAIL).  Folds inside the base64 signature value and around the item's
    # colons are handled by the same strip.
    my @items;
    for my $part (split /,/, $s) {
        push @items, [split(/:/, _strip_fws($part), 3)];
    }
    return \@items;
}

# --- Envelope accessors (mf= and rt= tags) ---

# mf= and rt= are base64-encoded RFC 5321 paths; both are excluded by nd=
# (§8.7), which marks an imaginary forwarding hop with no envelope of its
# own. Setting either on an nd= signature is therefore a caller error.
sub _croak_if_nd {
    my ($self, $tag) = @_;
    croak "cannot set $tag= on a signature carrying nd= (spec-06 §8.7)"
        if defined $self->get_tag('nd');
}

sub mail_from {
    my $self = shift;
    if (@_) {
        $self->_croak_if_nd('mf');
        $self->set_tag('mf', encode_base64(to_rfc5321_path(shift), ''));
    }
    my $mf = $self->get_tag('mf');
    return unless defined $mf;
    return decode_base64($mf);
}

# rt= is the only tag that differs between recipients of the same message.
# §9.6 signs solely the Message-Instance and DKIM2-Signature header fields, so
# the body hash, the header-fields hash and the Message-Instance are all
# recipient-invariant: re-signing for another recipient means changing this tag
# and nothing else. See Mail::DKIM2::Signer::sign_for_recipient. Takes one
# address or an arrayref of them; always returns an arrayref.
sub rcpt_to {
    my $self = shift;
    if (@_) {
        $self->_croak_if_nd('rt');
        my $rcpt = shift;
        my @list = ref $rcpt eq 'ARRAY' ? @$rcpt : ($rcpt);
        croak "rcpt_to requires at least one recipient" unless @list;
        $self->set_tag('rt',
            join(',', map { encode_base64(to_rfc5321_path($_), '') } @list));
    }
    my $rt = $self->get_tag('rt');
    return unless defined $rt;
    return [map { decode_base64($_) } split /,/, $rt];
}

# --- Convenience methods for signature items ---

sub _sig_items {
    my ($self) = @_;
    return $self->signatures_data;
}

sub selector {
    my ($self, $idx) = @_;
    $idx //= 0;
    my $sigs = $self->_sig_items;
    return unless $sigs && $sigs->[$idx];
    return $sigs->[$idx][SIG_SELECTOR];
}

sub algorithm {
    my ($self, $idx) = @_;
    $idx //= 0;
    my $sigs = $self->_sig_items;
    return unless $sigs && $sigs->[$idx];
    return $sigs->[$idx][SIG_ALGORITHM];
}

sub signature_value {
    my ($self, $idx) = @_;
    $idx //= 0;
    my $sigs = $self->_sig_items;
    return unless $sigs && $sigs->[$idx];
    return $sigs->[$idx][SIG_VALUE];
}

# --- Serialization ---

# Raw unfolded header — used by the verifier to reconstruct signing input.
sub as_string {
    my ($self) = @_;
    return "DKIM2-Signature: " . $self->SUPER::as_string();
}

# Serialize with signature data replaced by "." in each s= entry.
# Returns unfolded output. Used by the verifier to reconstruct the
# signing input from a header read from the message.
# Format: sel:alg:.,sel2:alg2:. (signature replaced with dot)
sub as_string_without_data {
    my ($self) = @_;

    # Rebuild from the parsed tags in their original order and case, blanking
    # each s= item's signature value in place.  Done directly (not via
    # set_tag/as_string) so a non-lowercase 's' tag name — e.g. "S=" in a
    # mixed-case header — is not duplicated by a fresh lowercase 's' key.
    my @parts;
    for my $t (@{$self->{order}}) {
        my $v = defined $self->{tags}{$t} ? $self->{tags}{$t} : '';
        if (lc $t eq 's') {
            # Replace each sel:alg:sig with sel:alg: (empty value per §8.5)
            $v =~ s/([^,:]+:[^,:]+):[^,]*/$1:/g;
        }
        push @parts, "$t=$v";
    }
    return "DKIM2-Signature: " . join('; ', @parts);
}

# Folded header with empty s= value, ready for signing.
# Used by the Signer: fold first, then canonicalize and sign.
# The fold positions become part of what is signed.
sub as_folded_string_without_data {
    my ($self) = @_;

    # Replace each sel:alg:sig with sel:alg: (null/empty string per spec §8.5)
    my $saved = $self->get_tag('s');
    my $stripped = $saved;
    $stripped =~ s/([^,:]+:[^,:]+):[^,]*/$1:/g;

    my @parts;
    for my $t (@{$self->{order}}) {
        if ($t eq 's') {
            push @parts, "s=$stripped";
        } else {
            push @parts, "$t=$self->{tags}{$t}";
        }
    }
    my $line = "DKIM2-Signature: " . join('; ', @parts) . ";";
    return fold_header($line);
}

# Folded header with real s= value, ready for insertion into a message.
# The prefix (everything before s=) has the same fold positions as
# as_folded_string_without_data(), with s= replaced by the real value.
sub as_folded_string {
    my ($self) = @_;

    my @parts;
    for my $t (@{$self->{order}}) {
        next if $t eq 's';
        push @parts, "$t=$self->{tags}{$t}";
    }
    my $s_val = $self->{tags}{s} // '';
    my $line = "DKIM2-Signature: " . join('; ', @parts) . "; s=$s_val;";
    return fold_header($line);
}

sub sig_count {
    my ($self) = @_;
    my $sigs = $self->_sig_items;
    return 0 unless $sigs;
    return scalar @$sigs;
}

# spec-06 §8.9 duplicate/limit rules for one DKIM2-Signature s= tag.
#
# A Selector MUST NOT appear more than once. The same signing algorithm MAY
# appear a second time, but only with a distinct Selector -- three or more
# occurrences of the same algorithm means "more selectors than allowed". The
# two checks are independent: two items sharing both algorithm and Selector
# are a duplicate-selector error, not a selector-count error (the count is 2,
# not 3+).
#
# Matching is case-insensitive for both: hash/algorithm names are RFC 5234
# ABNF quoted strings (case-insensitive), and a Selector is a Domain (§3.5),
# and DNS names are case-insensitive.
#
# Returns a list of PERMERROR strings (empty if clean).
sub check_duplicates {
    my ($self) = @_;
    my $sigs = $self->_sig_items;
    return () unless $sigs && @$sigs;

    my $i_val = $self->sequence;
    my (%sel_count, %alg_count);
    for my $item (@$sigs) {
        $sel_count{lc($item->[SIG_SELECTOR]  // '')}++;
        $alg_count{lc($item->[SIG_ALGORITHM] // '')}++;
    }

    my @errors;
    if (grep { $_ > 1 } values %sel_count) {
        push @errors, "PERMERROR DKIM2-Signature i=$i_val has a duplicate selector";
    }
    if (grep { $_ > 2 } values %alg_count) {
        push @errors, "PERMERROR DKIM2-Signature i=$i_val has more selectors than allowed";
    }
    return @errors;
}

1;

__END__

=encoding utf8

=head1 NAME

Mail::DKIM2::Signature - One DKIM2-Signature header, parsed or under construction

=head1 SYNOPSIS

    use Mail::DKIM2::Signature;

    # Parse a header read from a message
    my $sig = Mail::DKIM2::Signature->parse($header_value);
    say $sig->sequence;      # i=
    say $sig->domain;        # d=
    say $sig->mail_from;     # mf=, decoded: "<sender@example.com>"
    say @{ $sig->rcpt_to };  # rt=, decoded
    say $sig->selector(0);   # first s= item's selector

    # Build one (the Signer does this for you)
    my $sig = Mail::DKIM2::Signature->new(
        Sequence   => 1,
        Version    => 1,
        Timestamp  => time,
        Domain     => 'example.com',
        MailFrom   => '<sender@example.com>',
        RcptTo     => ['<rcpt@example.net>'],
        Signatures => [['sel1', 'rsa-sha256', '']],
    );

=head1 DESCRIPTION

A DKIM2-Signature header as defined in spec-06 section 8, as a
L<Mail::DKIM2::TagValueList>. The tags:

=over 4

=item C<i=>

Sequence number: this signature's position in the chain, from 1.

=item C<m=>

The Message-Instance C<m=> this signature covers; absent when the message
has no Message-Instance.

=item C<t=>

Unix timestamp of signing.

=item C<d=>

Signing domain.

=item C<mf=>, C<rt=>

The envelope of this hop: MAIL FROM, and a comma-separated list of RCPT TO,
each a base64-encoded RFC 5321 path with angle brackets (section 7.5 and
7.6). C<< <> >> is the null sender.

=item C<nd=>

For an imaginary forwarding hop (section 9.3), the C<d=> of the hop that
signs next. Replaces C<mf=> and C<rt=>.

=item C<n=>

A nonce of at most 64 characters.

=item C<f=>

Comma-separated flags: C<donotmodify>, C<donotexplode>, C<feedback>,
C<feedhere>.

=item C<s=>

The signature items, C<selector:algorithm:base64signature>, comma-separated.
A selector may appear once; an algorithm at most twice.

=back

This module implements draft-ietf-dkim-dkim2-spec-06; see L<Mail::DKIM2/STATUS>
for what that means for the wire format and the API, and
L<Mail::DKIM2/CONVENTIONS> for the option, input and error conventions every
module here follows.

=head1 CONSTRUCTORS

=head2 new(%args)

Builds a signature from C<Sequence>, C<Version>, C<Timestamp>, C<Domain>,
C<MailFrom>, C<RcptTo> (arrayref), C<NextDomain>, C<Nonce>, C<Flags>
(arrayref) and C<Signatures>, an arrayref of C<[selector, algorithm,
value]> arrayrefs. Each sets the tag described above when given;
C<NextDomain> suppresses C<MailFrom> and C<RcptTo>.

=head2 parse($header_value)

Parses a header value, with or without the leading C<DKIM2-Signature:>.
Tag names keep their case and order so the header can be re-serialised
byte for byte; lookups are case-insensitive.

=head1 TAG ACCESSORS

Each gets the tag, or sets it when given an argument and returns the new
value. Envelope paths are bracketed on the way in and decoded on the way
out.

=head2 sequence([$i]), version([$m]), timestamp([$t]), domain([$d]), next_domain([$nd])

The plain tags.

=head2 nonce([$n])

Croaks on a value over 64 characters.

=head2 mail_from([$path])

The decoded C<mf=>, e.g. C<< "<sender@example.com>" >>, or undef.

=head2 rcpt_to([$path_or_arrayref])

An arrayref of decoded C<rt=> paths, or undef. Setting accepts one address
or an arrayref and requires at least one.

Setting C<mail_from> or C<rcpt_to> on a signature carrying C<nd=> croaks.

=head2 flags([\@flags])

An arrayref of flags, or undef.

=head1 SIGNATURE ITEMS

=head2 signatures_data()

An arrayref of C<[selector, algorithm, value]> arrayrefs, one per C<s=>
item, with folding whitespace stripped.

=head2 selector([$index]), algorithm([$index]), signature_value([$index])

The parts of the item at C<$index> (default 0).

=head2 sig_count()

The number of items.

=head2 check_duplicates()

A list of PERMERROR strings for the section 8.9 rules: a selector used
twice, or an algorithm used more than twice. Empty if clean.

=head1 SERIALIZATION

=head2 as_string()

The complete header line, unfolded.

=head2 as_string_without_data()

The header with every C<s=> value emptied, unfolded: the last element of
the signing input as the Verifier reconstructs it.

=head2 as_folded_string_without_data()

The same, folded at 72 characters: the last element of the signing input
as the Signer produces it. Where the folds land is part of what is signed.

=head2 as_folded_string()

The complete header folded at 72 characters, ready to insert into the
message. Never refold it afterwards.

=head1 AUTHOR

Bron Gondwana E<lt>brong@fastmailteam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025-2026 Fastmail Pty Ltd.  This is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut

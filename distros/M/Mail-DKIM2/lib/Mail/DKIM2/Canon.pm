package Mail::DKIM2::Canon;
use 5.20.0;
use strict;
use warnings;

our $VERSION = '0.33';

use Carp ();
use Mail::DKIM2::Util ();

use Exporter 'import';
our @EXPORT_OK = qw(
    check_ignore_prefixes
    should_skip
    field_name
    header_values
    dkim2_canonicalize_header
    dkim2_canonicalize_sig_header
    build_signing_input
);

# Headers excluded from hashing per draft-ietf-dkim-dkim2-spec-09 Section 4.
# spec-05 narrowed the old /^arc-/ prefix to the three RFC 8617 field names and
# added a /^received-/ prefix rule so future trace fields of that form need no
# change here. spec-08 took auto-submitted and vbr-info off the list.
my %SKIP_EXACT = map { $_ => 1 } qw(
    apparently-to arc-authentication-results arc-message-signature arc-seal
    authentication-results delivered-to dkim-signature
    dkim2-signature dl-expansion-history message-instance original-recipient
    received return-path sio-label-history x400-received x400-trace
);

# The IgnorePrefixes option as every entry point validates it: undef, or an
# array reference. A bare string is a configuration mistake and croaks, so it
# does not surface later as a 'fail' on every message.
sub check_ignore_prefixes {
    my ($prefixes) = @_;
    return unless defined $prefixes;
    Carp::croak("IgnorePrefixes must be an array reference of header-name prefixes")
        unless ref $prefixes eq 'ARRAY';
    return $prefixes;
}

# should_skip($name, \@prefixes)
#
# True when the field is excluded from the header hash: by the spec's list
# above, or by one of the caller's prefixes. The prefixes are an operator's
# own field names, put on the wrong side of the signature by its own systems:
# added at its border on the way in, stripped at its border on the way out.
# A signer that hashed one would sign a message no recipient ever sees; a
# verifier that hashed one would fail the operator's own forwards. The spec
# knows nothing of them and neither does a remote verifier, so the operator
# also has to make sure no field with one of these names ever leaves its
# network. They are local policy, so they travel as an argument -- never as
# state shared by every Signer and Verifier in the process.
sub should_skip {
    my ($name, $prefixes) = @_;
    my $hname = lc $name;
    return 1 if $SKIP_EXACT{$hname};
    return 1 if $hname =~ m/^x-/;
    return 1 if $hname =~ m/^received-/;
    return 1 if $prefixes && grep { index($hname, lc $_) == 0 } @$prefixes;
    return 0;
}

# field_name($name): a header field's name as DKIM2 compares it: lowercased,
# without the WSP RFC 5322's obsolete syntax (obs-optional) allows between it
# and the colon. "From :" is a From field (-09 section 6.2 deletes that WSP);
# taking the WSP as part of the name hid such a field from the From check.
sub field_name {
    my ($name) = @_;
    ($name = lc($name // '')) =~ s/[ \t]+\z//;
    return $name;
}

# header_values($msg, $name): the values of every field of an Email::MIME
# message whose field_name is $name's, in order -- header_raw, but finding
# "From :" (which Email::Simple files under "From ") as well.
sub header_values {
    my ($msg, $name) = @_;
    my $want = field_name($name);
    my @pairs = $msg->header_obj->header_raw_pairs;
    return map { $pairs[2 * $_ + 1] }
           grep { field_name($pairs[2 * $_]) eq $want } 0 .. $#pairs / 2;
}

# DKIM2 header canonicalization for the header hash, -09 section 6.2:
# 1. Lowercase the field name
# 2. Unfold continuation lines (remove CRLF before WSP)
# 3. Collapse each run of WSP to a single SP
# 4. Strip trailing WSP before the CRLF
# 5. Remove WSP around the colon
sub dkim2_canonicalize_header {
    my ($line) = @_;
    # Unfold: remove CRLF followed by WSP
    $line =~ s/\r?\n[ \t]/ /g;
    # Split on colon
    my ($name, $value) = split(/:/, $line, 2);
    return $line unless defined $value;
    # Lowercase name, without the WSP RFC 5322's obsolete syntax allows
    # before the colon (-09 section 6.2 deletes it)
    $name = field_name($name);
    # Collapse WSP runs to single SP
    $value =~ s/[ \t]+/ /g;
    # Strip leading and trailing WSP from value
    $value =~ s/^[ \t]+//;
    $value =~ s/[ \t]*\r?\n?$//;
    return "$name:$value\r\n";
}

# DKIM2 header canonicalization for the signing input, -09 section 12.8:
# as for the header hash, except that ALL WSP is deleted rather than each
# run collapsed to one SP -- so where a Message-Instance or DKIM2-Signature
# field is folded never matters to a signature.
sub dkim2_canonicalize_sig_header {
    my ($line) = @_;
    # Unfold: remove CRLF followed by WSP
    $line =~ s/\r?\n[ \t]//g;
    # Split on colon
    my ($name, $value) = split(/:/, $line, 2);
    return $line unless defined $value;
    # Lowercase name, without any WSP before the colon
    $name = field_name($name);
    # Delete ALL WSP characters
    $value =~ s/[ \t]+//g;
    # Strip trailing CRLF/LF
    $value =~ s/\r?\n?$//;
    return "$name:$value\r\n";
}

# build_signing_input(%args): the octets a DKIM2-Signature signs (-09
# section 12.8), for the Signer and the Verifier alike. Each field is given
# whole, name and value, as it is in the message (or as it will be): folded
# or not, with or without its line break.
#   instances  => the Message-Instance fields the signature covers (m= up to
#                 its own m=), in ascending m= order
#   signatures => the DKIM2-Signature fields below it, in ascending i= order
#   signing    => the DKIM2-Signature being made or checked; its s= values
#                 are emptied here, so it may be given signed or unsigned
sub build_signing_input {
    my (%args) = @_;
    Mail::DKIM2::Util::check_options('build_signing_input', \%args, qw(instances signatures signing));
    Carp::croak("build_signing_input needs the field being signed (signing)")
        unless defined $args{signing};
    return join '',
        (map { dkim2_canonicalize_sig_header($_) }
             @{ $args{instances} || [] }, @{ $args{signatures} || [] }),
        _without_signature_values(dkim2_canonicalize_sig_header($args{signing}));
}

# A canonicalized DKIM2-Signature field with each s= item's signature value
# emptied (-09 section 12.8): the selectors, the algorithm names and the
# ":" "," "|" all stay. Only the tag named exactly "s": tag-names are
# case-sensitive (section 8), so an "S=" is an unknown tag, signed as it is.
sub _without_signature_values {
    my ($canon) = @_;
    my ($name, $value) = split /:/, $canon, 2;
    return $canon unless defined $value;
    my $eol = $value =~ s/(\r\n)\z// ? $1 : '';
    my @specs = split /;/, $value, -1;
    for (@specs) {
        next unless /\As=/;
        s/([^,|:=]+:[^,|:]+):[^,|]*/$1:/g;
    }
    return "$name:" . join(';', @specs) . $eol;
}

1;

__END__

=encoding utf8

=head1 NAME

Mail::DKIM2::Canon - Header canonicalization and the signing input for DKIM2

=head1 SYNOPSIS

    use Mail::DKIM2::Canon qw(dkim2_canonicalize_header should_skip build_signing_input);

    my $line = dkim2_canonicalize_header("Subject:  Hello\r\n\tworld\r\n");   # "subject:Hello world\r\n"

=head1 DESCRIPTION

The octets the spec defines: which header fields are hashed
(-09 section 4), how a field is canonicalized for the header hash (section
6.2) and for the signing input (section 12.8), and the signing input
itself. Of interest to anyone checking this implementation against
another. Nothing is exported by default; L<Mail::DKIM2::Common> exports
all of these too, as it did before they moved here in 0.31.

See L<Mail::DKIM2/CONVENTIONS> for the conventions every module follows.

=head1 FUNCTIONS

=head2 should_skip($header_name, [\@prefixes])

True if the field is excluded from the header hash: the -09 section 4
list (C<Received>, C<Return-Path>, C<Message-Instance>,
C<DKIM2-Signature>, C<DKIM-Signature>, C<Authentication-Results>, the ARC
fields and others), any C<X-*> or C<Received-*> field, or a field whose
name starts with one of the caller's prefixes, case-insensitively. The
prefixes are an operator's local policy; pass them as C<IgnorePrefixes> to
L<Mail::DKIM2::Verifier> and the L<Mail::DKIM2::MessageInstance> class
methods.

=head2 check_ignore_prefixes($value)

Croaks unless C<$value> is undef or an array reference; returns it. Every
entry point that takes C<IgnorePrefixes> calls this.

=head2 dkim2_canonicalize_header($line)

Header-hash canonicalization (-09 section 6.2) of one complete header line
including its CRLF: unfold, lowercase the name, collapse whitespace runs to
one space, trim whitespace around the colon and at the end. Returns
C<name:value\r\n>.

=head2 field_name($name)

A header field name as DKIM2 compares it: lowercased, without the white
space RFC 5322's obsolete syntax allows between the name and its colon
(-09 section 6.2 deletes it), so C<From :> names a From field. New in 0.31.

=head2 header_values($msg, $name)

The values of every field of an L<Email::MIME> message whose
C<field_name> is C<$name>'s, in order: C<header_raw>, but also finding a
field written with white space before its colon, which L<Email::Simple>
files under a name that includes it. New in 0.31.

=head2 dkim2_canonicalize_sig_header($line)

Signing-input canonicalization (-09 section 12.8): as above, but all
whitespace in the value is removed rather than collapsed.

=head2 build_signing_input(%args)

The octets a DKIM2-Signature signs (-09 section 12.8): the canonicalized
Message-Instance fields in ascending C<m=> order, the DKIM2-Signature
fields below the one being signed in ascending C<i=> order, and that one
with its C<s=> signature values emptied. Arguments, each field given whole
(name and value) and folded or not: C<instances>, an arrayref of the
Message-Instance fields the signature covers; C<signatures>, an arrayref
of the DKIM2-Signature fields below it; C<signing>, the DKIM2-Signature
being made or checked, signed or not. The Signer and the Verifier build
the input the same way, from the fields themselves. (Before 0.31 the
arguments were C<mi_headers>, C<dk2_headers>, C<signing_i>, C<signature>
and C<signing_header>.)

=head1 AUTHOR

Bron Gondwana E<lt>brong@fastmailteam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025-2026 Fastmail Pty Ltd.  This is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut

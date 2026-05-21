package File::Raw::Base64;

use 5.008003;
use strict;
use warnings;

our $VERSION = '0.04';

use base 'File::Raw';

require XSLoader;
XSLoader::load('File::Raw::Base64', $VERSION);

1;

__END__

=head1 NAME

File::Raw::Base64 - Base64 plugin for File::Raw

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

Loading the module registers two plugins (C<base64> and C<base64url>)
with File::Raw. Opt in per-call:

    use File::Raw::Base64;
    use File::Raw qw(import);   # installs file_slurp / file_spew / ...

    # Decode a base64-encoded blob into bytes.
    my $bytes = file_slurp("token.b64", plugin => 'base64');

    # Encode bytes into base64 text.
    file_spew("blob.b64", $payload, plugin => 'base64', wrap => 64);

    # PEM mode: strip BEGIN/END headers on read, wrap with them on write.
    my $der = file_slurp("cert.pem", plugin => 'base64', pem => 1);

    file_spew("cert.pem", $der,
        plugin    => 'base64',
        pem       => 1,
        pem_label => 'CERTIFICATE',
        wrap      => 64,
    );

    # URL-safe alphabet (- and _ instead of + and /).
    my $bytes = file_slurp("jwt.txt", plugin => 'base64url', padding => 0);

=head1 OPTIONS

Both plugins accept the same keys.

=over 4

=item C<wrap>

Encode-only. Insert a line terminator after every C<wrap> output
characters. C<0> (default) emits a single line. C<64> matches PEM,
C<76> matches MIME (RFC 2045).

=item C<urlsafe>

Switch to the URL-safe alphabet (C<-> and C<_> instead of C<+> and
C</>). The C<base64url> plugin sets this automatically; passing
C<urlsafe =E<gt> 0> on a C<base64url> call would force the standard
alphabet.

=item C<padding>

Encode-only. C<1> (default) appends C<=> to align the output to a
multiple of four characters. C<0> strips trailing padding (handy for
JWT, where padding is conventionally omitted). Decoders are always
tolerant of missing padding.

=item C<pem>

C<1> turns on PEM envelope handling. On encode, the output is wrapped
in C<-----BEGIN $pem_label-----> / C<-----END $pem_label-----> lines.
On decode, those lines are located and stripped before the body is
decoded; whitespace inside the body is ignored regardless of
C<strict>. BEGIN and END labels must match or decode croaks.

=item C<pem_label>

Encode-only. Label used in the BEGIN/END markers. Default C<DATA>.
Common real-world values: C<CERTIFICATE>, C<PRIVATE KEY>, C<PUBLIC KEY>,
C<RSA PRIVATE KEY>.

=item C<strict>

Decode-only. C<1> rejects any byte outside the active alphabet (with
an error message naming the byte offset). Default C<0> silently skips
non-alphabet bytes - matching C<MIME::Base64::decode_base64>.

=item C<eol>

Encode-only. Line terminator emitted when C<wrap> or C<pem> is on.
Default C<"\n">. Pass C<"\r\n"> for CRLF output. One or two bytes
only.

=back

=head1 PLUGIN BEHAVIOUR

The two registered plugins differ only in their seeded default
alphabet:

=over 4

=item *

C<base64> - RFC 4648 section 4 alphabet (C<A-Z a-z 0-9 + />).

=item *

C<base64url> - RFC 4648 section 5 alphabet (C<A-Z a-z 0-9 - _>).

=back

WRITE and READ phases are wired; STREAM and RECORD are not - base64
decoding is naturally chunk-aligned but the in-memory call covers the
common case at one syscall through File::Raw, which is the point.

Combine with other File::Raw plugins via plugin chains
(F<plugin =E<gt> ['base64', 'csv']>) once
File::Raw 0.11 lands chain support.

=head1 SEE ALSO

L<File::Raw>, L<MIME::Base64>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

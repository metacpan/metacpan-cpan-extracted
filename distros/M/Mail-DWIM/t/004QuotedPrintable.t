use warnings;
use strict;

use Test::More;
use Mail::DWIM;
use File::Temp qw(tempfile);
use MIME::QuotedPrint qw(decode_qp);

plan tests => 18;

# Extract the serialized parts without adding a MIME parser dependency.
sub parts {
    my($headers, $body) = @_;
    my($boundary) = $headers->{'Content-Type'} =~ /boundary="([^"]+)"/;
    die "Missing MIME boundary" unless defined $boundary;
    my @parts = split /^--\Q$boundary\E(?:--)?\r?\n/m, $body;
    shift @parts; # MIME preamble
    pop @parts;   # MIME epilogue
    for (@parts) {
        s/\r?\n\z//; # Newline belonging to the following boundary
    }
    return @parts;
}

sub check_part {
    my($part, $type, $expected, $label) = @_;
    my($headers, $encoded) = split /\r?\n\r?\n/, $part, 2;
    like($headers, qr/^Content-Type: \Q$type\E(?:;|\r?$)/mi,
         "$label content type");
    like($headers, qr/^Content-Transfer-Encoding: quoted-printable\r?$/mi,
         "$label uses quoted-printable");
    like($encoded, qr/=3D/, "$label escapes equals signs");
    unlike($encoded, qr/[^\x00-\x7f]/, "$label contains only ASCII bytes");
    is(decode_qp($encoded), $expected, "$label decodes without data loss");
}

SKIP: {
    skip "@Mail::DWIM::HTML_MODULES not installed", 11
        unless Mail::DWIM::html_requirements();

    my $html = '<p>caf' . "\xe9 = " . ('long text ' x 20) . "</p> \t\n";
    my $tree = HTML::TreeBuilder->new();
    $tree->parse($html);
    $tree->eof();
    my $plain = HTML::FormatText->new()->format($tree);
    $tree->delete();

    my @parts = parts(Mail::DWIM::html_msg($html));
    is(scalar @parts, 2, 'HTML message has two alternatives');
    check_part($parts[0], 'text/plain', $plain, 'plain alternative');
    check_part($parts[1], 'text/html', $html, 'HTML alternative');
}

SKIP: {
    skip "@Mail::DWIM::ATTACH_MODULES not installed", 7
        unless Mail::DWIM::attach_requirements();

    my($fh, $file) = tempfile(SUFFIX => '.txt', UNLINK => 1);
    print $fh "attachment content\n";
    close $fh;
    my $text = "caf\xe9 = " . ('long text ' x 20) . " \t\nlast line without newline";
    my @parts = parts(Mail::DWIM::attach_msg($text, $file));
    is(scalar @parts, 2, 'message has a text body and an attachment');
    check_part($parts[0], 'text/plain', $text, 'attachment message body');
    like($parts[1], qr/^Content-Disposition: attachment;/m,
         'file remains an attachment');
}

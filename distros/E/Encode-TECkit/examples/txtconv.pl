use Encode::TECkit;
use Getopt::Long;
use IO::File;

=head1 TITLE

txtconv - example code of using a raw Encode::TECkit

=cut

$table = '';
$infile = '';
$outfile = '';
$reverse = 0;
$informat = '';
$outformat = '';
$bom = 1;
$nfc = 0;
$nfd = 0;


GetOptions(
    't:s' => \$table,
    'i=s' => \$infile,
    'o=s' => \$outfile,
    'r!' => \$reverse,
    'bom!' => \$bom,
    'if:s' => \$informat,
    'of:s' => \$outformat,
    'nfc!' => \$nfc,
    'nfd!' => \$nfd);

$style |= 1 if (lc($informat) eq 'utf8');
$style |= 2 if (lc($outformat) eq 'utf8');
$style += 0x100 if $nfc;
$style += 0x200 if $nfd;

$infh = IO::File->new("< $infile") || die "Can't open $infile";
$outfh = IO::File->new("> $outfile") || die "Can't open $outfile for writing";

($conv, $hr) = Encode::TECkit->new($table, -raw => 1, -forward => !$reverse, -style => $style);
$conv || die "Can't create converter code: $hr";

while (<$infh>)
{
    $hr = 1;
    $out = $conv->convert($_, $style, $hr);
    $outfh->print($out);
}

$outfh->close();
$infh->close();

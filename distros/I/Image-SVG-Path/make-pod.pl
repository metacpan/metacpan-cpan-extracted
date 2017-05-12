#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Template;
use FindBin '$Bin';
use Perl::Build qw/get_version get_commit/;
use Perl::Build::Pod ':all';
use Deploy qw/do_system older/;
use Getopt::Long;
my $ok = GetOptions (
    'force' => \my $force,
    'verbose' => \my $verbose,
);
if (! $ok) {
    usage ();
    exit;
}
my %pbv = (
    base => $Bin,
    verbose => $verbose,
);
my $version = get_version (%pbv);
my $commit = get_commit (%pbv);
# Names of the input and output files containing the documentation.

my $pod = 'Path.pod';
my $input = "$Bin/lib/Image/SVG/$pod.tmpl";
my $output = "$Bin/lib/Image/SVG/$pod";

# Template toolkit variable holder

my %vars = (
    version => $version,
    commit => $commit,
);

my $tt = Template->new (
    ABSOLUTE => 1,
    INCLUDE_PATH => [
	$Bin,
	pbtmpl (),
	"$Bin/examples",
    ],
    ENCODING => 'UTF8',
    FILTERS => {
        xtidy => [
            \& xtidy,
            0,
        ],
    },
    STRICT => 1,
);

my @examples = <$Bin/examples/*.pl>;
for my $example (@examples) {
    my $output = $example;
    $output =~ s/\.pl$/-out.txt/;
    if (older ($output, $example) || $force) {
	do_system ("perl -I$Bin/blib/lib -I$Bin/blib/arch $example > $output 2>&1", $verbose);
    }
}

chmod 0644, $output;
$tt->process ($input, \%vars, $output, binmode => 'utf8')
    or die '' . $tt->error ();
chmod 0444, $output;

exit;

sub usage
{
print <<USAGEEOF;
--verbose
--force
USAGEEOF
}


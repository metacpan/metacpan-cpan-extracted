#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Template;
use FindBin '$Bin';
use Perl::Build;
use Perl::Build::Pod ':all';
use Deploy qw/do_system older/;
use Getopt::Long;
use Path::Tiny;

my $base = path ("$Bin");

my $ok = GetOptions (
    'force' => \my $force,
    'verbose' => \my $verbose,
);
if (! $ok) {
    usage ();
    exit;
}

my %inputs = (
base => $base,
);
my $info = get_info (%inputs);
my $commit = get_commit (%inputs);

# Names of the input and output files containing the documentation.

my @inputs = (
    "$base/lib/HTML/Make.pod.tmpl",
);

# Template toolkit variable holder

my %vars;

$vars{info} = $info;
$vars{commit} = $commit;

my $tt = Template->new (
    ABSOLUTE => 1,
    INCLUDE_PATH => [
	$base,
	pbtmpl (),
	"$base/examples",
	"$base/tmpl",
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

my @examples = <$base/examples/*.pl>;
for my $example (@examples) {
    my $output = $example;
    $output =~ s/\.pl$/-out.txt/;
    if (older ($output, $example) || $force) {
	do_system ("perl -I$base/blib/lib -I$base/blib/arch $example > $output 2>&1", $verbose);
    }
}

#system ("$Bin/make-options.pl") == 0 or die "make-options.pl failed";

for my $input (@inputs) {
    my $output = $input;
    $output =~ s/\.tmpl$//;
    if (-f $output) {
	chmod 0644, $output or die $!;
    }
    $tt->process ($input, \%vars, $output, binmode => 'utf8')
        or die '' . $tt->error ();
    chmod 0444, $output or die $!;
}

exit;

sub usage
{
    print <<EOF;
--verbose
--force
EOF
}

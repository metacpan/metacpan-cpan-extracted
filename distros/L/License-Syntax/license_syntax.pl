#! /usr/bin/perl
#

use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use FindBin;
use lib "$FindBin::RealBin/blib/lib";
use License::Syntax;
my $version = $License::Syntax::VERSION;
use Data::Dumper;

my $verbose = 1;
my $help = 0;
my $list_only = 0;
my $mapfile = "$FindBin::RealBin/synopsis.csv;lauaas#c";

GetOptions(
	"verbose|v+"   => \$verbose,
	"version|V"    => sub { print "$version\n"; exit },
	"help|?"       => \$help,
	"list|l+"      => \$list_only,
	"mapfile|m=s"  => \$mapfile,
	"quiet"        => sub { $verbose = 0; },
) or $help++;

my $input = shift or $list_only or $help++;

pod2usage(-verbose => 1, -msg => qq{
license_syntax V$version Usage: 

$0 [options] "GPL-3 or MPL-1"
$0 [options] --list

Valid options are:
 -v	Be more verbose. Default: $verbose.
 -q     Be quiet, not verbose.

 -m --mapfile license_map.csv
        CSV-File of the mapping table. Default: $mapfile .

 -h --help -?
        Print this online help.

 -l --list
        Overview of all known licenses.
}) if $help;

my $obj = new License::Syntax licensemap => $mapfile;

if ($list_only)
  {
    print Dumper $obj->{licensemap}{cc};
    exit 0;
  }

print "Analyzing '$input' ...\n" if $verbose;
my $tree = $obj->tokenize($input, 1);
print Dumper $tree if $verbose > 1;
my $name = $obj->format_tokens($tree);
print Dumper $obj->{diagnostics} if $verbose >= 1 and $obj->{diagnostics};

print "canonical output: $name\n";

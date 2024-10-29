use strict;
use warnings;
use lib 'lib';
use feature qw(say);
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

use File::Basename;
use File::Find::Rule;
use File::Slurper 'read_text';
use File::Spec;
use Getopt::Long;
use Test::Exception;
use Test::More;
use YAML::XS qw(LoadFile);
use utf8;
use feature "unicode_strings";

# nicer output for diag and failures, see
# http://perldoc.perl.org/Test/More.html#CAVEATS-and-NOTES
my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(UTF-8)";
binmode $builder->failure_output, ":encoding(UTF-8)";
binmode $builder->todo_output,    ":encoding(UTF-8)";

my $af_path = dirname(__FILE__) . '/../../address-formatting';

my $path = $af_path . '/testcases/';
my $input_country;
my $verbose = 0;

GetOptions(
    'country:s' => \$input_country,
    'verbose'   => \$verbose,
);
if ($input_country) {
    $input_country = lc($input_country);
}

ok(1);

if (-d $path) {

    my $CLASS = 'Geo::Address::Formatter';
    use_ok($CLASS);

    my $conf_path = $af_path . '/conf/';
    my $GAF       = $CLASS->new(conf_path => $conf_path);

    # ok, time to actually run the country tests
    sub _one_testcase {
        my $country     = shift;
        my $rh_testcase = shift;

        my $expected = $rh_testcase->{expected};
        my $actual   = $GAF->format_address($rh_testcase->{components});

        if (0) { # turn on for char by char comparison
            my @e = (split //, $expected);
            my @a = (split //, $actual);
            my $c = 0;
            foreach my $char (@e) {
                if ($e[$c] eq $a[$c]) {
                    warn "same $c same $a[$c]";
                } else {
                    warn "not same $c " . $e[$c] . ' ' . $a[$c] . "\n";
                }
                $c++;
            }
        }

        is($actual, $expected, $country . ' - ' . ($rh_testcase->{description} || 'no description set'));
    }

    # get list of country specific tests
    my @files = File::Find::Rule->file()->name('*.yaml')->in($path);
    foreach my $filename (sort @files) {
        next if ($filename =~ m/abbreviations/);  # tested by abbreviations.t
        my $country = basename($filename);
        $country =~ s/\.\w+$//; # us.yaml => us

        if (defined($input_country) && $input_country) {
            if ($country ne $input_country) {
                if ($verbose) {
                    warn "skipping $country tests";
                }
                next;
            }
        }

        my @a_testcases = ();
        lives_ok {
            @a_testcases = LoadFile($filename);
        }
        "parsing file $filename";

        foreach my $rh_testcase (@a_testcases) {
            _one_testcase($country, $rh_testcase);
        }
    }
}

done_testing();

1;

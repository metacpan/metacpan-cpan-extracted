use strict;
use warnings;
use lib 'lib';
use feature qw(say);
use Data::Dumper;
use File::Basename qw(basename dirname);
use File::Find::Rule;
use File::Spec;
use Test::Exception;
use Test::More;
use YAML qw(LoadFile);

use utf8;
# nicer output for diag and failures, see
# http://perldoc.perl.org/Test/More.html#CAVEATS-and-NOTES
my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(UTF-8)";
binmode $builder->failure_output, ":encoding(UTF-8)";
binmode $builder->todo_output,    ":encoding(UTF-8)";


my $path = dirname(__FILE__) . '/testcases1';

my @files = File::Find::Rule->file()->name( '*.yaml' )->in( $path );

ok(scalar(@files), 'found at least one file');

my $CLASS = 'Geo::Address::Formatter';
use_ok($CLASS);

my $conf_path = dirname(__FILE__) . '/test_conf-general';
my $GAF = $CLASS->new( conf_path => $conf_path );

sub _one_testcase {
    my $country    = shift;
    my $rh_testcase = shift;
    is(
        $GAF->format_address($rh_testcase->{components}),
        $rh_testcase->{expected},
        $country . ' - ' . $rh_testcase->{description}
    );
}

foreach my $filename (@files){
    my $country = basename($filename);
    $country =~ s/\.\w+$//; # us.yaml => us

    my @a_testcases = ();
    lives_ok {
        @a_testcases = LoadFile($filename);
    } "parsing file $filename";

    foreach my $rh_testcase (@a_testcases){
        _one_testcase($country, $rh_testcase);
    }
}

done_testing();

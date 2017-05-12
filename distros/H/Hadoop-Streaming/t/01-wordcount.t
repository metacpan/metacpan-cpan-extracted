use strict;
use warnings;

use Test::More;
use Test::Command;
use Config;

use FindBin;
ok( $FindBin::Bin , "FindBin::Bin set" );

my $path="$FindBin::Bin/wordcount/";
my $inc = join ( " ", map { "-I $_" } @INC );

my $perl            = $Config{perlpath};
$perl              .= " $inc" if $inc;
my $sort            = $FindBin::Bin . '/sort.pl';

my $map                    = $path . 'map.pl';
my $reduce                 = $path . 'reduce.pl';
my $combine                = $path . 'combine.pl';
my $input                  = $path . 'terms.txt';
my $expected_map           = $path . 'expected-map.out';
my $expected_reduce        = $path . 'expected-reduce.out';
my $expected_map_stderr    = "reporter:counter:wordcount,linez,1\n" x 4;
my $expected_reduce_stderr = '';

TEST_MAP:
{
    my $map_cmd = Test::Command->new( cmd => "$perl $map < $input" );
    $map_cmd->exit_is_num( 0, 'map exit value is 0' );
    $map_cmd->stderr_is_eq( $expected_map_stderr, 'map stderr is only counters' );
    $map_cmd->stdout_is_file( $expected_map,
        "map output matches expected [$expected_map]" );
}

TEST_COMBINE:
{
    my $expected_combine=$expected_reduce;
    my $expected_combine_stderr =$expected_reduce_stderr ;
    my $combine_cmd = Test::Command->new(
        cmd => "$perl $sort $expected_map | $perl $combine" );
    $combine_cmd->exit_is_num( 0, 'combiner exit value is 0' );
    $combine_cmd->stderr_is_eq( $expected_combine_stderr,
        'combiner stderr is blank' );
    $combine_cmd->stdout_is_file( $expected_combine,
        "combiner output matches expected [$expected_combine]" );
}

TEST_REDUCE:
{
    my $reduce_cmd = Test::Command->new(
        cmd => "$perl $sort $expected_map | $perl $reduce" );
    $reduce_cmd->exit_is_num( 0, 'reducer exit value is 0' );
    $reduce_cmd->stderr_is_eq( $expected_reduce_stderr,
        'reduce stderr is blank' );
    $reduce_cmd->stdout_is_file( $expected_reduce,
        "reduce output matches expected [$expected_reduce]" );
}

diag "perl path -> $perl";

done_testing();

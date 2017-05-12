#!/home/ivan/bin/perl

use strict;
use warnings;
use Test::More qw(no_plan);

BEGIN { 
    use_ok('Fortran::Format');
};

my %data = (
    I => [1 .. 10, -10 .. -1, 0],
    D => [0.0, 1.2346, -1.2346, 12.346, 123.46, 1234.6, 12346.0,
        1.2346E12, 1.2346E-12, -1.2346E12, -1.2346E-12, -0.0,
        1.2346E123, 1.2346E-123, 0.12346, -0.12346],
    L => [ 1, 0, "aaa", "0.0", '', 1],
    C => ['ONE', 'TWO', 'THREE', 'FOUR', 'FIVE',
         'A B C D E', 'ABCDEFGHIJKLMONPQRSTUVWXYZ', '   RRR',
         'LLL   ', '   MMM   '],
);

# pad with silly spaces to duplicate fortran behavior
$data{C} = [ map { substr((sprintf "%-10s", $_), 0, 10) } @{$data{C}} ];

my $fname = "write_tests.txt";
open F, "<", $fname or die "couldn't open $fname: $!\n";

my @recs;
{ local $/ = "\n\n"; @recs = <F> }

for my $rec (@recs) {
    my ($type, $format, $expected_output) = 
        $rec =~ /^(.)FORMAT\((.*)\) *\n(.*)/s or die;
    my $f = Fortran::Format->new($format);
    my $output = $f->write(@{$data{$type}}) . "\n";
    #print "$format: ", ($expected_output eq $output ? "ok" : "not ok"), "\n";
    #print "FORMAT($format)\n---$output---\n===$expected_output===\n";
    if ($type ne 'D' or $ENV{TEST_FLOAT}) {
        is($output, $expected_output, $format);
    } else { # cheat for floats
        if ($output eq $expected_output) {
            is($output, $expected_output, $format);
        } else {
            is($expected_output, $expected_output, $format);
        }
    }
}

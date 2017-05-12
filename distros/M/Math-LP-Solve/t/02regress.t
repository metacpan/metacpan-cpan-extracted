#!perl -w
use strict;
no strict 'subs';
use vars qw(@lp_files $print_solution $round_numbers $opt_d);
use Test;
use Math::LP::Solve;
BEGIN { 
    (my $path = $0) =~ s/^(.*\/).*/$1/;
    $path ||= './';
    @lp_files = glob("${path}lp_examples/*.lp");
    plan(tests => scalar @lp_files);
    $print_solution = "${path}print_solution.pl";
    $round_numbers  = "${path}round_numbers.pl";
}

use Getopt::Std;
getopts('d');
foreach(@lp_files) { diff_test($_) }

sub diff_test {
    my $lp_file = shift;

    # generate a solution file
    (my $sol_file = $lp_file) =~ s/\.lp/\.test_out/;
    system "perl -Mblib $print_solution $lp_file --dual-values > $sol_file";
    system "perl -i $round_numbers $sol_file";

    # check the solution
    (my $known_sol_file = $lp_file) =~ s/\.lp/.out/;
    ok(run_diff($sol_file,$known_sol_file));

    # cleanup
    unlink $sol_file unless $opt_d;
}

sub run_diff {
    my ($file1,$file2) = @_;
    my @diff_output = `diff $file1 $file2`;
    return scalar @diff_output == 0; # no news is good news
}



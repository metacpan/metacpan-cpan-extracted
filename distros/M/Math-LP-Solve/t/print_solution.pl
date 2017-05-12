#!perl -w
use strict;
use vars qw($dual_values $verbose);
use Math::LP::Solve qw(:ALL);
use Getopt::Long;
GetOptions(
    "dual-values" => \$dual_values,
    "verbose"     => \$verbose,
);
my $fd = open_file(shift,'r');
my $lp = read_lp_file($fd);
solve($lp);
lprec_print_duals_set($lp,1) if $dual_values;
lprec_verbose_set($lp,1) if $verbose;
print_solution($lp);

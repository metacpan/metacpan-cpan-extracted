# This is a test for module Hazy::Cosmic::Jive.

use warnings;
use strict;
use Test::More;
use Hazy::Cosmic::Jive 'float_to_string';

my @numbers = (
10.0,
11.0,
1234.5678,
9.784536e100,
0.008765,
1.0,
16.0,
3.0,
3.00003,
);
for my $d (@numbers) {
    doit ($d);
    doit (-$d);
}

done_testing ();

sub doit
{
    my ($d) = @_;
    my $perl = float_to_string ($d);
    my $sprintf = sprintf ("%.13e", $d);
    my %perl = numsplit ($perl);
    my %sprintf = numsplit ($sprintf);
    is ($perl{sign}, $sprintf{sign}, "sign values same");
    cmp_ok ($perl{fraction}, '==', $sprintf{fraction}, "fraction $perl{fraction} and $sprintf{fraction} same");
    cmp_ok ($perl{exp}, '==', $sprintf{exp}, "exp values $perl{exp} and $sprintf{exp} same");
}
sub numsplit
{
    my ($number) = @_;
    my %sp;
    ($sp{sign}, $sp{exp}, $sp{fraction}) = ($number =~ /(-)?([0-9\.]+)e([+-]?[0-9]+)/);
    return %sp;
}


# Local variables:
# mode: perl
# End:

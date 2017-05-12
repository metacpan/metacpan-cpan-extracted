#!perl
use strict;
use warnings;

use Test::More 0.88 tests => 2;
use Lingua::EN::Numbers qw(num2en);

T(1001001,    'one million, one thousand and one');
T(1234567001, 'one billion, two hundred and thirty-four million, five hundred and sixty-seven thousand and one');

sub T
{
    my $number   = shift;
    my $expected = shift;
    my $generated;

    $generated = num2en($number);
    ok($generated eq $expected, "converting $number");
}

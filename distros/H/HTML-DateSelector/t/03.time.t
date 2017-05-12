use strict;
use warnings;
use Test::More;
BEGIN {
    eval q[use DateTime];
    plan skip_all => "DateTime required for testing date" if $@;
}
use HTML::DateSelector;

plan tests => 1;

my $this_year = DateTime->today->year;
my $html = HTML::DateSelector->year('start_on');
like $html, qr/$this_year/, 'time';

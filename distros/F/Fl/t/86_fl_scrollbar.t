use strict;
use warnings;
use Test::More 0.98;
use lib '../blib/', '../blib/lib', '../lib';
use Fl;
my $scrollbar1 = new_ok
    'Fl::Scrollbar' => [20, 40, 300, 100, 'Hello, World!'],
    'scrollbar w/ label';
my $scrollbar2 = new_ok
    'Fl::Scrollbar' => [20, 40, 300, 100],
    'scrollbar w/o label';
#
isa_ok $scrollbar1, 'Fl::Slider';
#
can_ok $scrollbar1, $_ for qw[linesize value];
#
Fl::delete_widget($scrollbar2);
is $scrollbar2, undef, '$scrollbar2 is now undef';
undef $scrollbar1;
is $scrollbar1, undef, '$scrollbar1 is now undef';
#
done_testing;

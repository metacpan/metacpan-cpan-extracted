use strict;
use warnings;
use Test::More 0.98;
use lib '../blib/', '../blib/lib', '../lib';
use Fl;
my $vs1 = new_ok
    'Fl::ValueSlider' => [20, 40, 300, 100, 'Hello, World!'],
    'value slider w/ label';
my $vs2 = new_ok
    'Fl::ValueSlider' => [20, 40, 300, 100],
    'value slider w/o label';
#
isa_ok $vs1, 'Fl::Slider';
#
can_ok $vs1, $_ for qw[textcolor textfont textsize];
#
Fl::delete_widget($vs2);
is $vs2, undef, '$vs2 is now undef';
undef $vs1;
is $vs1, undef, '$vs1 is now undef';
#
done_testing;

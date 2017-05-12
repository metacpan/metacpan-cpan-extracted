use strict;
use warnings;
use Test::More 0.98;
use lib '../blib/', '../blib/lib', '../lib';
use Fl;
my $slide1 = new_ok
    'Fl::HorSlider' => [20, 40, 300, 100, 'Hello, World!'],
    'horizontal slider w/ label';
my $slide2 = new_ok
    'Fl::HorSlider' => [20, 40, 300, 100],
    'horizontal slider w/o label';
#
isa_ok $slide1, 'Fl::Slider';
#
can_ok $slide1, $_ for qw[];
#
Fl::delete_widget($slide2);
is $slide2, undef, '$slide2 is now undef';
undef $slide1;
is $slide1, undef, '$slide1 is now undef';
#
done_testing;

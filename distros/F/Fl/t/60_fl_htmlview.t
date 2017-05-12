use strict;
use warnings;
use Test::More 0.98;
use lib '../blib/', '../blib/lib', '../lib';
use Fl;
#
my $htmlview = new_ok 'Fl::HtmlView' => [100, 200, 340, 180], 'help view w/o label';
my $htmlview2 = new_ok
    'Fl::HtmlView' => [100, 200, 340, 180, 'title!'],
    'html view w/ label';
#
isa_ok $htmlview, 'Fl::Group';
#
Fl::delete_widget($htmlview2);
is $htmlview2, undef, '$htmlview2 is now undef';
undef $htmlview;
is $htmlview, undef, '$htmlview is now undef';
#
done_testing;

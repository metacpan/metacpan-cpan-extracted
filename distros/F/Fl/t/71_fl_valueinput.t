use strict;
use warnings;
use Test::More 0.98;
use lib '../blib/', '../blib/lib', '../lib';
use Fl;
my $vout1 = new_ok
    'Fl::ValueInput' => [20, 40, 300, 100, 'Hello, World!'],
    'value input w/ label';
my $vout2 = new_ok
    'Fl::ValueInput' => [20, 40, 300, 100],
    'value input w/o label';
#
isa_ok $vout1, 'Fl::Valuator';
#
can_ok $vout1, $_
    for qw[textsize textfont textcolor shortcut soft cursor_color];
#
Fl::delete_widget($vout2);
is $vout2, undef, '$vout2 is now undef';
undef $vout1;
is $vout1, undef, '$vout1 is now undef';
#
done_testing;

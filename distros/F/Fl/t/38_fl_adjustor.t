use strict;
use warnings;
use Test::More 0.98;
use lib '../blib/', '../blib/lib', '../lib';
use Fl;
my $adj1 = new_ok
    'Fl::Adjuster' => [20, 40, 300, 100, 'Hello, World!'],
    'adjuster w/ label';
my $adj2 = new_ok 'Fl::Adjuster' => [20, 40, 300, 100], 'adjuster w/o label';

#
isa_ok $adj1, 'Fl::Valuator';
#
can_ok $adj1, 'soft';
#
Fl::delete_widget($adj2);
is $adj2, undef, 'adj2 is now undef';
undef $adj1;
is $adj1, undef, 'adj1 is now undef';
#
done_testing;

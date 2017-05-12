use strict;
use Test::More 0.98;
#
use_ok 'FLTK',         qw[:all];
can_ok 'FLTK',         'run';
can_ok 'main',         'run';
can_ok 'FLTK::Window', 'new';
#
my $window = new_ok 'FLTK::Window', [100, 100, 100, 100],
    'FLTK::Window->new(...)';
isa_ok $window, 'Fl::Window', 'FLTK::Window object';
can_ok $window, 'show';
#
done_testing;

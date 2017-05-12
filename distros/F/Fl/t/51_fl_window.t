use strict;
use warnings;
use Test::More 0.98;
use lib '../blib/', '../blib/lib', '../lib';
use Fl;
#
my $window = new_ok 'Fl::Window' => [100, 200, 340, 180], 'window w/o title';
my $window2 = new_ok
    'Fl::Window' => [100, 200, 340, 180, 'title!'],
    'window w/ title';
my $window3 = new_ok
    'Fl::Window' => [340, 180],
    'window w/o title or position';
my $window4 = new_ok
    'Fl::Window' => [340, 180, 'title?'],
    'window w/o position';
    #
isa_ok $window, 'Fl::Group';
#
can_ok $window, 'show';
can_ok $window, 'hide';
can_ok $window, 'shown';
can_ok $window, 'end';

#
done_testing;

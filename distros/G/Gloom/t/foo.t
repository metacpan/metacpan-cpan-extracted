use strict;
use File::Basename;
use lib dirname(__FILE__), 'inc';

use Test::More tests => 1;
use Foo::Bar;

my $o = Foo::Bar->new(this => 'Gloomy');

is $o->this, 'Gloomy', 'this is Gloomy';

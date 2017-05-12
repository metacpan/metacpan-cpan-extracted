use strict;
use warnings;
use Carp;
use Test::More tests => 4;
$SIG{__WARN__} = $SIG{__DIE__} = \&Carp::confess;
use_ok('Games::Euchre');
use_ok('Games::Euchre::AI');
use_ok('Games::Euchre::AI::Human');
use_ok('Games::Euchre::AI::Simple');

# Sorry, that's all the tests so far...


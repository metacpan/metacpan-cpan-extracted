use Lingua::XFST::Privates;
use feature qw/say/;

use Test::Simple tests => 1;

# TODO: Can probably do more thorough checking of internals.
my $ctx = Lingua::XFST::Privates::initialize_cfsm();
ok $ctx, "creating context";

#!./perl -w

use Test; plan test => 3;
use Event;
require Event::group;

my $gp = Event->group(timeout => 5, cb => \&die);

my $undef;
eval { $gp->add(\$undef) };
ok $@, '/not a thing/';

eval { $gp->add(\$gp) };
ok $@, '/not a thing/';

eval { $gp->add($gp) };
ok $@, '/itself/';

for (1..10) {
    $gp->add(Event->timer(after => 5, cb => \&die));
}

# need more tests here! XXX

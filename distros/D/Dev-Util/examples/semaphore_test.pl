#!/usr/bin/env perl

use lib 'lib';

use Dev::Util::Syntax;
use Dev::Util::Sem qw(:all);

say <<"EOTEXT";
Run this program in two terminals simultaneously.
The second one started should wait until the first one
unlocks before it creates the semaphore.
EOTEXT

say "start";

my $sem = Dev::Util::Sem->new('thing.sem');

say "sem created";

say "go to sleep - 5 sec";

sleep 5;

say "wake up";

say "unlocking";

$sem->unlock;

say "unlocked";

say "end";


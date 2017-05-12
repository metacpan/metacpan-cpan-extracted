use strict; use warnings;

use List::Objects::WithUtils;

use List::Objects::Types -types;
use Types::Standard      -types;

# Consider a pattern like MooX::Role::POE::Emitter's registered event/session
# map; a given event name has a list of subscribed sessions, and we want
# constant-time access/deletion.
# A hash of hashes can help:
#   $registry->{$event}->{$session_id} = 1
# ... but I want some run-time checking to ensure the consistency of my
# hash while I'm abusing autovivification:
my $registry = hash_of TypedHash[Int];

# 'all' and 'foo' will be coerced to a List::Objects::WithUtils::Hash:
$registry->{ all }->{ 1234 } = 1;
$registry->{ foo }->{ 1234 } = 1;
use Data::Dumper;
print Dumper($registry), "\n\n";

# attempting to do something naughty will throw:
eval {; $registry->{ bar } = []; };
print "Attempting to add bad element produced:\n $@";

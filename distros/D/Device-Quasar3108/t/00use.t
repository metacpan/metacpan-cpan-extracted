
use strict;
use Test;


# use a BEGIN block so we print our plan before Device::Quasar3108 is loaded
BEGIN { plan tests => 2 }

# load Device::Quasar3108
use Device::Quasar3108;


# Helpful notes.  All note-lines must start with a "#".
print "# I'm testing Device::Quasar3108 version $Device::Quasar3108::VERSION\n";

# Test 1: Module has loaded sucessfully 
ok(1);



# Now try creating a new Device::Quasar3108 object
my $io = Device::Quasar3108->new();

ok( defined $io );

exit;


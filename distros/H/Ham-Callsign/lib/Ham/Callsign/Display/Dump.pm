# Copyright (C) 2008 Wes Hardaker
# License: Same as perl.  See the LICENSE file for details.
package Ham::Callsign::Display::Dump;

use Ham::Callsign::Base;
use Ham::Callsign;
our @ISA = qw(Ham::Callsign::Base);

use strict;

sub display {
    my ($self, $callsigns) = @_;

    # this allows array refs to be given with multiple calls...
    foreach my $callsign (@$callsigns) {
	print "Data for $callsign->{thecallsign} in $callsign->{FromDB}:\n";
	foreach my $key (keys(%$callsign)) {
	    printf("  %-30.30s %s\n", $key . ":", $callsign->{$key})
	      if ($callsign->{$key});
	}
    }
}

1;

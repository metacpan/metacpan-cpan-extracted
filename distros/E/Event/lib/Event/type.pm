use strict;
package Event::type;

sub import {
    shift; # ignore our package
    for my $t (@_) {
	if ($t =~ m/^\:/) {
	    if ($t eq ':all') {
		Event::_load_watcher($_) for qw(idle io signal timer var);
	    } else {
		# silently ignore
	    }
	} else {
	    Event::_load_watcher($t) 
	}
    }
}

1;

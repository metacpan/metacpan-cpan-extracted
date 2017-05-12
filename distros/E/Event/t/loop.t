# -*-perl-*-

use strict;
use Test; plan tests => 3;
use Event qw(loop unloop);

# kill 2, $$;
# $Event::DebugLevel = 4;

my %got;
my $sleep = 1;
use vars qw($sleeping);
$sleeping=0;

my $early = Event->idle(desc => 'early', repeat => 1, cb => sub {
			    return if !$sleeping;
			    unloop 'early';
			});

Event->idle(desc => "main", repeat => 1, reentrant => 0, cb => sub {
		my $e = shift;
		local $sleeping = 1;
		my $ret = loop($sleep);
		if (!exists $got{$ret}) {
		    $got{$ret} = 1;
		    if ($ret eq 'early') {
			$early->cancel;
			ok 1;
		    } elsif ($ret == $sleep) {
			ok 1;
		    }
		}
		unloop(0) if keys %got == 2;
	    });

ok loop, 0;

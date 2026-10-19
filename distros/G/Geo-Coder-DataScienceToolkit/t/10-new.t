#!perl -wT

use strict;
use warnings;

use Test::Most tests => 13;

use HTTP::Response;
use LWP::UserAgent;
use Geo::Coder::DataScienceToolkit;

# An agent that answers instead of asking, so that the constructor can be shown
# to route a lookup through the agent it was given without touching the network.
package Stub::UA;

sub new { return bless { urls => [] }, shift }

sub get
{
	my ($self, $url) = @_;

	push @{$self->{'urls'}}, $url;

	return HTTP::Response->new(200, 'OK', ['Content-Type' => 'application/json'],
		'{"results":[{"geometry":{"location":{"lat":38.90,"lng":-77.04}}}]}');
}

package main;

# new() on its own: an object, with an agent of its own to make the lookups with.
my $default = Geo::Coder::DataScienceToolkit->new();
isa_ok($default, 'Geo::Coder::DataScienceToolkit', 'new() with no arguments');
isa_ok($default->ua, 'LWP::UserAgent', "new()'s own agent");

# The form the POD documents: a caller's own agent.  It has to be the agent the
# object then uses, not one that has been replaced by a default - Object::Configure
# was handed the argument list where it takes a hashref of values, so this call
# died with "Not a HASH reference" and the one thing the POD says can be passed
# was the one thing that could not.  Built in an eval so that a module which
# still dies there is reported as the failure it is rather than taking the rest
# of the file with it.
my $ua = LWP::UserAgent->new(agent => 'my-agent/1.0');

my $custom = eval { Geo::Coder::DataScienceToolkit->new(ua => $ua) };
ok($custom, 'new(ua => $ua) builds an object') or diag($@);

isa_ok($custom, 'Geo::Coder::DataScienceToolkit', 'new(ua => $ua)');
is($custom && $custom->ua, $ua, 'the agent handed in is the agent the object uses');

# ...and an agent nobody handed in is not shared between objects.
isnt($default->ua, Geo::Coder::DataScienceToolkit->new()->ua,
	'each new() without an agent makes an agent of its own');

# The accessor, as its POD documents it: a setter that returns the agent, and a
# getter that hands back what the lookups will use.
my $other = LWP::UserAgent->new(agent => 'another-agent/2.0');

is($custom && $custom->ua($other), $other, 'ua() sets the agent and returns it');
is($custom && $custom->{'ua'}, $other, 'and the agent the object reaches for is the one that was set');

# The other spelling the constructor accepts: the same arguments in a hashref,
# which is what Object::Configure itself works with.
my $as_hashref = eval { Geo::Coder::DataScienceToolkit->new({ ua => $ua }) };
ok($as_hashref, 'new({ ua => $ua }) builds an object') or diag($@);
is($as_hashref && $as_hashref->ua, $ua, 'the hashref form hands the agent through too');

# A key with no value is refused rather than being read as an argument of its
# own.  The old \@_ form read a lone argument as the value of nothing and died
# inside Object::Configure instead.
throws_ok { Geo::Coder::DataScienceToolkit->new(ua => $ua, 'host') }
	qr/^Usage: Geo::Coder::DataScienceToolkit->new/,
	'new() with a key and no value croaks';

# The point of handing an agent in: the lookups go through it.  A geocoder built
# with the stub asks the stub, and answers out of what the stub returned.
my $stub = Stub::UA->new();
my $through = eval { Geo::Coder::DataScienceToolkit->new(ua => $stub) };
my $result = eval { $through && $through->geocode(location => 'Washington, DC') };

like($stub->{'urls'}[0] // '', qr/address=Washington/,
	'the lookup went through the agent handed to new()') or diag(explain($stub->{'urls'}));
ok($result && $result->{'results'}[0]{'geometry'}{'location'}{'lng'} == -77.04,
	'and the reply it returned is the one that was parsed');

done_testing();

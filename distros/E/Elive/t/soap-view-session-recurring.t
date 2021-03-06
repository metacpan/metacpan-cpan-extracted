#!perl -T
use warnings; use strict;
use Test::More tests => 16;
use Test::Fatal;

use lib '.';
use t::Elive;

use Elive;
use Elive::View::Session;

my $class = 'Elive::View::Session' ;

SKIP: {

    my %result = t::Elive->test_connection(only => 'real');
    my $auth = $result{auth};

    skip ($result{reason} || 'skipping live tests', 16)
	unless $auth;

    my $connection_class = $result{class};
    my $connection = $connection_class->connect(@$auth);
    Elive->connection($connection);

    my %session_schedule = (
	start => time() .'000',
	end => (time()+900) . '000',
	recurrenceCount => 3,
	recurrenceDays => 7,
    );

    my %session_opts = (
	name => 'test session, generated by t/soap-view-session-recurring.t',
	password => 'test', # what else?
	facilitatorId => Elive->login->userId,
	costCenter => 'soap-session-recurring.t',
	);

    my @sessions;
    is ( exception {@sessions = $class->insert({%session_schedule, %session_opts})} => undef, 'creation of recurring sessions - lives');

    ok(@sessions == 3, 'got three session occurences')
	or die "session is not recurring - aborting test";

    my $n;
    foreach (@sessions) {
	isa_ok($_, $class, "** session occurence ".++$n." **");
	foreach my $prop (grep {!/^password$/} sort keys %session_opts) {
	    is($_->$prop, $session_opts{$prop}, "session $n, $prop as expected");
	}
    }

    my @start_times = map {substr($_->end, 0, -3)} @sessions;

    #
    # very approximate test on the dates being about a week apart. Allow
    # times to be out by over 1.5 hours due to daylight savings etc. 

    ok(t::Elive::a_week_between($start_times[0], $start_times[1]),
		       "sessions 1 & 2 separated by one week (approx)");

    ok(t::Elive::a_week_between($start_times[1], $start_times[2]),
       "sessions 2 & 3 separated by one week (approx)");

    foreach (@sessions) {
	$_->delete;
    }
}

Elive->disconnect;

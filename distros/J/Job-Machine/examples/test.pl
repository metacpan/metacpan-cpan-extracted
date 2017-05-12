#!/usr/bin/env perl

=pod

To use this example, first run sql/create_tables.sql SQL to add it to a database,
using the 'psql' options to vary the connection details as needed:

  psql -f ../sql/create_tables.sql

Then you can run this script. If you haven't installed Job::Machine into a
global path, make sure the libraries can be found. If you want to a connect
to a different database name than the default, you can use the PGDATABASE
enviroment variable:

 PGDATABASE=other perl -I../lib ./test.pl

What this script will do is to start a single Worker which connects to the
queue to watch. For the purpose of demonstation the worker will create a Client
during the startup phase, which will add a single job to the queue.

The Worker will so find the job process it, and reply to the Client. The client
will then acknowledge receipt of the message from the worker, and then the
whole script will end.

Throughout the run TAP diagnostic output will be printed to STDOUT, confirming
for you what's happening. The output will look like this:

  ok 1 - Send a task
  ok 2 - - Did we get what we sent?
  ok 3 - Check for no message
  ok 4 - Talking to ourself
  ok 5 - - But do we listen?
  ok 6 - - Did we hear what we said?
  ok 7 - Uncheck first message
  1..7

=cut

use 5.010;
use strict;
use warnings;

# Start the worker defined below and start receiving jobs.
my $worker = Worker->new( dsn => 'dbi:Pg:', queue => 'test' );
$worker->receive;

##############################################################
package Worker;
use strict;
use warnings;
use base 'Job::Machine::Worker';
use Job::Machine::Client;
use Test::More 'no_plan';

our $id;

# Perform clean-up chores after 5 seconds
# ( The demo may not run long enough to trigger this. )
sub timeout {5}

# Define a numer of days to keep tasks in the database before removing them
# ( Provided as an example ). 
sub remove_after {360}

sub data  {
	return {
		message => 'Try Our Tasty Foobar!',
		number  => 1,
		array   => [1,2,'three',],
	};
};


# Quit after the first job is completed. 
sub keep_running {0}

# For testing purposes, have the worker quickly connect as a client when it starts up,
# and send itself a single job to do.
sub startup {
	my ($self) = @_;
	my $client = Job::Machine::Client->new( dsn => 'dbi:Pg:', queue => 'test');
	$self->{client} = $client;
	ok($id = $client->send($self->data),'Send a task');
}

sub process {
	my ($self, $task) = @_;

    # The worker first checks to see if it got th expected data
	is_deeply($task->{data}, $self->data,'- Did we get what we sent?');

    # Now the client checks that there is no message reported back yet.
	my $client = $self->{client};
	is(my $res = $client->check($id),undef,'Check for no message');

    # Now the worker replies to the client. This also marks the task as "done"
	my $reply = "You've got mail";
	ok($self->reply({data => $reply}), 'Talking to ourself');

    # Now the client actively looks for this task in the queue
	ok($res = $client->receive($id),'- But do we listen?');
	is($res, $reply,'- Did we hear what we said?');

    # Finally, the client quits listening for this task
	ok($client->uncheck($id),'Uncheck first message');

}

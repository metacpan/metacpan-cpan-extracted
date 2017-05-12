package Worker;

use strict;
use warnings;
use Test::More;

use base 'Job::Machine::Worker';

use Job::Machine::Client;

our $id;
sub data  {
	return {
		message => 'Try Our Tasty Foobar!',
		number  => 1,
		array   => [1,2,'three',],
	};
};

sub timeout {5}

sub keep_running {0}

sub startup {
	my ($self) = @_;
	my %config = main::config();
	ok(my $client = Job::Machine::Client->new(%config),'New client');
	my $version = $client->db->dbh->{pg_server_version};
	return if $version < 90000;

	$self->{client} = $client;
	ok($id = $client->send($self->data),'Send a task');
	$config{queue} = 'q';
	my $id2;
	ok(my $client2 = Job::Machine::Client->new(%config),'Another client');
	ok($id2 = $client2->send($self->data),'Send another task');
	ok($client2->uncheck($id2),'Uncheck send message');
}

sub process {
	my ($self, $task) = @_;
	is_deeply($task->{data}, $self->data,'- Did we get what we sent?');
	my $client = $self->{client};
	is(my $res = $client->check($id),undef,'Check for no message') if $task->{name} eq 'qyouw';
	my $reply = "You've got nail";
	ok($self->reply({foo => $reply}), 'Talking to ourself');
	ok($res = $client->receive($id),'- But do we listen?');
	is($res->{foo}, $reply,'- Did we hear what we said?');
	ok($client->uncheck($id),'Uncheck first message');
};

package Test::Job::Machine;

use strict;
use warnings;
use base qw(Test::Class);
use Test::More;

sub db_name {'__jm::test__'};

sub startup : Test(startup => 2) {
	my $self = shift;
	my $command = 'createdb -e '.db_name;
	qx{$command} || return $self->{skip} = 1;

	$command = 'psql '.db_name.'<sql/create_tables.sql';
	ok(qx{$command},'Create Job::Machine tables') or return;
	ok($self->{dbh} = DBI->connect('dbi:Pg:dbname='.db_name), 'Connect to test database') or return;
};

sub cleanup : Test(shutdown) {
	my $self = shift;
	return if $self->{skip};

	$self->{dbh}->disconnect;
	my $command = 'dropdb '.db_name;
	qx{$command};
};

sub _worker : Test(98) {
	my $self = shift;
	return if $self->{skip};

	for my $serializer (qw/
		<default>
		Config::General
		Data::Dumper
		JSON
		Storable
		XML::Simple
		YAML
	/) {
		if ($serializer ne '<default>') {
			my $class = "Data::Serializer::".$serializer;
			eval "use $class";

			if ($@) {
				diag("$class not installed, skipping");
				next;
			}
		}
		my %config = main::config();
		$config{serializer} = $serializer unless $serializer eq '<default>';
		ok(my $worker = Worker->new(%config),'New Worker using '.$serializer);
		isa_ok($worker,'Worker','Worker class');
		is($worker->receive,undef,'receive loop');
	}
};

package main;

use strict;
use warnings;

sub config {
	return (dsn => 'dbi:Pg:dbname=__jm::test__', queue => 'qyouw');
}

Test::Job::Machine->runtests;

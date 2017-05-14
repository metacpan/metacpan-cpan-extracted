package Hopkins::Store;

use strict;
use warnings;

=head1 NAME

Hopkins::Store - interface to backend storage

=head1 DESCRIPTION

Hopkins::Store encapsulates all of the busywork associated
with the DBIx::Class schema creation.

=cut

use POE;
use POE::Filter::Reference;
use POE::Wheel::Run;
use Class::Accessor::Fast;

use Cache::FileCache;
use Data::UUID;
use Tie::IxHash;

use Hopkins::Store::Backend;

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw(config cache events backend tries subscribers));

use constant HOPKINS_STORE_EVENT_PROC_INTERVAL => 10;

my $ug = new Data::UUID;

=head1 METHODS

=over 4

=item init

=cut

sub new
{
	my $self = shift->SUPER::new(@_);

	return undef if not $self->config->loaded;

	$self->events(new Tie::IxHash);
	$self->subscribers({});

	$self->cache(new Cache::FileCache {
		cache_root		=> $self->config->fetch('state/root')->stringify,
		namespace		=> 'store',
		directory_umask	=> 0077
	});

	if (my $events = $self->cache->get('events')) {
		last if not ref $events eq 'ARRAY';

		foreach my $href (@$events) {
			next if not ref $href eq 'HASH';
			next if not defined $href->{id};
			next if not defined $href->{contents};

			$self->events->Push($href->{id} => $href->{contents});
		}
	}

	POE::Session->create
	(
		object_states =>
		[
			$self =>
			{
				_start		=> 'start',
				_stop		=> 'stop',

				init		=> 'init',
				notify		=> 'notify',
				subscribe	=> 'subscribe',
				unsubscribe	=> 'unsubscribe',
				proc		=> 'proc',
				shutdown	=> 'shutdown',

				spawn		=> 'backend_spawn',
				stdout		=> 'backend_notify',
				stderr		=> 'backend_error',
				done		=> 'backend_exited'
			}
		]
	);

	return $self;
}

=back

=head1 STATES

=over 4

=item start

=cut

sub start
{
	my $self	= $_[OBJECT];
	my $kernel	= $_[KERNEL];

	$kernel->alias_set('store');

	$kernel->post(store => 'init');
	$kernel->alarm(proc => time + HOPKINS_STORE_EVENT_PROC_INTERVAL);
}

=item stop

=cut

sub stop
{
}

=item init

initialize the store.  if a backend is currently
running, it is destroyed and a new spawn event is
generated.

=cut

sub init
{
	my $self	= $_[OBJECT];
	my $kernel	= $_[KERNEL];

	$self->backend(undef);
	$kernel->post(store => 'spawn');
}

=item shutdown

=cut

sub shutdown
{
	my $self	= $_[OBJECT];
	my $kernel	= $_[KERNEL];

	$self->backend(undef);
	$kernel->alias_remove('store');
	$kernel->alarm('proc');
}

sub proc
{
	my $self	= $_[OBJECT];
	my $kernel	= $_[KERNEL];

	$kernel->alarm(proc => time + HOPKINS_STORE_EVENT_PROC_INTERVAL);

	if (not defined $self->backend) {
		$kernel->post(store => 'spawn');
		return;
	}

	foreach my $id ($self->events->Keys) {
		my $event = $self->events->FETCH($id);

		Hopkins->log_debug("sending event $id to backend");

		$self->backend->put({ event => { id => $id, contents => $event } });
	}

	$kernel->alarm(proc => time + HOPKINS_STORE_EVENT_PROC_INTERVAL);
}

sub evtflush
{
	my $self	= $_[OBJECT];
	my $kernel	= $_[KERNEL];
	my $heap	= $_[HEAP];

	while ($self->events->count) {
		my $aref	= $self->events->shift;
		my $res		= $kernel->call(store => $aref->[0] => $aref->[1..$#{$aref}]);
	}
}

sub subscribe
{
	my $self = $_[OBJECT];

	$self->subscribers->{$_} = 1 foreach @_[ARG0..$#_];
}

sub unsubscribe
{
	my $self = $_[OBJECT];

	delete $self->subscribers->{$_} foreach @_[ARG0..$#_];
}

sub notify
{
	my $self	= $_[OBJECT];
	my $kernel	= $_[KERNEL];

	my $id = $ug->create_str;

	Hopkins->log_debug("received $_[ARG0] notification; assigned event ID $id");

	my @args = @_[ARG0..$#_];

	$self->events->Push($id => \@args);
	$self->write_state;

	# notify any other interested sessions
	$kernel->post($_ => notify => @args) foreach keys %{ $self->subscribers };
}

sub write_state
{
	my $self = shift;

	my @events = map +{ id => $_, contents => $self->events->FETCH($_) }, $self->events->Keys;

	$self->cache->set(events => \@events);
}

sub backend_spawn
{
	my $self	= $_[OBJECT];
	my $kernel	= $_[KERNEL];

	my %args =
	(
		Program			=> sub { new Hopkins::Store::Backend { config => $self->config } },
		StdoutEvent		=> 'stdout',
		StderrEvent		=> 'stderr',
		StdioFilter		=> new POE::Filter::Reference 'Storable'
	);

	$kernel->sig(CHLD => 'done');
	$self->backend(new POE::Wheel::Run %args);
}

sub backend_notify
{
	my $self	= $_[OBJECT];
	my $kernel	= $_[KERNEL];
	my $href	= $_[ARG0];

	if (my $href = $href->{eventproc}) {
		$self->events->Delete($href->{id});
		$self->write_state;
	}
}

sub backend_error
{
	my $self	= $_[OBJECT];
	my $kernel	= $_[KERNEL];
	my $text	= $_[ARG0];

	Hopkins->log_warn($text);
}

sub backend_exited
{
	my $self	= $_[OBJECT];
	my $kernel	= $_[KERNEL];
	my $signal	= $_[ARG0];
	my $pid		= $_[ARG1];
	my $status	= $_[ARG2];

	return if $pid != $self->backend->PID;

	Hopkins->log_error('lost database backend');

	$self->backend(undef);
	$kernel->sig('CHLD');
}

=back

=head1 AUTHOR

Mike Eldridge <diz@cpan.org>

=head1 LICENSE

=cut

1;


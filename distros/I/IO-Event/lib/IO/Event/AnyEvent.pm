
#
# Use AnyEvent for the IO::Event's event handler
#

my $debug = 0;
my $debug_timer;
my $lost_event_timer;

{
package IO::Event::AnyEvent;

our $lost_event_hack = 2;

require IO::Event;
use strict;
use warnings;
use Scalar::Util qw(refaddr);

our @ISA = qw(IO::Event::Common);

my %selves;
my $condvar;

sub import
{
	require IO::Event;
	IO::Event->import('AnyEvent');
}

sub new
{
	my ($pkg, @stuff) = @_;
	my $self = $pkg->SUPER::new(@stuff);
	return $self;
}

sub loop
{
	$condvar = AnyEvent->condvar;

	if ($debug) {
		$debug_timer = AnyEvent->timer(after => 0.1, interval => 0.1, cb => sub {
			print STDERR "WATCHING:\n";
			for my $ie (values %selves) {
				print STDERR "\t";
				print STDERR "R" if ${*$ie}{ie_anyevent_read};
				print STDERR "W" if ${*$ie}{ie_anyevent_read};
				print STDERR " ${*$ie}{ie_desc}\n";
			}
		});
	}
	if ($lost_event_hack) {
		$lost_event_timer = AnyEvent->timer(
			after => $lost_event_hack,
			interval => $lost_event_hack,
			cb => sub {
				for my $ie (values %selves) {
					next unless ${*$ie}{ie_anyevent_read};
					next if ${*$ie}{ie_listener};  # no spurious connections!
#					print STDERR "DISPATCHING FOR READ for ${*$ie}{ie_desc}\n";  # LOST EVENTS
					$ie->ie_dispatch_read();
				}
			},
		);
	}
	$condvar->recv;
}

sub timer
{
	IO::Event::AnyEvent::Wrapper->new('Timer', @_);
}

sub unloop
{
	$condvar->send(@_) if $condvar;
}

sub unloop_all
{
	$condvar->send(@_) if $condvar;
}

sub idle
{
	IO::Event::AnyEvent::Wrapper->new('Idle', @_);
}

sub set_write_polling
{
	my ($self, $new) = @_;
	my $event = ${*$self}{ie_write};
	if ($new) {
		${*$self}{ie_anyevent_write} = AnyEvent->io(
			fh	=> ${*$self}{ie_fh},
			cb	=> sub {
#				print STDERR "<Write ${*$self}{ie_desc}>";	# LOST EVENTS
				$self->ie_dispatch_write();
			},
			poll	=> 'w',
		);
	} else {
		delete ${*$self}{ie_anyevent_write};
	}
}

sub set_read_polling
{
	my ($self, $new) = @_;
	my $event = ${*$self}{ie_event};
	if ($new) {
		${*$self}{ie_anyevent_read} = AnyEvent->io(
			fh	=> ${*$self}{ie_fh},
			cb	=> sub {
#				print STDERR "<READ ${*$self}{ie_desc}>";	# LOST EVENTS
				$self->ie_dispatch_read();
			},
			poll	=> 'r',
		);
	} else {
		delete ${*$self}{ie_anyevent_read};
	}
}

sub ie_register
{
	my ($self) = @_;
	my ($fh, $fileno) = $self->SUPER::ie_register();
	$self->set_read_polling(${*$self}{ie_want_read_events} = ! ${*$self}{ie_readclosed});
	${*$self}{ie_want_write_events} = '';
	$selves{refaddr($self)} = $self;
	print STDERR "registered ${*$self}{ie_fileno}:${*$self}{ie_desc} $self $fh ${*$self}{ie_event}\n"
		if $debug;
}

sub ie_deregister
{
	my ($self) = @_;
	$self->SUPER::ie_deregister();
	delete ${*$self}{ie_anyevent_write};
	delete ${*$self}{ie_anyevent_read};
	delete $selves{refaddr($self)};
}

}{package IO::Event::AnyEvent::Wrapper;

use strict;
use warnings;
use Scalar::Util qw(refaddr);

my %handlers;

sub new
{
	my ($pkg, $type, $req_pkg, %param) = @_;
	my ($cpkg, $file, $line, $sub) = caller;
	my $desc;
	{ 
		no warnings;
		$desc = $param{desc} || "\u$type\E event  defined in ${cpkg}::${sub} at $file:$line";
	}
	if (ref($param{cb}) eq 'ARRAY') {
		my ($obj, $meth) = @{$param{cb}};
		$param{cb} = sub {
			$obj->$meth();
		};
	}
	$param{after} ||= $param{interval};
	my $self = bless {
		type	=> lc($type),
		desc	=> $desc,
		param	=> \%param,
	}, $pkg;

	$self->start();

	return $self;
}

sub start
{
	my ($self) = @_;
	$handlers{refaddr($self)} = $self;
	my $type = $self->{type};
	$self->{handler} = AnyEvent->$type(%{$self->{param}});
}

sub again
{
	my ($self) = @_;
	$self->start;
}

sub now
{
	my ($self) = @_;
	$self->{param}{cb}->($self);
}

sub stop
{
	my ($self) = @_;
	delete $self->{handler};
}

sub cancel
{
	my ($self) = @_;
	$self->stop();
	delete $handlers{refaddr($self)};
}

sub is_cancelled
{
	my ($self) = @_;
	return ! $handlers{refaddr($self)}; 
}

sub is_active
{
	my ($self) = @_;
	return ! ! $self->{handler};
}

sub is_running
{
	return;
}

sub pending
{
	return;
}


}#end package
1;

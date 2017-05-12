package EntityModel::Collection;
{
  $EntityModel::Collection::VERSION = '0.102';
}
use EntityModel::Class {
	pending	=> 'int',
	event_handler => 'hash',
};
no if $] >= 5.017011, warnings => "experimental::smartmatch";

=head1 NAME

EntityModel::Collection - manage entity model definitions

=head1 VERSION

version 0.102

=head1 SYNOPSIS

=cut

=head2 OPERATORS

The coderef operator is overloaded by default, allowing syntax such as C< $self->(event => @data) >.

=cut

use overload
# Allow ->(event => @parameter) for laziness
	'&{}'	=> sub {
		my $self = shift;
		sub {
			my $event = shift;
			my @param = @_;
			logDebug("[%s] %s", $event, join ', ', @param);
			if(my $handler = $self->{event_handler}->{$event}) {
				try {
				# Use a temporary so we don't end up in void context
					my $rslt;
					$rslt = $_->($self, @param) for @$handler;
				} catch {
					my $failure = $_;
					logError("Handler on %s for [%s] threw error %s", $self, $event, $failure);
					die "No failure handler available" unless $self->has_event_handlers_for('fail');
					# Raise a failure event, but avoid loops
					try { $self->(fail => $failure); }
					catch { logError("Also failed in failure handler, this time [%s] original [%s]", $_, $failure) }
					unless $event eq 'fail';
				};
			} else {
				logWarning("No handler for [%s]", $event);
			}
			return defined wantarray
			? $self
			: $self->commit;
		}
	},
# Could dump out more info on "" perhaps
	fallback => 1;

=head2 each

Execute the given code for each item that matches the current chain.

=cut

sub each {
	my $self = shift;
	my $code = shift;
	logDebug("Each");
	$self->add_handler(item => $code);
	return defined wantarray
	? $self
	: $self->commit
}

=head2 done

Supply a coderef which will be called on successful completion of the chain so far, guaranteed
to be after any items have been processed.

=cut

sub done {
	my $self = shift;
	my $code = shift;
	logDebug("Done");
	$self->add_handler(done => $code);
	return defined wantarray
	? $self
	: $self->commit
}

=head2 fail

Supply a coderef which will be called on error. Default behaviour is to die().

=cut

sub fail {
	my $self = shift;
	my $code = shift;
	logDebug("Set handler for failed");
	$self->add_handler(fail => $code);
	return defined wantarray
	? $self
	: $self->commit
}

=head2 commit

=cut

sub commit {
	my $self = shift;
	my $code = shift;
# Protect against unnecessary calls
	unless($self->{pending}) {
		logDebug("Commit with nothing pending");
		$code->() if $code;
		return $self;
	}

	logDebug("Commit");
# Apply anything we can - and make sure we're not in void context to avoid commit loops
	if(my $apply = $self->can('apply')) {
		my $x; $x = $apply->($self);
	}
	$self->pending(0);
	logDebug("Has pending? %s", ($self->has_pending ? 'yes' : 'no'));

	$code->($self) if $code;
	$self->('done' => $self);
	return $self;
}

=head2 add_handler

=cut

sub add_handler {
	my $self = shift;
	while(@_) {
		my ($event, $code) = splice @_, 0, 2;
		logDebug("Defining handler %s for event %s", "$code", $event);
		push @{$self->{event_handler}->{$event}}, $code;
		++$self->{pending} if $event ~~ [qw(item done)];
	}
	return $self;
}

=head2 has_event_handlers_for

Returns how many event handlers are defined for this event.

=cut

sub has_event_handlers_for {
	my $self = shift;
	my $event = shift or die "Invalid event passed";
	return scalar @{$self->{event_handler}->{$event}};
}

=head2 has_pending

Returns true if there's anything pending, false otherwise.

=cut

sub has_pending { (shift->pending || 0) > 0 }

=head2 DESTROY

When we go out of scope, we want any pending actions to be applied immediately.

=cut

sub DESTROY {
	my $self = shift;
	$self->commit if $self->has_pending;
}

1;

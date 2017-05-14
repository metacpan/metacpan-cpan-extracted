package Hopkins::Work;

use strict;

=head1 NAME

Hopkins::Work - task queued as a unit of work

=head1 DESCRIPTION

Hopkins::Work represents an instance of a task.  in other
words, it is a task that has been queued as a unit of work
ready for execution.  it is eventually associated with a
database object by the store session, but can and will live
on its own without database connectivity.

=cut

use Class::Accessor::Fast;

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw(id worker task priority options queue output succeeded failed aborted date_enqueued date_to_execute date_started date_completed));

sub new
{
	my $self = shift->SUPER::new(@_);

	$self->succeeded(0)	if not defined $self->succeeded;
	$self->failed(0)	if not defined $self->failed;
	$self->aborted(0)	if not defined $self->aborted;
	$self->priority(5)	if not defined $self->priority;

	return $self;
}

sub serialize
{
	my $self = shift;

	return
	{
		id				=> $self->id,
		task			=> $self->task ? $self->task->name : undef,
		queue			=> $self->queue->name,
		priority		=> $self->priority,
		options			=> $self->options,
		succeeded		=> $self->succeeded,
		failed			=> $self->failed,
		aborted			=> $self->aborted,
		output			=> $self->output,
		date_enqueued	=> $self->date_enqueued ? $self->date_enqueued->iso8601 : undef,
		date_to_execute	=> $self->date_to_execute->iso8601,
		date_started	=> $self->date_started ? $self->date_started->iso8601 : undef,
		date_completed	=> $self->date_completed ? $self->date_completed->iso8601 : undef
	};
}

=back

=head1 AUTHOR

Mike Eldridge <diz@cpan.org>

=head1 LICENSE

=cut

1;


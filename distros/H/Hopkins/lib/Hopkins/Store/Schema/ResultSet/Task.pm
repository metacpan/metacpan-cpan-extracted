package Hopkins::Store::Schema::ResultSet::Task;

=head1 NAME

Hopkins::Store::Schema::ResultSet::Task - ResultSet class for Task

=head1 DESCRIPTION

this class houses ResultSet methods for the Task
ORM class.  it provides niceties and convenience
methods.

=cut

use base 'DBIx::Class::ResultSet';

=head1 METHODS

=over 4

=item queued

restricts the ResultSet to only those Tasks that
have been queued but not started.

=cut

sub queued
{
	return shift->search({ date_started => undef });
}

=sub task_executed_since

given a task name and a DateTime object, returns a
boolean value indicating whether or not the task has
successfully executed since

=cut

sub task_executed_since
{
	my $self = shift;
	my $name = shift;
	my $date = shift;

	my $rs = $self->search({ name => $name, date_queued => { '>=', $date } });

	return $rs->count == 0 ? 0 : 1;
}

=sub task_executing_now

given a task name, returns a boolean value indicating
whether or not the task is currently running

=cut

sub task_executing_now
{
	my $self = shift;
	my $name = shift;

	my $rs = $self->search({ name => $name, date_completed => undef });

	return $rs->count == 0 ? 0 : 1;
}

=back

=head1 AUTHOR

Mike Eldridge <diz@cpan.org>

=cut

1;

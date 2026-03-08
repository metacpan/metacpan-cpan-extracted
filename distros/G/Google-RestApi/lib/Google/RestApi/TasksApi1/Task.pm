package Google::RestApi::TasksApi1::Task;

our $VERSION = '2.1.1';

use Google::RestApi::Setup;

use parent 'Google::RestApi::SubResource';

sub new {
  my $class = shift;
  state $check = signature(
    bless => !!0,
    named => [
      task_list => HasApi,
      id        => Str, { optional => 1 },
    ],
  );
  return bless $check->(@_), $class;
}

sub _uri_base { "lists/" . $_[0]->task_list()->task_list_id() . "/tasks" }
sub _parent_accessor { 'tasks_api' }

sub get {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      fields => Str, { optional => 1 },
    ],
  );
  my $p = $check->(@_);

  $self->require_id('get');

  my %params;
  $params{fields} = $p->{fields} if defined $p->{fields};

  return $self->api(params => \%params);
}

sub update {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      title   => Str, { optional => 1 },
      notes   => Str, { optional => 1 },
      due     => Str, { optional => 1 },
      status  => Str, { optional => 1 },
      _extra_ => slurpy HashRef,
    ],
  );
  my $p = named_extra($check->(@_));

  $self->require_id('update');

  my %content;
  $content{title} = delete $p->{title} if defined $p->{title};
  $content{notes} = delete $p->{notes} if defined $p->{notes};
  $content{due} = delete $p->{due} if defined $p->{due};
  $content{status} = delete $p->{status} if defined $p->{status};

  DEBUG(sprintf("Updating task '%s'", $self->{id}));
  return $self->api(
    method  => 'patch',
    content => \%content,
  );
}

sub delete {
  my $self = shift;

  $self->require_id('delete');

  DEBUG(sprintf("Deleting task '%s'", $self->{id}));
  return $self->api(method => 'delete');
}

sub move {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      parent                => Str, { optional => 1 },
      previous              => Str, { optional => 1 },
      destination_tasklist   => Str, { optional => 1 },
    ],
  );
  my $p = $check->(@_);

  $self->require_id('move');

  my %params;
  $params{parent} = $p->{parent} if defined $p->{parent};
  $params{previous} = $p->{previous} if defined $p->{previous};
  $params{destinationTasklist} = $p->{destination_tasklist} if defined $p->{destination_tasklist};

  DEBUG(sprintf("Moving task '%s'", $self->{id}));
  return $self->api(
    uri    => 'move',
    method => 'post',
    params => \%params,
  );
}

sub complete {
  my $self = shift;

  $self->require_id('complete');

  DEBUG(sprintf("Completing task '%s'", $self->{id}));
  return $self->api(
    method  => 'patch',
    content => { status => 'completed' },
  );
}

sub uncomplete {
  my $self = shift;

  $self->require_id('uncomplete');

  DEBUG(sprintf("Uncompleting task '%s'", $self->{id}));
  return $self->api(
    method  => 'patch',
    content => { status => 'needsAction', completed => undef },
  );
}

sub task_id { shift->{id}; }
sub task_list { shift->{task_list}; }
sub tasks_api { shift->{task_list}->{tasks_api}; }

1;

__END__

=head1 NAME

Google::RestApi::TasksApi1::Task - Task object for Google Tasks.

=head1 SYNOPSIS

 # Create a task
 my $task = $tl->create_task(
   title => 'Buy groceries',
   notes => 'Milk, eggs, bread',
   due   => '2026-03-01T00:00:00.000Z',
 );

 # Get task details
 my $details = $task->get();

 # Update task
 $task->update(title => 'Buy groceries and snacks');

 # Complete/uncomplete
 $task->complete();
 $task->uncomplete();

 # Move task (make it a subtask or reorder)
 $task->move(parent => 'parent_task_id');
 $task->move(previous => 'sibling_task_id');

 # Delete task
 $task->delete();

=head1 DESCRIPTION

Represents a task in a Google Task List. Supports creating, reading,
updating, deleting, moving, completing, and uncompleting tasks.

=head1 METHODS

=head2 get(fields => $fields)

Gets task details. Requires task ID.

=head2 update(title => $text, notes => $text, due => $date, status => $status)

Updates task properties. Requires task ID.

=head2 delete()

Deletes the task. Requires task ID.

=head2 move(parent => $id, previous => $id, destination_tasklist => $id)

Moves the task. Use C<parent> to make it a subtask, C<previous> to reorder,
or C<destination_tasklist> to move to another list. Requires task ID.

=head2 complete()

Marks the task as completed. Requires task ID.

=head2 uncomplete()

Marks the task as needing action (not completed). Requires task ID.

=head2 task_id()

Returns the task ID.

=head2 task_list()

Returns the parent TaskList object.

=head2 tasks_api()

Returns the TasksApi1 object.

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019-2026 Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

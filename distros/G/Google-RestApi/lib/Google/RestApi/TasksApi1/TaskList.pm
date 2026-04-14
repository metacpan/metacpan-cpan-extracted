package Google::RestApi::TasksApi1::TaskList;

our $VERSION = '2.2.1';

use Google::RestApi::Setup;

use parent 'Google::RestApi::SubResource';

use aliased 'Google::RestApi::TasksApi1::Task';

sub new {
  my $class = shift;
  state $check = signature(
    bless => !!0,
    named => [
      tasks_api => HasApi,
      id        => Str, { optional => 1 },
    ],
  );
  return bless $check->(@_), $class;
}

sub _uri_base { 'users/@me/lists' }
sub _parent_accessor { 'tasks_api' }

sub get {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      fields => Str, { optional => 1 },
      params => HashRef, { default => {} },
    ],
  );
  my $p = $check->(@_);

  $self->require_id('get');

  my $params = $p->{params};
  $params->{fields} = $p->{fields} if defined $p->{fields};

  return $self->api(params => $params);
}

sub update {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      title   => Str, { optional => 1 },
      _extra_ => slurpy HashRef,
    ],
  );
  my $p = named_extra($check->(@_));

  $self->require_id('update');

  my %content;
  $content{title} = delete $p->{title} if defined $p->{title};

  DEBUG(sprintf("Updating task list '%s'", $self->{id}));
  return $self->api(
    method  => 'patch',
    content => \%content,
  );
}

sub delete {
  my $self = shift;

  $self->require_id('delete');

  DEBUG(sprintf("Deleting task list '%s'", $self->{id}));
  return $self->api(method => 'delete');
}

sub task {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      id => Str, { optional => 1 },
    ],
  );
  my $p = $check->(@_);
  return Task->new(task_list => $self, %$p);
}

sub tasks {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      max_pages     => Int, { default => 1 },
      page_callback => CodeRef, { optional => 1 },
      params        => HashRef, { default => {} },
    ],
  );
  my $p = $check->(@_);

  $self->require_id('tasks');

  return paginated_list(
    api            => $self->tasks_api(),
    uri            => "lists/$self->{id}/tasks",
    result_key     => 'items',
    default_fields => 'items(id, title, status, due)',
    max_pages      => $p->{max_pages},
    params         => $p->{params},
    ($p->{page_callback} ? (page_callback => $p->{page_callback}) : ()),
  );
}

sub create_task {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      title   => Str,
      notes   => Str, { optional => 1 },
      due     => Str, { optional => 1 },
      _extra_ => slurpy HashRef,
    ],
  );
  my $p = named_extra($check->(@_));

  $self->require_id('create_task');

  my %content = (
    title => delete $p->{title},
  );
  $content{notes} = delete $p->{notes} if defined $p->{notes};
  $content{due} = delete $p->{due} if defined $p->{due};

  DEBUG(sprintf("Creating task '%s' on task list '%s'", $content{title}, $self->{id}));
  my $result = $self->tasks_api()->api(
    uri     => "lists/$self->{id}/tasks",
    method  => 'post',
    content => \%content,
  );
  return Task->new(task_list => $self, id => $result->{id});
}

sub clear {
  my $self = shift;

  $self->require_id('clear');

  DEBUG(sprintf("Clearing completed tasks from task list '%s'", $self->{id}));
  return $self->tasks_api()->api(
    uri    => "lists/$self->{id}/clear",
    method => 'post',
  );
}

sub task_list_id { shift->{id}; }
sub tasks_api { shift->{tasks_api}; }

1;

__END__

=head1 NAME

Google::RestApi::TasksApi1::TaskList - Task list object for Google Tasks.

=head1 SYNOPSIS

 my $tl = $tasks_api->task_list(id => 'task_list_id');

 # Get task list metadata
 my $metadata = $tl->get();

 # Update task list
 $tl->update(title => 'New Name');

 # Delete task list
 $tl->delete();

 # Tasks
 my @tasks = $tl->tasks();
 my $task = $tl->task(id => 'task_id');
 $tl->create_task(
   title => 'Buy groceries',
   notes => 'Milk, eggs, bread',
   due   => '2026-03-01T00:00:00.000Z',
 );

 # Clear completed tasks
 $tl->clear();

=head1 DESCRIPTION

Represents a Google Task List with full CRUD operations and task management.

=head1 METHODS

=head2 get(fields => $fields, params => \%params)

Retrieves task list metadata. Requires task list ID.

=head2 update(title => $title)

Updates task list metadata. Requires task list ID.

=head2 delete()

Permanently deletes the task list. Requires task list ID.

=head2 task(id => $id)

Returns a Task object. Without id, can be used to create new tasks.

=head2 tasks(max_pages => $n, page_callback => $coderef)

Lists all tasks on the task list. Requires task list ID. C<max_pages> limits
the number of pages fetched (default 1). Set to 0 for unlimited.
Supports C<page_callback>, see L<Google::RestApi/PAGE CALLBACKS>.

=head2 create_task(title => $title, notes => $notes, due => $due)

Creates a new task on the task list. Requires task list ID.

=head2 clear()

Clears all completed tasks from the task list. Requires task list ID.

=head2 task_list_id()

Returns the task list ID.

=head2 tasks_api()

Returns the parent TasksApi1 object.

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019-2026 Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

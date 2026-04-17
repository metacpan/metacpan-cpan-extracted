package Google::RestApi::TasksApi1;

our $VERSION = '2.2.2';

use Google::RestApi::Setup;

use Readonly;
use URI;

use aliased 'Google::RestApi::TasksApi1::TaskList';

Readonly our $Tasks_Endpoint => 'https://tasks.googleapis.com/tasks/v1';

sub new {
  my $class = shift;
  state $check = signature(
    bless => !!0,
    named => [
      api      => HasApi,
      endpoint => Str, { default => $Tasks_Endpoint },
    ],
  );
  return bless $check->(@_), $class;
}

sub api {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      uri     => Str, { optional => 1 },
      _extra_ => slurpy HashRef,
    ],
  );
  my $p = named_extra($check->(@_));
  my $uri = "$self->{endpoint}/";
  $uri .= delete $p->{uri} if defined $p->{uri};
  return $self->{api}->api(%$p, uri => $uri);
}

sub task_list {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      id => Str, { optional => 1 },
    ],
  );
  my $p = $check->(@_);
  return TaskList->new(tasks_api => $self, %$p);
}

sub create_task_list {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      title   => Str,
      _extra_ => slurpy HashRef,
    ],
  );
  my $p = named_extra($check->(@_));

  my %content = (
    title => delete $p->{title},
  );

  DEBUG("Creating task list '$content{title}'");
  my $result = $self->api(
    uri     => 'users/@me/lists',
    method  => 'post',
    content => \%content,
  );
  return TaskList->new(tasks_api => $self, id => $result->{id});
}

sub list_task_lists {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      max_pages     => Int, { default => 0 },
      page_callback => CodeRef, { optional => 1 },
      params        => HashRef, { default => {} },
    ],
  );
  my $p = $check->(@_);

  return paginated_list(
    api            => $self,
    uri            => 'users/@me/lists',
    result_key     => 'items',
    default_fields => 'items(id, title)',
    max_pages      => $p->{max_pages},
    params         => $p->{params},
    ($p->{page_callback} ? (page_callback => $p->{page_callback}) : ()),
  );
}

sub rest_api { shift->{api}; }
sub transaction { shift->rest_api()->transaction(); }
sub stats { shift->rest_api()->stats(); }
sub reset_stats { shift->rest_api->reset_stats(); }

1;

__END__

=head1 NAME

Google::RestApi::TasksApi1 - API to Google Tasks API V1.

=head1 SYNOPSIS

=head2 Basic Setup

 use Google::RestApi;
 use Google::RestApi::TasksApi1;

 # Create the REST API instance
 my $rest_api = Google::RestApi->new(
   config_file => '/path/to/config.yaml',
 );

 # Create the Tasks API instance
 my $tasks_api = Google::RestApi::TasksApi1->new(api => $rest_api);

=head2 Working with Task Lists

 # Create a new task list
 my $task_list = $tasks_api->create_task_list(title => 'My Task List');

 # Get an existing task list
 my $tl = $tasks_api->task_list(id => 'task_list_id');
 my $metadata = $tl->get();

 # Update task list title
 $tl->update(title => 'Updated Name');

 # List all task lists
 my @lists = $tasks_api->list_task_lists();

=head2 Working with Tasks

 my $tl = $tasks_api->task_list(id => 'task_list_id');

 # Create a task
 my $task = $tl->create_task(
   title => 'Buy groceries',
   notes => 'Milk, eggs, bread',
   due   => '2026-03-01T00:00:00.000Z',
 );

 # Get/update/delete a task
 my $details = $task->get();
 $task->update(title => 'Buy groceries and snacks');
 $task->delete();

 # Complete/uncomplete a task
 $task->complete();
 $task->uncomplete();

 # Move a task (make it a subtask or reorder)
 $task->move(parent => 'parent_task_id');
 $task->move(previous => 'sibling_task_id');

 # List tasks
 my @tasks = $tl->tasks();

 # Clear completed tasks
 $tl->clear();

=head1 DESCRIPTION

Google::RestApi::TasksApi1 provides a Perl interface to the Google Tasks API V1.
It enables task management including:

=over 4

=item * Task list CRUD operations (create, get, update, delete)

=item * Task management (create, get, update, delete)

=item * Task completion tracking (complete, uncomplete)

=item * Task organization (move for subtasks and reordering)

=item * Clear completed tasks from a list

=back

It is assumed that you are familiar with the Google Tasks API:
L<https://developers.google.com/tasks/reference/rest>

=head2 Architecture

The API uses a hierarchical object model where child objects delegate API calls
to their parent:

 TasksApi1 (top-level)
   |-- task_list(id => ...)       -> TaskList
   |     |-- task(id => ...)      -> Task
   |     |-- tasks()              -> list of task hashrefs
   |     |-- create_task()        -> Task
   |     |-- clear()              -> clears completed

Each object provides CRUD operations appropriate to its resource type.

=head1 NAVIGATION

=over

=item * L<Google::RestApi::TasksApi1> - This module (top-level Tasks API)

=item * L<Google::RestApi::TasksApi1::TaskList> - Task list operations

=item * L<Google::RestApi::TasksApi1::Task> - Task management

=back

=head1 SUBROUTINES

=head2 new(%args)

Creates a new TasksApi1 instance.

 my $tasks_api = Google::RestApi::TasksApi1->new(api => $rest_api);

%args consists of:

=over

=item * C<api> L<Google::RestApi>: Required. A configured RestApi instance.

=item * C<endpoint> <string>: Optional. Override the default Tasks API endpoint.

=back

=head2 api(%args)

Low-level method to make API calls. You would not normally call this directly
unless making a Google API call not currently supported by this framework.

%args consists of:

=over

=item * C<uri> <string>: Path segments to append to the Tasks endpoint.

=item * C<%args>: Additional arguments passed to L<Google::RestApi>'s api() (content, params, method, etc).

=back

Returns the response hash from the Google API.

=head2 task_list(%args)

Returns a TaskList object for the given task list ID.

 my $tl = $tasks_api->task_list(id => 'task_list_id');

%args consists of:

=over

=item * C<id> <string>: Optional. The task list ID. Required for get/update/delete.

=back

=head2 create_task_list(%args)

Creates a new task list.

 my $tl = $tasks_api->create_task_list(title => 'My Tasks');

%args consists of:

=over

=item * C<title> <string>: Required. The name for the task list.

=back

Returns a TaskList object for the created task list.

=head2 list_task_lists(%args)

Lists all task lists for the user.

 my @lists = $tasks_api->list_task_lists();
 my @lists = $tasks_api->list_task_lists(max_pages => 2);

C<max_pages> limits the number of pages fetched (default 0 = unlimited).
Supports C<page_callback>, see L<Google::RestApi/PAGE CALLBACKS>.

Returns a list of task list hashrefs with id and title.

=head2 rest_api()

Returns the underlying L<Google::RestApi> object.

=head1 SEE ALSO

=over

=item * L<Google::RestApi> - The underlying REST API client

=item * L<Google::RestApi::DriveApi3> - Google Drive API (related module)

=item * L<Google::RestApi::SheetsApi4> - Google Sheets API (related module)

=item * L<Google::RestApi::CalendarApi3> - Google Calendar API (related module)

=item * L<Google::RestApi::GmailApi1> - Google Gmail API (related module)

=item * L<Google::RestApi::DocsApi1> - Google Docs API (related module)

=item * L<https://developers.google.com/tasks/reference/rest> - Google Tasks API Reference

=back

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019-2026 Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

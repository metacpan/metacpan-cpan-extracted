package Langertha::Raider::TodoTools;
# ABSTRACT: Internal task-list tools of raider: task_create, task_update, task_list, task_get and todo_write
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;
use Carp qw( croak );
use MCP::Server;


has on_update => (
  is        => 'ro',
  isa       => 'CodeRef',
  predicate => 'has_on_update',
);


has before_task => (
  is        => 'ro',
  isa       => 'CodeRef',
  predicate => 'has_before_task',
);


has server => (
  is       => 'ro',
  lazy     => 1,
  builder  => '_build_server',
  init_arg => undef,
);


has task_server => (
  is       => 'ro',
  lazy     => 1,
  builder  => '_build_task_server',
  init_arg => undef,
);


has _tasks => (
  is       => 'ro',
  isa      => 'ArrayRef',
  default  => sub { [] },
  init_arg => undef,
);

# The highest id given out so far: ids are never used again.
has _last_id => (
  is       => 'rw',
  isa      => 'Int',
  default  => 0,
  init_arg => undef,
);

my @STATUS = qw( pending in_progress completed );
my %MARK   = ( pending => '[ ]', in_progress => '[>]', completed => '[x]' );


sub check {
  my ( $self, $items ) = @_;
  croak 'todos must be a list' unless ref $items eq 'ARRAY';
  my ( @list, $active );
  for my $i ( 0 .. $#$items ) {
    my $n    = $i + 1;
    my $item = $items->[$i];
    croak 'todo '.$n.' is not an object' unless ref $item eq 'HASH';
    my $content = $item->{content};
    croak 'todo '.$n.' has no content' unless defined $content && !ref $content && $content =~ /\S/;
    my $status = $item->{status} // '';
    croak 'todo '.$n.' has the status "'.$status.'", expected one of '.join( ', ', @STATUS )
      unless grep { $_ eq $status } @STATUS;
    croak 'todo '.$n.' is a second item in_progress (todo '.$active.' is): only one at a time'
      if $status eq 'in_progress' && defined $active;
    $active = $n if $status eq 'in_progress';
    push @list, {
      content    => $content,
      status     => $status,
      activeForm => ( defined $item->{activeForm} && length $item->{activeForm} ? $item->{activeForm} : $content ),
    };
  }
  return \@list;
}


sub render {
  my ( $self, $list ) = @_;
  return 'Todo list is empty.' unless @$list;
  my %count;
  $count{ $_->{status} }++ for @$list;
  return 'Todo list updated: '
    .join( ', ', map { ( $count{$_} // 0 ).' '.( s/_/ /r ) } reverse @STATUS )."\n"
    .join( "\n", map { $MARK{ $_->{status} }.' '.$_->{content} } @$list );
}

#### The task tools


sub tasks {
  my ( $self ) = @_;
  return [ map { $self->_task_item($_) } @{ $self->_tasks } ];
}


sub clear_tasks {
  my ( $self ) = @_;
  @{ $self->_tasks } = ();
  return;
}


sub restore_tasks {
  my ( $self, $list ) = @_;
  my @tasks;
  my $last = $self->_last_id;
  for my $item ( ref $list eq 'ARRAY' ? @$list : () ) {
    next unless ref $item eq 'HASH' && defined $item->{id} && !ref $item->{id};
    my $status = $item->{status} // 'pending';
    push @tasks, {
      id          => "$item->{id}",
      subject     => $item->{content} // '',
      description => $item->{description} // '',
      status      => ( grep { $_ eq $status } @STATUS ) ? $status : 'pending',
      blocks      => [ ref $item->{blocks} eq 'ARRAY' ? @{ $item->{blocks} } : () ],
      blockedBy   => [ ref $item->{blockedBy} eq 'ARRAY' ? @{ $item->{blockedBy} } : () ],
      ( defined $item->{activeForm} && $item->{activeForm} ne ( $item->{content} // '' ) ? ( activeForm => $item->{activeForm} ) : () ),
      ( defined $item->{owner} ? ( owner => $item->{owner} ) : () ),
      ( ref $item->{metadata} eq 'HASH' ? ( metadata => { %{ $item->{metadata} } } ) : () ),
    };
    $last = $item->{id} if $item->{id} =~ /\A\d+\z/ && $item->{id} > $last;
  }
  @{ $self->_tasks } = @tasks;
  $self->_last_id($last);
  return;
}


sub create_task {
  my ( $self, $in ) = @_;
  $in = {} unless ref $in eq 'HASH';
  for my $key (qw( subject description )) {
    return ( 'Error: '.$key.' is required and must be a string', 1 ) unless $self->_is_string( $in->{$key} );
  }
  return ( 'Error: activeForm must be a string', 1 ) if defined $in->{activeForm} && !$self->_is_string( $in->{activeForm} );
  return ( 'Error: metadata must be an object', 1 ) if defined $in->{metadata} && ref $in->{metadata} ne 'HASH';
  my $id = $self->_last_id + 1;
  my $task = {
    id          => "$id",
    subject     => $in->{subject},
    description => $in->{description},
    ( defined $in->{activeForm} ? ( activeForm => $in->{activeForm} ) : () ),
    status      => 'pending',
    blocks      => [],
    blockedBy   => [],
    ( defined $in->{metadata} ? ( metadata => { %{ $in->{metadata} } } ) : () ),
  };
  if ( $self->has_before_task ) {
    my $blocked = $self->before_task->( TaskCreated => $self->_task_item($task) );
    return ( $blocked, 1 ) if defined $blocked;
  }
  $self->_last_id($id);
  push @{ $self->_tasks }, $task;
  $self->_tasks_changed;
  return ( 'Task #'.$id.' created successfully: '.$in->{subject}, 0 );
}


my %UPDATE_STATUS = map { $_ => 1 } @STATUS, 'deleted';

sub update_task {
  my ( $self, $in ) = @_;
  $in = {} unless ref $in eq 'HASH';
  my $id = $in->{taskId};
  return ( 'Error: taskId is required and must be a string', 1 ) unless $self->_is_string($id);
  for my $key (qw( subject description activeForm owner )) {
    return ( 'Error: '.$key.' must be a string', 1 ) if defined $in->{$key} && !$self->_is_string( $in->{$key} );
  }
  my $status = $in->{status};
  return ( 'Error: status must be one of '.join( ', ', @STATUS, 'deleted' ), 1 )
    if defined $status && !( !ref $status && $UPDATE_STATUS{$status} );
  for my $key (qw( addBlocks addBlockedBy )) {
    next unless defined $in->{$key};
    return ( 'Error: '.$key.' must be a list of task ids', 1 )
      unless ref $in->{$key} eq 'ARRAY' && !grep { !$self->_is_string($_) } @{ $in->{$key} };
  }
  return ( 'Error: metadata must be an object', 1 ) if defined $in->{metadata} && ref $in->{metadata} ne 'HASH';

  my $task = $self->_task($id) or return ( 'Task not found', 0 );
  return $self->_delete_task($task) if defined $status && $status eq 'deleted';

  if ( defined $status && $status eq 'completed' && $task->{status} ne 'completed' && $self->has_before_task ) {
    my $item = { %{ $self->_task_item($task) }, status => 'completed' };
    $item->{content}     = $in->{subject}     if defined $in->{subject};
    $item->{description} = $in->{description} if defined $in->{description};
    my $blocked = $self->before_task->( TaskCompleted => $item );
    return ( $blocked, 1 ) if defined $blocked;
  }

  my @fields;
  for my $key (qw( subject description activeForm owner )) {
    next unless defined $in->{$key};
    next if defined $task->{$key} && $task->{$key} eq $in->{$key};
    $task->{$key} = $in->{$key};
    push @fields, $key;
  }
  if ( defined $in->{metadata} ) {
    my %meta = ( %{ $task->{metadata} // {} }, %{ $in->{metadata} } );
    delete @meta{ grep { !defined $meta{$_} } keys %meta };
    $task->{metadata} = \%meta;
    push @fields, 'metadata';
  }
  if ( defined $status && $status ne $task->{status} ) {
    $task->{status} = $status;
    push @fields, 'status';
  }
  push @fields, 'blocks'    if $self->_add_links( $task, $in->{addBlocks}, 0 );
  push @fields, 'blockedBy' if $self->_add_links( $task, $in->{addBlockedBy}, 1 );
  $self->_tasks_changed if @fields;
  return ( 'Updated task #'.$task->{id}.' '.join( ', ', @fields ), 0 );
}


sub list_tasks {
  my ( $self ) = @_;
  my @tasks = grep { !( $_->{metadata} && $_->{metadata}{_internal} ) } @{ $self->_tasks };
  return 'No tasks found' unless @tasks;
  my %done = map { $_->{id} => 1 } grep { $_->{status} eq 'completed' } @tasks;
  return join "\n", map {
    my @open = grep { !$done{$_} } @{ $_->{blockedBy} };
    '#'.$_->{id}.' ['.$_->{status}.'] '.$_->{subject}
      .( defined $_->{owner} && length $_->{owner} ? ' ('.$_->{owner}.')' : '' )
      .( @open ? ' [blocked by '.join( ', ', map { '#'.$_ } @open ).']' : '' )
  } @tasks;
}


sub get_task {
  my ( $self, $id ) = @_;
  my $task = $self->_is_string($id) ? $self->_task($id) : undef;
  return 'Task not found' unless $task;
  return join "\n",
    'Task #'.$task->{id}.': '.$task->{subject},
    'Status: '.$task->{status},
    'Description: '.$task->{description},
    ( @{ $task->{blockedBy} } ? 'Blocked by: '.join( ', ', map { '#'.$_ } @{ $task->{blockedBy} } ) : () ),
    ( @{ $task->{blocks} } ? 'Blocks: '.join( ', ', map { '#'.$_ } @{ $task->{blocks} } ) : () );
}

sub _is_string { my ( $self, $v ) = @_; return defined $v && !ref $v ? 1 : 0 }

sub _task {
  my ( $self, $id ) = @_;
  my ( $task ) = grep { $_->{id} eq $id } @{ $self->_tasks };
  return $task;
}

# Removes the task and every link to it (Claude Code's TaskUpdate status deleted).
sub _delete_task {
  my ( $self, $task ) = @_;
  my $id = $task->{id};
  @{ $self->_tasks } = grep { $_->{id} ne $id } @{ $self->_tasks };
  for my $other ( @{ $self->_tasks } ) {
    $other->{$_} = [ grep { $_ ne $id } @{ $other->{$_} } ] for qw( blocks blockedBy );
  }
  $self->_tasks_changed;
  return ( 'Updated task #'.$id.' deleted', 0 );
}

# addBlocks ($reverse false: the task blocks each) or addBlockedBy ($reverse
# true: each blocks the task). As Claude Code: true when an id was new to the
# list, the link itself only between two tasks that exist.
sub _add_links {
  my ( $self, $task, $ids, $reverse ) = @_;
  return 0 unless $ids;
  my $field = $reverse ? 'blockedBy' : 'blocks';
  my %have  = map { $_ => 1 } @{ $task->{$field} };
  my @new   = grep { !$have{$_}++ } @$ids;
  for my $other_id (@new) {
    my $other = $self->_task($other_id) or next;
    my ( $from, $to ) = $reverse ? ( $other, $task ) : ( $task, $other );
    push @{ $from->{blocks} }, $to->{id} unless grep { $_ eq $to->{id} } @{ $from->{blocks} };
    push @{ $to->{blockedBy} }, $from->{id} unless grep { $_ eq $from->{id} } @{ $to->{blockedBy} };
  }
  return @new ? 1 : 0;
}

sub _task_item {
  my ( $self, $task ) = @_;
  return {
    id          => $task->{id},
    content     => $task->{subject},
    status      => $task->{status},
    activeForm  => ( defined $task->{activeForm} && length $task->{activeForm} ? $task->{activeForm} : $task->{subject} ),
    description => $task->{description},
    blocks      => [ @{ $task->{blocks} } ],
    blockedBy   => [ @{ $task->{blockedBy} } ],
    ( defined $task->{owner}    ? ( owner    => $task->{owner} ) : () ),
    ( defined $task->{metadata} ? ( metadata => { %{ $task->{metadata} } } ) : () ),
  };
}

sub _tasks_changed {
  my ( $self ) = @_;
  $self->on_update->( $self->tasks ) if $self->has_on_update;
  return;
}

sub _build_task_server {
  my ( $self ) = @_;
  my $server = MCP::Server->new( name => 'raider-tasks', version => '1.0' );
  my $result = sub { my ( $tool, $text, $is_error ) = @_; $tool->text_result( $text, $is_error ? 1 : 0 ) };
  $server->tool(
    name         => 'task_create',
    description  => 'Create a task in the task list of this session, to plan and track a larger job (three or more '
      .'steps, or several things the user asked for). One task per call; it starts as pending. subject: a short title, '
      .'imperative ("Fix the login bug"); description: what needs to be done; activeForm: the same in the present '
      .'continuous ("Fixing the login bug"), shown while it is in progress. Use task_update to start, finish or '
      .'link tasks, task_list to see them. Not for a single simple step.',
    input_schema => {
      type       => 'object',
      properties => {
        subject     => { type => 'string', description => 'A brief title for the task' },
        description => { type => 'string', description => 'What needs to be done' },
        activeForm  => { type => 'string', description => 'Present continuous form shown while in_progress (e.g. "Running tests")' },
        metadata    => { type => 'object', description => 'Arbitrary metadata to attach to the task' },
      },
      required => [qw( subject description )],
    },
    code => sub { my ( $tool, $in ) = @_; $result->( $tool, $self->create_task($in) ) },
  );
  $server->tool(
    name         => 'task_update',
    description  => 'Update a task of the task list by its id. Set status in_progress before you start working on '
      .'it and completed only when it is fully done (tests pass, nothing partial); deleted removes it. You can also '
      .'change subject, description, activeForm and owner, merge metadata (a key set to null is removed) and add '
      .'dependencies: addBlocks (tasks that cannot start before this one is done), addBlockedBy (tasks that must be '
      .'done first).',
    input_schema => {
      type       => 'object',
      properties => {
        taskId       => { type => 'string', description => 'The id of the task to update' },
        subject      => { type => 'string', description => 'New subject for the task' },
        description  => { type => 'string', description => 'New description for the task' },
        activeForm   => { type => 'string', description => 'Present continuous form shown while in_progress' },
        status       => { type => 'string', enum => [ @STATUS, 'deleted' ], description => 'New status for the task' },
        addBlocks    => { type => 'array', items => { type => 'string' }, description => 'Task ids that this task blocks' },
        addBlockedBy => { type => 'array', items => { type => 'string' }, description => 'Task ids that block this task' },
        owner        => { type => 'string', description => 'New owner for the task' },
        metadata     => { type => 'object', description => 'Metadata keys to merge into the task; null removes a key' },
      },
      required => ['taskId'],
    },
    code => sub { my ( $tool, $in ) = @_; $result->( $tool, $self->update_task($in) ) },
  );
  $server->tool(
    name         => 'task_list',
    description  => 'List all tasks of the task list: id, status, subject, owner and the open tasks each is '
      .'blocked by. Use it to see what is left, and after finishing a task to pick the next (lowest id first).',
    input_schema => { type => 'object', properties => {} },
    code         => sub { my ( $tool ) = @_; $result->( $tool, $self->list_tasks ) },
  );
  $server->tool(
    name         => 'task_get',
    description  => 'Get one task by its id with its full description and dependencies (blocks, blockedBy).',
    input_schema => {
      type       => 'object',
      properties => { taskId => { type => 'string', description => 'The id of the task to retrieve' } },
      required   => ['taskId'],
    },
    code => sub { my ( $tool, $in ) = @_; $result->( $tool, $self->get_task( ( $in // {} )->{taskId} ) ) },
  );
  return $server;
}

sub _build_server {
  my ( $self ) = @_;
  my $server = MCP::Server->new( name => 'raider-todos', version => '1.0' );
  $server->tool(
    name         => 'todo_write',
    description  => 'Keep the list of steps of a larger task (three or more steps). Send the whole list on every change: '
      .'each item has content (imperative), status (pending, in_progress, completed) and activeForm (present continuous). '
      .'Exactly one item is in_progress while you work; mark an item completed as soon as it is done. '
      .'Do not use it for a single simple step.',
    input_schema => {
      type       => 'object',
      properties => {
        todos => {
          type  => 'array',
          items => {
            type       => 'object',
            properties => {
              content    => { type => 'string', description => 'What to do, imperative: "Run the tests"' },
              status     => { type => 'string', enum => \@STATUS },
              activeForm => { type => 'string', description => 'The same in the present continuous: "Running the tests"' },
            },
            required => [qw( content status )],
          },
          description => 'The complete list; it replaces the previous one',
        },
      },
      required => ['todos'],
    },
    code => sub {
      my ( $tool, $in ) = @_;
      my $list = eval { $self->check( $in->{todos} ) };
      if ($@) {
        ( my $msg = $@ ) =~ s/\s+at \S+ line \d+\.?\s*\z//;
        return $tool->text_result( 'Error: '.$msg, 1 );
      }
      $self->on_update->($list) if $self->has_on_update;
      return $tool->text_result( $self->render($list) );
    },
  );
  return $server;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::TodoTools - Internal task-list tools of raider: task_create, task_update, task_list, task_get and todo_write

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    my $todos  = Langertha::Raider::TodoTools->new( on_update => sub { my ($list) = @_; ... } );
    my $tasks  = $todos->task_server;   # MCP::Server with task_create, task_update, task_list, task_get
    my $legacy = $todos->server;        # MCP::Server with todo_write

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

The task-list tools of raider, in the two families Claude Code has had
(L<Langertha::Raider::ToolNames>, ADR 0018, ADR 0025). An application mounts
one family, as Claude Code offers one: L</task_server> by default,
L</server> with C<RAIDER_ENABLE_TASKS=0>.

=over

=item * B<The task tools> (L</task_server>), shaped after Claude Code's
C<TaskCreate>, C<TaskUpdate>, C<TaskList> and C<TaskGet>: the model creates
one task at a time (a C<subject>, a C<description>, an optional
C<activeForm> and C<metadata>), each gets the next id (C<"1">, C<"2">, ...;
ids are never used twice, a deleted one included), and changes them by id:
status (C<pending>, C<in_progress>, C<completed>, or C<deleted>, which
removes the task), subject, description, activeForm, owner, metadata (merged;
a key set to null goes) and dependencies (C<addBlocks>, C<addBlockedBy>).
The tools hold the list: it lasts as long as the object (the application
keeps it for its conversation and empties it with L</clear_tasks>). The
answers are Claude Code's: C<Task #1 created successfully: SUBJECT>,
C<Updated task #1 status>, C<Task not found> (not an error, as in Claude
Code), C<No tasks found>, one line per task for the list.

=item * B<todo_write> (L</server>), shaped after Claude Code's C<TodoWrite>:
the model sends the whole list on every change. It holds no list of its own;
it checks the list it is given and hands it on. An item has a C<content>
(what to do, imperative), a C<status> (C<pending>, C<in_progress> or
C<completed>) and an optional C<activeForm> (the same in the present
continuous; it defaults to the content). At most one item is
C<in_progress>.

=back

Both hand the list to L</on_update> on every change, in one shape: hashes
with C<content> (the subject of a task), C<status> and C<activeForm>; a task
adds C<id>, C<description>, C<blocks>, C<blockedBy> and, when set, C<owner>
and C<metadata>. The application keeps it in its state and reports it
(L<Langertha::Raider::Application/todos>, the C<todo.updated> event). The
tools have no effect outside the run.

=head2 on_update

Optional. Called with the list (an array reference of hashes, see
L</DESCRIPTION>) when a call changed it.

=head2 before_task

Optional. Called as C<< $code->($event, $item) >> before C<task_create>
creates a task (C<TaskCreated>) and before C<task_update> completes one
(C<TaskCompleted>); C<$item> is the task in the shape of L</on_update>
(C<id>, C<content>, C<description>, ...). It returns undef to go on, or the
text to hand the model as an error result: the call then changes nothing.
The application hangs the Claude Code hooks of the same names here (ADR
0022). Only the task tools call it, not C<todo_write>.

=head2 server

The L<MCP::Server> with the tool C<todo_write>, built once.

=head2 task_server

The L<MCP::Server> with the tools C<task_create>, C<task_update>,
C<task_list> and C<task_get>, built once. They share the task list of this
object.

=head2 check

    my $list = $todos->check( \@items );

The list as C<todo_write> stores it, or a croak naming the first item that
is wrong: not a hash, no C<content>, an unknown C<status>, or a second
C<in_progress> item.

=head2 render

    my $text = $todos->render($list);

The list as C<todo_write> answers it: a count line, then one line per item.

=head2 tasks

    my $list = $todos->tasks;

The task list in the shape L</on_update> gets: a copy, in id order.

=head2 clear_tasks

    $todos->clear_tasks;

Empties the task list (the application's C</clear>). Ids go on counting.

=head2 restore_tasks

    $todos->restore_tasks( $list );

Takes over a task list in the shape L</on_update> hands out (what a resumed
session's journal holds) in place of the current one, without calling
L</on_update> or L</before_task>. The next id follows the highest id of the
list.

=head2 create_task

    my ( $text, $is_error ) = $todos->create_task( { subject => 'Run the tests', description => '...' } );

What C<task_create> does and answers: a new C<pending> task with the next
id.

=head2 update_task

    my ( $text, $is_error ) = $todos->update_task( { taskId => '1', status => 'in_progress' } );

What C<task_update> does and answers: C<Updated task #ID> and the fields
that changed (C<subject>, C<description>, C<activeForm>, C<owner>,
C<metadata>, C<status>, C<blocks>, C<blockedBy>), C<Updated task #ID
deleted> for the status C<deleted>, C<Task not found> for an unknown id.

=head2 list_tasks

    my $text = $todos->list_tasks;

What C<task_list> answers: C<#ID [STATUS] SUBJECT>, with C< (OWNER)> and
C< [blocked by #A, #B]> (only the blocking tasks not completed yet), one line
per task; C<No tasks found> for none. A task whose metadata has C<_internal>
is left out.

=head2 get_task

    my $text = $todos->get_task('1');

What C<task_get> answers: the lines C<Task #ID: SUBJECT>, C<Status: ...>,
C<Description: ...>, and C<Blocked by: #A, ...> / C<Blocks: #B, ...> when
there are any; C<Task not found> for an unknown id.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::Application>

=item * L<Langertha::Raider::ToolNames>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/langertha-raider/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

L<https://raudssus.de/>

=cut

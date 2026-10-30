package Langertha::Raider::Subagent;
# ABSTRACT: Internal subagent run of raider: one agent call, its own raider, tools and journal
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;
use Future;
use Future::AsyncAwait;
use JSON::MaybeXS;
use MCP::Server;
use Path::Tiny;
use Scalar::Util qw( blessed refaddr weaken );
use Time::HiRes ();
use Langertha::Raider;
use Langertha::Raider::AgentTools;
use Langertha::Raider::Briefing;
use Langertha::Raider::FileTools::ReadState;
use Langertha::Raider::PlanTools;
use Langertha::Raider::TodoTools;
use Langertha::Raider::Worktree;


has app => (
  is       => 'ro',
  isa      => 'Langertha::Raider::Application',
  required => 1,
  weak_ref => 1,
);


has agent => (
  is       => 'ro',
  isa      => 'HashRef',
  required => 1,
);


has depth => (
  is       => 'ro',
  isa      => 'Int',
  required => 1,
);


has prompt => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);


has description => (
  is      => 'ro',
  isa     => 'Str',
  default => '',
);


has name => (
  is  => 'ro',
  isa => 'Maybe[Str]',
);


has model => (
  is  => 'ro',
  isa => 'Maybe[Str]',
);


has background => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
  writer  => '_set_background',
);


has isolation => (
  is  => 'ro',
  isa => 'Maybe[Str]',
);


has caller_root => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  builder => '_build_caller_root',
);


sub _build_caller_root { $_[0]->app->working_root }

has worktree => (
  is       => 'ro',
  isa      => 'Maybe[HashRef]',
  init_arg => undef,
  writer   => '_set_worktree',
);



sub isolated {
  my ( $self ) = @_;
  return 1 if ( $self->agent->{isolation} // '' ) eq 'worktree';
  return ( $self->isolation // '' ) eq 'worktree' ? 1 : 0;
}

sub isolation_refusal {
  my ( $self ) = @_;
  my $value = $self->agent->{isolation};
  return if !defined $value || $value eq 'worktree';
  return 'Agent \''.$self->agent->{name}.'\': isolation "'.$value.'" is not supported; use "worktree".';
}

sub working_root {
  my ( $self ) = @_;
  my $wt = $self->worktree;
  return $wt ? $wt->{root} : $self->caller_root;
}

sub worktree_name {
  my ( $self, $id ) = @_;
  return $id =~ s/\Aagent_/agent-/r;
}

sub worktree_class { 'Langertha::Raider::Worktree' }

has _git => ( is => 'ro', init_arg => undef, lazy => 1, builder => '_build__git' );

sub _build__git { $_[0]->worktree_class->new }

# True when the subagent's tools work somewhere else than the application's
# root: its file and search tools are then built for its working root, over
# its own policy.
sub _moved { $_[0]->working_root ne $_[0]->app->root ? 1 : 0 }

has task_id => (
  is        => 'ro',
  isa       => 'Str',
  writer    => '_set_task_id',
  predicate => 'has_task_id',
);


has caller_servers => (
  is       => 'ro',
  isa      => 'ArrayRef',
  required => 1,
);


has caller_session => (
  is        => 'ro',
  predicate => 'has_caller_session',
  writer    => '_set_caller_session',
);


has caller_call => (
  is     => 'ro',
  isa    => 'Maybe[Str]',
  writer => '_set_caller_call',
);


has on_caller_event => (
  is       => 'ro',
  isa      => 'CodeRef',
  required => 1,
  writer   => '_set_on_caller_event',
);


has caller_task_id => (
  is     => 'ro',
  isa    => 'Maybe[Str]',
  writer => '_set_caller_task_id',
);


has caller_detached => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
  writer  => '_set_caller_detached',
);


has caller_policy => (
  is        => 'ro',
  isa       => 'Langertha::Raider::Permissions',
  predicate => 'has_caller_policy',
);


has permissions => (
  is       => 'ro',
  isa      => 'Langertha::Raider::Permissions',
  init_arg => undef,
  lazy     => 1,
  builder  => '_build_permissions',
);


sub _build_permissions {
  my ( $self ) = @_;
  my $caller = $self->has_caller_policy ? $self->caller_policy : $self->app->permissions;
  my $wt = $self->worktree;
  return $caller->for_subrun( $wt ? (
    root               => $wt->{root},
    worktree_isolation => { top => $wt->{top}, worktree => $wt->{path} },
  ) : () );
}

has briefing => (
  is       => 'ro',
  isa      => 'Langertha::Raider::Briefing',
  init_arg => undef,
  lazy     => 1,
  builder  => '_build_briefing',
);


has briefed_prompt => (
  is       => 'ro',
  isa      => 'Str',
  init_arg => undef,
  lazy     => 1,
  builder  => '_build_briefed_prompt',
);


has sent_prompt => (
  is       => 'ro',
  isa      => 'Str',
  init_arg => undef,
  writer   => '_set_sent_prompt',
);


has agent_id => (
  is       => 'ro',
  isa      => 'Str',
  init_arg => undef,
  lazy     => 1,
  builder  => '_build_agent_id',
);


sub _build_agent_id {
  my ( $self ) = @_;
  return $self->session ? $self->session->id : 'local-agent-'.$$.'-'.refaddr($self);
}

has model_resolution => (
  is       => 'ro',
  isa      => 'HashRef',
  init_arg => undef,
  lazy     => 1,
  builder  => '_build_model_resolution',
);


has tool_servers => (
  is       => 'ro',
  isa      => 'ArrayRef',
  init_arg => undef,
  lazy     => 1,
  builder  => '_build_tool_servers',
);


has mission => (
  is       => 'ro',
  isa      => 'Str',
  init_arg => undef,
  lazy     => 1,
  builder  => '_build_mission',
);


has engine => (
  is       => 'ro',
  init_arg => undef,
  lazy     => 1,
  builder  => '_build_engine',
);


has raider => (
  is        => 'ro',
  isa       => 'Langertha::Raider',
  init_arg  => undef,
  lazy      => 1,
  builder   => '_build_raider',
  predicate => '_has_raider',
);


has session => (
  is       => 'ro',
  init_arg => undef,
  writer   => '_set_session',
);


has cancel_requested => (
  is       => 'ro',
  isa      => 'Bool',
  init_arg => undef,
  default  => 0,
  writer   => '_set_cancel_requested',
);


has todos => (
  is       => 'ro',
  isa      => 'ArrayRef',
  init_arg => undef,
  default  => sub { [] },
  writer   => '_set_todos',
);


has file_read_state => (
  is       => 'ro',
  isa      => 'Langertha::Raider::FileTools::ReadState',
  init_arg => undef,
  lazy     => 1,
  builder  => '_build_file_read_state',
);


has _own_todos       => ( is => 'ro', init_arg => undef, lazy => 1, builder => '_build_own_todos' );
has _own_file_server => ( is => 'ro', init_arg => undef, lazy => 1, builder => '_build_own_file_server' );
has _own_search_server => ( is => 'ro', init_arg => undef, lazy => 1, builder => '_build_own_search_server' );
has _own_perl_server   => ( is => 'ro', init_arg => undef, lazy => 1, builder => '_build_own_perl_server' );

has last_outcome => (
  is       => 'ro',
  isa      => 'HashRef',
  init_arg => undef,
  writer   => '_set_last_outcome',
);


has _mcps    => ( is => 'ro', init_arg => undef, lazy => 1, builder => '_build_mcps', predicate => '_has_mcps' );
has _agent_tools => ( is => 'ro', init_arg => undef, lazy => 1, builder => '_build_agent_tools' );
has _run_id  => ( is => 'rw', init_arg => undef );
has _t0      => ( is => 'rw', init_arg => undef );
has _model   => ( is => 'rw', init_arg => undef );
has _tool_uses => ( is => 'rw', init_arg => undef, default => 0 );
has _last_tokens => ( is => 'rw', init_arg => undef, default => 0 );
has _journal_failed => ( is => 'rw', init_arg => undef, default => 0 );


sub recipient { $_[0]->caller_task_id // 'main' }

sub detached { $_[0]->background || $_[0]->caller_detached ? 1 : 0 }

sub one_shot { $_[0]->agent->{one_shot} ? 1 : 0 }


sub agent_tools {
  my ( $class, %arg ) = @_;
  my ( $app, $depth, $caller ) = @arg{qw( app depth caller )};
  weaken $app;
  return Langertha::Raider::AgentTools->new(
    catalog  => $app->context->agent_catalog,
    on_spawn => sub {
      my ( $agent, $call, %ctx ) = @_;
      return $class->spawn_f( app => $app, depth => $depth, caller => $caller->(%ctx), agent => $agent, call => $call );
    },
    on_send  => sub {
      my ( $message, %ctx ) = @_;
      return $class->send_message( app => $app, depth => $depth, caller => $caller->(%ctx),
        to => $message->{to}, message => $message->{message} );
    },
  );
}

sub agent_tool_server {
  my ( $class, %arg ) = @_;
  return $class->agent_tools(%arg)->server;
}


sub spawn_f {
  my ( $class, %arg ) = @_;
  my ( $app, $depth, $c, $agent, $call ) = @arg{qw( app depth caller agent call )};
  my $sub = $class->new(
    $class->_caller_args($c),
    app            => $app,
    agent          => $agent,
    depth          => $depth + 1,
    description    => $call->{description} // '',
    prompt         => $call->{prompt},
    background     => $call->{run_in_background} ? 1 : 0,
    caller_servers => $c->{servers},
    ( defined $call->{model} ? ( model => $call->{model} ) : () ),
    ( defined $call->{name}  ? ( name  => $call->{name} )  : () ),
    ( defined $call->{isolation} ? ( isolation => $call->{isolation} ) : () ),
    ( $c->{policy} ? ( caller_policy => $c->{policy} ) : () ),
  );
  if ( defined( my $refusal = $sub->isolation_refusal ) ) {
    return Future->done( $refusal, 1 );
  }
  my $briefing = $sub->briefing;
  return Future->done( $briefing->missing_note, 1 ) if $briefing->has_missing;
  if ( defined( my $refusal = $class->limit_refusal($app) ) ) {
    return Future->done( $refusal, 1 );
  }
  return $sub->background ? Future->done( $sub->start_background ) : $sub->foreground_f;
}


sub limit_refusal {
  my ( $class, $app ) = @_;
  my $running = () = $app->tasks->running( kind => 'agent' );
  return if $running < $app->max_concurrent_agents;
  return 'Concurrent subagent limit reached ('.$running.' running). Do not retry this call now;'
    .' wait for running agents to finish.';
}

# The constructor arguments a caller hash gives (see agent_tool_server).
sub _caller_args {
  my ( $class, $c ) = @_;
  return (
    on_caller_event => $c->{event},
    caller_call     => $c->{call},
    caller_task_id  => $c->{task_id},
    caller_detached => $c->{detached} ? 1 : 0,
    ( $c->{session} ? ( caller_session => $c->{session} ) : () ),
    ( defined $c->{root} ? ( caller_root => $c->{root} ) : () ),
  );
}


sub foreground_f {
  my ( $self ) = @_;
  my $app = $self->app;
  my $briefing = $self->briefing;
  return Future->done( $briefing->missing_note, 1 ) if $briefing->has_missing;
  if ( defined( my $error = $self->_open_worktree ) ) {
    return Future->done( $error, 1 );
  }
  $self->_register;
  my $live = $app->_live_subagents;
  my $key  = refaddr $self;
  unless ( $self->detached ) {
    $live->{$key} = $self;
    weaken $live->{$key};
    $self->cancel if $app->has_run && $app->_run->{cancelled};
  }
  my $f = $self->run_f;
  $app->tasks->set( $self->task_id, future => $f );
  $f->on_ready( sub { delete $live->{$key} } );
  weaken( my $weak = $self );
  return $f->without_cancel->then( sub {
    my ( $outcome ) = @_;
    return Future->done( $weak ? $weak->result_text($outcome) : ( 'the subagent is gone', 1 ) );
  } )->on_cancel( sub { $weak->cancel if $weak } );
}

sub run {
  my ( $self ) = @_;
  my $f = $self->foreground_f;
  $self->app->loop->await($f);
  return $f->get;
}


sub start_background {
  my ( $self ) = @_;
  my $app = $self->app;
  my $briefing = $self->briefing;
  return ( $briefing->missing_note, 1 ) if $briefing->has_missing;
  if ( defined( my $error = $self->_open_worktree ) ) {
    return ( $error, 1 );
  }
  $self->_set_background(1);
  # It outlives the run it was started in: its own copy of the run rules.
  $self->permissions->own_run_rules;
  $self->_register;
  my $f = $app->loop->delay_future( after => 0 )->then( sub { $self->run_f } );
  $app->tasks->set( $self->task_id, future => $f );
  return ( $self->launch_text, 0 );
}


sub send_message {
  my ( $class, %arg ) = @_;
  my ( $app, $c, $to, $message ) = @arg{qw( app caller to message )};
  my $tasks = $app->tasks;
  my $entry = $tasks->find($to);
  unless ($entry) {
    my ( $sub, $error ) = $class->restore(%arg);
    return ( $error, 1 ) if defined $error;
    return ( 'No agent found with ID or name: '.$to, 1 ) unless $sub;
    $entry = $tasks->get( $sub->task_id );
  }
  my $id = $entry->{id};
  return ( $id.' is a background shell, not an agent; read it with bash_output.', 1 ) if $entry->{kind} eq 'bash';
  return ( $id.' is not an agent.', 1 ) unless $entry->{kind} eq 'agent' && $entry->{subagent};
  my $sub = $entry->{subagent};
  return ( 'Agent '.$id.' ('.$sub->agent->{name}.') is one-shot and cannot be continued.', 1 ) if $sub->one_shot;
  if ( $entry->{status} eq 'running' ) {
    $tasks->post( $id, $message );
    return ( 'Message queued for delivery to '.$id.' at its next tool round.', 0 );
  }
  if ( defined( my $refusal = $class->limit_refusal($app) ) ) {
    return ( $refusal, 1 );
  }
  return $sub->resume( $message, $c );
}


sub restore {
  my ( $class, %arg ) = @_;
  my ( $app, $depth, $c, $to ) = @arg{qw( app depth caller to )};
  my $parent = $c->{session} or return;
  my $store = $app->session_store;
  my ($child) = grep {
    my $created = $_->{created};
    defined $created->{agent_id} && ( $created->{agent_id} eq $to || ( defined $created->{name} && $created->{name} eq $to ) )
  } $store->children_of( $parent->id );
  return unless $child;
  my $created = $child->{created};
  my $id = $created->{agent_id};
  return if $app->tasks->get($id);
  my $type = $created->{agent} // '';
  my $agent = $app->context->agent_catalog->find($type)
    or return ( undef, 'Agent '.$id.' cannot be continued: its agent type \''.$type.'\' is not defined any more.' );
  return ( undef, 'Agent '.$id.' ('.$agent->{name}.') is one-shot and cannot be continued.' ) if $agent->{one_shot};
  my $journal = eval { $store->read( $child->{id} ) }
    or return ( undef, 'Agent '.$id.' cannot be continued: '.$class->_error_text($@) );
  my $history = $journal->history_messages;
  my ($first) = map { $_->{content} } grep { ( $_->{role} // '' ) eq 'user' } @$history;
  my $parent_journal = eval { $store->read( $parent->id ) };
  my ($started) = grep { $_->{type} eq 'agent.started' && ( $_->{session} // '' ) eq $child->{id} }
    $parent_journal ? @{ $parent_journal->events } : ();
  my $sub = $class->new(
    $class->_caller_args($c),
    app            => $app,
    agent          => $agent,
    depth          => $created->{depth} // $depth + 1,
    description    => $started && defined $started->{description} ? $started->{description} : '',
    prompt         => $first // '',
    caller_servers => $c->{servers},
    ( defined $created->{name} ? ( name => $created->{name} ) : () ),
    ( $started && defined $started->{worktree} ? ( isolation => 'worktree' ) : () ),
    ( $c->{policy} ? ( caller_policy => $c->{policy} ) : () ),
  );
  $sub->_set_task_id($id);
  if ( defined( my $refusal = $sub->isolation_refusal ) ) {
    return ( undef, $refusal );
  }
  # An isolated agent goes on in its worktree (made again on resume when it is gone).
  if ( $sub->isolated && defined( my $error = $sub->_plan_worktree ) ) {
    return ( undef, 'Agent '.$id.' cannot be continued: '.$error );
  }
  my $session = eval { $store->open( $child->{id} ) }
    or return ( undef, 'Agent '.$id.' cannot be continued: '.$class->_error_text($@) );
  $sub->_set_session($session);
  my $raider = $sub->raider;
  $raider->add_history( $_->{role}, $_->{content} ) for @$history;
  $raider->add_session_history( @{ $journal->session_history_messages } );
  $sub->_register( status => 'completed', background => 1 );
  return $sub;
}

sub _error_text {
  my ( $class, $error ) = @_;
  $error = "$error";
  $error =~ s/ at \S+ line \d+\.?\n?\z//;
  $error =~ s/\s+\z//;
  return $error;
}


sub resume {
  my ( $self, $message, $c ) = @_;
  my $app = $self->app;
  $self->_set_on_caller_event( $c->{event} );
  $self->_set_caller_call( $c->{call} );
  $self->_set_caller_task_id( $c->{task_id} );
  $self->_set_caller_detached( $c->{detached} ? 1 : 0 );
  $self->_set_caller_session( $c->{session} ) if $c->{session};
  $self->_set_background(1);
  $self->permissions->own_run_rules;
  $self->_set_cancel_requested(0);
  $self->raider->clear_cancel if $self->_has_raider;
  my $f = $app->loop->delay_future( after => 0 )->then( sub { $self->resume_f($message) } );
  $app->tasks->set( $self->task_id,
    status      => 'running',
    quiet       => 0,
    background  => 1,
    recipient   => $self->recipient,
    tool_use_id => $self->caller_call,
    future      => $f,
  );
  return ( 'Resuming agent '.$self->task_id.' in the background. You will be notified when it finishes.', 0 );
}

# Registers the subagent in the application's registry, with an agent ID
# unless it has one.
sub _register {
  my ( $self, %fields ) = @_;
  my $tasks = $self->app->tasks;
  $self->_assign_task_id;
  weaken( my $weak = $self );
  my $wt = $self->worktree;
  return $tasks->add(
    id          => $self->task_id,
    kind        => 'agent',
    agent       => $self->agent->{name},
    description => $self->description,
    name        => $self->name,
    tool_use_id => $self->caller_call,
    recipient   => $self->recipient,
    background  => $self->background,
    subagent    => $self,
    stop        => sub { $weak->cancel if $weak },
    ( $wt ? ( worktree => $wt->{path}, branch => $wt->{branch} ) : () ),
    %fields,
  );
}

# The agent ID, unless the subagent has one: the next of the registry,
# skipping those the caller's session already gave out and those $also
# says are taken (an isolated agent: a worktree or branch of that name is
# left from earlier).
sub _assign_task_id {
  my ( $self, $also ) = @_;
  return if $self->has_task_id;
  my ( $taken ) = $self->_taken_ids;
  my @taken = grep { defined } $taken, $also;
  $self->_set_task_id( $self->app->tasks->next_id( 'agent',
    @taken ? ( taken => sub { my ( $id ) = @_; scalar grep { $_->($id) } @taken } ) : () ) );
  return;
}

# The agent IDs the child sessions of the caller's session already carry
# (a resumed session), so a new agent never takes one of them.
sub _taken_ids {
  my ( $self ) = @_;
  return unless $self->has_caller_session;
  my %taken = map { defined $_->{created}{agent_id} ? ( $_->{created}{agent_id} => 1 ) : () }
    eval { $self->app->session_store->children_of( $self->caller_session->id ) };
  return sub { $taken{ $_[0] } };
}

#### The worktree of an isolated subagent (ADR 0032 section 2)

# Before the first run: the worktree planned, then made and locked. The
# error text when it cannot be (nothing starts), or nothing.
sub _open_worktree {
  my ( $self ) = @_;
  return unless $self->isolated;
  unless ( $self->worktree ) {
    my $error = $self->_plan_worktree;
    return $error if defined $error;
  }
  return $self->_ensure_worktree;
}

# Where the worktree goes: under the main checkout's top, named after the
# agent ID (given here unless the subagent has one, skipping IDs whose
# worktree directory or branch is left from earlier), the working root in
# the same subdirectory as the caller's. Sets worktree; the error text when
# the caller's root is in no git repository, or nothing.
sub _plan_worktree {
  my ( $self ) = @_;
  my $git  = $self->_git;
  my $root = $self->caller_root;
  my $top  = $git->repository_top($root);
  return 'isolation "worktree" needs a git repository; '.$root.' is not inside one.' if $top->{error};
  my $tree = $git->toplevel($root);
  return 'isolation "worktree": '.$tree->{error} if $tree->{error};
  my $dir = path( $self->app->worktrees_dir( $top->{top} ) );
  $self->_assign_task_id( sub {
    my $name = $self->worktree_name( $_[0] );
    -e $dir->child($name) || $git->branch_exists( $top->{top}, 'worktree-'.$name );
  } );
  my $name = $self->worktree_name( $self->task_id );
  my $path = $dir->child($name)->stringify;
  my $sub  = path($root)->realpath->relative( $tree->{top} )->stringify;
  $self->_set_worktree( {
    top    => $top->{top},
    source => $tree->{top},
    path   => $path,
    branch => 'worktree-'.$name,
    root   => $sub eq '.' ? $path : path($path)->child($sub)->stringify,
  } );
  return;
}

# Before every run: the worktree as it is when it still exists; else its
# branch checked out into the same path when that is left; else made anew
# from the base (Application/worktree_base_ref) with the .worktreeinclude
# copy. Then locked for the run (a lock git refuses changes nothing else).
# The error text when git cannot make it, or nothing.
sub _ensure_worktree {
  my ( $self ) = @_;
  my $wt = $self->worktree or return;
  my $git = $self->_git;
  unless ( -e path( $wt->{path} )->child('.git') ) {
    my $made;
    if ( $git->branch_exists( $wt->{top}, $wt->{branch} ) ) {
      $made = $git->checkout( dir => $wt->{top}, path => $wt->{path}, branch => $wt->{branch} );
    }
    else {
      my $base = $git->base_ref( $self->caller_root, $self->app->worktree_base_ref );
      return 'isolation "worktree": '.$base->{error} if $base->{error};
      $made = $git->create( source => $wt->{source}, path => $wt->{path}, branch => $wt->{branch}, base => $base->{commit} );
      $wt->{base} = $base->{commit} unless $made->{error};
    }
    return 'isolation "worktree": '.$made->{error} if $made->{error};
  }
  path( $wt->{root} )->mkpath unless -d $wt->{root};
  $git->lock( $wt->{path}, 'raider agent '.$self->task_id );
  return;
}

# After every run, however it ended: unlocked; without changes -- a clean
# git status (untracked files count) and no commit beyond the base -- the
# worktree and its branch removed, else both kept and named in $outcome
# (worktree => { path, branch }); a git command that fails keeps them too,
# its error in worktree_error. Never dies.
sub _close_worktree {
  my ( $self, $outcome ) = @_;
  my $wt = $self->worktree or return;
  return unless -e path( $wt->{path} )->child('.git');
  my $git = $self->_git;
  $git->unlock( $wt->{path} );
  my $error;
  my $base = $wt->{base};
  unless ( defined $base ) {
    # A worktree an earlier process made: its base as it resolves now.
    my $app = $self->app;
    my $b = $git->base_ref( $self->caller_root, $app ? $app->worktree_base_ref : 'fresh' );
    $b->{error} ? ( $error = $b->{error} ) : ( $base = $b->{commit} );
  }
  unless ( defined $error ) {
    my $changes = $git->changes( $wt->{path}, $base );
    if ( $changes->{error} ) {
      $error = $changes->{error};
    }
    elsif ( !@{ $changes->{status} } && !$changes->{commits} ) {
      my $removed = $git->remove( dir => $wt->{top}, path => $wt->{path}, branch => $wt->{branch} );
      return unless $removed->{error};
      $error = $removed->{error};
    }
  }
  $outcome->{worktree} = { path => $wt->{path}, branch => $wt->{branch} };
  $outcome->{worktree_error} = $error if defined $error;
  return;
}

# The lines a result names a kept worktree with (ADR 0027 section 2).
sub _worktree_lines {
  my ( $self, $outcome ) = @_;
  my $wt = $outcome->{worktree} or return;
  return (
    'worktreePath: '.$wt->{path},
    'worktreeBranch: '.$wt->{branch},
    ( defined $outcome->{worktree_error} ? 'worktree kept: '.$outcome->{worktree_error} : () ),
  );
}


async sub run_f {
  my ( $self ) = @_;
  my $briefing = $self->briefing;
  return { status => 'refused', error => $briefing->missing_note } if $briefing->has_missing;
  return await $self->_run_with_f( sub { $self->_raid_f } );
}

async sub resume_f {
  my ( $self, $message ) = @_;
  return await $self->_run_with_f( sub { $self->_resume_raid_f($message) } );
}

async sub _run_with_f {
  my ( $self, $code ) = @_;
  $self->_t0( Time::HiRes::time() );
  $self->_tool_uses(0);
  my $outcome = await Future->call($code)->then(
    sub { Future->done( $self->_outcome_of( $_[0] ) ) },
    sub {
      my ( $error ) = @_;
      $error = "$error";
      $error =~ s/\s+\z//;
      Future->done( { status => 'failed', error => $error } );
    },
  );
  await $self->_end_children_f;
  $outcome->{usage} = $self->usage_pairs;
  $self->_finish($outcome);
  return $outcome;
}

async sub _raid_f {
  my ( $self ) = @_;
  $self->_open_session;
  my $start = await $self->_subagent_start_f;
  $self->_begin($start);
  die 'a SubagentStart hook stopped it'.( defined $start->stop_reason ? ': '.$start->stop_reason : '' )."\n"
    if $start && $start->stopped;
  await $self->_initialize_mcps_f;
  my $raider = $self->raider;
  $raider->cancel if $self->cancel_requested;
  my $result = await $raider->raid_f( $self->sent_prompt );
  return await $self->_until_done_f($result);
}

async sub _resume_raid_f {
  my ( $self, $message ) = @_;
  $self->_reopen_session;
  # Its worktree again: as it is, back on its branch, or anew (ADR 0032 section 2).
  my $wt_error = $self->_ensure_worktree;
  $self->_begin_resume($message);
  die $wt_error."\n" if defined $wt_error;
  await $self->_initialize_mcps_f;
  my $raider = $self->raider;
  $raider->cancel if $self->cancel_requested;
  my $result = await $raider->raid_f($message);
  return await $self->_until_done_f($result);
}

# The subagent's own clients of the tool set on the loop (again, for a
# continued run) and initialized. A view of a configured MCP server (ADR
# 0029) is no notifier: it rides on the application's connection, which
# stays where it is.
async sub _initialize_mcps_f {
  my ( $self ) = @_;
  my $loop = $self->app->loop;
  for my $mcp ( @{ $self->_mcps } ) {
    $loop->add($mcp) if blessed $mcp && $mcp->isa('IO::Async::Notifier') && !$mcp->loop;
    await $mcp->initialize;
  }
  return;
}

# After a final answer: SubagentStop (_after_answer_f), then the
# notifications and messages that wait or are still to come from running
# background children, as the next message; until an answer leaves nothing.
async sub _until_done_f {
  my ( $self, $result ) = @_;
  while (1) {
    $result = await $self->_after_answer_f($result);
    return $result unless blessed $result && $result->can('is_final') && $result->is_final;
    return $result if $self->cancel_requested;
    return $result unless await $self->_wait_messages_f;
    $self->event( 'message', role => 'assistant', content => "$result" );
    $result = await $self->raider->raid_f( $self->_take_messages );
  }
}

# True once something waits for this subagent in the registry; while
# nothing does but background children of it run, waits for them on the
# loop. False when neither, or once the subagent is cancelled.
async sub _wait_messages_f {
  my ( $self ) = @_;
  my $app = $self->app or return 0;
  return 0 unless $self->has_task_id;
  my $tasks = $app->tasks;
  my $me = $self->task_id;
  while (1) {
    return 1 if $tasks->pending($me);
    return 0 unless $tasks->running( kind => 'agent', recipient => $me, background => 1 );
    await $self->raider->_until_cancelled( $tasks->wait_f($me) );
    return 0 if $self->cancel_requested;
  }
}

# Takes what waits for this subagent in the registry as user messages and
# journals each (a notification with notification 1). Returns the texts.
sub _take_messages {
  my ( $self ) = @_;
  my $app = $self->app or return;
  return unless $self->has_task_id;
  my @texts;
  for my $m ( $app->tasks->take_messages( $self->task_id ) ) {
    $self->event( 'message', role => 'user', content => $m->{content}, ( $m->{notification} ? ( notification => 1 ) : () ) );
    push @texts, $m->{content};
  }
  return @texts;
}

# A run that ends while child agents of it still run stops them and waits
# for their end; what waits for this subagent is dropped. Its background
# shells stay: they belong to the application (ADR 0024).
async sub _end_children_f {
  my ( $self ) = @_;
  my $app = $self->app or return;
  return unless $self->has_task_id;
  my $tasks = $app->tasks;
  my @running = $tasks->running( kind => 'agent', recipient => $self->task_id );
  $tasks->stop( $_->{id} ) for @running;
  # Its monitors end with it: nobody is left to read their events (ADR 0031).
  $tasks->stop( $_->{id}, quiet => 1 ) for $tasks->running( kind => 'monitor', recipient => $self->task_id );
  my @futures = grep { defined && !$_->is_ready } map { $_->{future} } @running;
  await Future->wait_all(@futures) if @futures;
  $tasks->discard( $self->task_id );
  return;
}

# The pairs every hook input of this subagent carries besides the caller's
# session fields (ADR 0022 section 5); its cwd is the subagent's working
# root (ADR 0032 §3).
sub _hook_fields {
  my ( $self ) = @_;
  return (
    agent_id        => $self->agent_id,
    agent_type      => $self->agent->{name},
    permission_mode => $self->permissions->mode,
    cwd             => $self->working_root,
  );
}

# SubagentStart (Claude layout): resolves to its Hooks::Result, or undef when
# no hook is configured. Reported to the caller's stream.
sub _subagent_start_f {
  my ( $self ) = @_;
  my $app   = $self->app;
  my $hooks = $app->hooks;
  return Future->done(undef) unless $hooks && $hooks->has_hooks('SubagentStart');
  return $hooks->run_f( SubagentStart => $app->_hook_input( $self->_hook_fields ) )->then( sub {
    my ( $r ) = @_;
    $app->_report_hooks( $r, $self->on_caller_event );
    return Future->done($r);
  } );
}

# SubagentStop after a final answer, as the application's Stop hooks for the
# main run: a block or additionalContext sends the feedback back as the next
# message (stop_hook_active true), at most stop_hook_limit times; the turns
# in between go into the subagent's journal. Resolves to the last result.
async sub _after_answer_f {
  my ( $self, $result ) = @_;
  my $app   = $self->app;
  my $hooks = $app ? $app->hooks : undef;
  return $result unless $hooks;
  my $active = 0;
  for ( my $round = 0; ; $round++ ) {
    return $result unless blessed $result && $result->can('is_final') && $result->is_final;
    return $result if $self->cancel_requested;
    return $result unless $hooks->has_hooks('SubagentStop');
    my $r = await $hooks->run_f( SubagentStop => $app->_hook_input(
      $self->_hook_fields,
      ( $self->session ? ( agent_transcript_path => ''.$self->session->path ) : () ),
      stop_hook_active       => $active ? JSON::MaybeXS->true : JSON::MaybeXS->false,
      last_assistant_message => "$result",
    ) );
    $app->_report_hooks( $r, $self->on_caller_event );
    return $result if $r->stopped;
    my @feedback = ( $r->blocked ? ( @{ $r->reasons } ? @{ $r->reasons } : '(no reason given)' ) : () ),
      ( defined $r->context ? $r->context : () );
    return $result unless @feedback;
    if ( $round >= $app->stop_hook_limit ) {
      $self->on_caller_event->( 'hook.message', hook_event => 'SubagentStop', kind => 'error',
        text => 'SubagentStop hooks kept agent \''.$self->agent->{name}.'\' going '.$app->stop_hook_limit
          .' times in a row; it ends here' );
      return $result;
    }
    my $feedback = "SubagentStop hook feedback:\n".join( "\n", @feedback );
    $self->event( 'message', role => 'assistant', content => "$result" );
    $self->event( 'message', role => 'user', content => $feedback, hook => 'SubagentStop' );
    $active = 1;
    $result = await $self->raider->raid_f($feedback);
  }
}


sub approval_binding {
  my ( $self ) = @_;
  my $session = $self->session or return;
  return ( session_id => $session->id, ( defined $self->_run_id ? ( run_id => $self->_run_id ) : () ) );
}


sub cancel {
  my ( $self ) = @_;
  $self->_set_cancel_requested(1);
  $self->raider->cancel if $self->_has_raider;
  my $app = $self->app;
  if ( $app && $self->has_task_id ) {
    my $tasks = $app->tasks;
    $tasks->stop( $_->{id} ) for $tasks->running( kind => 'agent', recipient => $self->task_id );
  }
  return;
}


sub event {
  my ( $self, $type, %payload ) = @_;
  $self->_tool_uses( $self->_tool_uses + 1 ) if $type eq 'tool.call';
  $self->_last_tokens( ( $payload{input_tokens} // 0 ) + ( $payload{output_tokens} // 0 ) )
    if $type eq 'model.usage' && ( $payload{purpose} // 'chat' ) eq 'chat';
  my $app = $self->app or return;
  $self->_append( $type, run => $self->_run_id, %payload ) if $app->is_journal_type($type);
  return;
}


sub usage_pairs {
  my ( $self ) = @_;
  my $tokens = $self->_last_tokens;
  my $t0 = $self->_t0 // Time::HiRes::time();
  return [
    subagent_tokens => 0 + $tokens,
    tool_uses       => 0 + $self->_tool_uses,
    duration_ms     => int( ( Time::HiRes::time() - $t0 ) * 1000 ),
  ];
}


sub agent_id_line {
  my ( $self ) = @_;
  my $id = $self->task_id;
  return 'agentId: '.$id if $self->one_shot;
  return 'agentId: '.$id.' (use send_message with to: \''.$id.'\' to continue this agent)';
}


sub result_text {
  my ( $self, $outcome ) = @_;
  my $status = $outcome->{status};
  return ( $outcome->{error}, 1 ) if $status eq 'refused';
  my $who = 'Agent \''.$self->agent->{name}.'\''.( $self->one_shot || !$self->has_task_id ? '' : ' ('.$self->task_id.')' );
  my @worktree = $self->_worktree_lines($outcome);
  return ( join( "\n", $who.' was cancelled.', @worktree ), 1 ) if $status eq 'cancelled';
  return ( join( "\n", $who.' failed: '.$outcome->{error}, @worktree ), 1 ) unless $status eq 'completed';
  my @usage = @{ $outcome->{usage} // $self->usage_pairs };
  my @lines;
  while ( my ( $k, $v ) = splice @usage, 0, 2 ) {
    push @lines, $k.': '.$v;
  }
  return ( join( "\n",
    $outcome->{text} // '',
    ( $self->one_shot ? () : $self->agent_id_line ),
    '<usage>'.join( "\n", @lines ).'</usage>',
    @worktree,
  ), 0 );
}


sub launch_text {
  my ( $self ) = @_;
  return join "\n",
    'Async agent launched successfully.',
    $self->agent_id_line,
    "The agent is working in the background. You will be notified automatically when it completes. You know nothing about its results until that notification arrives \x{2014} do not report, assume, or predict them; continue other work or respond to the user in the meantime.",
    "Do not duplicate this agent's work \x{2014} avoid working with the same files or topics it is using.";
}


sub notification {
  my ( $self, $outcome ) = @_;
  my $tasks  = $self->app->tasks;
  my $status = $self->_registry_status( $outcome->{status} );
  my $label  = length $self->description ? $self->description : $self->agent->{name};
  my ( $summary, $verb ) = $status eq 'completed' ? ( 'Agent "'.$label.'" finished', 'finished' )
                         : $status eq 'killed'    ? ( 'Agent "'.$label.'" was stopped', 'was stopped' )
                         :                          ( 'Agent "'.$label.'" failed: '.( $outcome->{error} // 'unknown error' ), 'failed' );
  my $text = $tasks->notification_text(
    task_id     => $self->task_id,
    tool_use_id => $self->caller_call,
    status      => $status,
    summary     => $summary,
    ( $status eq 'completed' ? ( result => join( "\n", $outcome->{text} // '',
      ( defined $outcome->{worktree_error} ? 'worktree kept: '.$outcome->{worktree_error} : () ) ) ) : () ),
    usage       => $outcome->{usage} // $self->usage_pairs,
    ( $outcome->{worktree} ? ( worktree => $outcome->{worktree} ) : () ),
  );
  return ( $text, 'background agent '.$self->task_id.' '.$verb );
}

# The registry status of an outcome status.
sub _registry_status {
  my ( $self, $status ) = @_;
  return $status eq 'completed' ? 'completed' : $status eq 'cancelled' ? 'killed' : 'failed';
}

# The subagent's own session (when the caller has one) and its run id.
sub _open_session {
  my ( $self ) = @_;
  my $app = $self->app;
  if ( $self->has_caller_session ) {
    my $session = eval {
      $app->session_store->create(
        parent => $self->caller_session->id,
        ( defined $self->caller_call ? ( parent_call => $self->caller_call ) : () ),
        agent  => $self->agent->{name},
        depth  => $self->depth,
        ( $self->has_task_id ? ( agent_id => $self->task_id ) : () ),
        ( defined $self->name ? ( name => $self->name ) : () ),
      );
    };
    if ($session) {
      $self->_set_session($session);
      $self->_run_id( $session->next_run );
    }
    else {
      $self->_report_journal_error( $self->caller_session, $@ );
    }
  }
  return;
}

# The child session again for a continued run: opened anew when the last
# run released it.
sub _reopen_session {
  my ( $self ) = @_;
  my $session = $self->session or return;
  unless ( $session->is_open ) {
    my $again = eval { $self->app->session_store->open( $session->id ) };
    unless ($again) {
      $self->_report_journal_error( $session, $@ );
      return;
    }
    $session = $again;
    $self->_set_session($session);
  }
  $self->_journal_failed(0);
  $self->_run_id( $session->next_run );
  return;
}

# agent.started and the start of the journal; $start is SubagentStart's
# result (or undef): its context goes in front of the briefed prompt, its
# stop leaves the prompt unsent.
sub _begin {
  my ( $self, $start ) = @_;
  my $app = $self->app;
  my $model = eval { $self->engine->chat_model };
  $self->_model($model);
  $self->on_caller_event->( 'agent.warning', $self->_defined(
    call    => $self->caller_call,
    agent   => $self->agent->{name},
    message => $self->briefing->size_note,
  ) ) if $self->briefing->oversized;
  $self->_agent_started;
  $self->event( 'run.started', engine => $app->engine_name, defined $model ? ( model => $model ) : () );
  return if $start && $start->stopped;
  my $context = $start ? $start->context : undef;
  $self->_set_sent_prompt( join "\n\n",
    ( defined $context ? "<system-reminder>\nSubagentStart hook additional context: ".$context."\n</system-reminder>" : () ),
    $self->briefed_prompt );
  $self->event( 'message', role => 'user', content => $self->sent_prompt );
  return;
}

# agent.started and the start of the journal of a continued run.
sub _begin_resume {
  my ( $self, $message ) = @_;
  my $model = eval { $self->engine->chat_model };
  $self->_model($model);
  $self->_agent_started( resumed => JSON::MaybeXS->true );
  $self->event( 'run.started', engine => $self->app->engine_name, defined $model ? ( model => $model ) : () );
  $self->event( 'message', role => 'user', content => $message );
  return;
}

sub _agent_started {
  my ( $self, %more ) = @_;
  my $wt = $self->worktree;
  $self->on_caller_event->( 'agent.started', $self->_defined(
    call        => $self->caller_call,
    agent       => $self->agent->{name},
    agent_id    => $self->has_task_id ? $self->task_id : undef,
    background  => $self->background ? JSON::MaybeXS->true : JSON::MaybeXS->false,
    description => $self->description,
    session     => $self->session ? $self->session->id : undef,
    model       => $self->_model,
    worktree    => $wt ? $wt->{path} : undef,
    branch      => $wt ? $wt->{branch} : undef,
    %more,
  ) );
  return;
}

sub _outcome_of {
  my ( $self, $result ) = @_;
  return { status => 'cancelled' } if blessed $result && $result->can('is_cancelled') && $result->is_cancelled;
  return { status => 'cancelled' } if $self->cancel_requested;
  return { status => 'completed', text => "$result" };
}

# The end of a run: the journal, agent.finished, the registry entry and --
# in the background -- the notification for the recipient, last.
sub _finish {
  my ( $self, $outcome ) = @_;
  my $app = $self->app;
  $self->_close_worktree($outcome);
  $self->_set_last_outcome($outcome);
  $self->event( 'message', role => 'assistant', content => $outcome->{text} ) if $outcome->{status} eq 'completed';
  if ( my $session = $self->session ) {
    my $metrics = $self->_has_raider ? $self->raider->metrics : undef;
    $self->_append( 'run.finished', $self->_defined(
      run     => $self->_run_id,
      status  => $outcome->{status},
      error   => $outcome->{error},
      elapsed => 0 + sprintf( '%.3f', Time::HiRes::time() - ( $self->_t0 // Time::HiRes::time() ) ),
      metrics => $metrics,
    ) );
    $session->release;
  }
  # Its own clients leave the loop; the application's MCP connections (the
  # views' servers) are not its to stop.
  if ( $self->_has_mcps && $app ) {
    $_->loop->remove($_) for grep { blessed $_ && $_->isa('IO::Async::Notifier') && $_->loop } @{ $self->_mcps };
  }
  $self->on_caller_event->( 'agent.finished', $self->_defined(
    call     => $self->caller_call,
    agent    => $self->agent->{name},
    agent_id => $self->has_task_id ? $self->task_id : undef,
    session  => $self->session ? $self->session->id : undef,
    status   => $outcome->{status},
    ( $self->worktree ? ( worktree_kept => $outcome->{worktree} ? JSON::MaybeXS->true : JSON::MaybeXS->false ) : () ),
  ) );
  return unless $app && $self->has_task_id;
  my $tasks = $app->tasks;
  my $kept = $outcome->{worktree};
  my $entry = $tasks->finish( $self->task_id, $self->_registry_status( $outcome->{status} ),
    report => $outcome->{text},
    error  => $outcome->{error},
    usage  => $outcome->{usage},
    ( $self->worktree ? ( worktree => $kept ? $kept->{path} : undef, branch => $kept ? $kept->{branch} : undef ) : () ),
  );
  my $notifies = $self->background && !$entry->{quiet};
  if ($notifies) {
    my ( $text, $label ) = $self->notification($outcome);
    $tasks->notify( $self->recipient, $text, id => $self->task_id, label => $label );
  }
  # A cancelled run whose result nobody reads -- a new conversation, leaving
  # raider, a cancelled turn -- names its kept worktree to the person.
  $app->note_meta( 'agent '.$self->task_id.' left its worktree '.$kept->{path}.' on branch '.$kept->{branch} )
    if $kept && $outcome->{status} eq 'cancelled' && ( !$notifies || $app->leaving );
  return;
}

# The pairs whose value is defined.
sub _defined {
  my ( $self, @pairs ) = @_;
  my @out;
  while ( my ( $k, $v ) = splice @pairs, 0, 2 ) {
    push @out, $k => $v if defined $v;
  }
  return @out;
}

sub _append {
  my ( $self, $type, %fields ) = @_;
  my $session = $self->session or return;
  return 1 if eval { $session->append( $type, %fields ); 1 };
  $self->_report_journal_error( $session, $@ ) unless $self->_journal_failed;
  $self->_journal_failed(1);
  return 0;
}

sub _report_journal_error {
  my ( $self, $session, $error ) = @_;
  my $app = $self->app;
  if ( $app && $app->has_on_journal_error ) {
    $app->on_journal_error->( $session, $error );
  }
  else {
    warn 'subagent session of '.$session->id.' not fully saved: '.$error;
  }
  return;
}

# Tools an agent file's tools / disallowedTools name together (ADR 0025):
# each name of a family stands for all of it -- the task-list family is one
# whichever of its two shapes is mounted, multi_edit is edit_file with more
# edits -- and bash brings the tools that read and stop its background
# shells (those alone do not bring bash).
my @FAMILY = (
  [ [qw( todo_write task_create task_update task_list task_get )] => [qw( todo_write task_create task_update task_list task_get )] ],
  [ [qw( edit_file multi_edit )] => [qw( edit_file multi_edit )] ],
  [ [qw( bash )] => [qw( bash_output kill_shell )] ],
);

# Tools a subagent never has: nobody can answer it (ask_user), and only the
# main session can enter plan mode (enter_plan_mode) or move into a worktree
# and out (enter_worktree, exit_worktree; ADR 0032 §4). The cron tools are the
# session's: a scheduled prompt runs in the main conversation (ADR 0031).
my @NEVER = qw( ask_user enter_plan_mode enter_worktree exit_worktree cron_create cron_delete cron_list );

sub _with_families {
  my ( $self, @names ) = @_;
  my %set = map { $_ => 1 } @names;
  for my $f (@FAMILY) {
    my ( $by, $brings ) = @$f;
    next unless grep { $set{$_} } @$by;
    $set{$_} = 1 for @$brings;
  }
  return %set;
}

# The file tools are the subagent's own, over its own read state; the
# task-list tools its own, over its own list. The search tools and the Perl
# tools -- every tool bound to a root -- are its own too, working in its
# working root: the main run's follow the application's working root (ADR
# 0032 §3), a subagent stays where it started.
sub _own_tools {
  my ( $self ) = @_;
  my $nested = $self->depth < $self->app->max_agent_depth;
  my %own = (
    exit_plan_mode => sub { $self->_own_plan_tool },
    agent          => sub { $nested ? $self->_own_agent_tool('agent') : undef },
    send_message   => sub { $nested ? $self->_own_agent_tool('send_message') : undef },
  );
  my $perl = grep { $_->name eq $self->perl_server_name } @{ $self->caller_servers };
  for my $server ( $self->_own_file_server, $self->_own_todos->server, $self->_own_todos->task_server,
    $self->_own_search_server, ( $perl ? $self->_own_perl_server : () ) ) {
    for my $tool ( @{ $server->tools } ) {
      $own{ $tool->name } = sub { $tool };
    }
  }
  return %own;
}


sub perl_server_name { 'raider-perl' }

sub _build_tool_servers {
  my ( $self ) = @_;
  my $agent = $self->agent;
  my %allow = $self->_with_families( @{ $agent->{tools} // [] } );
  my %deny  = ( $self->_with_families( @{ $agent->{disallowed} // [] } ), map { $_ => 1 } @NEVER );
  my $all   = !defined $agent->{tools};
  my %own   = $self->_own_tools;
  # send_message goes with agent: allowed when agent is, unless denied itself.
  my $ok = sub {
    my ( $name ) = @_;
    return 0 if $deny{$name};
    return $all || $allow{$name} ? 1 : 0 unless $name eq 'send_message';
    return !$deny{agent} && ( $all || $allow{agent} || $allow{send_message} ) ? 1 : 0;
  };
  my @servers;
  for my $server ( @{ $self->caller_servers } ) {
    my @tools = @{ $server->tools };
    my @kept = map { $own{ $_->name } ? ( $own{ $_->name }->() // () ) : $_ } grep { $ok->( $_->name ) } @tools;
    next unless @kept;
    my $same = @kept == @tools && !grep { refaddr $kept[$_] != refaddr $tools[$_] } 0 .. $#kept;
    push @servers, $same ? $server : MCP::Server->new( name => $server->name, version => $server->version, tools => \@kept );
  }
  return \@servers;
}

sub _build_own_todos {
  my ( $self ) = @_;
  weaken( my $weak = $self );
  return Langertha::Raider::TodoTools->new(
    on_update => sub {
      my ( $list ) = @_;
      my $sub = $weak or return;
      $sub->_set_todos($list);
      $sub->event( 'todo.updated', todos => [ map { { %$_ } } @$list ] );
    },
    # TaskCreated / TaskCompleted as in the main run, with this subagent's
    # hook fields; the reports go to its journal, a stop cancels it.
    before_task => sub {
      my ( $event, $task ) = @_;
      my $sub = $weak or return;
      my $app = $sub->app or return;
      return $app->_task_hook( $event, $task,
        input    => sub { $weak ? $weak->_hook_fields : () },
        on_event => sub { $weak->event(@_) if $weak },
        on_stop  => sub { $weak->cancel if $weak },
      );
    },
  );
}

sub _build_own_file_server {
  my ( $self ) = @_;
  weaken( my $weak = $self );
  return $self->app->_file_tools_server(
    read_state  => $self->file_read_state,
    sees_images => sub { $weak && $weak->app ? $weak->app->_engine_sees_images( $weak->engine ) : 0 },
    reads_pdf   => sub { $weak && $weak->app ? $weak->app->_engine_reads_pdf( $weak->engine ) : 0 },
    $self->_moved_tools_args,
  );
}

# The search tools of the subagent, in its working root -- with its own
# policy when that is not the application's root (_moved).
sub _build_own_search_server {
  my ( $self ) = @_;
  return $self->app->_search_tools_server( $self->_moved_tools_args );
}

# The Perl tools of the subagent, running in its working root, with the
# private lib of the application's root.
sub _build_own_perl_server {
  my ( $self ) = @_;
  return $self->app->_perl_tools_server( root => $self->working_root );
}

# What the file and search tools of a subagent working in another root
# (_moved: a worktree) are built with: that root, and its own policy.
sub _moved_tools_args {
  my ( $self ) = @_;
  return unless $self->_moved;
  weaken( my $weak = $self );
  return ( root => $self->working_root, policy => sub { $weak ? $weak->permissions : undef } );
}

sub _build_file_read_state { Langertha::Raider::FileTools::ReadState->new }

# The tool $name (agent or send_message) of this subagent's own agent tool
# server, for a caller at its depth.
sub _own_agent_tool {
  my ( $self, $name ) = @_;
  my ($tool) = grep { $_->name eq $name } @{ $self->_agent_tools->server->tools };
  return $tool;
}

# The agent tools of a caller at this subagent's depth: the call id comes
# with each call (its context), so calls that run at the same time keep
# theirs.
sub _build_agent_tools {
  my ( $self ) = @_;
  weaken( my $weak = $self );
  return ref($self)->agent_tools(
    app    => $self->app,
    depth  => $self->depth,
    caller => sub {
      my ( %ctx ) = @_;
      return {
        servers  => $weak->tool_servers,
        session  => $weak->session,
        call     => $ctx{call} // $ctx{id},
        event    => sub { $weak->event(@_) if $weak },
        policy   => $weak->permissions,
        task_id  => $weak->has_task_id ? $weak->task_id : undef,
        detached => $weak->detached,
        root     => $weak->working_root,
      };
    },
  );
}

# exit_plan_mode of the subagent: nobody reviews a subagent's plan and its
# mode never changes the caller's, so in plan mode the plan is its answer.
sub _own_plan_tool {
  my ( $self ) = @_;
  weaken( my $weak = $self );
  return Langertha::Raider::PlanTools->new( handler => sub {
    my $sub = $weak or return ( 'the subagent is gone', 1 );
    # Claude Code's words (ADR 0026), without its pointer to enter_plan_mode,
    # which a subagent does not have.
    return ( '<tool_use_error>You are not in plan mode. If your plan was already approved, continue with '
      .'implementation.</tool_use_error>', 1 )
      unless $sub->permissions->mode eq 'plan';
    return ( 'Nobody can approve the plan in a subagent. Stay in plan mode and give the plan as your final'
      .' answer; the caller gets it.', 0 );
  } )->server->tools->[0];
}


sub briefing_class { 'Langertha::Raider::Briefing' }

sub _build_briefing {
  my ( $self ) = @_;
  return $self->briefing_class->new(
    agent    => $self->agent->{name},
    skills   => [ @{ $self->agent->{skills} // [] } ],
    resolver => $self->app->context->skill_resolver,
  );
}

sub _build_briefed_prompt {
  my ( $self ) = @_;
  return $self->briefing->prompt( $self->prompt );
}

sub _build_model_resolution {
  my ( $self ) = @_;
  my $app = $self->app;
  return $app->context->agent_catalog->resolve_model( $self->model // $self->agent->{model},
    engine_class => scalar eval { $app->_engine_class },
    engine_name  => $app->engine_name,
    agent_models => $app->agent_models,
  );
}

sub _build_mission {
  my ( $self ) = @_;
  return $self->app->compile_mission( $self->agent->{body} // '', $self->tool_servers,
    memory => $self->agent->{memory} // 1, working_directory => $self->working_root );
}

sub _build_mcps {
  my ( $self ) = @_;
  my $app = $self->app;
  # The caller's configured MCP servers lead, as views by the agent's tools
  # (same connections, same engine:N for the policy; ADR 0029).
  return [ $app->configured_mcp->views( tools => $self->agent->{tools}, disallowed => $self->agent->{disallowed} ),
    map { $app->_mcp_client($_) } @{ $self->tool_servers } ];
}

sub _build_engine {
  my ( $self ) = @_;
  my $model = $self->model_resolution->{model};
  return $self->app->build_subagent_engine( mcp_servers => $self->_mcps,
    defined $model ? ( model => $model ) : () );
}

sub _build_raider {
  my ( $self ) = @_;
  my $app = $self->app;
  weaken( my $weak = $self );
  my %hook = (
    input   => sub { $weak ? $weak->_hook_fields : () },
    on_stop => sub { $weak->cancel if $weak },
  );
  return Langertha::Raider->new(
    _tool_gate                 => $app->tool_gate(
      policy     => $self->permissions,
      on_event   => sub { $weak->event(@_) if $weak },
      binding    => sub { $weak ? $weak->approval_binding : () },
      unattended => sub { $weak && $weak->detached ? 'this agent runs in the background' : undef },
    ),
    ( $app->context->claude_layout
      ? ( _tool_hook => $app->tool_hook( %hook, on_event => sub { $weak->event(@_) if $weak } ) ) : () ),
    # agent and send_message run on the loop (ADR 0027 section 9); the shell
    # tools know this run as their caller (its notifications, detached).
    async_tools                => {
      ( $self->depth < $app->max_agent_depth ? %{ $self->_agent_tools->async_tools } : () ),
      %{ $app->_shell_async_tools(
        recipient => sub { $weak && $weak->has_task_id ? $weak->task_id : 'main' },
        detached  => sub { $weak ? $weak->detached : 0 },
        working_directory => sub { $weak ? $weak->working_root : undef },
      ) },
    },
    engine                     => $self->engine,
    mission                    => $self->mission,
    max_iterations             => $app->max_iterations,
    max_context_tokens         => $app->max_context_tokens,
    context_compress_threshold => $app->context_compress_threshold,
    plugins                    => [ $app->run_plugins( sub { $weak->event(@_) if $weak }, %hook ) ],
    on_iteration               => sub { $weak ? [ $weak->_take_messages ] : undef },
  );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Subagent - Internal subagent run of raider: one agent call, its own raider, tools and journal

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    # The agent tools of a run at depth 0 (what the application mounts):
    my $agent_tools = Langertha::Raider::Subagent->agent_tools(
      app    => $app,
      depth  => 0,
      caller => sub { my ( %ctx ) = @_; {    # %ctx: the agent call's context
        servers  => $app->_tool_servers,      # the caller's active tool set
        session  => $session,                 # or undef
        call     => $ctx{call},               # the agent call's id (c3)
        event    => sub { $app->event(@_) },  # the caller's event stream
        policy   => $app->permissions,        # the caller's permission policy
        task_id  => undef,                    # the calling subagent's agent ID
        detached => 0,                        # the caller runs in the background
        root     => $app->root,               # the caller's working root
      } },
    );
    my $server = $agent_tools->server;        # agent, send_message
    my $raider = Langertha::Raider->new( ..., async_tools => $agent_tools->async_tools );

    # What one agent call does:
    my $sub = Langertha::Raider::Subagent->new(
      app => $app, agent => $agent, depth => 1, prompt => 'Find ...',
      caller_servers => \@servers, on_caller_event => sub { ... },
      caller_policy => $app->permissions,
    );
    my ( $text, $is_error ) = await $sub->foreground_f; # foreground, on the loop
    my ( $text, $is_error ) = $sub->start_background;   # 'Async agent launched successfully. ...'

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

The subagent run of ADR 0020 E<sect>4 and ADR 0027: one call of the
C<agent> tool (L<Langertha::Raider::AgentTools>) becomes a new
L<Langertha::Raider> in the same process, on the loop of the L</app> (ADR
0016). In the foreground the call's result is the subagent's last assistant
text with its agent ID and usage (L</result_text>); in the background
(C<run_in_background>) the call answers at once (L</launch_text>) and the
end of the run is a C<< <task-notification> >> for the caller
(L</notification>).

=over

=item * B<Agent ID and registry> (ADR 0027 E<sect>1). Every run that
starts gets an agent ID, C<agent_N> (L</task_id>), and an entry in the
application's L<Langertha::Raider::Tasks> -- status, description, name,
the C<agent> call id, its caller (the I<recipient> of its notifications:
C<main>, or the agent ID of the calling subagent), the report and usage of
its last run, and the subagent itself. The entry stays after the run, so
C<send_message> can continue the agent (L</send_message>). The ID skips the
agent IDs of the earlier child sessions of the caller's session (a resumed
session), so it never names two agents there.

=item * B<Own context.> The raider starts with an empty history and gets
only the prompt. Its mission is compiled by the application like the
caller's (L<Langertha::Raider::Application/compile_mission>), with the
agent's body in the place of the persona and the native instructions --
what C<-M> replaces (ADR 0014). An agent without memory (C<memory> 0: the
built-ins C<Explore> and C<Plan>, ADR 0027 E<sect>6) gets no Claude
memory, no F<AGENTS.md> and no packs, only its body, the skill listing
when its set has C<skill>, and its tools.

=item * B<Own tool set> (L</tool_servers>). The caller's active set, each
tool kept when the agent's C<tools> allows it and C<disallowedTools> does
not. A name there stands for its family (ADR 0025): the task-list tools
(C<todo_write>, C<task_create>, C<task_update>, C<task_list>, C<task_get>)
are one, so are C<edit_file> and C<multi_edit>, and C<bash> brings
C<bash_output> and C<kill_shell>. C<ask_user> always goes (nobody can
answer a subagent), and so does C<enter_plan_mode> (only the main session
enters plan mode). The task-list tools get an instance of their own, so the
subagent's list never overwrites the caller's; the file tools get one over
the subagent's own L</file_read_state>, so it reads a file before it writes
it, as the caller must (ADR 0023); background shells stay the
application's. C<agent> and C<send_message> get instances for this depth --
or go, when this run is at
L<Langertha::Raider::Application/max_agent_depth>. C<send_message> stays
exactly when C<agent> does (and is not disallowed itself). A server whose
tools all stay is mounted as it is; otherwise a new L<MCP::Server> carries
the tools that stay. Prompt and catalogue derive from this set alone; the
skill listing stays only when the set has the C<skill> tool.

=item * B<Briefing> (L</briefing>, ADR 0020 E<sect>6). The skills the agent
declares are resolved through L<Langertha::Raider::Context/skill_resolver>
and put in front of the prompt in the briefing plugin's format
(L<Langertha::Raider::Briefing>); that is the subagent's prompt
(L</briefed_prompt>). A skill that does not resolve refuses the call: the
result is the error C<briefing: agent 'NAME' references unknown skill(s):
a, b>, and nothing starts -- no agent ID, no session, no C<agent.started>,
no request. Above 64 kB of skill text the run goes ahead, and the caller's
stream and journal get C<agent.warning> (C<call>, C<agent>, C<message>:
the size note) before C<agent.started>.

=item * B<Permissions> (L</permissions>, ADR 0021). The caller's policy
through L<Langertha::Raider::Permissions/for_subrun>: the mode the caller
has when the call starts, the same rules and additional directories, and
the B<same> session rules. Every tool call of the subagent passes the
application's gate (L<Langertha::Raider::Application/tool_gate>) with this
policy; a call it asks about goes to the same person
(L<Langertha::Raider::Application/on_permission_request>) or, with nobody to
ask, is refused as in the caller. A L</detached> subagent -- one in the
background, or started by one -- never asks: such a call is refused with a
reason that says it runs in the background (ADR 0027 E<sect>3). Its
C<permission.*> events go to the subagent's journal. C<exit_plan_mode> gets
an instance of its own that never switches a mode: a subagent in plan mode
gives its plan as its answer, to the caller.

=item * B<Engine.> One engine of the caller's class and arguments, built by
L<Langertha::Raider::Application/build_subagent_engine> over this set's
clients, on the same loop. Its model is the call's C<model> (L</model>),
else the agent's C<model>, as
L<Langertha::Raider::Context::Agents/resolve_model> maps it under the
caller's engine and L<Langertha::Raider::Application/agent_models>
(L</model_resolution>, ADR 0020 E<sect>5): a resolved model replaces the
caller's, otherwise it is inherited. C<agent.started> carries the model the
engine really uses.

=item * B<Journal.> When the caller has a session, the subagent gets its own
session in the same store, whose C<session.created> carries C<parent>,
C<parent_call>, C<agent>, C<depth>, C<agent_id> and the C<name> given at
spawn, and runs one journaled run there per run of the agent --
C<run.started>, the briefed prompt (or the message it was continued with)
and the answer as C<message>, every C<tool.call>, C<tool.result> and
C<todo.updated>, a delivered notification as a user C<message> with
C<notification> 1, and C<run.finished>. The caller gets only
C<agent.started> (C<call>, C<agent>, C<agent_id>, C<background>,
C<description>, C<session>, C<model>; C<resumed> for a continued run) and
C<agent.finished> (C<call>, C<agent>, C<agent_id>, C<session>, C<status>),
through its event stream -- for a subagent of the main run that ended
between two runs, straight into the session it was started from
(L<Langertha::Raider::Application/caller_event>).

=item * B<Hooks> (Claude layout, ADR 0022, ADR 0020 E<sect>6). Before
the first run C<SubagentStart> fires (matcher on C<agent_type>) with
C<agent_id> -- the subagent's session id, or C<local-agent-PID-ADDR> without
a session -- and C<agent_type>, the agent's name; its
C<additionalContext> goes in front of the briefed prompt as a
C<< <system-reminder> >> block (L</sent_prompt>), and a C<continue: false>
fails the run before its first request. After a final answer
C<SubagentStop> fires as C<Stop> does for the main run
(L<Langertha::Raider::Application/stop_hook_limit>): a block or
C<additionalContext> sends C<SubagentStop hook feedback:> and the reasons
back to the subagent as its next message, with C<stop_hook_active> true,
and the run goes on. The reports of both go to the caller's stream
(C<hook.ran>, C<hook.message>). The subagent's own tool calls run the
C<PreToolUse> and C<PostToolUse> hooks as the caller's do, with
C<agent_id>, C<agent_type> and its own C<permission_mode> in the input;
those reports go to its journal, and a C<continue: false> there cancels the
subagent only. Its own task list fires C<TaskCreated> and C<TaskCompleted>
the same way, before the change, with the same fields; a block refuses the
change with the hook's reason as the tool's error result. A continued run
fires no C<SubagentStart>.

=item * B<Worktree isolation> (ADR 0032 E<sect>2, ADR 0027 E<sect>7). The
call's C<isolation: "worktree"> or the agent file's C<isolation: worktree>
(L</isolated>) runs the subagent in a git worktree of its own
(L<Langertha::Raider::Worktree>): C<TOP/.claude/worktrees/agent-N> in the
Claude layout, C<TOP/.raider/worktrees/agent-N> otherwise
(L<Langertha::Raider::Application/worktrees_dir>), TOP the main checkout
of the caller's root, on branch C<worktree-agent-N>, from the base of
L<Langertha::Raider::Application/worktree_base_ref>, with the
F<.worktreeinclude> copy. An agent ID whose directory or branch is left
from earlier is skipped. A caller root in a subdirectory works in the same
subdirectory of the worktree (L</working_root>). Not in a git repository:
C<isolation "worktree" needs a git repository; ROOT is not inside one.>,
and nothing starts; an agent file's other C<isolation> value refuses the
spawn too (L</isolation_refusal>). The file, search and shell tools work in
the working root (the same classes and settings, the root replaced), and
so do the Perl tools when the caller has them; every hook input of the
subagent has the working root as C<cwd>; the
policy is the caller's moved there (L</permissions>), which refuses edits
into the main checkout; the mission is compiled for the caller's context
with the working root as its working directory. The worktree is locked
(C<raider agent agent_N>) while a run runs. After every run, however it
ended, it is unlocked; with no changes (a clean status, untracked files
counting, and no commit beyond the base) worktree and branch are removed,
else both stay and are named in the result (L</result_text>), the
notification, the registry entry (C<worktree>, C<branch>) and
C<agent.finished> (C<worktree_kept>; C<agent.started> has C<worktree> and
C<branch>). A cancelled run nobody hears of -- a new conversation, leaving
raider, a cancelled turn -- names it in a meta line instead
(L<Langertha::Raider::Application/note_meta>: C<agent agent_1 left its
worktree P on branch B>). A git command that fails keeps the worktree
(C<worktree kept: REASON>), never failing the answer. A continued run
uses the worktree again, checks its branch out into the same path when the
worktree is gone, or makes it anew when both are.

=item * B<Messages and children.> What waits for the subagent in the
registry's queue -- the notifications of its own background subagents, the
messages C<send_message> hands it -- goes into its raid before its next
model request (L<Langertha::Raider/on_iteration>). A run that would end
with a final answer while background subagents it started still run waits
for them on the loop and goes on with their notifications as its next
message (ADR 0027 E<sect>3); it ends when it answers with nothing left.

=item * B<On the loop> (ADR 0027 E<sect>9). C<agent> and C<send_message>
are asynchronous tools of the caller's raider
(L<Langertha::Raider/async_tools>): no tool code waits for a subagent, a
foreground run is a Future the caller's raid awaits, and the C<agent> calls
of one model turn run at the same time, each with its own agent ID and
result. At most L<Langertha::Raider::Application/max_concurrent_agents>
subagent runs of the application run at once -- all depths, foreground and
background, resumed ones too; beyond that a spawn or a resume is refused
with C<Concurrent subagent limit reached (N running). Do not retry this
call now; wait for running agents to finish.>, and nothing starts. The
agent call id a subagent knows (its C<caller_call>, the C<tool-use-id> of
its notification) comes from the call's context, not from the last call
of the caller's run.

=item * B<End.> A completed run answers with the subagent's text; a failed
one with an error result giving the reason; a cancelled one -- the
application cancels every live foreground subagent with its run
(L<Langertha::Raider::Application/cancel_run>), and L</cancel> reaches the
subagent's own children -- with an error result. A caller's cancel that
cuts the C<agent> call off cancels the subagent too; its run ends on the
loop, held by the registry. Failed and cancelled
results name the agent ID. A run that ends that way first stops the
subagents it started and waits for them. The subagent gets the caller's
C<max_iterations>.

=back

=head2 app

The L<Langertha::Raider::Application> of the main run, which builds the
engine and the mission and owns the loop, the session store and the
registry. Required, held weakly.

=head2 agent

The catalogue entry of the agent (L<Langertha::Raider::Context::Agents>).
Required.

=head2 depth

The depth of this run: C<1> for a subagent of the main run. Required.

=head2 prompt

The task, the subagent's first user message. Required.

=head2 description

The short label of the call, for C<agent.started> and the notification.

=head2 name

The C<name> the call gave the agent, by which C<send_message> can address
it, if any.

=head2 model

The C<model> of the call (C<sonnet>, C<opus>, C<haiku>), which replaces
the agent's own, if any.

=head2 background

True when the run goes on in the background (C<run_in_background>, and
every continued run).

=head2 isolation

The C<isolation> of the call (C<worktree>), if any. The agent file's
C<isolation> holds as well (L</isolated>).

=head2 caller_root

The caller's working root: where its file, search and shell tools work.
Defaults to the application's L<Langertha::Raider::Application/working_root>
-- a worktree while the main run works in one (ADR 0032 E<sect>3); a
subagent of an isolated one gets that one's worktree (L</working_root>).

=head2 worktree

The worktree of an L</isolated> subagent once it is planned (ADR 0032
E<sect>2): C<top> (the main checkout), C<source> (the working tree of the
caller's root, where F<.worktreeinclude> is read), C<path>, C<branch>,
C<root> (L</working_root>) and, once this process made it, C<base> (the
commit it branched from). Undef otherwise.

=head2 isolated

True when the subagent runs in a worktree of its own: the call's
L</isolation> or the agent file's C<isolation> is C<worktree> (ADR 0032
E<sect>2; the call cannot turn the file's off).

=head2 isolation_refusal

    my $text = $sub->isolation_refusal;   # or nothing

The error result when the agent file's C<isolation> is not C<worktree>:
C<Agent 'NAME': isolation "V" is not supported; use "worktree".>

=head2 working_root

Where the subagent's file, search and shell tools work and what its
mission calls the working directory: the worktree's C<root> (the same
subdirectory of the worktree as the caller's root is of its working tree)
for an L</isolated> subagent, else L</caller_root>.

=head2 worktree_name

    my $name = $sub->worktree_name('agent_3');   # agent-3

The directory name of an agent's worktree under
L<Langertha::Raider::Application/worktrees_dir>; its branch is
C<worktree-NAME>.

=head2 worktree_class

The class doing the git work: L<Langertha::Raider::Worktree>.

=head2 task_id

The agent ID (C<agent_1>), once the run is registered: what the model sees
and addresses (ADR 0027 E<sect>1). Not the same as L</agent_id>, the id the
hooks get.

=head2 caller_servers

The caller's active tool set, as L<MCP::Server> objects. Required.

=head2 caller_session

The caller's L<Langertha::Raider::Session>, if it has one.

=head2 caller_call

The id of the caller's C<agent> tool call (C<c3>), as its journal names it
-- for a continued run, the id of the C<send_message> call.

=head2 on_caller_event

The caller's event stream, called as C<< ->($type, %payload) >> with
C<agent.started> and C<agent.finished>. Required.

=head2 caller_task_id

The agent ID of the calling subagent; undef for a subagent of the main
run. See L</recipient>.

=head2 caller_detached

True when the caller runs detached (L</detached>).

=head2 caller_policy

The caller's L<Langertha::Raider::Permissions>: the application's
L<Langertha::Raider::Application/permissions> for a subagent of the main
run, the calling subagent's L</permissions> for a nested one. Defaults to
the application's.

=head2 permissions

The subagent's policy: L<Langertha::Raider::Permissions/for_subrun> of
L</caller_policy>, built once -- for an L</isolated> one with the
L</working_root> as root and the worktree as
L<Langertha::Raider::Permissions/worktree_isolation>, so project rules mean
the same files in the copy and edits into the main checkout are refused.

=head2 briefing

The L<Langertha::Raider::Briefing> of the agent's declared skills, built
once (L</briefing_class>).

=head2 briefed_prompt

What the subagent is asked: L</prompt> behind its briefing, or L</prompt>
itself when the agent declares no skill.

=head2 sent_prompt

What the subagent was really sent once the run has started: the
C<additionalContext> of C<SubagentStart> hooks in front of
L</briefed_prompt>, or L</briefed_prompt> itself.

=head2 agent_id

The C<agent_id> of the hook inputs (ADR 0020 E<sect>7): the subagent's
session id, else C<local-agent-PID-ADDR>, unique while the subagent runs.
The model addresses the agent by L</task_id>.

=head2 model_resolution

What the call's L</model>, else the agent's C<model>, means under the
caller's engine (L<Langertha::Raider::Context::Agents/resolve_model>):
C<< { model => ... } >> or C<< { inherit => 1, reason => ... } >>.

=head2 tool_servers

The subagent's active tool set (see L</DESCRIPTION>), built once.

=head2 mission

The subagent's system prompt, built once.

=head2 engine

The subagent's engine, built once.

=head2 raider

The subagent's L<Langertha::Raider>, built once; it keeps the history
from one run of the agent to the next.

=head2 session

The subagent's own L<Langertha::Raider::Session> once the run has started,
when the caller has one.

=head2 cancel_requested

True once L</cancel> was called, until the agent is continued.

=head2 todos

The subagent's own task list, as its task tools (or C<todo_write>) last
left it.

=head2 file_read_state

The subagent's own record of the files it has read
(L<Langertha::Raider::FileTools::ReadState>, ADR 0023): its C<write_file>,
C<edit_file> and C<multi_edit> hold against it, so a file the caller read
counts as unread until the subagent reads it itself.

=head2 last_outcome

The outcome of the last run that ended (see L</run_f>).

=head2 recipient

Who gets the notifications of this subagent: L</caller_task_id>, or
C<main> for a subagent of the main run.

=head2 detached

True when nobody waits for the subagent at the keyboard: it runs in the
L</background>, or its caller does (L</caller_detached>).

=head2 one_shot

True for an agent that cannot be continued (the built-ins C<Explore> and
C<Plan>, ADR 0027 E<sect>6).

=head2 agent_tools

    my $agent_tools = Langertha::Raider::Subagent->agent_tools(
      app => $app, depth => $depth,
      caller => sub { my ( %ctx ) = @_; { servers, session, call, event, policy, task_id, detached, root } });

The L<Langertha::Raider::AgentTools> with the tools C<agent> and
C<send_message> for a run at C<$depth>, over the agent catalogue of the
application's context: its C<server> for the tool set, its C<async_tools>
for the raider of that run. Every call asks C<caller> -- with the call's
context (L<Langertha::Raider/async_tools>) -- for the state of the calling
run at that moment: its active tool set, session, the id of the call (the
context's C<call>), its event stream, its permission policy, its agent ID
(undef for the main run), whether it runs detached and its working root
(L</caller_root>; the application's root when not given). An C<agent> call
runs a new subagent of the invocant class at C<$depth + 1> (L</spawn_f>), a
C<send_message> call goes to L</send_message>.

=head2 agent_tool_server

    my $server = Langertha::Raider::Subagent->agent_tool_server(%args);

The C<server> of L</agent_tools>.

=head2 spawn_f

    my ( $text, $is_error ) = await Langertha::Raider::Subagent->spawn_f(
      app => $app, depth => 0, caller => \%caller, agent => $agent,
      call => { description, prompt, model, name, run_in_background },
    );

One C<agent> call: a new subagent at C<$depth + 1>; an agent file's
C<isolation> other than C<worktree> refuses it (L</isolation_refusal>), so
do a briefing that does not resolve and the concurrency limit
(L</limit_refusal>); else it runs in the foreground (L</foreground_f>) or
starts in the background (L</start_background>), which make the worktree
of an L</isolated> one first. A Future of the tool result.

=head2 limit_refusal

    my $text = Langertha::Raider::Subagent->limit_refusal($app);

The error text when L<Langertha::Raider::Application/max_concurrent_agents>
subagent runs of the application already run (ADR 0027 E<sect>9) -- every
C<agent> entry of the registry that is C<running>, at any depth, in the
foreground or the background -- else nothing.

=head2 foreground_f

    my ( $text, $is_error ) = await $sub->foreground_f;

Makes the worktree of an L</isolated> subagent (an error result when that
fails, nothing started), registers the subagent and runs it in the
foreground (L</run_f>) on the
application's loop; a Future of the tool result (L</result_text>), which
the caller's raider awaits. While it runs, the application knows it as
live, so cancelling the main run cancels it -- unless it is L</detached>;
then only its caller's L</cancel> reaches it. Cancelling the returned
Future -- a cancel cut the C<agent> call off -- cancels the subagent; its
run still ends in order on the loop (the registry holds it).

=head2 run

    my ( $text, $is_error ) = $sub->run;

L</foreground_f>, waited for on the application's loop: the synchronous
wrapper for a library caller outside the loop. Never call it from code that
runs on the loop -- a tool, a hook --: that is what L</foreground_f> is for.

=head2 start_background

    my ( $text, $is_error ) = $sub->start_background;

Makes the worktree of an L</isolated> subagent as L</foreground_f> does,
registers the subagent, starts its run (L</run_f>) on the application's
loop with the next turn of the loop, and returns at once with
L</launch_text>. The registry holds the run; its end becomes a
notification for L</recipient> (L</notification>).

=head2 send_message

    my ( $text, $is_error ) = Langertha::Raider::Subagent->send_message(
      app => $app, depth => 0, caller => \%caller, to => 'agent_1', message => '...');

The C<send_message> tool (ADR 0027 E<sect>5). C<to> is an agent ID or a
name given at spawn (L<Langertha::Raider::Tasks/find>); an ID the registry
does not know is looked up among the child sessions of the caller's session
(L</restore>). A running agent gets the message before its next model
request (C<Message queued for delivery to agent_1 at its next tool
round.>); a finished one is continued in the background (L</resume>),
unless the concurrency limit refuses it (L</limit_refusal>). Error
results: C<No agent found with ID or name: X>, C<Agent agent_1 (Explore) is
one-shot and cannot be continued.>, and for a background shell
C<bash_1 is a background shell, not an agent; read it with bash_output.>

=head2 restore

    my ( $sub, $error ) = Langertha::Raider::Subagent->restore(
      app => $app, depth => 0, caller => \%caller, to => 'agent_1');

An agent of an earlier process: the newest child session of the caller's
session whose C<session.created> has C<agent_id> (or C<name>) C<to>. Its
agent is looked up by name in the current catalogue; its history is
replayed into a new subagent (ADR 0015), which takes the session over and
is registered under the agent ID, finished. An agent that ran in a
worktree (its C<agent.started> names one) or whose file says
C<isolation: worktree> is L</isolated> again, with the worktree path and
branch its agent ID gives. Returns the subagent, an error
text (the agent is not defined any more, is one-shot, its session cannot
be opened, or its root is no git repository any more), or nothing when
there is no such session.

=head2 resume

    my ( $text, $is_error ) = $sub->resume( $message, \%caller );

Continues a finished subagent (ADR 0027 E<sect>5): its caller becomes the
given one, and a new run (L</resume_f>) of it starts in the background with
the next turn of the loop, with its history and C<$message> as the next
user message, in a new run of its child session. Returns
C<Resuming agent agent_1 in the background. You will be notified when it
finishes.>

=head2 run_f

    my $outcome = await $sub->run_f;

The first run: starts the journal and C<agent.started>, raids with the
briefed prompt (and goes on as long as notifications and messages come,
see L</DESCRIPTION>), ends the journal, the registry entry, C<agent.finished>
and -- in the background -- the notification. Never fails; returns the
outcome as a hash reference: C<status> (C<completed>, C<failed>,
C<cancelled>, or C<refused> when a declared skill does not resolve -- then
nothing ran), C<text> of a completed run, C<error> of a failed or refused
one, and C<usage> (L</usage_pairs>) of one that ran.

=head2 resume_f

    my $outcome = await $sub->resume_f($message);

A further run of a finished subagent with C<$message> as the next user
message; otherwise as L</run_f>.

=head2 approval_binding

    my %binding = $sub->approval_binding;   # session_id, run_id

What an approval of one of the subagent's calls is bound to: its own
session and run, when it has a session; else nothing, and the
application's stand-ins apply.

=head2 cancel

Asks the run to stop (L<Langertha::Raider/cancel>), and every subagent it
started that still runs (L<Langertha::Raider::Tasks/stop>); only sets flags,
so a signal handler may call it.

=head2 event

    $sub->event('tool.call', call => 'c1', name => 'read_file', ...);

One event of the subagent's own run: into its journal for the types the
application journals (L<Langertha::Raider::Application/is_journal_type>),
nowhere else. A C<tool.call> counts as one of its L</usage_pairs>
C<tool_uses>; a C<model.usage> of its own model calls (C<purpose> C<chat>)
sets its C<subagent_tokens>.

=head2 usage_pairs

    my $pairs = $sub->usage_pairs;   # [ subagent_tokens => 1200, tool_uses => 4, duration_ms => 5300 ]

The usage of the current (or last) run, in the order the result and the
notification show it (ADR 0027 E<sect>2): C<subagent_tokens> -- input plus
output tokens of the subagent's last model call that reported usage, from
its C<model.usage> event (the one the application's token ledger counts,
ADR 0026), C<0> before any --, C<tool_uses> -- the tool calls of this run --,
C<duration_ms> -- its wall clock.

=head2 agent_id_line

    agentId: agent_1 (use send_message with to: 'agent_1' to continue this agent)

The line that names the agent ID in a result; for a L</one_shot> agent
only C<agentId: agent_1>.

=head2 result_text

    my ( $text, $is_error ) = $sub->result_text($outcome);

The tool result of a foreground run (ADR 0027 E<sect>2). Completed: the
report, then L</agent_id_line> (not for a L</one_shot> agent) and

    <usage>subagent_tokens: N
    tool_uses: N
    duration_ms: N</usage>

Refused: the refusal. Cancelled: C<Agent 'NAME' (agent_1) was cancelled.>,
failed: C<Agent 'NAME' (agent_1) failed: REASON> -- both errors, the agent ID
left out for a one-shot agent.

A kept worktree (ADR 0032 E<sect>2) adds, after the usage (or the error),

    worktreePath: /repo/.claude/worktrees/agent-1
    worktreeBranch: worktree-agent-1

and C<worktree kept: REASON> when a git command failed.

=head2 launch_text

The answer of a background start (ADR 0027 E<sect>3):

    Async agent launched successfully.
    agentId: agent_1 (use send_message with to: 'agent_1' to continue this agent)
    The agent is working in the background. You will be notified automatically when it completes. ...
    Do not duplicate this agent's work -- ...

=head2 notification

    my ( $text, $label ) = $sub->notification($outcome);

The C<< <task-notification> >> of a run that ended (ADR 0027 E<sect>4,
L<Langertha::Raider::Tasks/notification_text>) and the line a surface shows
for it (C<background agent agent_1 finished>). C<completed>: summary
C<Agent "DESCRIPTION" finished> and the report as C<result>; C<failed>:
summary C<Agent "DESCRIPTION" failed: REASON>; C<killed> (a cancelled run):
summary C<Agent "DESCRIPTION" was stopped>. Each with the usage, and a
kept worktree as the C<< <worktree> >> element (C<worktreePath>,
C<worktreeBranch>; ADR 0032 E<sect>2) -- a git command that failed adds
C<worktree kept: REASON> to the report of a completed run. Without a
description the agent's name stands in.

=head2 perl_server_name

The name of the Perl tools' server (L<Langertha::Raider::PerlTools>):
C<raider-perl>. When the caller has it, the subagent's Perl tools are its
own, working in its L</working_root>.

=head2 briefing_class

The class of L</briefing>: L<Langertha::Raider::Briefing>.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::AgentTools>

=item * L<Langertha::Raider::Tasks>

=item * L<Langertha::Raider::Application>

=item * L<Langertha::Raider::Context::Agents>

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

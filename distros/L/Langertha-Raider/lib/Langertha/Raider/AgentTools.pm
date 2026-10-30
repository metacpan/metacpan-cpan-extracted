package Langertha::Raider::AgentTools;
# ABSTRACT: Internal subagent tools of raider: agent and send_message
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;
use Future;
use JSON::MaybeXS ();
use MCP::Server;
use Scalar::Util qw( blessed );


has catalog => (
  is       => 'ro',
  isa      => 'Langertha::Raider::Context::Agents',
  required => 1,
);


has on_spawn => (
  is       => 'ro',
  isa      => 'CodeRef',
  required => 1,
);


has on_send => (
  is        => 'ro',
  isa       => 'CodeRef',
  predicate => 'has_on_send',
);


has server => (
  is       => 'ro',
  lazy     => 1,
  builder  => '_build_server',
  init_arg => undef,
);



sub async_tools {
  my ( $self ) = @_;
  return {
    agent => { code => sub { $self->call_f( agent => @_ ) }, concurrent => 1 },
    ( $self->has_on_send ? ( send_message => { code => sub { $self->call_f( send_message => @_ ) } } ) : () ),
  };
}

sub call_f {
  my ( $self, $name, $input, %ctx ) = @_;
  $input = {} unless ref $input eq 'HASH';
  my $f = $name eq 'agent' ? $self->_agent_f( $input, %ctx )
    : $name eq 'send_message' && $self->has_on_send ? $self->_send_f( $input, %ctx )
    : Future->done( 'unknown tool '.( $name // '' ), 1 );
  return $f->then(
    sub { my ( $text, $is_error ) = @_; Future->done( $self->_result( $text, $is_error ) ) },
    sub { my ( $error ) = @_; Future->done( $self->_result( 'Error: '.$error, 1 ) ) },
  );
}

# An MCP tool result, as MCP::Tool->text_result gives it.
sub _result {
  my ( $self, $text, $is_error ) = @_;
  return {
    content => [ { type => 'text', text => ''.( $text // '' ) } ],
    isError => $is_error ? JSON::MaybeXS->true : JSON::MaybeXS->false,
  };
}

# What on_spawn or on_send returned -- ( $text, $is_error ) or a Future of
# it -- as a Future.
sub _future_of {
  my ( $self, @r ) = @_;
  return $r[0] if @r == 1 && blessed $r[0] && $r[0]->isa('Future');
  return Future->done(@r);
}

# The agent call: checked, then on_spawn. A Future of ( $text, $is_error ).
sub _agent_f {
  my ( $self, $in, %ctx ) = @_;
  my $type = defined $in->{subagent_type} && length $in->{subagent_type}
    ? $in->{subagent_type} : $self->catalog->builtin_name;
  my $agent = $self->catalog->find($type)
    or return Future->done( $self->unknown($type), 1 );
  return Future->done( 'Error: the prompt is empty: write the task for the agent.', 1 )
    unless defined $in->{prompt} && $in->{prompt} =~ /\S/;
  my $model = $in->{model};
  return Future->done( 'Error: model must be one of '.join( ', ', $self->model_aliases ).'.', 1 )
    if defined $model && !grep { $_ eq $model } $self->model_aliases;
  my $isolation = $in->{isolation};
  return Future->done( $self->isolation_refusal($isolation), 1 )
    if defined $isolation && !grep { !ref $isolation && $_ eq $isolation } $self->isolation_modes;
  my $name = defined $in->{name} && $in->{name} =~ /\S/ ? $in->{name} : undef;
  return Future->call( sub { $self->_future_of( $self->on_spawn->( $agent, {
    description       => $in->{description} // '',
    prompt            => $in->{prompt},
    subagent_type     => $type,
    run_in_background => $in->{run_in_background} ? 1 : 0,
    ( defined $model     ? ( model     => $model )     : () ),
    ( defined $name      ? ( name      => $name )      : () ),
    ( defined $isolation ? ( isolation => $isolation ) : () ),
  }, %ctx ) ) } );
}

# The send_message call: checked, then on_send. A Future of ( $text, $is_error ).
sub _send_f {
  my ( $self, $in, %ctx ) = @_;
  return Future->done( 'Error: to is empty: give an agent ID or name.', 1 )
    unless defined $in->{to} && $in->{to} =~ /\S/;
  return Future->done( 'Error: the message is empty.', 1 )
    unless defined $in->{message} && $in->{message} =~ /\S/;
  return Future->call( sub { $self->_future_of( $self->on_send->( {
    to      => $in->{to},
    message => $in->{message},
    ( defined $in->{summary} ? ( summary => $in->{summary} ) : () ),
  }, %ctx ) ) } );
}


sub model_aliases { qw( sonnet opus haiku ) }


sub isolation_modes { qw( worktree ) }

sub isolation_refusal {
  my ( $self, $value ) = @_;
  return 'Error: isolation "'.( ref $value ? JSON::MaybeXS->new( canonical => 1, allow_nonref => 1 )->encode($value) : $value )
    .'" is not supported; use "worktree".';
}


sub tools_label {
  my ( $self, $agent ) = @_;
  my %no = map { $_ => 1 } @{ $agent->{disallowed} // [] };
  unless ( defined $agent->{tools} ) {
    return '*' unless %no;
    return 'All tools except '.join( ', ', @{ $agent->{disallowed} } );
  }
  my @tools = grep { !$no{$_} } @{ $agent->{tools} };
  return @tools ? join( ', ', @tools ) : 'none';
}


sub description {
  my ( $self ) = @_;
  my $agents = join "\n", map {
    '- '.$_->{name}.': '.$_->{description}.' (Tools: '.$self->tools_label($_).')'
  } $self->catalog->agents;
  my $builtin = $self->catalog->builtin_name;
  return <<"EOM" =~ s/\n+\z//r;
Launch a new agent to handle complex, multi-step tasks autonomously.

The agent tool launches specialized agents that work on their own, each in a context of its own. Each agent type has its own instructions and the tools listed with it.

Available agent types and the tools they have access to:
$agents

Set subagent_type to pick the agent type; without it, $builtin runs.

When NOT to use the agent tool:
- To read a specific file path, use read_file or glob instead, to find the match more quickly.
- To find a specific definition such as "sub foo" or "class Foo", use grep or glob instead.
- To search code within a specific file or a set of 2-3 files, use read_file instead.
- For tasks that are not related to the agent descriptions above.

Usage notes:
- Always include a short description (3-5 words) summarizing what the agent will do.
- The agent starts with no memory of this conversation: write a self-contained prompt with the task, the context it needs, and what it should report back. Tell it clearly whether you expect it to write code or only to do research (search, file reads, web fetches), since it does not know the user's intent.
- When the agent is done, its final message is returned to you as the result of this tool, with its agent ID and usage. The result is not visible to the user: to show the user the result, send a text message back with a concise summary of it.
- Launch multiple agents concurrently whenever possible, to maximize performance; to do that, use a single message with multiple agent calls. If the user asks for agents "in parallel", you MUST send a single message with multiple agent calls.
- You can run an agent in the background with run_in_background. You are then notified automatically when it completes, by a <task-notification> message -- do NOT sleep, poll or proactively check on its progress; continue with other work or respond to the user in the meantime.
- Foreground or background: use the foreground (the default) when you need the agent's results before you can go on, such as research whose findings inform your next steps. Use the background when you have genuinely independent work to do in the meantime.
- To continue an agent you started, use send_message with its agent ID (or the name you gave it with name) as to. It resumes with its full context preserved. Each agent call starts a fresh agent, so give it a complete task description.
- model (sonnet, opus or haiku) runs the agent on that model instead of its own; only on the Anthropic API, elsewhere it runs on yours.
- You can optionally set isolation: "worktree" to run the agent in a temporary git worktree, giving it an isolated copy of the repository. The worktree is automatically cleaned up if the agent makes no changes; if changes are made, the worktree path and branch are returned in the result.
- The agent's outputs should generally be trusted.
- If an agent's description says it should be used proactively, try your best to use it without the user having to ask for it first. Use your judgement.
EOM
}


sub send_description {
  my ( $self ) = @_;
  return <<'EOM' =~ s/\n+\z//r;
Send a message to an agent you started with the agent tool, to continue it.

- to: the agent ID (agent_1, from the agent result or its <task-notification>), or the name you gave the agent with name -- the newest agent of that name.
- A running agent gets the message at its next tool round.
- A finished agent is resumed in the background, with its full context and your message as its next instruction; you are notified by a <task-notification> when it finishes, as for any background agent.
- summary: a 5-10 word recap of the message, for the record; the agent does not get it.
- One-shot agents (Explore, Plan) cannot be continued.
EOM
}


sub unknown {
  my ( $self, $type ) = @_;
  return 'Unknown agent type \''.$type.'\'. Available agents: '
    .join( ', ', map { $_->{name} } $self->catalog->agents ).'.';
}

sub _build_server {
  my ( $self ) = @_;
  my $server = MCP::Server->new( name => 'raider-agent', version => '1.0' );
  $server->tool(
    name         => 'agent',
    description  => $self->description,
    input_schema => {
      type       => 'object',
      properties => {
        description       => { type => 'string', description => 'A short (3-5 word) description of the task' },
        prompt            => { type => 'string', description => 'The task for the agent to perform' },
        subagent_type     => { type => 'string', description => 'The type of agent to use (default: '.$self->catalog->builtin_name.')' },
        model             => { type => 'string', enum => [ $self->model_aliases ],
          description => 'Optional model for this agent instead of its own (Anthropic API only)' },
        run_in_background => { type => 'boolean',
          description => 'Run the agent in the background; you are notified when it completes' },
        name              => { type => 'string',
          description => 'Optional name for the agent, so send_message can address it by name' },
        isolation         => { type => 'string', enum => [ $self->isolation_modes ],
          description => 'Isolation mode. "worktree" creates a temporary git worktree so the agent works on an isolated'
            .' copy of the repository' },
      },
      required => [qw( description prompt )],
    },
    # The synchronous fallback (see DESCRIPTION): waits for the call.
    code => sub {
      my ( $tool, $in ) = @_;
      my ( $text, $is_error ) = $self->_agent_f( ref $in eq 'HASH' ? $in : {} )->get;
      return $tool->text_result( $text // '', $is_error ? 1 : 0 );
    },
  );
  return $server unless $self->has_on_send;
  $server->tool(
    name         => 'send_message',
    description  => $self->send_description,
    input_schema => {
      type       => 'object',
      properties => {
        to      => { type => 'string', description => 'The agent ID (agent_1) or the name given at spawn' },
        message => { type => 'string', description => 'The message for the agent' },
        summary => { type => 'string', description => 'A 5-10 word recap of the message' },
      },
      required => [qw( to message )],
    },
    code => sub {
      my ( $tool, $in ) = @_;
      my ( $text, $is_error ) = $self->_send_f( ref $in eq 'HASH' ? $in : {} )->get;
      return $tool->text_result( $text // '', $is_error ? 1 : 0 );
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

Langertha::Raider::AgentTools - Internal subagent tools of raider: agent and send_message

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    my $agents = Langertha::Raider::AgentTools->new(
      catalog  => $context->agent_catalog,
      on_spawn => sub { my ( $agent, $call ) = @_; ...; return ( $text, $is_error ) },
      on_send  => sub { my ( $message ) = @_; ...; return ( $text, $is_error ) },   # optional
    );
    my $server = $agents->server;      # MCP::Server with agent (and send_message)
    my $tools  = $agents->async_tools; # for Langertha::Raider/async_tools

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

The C<agent> tool of ADR 0020 E<sect>3 and ADR 0027 E<sect>10, shaped after
Claude Code's C<Agent> (formerly C<Task>, both mapped by
L<Langertha::Raider::ToolNames>): the model hands a task to a subagent,
which works in a context of its own -- in the foreground, answering with its
last text, or in the background (C<run_in_background>), announcing its end
with a C<< <task-notification> >> later. Beside it, when L</on_send> is
given, the C<send_message> tool of ADR 0027 E<sect>5 (Claude Code's
C<SendMessage>) continues an agent by its ID or name.

The tools know the agents (L</catalog>), check the call and describe every
agent in the text; they start nothing themselves. L</on_spawn> runs the
subagent (L<Langertha::Raider::Subagent>), L</on_send> delivers a message.
An unknown C<subagent_type>, an empty prompt, a C<model> that is not
C<sonnet>, C<opus> or C<haiku> and an C<isolation> that is not C<worktree>
(L</isolation_refusal>, ADR 0032) are error results, and no subagent
starts.

A raider runs both as asynchronous tools (L</async_tools>, ADR 0027
E<sect>9): the server carries their name, text and schema, the call itself
goes to L</call_f>, whose Future the raider awaits, so a foreground agent
runs on the loop without blocking it and several C<agent> calls of one turn
run at the same time. The C<code> of the server's tools is the synchronous
fallback for a raider without them: it waits for the Future on the loop
(C<< ->get >>), so it must never run inside the loop.

=head2 catalog

The L<Langertha::Raider::Context::Agents> the agents come from. Required.

=head2 on_spawn

Required. Called for every valid C<agent> call as
C<< $on_spawn->($agent, { description => ..., prompt => ..., subagent_type => ...,
model => ..., run_in_background => 0|1, name => ..., isolation => 'worktree' }, %ctx) >>
(C<model>, C<name> and C<isolation> only when given), with C<$agent> the catalogue entry and C<%ctx>
the call's context (L<Langertha::Raider/async_tools>; empty on the
synchronous fallback); returns the tool result as C<( $text, $is_error )>,
or a Future of it.

=head2 on_send

Called for every C<send_message> call as
C<< $on_send->({ to => ..., message => ..., summary => ... }, %ctx) >>; returns the
tool result as C<( $text, $is_error )>, or a Future of it. Without it the
server has no C<send_message>.

=head2 server

The L<MCP::Server> with the tool C<agent> and, with L</on_send>, the tool
C<send_message>, built once.

=head2 async_tools

    my $tools = $agents->async_tools;
    # { agent => { code => ..., concurrent => 1 }, send_message => { code => ... } }

The tools as L<Langertha::Raider/async_tools>: C<agent> concurrent --
several calls of one turn run at the same time --, C<send_message> (with
L</on_send>) not. Each handler is L</call_f> for its tool.

=head2 call_f

    my $f = $agents->call_f( agent => $input, %ctx );   # Future of { content => [...], isError => ... }

One call of the tool C<agent> or C<send_message> with the model's
arguments C<$input>: checked as the server's tool checks them, then handed
to L</on_spawn> or L</on_send> with C<%ctx>. Resolves to the MCP result;
an error of the call is an error result, never a failed Future.

=head2 model_aliases

The values the C<model> parameter takes: C<sonnet>, C<opus>, C<haiku>.

=head2 isolation_modes

The values the C<isolation> parameter takes: C<worktree> (ADR 0032).

=head2 isolation_refusal

    my $text = $agents->isolation_refusal('sandbox');
    # Error: isolation "sandbox" is not supported; use "worktree".

The error result of a call whose C<isolation> is not one of
L</isolation_modes>.

=head2 tools_label

    my $label = $agents->tools_label($agent);   # '*', 'read_file, grep', 'All tools except bash'

What the tool text says an agent may use, in raider names: C<*> for every
tool of the caller, else the list of C<tools> without C<disallowedTools>,
or C<All tools except ...> when only C<disallowedTools> restricts it.

=head2 description

The text of the C<agent> tool, after Claude Code's current C<Agent> text
in raider's names: what it does, one line per agent
(C<- name: description (Tools: ...)>), when not to use it, and how --
background runs and their notifications, C<send_message> to continue an
agent, several calls in one message, C<isolation> in a worktree.

=head2 send_description

The text of the C<send_message> tool.

=head2 unknown

    my $text = $agents->unknown('nope');

The error text for an unknown C<subagent_type>, naming the available
agents.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::Subagent>

=item * L<Langertha::Raider::Tasks>

=item * L<Langertha::Raider::Context::Agents>

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

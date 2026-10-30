package Langertha::Raider::ToolNames;
# ABSTRACT: Internal table of Claude Code tool names and the raider tools they stand for
our $VERSION = '0.504';
use strict;
use warnings;
use Carp qw( croak );
use JSON::MaybeXS ();


my %RAIDER = (
  Read            => 'read_file',
  Write           => 'write_file',
  Edit            => 'edit_file',
  MultiEdit       => 'multi_edit',
  Bash            => 'bash',
  BashOutput      => 'bash_output',
  TaskOutput      => 'bash_output',
  TaskStop        => 'kill_shell',
  KillShell       => 'kill_shell',
  KillBash        => 'kill_shell',
  Glob            => 'glob',
  Grep            => 'grep',
  LS              => 'list_files',
  WebFetch        => 'web_fetch',
  WebSearch       => 'web_search',
  TodoWrite       => 'todo_write',
  TaskCreate      => 'task_create',
  TaskUpdate      => 'task_update',
  TaskList        => 'task_list',
  TaskGet         => 'task_get',
  Task            => 'agent',
  Agent           => 'agent',
  Skill           => 'skill',
  AskUserQuestion => 'ask_user',
  EnterPlanMode   => 'enter_plan_mode',
  ExitPlanMode    => 'exit_plan_mode',
  SendMessage     => 'send_message',
  ListMcpResourcesTool => 'list_mcp_resources',
  ReadMcpResourceTool  => 'read_mcp_resource',
  Monitor         => 'monitor',
  CronCreate      => 'cron_create',
  CronDelete      => 'cron_delete',
  CronList        => 'cron_list',
  EnterWorktree   => 'enter_worktree',
  ExitWorktree    => 'exit_worktree',
);

# The way back: the current Claude Code name of each raider tool.
my %CLAUDE = (
  read_file       => 'Read',
  write_file      => 'Write',
  edit_file       => 'Edit',
  multi_edit      => 'MultiEdit',
  bash            => 'Bash',
  bash_output     => 'TaskOutput',
  kill_shell      => 'TaskStop',
  glob            => 'Glob',
  grep            => 'Grep',
  list_files      => 'LS',
  web_fetch       => 'WebFetch',
  web_search      => 'WebSearch',
  todo_write      => 'TodoWrite',
  task_create     => 'TaskCreate',
  task_update     => 'TaskUpdate',
  task_list       => 'TaskList',
  task_get        => 'TaskGet',
  agent           => 'Agent',
  skill           => 'Skill',
  ask_user        => 'AskUserQuestion',
  enter_plan_mode => 'EnterPlanMode',
  exit_plan_mode  => 'ExitPlanMode',
  send_message    => 'SendMessage',
  list_mcp_resources => 'ListMcpResourcesTool',
  read_mcp_resource  => 'ReadMcpResourceTool',
  monitor         => 'Monitor',
  cron_create     => 'CronCreate',
  cron_delete     => 'CronDelete',
  cron_list       => 'CronList',
  enter_worktree  => 'EnterWorktree',
  exit_worktree   => 'ExitWorktree',
);

# The arguments that carry another name: raider name => Claude name.
my %ARG_NAME = (
  read_file  => { path => 'file_path' },
  write_file => { path => 'file_path' },
  edit_file  => { path => 'file_path' },
  multi_edit => { path => 'file_path' },
  kill_shell => { shell_id => 'task_id' },
  bash_output => { bash_id => 'task_id' },
);


sub claude_input {
  my ( $self, $tool, $args ) = @_;
  return $self->_translate_input( 'claude_input', $tool, $args, 0 );
}

sub raider_input {
  my ( $self, $tool, $args ) = @_;
  return $self->_translate_input( 'raider_input', $tool, $args, 1 );
}

sub _translate_input {
  my ( $self, $method, $tool, $args, $back ) = @_;
  croak __PACKAGE__.'->'.$method.' needs a tool name' unless defined $tool && length $tool;
  croak __PACKAGE__.'->'.$method.' needs the arguments as a hash ref' unless ref $args eq 'HASH';
  my %names = %{ $ARG_NAME{$tool} // {} };
  %names = reverse %names if $back;
  # bash_output in the form of TaskOutput (task_id) or of the older BashOutput (bash_id).
  my $task_output = $tool eq 'bash_output' && ( !$back || exists $args->{task_id} );
  my %out = map { $_ => $args->{$_} } grep { !exists $names{$_} } keys %$args;
  $out{ $names{$_} } = $args->{$_} for grep { exists $args->{$_} } sort keys %names;
  $out{timeout} = $self->_bash_timeout( $out{timeout}, $back )
    if ( $tool eq 'bash' || $task_output ) && exists $out{timeout};
  # TaskOutput waits by default, raider's bash_output does not: say it.
  $out{block} //= $back ? JSON::MaybeXS->true : JSON::MaybeXS->false if $task_output;
  return \%out;
}

# raider's bash takes whole seconds, Claude Code's Bash milliseconds.
sub _bash_timeout {
  my ( $self, $value, $back ) = @_;
  return $value unless defined $value && !ref $value && $value =~ /\A[0-9]+(?:\.[0-9]+)?\z/;
  return $value * 1000 unless $back;
  my $seconds = $value / 1000;
  return $seconds == int $seconds ? int $seconds : int($seconds) + 1;
}

sub is_mcp { my ( $self, $name ) = @_; return defined $name && $name =~ /\Amcp__[^_].*__.+\z/s ? 1 : 0 }

sub raider_name {
  my ( $self, $name ) = @_;
  croak __PACKAGE__.'->raider_name needs a tool name' unless defined $name && length $name;
  return $name if $self->is_mcp($name);
  return $RAIDER{$name};
}

sub claude_name {
  my ( $self, $name ) = @_;
  croak __PACKAGE__.'->claude_name needs a tool name' unless defined $name && length $name;
  return $name if $self->is_mcp($name);
  return $CLAUDE{$name};
}

sub claude_names { return sort keys %RAIDER }

sub raider_names { return sort keys %CLAUDE }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::ToolNames - Internal table of Claude Code tool names and the raider tools they stand for

=head1 VERSION

version 0.504

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

One place that says which raider tool a Claude Code tool name means. The
Claude-mode surfaces use it wherever a Claude Code name reaches raider: an
agent file's C<tools:> and C<disallowedTools:> list, a permission rule such as
C<Bash(npm run test:*)>, a hook matcher, a Claude Code session converted into
a scenario.

    Read -> read_file            Write -> write_file
    Edit -> edit_file            MultiEdit -> multi_edit
    Bash -> bash                 TaskOutput, BashOutput -> bash_output
    TaskStop, KillShell, KillBash -> kill_shell
    Glob -> glob                 Grep -> grep
    LS -> list_files             WebFetch -> web_fetch
    WebSearch -> web_search      Skill -> skill
    TodoWrite -> todo_write      TaskCreate -> task_create
    TaskUpdate -> task_update    TaskList -> task_list
    TaskGet -> task_get          Task, Agent -> agent
    AskUserQuestion -> ask_user  EnterPlanMode -> enter_plan_mode
    ExitPlanMode -> exit_plan_mode
    SendMessage -> send_message
    Monitor -> monitor           CronCreate -> cron_create
    CronDelete -> cron_delete    CronList -> cron_list
    EnterWorktree -> enter_worktree
    ExitWorktree -> exit_worktree

A name C<mcp__server__tool> is an MCP tool and passes through unchanged:
raider addresses MCP tools the same way. Any other name is unknown --
L</raider_name> returns undef; the table never guesses. ADR 0025 lists every
Claude Code tool name known and why those without a raider tool have none
(C<NotebookEdit>, C<ToolSearch>, ...).
C<Monitor>, C<CronCreate>, C<CronDelete> and C<CronList> mean the tools of the
same names since ADR 0031; C<ScheduleWakeup> stays unmapped.
C<SendMessage> means C<send_message> since ADR 0027, C<EnterWorktree> and
C<ExitWorktree> mean C<enter_worktree> and C<exit_worktree> since ADR 0032.

The table names the raider tool a Claude Code tool stands for; it does not
say that the tool is mounted in a run. raider mounts one task-list family at
a time, as Claude Code offers one (L<Langertha::Raider::TodoTools>):
C<task_create>, C<task_update>, C<task_list> and C<task_get> by default,
C<todo_write> instead with C<RAIDER_ENABLE_TASKS=0>.

Some raider tools have more than one Claude Code name: C<Task> and C<Agent>
mean C<agent>; C<TaskStop>, C<KillShell> and C<KillBash> (the names Claude
Code has given the tool that stops a background shell) mean C<kill_shell>;
C<TaskOutput> and the older C<BashOutput> mean C<bash_output>. The way back
(L</claude_name>) answers with the current name: C<Agent>, C<TaskStop>,
C<TaskOutput>. C<LS>, C<BashOutput> and C<TaskOutput> are gone from current
Claude Code; they stay for older sessions and agent files.

=head2 Arguments

The tools also name some arguments differently. L</claude_input> turns a
raider tool's arguments into the Claude Code tool's (what a hook gets as
C<tool_input>), L</raider_input> goes the way back (a hook's
C<updatedInput>):

    read_file, write_file, edit_file, multi_edit   path <-> file_path
    kill_shell                                     shell_id <-> task_id
    bash                                           timeout: seconds <-> milliseconds
    bash_output                                    bash_id <-> task_id,
                                                   timeout: seconds <-> milliseconds,
                                                   block: false <-> true when not given

C<kill_shell> answers to C<TaskStop>'s C<task_id> and to the C<shell_id> of
C<KillShell> and C<KillBash> (which C<TaskStop> still takes, deprecated):
the way back turns C<task_id> into C<shell_id> and lets C<shell_id> through.

C<bash_output> goes out as C<TaskOutput> (C<task_id>, C<block>, C<timeout>
in milliseconds). C<TaskOutput> waits for the command by default and
raider's C<bash_output> does not, so a C<block> left out is written down:
C<false> on the way to Claude Code, C<true> on the way back from a
C<TaskOutput> input. An input with C<bash_id> and no C<task_id> is the older
C<BashOutput> (C<bash_id>, C<filter>) and passes unchanged.

Every other key passes through unchanged under its own name, in both
directions: raider's tools took Claude Code's names where they have the same
argument (C<content>, C<old_string>, C<new_string>, C<edits>, C<pattern>,
C<glob>, C<output_mode>, C<-i>, C<command>, C<bash_id>, C<filter>, C<url>,
C<query>, C<todos>, C<subject>, C<description>, C<activeForm>, C<taskId>,
C<status>, C<addBlocks>, C<addBlockedBy>, C<owner>, C<metadata>, C<skill>,
C<args>, C<prompt>, C<subagent_type>, C<plan>, ...). Keys only one side knows
(C<offset> of C<Read>, C<description> of C<Bash>, C<as_html> of
C<web_fetch>, C<working_directory> of C<bash>) pass through too; the
receiving tool decides what to do with them.

C<ask_user> is the one tool whose arguments have another I<shape>, not other
names (C<question> and a list of C<options> strings, against
C<AskUserQuestion>'s C<questions> list of objects). There is no lossless
mapping, so its arguments pass through unchanged.

The round trip is lossless: C<raider_input( $t, claude_input( $t, $args ) )>
is C<$args> again, and the other way round, as long as an input does not
carry both names of one argument (C<path> and C<file_path>): then the
translated key wins and the other is dropped. The C<bash> C<timeout> is
lossless from raider (whole seconds) and back; milliseconds that are not
whole seconds become the next whole second, as raider's C<bash> takes
integers; the same for the C<timeout> of C<bash_output>. A C<bash_output>
input without C<block> comes back with C<block> false, which is what it meant.

=head2 is_mcp

    Langertha::Raider::ToolNames->is_mcp('mcp__github__create_issue');   # true

True for a name of the form C<mcp__server__tool>.

=head2 raider_name

    my $name = Langertha::Raider::ToolNames->raider_name('Read');   # 'read_file'

The raider tool for a Claude Code tool name, an C<mcp__*> name unchanged, or
undef for a name that is in neither.

=head2 claude_name

    my $name = Langertha::Raider::ToolNames->claude_name('read_file');   # 'Read'

The Claude Code name of a raider tool, an C<mcp__*> name unchanged, or undef
for a tool the table does not know.

=head2 claude_names

All Claude Code names of the table (not the MCP pass-through), sorted.

=head2 raider_names

All raider tool names of the table, sorted, each once.

=head2 claude_input

    my $in = Langertha::Raider::ToolNames->claude_input( read_file => { path => 'lib/A.pm' } );
    # { file_path => 'lib/A.pm' }

The arguments of a raider tool (named first, by its raider name) in the
form the Claude Code tool takes. A new hash ref; the input is not changed.
An unknown tool or an C<mcp__*> tool gets a plain copy. Croaks without a
tool name or when the arguments are not a hash ref.

=head2 raider_input

    my $in = Langertha::Raider::ToolNames->raider_input(
      edit_file => { file_path => '/abs/A.pm', old_string => 'a', new_string => 'b' },
    );
    # { path => '/abs/A.pm', old_string => 'a', new_string => 'b' }

The way back: arguments in the Claude Code form, for the raider tool named
first. Same rules as L</claude_input>.

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

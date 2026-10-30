package Langertha::Raider::WorktreeTools;
# ABSTRACT: Internal worktree tools of raider: enter_worktree and exit_worktree
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;
use MCP::Server;


has enter_handler => (
  is       => 'ro',
  isa      => 'CodeRef',
  required => 1,
);


has exit_handler => (
  is       => 'ro',
  isa      => 'CodeRef',
  required => 1,
);


has worktrees_dir => (
  is      => 'ro',
  isa     => 'Str',
  default => '.raider/worktrees/',
);


has base_setting => (
  is      => 'ro',
  isa     => 'Str',
  default => 'worktree_base_ref',
);


has server => (
  is       => 'ro',
  lazy     => 1,
  builder  => '_build_server',
  init_arg => undef,
);



sub name_error {
  my ( $self, $name ) = @_;
  my $rule = 'each "/"-separated segment may contain only letters, digits, dots, underscores and dashes,'
    .' at most 64 characters in all';
  return 'Invalid worktree name: '.$rule.'.' if !defined $name || ref $name || !length $name;
  return 'Invalid worktree name "'.$name.'": '.$rule.'.'
    if length $name > 64 || $name !~ m{\A[A-Za-z0-9._-]+(?:/[A-Za-z0-9._-]+)*\z};
  return 'Invalid worktree name "'.$name.'": a segment may not be "." or "..".'
    if grep { $_ eq '.' || $_ eq '..' } split m{/}, $name;
  return;
}


sub enter_error {
  my ( $self, $in ) = @_;
  my ( $name, $path ) = @{$in}{qw( name path )};
  return 'Pass name or path, not both.' if defined $name && defined $path;
  return 'path must be a non-empty string.' if defined $path && ( ref $path || !length $path );
  return $self->name_error($name) if defined $name;
  return;
}


sub enter_description {
  my ( $self ) = @_;
  my ( $dir, $base ) = ( $self->worktrees_dir, $self->base_setting );
  return <<"EOM" =~ s/\n+\z//r;
Use this tool ONLY when explicitly instructed to work in a worktree -- either by the user directly, or by project instructions (CLAUDE.md / memory). This tool creates an isolated git worktree and switches the current session into it.

## When to Use
- The user explicitly says "worktree" (e.g., "start a worktree", "work in a worktree", "create a worktree", "use a worktree")
- Project instructions or memory direct you to work in a worktree for the current task

## When NOT to Use
- The user asks to create a branch, switch branches, or work on a different branch -- use git commands instead
- The user asks to fix a bug or work on a feature -- use the normal git workflow unless worktrees are explicitly requested by the user or the project instructions
- Never use this tool unless "worktree" is explicitly mentioned by the user or in the project instructions

## Requirements
- Must be in a git repository
- Must not already be in a worktree session when creating a new worktree (name); switching into another existing worktree via path is allowed

## Behavior
- Creates a new git worktree inside $dir of the repository on a new branch worktree-NAME. The base is governed by the $base setting: fresh (default) branches from origin/HEAD (or HEAD when there is none); head branches from your current HEAD
- A name whose worktree or branch already exists is an error; pass path to enter it
- Switches the session's working directory to the new worktree: the file, search and shell tools work there from the next call on
- Use exit_worktree to leave the worktree mid-session (keep or remove). When the session ends while still in the worktree, it is removed if unchanged and kept otherwise

## Entering an existing worktree
Pass path instead of name to switch the session into a worktree that already exists. The path must appear in `git worktree list` of the repository and must not be the main checkout. The previous worktree, if any, is left on disk untouched and only the new one is tracked. exit_worktree will not remove a worktree entered this way; use action "keep" to return to the original directory. A path outside $dir is put to the user first.

## Parameters
- name (optional): A name for a new worktree. If neither name nor path is given, the name is session-N.
- path (optional): Path to an existing worktree to enter instead of creating one. Mutually exclusive with name.
EOM
}

sub exit_description {
  my ( $self ) = @_;
  return <<'EOM' =~ s/\n+\z//r;
Exit a worktree session started by enter_worktree and return the session to the original working directory.

## Scope
This tool ONLY operates on the worktree enter_worktree entered in this session. It will NOT touch:
- Worktrees you created manually with `git worktree add`
- Worktrees from a previous session (even if created by enter_worktree then)
- The directory you're in if enter_worktree was never called

If called outside a worktree session, the tool is a no-op: it reports that no worktree session is active and takes no action. Filesystem state is unchanged.

## When to Use
- The user explicitly asks to "exit the worktree", "leave the worktree", "go back", or otherwise end the worktree session
- Do NOT call this proactively -- only when the user asks

## Parameters
- action (required): "keep" or "remove"
  - "keep" -- leave the worktree directory and branch intact on disk. Use this if the user wants to come back to the work later, or if there are changes to preserve.
  - "remove" -- delete the worktree directory and its branch. Use this for a clean exit when the work is done or abandoned. Only a worktree enter_worktree created in this session can be removed.
- discard_changes (optional, default false): only meaningful with action "remove". If the worktree has uncommitted files or commits not on the original branch, the tool will REFUSE to remove it unless this is set to true. If the tool returns an error listing changes, confirm with the user before calling it again with discard_changes: true.

## Behavior
- Restores the session's working directory to where it was before enter_worktree
EOM
}

# Runs a handler; one that dies gives an error result.
sub _answer {
  my ( $self, $tool, $handler, $in ) = @_;
  my ( $text, $is_error );
  unless ( eval { ( $text, $is_error ) = $handler->($in); 1 } ) {
    ( $text, $is_error ) = ( ( "$@" =~ s/\s+\z//r ), 1 );
  }
  return $tool->text_result( $text // '', $is_error ? 1 : 0 );
}

sub _build_server {
  my ( $self ) = @_;
  my $server = MCP::Server->new( name => 'raider-worktree', version => '1.0' );
  $server->tool(
    name         => 'enter_worktree',
    description  => $self->enter_description,
    input_schema => {
      type       => 'object',
      properties => {
        name => { type => 'string', description => 'Optional name for a new worktree. Each "/"-separated segment may contain'
          .' only letters, digits, dots, underscores, and dashes; max 64 chars total. session-N when not given.'
          .' Mutually exclusive with path.' },
        path => { type => 'string', description => 'Path to an existing worktree to switch into instead of creating a new one.'
          .' Must appear in `git worktree list` of the repository. Mutually exclusive with name.' },
      },
    },
    code => sub {
      my ( $tool, $in ) = @_;
      $in = {} unless ref $in eq 'HASH';
      my %in = map { defined $in->{$_} ? ( $_ => $in->{$_} ) : () } qw( name path );
      if ( defined( my $error = $self->enter_error( \%in ) ) ) {
        return $tool->text_result( $error, 1 );
      }
      return $self->_answer( $tool, $self->enter_handler, \%in );
    },
  );
  $server->tool(
    name         => 'exit_worktree',
    description  => $self->exit_description,
    input_schema => {
      type       => 'object',
      properties => {
        action          => { type => 'string', enum => [qw( keep remove )],
          description => '"keep" leaves the worktree and branch on disk; "remove" deletes both.' },
        discard_changes => { type => 'boolean', description => 'Required true when action is "remove" and the worktree has'
          .' uncommitted files or unmerged commits. The tool will refuse and list them otherwise.' },
      },
      required => ['action'],
    },
    code => sub {
      my ( $tool, $in ) = @_;
      $in = {} unless ref $in eq 'HASH';
      my $action = $in->{action};
      return $tool->text_result( 'action must be "keep" or "remove".', 1 )
        unless defined $action && !ref $action && ( $action eq 'keep' || $action eq 'remove' );
      return $self->_answer( $tool, $self->exit_handler,
        { action => $action, discard_changes => $in->{discard_changes} ? 1 : 0 } );
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

Langertha::Raider::WorktreeTools - Internal worktree tools of raider: enter_worktree and exit_worktree

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    my $tools = Langertha::Raider::WorktreeTools->new(
      enter_handler => sub { my ( $in ) = @_; ...; return ( $text, $is_error ) },   # { name, path }
      exit_handler  => sub { my ( $in ) = @_; ...; return ( $text, $is_error ) },   # { action, discard_changes }
      worktrees_dir => '.claude/worktrees/',
    );
    my $server = $tools->server;   # MCP::Server with enter_worktree and exit_worktree

    Langertha::Raider::WorktreeTools->name_error('feature/x');   # undef: a valid name

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

The worktree tools of the main run (ADR 0032 E<sect>4), shaped after
Claude Code's C<EnterWorktree> and C<ExitWorktree>
(L<Langertha::Raider::ToolNames>): C<enter_worktree> moves the session's
working root into a git worktree -- a new one by C<name>, an existing one
by C<path> -- and C<exit_worktree> moves it back, keeping or removing the
worktree. The tools carry the texts and the schemas and check the shape of
a call (C<name> and C<path> together, a C<name> against Claude Code's rule,
an C<action> that is neither C<keep> nor C<remove>); everything else is the
handlers' -- the application's (L<Langertha::Raider::Application/working_root>).
A handler that dies gives an error result, never a dead answer.

=head2 enter_handler

Required. Called as C<< $enter_handler->({ name => ..., path => ... }) >>
(each key only when given) for every C<enter_worktree> call that passed the
checks of L</enter_error>; returns the result text and whether it is an
error.

=head2 exit_handler

Required. Called as C<< $exit_handler->({ action => 'keep' | 'remove',
discard_changes => 0 | 1 }) >> for every C<exit_worktree> call with a valid
C<action>; returns the result text and whether it is an error.

=head2 worktrees_dir

The directory below the repository's top that new worktrees go into, as
the texts name it: F<.claude/worktrees/> in the Claude layout, else (the
default) F<.raider/worktrees/>.

=head2 base_setting

The setting the texts name for the base of a new worktree:
C<worktree.baseRef> in the Claude layout, else (the default)
C<worktree_base_ref>.

=head2 server

The L<MCP::Server> with the tools C<enter_worktree> and C<exit_worktree>,
built once.

=head2 name_error

    my $error = $tools->name_error($name);   # undef when valid

Why C<$name> is no worktree name, or undef: Claude Code's rule -- segments
of letters, digits, C<.>, C<_> and C<->, joined by C</>, at most 64
characters -- and no segment C<.> or C<..> (the name is a directory below
L</worktrees_dir>).

=head2 enter_error

    my $error = $tools->enter_error({ name => 'x', path => '/repo/wt' });   # 'Pass name or path, not both.'

The error result of an C<enter_worktree> call whose shape is wrong, or
undef: C<name> and C<path> together, a C<path> that is not a non-empty
string, a C<name> L</name_error> refuses.

=head2 enter_description

=head2 exit_description

The texts of the two tools, after Claude Code's current C<EnterWorktree>
and C<ExitWorktree> texts in raider's names and with raider's behaviour:
no C<WorktreeCreate> hooks, an existing name is an error, the end of the
session keeps a worktree with changes without asking.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::Application>

=item * L<Langertha::Raider::Worktree>

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

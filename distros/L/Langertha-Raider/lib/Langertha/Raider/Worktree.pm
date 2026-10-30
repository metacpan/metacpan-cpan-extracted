package Langertha::Raider::Worktree;
# ABSTRACT: Internal git worktrees of raider: create, lock, inspect and remove them with the git command line
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;
use IPC::Run ();
use Path::Tiny;


has git => (
  is      => 'ro',
  isa     => 'Str',
  default => 'git',
);


# Runs git in $dir with @args (fixed, no shell); $in goes to its standard
# input. { out, err, exit } -- exit -1 when git could not be started.
sub _run {
  my ( $self, $dir, $args, $in ) = @_;
  my ( $out, $err ) = ( '', '' );
  local %ENV = %ENV;
  delete @ENV{qw( GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR )};
  $ENV{LC_ALL} = 'C';
  $ENV{GIT_TERMINAL_PROMPT} = 0;
  my $ok = eval {
    IPC::Run::run( [ $self->git, '-C', "$dir", @$args ], \( $in // '' ), \$out, \$err );
    1;
  };
  return { out => '', err => 'git cannot be started: '.( "$@" =~ s/ at \S+ line \d+.*//sr ), exit => -1 } unless $ok;
  return { out => $out, err => $err, exit => $? >> 8 };
}

# git in $dir; { out } when it exits 0 (or with one of @ok_exits), else
# { error }.
sub _git {
  my ( $self, $dir, @args ) = @_;
  my $opt = ref $args[0] eq 'HASH' ? shift @args : {};
  my $r = $self->_run( $dir, \@args, $opt->{in} );
  return { out => $r->{out}, exit => $r->{exit} }
    if $r->{exit} == 0 || grep { $_ == $r->{exit} } @{ $opt->{ok} // [] };
  return { error => $self->_error_text( \@args, $r ) };
}

# 'git worktree add: fatal: ...': the command words (up to the first
# option) and the first line of what git said.
sub _error_text {
  my ( $self, $args, $r ) = @_;
  return $r->{err} if $r->{exit} < 0;
  my @words;
  for my $a (@$args) {
    last if $a =~ /\A-/ || @words == 2;
    push @words, $a;
  }
  # git says what it is doing before it fails ("Preparing worktree ..."):
  # the line that says why comes first.
  my @lines = grep { /\S/ } split /\n/, $r->{err};
  my ( $line ) = ( ( grep { /\A(?:fatal|error):/ } @lines ), @lines );
  $line //= 'exit code '.$r->{exit};
  $line =~ s/\s+\z//;
  return 'git '.join( ' ', @words ).': '.$line;
}

sub _chomp { my ( $self, $s ) = @_; $s //= ''; $s =~ s/\s+\z//; $s }


sub toplevel {
  my ( $self, $dir ) = @_;
  return { error => $dir.' does not exist' } unless defined $dir && -d $dir;
  my $r = $self->_git( $dir, qw( rev-parse --show-toplevel ) );
  return $r if $r->{error};
  my $top = $self->_chomp( $r->{out} );
  return { error => $dir.' is not inside a git working tree' } unless length $top;
  return { top => $self->_real($top) };
}


sub repository_top {
  my ( $self, $dir ) = @_;
  my $tree = $self->toplevel($dir);
  return $tree if $tree->{error};
  my $r = $self->_git( $dir, qw( rev-parse --git-common-dir ) );
  return $r if $r->{error};
  my $common = $self->_chomp( $r->{out} );
  return { error => 'git rev-parse: no common git directory for '.$dir } unless length $common;
  return { top => $self->_real( path($common)->absolute($dir)->parent ) };
}


sub base_ref {
  my ( $self, $dir, $mode ) = @_;
  $mode //= 'fresh';
  if ( $mode ne 'head' ) {
    my $r = $self->_git( $dir, qw( rev-parse --verify --quiet refs/remotes/origin/HEAD^{commit} ) );
    my $commit = $r->{error} ? '' : $self->_chomp( $r->{out} );
    return { ref => 'origin/HEAD', commit => $commit } if length $commit;
  }
  my $r = $self->_git( $dir, qw( rev-parse --verify HEAD^{commit} ) );
  return { error => 'git rev-parse: HEAD does not name a commit in '.$dir } if $r->{error};
  return { ref => 'HEAD', commit => $self->_chomp( $r->{out} ) };
}


sub branch_exists {
  my ( $self, $dir, $branch ) = @_;
  my $r = $self->_git( $dir, qw( show-ref --verify --quiet ), 'refs/heads/'.$branch );
  return $r->{error} ? 0 : 1;
}


sub create {
  my ( $self, %arg ) = @_;
  my ( $source, $path, $branch, $base ) = @arg{qw( source path branch base )};
  return { error => 'create needs source, path, branch and base' }
    unless defined $source && defined $path && defined $branch && defined $base;
  return { error => $path.' exists' } if -e $path;
  eval { path($path)->parent->mkpath; 1 } or return { error => 'cannot make '.path($path)->parent.': '.$@ };
  my $r = $self->_git( $source, qw( worktree add --no-track -b ), $branch, $path, $base );
  return $r if $r->{error};
  my $copy = $self->_copy_included( $source, $path );
  return {
    path        => $self->_real($path),
    branch      => $branch,
    base        => $base,
    copied      => $copy->{copied},
    copy_errors => $copy->{errors},
  };
}


sub checkout {
  my ( $self, %arg ) = @_;
  my ( $dir, $path, $branch ) = @arg{qw( dir path branch )};
  return { error => $path.' exists' } if -e $path;
  eval { path($path)->parent->mkpath; 1 } or return { error => 'cannot make '.path($path)->parent.': '.$@ };
  my $r = $self->_git( $dir, qw( worktree add ), $path, $branch );
  return $r if $r->{error};
  return { path => $self->_real($path), branch => $branch };
}

# The .worktreeinclude copy of create: { copied => [...], errors => [...] }.
sub _copy_included {
  my ( $self, $source, $path ) = @_;
  my %out = ( copied => [], errors => [] );
  return \%out unless -f path($source)->child('.worktreeinclude');
  my $ls = $self->_git( $source, qw( ls-files -z --others --ignored --exclude-from=.worktreeinclude ) );
  if ( $ls->{error} ) {
    push @{ $out{errors} }, $ls->{error};
    return \%out;
  }
  my @candidates = grep { length && -f path($source)->child($_) } split /\0/, $ls->{out};
  return \%out unless @candidates;
  # check-ignore exits 1 when none of them is ignored.
  my $ci = $self->_git( $source, { in => join( "\0", @candidates )."\0", ok => [1] }, qw( check-ignore -z --stdin ) );
  if ( $ci->{error} ) {
    push @{ $out{errors} }, $ci->{error};
    return \%out;
  }
  for my $rel ( grep { length } split /\0/, $ci->{out} ) {
    my ( $from, $to ) = ( path($source)->child($rel), path($path)->child($rel) );
    next if -e $to;
    if ( eval { $to->parent->mkpath; $from->copy($to); chmod( ( stat $from )[2] & 07777, "$to" ); 1 } ) {
      push @{ $out{copied} }, $rel;
    }
    else {
      push @{ $out{errors} }, $rel.': '.( "$@" =~ s/\s+\z//r );
    }
  }
  return \%out;
}


sub lock {
  my ( $self, $path, $reason ) = @_;
  my $r = $self->_git( path($path)->parent, qw( worktree lock ), ( defined $reason ? ( '--reason', $reason ) : () ), $path );
  return $r->{error} ? $r : {};
}

sub unlock {
  my ( $self, $path ) = @_;
  my $r = $self->_git( path($path)->parent, qw( worktree unlock ), $path );
  return $r->{error} ? $r : {};
}


sub changes {
  my ( $self, $path, $base ) = @_;
  my $st = $self->_git( $path, qw( status --porcelain ) );
  return $st if $st->{error};
  my @status = grep { length } split /\n/, $st->{out};
  my $commits = 0;
  if ( defined $base && length $base ) {
    my $rl = $self->_git( $path, qw( rev-list --count ), $base.'..HEAD' );
    return $rl if $rl->{error};
    $commits = 0 + $self->_chomp( $rl->{out} );
  }
  return { status => \@status, commits => $commits };
}


sub remove {
  my ( $self, %arg ) = @_;
  my ( $dir, $path, $branch ) = @arg{qw( dir path branch )};
  my $r = $self->_git( $dir, qw( worktree remove ), ( $arg{force} ? '--force' : () ), $path );
  return $r if $r->{error};
  return {} unless defined $branch;
  my $b = $self->_git( $dir, qw( branch -D ), $branch );
  return $b->{error} ? { error => $b->{error} } : {};
}


sub list {
  my ( $self, $dir ) = @_;
  my $r = $self->_git( $dir, qw( worktree list --porcelain ) );
  return $r if $r->{error};
  my @trees;
  for my $block ( split /\n\n+/, $r->{out} ) {
    my %t;
    for my $line ( split /\n/, $block ) {
      my ( $key, $value ) = split / /, $line, 2;
      next unless defined $key && length $key;
      if    ( $key eq 'worktree' ) { $t{path} = $value }
      elsif ( $key eq 'HEAD' )     { $t{head} = $value }
      elsif ( $key eq 'branch' )   { $t{branch} = $value =~ s{\Arefs/heads/}{}r }
      elsif ( $key eq 'locked' || $key eq 'prunable' ) { $t{$key} = defined $value && length $value ? $value : 1 }
      else  { $t{$key} = 1 }
    }
    next unless defined $t{path};
    $t{main} = 1 unless @trees;
    push @trees, \%t;
  }
  return { worktrees => \@trees };
}

# The real path when it exists, else the path as it is.
sub _real {
  my ( $self, $p ) = @_;
  my $real = eval { path($p)->realpath };
  return defined $real ? "$real" : "$p";
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Worktree - Internal git worktrees of raider: create, lock, inspect and remove them with the git command line

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    my $git = Langertha::Raider::Worktree->new;

    my $top = $git->repository_top($root);             # { top => '/repo' } or { error => '...' }
    my $base = $git->base_ref( $root, 'fresh' );       # { ref => 'origin/HEAD', commit => 'a1b2...' }
    my $made = $git->create(
      source => '/repo',                               # the working tree the copy comes from
      path   => '/repo/.claude/worktrees/agent-1',
      branch => 'worktree-agent-1',
      base   => $base->{commit},
    );                                                 # { path, branch, base, copied => [ '.env' ] }
    $git->lock( $made->{path}, 'raider agent agent_1' );
    ...
    $git->unlock( $made->{path} );
    my $changes = $git->changes( $made->{path}, $base->{commit} );   # { status => [ '?? new.txt' ], commits => 0 }
    $git->remove( dir => '/repo', path => $made->{path}, branch => $made->{branch} )
      unless @{ $changes->{status} } || $changes->{commits};

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

The git work behind worktree isolation (ADR 0032 E<sect>1): subagents with
C<isolation: "worktree"> (L<Langertha::Raider::Subagent>) and the
C<enter_worktree> / C<exit_worktree> tools share it. Everything goes
through the C<git> command line (L</git>) with a fixed argument list --
C<git -C DIR ...>, no shell -- and the variables C<GIT_DIR>,
C<GIT_WORK_TREE>, C<GIT_INDEX_FILE> and C<GIT_COMMON_DIR> removed, so a
raider started from a git hook still works on the directory it names.

Every method answers with a hash reference; a failure is a value, never an
exception: C<< { error => 'git worktree add: fatal: ...' } >> (the git
command and the first line git wrote to standard error). A caller tests
C<< $r->{error} >>.

=head2 git

The git program. Default C<git>, found on C<PATH>.

=head2 toplevel

    my $r = $git->toplevel($dir);   # { top => '/repo' } or { error => ... }

The top of the working tree C<$dir> is in (C<git rev-parse
--show-toplevel>): the main checkout, or the worktree when C<$dir> is inside
one. An error when C<$dir> is not inside a git working tree.

=head2 repository_top

    my $r = $git->repository_top($dir);   # { top => '/repo' } or { error => ... }

The main checkout of the repository C<$dir> is in: the parent of the
absolute C<git rev-parse --git-common-dir>, so a C<$dir> inside a linked
worktree finds the same top as one in the main checkout. An error when
C<$dir> is not inside a git working tree.

=head2 base_ref

    my $r = $git->base_ref( $dir, 'fresh' );   # { ref => 'origin/HEAD', commit => '...' }
    my $r = $git->base_ref( $dir, 'head' );    # { ref => 'HEAD', commit => '...' }

The base a new worktree branches from (ADR 0032 E<sect>2, Claude Code's
C<worktree.baseRef>): C<fresh> (the default for any other value) is
C<origin/HEAD> when it resolves to a commit, else the C<HEAD> of C<$dir>;
C<head> is the C<HEAD> of C<$dir> -- inside a worktree that worktree's.
Nothing is fetched. An error when C<HEAD> does not resolve (a repository
without a commit).

=head2 branch_exists

    my $yes = $git->branch_exists( $dir, 'worktree-agent-1' );

True when the repository of C<$dir> has a local branch of that name.

=head2 create

    my $r = $git->create( source => $tree_top, path => $path, branch => $branch, base => $commit );
    # { path, branch, base, copied => [ ... ], copy_errors => [ ... ] } or { error => ... }

A new worktree at C<path> on a new branch C<branch> from C<base> (a commit
or ref; C<git worktree add --no-track -b BRANCH PATH BASE>, run in
C<source>), the parent directories made first. Then the
F<.worktreeinclude> of C<source> (C<.gitignore> syntax) is honoured: the
untracked files it matches (C<git ls-files --others --ignored
--exclude-from=.worktreeinclude>) that the repository ignores (C<git
check-ignore>) are copied to the same relative path, with their mode;
C<copied> lists them, C<copy_errors> what could not be copied (the
worktree is made either way). Without the file nothing is copied.

=head2 checkout

    my $r = $git->checkout( dir => $top, path => $path, branch => $branch );   # { path, branch } or { error }

An existing branch checked out into a new worktree at C<path> (C<git
worktree add PATH BRANCH>, run in C<dir>): a removed worktree of a resumed
agent comes back on its branch. No F<.worktreeinclude> copy -- only a new
worktree gets one.

=head2 lock

    my $r = $git->lock( $path, 'raider agent agent_1' );   # {} or { error }

=head2 unlock

    my $r = $git->unlock($path);   # {} or { error }

C<git worktree lock --reason REASON PATH> and C<git worktree unlock PATH>,
run in the worktree's parent: a locked worktree is not pruned and not
removed without C<--force> twice.

=head2 changes

    my $r = $git->changes( $path, $base );   # { status => [ ' M lib/A.pm', '?? new.txt' ], commits => 2 }

What the worktree at C<$path> has that its base has not (ADR 0027
E<sect>7): the lines of C<git status --porcelain> -- untracked files count,
ignored ones do not -- and the number of commits on its C<HEAD> beyond
C<$base> (C<git rev-list --count BASE..HEAD>). Without C<$base> only the
status is asked and C<commits> is C<0>.

=head2 remove

    my $r = $git->remove( dir => $top, path => $path, branch => $branch );            # {} or { error }
    my $r = $git->remove( dir => $top, path => $path, branch => $branch, force => 1 );

Removes the worktree (C<git worktree remove [--force] PATH>, run in
C<dir>) and then deletes its branch (C<git branch -D BRANCH>). A worktree
git refuses to remove keeps its branch; the error says which step failed.

=head2 list

    my $r = $git->list($dir);
    # { worktrees => [ { path => '/repo', head => '...', branch => 'main', main => 1 },
    #                  { path => '/repo/.claude/worktrees/agent-1', branch => 'worktree-agent-1', locked => 'raider agent agent_1' } ] }

The worktrees of the repository of C<$dir> (C<git worktree list
--porcelain>), the main checkout first (C<main> 1): C<path>, C<head>,
C<branch> (without C<refs/heads/>), and when git says so C<detached>,
C<bare>, C<locked> (the reason, or C<1>) and C<prunable>.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::Subagent>

=item * L<Langertha::Raider::Permissions/main_checkout_refusal>

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

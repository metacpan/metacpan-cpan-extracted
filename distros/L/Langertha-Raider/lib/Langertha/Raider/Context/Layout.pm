package Langertha::Raider::Context::Layout;
# ABSTRACT: Internal decision which project layout raider reads
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;
use Path::Tiny;
use Langertha::Raider::Home;


has root => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

sub home_class { 'Langertha::Raider::Home' }


has home => (
  is         => 'ro',
  isa        => 'Maybe[Str]',
  lazy_build => 1,
);

sub _build_home { $_[0]->home_class->home_dir }


has claude_home => (
  is         => 'ro',
  isa        => 'Maybe[Str]',
  lazy_build => 1,
);

sub _build_claude_home {
  my ( $self ) = @_;
  return unless defined $self->home || length( $ENV{CLAUDE_CONFIG_DIR} // '' );
  my $dir = $self->home_class->claude_home($self->home);
  return defined $dir ? $dir->stringify : undef;
}


has config_claude => (
  is => 'ro',
);

has force_claude => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);

has bare => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);

has _real_root => (
  is         => 'ro',
  lazy_build => 1,
);

sub _build__real_root { $_[0]->_real($_[0]->root) }

has _real_home => (
  is         => 'ro',
  lazy_build => 1,
);

sub _build__real_home {
  my ( $self ) = @_;
  my $home = $self->home;
  return defined $home ? $self->_real($home) : undef;
}

# Real paths of the home's own .claude directories: never project markers.
has _home_claude_dirs => (
  is         => 'ro',
  lazy_build => 1,
);

sub _build__home_claude_dirs {
  my ( $self ) = @_;
  my %dirs;
  $dirs{ $self->_real($self->claude_home)->stringify } = 1 if defined $self->claude_home;
  $dirs{ $self->_real($self->_real_home->child('.claude'))->stringify } = 1 if defined $self->_real_home;
  return \%dirs;
}

has _decision => (
  is         => 'ro',
  lazy_build => 1,
);

sub _build__decision {
  my ( $self ) = @_;
  return [ bare => '--bare' ] if $self->bare;
  my $root = $self->_real_root;
  my $home = $self->_real_home;
  return [ native => 'root is the home directory' ]
    if defined $home && $root->stringify eq $home->stringify;
  if ( defined( my $marker = $self->_raider_marker($root) ) ) {
    return [ raider => $marker.' in root' ];
  }
  for my $legacy (qw( .raider.yml .raider.md )) {
    return [ raider => $legacy.' in root' ] if -f $root->child($legacy);
  }
  for my $dir (reverse $self->walk_dirs) {
    my $marker = $self->_claude_marker($dir) or next;
    my $where = $dir->stringify eq $root->stringify ? 'root' : $dir->stringify;
    return [ claude => $marker.' in '.$where ];
  }
  return [ native => 'no raider or Claude files' ];
}


sub mode { $_[0]->_decision->[0] }

sub reason { $_[0]->_decision->[1] }


sub claude_layout { $_[0]->_claude_layout->[0] }

sub claude_layout_reason { $_[0]->_claude_layout->[1] }

has _claude_layout => (
  is         => 'ro',
  lazy_build => 1,
);

sub _build__claude_layout {
  my ( $self ) = @_;
  my $mode = $self->mode;
  return [ 0, 'off: --bare' ]             if $mode eq 'bare';
  return [ 1, 'Claude mode' ]             if $mode eq 'claude';
  return [ 1, '--claude' ]                if $self->force_claude;
  return [ 1, 'claude: true in config' ]  if $mode eq 'raider' && $self->config_claude;
  return [ 0, 'off: raider project without claude: true' ] if $mode eq 'raider';
  return [ 0, 'off: '.$self->reason ];
}


has _repo_top => (
  is         => 'ro',
  lazy_build => 1,
);

sub _build__repo_top {
  my ( $self ) = @_;
  my $dir = $self->_real_root;
  while (1) {
    return $dir if -e $dir->child('.git');
    return if $dir->is_rootdir;
    $dir = $dir->parent;
  }
}

sub repo_top { $_[0]->_repo_top }


has _walk_dirs => (
  is         => 'ro',
  lazy_build => 1,
);

sub _build__walk_dirs {
  my ( $self ) = @_;
  my $root = $self->_real_root;
  my $home = $self->_real_home;
  my $top  = $self->repo_top
    // ( defined $home && $home->subsumes($root) ? $home : $root );
  my @dirs;
  my $dir = $root;
  while (1) {
    push @dirs, $dir;
    last if $dir->stringify eq $top->stringify || $dir->is_rootdir;
    $dir = $dir->parent;
  }
  return [ reverse @dirs ];
}

sub walk_dirs { @{ $_[0]->_walk_dirs } }


sub project_dir {
  my ( $self ) = @_;
  for my $dir (reverse $self->walk_dirs) {
    return $dir if $self->_has_project_claude_dir($dir) || -f $dir->child('CLAUDE.md');
  }
  return $self->_real_root;
}

# A .raider/ directory makes a raider project only when it holds project
# files. raider itself creates .raider/sessions (the journal, ADR 0015), its
# .gitignore and .raider/lib (perl_cpanm's local::lib) in any project it runs
# in; counting those turned a Claude Code project native from its second run
# on. Only what raider reads counts: raiders/ (ADR 0011's named agents) is
# not read since ADR 0020 replaced it by agents/.
my @RAIDER_PROJECT_FILES = qw( config.yml instructions.md );
my @RAIDER_PROJECT_DIRS  = qw( skills agents packs );

sub _raider_marker {
  my ( $self, $root ) = @_;
  my $dir = $root->child('.raider');
  return unless -d $dir;
  for my $file (@RAIDER_PROJECT_FILES) {
    return ".raider/$file" if -f $dir->child($file);
  }
  for my $sub (@RAIDER_PROJECT_DIRS) {
    return ".raider/$sub/" if -d $dir->child($sub);
  }
  return;
}

sub _claude_marker {
  my ( $self, $dir ) = @_;
  for my $file (qw( CLAUDE.md CLAUDE.local.md )) {
    return $file if -f $dir->child($file);
  }
  return '.claude/' if $self->_has_project_claude_dir($dir);
  return;
}

sub _has_project_claude_dir {
  my ( $self, $dir ) = @_;
  my $claude = $dir->child('.claude');
  return 0 unless -d $claude;
  return $self->_home_claude_dirs->{ $self->_real($claude)->stringify } ? 0 : 1;
}

# The real path of $p; for a path that does not exist, the real path of its
# nearest existing ancestor with the rest appended.
sub _real {
  my ( $self, $p ) = @_;
  my $path = path($p)->absolute;
  my @rest;
  until (-e $path || $path->is_rootdir) {
    unshift @rest, $path->basename;
    $path = $path->parent;
  }
  my $real = eval { $path->realpath } // $path;
  return @rest ? $real->child(@rest) : $real;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Context::Layout - Internal decision which project layout raider reads

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $layout = Langertha::Raider::Context::Layout->new(
      root          => $root,
      config_claude => $config->{claude},   # undef when not set
      force_claude  => $opt{claude},
      bare          => $opt{bare},
    );
    say $layout->mode.' ('.$layout->reason.')';     # claude (CLAUDE.md in root)
    if ($layout->claude_layout) {
      my @dirs = $layout->walk_dirs;                 # repo top .. root
      my $dir  = $layout->project_dir;               # where .claude/ lives
    }

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

The layout-mode rule of ADR 0019 E<sect>1 as a pure function of the
filesystem and a few inputs. Raider decides once per application, from
L</root>, which layout it reads:

=over

=item * C<bare> -- L</bare> is set (C<--bare>, ADR 0014): no layout at all.

=item * C<native> -- L</root> is the home directory (the assistant home,
ADR 0002), whatever is there.

=item * C<raider> -- F<.raider/> in L</root> holding a project file:
F<config.yml>, F<instructions.md>, or one of the directories F<skills/>,
F<agents/>, F<packs/> (what raider writes there itself -- F<sessions/>,
F<lib/>, F<.gitignore> -- does not count, nor does F<raiders/>, which
nothing reads since ADR 0020); or a legacy F<.raider.yml> / F<.raider.md>
(ADR 0011).

=item * C<claude> -- no raider files, but F<CLAUDE.md>, F<CLAUDE.local.md>
or a F<.claude/> directory in L</root> or in a directory of L</walk_dirs>.
The home's own F<.claude/> (L</claude_home> and F<< <home>/.claude >>) never
counts as a marker.

=item * C<native> -- neither.

=back

L</claude_layout> then says whether the Claude layout (memory, settings,
Claude skill roots) is read. Paths are compared by their real path where the
filesystem has one, so a symlinked temp directory compares equal to its
target. Every directory this module returns is such a real path.

=head2 root

The project directory. Required.

=head2 home

The user's home directory. Defaults to
L<Langertha::Raider::Home/home_dir>; may be C<undef> when no home is known.

=head2 claude_home

The Claude Code configuration directory: C<$ENV{CLAUDE_CONFIG_DIR}> when
set and not empty, else F<< <home>/.claude >>. C<undef> when neither is
known.

=head2 config_claude

The effective C<claude:> value of the raider config: true, false, or
C<undef> when the config does not set it. Taken by truth, so a YAML or JSON
boolean object works as well.

=head2 force_claude

True for C<--claude>: the Claude layout is read in every mode but C<bare>.

=head2 bare

True for C<--bare>: mode C<bare>, no layout is read.

=head2 mode

    my $mode = $layout->mode;   # bare | raider | claude | native

The layout mode, decided once per object (see L</DESCRIPTION>).

=head2 reason

    my $why = $layout->reason;

What decided L</mode>, for C<config explain>: C<--bare>,
C<root is the home directory>, C<.raider/config.yml in root> (or another
project file in C<.raider/>, see L</DESCRIPTION>), C<.raider.yml in root>,
C<.raider.md in root>, C<CLAUDE.md in root> (or C<CLAUDE.local.md>,
C<.claude/>; an ancestor of the walk is named by its absolute path, as in
C<CLAUDE.md in /abs/dir>), or C<no raider or Claude files>.

=head2 claude_layout

    if ($layout->claude_layout) { ... }

True when the Claude layout (memory, settings, Claude skill roots) is read:
always in mode C<claude>; in mode C<raider> only with a true
L</config_claude>; never in mode C<native>; in every mode but C<bare> when
L</force_claude> is set; never in mode C<bare>.

=head2 claude_layout_reason

Why L</claude_layout> is on or off: C<Claude mode>, C<--claude>,
C<claude: true in config>, C<off: --bare>,
C<off: raider project without claude: true>, or C<off: > followed by the
L</reason> of mode C<native>.

=head2 repo_top

    my $top = $layout->repo_top;   # Path::Tiny or undef

The nearest directory from L</root> upward (L</root> included) that holds a
F<.git> file or directory, or C<undef> outside a repository.

=head2 walk_dirs

    my @dirs = $layout->walk_dirs;   # Path::Tiny, top down, last is root

The directories of the memory walk (ADR 0019 E<sect>2), top down and ending
at L</root>: from L</repo_top> when there is one, else from L</home> (the
home included) when L</root> is below it, else only L</root>.

=head2 project_dir

    my $dir = $layout->project_dir;   # Path::Tiny

The directory whose F<.claude/> holds the project settings and skills: the
nearest directory from L</root> upward along L</walk_dirs> with a
F<.claude/> directory (not the home's own) or a F<CLAUDE.md>; L</root> when
there is none.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::Context::Memory>

=item * L<Langertha::Raider::Home>

=item * L<Langertha::Raider::Instructions>

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

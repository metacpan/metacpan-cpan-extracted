# ABSTRACT: Native Git for Perl via libgit2 (FFI, no fork/exec)

package Git::Native;
our $VERSION = '0.005';
use Moo;
use Carp ();
use Git::Libgit2 qw(
  init_lib
  GIT_REPOSITORY_INIT_BARE
  GIT_OPT_SET_SEARCH_PATH
  GIT_CONFIG_LEVEL_PROGRAMDATA
  GIT_CONFIG_LEVEL_SYSTEM
  GIT_CONFIG_LEVEL_XDG
  GIT_CONFIG_LEVEL_GLOBAL
);
use Git::Libgit2::FFI ();
use Git::Native::Error qw( check_rc );
use Git::Native::Repository ();
use FFI::Platypus::Buffer qw( scalar_to_buffer );

use constant {
  GIT_CLONE_OPTIONS_VERSION => 1,
  # git_clone_options on libgit2 1.5 is ~312 bytes; over-allocate for
  # forward compat with newer libgit2 versions.
  CLONE_OPTIONS_SIZE        => 512,
};

# Ensure libgit2 is initialised before first use.
my $_init_count = 0;
sub _ensure_init {
  return if $_init_count;
  $_init_count = init_lib();
}

sub open {
  my ( $class, $path ) = @_;
  Carp::croak "Git::Native->open requires a path" unless defined $path;
  _ensure_init();
  my $repo;
  check_rc Git::Libgit2::FFI::git_repository_open( \$repo, $path );
  return Git::Native::Repository->new( _handle => $repo );
}

sub open_ext {
  my ( $class, $start_path, %opts ) = @_;
  _ensure_init();
  my $repo;
  check_rc Git::Libgit2::FFI::git_repository_open_ext(
    \$repo, $start_path,
    $opts{flags} // 0,
    $opts{ceiling_dirs},
  );
  return Git::Native::Repository->new( _handle => $repo );
}

sub init {
  my ( $class, $path, %opts ) = @_;
  Carp::croak "Git::Native->init requires a path" unless defined $path;
  _ensure_init();
  my $repo;
  my $flags = $opts{bare} ? GIT_REPOSITORY_INIT_BARE : 0;
  check_rc Git::Libgit2::FFI::git_repository_init( \$repo, $path, $flags );
  my $r = Git::Native::Repository->new( _handle => $repo );
  # Pin HEAD at the requested branch regardless of the compiled-in default
  # or ambient init.defaultBranch (sterile CI containers default to
  # 'master'). The branch may be unborn at this point - that's fine.
  if ( defined( my $branch = $opts{initial_branch} ) ) {
    $branch = "refs/heads/$branch" unless $branch =~ m{^refs/};
    $r->set_head($branch);
  }
  return $r;
}

# clone($url, $local_path) - non-bare only for now.
# Auth via credentials => sub {...} not yet plumbed; the clone_options
# struct embeds a fetch_options whose callback offset we'd need to probe
# per libgit2 version. Bare clones go through init+fetch+HEAD instead -
# the offset of `bare` is past two large embedded structs and isn't
# stable across libgit2 versions worth pinning here.
sub clone {
  my ( $class, $url, $local_path, %opts ) = @_;
  Carp::croak "Git::Native->clone requires url and local_path"
    unless defined $url && defined $local_path;
  Carp::croak "bare clones not yet supported by Git::Native->clone - use init(bare=>1) + remote + fetch"
    if $opts{bare};
  _ensure_init();

  my $buf = "\0" x CLONE_OPTIONS_SIZE;
  my ($buf_p) = scalar_to_buffer($buf);
  check_rc Git::Libgit2::FFI::git_clone_options_init( $buf_p, GIT_CLONE_OPTIONS_VERSION );

  my $repo;
  check_rc Git::Libgit2::FFI::git_clone( \$repo, $url, $local_path, $buf_p );
  return Git::Native::Repository->new( _handle => $repo );
}

# reference_name_is_valid($name) - does libgit2 accept this refname?
# No repository required. Returns 1 (valid) or 0 (invalid).
sub reference_name_is_valid {
  my ( $class, $name ) = @_;
  return 0 unless defined $name;
  _ensure_init();
  my $rc = Git::Libgit2::FFI::git_reference_name_is_valid( \my $valid, $name );
  return ( $rc == 0 && $valid ) ? 1 : 0;
}

# set_config_search_path(system => $dir, global => $dir, ...)
#
# Class method on purpose: git_libgit2_opts(GIT_OPT_SET_SEARCH_PATH) mutates
# one process-global table inside libgit2, not any repository's state. It
# does not change what an already-open repository reads (libgit2 resolved
# and cached that when the repository was opened) - only what the next
# git_repository_open sees. A ->set_config_search_path on
# Git::Native::Repository would therefore be a method that provably does
# nothing to the object it is called on.
my %CONFIG_LEVEL = (
  programdata => GIT_CONFIG_LEVEL_PROGRAMDATA,
  system      => GIT_CONFIG_LEVEL_SYSTEM,
  xdg         => GIT_CONFIG_LEVEL_XDG,
  global      => GIT_CONFIG_LEVEL_GLOBAL,
);

sub set_config_search_path {
  my ( $class, %levels ) = @_;
  Carp::croak "Git::Native->set_config_search_path needs at least one level"
    unless %levels;
  _ensure_init();
  for my $name ( sort keys %levels ) {
    my $level = $CONFIG_LEVEL{ lc $name }
      or Carp::croak "Git::Native->set_config_search_path: unknown config level "
        . "'$name' - expected one of: " . join( ', ', sort keys %CONFIG_LEVEL );
    my $dir = $levels{$name};
    check_rc Git::Libgit2::FFI::git_libgit2_opts(
      GIT_OPT_SET_SEARCH_PATH, $level, defined $dir ? "$dir" : undef );
  }
  return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Native - Native Git for Perl via libgit2 (FFI, no fork/exec)

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  use Git::Native;

  my $repo = Git::Native->open('/path/to/.git');
  my $main = $repo->reference('refs/heads/main');
  say $main->target;     # commit OID

  # Build a commit without forking git
  my $blob_oid = $repo->blob_create_frombuffer("hello\n");
  my $tb       = $repo->tree_builder;
  $tb->insert(name => 'hi.txt', oid => $blob_oid, mode => 0100644);
  my $tree_oid = $tb->write;
  my $commit_oid = $repo->commit_create(
    update_ref => 'HEAD',
    tree       => $tree_oid,
    parents    => [$main->target],
    message    => 'add greeting',
  );

=head1 DESCRIPTION

L<Git::Native> is a Moo wrapper around L<Git::Libgit2> (which binds
C<libgit2> via L<FFI::Platypus>). Use it instead of L<Git::Wrapper> or
L<Git::Repository> when you want to do Git work without forking the
C<git> binary on every operation.

Contrast:
- L<Git::Wrapper>, L<Git::Repository>: shell out to C<git>
- L<Git::Raw>: XS bindings, unmaintained since 2022, known segfaults
- L<Git::PurePerl>: pure-Perl read-only, no push/pull

=head2 open

  my $repo = Git::Native->open($path);

Open an existing repository at C<$path>. Returns a L<Git::Native::Repository>.

Opening can fail on ownership rather than on anything about the repository:
libgit2 carries git's dubious-ownership check and refuses a path owned by
another uid unless it is listed in C<safe.directory>. Containers and CI hit
this when an image is baked as root and then used as an unprivileged user —
see C<is_owner_mismatch> in L<Git::Native::Error>.

On libgit2 1.5.1 that failure does not identify itself. With no
C<safe.directory> entry anywhere, which is the usual state, the open dies with
C<GIT_ENOTFOUND> and C<config value 'safe.directory' was not found> — a
not-found naming a key that was never set, and C<is_not_found> is the
predicate that answers, not C<is_owner_mismatch>. C<safe.directory = *> is not
honoured either; the path has to be listed literally.

=head2 open_ext

  my $repo = Git::Native->open_ext($start_path, %opts);

Same as C<git_repository_open_ext> — walks up from C<$start_path>.
C<flags> and C<ceiling_dirs> are forwarded.

The ownership check described under C<open> applies here as well, to the
repository the walk lands on rather than to C<$start_path>.

=head2 init

  my $repo = Git::Native->init($path, bare => 1);
  my $repo = Git::Native->init($path, initial_branch => 'main');

Initialise a new repository at C<$path>, creating the directory if
needed, and return a L<Git::Native::Repository>. C<bare =E<gt> 1> creates
a bare repo.

C<initial_branch> points HEAD at that branch instead of whatever default
libgit2 was compiled with (Debian patches it to C<main>, upstream still
uses C<master>) — worth setting whenever the branch name matters, since
the branch is unborn until the first commit either way. A plain name is
taken as C<refs/heads/$name>.

=head2 clone

  my $repo = Git::Native->clone('https://github.com/Getty/p5-git-native.git', $path);

Clone C<$url> into C<$path> and return the L<Git::Native::Repository>.

Two limits today, both down to field offsets inside C<git_clone_options>
that shift between libgit2 versions: C<bare =E<gt> 1> is refused (use
C<< init(bare => 1) >> plus a remote and a fetch), and there is no
credentials callback, so the URL has to be one that needs no
authentication — public HTTPS, C<git://> or C<file://>. For an
authenticated clone, C<init> then
L<Git::Native::Remote/fetch> with C<credentials>.

=head2 reference_name_is_valid

  Git::Native->reference_name_is_valid('refs/heads/main');   # 1
  Git::Native->reference_name_is_valid('refs/bad..name');    # 0

Class method. Returns true if C<libgit2> considers C<$name> a valid
reference name. No repository handle required.

=head2 set_config_search_path

  # keep a test suite out of the developer's real git config
  Git::Native->set_config_search_path(
    system => $tmp, global => $tmp, xdg => $tmp, programdata => $tmp,
  );

  # prepend a directory, keeping what the level already searches
  Git::Native->set_config_search_path( global => "$dir" . ':$PATH' );

  # back to libgit2's compiled-in default
  Git::Native->set_config_search_path( system => undef );

Class method. Tells C<libgit2> which directories to search for the
non-repository config levels, i.e. where F</etc/gitconfig>,
F<~/.gitconfig> and F<$XDG_CONFIG_HOME/git/config> are looked up. Levels
are given by name — C<system>, C<global>, C<xdg>, C<programdata> — and
any combination may be passed in one call. Returns true.

Each argument is the level's I<search path>, not the config file:
libgit2 appends the filename it expects at that level (C<gitconfig> for
C<system> and C<programdata>, C<.gitconfig> for C<global>, C<git/config>
for C<xdg>). Several directories may be given in one string, separated
by C<:>; the first one that actually holds that file wins — they are
searched, not merged. A literal C<$PATH> in the string (single-quote it
in Perl) stands for what the level searches right now, so a path can be
extended instead of replaced. C<undef> resets the level to libgit2's
compiled-in default; an empty string blanks it, so nothing is read at
that level at all.

This is the only supported way to keep a process away from the system
config: C<libgit2> compiles the F</etc/gitconfig> path in and ignores
C<GIT_CONFIG_SYSTEM> and C<GIT_CONFIG_NOSYSTEM> alike (those reach the
C<git> CLI only). For C<global> and C<xdg> it is the more dependable
half of the same job as pointing C<HOME> elsewhere, and unlike C<HOME>
it still works after C<libgit2> has been initialised — the C<HOME> guess
happens once, inside C<git_libgit2_init>.

Two properties worth knowing before calling this outside a test suite:

=over 4

=item *

It is B<process-global>. Every repository opened afterwards — including
ones opened by unrelated code in the same process — uses the new paths.
That is why this is a class method on L<Git::Native> and not something
on L<Git::Native::Repository>.

=item *

It does not reach back. A repository that is already open keeps the
config it resolved when it was opened; only the next
C<git_repository_open> sees the change.

=back

Needs L<Git::Libgit2> 0.006 or newer, which is where C<git_libgit2_opts>
and the C<GIT_CONFIG_LEVEL_*> constants arrived.

=head1 SEE ALSO

L<Alien::Libgit2>, L<Git::Libgit2>, L<FFI::Platypus>, L<libgit2|https://libgit2.org/>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-git-native/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

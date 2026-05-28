# ABSTRACT: Native Git for Perl via libgit2 (FFI, no fork/exec)

package Git::Native;
our $VERSION = '0.003';
use Moo;
use Carp ();
use Git::Libgit2 qw( init_lib check_rc GIT_REPOSITORY_INIT_BARE );
use Git::Libgit2::FFI ();
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

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Native - Native Git for Perl via libgit2 (FFI, no fork/exec)

=head1 VERSION

version 0.003

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

=head2 open_ext

  my $repo = Git::Native->open_ext($start_path, %opts);

Same as C<git_repository_open_ext> — walks up from C<$start_path>.
C<flags> and C<ceiling_dirs> are forwarded.

=head2 init

  my $repo = Git::Native->init($path, bare => 1);

Initialise a new repository. C<bare =E<gt> 1> creates a bare repo.

=head2 reference_name_is_valid

  Git::Native->reference_name_is_valid('refs/heads/main');   # 1
  Git::Native->reference_name_is_valid('refs/bad..name');    # 0

Class method. Returns true if C<libgit2> considers C<$name> a valid
reference name. No repository handle required.

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

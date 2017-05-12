use 5.006;    # our
use strict;
use warnings;

package Git::Wrapper::Plus::Tester;

our $VERSION = '0.004011';

# ABSTRACT: Utility for testing things with a git repository

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo qw( has );
use Path::Tiny qw(path);








































































has 'temp_dir' => ( is => ro =>, lazy => 1, builder => 1 );
has 'home_dir' => ( is => ro =>, lazy => 1, builder => 1 );
has 'repo_dir' => ( is => ro =>, lazy => 1, builder => 1 );
has 'git'      => ( is => ro =>, lazy => 1, builder => 1 );



















has 'committer_name'  => ( is => ro =>, lazy => 1, builder => 1 );
has 'committer_email' => ( is => ro =>, lazy => 1, builder => 1 );
has 'author_name'     => ( is => ro =>, lazy => 1, builder => 1 );
has 'author_email'    => ( is => ro =>, lazy => 1, builder => 1 );

sub _build_temp_dir {
  return Path::Tiny->tempdir;
}

sub _build_home_dir {
  my ( $self, ) = @_;
  my $d = $self->temp_dir->child('homedir');
  $d->mkpath;
  return $d;
}

sub _build_repo_dir {
  my ( $self, ) = @_;
  my $d = $self->temp_dir->child('repodir');
  $d->mkpath;
  return $d;
}

sub _build_git {
  my ( $self, ) = @_;
  require Git::Wrapper;
  return Git::Wrapper->new( $self->repo_dir->absolute->stringify );
}

sub _build_committer_name {
  return 'A. U. Thor';
}

sub _build_committer_email {
  return 'author@example.org';
}

sub _build_author_name {
  my ( $self, ) = @_;
  return $self->committer_name;
}

sub _build_author_email {
  my ( $self, ) = @_;
  return $self->committer_email;

}












sub run_env {
  my ( $self, $code ) = @_;
  local $ENV{HOME}                = $self->home_dir->absolute->stringify;
  local $ENV{GIT_AUTHOR_NAME}     = $self->author_name;
  local $ENV{GIT_AUTHOR_EMAIL}    = $self->author_email;
  local $ENV{GIT_COMMITTER_NAME}  = $self->committer_name;
  local $ENV{GIT_COMMITTER_EMAIL} = $self->committer_email;
  return $code->( $self, );
}

no Moo;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Wrapper::Plus::Tester - Utility for testing things with a git repository

=head1 VERSION

version 0.004011

=head1 SYNOPSIS

    use Git::Wrapper::Plus::Tester;

    my $t = Git::Wrapper::Plus::Tester->new();

    $t->run_env( sub {

        my $wrapper = $t->git;

        $wrapper->init_db(); # ETC.

    } );

=head1 DESCRIPTION

This module solves the problem of the tedious amount of leg work you need to do
to simply execute a test with Git.

Namely:

=over 4

=item * Creating a scratch directory

=item * Creating a fake home directory in that scratch directory

=item * Setting C<HOME> to that fake home

=item * Setting valid, but bogus values for C<GIT_(COMMITTER|AUTHOR)_(NAME|EMAIL)>

=item * Creating a directory for the repository to work with in the scratch directory

=item * Creating a Git::Wrapper instance with that repository path

=back

This module does all of the above for you, and makes some of them flexible via attributes.

=head1 METHODS

=head2 C<run_env>

Sets up basic environment, and runs code, reverting environment when done.

    $o->run_env(sub {
        my $wrapper = $o->git;

    });

=head1 ATTRIBUTES

=head2 C<temp_dir>

B<OPTIONAL>

=head2 C<home_dir>

B<OPTIONAL>

=head2 C<repo_dir>

B<OPTIONAL>

=head2 C<git>

B<OPTIONAL>

=head2 C<committer_name>

B<OPTIONAL>. Defaults to C<A. U. Thor>

=head2 C<committer_email>

B<OPTIONAL>. Defaults to C<author@example.org>

=head2 C<author_name>

B<OPTIONAL>. Defaults to C<< ->committer_name >>

=head2 C<author_email>

B<OPTIONAL>. Defaults to C<< ->committer_email >>

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Git::Wrapper::Plus::Tester",
    "interface":"class",
    "inherits":"Moo::Object"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

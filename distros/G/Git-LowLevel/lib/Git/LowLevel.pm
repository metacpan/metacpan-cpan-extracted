package Git::LowLevel;
# ABSTRACT: LowLevel Blob/Tree/Commit operations on a GIT Repository
use strict;
use warnings;
use Moose;
use MooseX::Privacy;
use Git::LowLevel::Reference;



has 'git_dir' => (is => 'ro', isa => 'Str', required => 1);

has 'gitcmd' => (is => 'rw', isa=>'Str', default=>'git');

has 'bare' => (is => 'rw', default=>0, traits => [qw/Private/]);




private_method _isGit => sub {
  my $self = shift;

  return 0 unless -d $self->git_dir();

  if (-d $self->git_dir . "/.git")
  {
      $self->bare(0);
      return 1;
  }
  my $help=readpipe("cd " . $self->git_dir . "; " . $self->gitcmd() . ' rev-parse --git-dir 1>/dev/null 2> /dev/null;echo $?');
  chomp($help);

  if ($help == 0)
  {
    $self->bare(1);
    return 1;
  }

  return 0;
};

sub BUILD {
  my $self = shift;

  die("directory does not exist (".$self->git_dir . " )") unless -d $self->git_dir();
  die("directory is not a git repository (" .$self->git_dir . " )") unless $self->_isGit();

  #update gitcmd attribute
  $self->gitcmd($self->gitcmd . ' --git-dir='.$self->git_dir());
  if ($self->bare()==0)
  {
    $self->gitcmd($self->gitcmd . "/.git");
  }

};


sub getReference
{
  my $self = shift;
  my $ref  = shift;

  return Git::LowLevel::Reference->new(repository=>$self, reference=>$ref);
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::LowLevel - LowLevel Blob/Tree/Commit operations on a GIT Repository

=head1 VERSION

version 0.4

=head1 DESCRIPTION

Git::LowLevel is a Perl Module for using gits low level functions to create and read
blobs, trees, commits and references.

Git::LowLevel is not intended to be used for script based committing or something
like that.

It main indent is to create/read references and their trees while you have checked out
abother branch.

=head2 EXAMPLE1

  use Git::LowLevel;

  my $repository = Git::LowLevel->new(git_dir => "/tmp/repo");
  my $ref        = $repository->getReference("refs/heads/master");
  my $tree       = $ref->getTree();

  die ("reference does not exist") unless $ref->exist();
  die ("no files in tree") unless !$tree->empty();

  my $blob = $tree->find("/doc/doxygen.conf");
  die("no blob found") unless defined($blob) && ref($blob) eq "Git::LowLevel::Blob";

  print $blob->content;

=head2 EXAMPLE2

  use Git::LowLevel;

  my $repository = Git::LowLevel->new(git_dir => "/tmp/repo");
  my $ref        = $repository->getReference("refs/heads/master");
  my $tree       = $ref->getTree();

  my $newblob    = $tree->newBlob();
  $newblob->path("hello");
  $newblob->_content("Hello World");
  $tree->add($newblob);
  $ref->commit("added hello");

=head1 ATTRIBUTES

=head2 git_dir

directory of the git repository

=head2 gitcmd

path to the git command, default is to search in your path

=head2 bare

B<private attribute>

holds the value if this repository is a bare one or not

=head1 METHODS

=head2 _isGit

B<private method>

checks if git_dir is a git repository

=head2 BUILD

B<private method>

called after new for internal setup

=head2 getReference

returns a reference object from the given reference path

@param none

@return L<Git::LowLevel::Reference> object

=head1 AUTHOR

Dominik Meyer <dmeyer@federationhq.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Dominik Meyer.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

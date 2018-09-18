package Git::LowLevel::Reference;
# ABSTRACT: class representing a reference in a git repository
use Moose;
use MooseX::Privacy;

use Git::LowLevel::Tree;


has 'repository'  =>  (is => 'ro', isa => 'Git::LowLevel', required => 1);

has 'reference' => (is => 'ro',  isa => 'Str', required=>1);

has '_hash' => (is => 'rw', isa => 'Str', default => "empty", traits => [qw/Private/]);

has 'tree' => (is => 'rw', isa => 'Git::LowLevel::Tree');


sub exist
{
  my $self  =shift;

  my $help = readpipe($self->repository->gitcmd() . " show-ref --dereference");
  my @lines = split /\n/,$help;
  for my $line (@lines)
  {
    $line =~/^([0-9a-fA-F]+)\s(.+)$/;
    if ($2 eq $self->reference)
    {
      $self->_hash($1);
      return 1;
    }
  }

  return 0;
}

sub hash
{
  my $self  = shift;

  die("reference does not exist") unless $self->exist();

  return $self->_hash;
}

sub getTree
{
  my $self = shift;
  my $help;
  if ($self->exist) {
    $help = readpipe($self->repository->gitcmd() . " cat-file -p  " . $self->_hash);
    my @lines = split /\n/,$help;
    if ($lines[0]=~/^tree\s(.*)$/)
    {
      $help=$1;
    }
  }
  if (!defined($help) || length($help) == 0)
  {
    $help="empty";
  }

  if ($help eq "empty")
  {
    $self->tree(Git::LowLevel::Tree->new(repository=> $self->repository, reference=> $self, hash => $help));
  }
  else
  {
    $self->tree(Git::LowLevel::Tree->new(repository=> $self->repository, reference=> $self, hash => $help, changed=>1));
  }
  return $self->tree;
}

sub find
{
  my $self = shift;
  my $path = shift;

  return $self->getTree()->find($path);
}

sub commit
{
  my $self = shift;
  my $comment = shift;

  die("no comment given") unless defined($comment);

  $self->exist;

  return unless defined($self->tree);

  $self->tree->save();

  my $cmd = "/bin/echo -e \'" . $comment. "\' | " .  $self->repository->gitcmd() . " commit-tree " . $self->tree->hash;
  if (length($self->_hash) == 40)
  {
    $cmd .= " -p " . $self->_hash;
  }
  my $help = readpipe($cmd);
  chomp($help);
  $self->_hash($help);

  $help = readpipe($self->repository->gitcmd() . " update-ref " . $self->reference . " " . $self->_hash);


}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::LowLevel::Reference - class representing a reference in a git repository

=head1 VERSION

version 0.4

=head1 DESCRIPTION

Class representing a Reference object within the Git::LowLevel distribution.

References in B<git> normally start with C<refs/heads/> e.g. C<refs/heads/master>

To get a reference to an existing or non existing reference your first require
a L<Git::LowLevel> object representing a B<git> repository.

  my $repository = Git::LowLevel->new(git_dir => "/tmp/repo");
  my $ref        = $repository->getReference();

The main methods within a reference object are getTree to fetch a tree object of the selected
reference, find to find a specific path within the tree and commit to commit any changes to
the tree and update the reference within B<git>.

=head1 ATTRIBUTES

=head2 repository

the repository the rerference lives in

=head2 reference

the reference path e.g. refs/heads/master

=head2 _hash

the hash pointing to by the reference

=head2 tree

the tree of this reference

=head1 METHODS

=head2 exist

checks if the reference already exists

1 = exist, 0 = not exist

=head2 hash

returns the hash pointing to by the reference

=head2 getTree

return the tree pointing to by the hash

=head2 find

find a path within the tree of the reference

=head2 commit

commit all changes and update the reference

=head1 AUTHOR

Dominik Meyer <dmeyer@federationhq.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Dominik Meyer.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

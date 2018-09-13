package Git::LowLevel::Tree;
# ABSTRACT: class representing a tree object in a GIT Repository
use Moose;
use MooseX::Privacy;
use File::Basename;
use Git::LowLevel::Blob;

has 'repository'  => (is => 'ro', isa => 'Git::LowLevel', required => 1);

has 'reference' => (is => 'ro', isa => 'Git::LowLevel::Reference', required => 1);

has 'path'  => (is => 'rw',isa=>'Str', default=> '.');

has 'hash'  => (is => 'rw', isa => 'Str', required => 1);

has 'tree' => (is => 'rw',isa=> 'ArrayRef', default=> sub {return [];});

has 'parent' => (is => 'rw', isa => 'Git::LowLevel::Tree');


has 'changed' => (is => 'rw', isa => 'Bool', default=>0);

sub timestamp_added
{
  my $self  = shift;
  my $help = readpipe($self->repository->gitcmd() . " log --follow --diff-filter=A --date=raw " . $self->reference->reference . " -- \"" . $self->path . "\" 2>/dev/null");
  my @lines = split /\n/,$help;
  for my $line (@lines)
  {
    if ($line =~ /^Date:\s+(\d+)\s([+-]\d+)$/)
    {
      return $1;
    }
  }

  return $help;
}

sub timestamp_last
{
  my $self  = shift;
  my $help = readpipe($self->repository->gitcmd() . " log --follow --date=raw " . $self->reference->reference . " -- \"" . $self->path . "\" 2>/dev/null");
  my @lines = split /\n/,$help;
  for my $line (@lines)
  {
    if ($line =~ /^Date:\s+(\d+)\s([+-]\d+)$/)
    {
      return $1;
    }
  }

  return $help;
}

sub committer
{
  my $self  = shift;
  my $help = readpipe($self->repository->gitcmd() . " log --follow --date=raw " . $self->reference->reference . " -- \"" . $self->path . "\" 2>/dev/null");
  my @lines = split /\n/,$help;
  for my $line (@lines)
  {
    if ($line =~ /^Author:\s(.*)$/)
    {
      return $1;
    }
  }

  return $help;
}


sub mypath
{
  my $self = shift;
  my $path = basename($self->path);

  return $path;
}

sub get
{
  my $self = shift;
  my @ret;

  return @{$self->tree} unless @{$self->tree} == 0;

  my $help = readpipe($self->repository->gitcmd() . " ls-tree " . $self->reference->reference . " \"" . $self->path . "/\" 2>/dev/null");
  my @lines = split /\n/,$help;
  for my $line (@lines)
  {
    $line =~ /^([0-9]+) (.+) ([0-9a-fA-F]{40})\t(.+)$/;

    if ($2 eq "blob")
    {
      push(@ret, Git::LowLevel::Blob->new(repository=>$self->repository, hash => $3, path => $4, parent=>$self));
    }
    else
    {
      push(@ret, Git::LowLevel::Tree->new(repository=>$self->repository, reference=> $self->reference, hash => $3, path => $4 . "/", parent=>$self));
    }

  }
  $self->tree(\@ret);

  return @ret;
}

sub empty
{
  my $self  = shift;
  $self->get();

  if (@{$self->tree} == 0)
  {
    return 1;
  }

  return 0;
}

sub newBlob
{
  my $self  = shift;

  return Git::LowLevel::Blob->new(repository => $self->repository);
}

sub newTree
{
  my $self  = shift;

  return Git::LowLevel::Tree->new(repository => $self->repository, reference => $self->reference, hash=>"empty", changed => 1);
}

sub add
{
  my $self  = shift;
  my $elem  = shift;

  die("no supported object type " . ref($elem)) unless ref($elem) eq 'Git::LowLevel::Blob' || ref($elem) eq 'Git::LowLevel::Tree';

  if (ref($elem) eq "Git::LowLevel::Blob")
  {
    die("path missing in Blob") unless length($elem->path)>0;
    die("content missing in Blob") unless length($elem->_content)>0;
  }

  $self->get();
  $self->changed(1);
  $elem->parent($self);
  push(@{$self->tree}, $elem);
}

sub del
{
  my $self = shift;
  my $elem = shift;

  die("no supported object type " . ref($elem)) unless ref($elem) eq 'Git::LowLevel::Blob' || ref($elem) eq 'Git::LowLevel::Tree';

  $self->get();
  my @tree;
  for my $t (@{$self->tree})
  {
    my $path = fileparse($t->path);
    if (length($path)==0)
    {
      $path = $t->path;
      $path =~ s/\///;
    }

    my $path2 = fileparse($elem->path);
    if (length($path2)==0)
    {
      $path2 = $elem->path;
      $path2 =~ s/\///;
    }

    if ($path ne $path2)
    {
      push(@tree,$t);
    }

  }
  $self->changed(1);
  $self->tree(\@tree);

}

sub save
{
  my $self  = shift;
  my $str   = "";

  for my $t (@{$self->tree})
  {
    $t->save;
    $str .= $t->treeEntry;
  }

  if ($self->changed()) {
    my $help = readpipe("/bin/echo -e \"" . $str. "\" | " .  $self->repository->gitcmd() . " mktree --batch ");
    chomp($help);
    $self->hash($help);
    $self->changed(0);
  }

}
sub treeEntry
{
  my $self = shift;

  return "" unless $self->hash ne "empty";

  return "040000 tree " . $self->hash . "\t" . $self->mypath() . "\n";
}


sub find
{
  my $self  = shift;
  my $path  = shift;

  return $self unless $self->mypath ne $path;

  $self->get();
  for my $t (@{$self->tree})
  {
    my $r = $t->find($path);
    if (defined($r))
    {
      return $r;
    }
  }

  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::LowLevel::Tree - class representing a tree object in a GIT Repository

=head1 VERSION

version 0.3

=head1 ATTRIBUTES

=head2 repository

the repository the tree lives in

=head2 reference

the reference the tree lives in

=head2 path

the path to the tree object

=head2 hash

the hash identifying the tree object

=head2 tree

the tree entries

=head2 parent

the parent of the object within the tree

=head2 changed

identifies if the tree has been changed
add,del or initial create of the tree

=head1 METHODS

=head2 timestamp_added

returns the timestamp of the commit where this object was added or undef if
object has not been commited yet.

=head2 timestamp_last

returns the timestamp of the last commit of this object or undef if
object has not been commited yet.

=head2 committer

returns the committer of the the object

=head2 mypath

=head2 get

returns an array of all the tree objects

=head2 empty

tests if the tree is empty

=head2 newBlob

create a new blob entry

=head2 newTree

create a new tree entry

=head2 add

add a new tree element

=head2 del

delete an element from the tree

=head2 save

save the full tree to the git object safe

=head2 treeEntry

return a string representing a tree entry

=head2 find

find a path within the tree

=head1 AUTHOR

Dominik Meyer <dmeyer@federationhq.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Dominik Meyer.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

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

sub get
{
  my $self = shift;
  my @ret;

  return @{$self->tree} unless @{$self->tree} == 0;

  my $help = readpipe($self->repository->gitcmd() . " ls-tree " . $self->reference->reference . " \"" . $self->path . "\" 2>/dev/null");
  my @lines = split /\n/,$help;
  for my $line (@lines)
  {
    $line =~ /^([0-9]+) (.+) ([0-9a-fA-F]{40})\t(.+)$/;

    if ($2 eq "blob")
    {
      push(@ret, Git::LowLevel::Blob->new(repository=>$self->repository, hash => $3, path => $4));
    }
    else
    {
      push(@ret, Git::LowLevel::Tree->new(repository=>$self->repository, reference=> $self->reference, hash => $3, path => $4 . "/"));
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

  return Git::LowLevel::Tree->new(repository => $self->repository, reference => $self->reference, hash=>"empty");
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

  $self->tree(\@tree);

}

sub save
{
  my $self  = shift;
  my $str   = "";

  return unless defined($self->tree);

  for my $t (@{$self->tree})
  {
    $t->save;
    $str .= $t->treeEntry;
  }
  my $help = readpipe("/bin/echo -e \"" . $str. "\" | " .  $self->repository->gitcmd() . " mktree --batch ");
  chomp($help);
  $self->hash($help);

}
sub treeEntry
{
  my $self = shift;

  return "" unless $self->hash ne "empty";

  my $path = fileparse($self->path);
  if (length($path)==0)
  {
    $path=substr($self->path,0,length($self->path)-1);
  }



  return "040000 tree " . $self->hash . "\t" . $path . "\n";
}


sub find
{
  my $self  = shift;
  my $path  = shift;

  return $self unless $self->path ne $path;

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

version 0.1

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

=head1 METHODS

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

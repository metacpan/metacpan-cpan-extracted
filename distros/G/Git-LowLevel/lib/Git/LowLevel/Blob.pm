package Git::LowLevel::Blob;
#ABSTRACT: class representing a GIT Blow Object
use Moose;
use MooseX::Privacy;
use File::Basename;



has 'repository'  => (is => 'ro', isa => 'Git::LowLevel', required => 1);

has 'hash'  => (is => 'rw', isa => 'Str');

has 'path'  => (is => 'rw', isa => 'Str');

has 'parent' => (is => 'rw', isa => 'Git::LowLevel::Tree');


has '_content' => (is =>'rw');

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
  my $path = fileparse($self->path);
  if (!defined($path) || length($path)==0)
  {
    $path = $self->path;
  }

  $path=~s/\///g;

  return $path;
}



sub content
{
  my $self = shift;

  my $help = readpipe($self->repository->gitcmd() . " cat-file blob " . $self->hash);
  chomp($help);

  $self->_content($help);

  return $help;
}


sub save
{
  my $self  = shift;

  return unless defined($self->_content()) && length($self->_content)>0;

  #TODO: perhaps do not use stdin ... better for binary files
  my $help = readpipe("echo \'".$self->_content."\' |" .  $self->repository->gitcmd() . " hash-object -w --stdin ");
  chomp($help);

  $self->hash($help);

}

sub treeEntry
{
  my $self = shift;

  if (defined($self->hash) && length($self->hash)>30 )
  {
    return "100644 blob " . $self->hash . "\t" . $self->mypath . "\n";
  }

  return "";
}

sub find
{
  my $self  = shift;
  my $path  = shift;

  return $self unless $self->mypath ne $path;

  return;
}

sub del
{
  my $self = shift;

  $self->_content("");
  $self->hash(" ");

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::LowLevel::Blob - class representing a GIT Blow Object

=head1 VERSION

version 0.4

=head1 DESCRIPTION

Class representing a Blob object within the Git::LowLevel distribution.

Blobs in B<git> normally hold any type of file data.

=head1 ATTRIBUTES

=head2 repository

the repository the blob lives in

=head2 hash

the hash identifying the blob, only set if the blob exist/is created in the repository

=head2 path

the path identifying the blob

=head2 parent

the parent of the object within the tree

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

=head2 content

return the content of the Blob

=head2 save

save content to git object and update hash

=head2 treeEntry

return a string representing a tree entry

=head2 find

find a path within the tree

=head2 del

delete the blob

=head1 AUTHOR

Dominik Meyer <dmeyer@federationhq.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Dominik Meyer.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

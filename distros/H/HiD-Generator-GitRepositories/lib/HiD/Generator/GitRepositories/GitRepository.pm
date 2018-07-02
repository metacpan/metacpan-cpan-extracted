package HiD::Generator::GitRepositories::GitRepository;
# ABSTRACT: HiD GitRepository Class
use Moose;
use File::Basename;
use File::ShareDir ':ALL';
use JSON;
use DateTime;
use DateTime::TimeZone;
use Data::Dumper;
use strict;
use warnings;

our $VERSION = "0.3";

binmode STDOUT, ':utf8';

has 'git_dir' => (is => 'ro', isa=> 'Str', default=>"");

has 'gitcmd' => (is => 'rw', isa=>'Str', default=>'git');

has 'bare' => (is => 'rw', default=>0);


has 'name' => (is => 'rw', isa=>'Str');


has 'branches' => (is => 'rw', default => sub{return [];});

has 'languages' => (is => 'rw', default => sub{return [];});

sub isGit
{
  my $self = shift;

  return 0 unless -d $self->git_dir();

  if (-d $self->git_dir . "/.git")
  {
      $self->bare(0);
      return 1;
  }

  my $help=readpipe($self->gitcmd() . ' rev-parse --git-dir 1>/dev/null 2> /dev/null;echo $?');
  chomp($help);

  if ($help == 0)
  {
    $self->bare(1);
    return 1;
  }

  return 0;
}

sub parse_branches
{
  my $self = shift;

  my $help = readpipe($self->gitcmd() . " show-ref --dereference");
  my @lines = split /\n/, $help;

  $self->branches([]);

  for my $line (@lines)
  {
    if ($line =~ m!^([0-9a-fA-F]{40})\srefs/(.*)$!) {

      my $branch = {
          name => $2,
          ref => $1
      };

      if ($branch->{name} !~ /^tags/ && $branch->{name} !~ /^remote/)
      {
        push(@{$self->branches},$branch);
      }
    }
  }

}

sub hasBranch
{
  my $self  = shift;
  my $branch= shift;

  for my $b (@{$self->branches})
  {
    if ($b->{name} eq $branch)
    {
      return 1;
    }
  }

  return 0;
}

sub getBranchRef
{
  my $self   = shift;
  my $branch = shift;

  for my $b (@{$self->branches})
  {
    if ($b->{name} eq $branch)
    {
      return $b->{ref};
    }
  }

  return;
}

sub getFileRef
{
  my $self    = shift;
  my $branch  = shift;
  my $file    = shift;

  my $help = readpipe($self->gitcmd() . " ls-tree " . $branch . " " . $file);
  chomp($help);
  if ($help =~ /^([0-9]+) (.+) ([0-9a-fA-F]{40})\t(.+)$/)
  {
    return $3;
  }

  return;
}

sub hasMetaData
{
  my $self = shift;

  return 0 unless $self->hasBranch("heads/metadata");
}

sub tags {
  my $self = shift;
  my @tags;

  return [] unless $self->hasMetaData;

  my $ref = $self->getFileRef("metadata","tags");

  warn("No tags file found in metadata branch (". $self->git_dir .")") unless $ref;
  return unless $ref;

  my $help = readpipe($self->gitcmd() . " cat-file blob " . $ref);
  my @lines = split /\n/,$help;

  for my $line (@lines)
  {
    push(@tags, $line);
  }

  return @tags;
}

sub description {
  my $self = shift;
  my @tags;

  return [] unless $self->hasMetaData;

  my $ref = $self->getFileRef("metadata","description");

  warn("No description file found in metadata branch (". $self->git_dir .")") unless $ref;
  return unless $ref;

  my $help = readpipe($self->gitcmd() . " cat-file blob " . $ref);
  chomp($help);

  return $help;
}

sub hasLanguage
{
  my $self = shift;
  my $lang = shift;

  for my $l (@{$self->languages})
  {
    if ($l eq $lang)
    {
      return 1;
    }
  }

  return 0;
}

sub parse_languages
{
  my $self = shift;
  my $shared = dist_dir('HiD-Generator-GitRepositories');
  $self->languages([]);

  # only parse programming languages if metadata is available
  return unless $self->hasMetaData();

  my $json_text = do {
   open(my $json_fh, "<:encoding(UTF-8)", $shared."/extensions.json")
      or die("Can't open \$filename\": $!\n");
   local $/;
   <$json_fh>
};

my $extensions=from_json($json_text);

for my $b (@{$self->branches})
{
  #get all files of current branch
  my $help = readpipe($self->gitcmd() . " ls-tree " . $b->{name} . " -r" );
  my @lines = split /\n/,$help;
  for my $l (@lines)
  {
      if ($l =~ /^([0-9]+) (.+) ([0-9a-fA-F]{40})\t(.+)$/)
      {
        my $filename = fileparse($4);
        $filename=~/^.*(\..+)$/;
        my $extension=$1;

        if ($extension=~/\S+/) {
          for my $ee (@{$extensions})
          {
            if ($ee->{type} eq "programming") {
              for my $e (@{$ee->{extensions}})
              {
                if ($e eq $extension)
                {
                  push(@{$self->languages}, $ee->{name}) unless $self->hasLanguage($ee->{name});
                }
              }
            }
          }
        }
      }
  }

}

}


sub lastActivity
{
  my $self = shift;

  my $help = readpipe($self->gitcmd() . " for-each-ref --format=\'%(committer)\' --sort=-committerdate --count=1" );
  chomp($help);

  if ( $help=~ / (\d+) [-+][01]\d\d\d$/)
  {
    my $dt  = DateTime->from_epoch( epoch => $1 );

    return $dt->month_name . " " . $dt->day . " " . $dt->year;
  }

  return;
}


sub lastChange
{
  my $self = shift;

  my $help = readpipe($self->gitcmd() . " for-each-ref --format=\'%(committer)\' --sort=-committerdate --count=1" );
  chomp($help);

  if ( $help=~ / (\d+) ([-+][01]\d\d\d)$/)
  {
    my $tz=DateTime::TimeZone->new( name => 'local' );
    my $dt  = DateTime->from_epoch( epoch => $1 , time_zone=>$tz);

    return $dt;
  }

  return;
}

sub lastChangeBranch
{
  my $self   = shift;
  my $branch = shift || "heads/master";

  my $help = readpipe($self->gitcmd() . " for-each-ref --format=\'%(refname) %(committer)\' --sort=-committerdate | grep \"" . $branch ."\"");
  chomp($help);

  if ( $help=~ / (\d+) [-+][01]\d\d\d$/)
  {
    my $dt  = DateTime->from_epoch( epoch => $1 );

    return $dt;
  }

  return;
}

sub getFileLog
{
  my $self   = shift;
  my $branch = shift || "master";
  my $file   = shift || ".";
  my $nr     = shift || 20;
  my $skip   = shift || 0;

  my @log;
  my $help = readpipe(" LC_ALL=C " . $self->gitcmd() . " log --follow --date=raw --max-count=" . $nr . " --skip=" .$skip . " " . $branch . " -- " .$file);
  my @lines = split /\n/,$help;

  my %entry;
  my $start_comment=0;

  for my $line (@lines)
  {
    if ($line =~ /^commit\s([a-fA-F0-9]+)/)
    {
        my $commit = $1;
        if (defined($entry{commit}))
        {
          push(@log, \%entry);
        }

        %entry=();
        $entry{commit}=$commit;
    }

    if ($line =~ /^Author:\s(.*)\s<(.*)>$/)
    {
      $entry{author}->{name}=$1;
      $entry{author}->{email}=$2;
    }

    if ($line =~/^Date:\s+(\d+)/)
    {
      $entry{date}=$1;
    }

    if ($line=~/^\s*$/ && $start_comment==0)
    {
      $start_comment=1;
    }
    elsif ($line=~/^\s*$/ && $start_comment==1)
    {
      $start_comment=0;
    }
    elsif ($start_comment == 1)
    {
      $entry{comment} .= $line;
    }

  }
  push(@log,\%entry);

  return @log;
}

sub getTree
{
  my $self    = shift;
  my $branch  = shift || "master";
  my $root    = shift;
  my @tree;

  my $help = readpipe($self->gitcmd() . " ls-tree " . $branch . " " . $root);

  my @lines = split /\n/,$help;

  for my $l (@lines)
  {
    $l =~ /^([0-9]+) (.+) ([0-9a-fA-F]{40})\t(.+)$/;
    my $path = $4;
    my $type = $2;
    my $name = fileparse($path);
    my @log =  $self->getFileLog($branch, $path, 1, 0);

    my $entry={
      type => $type,
      ref  => $3,
      path  => $path,
      name => $name,
      mode => $1,
      commit => $log[0]
    };
    push(@tree, $entry);
  }

  return @tree;
}

sub getBlob
{
  my $self = shift;
  my $ref = shift;

  my $help = readpipe($self->gitcmd() . " cat-file blob " . $ref);

  return $help;
}

# subroutine to parse information from the git repository after calling new
sub BUILD {
  my $self = shift;

  die("directory parameter missing (" .$self->git_dir . " )") unless length($self->git_dir())>0;
  die("directory does not exist (".$self->git_dir . " )") unless -d $self->git_dir();
  die("directory is not a git repository (" .$self->git_dir . " )") unless $self->isGit();

  #update gitcmd attribute
  $self->gitcmd($self->gitcmd . ' --git-dir='.$self->git_dir());
  if ($self->bare()==0)
  {
    $self->gitcmd($self->gitcmd . "/.git");
  }

  # set the repository name
  $self->name(fileparse($self->git_dir));

  # parse all available branches
  $self->parse_branches();

};

sub generate {
  my( $self , $site ) = @_;


}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HiD::Generator::GitRepositories::GitRepository - HiD GitRepository Class

=head1 VERSION

version 0.3

=head1 ATTRIBUTES

=head2 git_dir

the path to the git directory

=head2 gitcmd

the full path to the git command

=head2 bare

is the git repository a bare repository

=head2 name

the name of the repository

=head2 branches

all the available branches

=head2 languages

all the languages used in the repository

=head1 METHODS

=head2 isGit

tests if the given directory is a valid git repository

=head2 parse_branches

parses all the available branches

=head2 hasBranch

method search for a specific branch

  hasbranch("heads/master")

=head2 getBranchRef

return the reference of a specific branch

=head2 getFileRef

return the reference to a file in a branch

=head2 hasMetaData

checks of a metadata branch exist and information is available

=head2 tags

returns all the tags for this repository

=head2 description

returns the short description of the repository

=head2 hasLanguage

checks if the project has this kind of programming language

=head2 languages

returns an array of programming languages used within the repository

=head2 lastActivity

  returns a string with last activity information

=head2 lastChange

returns a DateTime object identifying the last commit within the repository

=head2 lastChangeBranch

returns a DateTime object identifying the last change in a branch

=head2 getFileLog

return log entries of a specific branch and file

=head2 getTree

return the tree of the given branch and root

=head2 getBlob

return the blob of a file reference

=head1 AUTHOR

Dominik Meyer <dmeyer@federationhq.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Dominik Meyer.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

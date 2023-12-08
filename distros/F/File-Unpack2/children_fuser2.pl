#! /usr/bin/perl -w
# 
# children_fuser2.pl -- find children of a given process 
#                       that have opened a given file.
#
# 2010-07-31, jw - initial version (not using Proc::ProcessTable)

use Data::Dumper;
use Cwd;

my $file = shift || '/home/testy/.xsession-errors';
my $parent = shift;

my $p = fuser($file, $parent);
fuser_offset($p);
print Dumper $p;

exit 0;
##############################################
sub fuser
{
  my ($file, $ppid) = @_;
  $ppid ||= 1;
  $file = Cwd::abs_path($file);

  opendir DIR, "/proc" or die "opendir /proc failed: $!\n";
  my %p = map { $_ => {} } grep { /^\d+$/ } readdir DIR;
  closedir DIR;

  # get all procs, and their parent pids
  for my $p (keys %p)
    {
      if (open IN, "<", "/proc/$p/stat")
        {
	  # don't care if open fails. the process may have exited.
	  my $text = join '', <IN>;
	  close IN;
	  if ($text =~ m{\((.*)\)\s+(\w)\s+(\d+)}s)
	    {
	      $p{$p}{cmd} = $1;
	      $p{$p}{state} = $2;
	      $p{$p}{ppid} = $3;
	    }
	}
    }

  # Weed out those who are not in our family
  if ($ppid > 1)
    {
      for my $p (keys %p)
	{
	  my $family = 0;
	  my $pid = $p;
	  while ($pid)
	    {
	      # Those that have ppid==1 may also belong to our family. 
	      # We never know.
	      if ($pid == $ppid or $pid == 1)
		{
		  $family = 1;
		  last;
		}
	      last unless $p{$pid};
	      $pid = $p{$pid}{ppid};
	    }
	  delete $p{$p} unless $family;
	}
    }

  my %o; # matching open files are recorded here

  # see what files they have open
  for my $p (keys %p)
    {
      if (opendir DIR, "/proc/$p/fd")
        {
	  my @l = grep { /^\d+$/ } readdir DIR;
	  closedir DIR;
	  for my $l (@l)
	    {
	      my $r = readlink("/proc/$p/fd/$l");
	      next unless defined $r;
	      # warn "$p, $l, $r\n";
	      if ($r eq $file)
	        {
	          $o{$p}{cmd} ||= $p{$p}{cmd};
	          $o{$p}{fd}{$l} = { file => $file };
		}
	    }
	}
    }
  return \%o;
}


# see if we can read the file offset of a file descriptor, and the size of its file.
sub fuser_offset
{
  my ($p) = @_;
  for my $pid (keys %$p)
    {
      for my $fd (keys %{$p->{$pid}{fd}})
        {
	  if (open IN, "/proc/$pid/fdinfo/$fd")
	    {
	      while (defined (my $line = <IN>))
	        {
		  chomp $line;
		  $p->{$pid}{fd}{$fd}{$1} = $2 if $line =~ m{^(\w+):\s+(.*)\b};
		}
	    }
	  close IN;
	  $p->{$pid}{fd}{$fd}{size} = -s $p->{$pid}{fd}{$fd}{file};
	}
    }
}

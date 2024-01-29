#!/usr/bin/env perl
package File::Find::Fast;
use strict;
use warnings;
#use Class::Interface qw/implements/;
use Exporter qw(import);
use File::Basename qw/fileparse basename dirname/;
use File::Temp qw/tempdir tempfile/;
use File::Spec;
use Data::Dumper;
use Carp qw/croak confess/;

our $VERSION = '0.4.0';

our @EXPORT_OK = qw(find find_iterator $VERSION);

local $0=basename $0;

# If this is used in a scalar context, $self->toString() is called
#use overload '""' => 'toString';

=pod

=head1 NAME

File::Find::Fast

=head1 SYNOPSIS

A module to find files much more quickly than `File::Find`.
The trick is that it doesn't `stat` any files.

=head2 Quick start

    use strict;
    use warnings;
    use Data::Dumper qw/Dumper/;
    use File::Find::Fast qw/find/;

    my $files = find("some/directory");
    print Dumper $files

=head1 DESCRIPTION

I purely made this module because I wanted a fast way to list files without running stat.
By using this module, you do not get file information directly.
You would have to use `stat` or similar methods as a follow up.

=head1 METHODS

=over

=item find($dir)

Finds all files in a directory, recursively.

    my $files = find("t/files");
    print join("\n", @$files);
    print "\n";

=back

=cut

sub find{
  my($dir) = @_;

  my @file = ($dir);

  if(!-d $dir){
    croak "ERROR: $dir is not a directory";
  }
  _find_recursive($dir, \@file);

  return \@file;
}

# TODO make a find_iterator function, e.g., 
# https://chat.openai.com/share/1788ccf6-60f1-4c19-8674-01a42deb4daa

=pod

=over

=item find_iterator

An iterator for finding files. Breadth first.
This is useful if you don't want to load all the files into memory first.

    $it = find_iterator("t/files");
    while(my $f=$it->()){
      next if($f =~ /2/); # skip any file that has a 2 in it
      print $f."\n";
    }

=back

=cut

sub find_iterator{
  my($dir) = @_;

  # First check to make sure we can actually look at this directory
  if(!-d $dir){
    croak "ERROR: $dir is not a directory";
  }
  
  # List of files that will be returned
  my @file = ($dir);
  # List of directories to read down the road
  my @dirQueue = ($dir);

  my $is_done = 0;

  return sub{
    if($is_done){
      return undef;
    }

    if(@file){
      return(shift(@file));
    }
    if(!@file){
      # if no more files and no more dirs, then mark that we're done
      if(!@dirQueue){
        $is_done = 1;
        return undef;
      }

      # Get more files loaded: read a whole directory from the @dirQueue
      my $currentDir = shift(@dirQueue);
      opendir(my $dh, $currentDir) || confess "Can't opendir $currentDir: $!";
      while(my $file = readdir($dh)){
        next if($file =~ /^\.{1,2}$/); # avoid . and .. files
        my $path = "$currentDir/$file";
        push(@file, $path);
        if(-d $path){
          push(@dirQueue, $path);
        }
      }
      closedir($dh);

      # if more files get loaded
      if(@file){
        return(shift(@file));
      }
      else{
        $is_done = 1;
        return undef;
      }
    }
  }
}

sub _find_recursive{
  my($parentDir, $files) = @_;

  opendir(my $dh, $parentDir) || confess "Can't opendir $parentDir: $!";
  while(my $file = readdir($dh)){
    next if($file =~ /^\.{1,2}$/);
    my $path = "$parentDir/$file";
    #my $path = File::Spec->catfile($parentDir, $file);
    push(@$files, $path);
    if(-d $path){
      _find_recursive($path, $files);
    }
  }
  closedir($dh);
  return 1;
}

1;


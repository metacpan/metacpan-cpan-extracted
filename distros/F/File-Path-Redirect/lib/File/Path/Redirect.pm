package File::Path::Redirect;

use strict;
use warnings;

our $VERSION="v0.1.3";




=head1 NAME

File::Path::Redirect - Poor Man's Symbolic Link Path Redirection

=head1 SYNOPSIS

  use File::Path::Redirect;

  # Run this example in 'examples' dir
  # Create  a test file to link to
  #
  my $source_path="path_to_file.txt";
  my $contents="Probably a large file";

  open my $fh, ">", $source_path or die $!;
  print $fh $contents;
  close $fh;
  
  

  # 'Link' or redirect a file to another
  #
  my $link_path="my_link.txt";

  make_redirect($source_path, $link_path);

  
  # Elsewhere in the application normal and redirect files are tested
  my $path=follow_redirect($link_path);

  # open/process $path as normal
  open my $f,"<", $path or die $!;
  while(<$f>){
    print $_;
  }


=head1 DESCRIPTION

This module implements a handful of functions implementing 'user space' file
path redirection, similar to a symbolic link on your file system.

It supports chained redirect files, with recursion limit.

=head1 WHY SHOULD I USE THIS?

=over
  
=item Not all File Systems support Sumbolic links

For example FAT and exFAT variants do not support symbolic links.

=item Symbolic links only work withing the same volume

If you wanted to symbolic link to a file on a different volume, you can't

=item Copying files my night be feasable

Slow and size constrained external media means extra copies of large files
might not fit. Also slow devices would take too long to physically copy

=back

=head1 HOW IT WORKS

The redirect ( or link ) file is just a basic text file. It contains a single
line of the format:
  
  !<symlink>PATH

!<symlink> is a magic header
PATH is the relative path to a file it links to. It can be a link to another link file.


Before using a path in an C<open> function, the path can be passed to
C<follow_redirect>. The return value is the path of the first non link file
found. This is path can be used in the C<open> call instead.


=head1 API

=head2 Creating Redirects

=head3 make_redirect

  my $path = make_redirect $existing_file, $link_file, $force;

Creates a new redirect file at C<$link_file> containing a link to the file located at C<$existing_file>.

C<$existing_file> can be a relative or absolute path.

The file is only created if C<$link_file> doesn't already exist, or C<$force>
is a true value.



Returns the relative path between the two files if possible, otherwise a
absolute path.  Dies on any IO related errors in creating / opening / writing /
closing the link file.

=head2 Using Redirects

=head3 follow_redirect 

  my $path = follow_redirect $file_path, $limit;

Given a file path C<$path>, it attempts to open the file, check it is a
redirect file.  If so it parses and follows the link path. The process is
recursive until the file does not look like a link path, or until the total
number of redirects is equal to or greater than C<$limit>.

C<$limit> is an optional parameter and by default is 10.

Returns the final redirect path. The path could be relative or absolute.

Dies on any IO errors when processing a redirect chain.

=head1 PERFORMANCE CONSIDERATIONS

Each redirect file encountered is opened and read. For repeated access to the
same file, it is best to store the results of the C<follow_redirect> function.

For more comprehensive solution, L<File::Meta::Cache> (which uses this module)
might suit your needs

=head1 REPOSITORY and BUG REPORTING

Please report any bugs and feature requests on the repo page:
L<GitHub|https://github.com/drclaw1394/perl-file-path-redirect>

=head1 AUTHOR

Ruben Westerberg, E<lt>drclaw@mac.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 by Ruben Westerberg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, or under the MIT license

=cut


#use IO::FD;
use Fcntl qw(O_RDONLY);
use POSIX;
use File::Spec::Functions qw<abs2rel rel2abs catfile file_name_is_absolute>;
use File::Basename qw<dirname basename>;

my $default_limit=10;
my $mode=O_RDONLY;  # Read only while following links
my $magic="!<symlink>";
my $max_size = $^O eq 'MSWin32' ? 260 : (POSIX::pathconf('/', &POSIX::_PC_PATH_MAX) // 4096);

use constant::more qw<OK=0 TOO_MANY ACCESS_ERROR NOT_A_REDIRECT>;
use Export::These qw<make_redirect follow_redirect is_redirect>;

$max_size+=length $magic;



# $existing is the path to link to
# $name is the path to the file we will create
sub make_redirect {
  my ($existing, $name, $force)=@_;
   
  if( $force or ! -e $name ){
    # make relative $name to existing
    my $path;
    if(file_name_is_absolute $existing){
      $path=$existing;
    }
    else {
      $path=abs2rel($existing, dirname $name);
    }
    open my $fh, ">", $name or die $!;
    print $fh "$magic$path" or die $!;
    close $fh;
    return $path;
  }
  die "Redirect/Link file already exists: $name";
}

sub follow_redirect{
  my ($path, $limit, $trace)=@_;

  if(!defined $limit){
    $limit=$default_limit;
  }

  if($limit == 0){
      # gone far enough. Error
      $!=TOO_MANY;      # mark as to many reidrects
      return undef;
  }

  
  my $is_abs=file_name_is_absolute $path;

  # Open the file
  #
  my $fd=POSIX::open($path, $mode);
  defined $fd or die "Error opening file $path: $!";
  my $buffer="";
  my $count=0;
  # Read the contents up to the max length of path for the current system + magic header size
  my $res;
  while(($res=POSIX::read $fd, my $data="", $max_size)!=0){
    $count+=$res;
    
    $buffer.=$data;
    last if $count== $max_size;
  }
  defined $res or die $!;
  POSIX::close $fd;


  # Check for magic header
  if((my $index=index($buffer, $magic))==0){
    # Found  attempt to read
    my $new_path=substr $buffer, length $magic;

    if(file_name_is_absolute $new_path){
      # Use as is
    }
    else {
      # Build realtive to current file
      $new_path= catfile dirname($path), $new_path;
    }

    push @$trace, $path if $trace;
    return follow_redirect($new_path, $limit-1, $trace);
  }
  else {
    # Not a redirect file, this is the target
    $!=NOT_A_REDIRECT;
    return $path;
  }
}

sub is_redirect {
  my ($path)=@_;

  my $fd=POSIX::open($path, $mode);
  defined $fd or die $!;
  my $buffer="";
  my $count=0;
  # Read the contents up to the max length of path for the current system + magic header size
  my $res;
  while(($res=POSIX::read $fd, my $data="", $max_size)!=0){
    $count+=$res;
    $buffer.=$data;
  }
  defined $res or die $!;
  POSIX::close $fd;


  # Check for magic header
  (my $index=index($buffer, $magic))==0;
}

1;

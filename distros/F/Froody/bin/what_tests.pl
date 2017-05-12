#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use File::Spec::Functions;
use File::Basename;

my @files;

my $path = catfile(shift(@ARGV),"*.t");
@files = sort grep {!/00/ } glob($path);

my $foo = <<ENDOFDOC;
#=head1 NAME
#
#tests - describes what the test files do
#
#=head1 DESCRIPTION
#
#This is a quick summary of what the test files for this distribution
#do.  It's automatically build form the comments at the start of each
#of the pod files.
#
#=over
#
ENDOFDOC
print map { s/#//g; $_ } $foo;


FISH:
foreach my $filename (@files)
{
  open my $fh, "<", $filename
    or die "Can't open '$filename' for reading!\n";

  my $name = fileparse($filename);
  my $output = "=item $name\n\n";

  while (<$fh>)
    { last if /\s*##########################/; }
  
  # did we either not find the start of the comment block or
  # find that the comment block starts too far down the file?  FAIL!
  if ($. > 8 or eof $fh) {
    next;
  }
  
  while (<$fh>)
  { 
    # found closing ########## - we got the comment - PASS!
    if (/\s*###########################/)
    {
      print "$output\n";
      next FISH;
    }
    
    # comment ended without a ############ - FAIL!
    if (!/^\s*#\s*(.*)?/)
    {
      next FISH;
    }
    
    $output .= "$1\n";
  }
  
  # reached end of file without ending comment - FAIL!
}

$foo = <<ENDOFDOC;
#=back
#
#=head1 SEE ALSO
#
#L<Test::More>
#
#=cut
ENDOFDOC
print map { s/#//g; $_ } $foo;


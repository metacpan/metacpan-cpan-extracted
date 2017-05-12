#
#===============================================================================
#
#         FILE:  RelDir.pm
#
#  DESCRIPTION:  This module provides a mechanism to determine the relative
#                path between two directory names.
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:   (Dave Roberts), <droberts@cpan.org>
#      COMPANY:
#      VERSION:  1.0
#      CREATED:  15/04/2010 20:30:39 GMT
#     REVISION:  $Revision: 1.0 $
#===============================================================================

use strict;
use warnings;
package File::RelDir;
use Carp;
require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(
  
);

our $VERSION = "0.1";
sub Version {
return $VERSION;
}

sub New {
  if ($#_ != 1){
     printf "_  %s\n",$#_;
     carp "Usage: File::Repl->New(\$dir)";
  }
  my $class = shift;
  my($r);
  $r->{dira} = $_[0];
  ($r->{patha},$r->{w32a})=&_dc($r->{dira});
  bless  $r, $class;
  return $r;
}

sub _dc {   # Directory Check - sanity check the directory name
	my($dir) = @_;
	my($c) = $dir =~ s/\\/\//g;  # use forward slash as directory seperator
        if ($c>0){
		return $dir,1;   # return win32 status if \ directory seperators
	}elsif ($dir =~ m/^[a-z]{1}:/){
		return $dir,2;   # return win32 status if drive letter leads path
	}else{
		return $dir,0;
	}
	carp "sub _dc failed";
}

sub Path {
    my($r,$dirb,$w);
  if ( scalar(@_) eq 2 ) {
    ($r,$dirb) =@_;
}else{
     carp "Usage: \$ref->Path(\$dir)";
}
  $r->{dirb} = $dirb;
  ($r->{pathb},$r->{w32b})=&_dc($r->{dirb});
  # Set windows flag - drives case insensitive testing
  $w = $r->{w32a} || $r->{w32b} || 0;

# split both paths by dir seperators
   my(@dira,@dirb,$i,$j,$relpath);
   @dira = split(/\//,$r->{patha});
   @dirb = split(/\//,$r->{pathb});
   unless( $dira[0] eq $dirb[0] ){
	my($err) = "different file systems or not absolute paths";
	# for unix these values will be null ("")
	# for win32 a drive letter (need to deal with case differences here
	#if ( $dira[0] =~ m/^[a-z]{1}:$/i ){  # test logic for a drive letter
	if ( $dira[0] =~ m/^[a-z]{1}:$/i ){  # test logic for a drive letter
	   unless (lc($dira[0]) eq lc($dirb[0])){
		   carp $err;
		   return 0;
	   }
	}else{
	   carp $err;
		   return 0;
        }
}
my($min) = $#dira;
$min = $#dirb if ($#dirb < $min);
$j=-1;

for($i=0;$i<=$min;$i++){
	if (($w == 0) & ($dira[$i] eq $dirb[$i])){
		#	print "segment $i identical ( $dira[$i] eq $dirb[$i] )\n";
		$j=$i;
	}elsif (($w >= 1) & (lc($dira[$i]) eq lc($dirb[$i]))){
		#	print "segment $i identical ( $dira[$i] eq $dirb[$i] )\n";
		$j=$i;
	}else{
		#print "segment $i differ\n";
		last;
	}
}
if ($j >= 0){
  $i = $#dira - $j;
    $relpath = "." if ($i == 0);
    $relpath = sprintf "../" x $i unless ($i == 0);
    for ($i=$j+1;$i<=$#dirb;$i++){
      $relpath .= "/" unless ($relpath =~ m/\/$/);
      $relpath .= $dirb[$i];
    }

}else{
   carp "different file systems or not absolute paths";
}
$relpath =~ s/\//\\/g if ($r->{w32a} == 1);
return $relpath;

}

sub Diff ($$) {
# provide a relartive pathname from direcrtory a to directory b
  my ($dira, $dirb) = @_;
  my($ref)=File::RelDir->New($dira);
  return $ref->Path($dirb);
  }
1;

__END__

=head1 NAME

File::RelDir - Perl module that returns relative path between two directories

=head1 SYNOPSIS

   use File::RelDir;

   $ref=File::RelDir->New("/tmp/here");

   $relative_path = $ref->Path("/tmp/there");

   #returns "../there"

   $ref=File::RelDir->New('d:\users\me\excel');

   $relative_path = $ref->Path('d:\users\me\word');

   #returns '../word'

   $relative_path = File::RelDir->Diff('d:\users\me\excel',  e:\users\me\word');

   #returns undef

   $relative_path = File::RelDir->Diff('d:\users\me\excel',  d:\users\me\word');

   #returns '../word'


=head1 DESCRIPTION

The File:RelDir provides a mechanism to determine the relative path between two directory structures.  It honours case sensitivity unless one (or both) the paths compared appears to be a windows path, when it becomes case insensitive.

It returns undef when no similarity between the directories supplied is determined.

=head1 METHODS

=over 2

=item B<New(DirA)>

The B<New> method establishes a reference based on the directory name provided.

=item B<Path(DirB)>

The B<Path> method returns the relative path to the directory name supplied, or undef in the event the
two directories are not compatible.

The case of the relative path is retained (wether a windows style case insensitive directory comparison was performed). The directory seperator will be forward slash based (/), unless a backslash (\) based
directory path is provided to the B<New> call. 

=item B<Diff(DirA,DirB)>

The B<Diff> method provides a simpler method of achieving the same end for the occasional relative path, use B<New> and B<Path> if you have multiple calls on the same base directory.

=back

=head1 REQUIRED MODULES

None.

=head1 AUTHOR

Dave Roberts <droberts@cpan.org>

=head1 SUPPORT

You can send bug reports and suggestions for improvements on this module
to me at droberts@cpan.org. However, I can't promise to offer
any other support for this package.

=head1 COPYRIGHT

This module is Copyright © 2012 Dave Roberts. All rights reserved.

This script is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. This script is distributed in the
hope that it will be useful, but WITHOUT ANY WARRANTY; without even
the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE. The copyright holder of this script can not be held liable
for any general, special, incidental or consequential damages arising
out of the use of the script.

=head1 CHANGE HISTORY


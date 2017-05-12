#############################################################
# File/MkTemp.pm. Written in 1999|2000 by Travis Gummels.
# If you find problems with this please let me know.
# travis@gummels.com
#############################################################

package File::MkTemp;

require Exporter;

use strict;

use vars qw($VERSION @ISA @EXPORT);

use FileHandle;
use File::Spec;
use Carp;

@ISA=qw(Exporter);
@EXPORT=qw(mktemp mkstemp mkstempt);

$VERSION = '1.0.6';

sub mkstempt {
   my ($template,$openup,$fh);
   my @retval;

   croak("Usage: mkstempt('templateXXXXXX','dir',['ext']) ")
      unless(@_ == 2 || @_ == 3);

   $template = mktemp(@_);

   $openup = File::Spec->catfile($_[1], $template);

   $fh = new FileHandle ">$openup";  #and say ahhh.

   croak("Could not open file: $openup")
      unless(defined $fh);

   @retval = ($fh,$template);

   return(@retval);
}

sub mkstemp {
   my ($template,$openup,$fh);

   croak("Usage: mkstemp('templateXXXXXX','dir',['ext']) ")
      unless(@_ == 2 || @_ == 3);

   $template = mktemp(@_);

   $openup = File::Spec->catfile($_[1], $template);

   $fh = new FileHandle ">$openup";  #and say ahhh.

   croak("Could not open file: $openup")
      unless(defined $fh);

   return($fh);
}

sub mktemp {
   my ($template,$dir,$ext,$keepgen,$lookup);
   my (@template,@letters);

   croak("Usage: mktemp('templateXXXXXX',['/dir'],['ext']) ") 
     unless(@_ == 1 || @_ == 2 || @_ == 3);

   ($template,$dir,$ext) = @_;
   @template = split //, $template;

   croak("The template must end with at least 6 uppercase letter X")
      if (substr($template, -6, 6) ne 'XXXXXX');

   if ($dir){
      croak("The directory in which you wish to test for duplicates, $dir, does not exist") unless (-e $dir);
   }

   @letters = split(//,"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ");

   $keepgen = 1;

   while ($keepgen){
      for (my $i = $#template; $i >= 0 && ($template[$i] eq 'X'); $i--){
         $template[$i] = $letters[int(rand 52)];
      }

      undef $template;

      $template = pack "a" x @template, @template;

      $template = $template . $ext if ($ext);

         if ($dir){
            $lookup = File::Spec->catfile($dir, $template);
            $keepgen = 0 unless (-e $lookup);
         }else{
            $keepgen = 0;
         }

   next if $keepgen == 0;
   }

   return($template);
}
1;

__END__

=head1 NAME

File::MkTemp - Make temporary filename from template

=head1 SYNOPSIS

  use File::MkTemp;

  mktemp(tempXXXXXX,[dir]);

  $string = mktemp(tempXXXXXX,[dir]);
  open(F,$string);

	
  mkstemp(tempXXXXXX,dir);

  $fh = mkstemp(tempXXXXXX,dir);
  print $fh "stuff";
  $fh->close;


  mkstempt(tempXXXXXX,dir);

  ($fh,$template) = mkstempt(tempXXXXXX,dir);
  print $fh "stuff";
  $fh->close;
  print "Template is: $template\n";

=head1 DESCRIPTION

The MkTemp module provides three functions mktemp() mkstemp() and mkstempt().

The function mktemp() returns a unique string based upon the template.  The
template must contain at least six trailing Xs.  The Xs are replaced by a
unique string and the template is returned.  The unique string is made from
picking random elements out of a 52 alpha character array ([a-z][A-Z]).
A directory can be specified in which to test for duplicates of the string.

The function mkstemp() does the same as mktemp() except it returns an open
file handle.  This prevents any possibility of opening up an identical file.
The function requires that the directory be specified.

The function mkstempt() does the same as mkstemp() except it returns the name
of the template in addition to the file handle.  

=head1 AUTHOR

File::MkTemp was written by Travis Gummels.
Please send bug reports and or comments to: travis@gummels.com

=head1 COPYRIGHT

Copyright 1999|2000 Travis Gummels.  All rights reserved.  This may be 
used and modified however you want.  If you redistribute after making 
modifications please note modifications you made somewhere in the
distribution and notify the author.

=cut

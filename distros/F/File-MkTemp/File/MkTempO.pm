#############################################################
# File/MkTempO.pm. Written in 1999|2000 by Travis Gummels.
# If you find problems with this please let me know.
# travis@gummels.com
#############################################################

package File::MkTempO;

use vars qw($VERSION);

use FileHandle;
use File::Spec;
use Carp;
use strict;

$File::MkTemp::VERSION = '1.0.6';

sub new {
  my $pkg = shift;

  croak("Usage: \$var = new File::MkTempO('templateXXXXXX',['dir']) ")
    unless(@_ == 1 || @_ == 2);

  croak("The template must end with at least 6 uppercase letter X")
    if (substr($_[0], -6, 6) ne 'XXXXXX');

  my $me = bless {}, $pkg;
  $me->{'template'} = $_[0];
  $me->{'dir'} = $_[1] if @_ == 2;
  $me;
}

sub mktemp {
   my $me = shift;
   my ($template,$dir,$keepgen,$lookup);
   my (@template,@letters);

   $template = $me->{'template'};
   $dir = $me->{'dir'};

   @template = split //, $template;

   if ($dir){
      croak("The directory in which you wish to test for duplicates, $dir, does not exist") unless (-e $dir);
   }

   @letters = split(//,"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ");

   $keepgen = 1;

   while ($keepgen){

      for (my $i = $#template; $i >= 0 && ($template[$i] eq 'X'); $i--){
         $template[$i] = $letters[int(rand 52)];
      }

      $template = pack "a" x @template, @template;

         if ($me->{'dir'}){
            $lookup = File::Spec->catfile($dir, $template);
            $keepgen = 0 unless (-e $lookup);
         }else{
            $keepgen = 0;
         }

   next if $keepgen == 0;

   }

   return($template);
}

sub mkstemp {

   my $me = shift;

   my $dir = $me->{'dir'};

   croak("You must specify a directory when creating the object in order to use mkstemp")
      unless $dir;

   my $template = $me->mktemp;

   my $openup = File::Spec->catfile($dir, $template);

   my $fh = new FileHandle ">$openup";  #and say ahhh.

   croak("Could not open file: $openup")
      unless(defined $fh);

   $me->{'fhtmpl'} = $template;
   $me->{'fhdirtmpl'} = $openup;

   return($fh);
}

sub template	{ my $me=shift; return $me->{'template'}; }
sub dir		{ my $me=shift; return $me->{'dir'}; }
sub fhtmpl	{ my $me=shift; return $me->{'fhtmpl'}; }
sub fhdirtmpl	{ my $me=shift; return $me->{'fhdirtmpl'}; }

1;

__END__

=head1 NAME

File::MkTempO - Make temporary filename from template

=head1 SYNOPSIS

  use File::MkTempO;

  $object = new File::MkTempO('tempXXXXXX','dir');

  $string = $object->mktemp;
  open(F,$string);
  close(<F>);


  $fh = $object->mkstemp;
  print $fh "stuff";
  $fh->close;

  print "template stored in the object: $object->template\n";
  print "directory stored in the object: $object->dir\n";
  print "file handle in scalar form: $object->fhtmpl\n";
  print "fh and the directory in scalar form: $object->fhdirtmpl\n";

=head1 DESCRIPTION

The MkTempO module provides the following functions:

  new()      - for creation of the object.
  mktemp()   - for creation of a unique string based on the template
  mkstemp()  - for creation of a unique file handle opened in the 
               directory specified during creation of the object.
  template() - for returning the template stored in the object.
  dir()      - for returning the directory stored in the object.
  fhtmpl()   - for returning the file handle in scalar form.
  fhdirtmpl()- for returning the file handle and the directory its in.

The function mktemp() returns a unique string based upon the template.  The
template must contain at least six trailing Xs.  The Xs are replaced by a
unique string and the template is returned.  The unique string is made from
picking random elements out of a 52 alpha character array ([a-z][A-Z]).
A directory can be specified in which to test for duplicates of the string.

The function mkstemp() does the same as mktemp() except it returns an open
file handle.  This prevents any possibility of opening up an identical file.
The function requires that the directory be specified when creating the
object with the new function.

=head1 AUTHOR

File::MkTemp was written by Travis Gummels.
Please send bug reports and or comments to: travis@gummels.com

=head1 COPYRIGHT

Copyright 1999|2000 Travis Gummels.  All rights reserved.  This may be 
used and modified however you want.  If you redistribute after making 
modifications please note modifications you made somewhere in the
distribution.

=cut

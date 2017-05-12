package File::Trash;
use strict;
use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS @ISA $DEBUG $ABS_TRASH $ABS_BACKUP $errstr);
use Exporter;
use Carp;
use File::Path;
use File::Copy;
$VERSION = sprintf "%d.%02d", q$Revision: 1.10 $ =~ /(\d+)/g;
@ISA = qw/Exporter/;
@EXPORT_OK = qw(trash backup restore);
%EXPORT_TAGS = ( all => \@EXPORT_OK );
$ABS_TRASH = '/tmp/trash';
$ABS_BACKUP = '/tmp/backup';


sub trash {
   @_ 
      or Carp::cluck("no arguments provided") 
      and return;

   my $count = scalar @_;
   $count 
      or Carp::cluck("no arguments provided") 
      and return;

   
   if ( $count == 1 ){
      return _backup($_[0], 1);
   }


   my $_count = 0;
   for (@_){
      _backup($_, 1) and $_count++; 
   }

   $_count == $count 
      or $errstr = "Deleted $_count/$count files.";
   $_count;
}

sub restore {
   @_ 
      or Carp::cluck("no arguments provided") 
      and return;

   my $count = scalar @_;
   $count 
      or Carp::cluck("no arguments provided")
      and return;

   
   if ( $count == 1 ){
      return _restore($_[0]);
   }

   my $_count = 0;
   for (@_){
      _restore($_) and $_count++; 
   }

   $_count == $count 
      or $errstr = "Restored $_count/$count files.";
   $_count;
}


sub backup {
   @_ 
      or Carp::cluck("no arguments provided") 
      and return;
   my $count = scalar @_;
   $count 
      or Carp::cluck("no arguments provided") 
      and return;

   if ( $count == 1 ){
      return _backup($_[0]);
   }

   my $_count = 0;
   for (@_){
      _backup($_) and $_count++;
   }

   $_count == $count 
      or Carp::cluck("Backed up $_count/$count files.");
   $_count;
}


sub _backup {   
   my $abs_path = Cwd::abs_path($_[0]) 
         or Carp::cluck("Can't resolve with Cwd::abs_path : '$_[0]'")
         and return;

   -f $abs_path
         or Carp::cluck("Not a file on disk : '$abs_path'")
         and return;

   my $is_trash = $_[1]; # if true, we delete original after, and we use abs trash instead


   my $abs_to = $is_trash ? "$ABS_TRASH$abs_path" : "$ABS_BACKUP$abs_path";

   $abs_to =~/^(\/.+)\/[^\/]+$/ 
      or confess("Error with '$abs_to' matching into");
   _abs_dir_assure($1);

   my $backnum;
   no warnings;
   while( -e $abs_to ){
      $abs_to=~s/\.\d+$//;
      $abs_to.='.'.$backnum++;
   }

   
   if( $is_trash ){
      File::Copy::move($abs_path, $abs_to)
         or confess("can't move '$abs_path' to '$abs_to', $!");
      $DEBUG and warn("moved '$abs_path' to '$abs_to'");
   }
   else {

      File::Copy::copy($abs_path, $abs_to) 
         or confess("can't copy '$abs_path' to '$abs_to', $!");

      $DEBUG and warn("copied '$abs_path' to '$abs_to'");
   }

   $abs_to;
}

sub _restore {
   my $abs_path = Cwd::abs_path($_[0]) 
         or warn($errstr = "Can't resolve with Cwd::abs_path : '$_[0]'")
         and return;
      -f $abs_path
         or warn($errstr = "Not a file on disk : '$abs_path'")
         and return;

   my $abs_to = $abs_path;
   $abs_to=~s/$ABS_TRASH//
      or warn($errstr = "$abs_path not in $ABS_TRASH?")
      and return;

   # TAKE OUT .\d version !! 
   if ($abs_to=~/.+\.\d{1,10}$/){   
      $abs_to=~s/\.\d+$//;
   }

   -e $abs_to 
      and warn($errstr = "Restore to already exists: $abs_to, cannot restore.")
      and return;

   unless( $abs_to =~/^(\/.+)\/[^\/]+$/ ){
      warn("Error with '$abs_to' matching into, getting abs loc");
      return;
   }
   
      
   _abs_dir_assure($1);
  

   File::Copy::move($abs_path, $abs_to) 
      or warn( $errstr = "cant File::Copy::move($abs_path, $abs_to) , $!" )
      and return;

   $DEBUG and warn("moved '$abs_path' to '$abs_to'");
   $abs_to;
}
   



sub _abs_dir_assure {
   -d $_[0] or File::Path::mkpath($_[0]) # throws croak on system error
      or die("cant File::Path::mkpath $_[0], $!"); # just in case
   1;
}








1;

__END__

=pod

=head1 NAME

File::Trash - move files to trash and restore as well

=head1 SYNOPSIS

   use File::Trash qw/trash restore/;

   my $trashed_path = trash('~/this_is_boring.txt');
   # returns '/tmp/trash/home/username/this_is_boring.txt'
   
   restore($trashed_path) 
      or die($File::Trash::errstr);
   

   my $abs_trash = $File::Trash::ABS_TRASH;
   # returns '/tmp/trash' by default

   my $trash_count = trash('~/this_is_boring.txt', '~/this_is_boring_2.txt');
   # returns '2'

=head1 DESCRIPTION

File::Remove apparently does something similar. 
I don't see example for using File::Remove in a simple manner alike unlink().
Thus, here it is. 

=head2 The default abs trash dir

The default dir for trash has been chosen as /tmp/trash.
The other common sense place would be $ENV{HOME}/.trash, so, why not?
What if you are calling this from some script running under a used who does not have ~, like, maybe cron
or maybe from some cgi? This is safer.
If you want, you can set the dir to be something else..

   $File::Trash::ABS_TRASH = $ENV{HOME}/.trash

This is the same for default abs backup dir.


=head1 API

No subs are exported by default.

=head2 trash()

Ideally this should behave as unlink(). It does not at present.

Argument is a list of paths to files to delete.
If more than one file is provided, returns number of files deleted.
If one file is provided only, returns abs path to where the file moved.
Returns undef in failure, check errors in $File::Trash::errstr.

If the trash destination exists, the file is appended with a dot digit number.
So, this really makes sure you don't lose junk.

=head2 backup()

Same as trash(), but does not move the file, copies it instead.

=head2 restore()

Argument is abs path to file in trash.
Attempts to move back to where it was originally.
If the restore to destination exists, will not do it and return false.
If you provide one argument, returns destination it restored.
If you provide an array, returns number of files restored.

   restore('/home/myself/.trash/hi.txt') 
      or die($File::Trash::errstr);


=head2 $File::Trash::ABS_TRASH

Default is /tmp/trash

=head2 $File::Trash::ABS_BACKUP

Default is /tmp/backup

=head2 $File::Trash::DEBUG

Set to true to see some debug info.

=head2 $File::Trash::errstr

May hold error string.

=head1 CAVEATS

In development. Works great as far as I know.
This is mean to be POSIX compliant only. That means no windoze support is provided.
If you have suggestions, please forward to AUTHOR.

=head1 SEE ALSO

L<File::Remove>

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=head1 LICENSE

This package is free software; you can redistribute it and/or modify it under the same terms as Perl itself, i.e., under the terms of the "Artistic License" or the "GNU General Public License".

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.

=cut


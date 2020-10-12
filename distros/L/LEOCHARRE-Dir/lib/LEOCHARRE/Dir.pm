package LEOCHARRE::Dir;
use Carp;
use Cwd;
use strict;
use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT_OK);
use Exporter;
@ISA = qw/Exporter/;
@EXPORT_OK = qw(reqdir ls lsa lsf lsfa lsd lsda lsr lsfr lsdr);
%EXPORT_TAGS = ( all => \@EXPORT_OK );
$VERSION = '1.09';

BEGIN { 
   croak("Not meant to run in windows or cygwin environments.") 
      if $^O=~/cygwin|MSWin32/;
}



*reqdir = \&__require_dir;
*ls     = \&__ls;
*lsa    = \&__lsa;
*lsf    = \&__lsf;
*lsfa   = \&__lsfa;
*lsd    = \&__lsd;
*lsda   = \&__lsda;
*lsr    = \&__lsr;
*lsfr   = \&__lsfr;
*lsdr   = \&__lsdr;


sub __require_dir {
   my $arg = $_[0];
   $arg or croak("Missing argument");
   my $resolved_path = Cwd::abs_path($arg)
      or croak("Cwd::abs_path() not returning for '$arg'");
   unless ( -d $resolved_path ){
      unless( mkdir $resolved_path ){
         warn("cant mkdir '$resolved_path'");
         return undef;
      }
   }
   return $resolved_path;
   
   #my $_d = Cwd::abs_path($_[0]) or croak("Bad or missing argument '@_'.");
   #-d $_d or mkdir $_d or warn("cant mkdir $_d") and return;
   #return $_d;
}

sub __ls {
   $_[0] or croak("Bad or missing argument.");
   opendir(DIR, $_[0]) or die("Cant open dir '$_[0]', $!");
   my @ls = grep { !/^\.+$/ } readdir DIR;
   closedir DIR;
   return @ls;
}
sub __lsa {
   $_[0] or croak("Bad or missing argument");
   my $abs = Cwd::abs_path($_[0]) or die("Can't resolve abs path to '@_'");
   my @ls = map { "$abs/$_" } __ls($abs);
   return @ls;
}


# no leading path
sub __lsf  { return ( grep { -f "$_[0]/$_" }       __ls(   $_[0]) ) }
sub __lsd  { return ( grep { -d "$_[0]/$_" }       __ls(   $_[0]) ) }
#*__lsd = \&__lsreaddir; this is stupidly broken

# absolute path
sub __lsfa { return ( grep   -f,                   __lsa(  $_[0]) ) } 
sub __lsda { return ( grep   -d,                   __lsa(  $_[0]) ) }

# relative path to docroot
sub __lsr  { return ( map { __rel2docroot($_) }    __lsa(  $_[0]) ) }
sub __lsfr { return ( map { __rel2docroot($_) }    __lsfa( $_[0]) ) }
sub __lsdr { return ( map { __rel2docroot($_) }    __lsda( $_[0]) ) }

sub __rel2docroot {
   $ENV{DOCUMENT_ROOT} or die("ENV DOCUMENT ROOT not set");
   
   my $p = shift;
   $p or die('missing argument');

   $p=~s/^$ENV{DOCUMENT_ROOT}// or return;
   return $p;
}

1;

# see .pod


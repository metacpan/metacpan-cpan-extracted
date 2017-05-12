
# $Id: Remote.pm,v 1.17 2005/01/10 21:47:52 nwiger Exp $
####################################################################
#
# Copyright (c) 1998-2003 Nathan Wiger <nate@sun.com>
#
# This module takes care of dealing with files regardless of whether
# they're local or remote. It allows you to create and edit files
# without having to worry about their physical location. If a file
# passed in is of the form 'host:/path/to/file', then it uses rsh/rcp
# or ssh/scp (depending on how you configure it) calls to edit the file
# remotely. Otherwise, it edits the file locally.
#
# It is my intent to provide a full set of File::Remote routines that
# mirror the standard file routines. If anybody notices any that are
# missing or even has some suggestions for useful ones, I'm all ears.
#
# For full documentation, use "perldoc Remote.pm" or "man File::Remote"
#
# This module is free software; you may copy this under the terms of
# the GNU General Public License, or the Artistic License, copies of
# which should have accompanied your Perl kit.
#
####################################################################

#=========================== Setup =================================

# Basic module setup
require 5.005;
package File::Remote;

use strict;
use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS $VERSION
            %RW_HANDLES %RO_HANDLES %RW_TMPFILES %RO_TMPFILES);
use Exporter;
@ISA = qw(Exporter);

@EXPORT_OK   = qw(
   rreadfile rwritefile rmkdir rrmdir rrm runlink rcp rcopy rtouch rchown
   rchmod rmove rmv rbackup setrsh setrcp settmp ropen rclose rappend rprepend
   rsymlink rlink readfile writefile mkdir rmdir rm unlink cp copy touch chown
   chmod move mv backup open close append prepend symlink link readlink rreadlink
);

%EXPORT_TAGS = (
   files  => [qw(ropen rclose rreadfile rwritefile runlink rcopy rtouch rmove
		 rbackup rappend rprepend rlink rsymlink rreadlink)],
   config => [qw(setrsh setrcp settmp)],
   dirs   => [qw(rmkdir rrmdir)],
   perms  => [qw(rchown rchmod)],
   standard => [qw(ropen rclose rreadfile rwritefile runlink rcopy rtouch rmove
                   rbackup rappend rprepend setrsh setrcp settmp rmkdir rrmdir
                   rchown rchmod rsymlink rlink rreadlink)],
   aliases => [qw(rrm rmv rcp)],
   replace => [qw(open close readfile writefile unlink rm copy cp touch move mv
                  backup append prepend setrsh setrcp settmp mkdir rmdir chown chmod
		  symlink link readlink)]
);

# Straight from CPAN
$VERSION = do { my @r=(q$Revision: 1.17 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r }; 

# Errors
use Carp;

# Need the basic File classes to make it work
use File::Copy qw(!copy !move);		# prevent namespace clashes
use File::Path;

# For determining remote or local file
use Sys::Hostname;

#======================== Configuration ==========================

# Defaults
my @OPT = (
   rsh => "/usr/bin/rsh",
   rcp => "/usr/bin/rcp",
   tmp => "/tmp"
);

# This determines whether or not we should spend some time trying
# to see if rsh and rcp are set to valid values before using them.
# By default these checks are not done because they're SLOW...
# Note that if you enable these then you must use absolute paths
# when calling setrsh and setrcp; "setrsh('ssh')" will fail.
my $CHECK_RSH_IS_VALID = 0;
my $CHECK_RCP_IS_VALID = 0;

# This is whether or not to spend the extra cycles (and network
# latency) checking whether a remote file is actually writeable
# when we try to open it with > or >>. Note: Unsetting this can
# result in strange and unpredictable behavior, messing with it
# is NOT recommended.
my $CHECK_REMOTE_FILES = 1;

#======================== Misc. Settings =========================

# This is the default class for the File::Remote object (from CGI.pm!)
my $DefaultClass ||= 'File::Remote';
my $DefaultClassObject;   # holds an object later on

# This should not need to be overridden
(my $hostname = hostname()) =~ s/\..*//;

# Need to check our OS. As of this release, only UNIX is supported;
# perhaps this will change in the future, but probably not.
# Don't check $^O because we'd have to write an exhaustive function.
die "Sorry, File::Remote only supports UNIX systems\n" unless (-d "/");

#========================== Functions ============================

# Simple debugging function
my $DEBUG = 0;
sub _debug { warn "debug: ", @_ if $DEBUG };

#------------------------------------------------
# "Constructor" function to handle defaults
#------------------------------------------------

#######
# Usage: $remote = new File::Remote;
#
# This constructs a new File::Remote object
#######

sub new {
   # Easy mostly-std new()
   my $self = shift;
   my $class = ref($self) || $self || $DefaultClass;

   # Add any options to our own defaults
   my %opt = (@OPT, @_);
   return bless \%opt, $class;
}

#------------------------------------------------
# Private Functions (for public see "/__DATA__")
#------------------------------------------------

#######
# Usage: my($self, @args) = _self_or_default(@_);
#
# This is completely stolen from the amazing CGI.pm. I did 
# not write this!! Thanks, Lincoln Stein! :-)
#######

sub _self_or_default {

   return @_ if defined($_[0]) && (!ref($_[0])) && ($_[0] eq 'File::Remote');
   unless (defined($_[0]) && (ref($_[0]) eq 'File::Remote'
			  || UNIVERSAL::isa($_[0],'File::Remote'))) {
      $DefaultClassObject = $DefaultClass->new unless defined($DefaultClassObject);
      unshift(@_, $DefaultClassObject);
   }
   return @_;
}

#######
# Usage: $tmpfile = $remote->_tmpfile($file);
#
# This sets a unique temp file for each $self/$file combo,
# which is used during remote rsh/rcp calls
#######

sub _tmpfile {

   my($self, $file) = _self_or_default(@_);
   $file =~ tr#[:/]#_#;		# "fix" filename
   my($tmpdir, $tmpfile);
   $tmpdir = $self->settmp;

   # Have a little loop so that we don't collide w/ other File::Remote's
   my $num = $$;
   do {
      $tmpfile = "$tmpdir/.rfile.$file.$num";
      $num++;
   } while (-f $tmpfile);
   return $tmpfile;
}

#######
# Usage: $remote->_system(@cmd) or return undef;
#
# Front-end for built-in firing off system commands to twiddle
# return vals. Here, we don't actually use system() because we
# need the appropriate return value so that $! makes sense.
#######

sub _system {
   my($self, @cmd) = _self_or_default(@_);

   # return "Broken pipe" if cmd invalid
   chomp(my $return = `@cmd 2>&1 1>/dev/null || echo 32`);
   _debug("_system(@cmd) = $return");

   if ($return) {
      # if echo'ed an int (internal tests), use it, else use "Permission denied" (13)
      $return =~ m/^(\d+)$/;
      $! = $1 || 13;
      return undef;
   }
   return 1;
}

####### 
# Usage: my($host, $file) = _parsepath($path);
#
# This is used to parse the $path param to look for host:/file
# This always returns an array, the deal is that if the file
# is remote, you get a host (arg1). Otherwise, it's undef.
#
# Thanks to David Robins and Rob Mah for their fixes to this sub.
#######

sub _parsepath {

   my($self, $file) = _self_or_default(@_);
   my($rhost, $rfile) = split ':', $file, 2;

   return(undef, $rhost) unless $rfile;    # return the file if no colon (faster)
   if ($hostname =~ /^$rhost(\.|$)/ && $rfile =~ /^\//) {
      return(undef, $rfile); # file is actually local
   }
   return($rhost, $rfile); # file is remote after all
}
 
#######
# Usage: $fh = _to_filehandle($thingy);
#
# This is so we can pass in a filehandle or typeglob to open(),
# and close(). This is my own bastardization of Perl's symbol
# tables, so if it be broke, let me know.
#######

sub _to_filehandle {

   my($self, $thingy) = _self_or_default(@_);
   return undef unless $thingy;

   #warn "to_fh($thingy)";

   # This is the majority - bareword filehandles
   unless (ref $thingy) {
      no strict 'refs';
      return \*$thingy if $thingy =~ /^\*/;	# glob like '*main::FILE'
      local *globby = join '::', caller(1) || 'main', $thingy;
      return *globby;
   }

   # Check for globrefs and FileHandle objects
   return $thingy if UNIVERSAL::isa($thingy,'GLOB')
		  || UNIVERSAL::isa($thingy,'FileHandle');

   return undef;
}

#------------------------------------------------
# Public functions - all are exportable
#------------------------------------------------

# Everything down here should be SelfLoaded
# Can't use the SelfLoader because of conflicts with CORE::open
#__DATA__

#######
# Usage: $remote->setXXX($value);
#
# These three functions are for setting necessary variables.
# All of them do sanity checks which will be called both when
# a variable is assigned as well as retrieved. This prevents
# "mass badness". If not value is passed, the current setting
# is returned (good for checking).
#######

sub setrsh {
   # Sets the variable $self->{rsh}, which is what to use for rsh calls
   my($self, $value) = _self_or_default(@_);
   $self->{rsh} = $value if $value;

   # This check was removed because of relative paths/speed.
   if ($CHECK_RSH_IS_VALID) {
      croak "setrsh() set to non-executable file '$self->{rsh}'"
         unless (-x $self->{rsh});
   }

   return $self->{rsh};
}
   
sub setrcp {
   # Sets the variable $self->{rcp}, which is what to use for rcp calls
   my($self, $value) = _self_or_default(@_);
   $self->{rcp} = $value if $value;

   # This check was removed because of relative paths/speed.
   if ($CHECK_RCP_IS_VALID) {
      croak "setrcp() set to non-executable file '$self->{rcp}'"
         unless (-x $self->{rcp});
   }

   return $self->{rcp};
}

sub settmp {
   # Sets the variable $self->{tmp}, which refs the temp dir needed to
   # hold temporary files during rsh/rcp calls
   my($self, $value) = _self_or_default(@_);
   $self->{tmp} = $value if $value;
   croak "settmp() set to non-existent dir '$self->{tmp}'"
      unless (-d $self->{tmp});
   return $self->{tmp};
}


#######
# Usage: $remote->open(FILEHANDLE, $file);
#
# opens file onto FILEHANDLE (or typeglob) just like CORE::open()
#
# There's one extra step here, and that's creating a hash that
# lists the open filehandles and their corresponding filenames.
# If anyone knows a better way to do this, LET ME KNOW! This is
# a major kludge, but is needed in order to copy back the changes
# made to remote files via persistent filehandles.
#######

*ropen = \&open;
sub open {

   my($self, $handle, $file) = _self_or_default(@_);
   croak "Bad usage of open(HANDLE, file)" unless ($handle && $file);

   # Private vars
   my($f, $fh, $tmpfile);

   # Before parsing path, need to check for <, >, etc
   $file =~ m/^([\<\>\|\+]*)\s*(.*)/;
   $file = $2;
   my $method = $1 || '<';

   croak "Unsupported file method '$method'" unless ($method =~ m/^\+?[\<\>\|]{1,2}$/);
   my($rhost, $lfile) = _parsepath($file);

   # Catch for remote pipes
   if (($method =~ m/\|/) && $rhost) {
      croak "Sorry, File::Remote does not support writing to remote pipes" 
   }

   # Setup filehandle
   $fh = _to_filehandle($handle) or return undef;;

   # Check if it's open already - if so, close it first like native Perl
   if($RW_HANDLES{$fh} || $RW_HANDLES{$fh}) {
      $self->close($handle) or return undef;
   }

   # Check for local or remote files
   if($rhost) {
      $tmpfile = $self->_tmpfile($file);
      $f = $tmpfile;

      # XXX Add this filehandle to our hash - this is a big kludge,
      # XXX if there's something I'm missing please let me know!!!
      # XXX This is so that on close(), the file can be copied back
      # XXX over to the source to overwrite whatever's there.
      # XXX Because of the performance hit, only add it if it's rw.
      if ($method =~ m/\>/) {

         # First check to see if the remote file is writeable,
         # but only if the variable $CHECK_REMOTE_FILES is on.
         # Do our checks thru test calls that echo $! codes if
         # they fail...

         if($CHECK_REMOTE_FILES) {
            my $dir;
            ($dir = $lfile) =~ s@(.*)/.*@$1@;
            $self->_system($self->setrsh, $rhost,
		"'if test -f $lfile; then
			test -w $lfile || echo 13 >&2;
		  else
			test -d $dir || echo 2 >&2;
		  fi'") or return undef;
         }

         $RW_HANDLES{$fh} = $file;
         $RW_TMPFILES{$file} = $tmpfile;
      } else {
         # push tmpfile onto an array
         $RO_HANDLES{$fh} = $file;
         $RO_TMPFILES{$file} = $tmpfile;
      }

      # If we escaped that mess, copy our file over locally
      # For open(), ignore failed copies b/c the file might be new
      $self->copy($file, $tmpfile);

   } else {
      $f = $lfile;
   }

   # All we do is pass it straight thru to open()
   local *fh = $fh;
   CORE::open(*fh, "$method $f") or return undef;
   return 1;
}

#######
# Usage: $remote->open(FILEHANDLE, $file);
#
# closes FILEHANDLE and flushes buffer just like CORE::close()
#######

*rclose = \&close;
sub close {

   my($self, $handle) = _self_or_default(@_);
   croak "Bad usage of close(HANDLE)" unless ($handle);
 
   # Setup filehandle and close
   my $fh = _to_filehandle($handle) or return undef;
   local *fh = $fh;
   CORE::close($fh) or return undef;

   # See if it's a writable remote handle
   if(my $file = delete $RW_HANDLES{$fh}) {

      # If it's a remote file, we have extra stuff todo. Basically,
      # we need to copy the local tmpfile over to the remote host
      # which has the equivalent effect of flushing buffers for
      # local files (as far as the user can tell).

      my($rhost, $lfile) = _parsepath($file);	
      if($rhost) {
         my $tmpfile = delete $RW_TMPFILES{$file};
         $self->copy($tmpfile, $file) or return undef;
         CORE::unlink($tmpfile);
      }
   } else {
      my $tmpfile = delete $RO_HANDLES{$fh};
      delete $RO_TMPFILES{$tmpfile} if $tmpfile;
   }
   return 1;
}

# This is a special method to close all open rw remote filehandles on exit
END {
   for my $fh (keys %RW_HANDLES) {
      carp "$fh remote filehandle left open, use close()" if ($^W);
      &close($fh);	# ignore errors, programmer should use close()
   }
   for my $tmpfile (values %RW_TMPFILES) {
      CORE::unlink($tmpfile);
   }
   for my $fh (keys %RO_HANDLES) {
      &close($fh);
   }
   for my $tmpfile (values %RO_TMPFILES) {
      CORE::unlink($tmpfile);
   }
}

#######
# Usage: $remote->touch($file);
#
# "touches" a file (creates an empty one or updates mod time)
#######

*rtouch = \&touch;
sub touch {
   my($self, $file) = _self_or_default(@_);
   croak "Bad usage of touch" unless ($file);
   my($rhost, $lfile) = _parsepath($file);
   if($rhost) {
      $self->_system($self->setrsh, $rhost, "touch $lfile") or return undef;
   } else {
      local *F;
      CORE::open(F, ">>$lfile") or return undef;
   }
   return 1;
}


#######
# Usage: @file = $remote->readfile($file);
#
# This reads an entire file and returns it as an array. In a
# scalar context the number of lines will be returned.
#######

*rreadfile = \&readfile;
sub readfile {

   my($self, $file) = _self_or_default(@_);
   croak "Bad usage of readfile" unless ($file);
   my($rhost, $lfile) = _parsepath($file);

   # Private vars
   my($f, $fh, $tmpfile);

   # Check for local or remote files
   if($rhost) {
      $tmpfile = $self->_tmpfile($file);
      $self->copy($file, $tmpfile) or return undef;
      $f = $tmpfile;
   } else {
      $f = $lfile;
   }

   # These routines borrowed heavily from File::Slurp
   local(*F);
   CORE::open(F, "<$f") or return undef;
   my @r = <F>;
   CORE::close(F) or return undef;

   # Remove the local copy if it exists.
   # Thanks to Neville Jennings for catching this.
   CORE::unlink($tmpfile) if $tmpfile;

   return @r if wantarray;
   return join("", @r);
}

#######
# Usage: $remote->writefile($file, @file);
#
# This writes an entire file using the array passed in as
# the second arg. It overwrites any existing file of the
# same name. To back it up first, use backup().
#######

*rwritefile = \&writefile;
sub writefile {

   my($self, $file, @data) = _self_or_default(@_);
   croak "Bad usage of writefile" unless ($file);
   my($rhost, $lfile) = _parsepath($file);

   # Private vars
   my($f, $fh, $tmpfile);

   # Check for local or remote files
   if($rhost) {
      $tmpfile = $self->_tmpfile($file);
      $f = $tmpfile;
   } else {
      $f = $lfile;
   }
   
   # These routines borrowed heavily from File::Slurp
   local(*F);
   CORE::open(F, ">$f") or return undef;
   print F @data or return undef;
   CORE::close(F) or return undef;
 
   # Need to copy the file back over
   if($rhost) {
      if(-f $tmpfile) {
         $self->copy($tmpfile, $file) or return undef;
         CORE::unlink($tmpfile);  
      } else {
         carp "File::Remote Internal Error: Attempted to write to $file but $tmpfile missing!";
         return undef;
      }
   }

   return 1;
}

#######
# Usage: $remote->mkdir($dir, $mode);
#
# This creates a new dir with the specified octal mode.
#######

*rmkdir = \&mkdir;
sub mkdir {

   # Local dirs go to mkpath, remote to mkdir -p
   my($self, $dir, $mode) = _self_or_default(@_);
   croak "Bad usage of mkdir" unless ($dir);
   my($rhost, $ldir) = _parsepath($dir);
   #$mode = '0755' unless $mode;

   if($rhost) {
      $self->_system($self->setrsh, $rhost, "'mkdir -p $ldir'") or return undef;
   } else {
      mkpath(["$ldir"], 0, $mode) || return undef;
   }
   return 1;
}

#######
# Usage: $remote->rmdir($dir, $recurse);
#
# This removes the specified dir.
#######

*rrmdir = \&rmdir;
sub rmdir {

   my($self, $dir, $recurse) = _self_or_default(@_);
   croak "Bad usage of rmdir" unless ($dir);
   my($rhost, $ldir) = _parsepath($dir);
   $recurse = 1 unless defined($recurse);

   if($rhost) {
      if ($recurse) {
         $self->_system($self->setrsh, $rhost, "rm -rf $ldir") or return undef;
      } else {
         $self->_system($self->setrsh, $rhost, "rmdir $ldir") or return undef;
      }
   } else {
      if ($recurse) {
         rmtree(["$ldir"], 0, 0) or return undef;
      } else {
         rmdir $ldir or return undef;
      }
   }
   return 1;
}
 
#######
# Usage: $remote->copy($file1, $file2);
#
# This copies files around, just like UNIX cp. If one of
# the files is remote, it uses rcp. Both files cannot be
# remote.
#######

*rcp = \&copy;
*rcopy = \&copy;
*cp = \&copy;
sub copy {
   # This copies the given file, either locally or remotely
   # depending on whether or not it's remote or not.
   my($self, $srcfile, $destfile) = _self_or_default(@_);
   croak "Bad usage of copy" unless ($srcfile && $destfile);
   my($srhost, $slfile) = _parsepath($srcfile);
   my($drhost, $dlfile) = _parsepath($destfile);

   if($srhost || $drhost) {
      _debug("copy -- system($self->setrcp, $srcfile, $destfile)");
      $self->_system($self->setrcp, $srcfile, $destfile) or return undef;
   } else {
      _debug("copy -- copy($slfile, $dlfile)");
      File::Copy::copy($slfile, $dlfile) or return undef;
   }
   return 1;
}

#######
# Usage: $remote->move($file1, $file2);
#
# This moves files around, just like UNIX mv. If one of
# the files is remote, it uses rcp/rm. Both files cannot be
# remote.
#######

*rmove = \&move;
*rmv = \&move;
*mv = \&move;
sub move {

   # This does NOT fall through to a standard rename command,
   # simply because there are too many platforms on which this
   # works too differently (Solaris vs. Linux, for ex).

   (&copy(@_) && &unlink(@_)) || return undef;
   return 1;
}

#######
# Usage: $remote->chown($file1, $file2);
#
# This chown's files just like UNIX chown.
#######


*rchown = \&chown;
sub chown {

   # If remote, subshell it; else, use Perl's chown
   # Form of chown is the same as normal chown
   my($self, $uid, $gid, $file) = _self_or_default(@_);
   croak "Bad usage of chown" unless ($uid && $gid && $file);
   my($rhost, $lfile) = _parsepath($file);

   if($rhost) {
      $self->_system($self->setrsh, $rhost, "'chown $uid $lfile ; chgrp $gid $lfile'") or return undef;
   } else {
      # Check if we need to resolve stuff
      ($uid) = getpwnam($uid) if ($uid =~ /[a-zA-Z]/);
      ($gid) = getgrnam($gid) if ($gid =~ /[a-zA-Z]/);
      chown($uid, $gid, $lfile) || return undef;
   }
   return 1;
}

#######
# Usage: $remote->chmod($mode, $file);
#
# This chmod's files just like UNIX chmod.
#######

*rchmod = \&chmod;
sub chmod {

   # Same as chown, really easy
   my($self, $mode, $file) = _self_or_default(@_);
   croak "Bad usage of chmod" unless ($mode && $file);
   my($rhost, $lfile) = _parsepath($file);

   if($rhost) {
      $self->_system($self->setrsh, $rhost, "'chmod $mode $lfile'") or return undef;
   } else {
      chmod($mode, $lfile) || return undef;
   }
   return 1;
}

#######
# Usage: $remote->unlink($file);
#
# This removes files, just like UNIX rm.
#######

*rrm = \&unlink;
*rm = \&unlink;
*runlink = \&unlink;
sub unlink {

   # Really easy
   my($self, $file) = _self_or_default(@_);
   croak "Bad usage of unlink" unless ($file);
   my($rhost, $lfile) = _parsepath($file);

   if($rhost) {
      $self->_system($self->setrsh, $rhost, "'rm -f $lfile'") or return undef;
   } else {
      CORE::unlink($lfile) || return undef;
   }
   return 1;
}

#######
# Usage: $remote->link($file);
#
# This links files, just like UNIX ln.
#######

*rln = \&link;
*ln = \&link;
*rlink = \&link;
sub link {

   # This logic is similar to copy, only if a host:/path
   # is specified, that must be specified for both - we
   # can't link across servers! (obviously)
   my($self, $srcfile, $destfile) = _self_or_default(@_);
   croak "Bad usage of link" unless ($srcfile && $destfile);
   my($srhost, $slfile) = _parsepath($srcfile);
   my($drhost, $dlfile) = _parsepath($destfile);

   if($srhost && $drhost) {
      if($srhost eq $drhost) {
         $self->_system($self->setrsh, $srhost, "ln", $slfile, $dlfile) or return undef;
      } else {
         croak "Cannot link two files from different hosts!";
      }
   } elsif($srhost || $drhost) {
      croak "Cannot link two files from different hosts!";
   } else {
      CORE::link($slfile, $dlfile) or return undef;
   }
   return 1;
}

#######
# Usage: $remote->symlink($file);
#
# This symlinks files, just like UNIX ln -s.
#######

*rsymlink = \&symlink;
sub symlink {

   # This logic is similar to copy, only if a host:/path
   # is specified, that must be specified for both - we
   # can't link across servers! (obviously)
   my($self, $srcfile, $destfile) = _self_or_default(@_);
   croak "Bad usage of symlink" unless ($srcfile && $destfile);
   my($srhost, $slfile) = _parsepath($srcfile);
   my($drhost, $dlfile) = _parsepath($destfile);

   if($srhost && $drhost) {
      if($srhost eq $drhost) {
         $self->_system($self->setrsh, $srhost, "ln -s", $slfile, $dlfile) or return undef;
      } else {
         croak "Cannot symlink two files from different hosts!";
      }
   } elsif($srhost || $drhost) {
      croak "Cannot symlink two files from different hosts!";
   } else {
      CORE::symlink($slfile, $dlfile) or return undef;
   }
   return 1;
}

#######
# Usage: $remote->readlink($file);
#
# This reads what a symbolic link points to
#######

*rreadlink = \&readlink;
sub readlink {

   my($self, $file) = _self_or_default(@_);
   croak "Bad usage of readlink" unless ($file);
   my($rhost, $lfile) = _parsepath($file);

   if ($rhost) {
      # this command is a little tricky, and not guaranteed
      # to be 100% portable... note that we can't even use
      # the _system() internal function because it's so weird...
      my $rsh = $self->setrsh;
      chomp(my $path = `$rsh $rhost "ls -l $lfile | awk '{print \$NF}' || echo NOPE" 2>/dev/null`);
      if ($path eq 'NOPE') {
         $! = 2;
         return undef;
      } else {
         return $path;
      }
   } else {
      return CORE::readlink($lfile);
   }
   return undef;
}

#######
# Usage: $remote->backup($file, $suffix|$filename);
#
# Remotely backs up a file. A little tricky, but not too much.
# If the file is remote we just do a 'rcp -p'. If it's local,
# we do a cp, along with some stat checks. The cool thing about
# this function is that it takes two arguments, the second
# can be either a suffix (like '.bkup') or a full file name
# (like '/local/backups/myfile'), and the function does the
# appropriate thing. If will also accept a 'host:/dir/file'
# arg as the suffix, which means you can do this:
# 
#   rbackup('mainhost:/dir/file', 'backuphost:/dir/new/file');
#######

*rbackup = \&backup;
sub backup {

   my($self, $file, $suffix) = _self_or_default(@_);
   croak "Bad usage of backup" unless ($file);
   $suffix ||= 'bkup';

   my($rhost, $lfile) = _parsepath($file);
   my($bhost, $bfile) = _parsepath($suffix);

   # See if the thing is a suffix or filename
   $bfile = "$file.$suffix" unless ($bfile =~ m@/@); # a path name

   # All we do now if drop thru to our own copy routine
   _debug("backup() calling copy($file, $bfile)");
   $self->copy($file, $bfile) or return undef;
   return 1;
}

#######
# Usage: $remote->append($file, @file);
#
# This is just like writefile, only that it appends to the file
# rather than overwriting it.
#######

*rappend = \&append;
sub append {
   my($self, $file, @file) = _self_or_default(@_);
   croak "Bad usage of append" unless ($file);
   my @prefile = $self->readfile($file) or return undef;
   my @newfile = (@prefile, @file) or return undef;
   $self->writefile($file, @newfile) or return undef;
   return 1;
}

#######
# Usage: $remote->prepend($file, @file);
#
# This is just like writefile, only that it prepends to the file
# rather than overwriting it.
#######

*rprepend = \&prepend;
sub prepend {
   my($self, $file, @file) = _self_or_default(@_);
   croak "Bad usage of prepend" unless ($file);
   my @postfile = $self->readfile($file) or return undef;
   my @newfile = (@file, @postfile) or return undef;
   $self->writefile($file, @newfile) or return undef;
   return 1;
}

1;

#------------------------------------------------
# Documentation starts down here...
#------------------------------------------------

__END__ DATA

=head1 NAME

File::Remote - Read/write/edit remote files transparently

=head1 SYNOPSIS

   #
   # Two ways to use File::Remote
   #
   # First, the function-based style. Here, we can use the 
   # special :replace tag to overload Perl builtins!
   #
   use File::Remote qw(:replace);	# special :replace tag

   # read from a remote file
   open(REMOTE, "host:/remote/file") or die $!;
   print while (<REMOTE>);
   close(REMOTE);

   # writing a local file still works!
   open(LOCAL, ">>/local/file");
   print LOCAL "This is a new line.\n";
   close(LOCAL); 
 
   mkdir("host:/remote/dir", 0755);
   unlink("host:/remote/file");
   unlink("/local/file");		# still works too!
   symlink("host:/remote/src", "host:/remote/dest");

   chown("root", "other", "host:/remote/dir/file");
   chmod(0600, "host:/remote/dir/file");

   #  
   # Next, the object-oriented style, if you don't want to
   # mess with the builtins.
   #
   use File::Remote;
   my $remote = new File::Remote;
 
   # Standard filehandles
   $remote->open(FILE, ">>host:/remote/file") or die $!;
   print FILE "Here's a line that's added.\n";
   $remote->close(FILE);
 
   # Create a new file and change its permissions
   $remote->mkdir("host:/remote/dir");
   $remote->touch("host:/remote/dir/file");
 
   # Move files around
   $remote->copy("/local/file", "host:/remote/file") or warn $!;
   $remote->move("host:/remote/file", "/local/file");
 
   # Read and write whole files
   my @file = $remote->readfile("host:/remote/file");
   $remote->writefile("/local/file", @file);
 
   # Backup a file with a suffix
   $remote->backup("host:/remote/oldfile", "save");
 
   # Use secure connection methods
   my $secure = new File::Remote (rsh => "/usr/local/bin/ssh",
                                  rcp => "/usr/local/bin/scp");
   $secure->unlink("/local/file");
   $secure->rmdir("host:/remote/dir");

=head1 DESCRIPTION

This module takes care of dealing with files regardless of whether
they're local or remote.  It allows you to create and edit files without
having to worry about their physical location on the network.  If a file
passed into a function is of the form C<host:/path/to/file>, then
C<File::Remote> uses rsh/rcp (or ssh/scp, depending on how you configure it)
to edit the file remotely.  Otherwise, it assumes the file is local and
passes calls directly through to Perl's core functions.

The nice thing about this module is that you can use it for I<all> your
file calls, since it handles both remote and local files transparently.
This means you don't have to put a whole bunch of checks for remote files
in your code.  Plus, if you use the function-oriented interface along with
the C<:replace> tag, you can actually redefine the Perl builtin file
functions. This means that your existing Perl scripts can automatically
handle remote files with no re-engineering(!).

There are two ways to program with C<File::Remote>, an object-oriented
style and a function-oriented style.  Both methods work equally well,
it's just a matter of taste.  One advantage of the object-oriented
method is that this allows you to read and write from different servers
using different methods (eg, rsh vs. ssh) simultaneously:

   # Object-oriented method
   use File::Remote;
   my $remote = new File::Remote;
   my $secure = new File::Remote (rsh => "/bin/ssh", rcp => "/bin/scp");

   # Securely copy, write, and remove a file in one swoop...
   $remote->open(LOCAL, "/local/file") or die "Open failed: $!\n";
   $secure->open(REMOTE, "host:/remote/file") or die "Open failed: $!\n";
   print REMOTE "$_" while (<LOCAL>);

   $remote->close(LOCAL);
   $secure->close(REMOTE);

   # And let's move some files around securely
   $secure->move("/local/file", "host:/remote/file");
   $secure->copy("host:/remote/file", "/local/file");

To use the function-oriented interface, you must import the special tag
called C<:replace> which will actually replace the Perl builtin functions:

   # Replace Perl's file methods with File::Remote's
   use File::Remote qw(:replace);

   open(FILE, ">host:/remote/file") or die "Open failed: $!\n";
   print FILE "Hello, world!\n";
   close(FILE) or die "Close failed: $!\n";

   mkdir("/local/new/dir", "2775");
   mkdir("host:/remote/new/dir");
   chown("root", "other", "/local/new/dir");
   unlink("host:/remote/file");

This is pretty neat; since C<File::Remote> will pass calls to local files
straight through to Perl's core functions, you'll be able to do all this
"transparently" and not care about the locations of the files. Plus,
this has the big advantage of making your existing Perl scripts capable
of dealing with remote files without having to rewrite any code.

Because the names for the C<File::Remote> methods clash with the Perl builtins,
if you use the function-oriented style with the C<:standard> tag there is
an extra 'r' added to the front of the function names.  Thus, C<<$remote->open>>
becomes 'ropen' in the C<:standard> function-oriented version:

   # Function-oriented method
   use File::Remote qw(:standard);	# use standard function names
   setrsh("/share/bin/ssh");
   setrcp("/share/bin/scp");

   # same functionality, but there's an "r" prefix
   ropen(FILE, "host:/remote/file") or die "Open failed: $!\n";
   print while (<FILE>);
   rclose(FILE) or die "Close failed: $!\n";

   runlink("host:/remote/file");
   rmkdir("host:/remote/dir");
   rchmod("0700", "host:/remote/dir");

That's kinda nasty, though. I recommend you use the C<:replace> tag,
personally.

=head1 FUNCTIONS

Below are each of the functions you can make use of with C<File::Remote>.
Remember, for the function-oriented style, unless you use the C<:replace>
tag you'll have to add an extra 'r' to the start of each function name.
For all functions, the file arg can be either local or remote.

=head2 new(opt => val, opt => val)

This is the main constructor when you're using the object-oriented
method of calling. You only need to use this if you're using the
object-oriented calling form. You can pass it three arguments which 
change how it works:

   rsh  -  path to your rsh or ssh program
   rcp  -  path to your rcp or scp program
   tmp  -  path to your tmp directory

So, for example:

   use File::Remote;
   my $secure = File::Remote->new(rsh => '/usr/local/bin/ssh',
                                  rcp => '/usr/local/bin/scp',
                                  tmp => '/var/run');
   $secure->copy($src, $dest);

The above would setup your C<$secure> object so that calls to methods on
it would use ssh and scp for connections.

=head2 setrsh(prog) ; setrcp(prog) ; settmp(dir)

These perform the equivalent functionality to setting the above flags,
for use in the function-oriented method of calling. So, if you were to
decide you didn't want to use the OO method, but instead wanted to use
the drop-in replacement function method (which I prefer):

   use File::Remote qw(:replace);

   setrsh('/usr/local/bin/ssh'); 
   setrcp('/usr/local/bin/scp'); 
   settmp('/var/run'); 

   copy($src, $dest);

That chain of calls would have the exact same effect, only using the
function-oriented format instead of the object-oriented format.

=head2 open(HANDLE, file) ; close(HANDLE)

Used to open and close files just like the Perl builtins. These functions
accept both string filehandles and typeglob references, so any valid
Perl open calls:

   open(FILE, ">> $file");
   open(*FILE, ">$file");
   open(\*FH, "< $file");

Should work, except for the 5.6 and later:

   open(my $fh, $file);

This does not work when using C<File::Remote>. Patches to overcome this
are welcomed.

=head2 touch(file)

Updates the modification time on a file, or creates it if it doesn't exist,
just like the UNIX touch command.

=head2 mkdir(dir [, mode]) ; rmdir(dir [, recurse])

Create a dir with optional octal mode [mode]; remove a dir tree optionally
recursively. By default, rmdir works recursively, and the mode of the new
dir from mkdir depends on your umask.

=head2 copy(file1, file2)

Simply copies a file, just like File::Copy's function of the same name.
You can also address it as 'cp' (if you import the :aliases tag).

=head2 move(file1, file2)

Moves a file ala File::Copy.  You can also address it as 'mv'
(if you import the :aliases tag).

=head2 chmod(mode, file) ; chown(owner, group, file)

Change the permissions or the owner of a file.

=head2 unlink(file)

Remove a file. You can also address it as 'rm' (if you import the :aliases tag).

=head2 link(file1, file2)

Create a hard link between two files. The caveat to this function
is that both files must be local, or both files must be remote.

=head2 symlink(file1, file2)

Works just like link only creates symbolic instead of hard links.

=head2 readlink(file)

This reads what a symbolic link points to, just like the Perl builtin.

=head2 backup(file, [file|suffix])

This backs up a file, useful if you're going to be manipulating it.
If you just call it without the optional second filename or suffix,
the suffix 'bkup' will be added to the file.  Either file can be local
or remote; this is really just a front-end to copy().

=head2 readfile(file) , writefile(file, @data)

These read and write whole files in one swoop, just like File::Slurp.
readfile() returns an array of the file, and writefile just returns
success or failure.

=head2 append(file, @data) , prepend(file, @data)

Similar to writefile(), only these don't overwrite the file, these
either append or prepend the data to the file.

=head1 EXAMPLES

Here's some more examples of how to use this module:

=head2 1. Add a new user to /etc/passwd on your server

This might be useful if you've got some type of web-based newuser
program that runs on a host other than the one you have to edit
/etc/passwd on:

   # Function-oriented method
   use File::Remote qw(:replace);

   $passwd = "server:/etc/passwd";
   backup($passwd, 'old');		# back it up to be safe
   open(PASSWD, ">>$passwd") or die "Couldn't write $passwd: $!\n";
   print PASSWD "$newuser_entry\n";
   close(PASSWD);


=head2 2. Securely copy over a bunch of files

Hopefully you would use loops and variable names to make any actual code look
much cleaner...

   # Object-oriented method
   use File::Remote
   my $secure = File::Remote->new(rsh => "/share/bin/ssh",
                                  rcp => "/share/bin/scp",
                                  tmp => "/var/tmp");

   # Move files
   $secure->move("client:/home/bob/.cshrc", "client:/home/bob/.cshrc.old");
   $secure->copy("/etc/skel/cshrc.user", "client:/home/bob/.cshrc");
   $secure->copy("/etc/skel/kshrc.user", "client:/home/bob/.kshrc");
   

=head2 3. Use rsync w/ ssh for really fast transfers

Here we're assuming we're getting some huge datastream from some
other process and having to dump it into a file in realtime.
Note that the remote file won't be updated until close() is called.

   # Function-oriented, no :replace tag, so all functions
   # will be prefixed with an 'r'
   use File::Remote qw(:standard);

   setrsh("/local/bin/ssh");
   setrcp("/local/bin/rsync -z -e /local/bin/ssh");
   settmp("/my/secure_tmp"); 

   $file = "server:/local/dir/some/huge/file";
   ropen(REMOTE, ">>$file") or die "Couldn't write $file: $!\n";
   while(<DATASTREAM>) {
      print REMOTE $_;
   }
   rclose(REMOTE);		# file is finally updated

Again, I don't like the C<:standard> tag, but it's there if you want it.
The only difference between the different calling forms is syntax - the
functionality of all three is the same.

=head1 NOTES

C<File::Remote> only works on UNIX systems.

The main caveat to C<File::Remote> is that you have to have rsh/rcp or ssh/scp
access to the hosts you want to manipulate files on.  Make sure you consider
the security implications of this, especially if you live outside a firewall.

Enabling autoflush ($|) won't have any effect on remote filehandles, since
the remote file is not synched until close() is called on the filehandle.

C<File::Remote> does not support remote pipes.

Because of speed, by default no checks are made as to whether or not rsh/rcp
or their equivalents are executable. To change this, see the source.

=head1 ANNOYANCES

When using the C<:replace> tag and C<-w>, you may get warnings of the form:

   Name "main::FILE" used only once: possible typo

These result from the fact that Perl 5 uses bareword filehandles, and can
safely be ignored. If they're really annoying you, any of these solutions
will work:

   use File::Remote qw(:replace);

   { local $^W; open(FILE, $file) }	# there's more
   open(*FILE, $file);			# than one way
   open(\*FILE, $file);			# to do it

Using any of these will eliminate the warnings. If you know of a way to
make these disappear, I'd love to hear from you...

=head1 BUGS

Because of the internal implementation of open() on remote files, it 
is not possible to read from an ever-growing remote file ("tail" it).
Basically, a snapshot of the remote file is taken when you open it
for reading. Patches to overcome this limitation are welcomed.

Perl scripts that are tainted or setuid might not work with C<File::Remote>
because of its reliance on system() calls, depending on your %ENV. To
work around this, simply add an C<undef %ENV> statement to the top of
your script, which you should be doing anyways.

If you have a bug report or suggestion, please direct them to me (see below).
Please be specific and include the version of C<File::Remote> you're using.

=head1 VERSION

$Id: Remote.pm,v 1.17 2005/01/10 21:47:52 nwiger Exp $

=head1 AUTHOR

Copyright (c) 1998-2003 Nathan Wiger, Sun Microsystems <nate@sun.com>.
All Rights Reserved.

This module is free software; you may copy this under the terms of
the GNU General Public License, or the Artistic License, copies of
which should have accompanied your Perl kit.

=cut


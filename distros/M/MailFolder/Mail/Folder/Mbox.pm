# -*-perl-*-
#
# Copyright (c) 1996-1998 Kevin Johnson <kjj@pobox.com>.
#
# All rights reserved. This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.
#
# $Id: Mbox.pm,v 1.6 1998/04/05 17:21:53 kjj Exp $

require 5.00397;

package Mail::Folder::Mbox;
use strict;
use vars qw($VERSION @ISA $folder_id);

@ISA = qw(Mail::Folder);
$VERSION = "0.07";

Mail::Folder->register_type('mbox');

=head1 NAME

Mail::Folder::Mbox - A Unix mbox interface for Mail::Folder.

B<WARNING: This code is in alpha release. Expect the interface to
change.>

=head1 SYNOPSIS

C<use Mail::Folder::Mbox;>

=head1 DESCRIPTION

This module provides an interface to unix B<mbox> folders.

The B<mbox> folder format is the standard monolithic folder structure
prevalent on Unix.  A single folder is contained within a single file.
Each message starts with a line matching C</^From /> and ends with a
blank line.

The folder architecture does not provide any persistantly stored
current message variable, so the current message in this folder
interface defaults to C<1> and is not retained between C<open>s of a
folder.

If the C<Timeout> option is specified when the object is created, that
value will be used to determine the timeout for attempting to aquire a
folder lock.  The default is 10 seconds.

If the C<DotLock> option is specified when the object is created, that
value will be used to determine whether or not to use 'C<.lock>' style
folder locking.  The default value is C<1>.

If the C<Flock> option is specified when the object is created, that
value will be used to determined whether or not to use C<flock> style
folder locking.  By default, the option is not set.

If the C<NFSLock> option is specified when the object is created, that
value will be used to determine whether or not special measures are
taken when doing C<DotLock>ing.  These special measures consist of
constructing the lock file in a special manner that is more immune to
atomicity problems with NFS when creating a folder lock file.  By
default, the option is not set.  This option necessitates the ability
to use long filenames.

It is currently a fatal error to have both C<DotLock> and C<Flock>
disabled.

**NOTE** flock locking is currently disabled until I can sift out the
'right way'. **NOTE**

=cut

use Mail::Folder;
use Mail::Internet;
use Mail::Header;
use Mail::Address;
use Date::Format;
use Date::Parse;
# use File::BasicFlock;
use IO::File;
use DirHandle;
use Sys::Hostname;		# for NFSLock option
use Carp;

$folder_id = 0;			# used to generate a unique id per open folder

=head1 METHODS

=head2 open($folder_name)

=over 2

=item * Call the superclass C<open> method.

=item * Check to see if it is a valid mbox folder.

=item * Mark it as readonly if the folder is not writable.

=item * Lock the folder.

=item * Split the folder into individual messages in a temporary
working directory.

=item * Unlock the folder.

=item * Cache all the headers.

=item * Update the appropriate labels with information in the
C<Status> fields.

=item * Set C<current_message> to C<1>.

=back

=cut

sub open {
  my $self = shift;
  my $foldername = shift;
  
  return 0 unless $self->SUPER::open($foldername);
  
  is_valid_folder_format($foldername) || (-z $foldername)
    or croak "$foldername isn't an mbox folder";
  
  if (($< == 0) || ($> == 0)) {	# if we're root we have to check it by hand
    $self->set_readonly unless ((stat($foldername))[2] & 0200);
  } else {
    $self->set_readonly unless (-w $foldername);
  }
  # $self->set_readonly unless (-w $foldername);
  
  $self->_lock_folder or return 0;
  
  my $fh = new IO::File $foldername or croak "can't open $foldername: $!";
  $fh->seek(0, 2);
  $self->{MBOX_OldSeekPos} = $fh->tell;
  $fh->close;

  my $qty_new_msgs = $self->_absorb_mbox($foldername, 0);
  unless (defined($qty_new_msgs) && $self->_unlock_folder) {
    $self->_clean_working_dir;
    return 0;
  }
  $self->current_message(1);
  
  return $qty_new_msgs;
}

=head2 close

Deletes the internal working copy of the folder and calls the
superclass C<close> method.

=cut

sub close {
  my $self = shift;

  $self->_clean_working_dir;
  return $self->SUPER::close;
}

=head2 sync

=over 2

=item * Call the superclass C<sync> method.

=item * Lock the folder.

=item * Extract into the temporary working directory any new messages
that have been appended to the folder since the last time the folder
was either C<open>ed or C<sync>ed.

=item * Create a new copy of the folder and populate it with the
messages in the working copy that are not flagged for deletion and
update the C<Status> fields appropriately.

=item * Move the original folder to a temp location

=item * Move the new folder into place

=item * Delete the old original folder

=item * Unlock the folder

=back

=cut

sub sync {
  my $self = shift;

  my @statary;
  my $folder = $self->foldername;
  my $tmpfolder = "$folder.$$";
  my $infh;
  my $outfh;

  return -1 if ($self->SUPER::sync == -1);

  my $last_msgnum = $self->last_message;

  return -1 unless ($self->_lock_folder);

  unless ($infh = new IO::File($folder)) {
    $self->_unlock_folder;
    croak "can't open $folder: $!";
  }
  $infh->close;

  my $qty_new_msgs = $self->_absorb_mbox($folder, $self->{MBOX_OldSeekPos});
  unless (defined($qty_new_msgs)) {
    $self->_unlock_folder;
  }

  unless ($self->is_readonly) {
    # we need to diddle current_message if it's pointing to a deleted msg
    my $msg = $self->current_message;
    while ($msg >= $self->first_message) {
      last if (!$self->label_exists($msg, 'deleted'));
      $msg = $self->prev_message($msg);
    }
    $self->current_message($msg);

    for my $msg ($self->select_label('deleted')) {
      unlink("$self->{MBOX_WorkingDir}/$msg");
      $self->forget_message($msg);
    }
    $self->clear_label('deleted');

    unless (@statary = stat($folder)) {
      $self->_unlock_folder;
      croak "can't stat $folder: $!";
    }

    unless ($outfh = new IO::File $tmpfolder, O_CREAT|O_WRONLY, 0600) {
      $self->_unlock_folder;
      croak "can't create $tmpfolder: $!";
    }

    # match the permissions of the original folder
    unless (chmod(($statary[2] & 0777), $tmpfolder)) {
      unlink($tmpfolder);
      $self->_unlock_folder;
      croak "can't chmod $tmpfolder: $!";
    }

    for my $msg (sort { $a <=> $b } $self->message_list) {
      my $mref = $self->get_message($msg);
      my $href = $self->get_header($msg);

      unless ($self->get_option('NotMUA')) {
	my $status = 'O';
	$status = 'RO' if $self->label_exists($msg, 'seen');
	$href->replace('Status', $status, -1);
      }
      
      my $from = $href->get('Mail-From') || $href->get('From ');
      
      # we dup them cuz we're going to modify them
      my $dup_href = $href->dup;
      my $dup_mref = $mref->dup;
      $dup_href->delete('Mail-From') if ($dup_href->count('Mail-From'));
      
      $outfh->print("From $from");
      $dup_href->print($outfh);
      $outfh->print("\n");
      $dup_mref->escape_from unless $self->get_option('Content-Length');
      $dup_mref->print_body($outfh);
      $outfh->print("\n");
    }
    $outfh->close;

    # Move the original folder to a temp location

    unless (rename($folder, "$folder.tmp")) {
      $self->_unlock_folder;
      croak "can't move $folder out of the way: $!";
    }
    
    # Move the new folder into place
    
    unless (rename($tmpfolder, $folder)) {
      $self->_unlock_folder;
      croak "gack! can't rename $folder.tmp to $folder: $!"
	unless (rename("$folder.tmp", $folder));
      croak "can't move $folder to $folder.tmp: $!";
    }
    
    # Delete the old original folder
    
    unless (unlink("$folder.tmp")) {
      $self->_unlock_folder;
      croak "can't unlink $folder.tmp: $!";
    }
  }

  $self->_unlock_folder;

  return $qty_new_msgs;
}

=head2 pack

Calls the superclass C<pack> method.

Renames the message list to that there are no gaps in the numbering
sequence.

It also tweaks the current_message accordingly.

=cut

sub pack {
  my $self = shift;

  my $newmsg = 0;
  my $curmsg = $self->current_message;

  return 0 if (!$self->SUPER::pack);

  for my $msg (sort { $a <=> $b } $self->message_list) {
    $newmsg++;
    if ($msg > $newmsg) {
      $self->current_message($newmsg) if ($msg == $curmsg);
      $self->remember_message($newmsg);
      $self->cache_header($newmsg, $self->{Messages}{$msg}{Header});
      $self->forget_message($msg);
    }
  }

  return 1;
}

=item get_message ($msg_number)

Calls the superclass C<get_message> method.

Retrieves the given mail message file into a B<Mail::Internet> object
reference, sets the 'C<seen>' label, and returns the reference.

If the 'Content-Length' option is not set, then C<get_message> will
unescape 'From ' lines in the body of the message.

=cut

sub get_message {
  my $self = shift;
  my $key = shift;

  return undef unless $self->SUPER::get_message($key);

  my $file = "$self->{MBOX_WorkingDir}/$key";

  my $fh = new IO::File $file or croak "whoa! can't open $file: $!";
  my $mref = new Mail::Internet($fh,
				Modify => 0,
				MailFrom => 'COERCE');
  $mref->unescape_from unless $self->get_option('Content-Length');
  $fh->close;

  my $href = $mref->head;
  $self->cache_header($key, $href);

  $self->add_label($key, 'seen');

  return $mref;
}

=item get_message_file ($msg_number)

Calls the superclass C<get_message_file> method.

Retrieves the given mail message file and returns the name of the file.

Returns C<undef> on failure.

This method does NOT currently do any 'From ' unescaping.

=cut

sub get_message_file {
  my $self = shift;
  my $key = shift;

  return undef unless $self->SUPER::get_message($key);

  return "$self->{MBOX_WorkingDir}/$key";
}

=head2 get_header($msg_number)

If the particular header has never been retrieved then C<get_header>
loads (in a manner similar to C<get_message>) the header of the given
mail message into C<$self-E<gt>{Messages}{$msg_number}{Header}> and
returns the object reference.

If the header for the given mail message has already been retrieved in
a prior call to C<get_header>, then the cached entry is returned.

It also calls the superclass C<get_header> method.

=cut

sub get_header {
  my $self = shift;
  my $key = shift;

  my $hdr = $self->SUPER::get_header($key);
  return $hdr if defined($hdr);
  
  # return undef unless ($self->SUPER::get_header($key));

  # return $self->{Messages}{$key}{Header} if ($self->{Messages}{$key}{Header});

  my $file = "$self->{MBOX_WorkingDir}/$key";

  my $fh = new IO::File $file or croak "can't open $file: $!";
  my $href = new Mail::Header($fh,
			      Modify => 0,
			      MailFrom => 'COERCE');
  $fh->close;

  $self->cache_header($key, $href);

  return $href;
}

=head2 append_message($mref)

=over 2

Calls the superclass C<append_message> method.

Creates a new mail message file, in the temporary working directory,
with the contents of the mail message contained in C<$mref>.
It will synthesize a 'From ' line if one is not present in
C<$mref>.

If the 'Content-Length' option is not set, then C<get_message> will
escape 'From ' lines in the body of the message.

=cut

sub append_message {
  my $self = shift;
  my $mref = shift;
  
  my $msgnum = $self->last_message;
  
  my $dup_mref = $mref->dup;

  return 0 unless $self->SUPER::append_message($dup_mref);

  my $dup_href = $mref->head->dup;
  $dup_mref->escape_from unless ($self->get_option('Content-Length'));
  
  $msgnum++;
  my $fh = new IO::File("$self->{MBOX_WorkingDir}/$msgnum",
			O_CREAT|O_WRONLY, 0600)
    or croak "can't create $self->{MBOX_WorkingDir}/$msgnum: $!";
  _coerce_header($dup_href);
  $dup_href->print($fh);
  $fh->print("\n");
  $dup_mref->print_body($fh);
  $fh->close;

  $self->remember_message($msgnum);
  
  return 1;
}

=head2 update_message($msg_number, $mref)

Calls the superclass C<update_message> method.

Replaces the message pointed to by C<$msg_number> with the contents of
the C<Mail::Internet> object reference C<$mref>.

It will synthesize a 'From ' line if one is not present in
$mref.

If the 'Content-Length' option is not set, then C<get_message> will
escape 'From ' lines in the body of the message.

=cut

sub update_message {
  my $self = shift;
  my $key = shift;
  my $mref = shift;
  
  my $file_pos = 0;
  my $filename = "$self->{MBOX_WorkingDir}/$key";
  
  my $dup_mref = $mref->dup;
  my $dup_href = $dup_mref->head->dup;

  return 0 unless $self->SUPER::update_message($key, $dup_mref);

  $dup_mref->escape_from unless $self->get_option('Content-Length');

  my $fh = new IO::File "$filename.new", O_CREAT|O_WRONLY, 0600
    or croak "can't create $filename.new: $!";
  _coerce_header($dup_href);
  $dup_href->print($fh);
  $fh->print("\n");
  $dup_mref->print_body($fh);
  $fh->close;

  rename("$filename.new", $filename) or
    croak "can't rename $filename.new to $filename: $!";
  
  return 1;
}

=head2 init

Initializes various items specific to B<Mbox>.

=over 2

=item * Determines an appropriate temporary directory.  If the
C<TMPDIR> environment variable is set, it uses that, otherwise it uses
C</tmp>.  The working directory will be a subdirectory in that
directory.

=item * Bumps a sequence number used for unique temporary filenames.

=item * Initializes C<$self-E<gt>{WorkingDir}> to the name of a
directory that will be used to hold the working copies of the messages
in the folder.

=back

=cut

sub init {
  my $self = shift;

  my $tmpdir = $ENV{TMPDIR} ? $ENV{TMPDIR} : "/tmp";

  $self->{MBOX_WorkingDir} = undef;
  $folder_id++;
  for my $i ($folder_id .. ($folder_id + 10)) {
    if (! -e "$tmpdir/mbox$folder_id.$$") {
      $self->{MBOX_WorkingDir} = "$tmpdir/mbox.$folder_id.$$";
      last;
    }
    $folder_id++;
  }
  croak "can't seem to be able to create a working directory\n"
    unless (defined($self->{MBOX_WorkingDir}));
  $self->set_option('DotLock', 1)
    unless defined($self->get_option('DotLock'));

  croak "flock locking currently not implemented - sorry..."
    if ($self->get_option('Flock'));

  return 1;
}

=head2 is_valid_folder_format($foldername)

Returns C<1> if the folder is a plain file and starts with the string
'C<From >', otherwise it returns C<0>.

Returns C<1> if the folder is a zero-length file and the
C<$Mail::Format::DefaultEmptyFileFormat> class variable is set to
'C<mbox>'.

Otherwise it returns C<0>.

=cut

sub is_valid_folder_format {
  my $foldername = shift;

  return 0 if (! -f $foldername);
  if (-z $foldername) {
    return 1 if ($Mail::Folder::DefaultEmptyFileFormat eq 'mbox');
    return 0;
  }

  my $fh = new IO::File $foldername or return 0;
  my $line = <$fh>;
  $fh->close;
  return($line =~ /^From /);
}

=head2 create($foldername)

Creates a new folder named C<$foldername>.  Returns C<0> if the folder
already exists, otherwise returns C<1>.

=cut

sub create {
  my $self = shift;
  my $foldername = shift;

  return 0 if (-e $foldername);
  my $fh = new IO::File $foldername, O_CREAT|O_WRONLY, 0600
    or croak "can't create $foldername: $!";
  $fh->close;
  return 1;
}
###############################################################################
sub DESTROY {
  my $self = shift;

  # all of these are just in case...
  # the appropriate methods should have removed them already...
  if ($self->{Creator} == $$) {
    $self->_unlock_folder;
    $self->_clean_working_dir;
  }
}
###############################################################################
sub _absorb_mbox {
  my $self = shift;
  my $folder = shift;
  my $seek_pos = shift;

  my $qty_new_msgs = 0;
  my $last_was_blank = 0;
  my $is_blank = 0;
  my $last_msgnum = $self->last_message;
  my $new_msgnum = $last_msgnum;
  my $outfile_is_open = 0;
  my $outfh;

  if (! -e $self->{MBOX_WorkingDir}) {
    mkdir($self->{MBOX_WorkingDir}, 0700)
      or (carp "can't create $self->{MBOX_WorkingDir}: $!" and return undef);
  } elsif (! -d $self->{MBOX_WorkingDir}) {
    carp "$self->{MBOX_WorkingDir} isn't a directory!";
    return undef;
  }

  my $infh = new IO::File $folder or croak "can't open $folder: $!";
  $infh->seek($seek_pos, 0)
    or (carp "can't seek to $seek_pos in $folder: $!" and return undef);
  while (<$infh>) {
    $is_blank = /^$/ ? 1 : 0;
    if (/^From /) {
      $outfh->close if ($outfile_is_open);
      $outfile_is_open = 0;
      $new_msgnum++;
      $qty_new_msgs++;
      $self->remember_message($new_msgnum);
      $outfh = new IO::File("$self->{MBOX_WorkingDir}/$new_msgnum",
			    O_CREAT|O_WRONLY, 0600)
	or (carp "can't create $self->{MBOX_WorkingDir}/$new_msgnum: $!"
	    and return undef);
      $outfile_is_open++;
    } else {
      $outfh->print("\n") if ($last_was_blank);
    }
    $last_was_blank = $is_blank ? 1 : 0;
    $outfh->print($_) if !$is_blank;
  }
  $outfh->close if ($outfile_is_open);
  $self->{MBOX_OldSeekPos} = $infh->tell;
  $infh->close;

  for my $msg (($last_msgnum + 1) .. $self->last_message) {
    my $href = $self->get_header($msg);
    my $status = $href->get('Status') or next;
    $self->add_label($msg, 'seen') if ($status =~ /R/);
  }

  return $qty_new_msgs;
}

# Mbox files must have a 'From ' line at the beginning of each
# message.  This routine will synthesize one from the 'From:' and
# 'Date:' fields.  Original solution and code of the following
# subroutine provided by Andreas Koenig

# Since Mail::Header could have been told to coerce the 'From ' into a
# Mail-From field, we look for both, and neither is found then
# synthesize one.  In either case, a 'From ' string is returned.

sub _coerce_header {
  my $href = shift;
  my $from = '';
  my $date = '';
  
  my $mailfrom = $href->get('From ') || $href->get('Mail-From');
  
  unless ($mailfrom) {
    if ($from =
	$href->get('Reply-To') ||
	$href->get('From') ||
	$href->get('Sender') ||
	$href->get('Return-Path')) { # this is dubious
      my @addrs = Mail::Address->parse($from);
      $from = $addrs[0]->address();
    } else {
      $from = 'NOFROM';
    }
    
    if ($date = $href->get('Date')) {
      chomp($date);
      $date = gmtime(str2time($date));
    } else {
      # There was no date field. Let's just stuff today's date in there
      # for lack of a better value. I think it should be gmtime - someone
      # correct me if this is wrong.
      $date = gmtime;
    }
    chomp($date);
    $mailfrom = "$from $date\n";
  }
  
  $href->delete('From ');
  $href->delete('Mail-From');
  
  $href->mail_from('KEEP');
  $href->add('From ', $mailfrom, 0);
  $href->mail_from('COERCE');
  
  return $href;
}

sub _clean_working_dir {
  my $self = shift;
  # unlink(glob("$self->{MBOX_WorkingDir}/*"));
  # maybe this should filter out directories, just to be safe...
  my $dir = DirHandle->new($self->{MBOX_WorkingDir})
    or croak "yeep! can't read $self->{MBOX_WorkingDir} disappeared: $!\n";
  for my $file ($dir->read) {
    next if (($file eq '.') || ($file eq '..'));
    next if (-d "$self->{MBOX_WorkingDir}/$file");
    unlink "$self->{MBOX_WorkingDir}/$file";
  }
  $dir->close;
  rmdir($self->{MBOX_WorkingDir});
}

sub _lock_folder {
  my $self = shift;
  my $folder = $self->foldername;

  croak "DotLock and Flock are both disabled\n"
    unless ($self->get_option('DotLock') || $self->get_option('Flock'));

  my $timeout = $self->get_option('Timeout');
  $timeout ||= 10;
  my $sleep = 1.0;		# maybe this should be configurable

  if ($self->get_option('DotLock')) {
    my $nfshack = 0;
    my $lockfile = "$folder.lock";
    if ($self->get_option('NFSLock')) {
      my $host = hostname;
      $nfshack++;
      my $time = time;
      $lockfile .= ".$time.$$.$host";
    }
    for my $num (1 .. int($timeout / $sleep)) {
      my $fh;
      if ($fh = new IO::File $lockfile, O_CREAT|O_EXCL|O_WRONLY, 0600) {
	$fh->close;
	if ($nfshack) {
	  # Whhheeeee!!!!!
	  # In NFS, the O_CREAT|O_EXCL isn't guaranteed to be atomic.
	  # So we create a temp file that is probably unique in space
	  # and time ($folder.lock.$time.$pid.$host).
	  # Then we use link to create the real lock file. Since link
	  # is atomic across nfs, this works.
	  # It loses if it's on a filesystem that doesn't do long filenames.
	  link $lockfile, "$folder.lock"
	    or carp "link return: $!\n";
	  my @statary = stat($lockfile);
	  unlink $lockfile;
	  if (!defined(@statary) || $statary[3] != 2) { # failed to link?
	    goto RETRY;
	  }
	}
	return 1;
      }
    RETRY:
      last if ($! =~ /denied/);	# failure due to permissions
      select(undef, undef, undef, $sleep);
    }
    return 0;
  }

  # return lock($folder) if ($self->get_option('Flock'));
  return 0;
}

sub _unlock_folder {
  my $self = shift;
  my $folder = $self->foldername;

  if ($self->get_option('DotLock')) {
    return unlink("$folder.lock") if (-e "$folder.lock");
    return 1;
  }

  # return unlock($folder) if ($self->get_option('Flock'));
  return 0;
}

=head1 AUTHOR

Kevin Johnson E<lt>F<kjj@pobox.com>E<gt>

=head1 COPYRIGHT

Copyright (c) 1996-1998 Kevin Johnson <kjj@pobox.com>.

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;

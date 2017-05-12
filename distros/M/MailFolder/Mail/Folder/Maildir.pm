# -*-perl-*-
#
# Copyright (c) 1996-1998 Kevin Johnson <kjj@pobox.com>.
#
# All rights reserved. This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.
#
# $Id: Maildir.pm,v 1.4 1998/04/05 17:21:53 kjj Exp $

require 5.00397;
package Mail::Folder::Maildir;
use strict;
use POSIX qw(ENOENT);
use vars qw($VERSION @ISA);

@ISA = qw(Mail::Folder);
$VERSION = "0.07";

Mail::Folder->register_type('maildir');

my $counter = 0;

=head1 NAME

Mail::Folder::Maildir - A maildir folder interface for Mail::Folder.

B<WARNING: This code is in alpha release. Expect the interface to
change.>

=head1 SYNOPSIS

C<use Mail::Folder::Maildir;>

=head1 DESCRIPTION

This module provides an interface to the B<maildir> folder mechanism.

The B<maildir> folder format is the preferred folder mechanism for the
B<qmail> mail transport agent.  It uses directories as folders and
files as messages.  It also provides separate directories for new and
current messages.  One of the most distinguishing features of the
C<maildir> format is that it accomplishes it's job without the need
for file locking, so it's better equipped to deal with things like nfs
mounts and the like.

More information about qmail is available from
C<http://pobox.com/~djb/qmail.html>.

=cut

use Mail::Folder;
use Mail::Internet;
use Mail::Header;
use Mail::Address;
use Sys::Hostname;
use IO::File;
use DirHandle;
use File::Sync qw(fsync);

use Carp;

=head1 METHODS

=head2 open($folder_name)

Populates the C<Mail::Folder> object with information about the folder.

=over 2

=item * Call the superclass C<open> method.

=item * Make sure it is a valid maildir folder.

=item * Detect whether the folder is readonly.

=item * Clean the folder C<tmp> directory.

=item * Move message in folder C<new> directory into the C<cur> directory.

=item * Clean up the folder C<tmp> directory.

=item * Moves message file in C<new> directory to the C<cur> directory.

=item * For every message in the folder, add a new message number to
the list of messages in the object, and remember the association between
the message number and the message filename.

=item * Set C<current_message> to 1 (ugh).

=back

=cut

sub open {
  my $self = shift;
  my $foldername = shift;

  return 0 unless $self->SUPER::open($foldername);

  is_valid_folder_format($foldername)
    or croak "$foldername isn't an maildir folder";

  if (($< == 0) || ($> == 0)) {
    $self->set_readonly unless ((stat($foldername))[2] & 0200);
  } else {
    $self->set_readonly unless (-w $foldername);
  }

  $self->_absorb_folder($foldername);

  $self->current_message(1);

  return 1;
}

=head2 close

Deletes the working copy of the folder and calls the superclass
C<close> method.

=cut

sub close {
  my $self = shift;

  delete $self->{MAILDIR_MsgFiles};
  return $self->SUPER::close;
}

=head2 sync

=over 2

=item * Call the superclass C<sync> method.

=item * Scan for new messages and absorb them.

=item * If the folder is not readonly, expunge messages marked for
deletion.

=item * Update the C<:info> portion of each file in the folder.

=item * Return the quantity of new messages found.

=cut

sub sync {
  my $self = shift;

  my $qty_new_messages = 0;
  my @deletes = $self->select_label('deleted');
  my $foldername = $self->foldername;

  return -1 if ($self->SUPER::sync == -1);

  $self->_absorb_folder($foldername);

  unless ($self->is_readonly) {
    if (@deletes) {
      # we need to diddle current_message if it's pointing to a deleted msg
      my $msg = $self->current_message;
      while ($msg >= $self->first_message) {
	last if (!$self->label_exists($msg, 'deleted'));
	$msg = $self->prev_message($msg);
      }
      $self->current_message($msg);

      unlink(map { "$foldername/$self->{Messages}{$_}{Filename}" } @deletes);
      for my $msg (@deletes) {
	$self->forget_message($msg);
      }
      $self->clear_label('deleted');
    }
  }

  $self->_maildir_update_info unless ($self->is_readonly ||
				      $self->get_option('NotMUA'));

  return $qty_new_messages;
}

=head2 pack

Calls the superclass C<pack> method.  Reassociates the filenames in
the folders to message numbers, deleting holes in the sequence of
message numbers.

=cut

sub pack {
  my $self = shift;

  my $newmsg = 0;
  my $current_message = $self->current_message;

  return 0 if (!$self->SUPER::pack || $self->is_readonly);

  for my $msg (sort { $a <=> $b } $self->message_list) {
    $newmsg++;
    if ($msg > $newmsg) {
      $self->current_message($newmsg) if ($msg == $current_message);
      $self->remember_message($newmsg);
      $self->cache_header($newmsg, $self->{Messages}{$msg}{Header});
      $self->forget_message($msg);
    }
  }
  return 1;
}

=head2 get_message($msg_number)

Call the superclass C<get_message> method.

Retrieves the contents of the file pointed to by C<$msg_number> into a
B<Mail::Internet> object reference, caches the header, marks the
message as 'C<seen>' and returns the reference.

=cut

sub get_message {
  my $self = shift;
  my $key = shift;
  
  return undef unless $self->SUPER::get_message($key);
  
  my $filename = $self->foldername . "/$self->{Messages}{$key}{Filename}";
  my $fh = new IO::File $filename or croak "can't open $filename: $!";
  my $mref = new Mail::Internet($fh,
				Modify => 0,
				MailFrom => 'COERCE');
  $fh->close;

  my $href = $mref->head;
  $self->cache_header($key, $href);
  $self->add_label($key, 'seen');

  return $mref;
}

=head2 get_message_file($msg_number)

Call the superclass C<get_message_file> method.

Retrieves the given mail message file pointed to by $msg_number
and returns the name of the file.

=cut

sub get_message_file {
  my $self = shift;
  my $key = shift;
  
  return undef unless $self->SUPER::get_message_file($key);
  
  return($self->foldername . "/$self->{Messages}{$key}{Filename}");
}

=head2 get_header($msg_number)

If the particular header has never been retrieved then C<get_header>
loads the header of the given mail message into a member of
C<$self-E<gt>{Messages}{$msg_number}> and returns the object reference

If the header for the given mail message has already been retrieved in
a prior call to C<get_header>, then the cached entry is returned.

=cut

sub get_header {
  my $self = shift;
  my $key = shift;
  
  my $hdr = $self->SUPER::get_header($key);
  return $hdr if defined($hdr);
  
  # return undef unless ($self->SUPER::get_header($key));
  
  # return $self->{Messages}{$key}{Header} if ($self->{Messages}{$key}{Header});
  
  my $filename = $self->foldername . "/$self->{Messages}{$key}{Filename}";

  my $fh = new IO::File $filename or return undef;
  my $href = new Mail::Header($fh,
			      Modify => 0,
			      MailFrom => 'COERCE');
  $fh->close;

  $self->cache_header($key, $href);

  return $href;
}

=head2 append_message($mref)

Calls the superclass C<append_message> method.

Writes a temporary copy of the message in C<$mref> to the
folder C<tmp> directory, then moves that temporary copy into the
folder C<cur> directory.

It will delete the C<From_> line in the header if one is present.

=cut

sub append_message {
  my $self = shift;
  my $mref = shift;

  my $folder = $self->foldername;
  my $msg_num = $self->last_message;

  my $dup_mref = $mref->dup;

  return 0 unless $self->SUPER::append_message($dup_mref);

  $msg_num++;
  $dup_mref->delete('From ');
  
  my $tmpfile = $self->_get_tmp_file()
    or croak "timed out trying to create a file in $folder/tmp";
  my $fh = new IO::File "$folder/tmp/$tmpfile", O_CREAT|O_WRONLY, 0600
    or croak "can't create $folder/tmp/$tmpfile: $!";
  $fh->autoflush(1);
  _coerce_header($dup_mref);
  $dup_mref->print($fh) or croak "failed writing $folder/tmp/$tmpfile: $!";
  fsync($fh) or croak "failed fsyncing $folder/tmp/$tmpfile: $!";
  $fh->close or croak "failed closing $folder/tmp/$tmpfile: $!";

  link("$folder/tmp/$tmpfile", "$folder/cur/$tmpfile")
    or croak "can't link $folder/tmp/$tmpfile to $folder/cur/$tmpfile for append method: $!";
  unlink("$folder/tmp/$tmpfile")
    or croak "can't unlink $folder/tmp/$tmpfile for append method: $!";

  $self->remember_message($msg_num);
  $self->cache_header($msg_num, $dup_mref->head);
  $self->{MAILDIR_MsgFiles}{$tmpfile} = $msg_num; # file to msgnum mapping
  $self->{Messages}{$msg_num}{Filename} = "cur/$tmpfile";

  return 1;
}

=head2 update_message($msg_number, $mref)

Calls the superclass C<update_message> method.

Writes a temporary copy of the message in C<$mref> to the
folder C<tmp> directory, then moves that temporary copy into the
folder C<cur> directory, replacing the message pointed to by
C<$msg_number>.

It will delete the C<From_> line in the header if one is present.

=cut

sub update_message {
  my $self = shift;
  my $key = shift;
  my $mref = shift;

  my $folder = $self->foldername;
  my $dup_mref = $mref->dup;

  return 0 unless $self->SUPER::update_message($key, $dup_mref);

  $dup_mref->delete('From ');

  my $tmpfile = $self->_get_tmp_file()
    or croak "timed out trying to create a tmpfile";
  my $fh = new IO::File $tmpfile, O_CREAT|O_WRONLY, 0600
    or croak "can't create $tmpfile: $!";
  $fh->autoflush(1);
  _coerce_header($dup_mref);
  $dup_mref->print($fh) or croak "failed writing $tmpfile: $!";
  fsync($fh) or croak "failed fsyncing $tmpfile: $!";
  $fh->close or croak "failed closing $tmpfile: $!";

  rename($tmpfile, "$folder/$self->{Messages}{$key}{Filename}") or
    croak "can't rename $tmpfile to $folder/$self->{Messages}{$key}{Filename}: $!";

  return 1;
}

=head2 is_valid_folder_format($foldername)

Returns C<1> if the folder is a directory and contains C<tmp>, C<cur>,
and C<new> subdirectories otherwise returns C<0>.

=cut

sub is_valid_folder_format {
  my $foldername = shift;

  return 0 unless (-d $foldername &&
		   -d "$foldername/tmp" &&
		   -d "$foldername/cur" &&
		   -d "$foldername/new");
  return 1;
}

=head2 create($foldername)

Creates a new folder named C<$foldername>.  Returns C<0> if the folder
already exists, otherwise returns C<1>.

=cut

sub create {
  my $self = shift;
  my $foldername = shift;

  return 0 if (-e $foldername);

  mkdir($foldername, 0700) or croak "can't create $foldername: $!";
  mkdir("$foldername/cur", 0700);
  mkdir("$foldername/new", 0700);
  mkdir("$foldername/tmp", 0700);
  return 1;
}
###############################################################################
sub _coerce_header {
  my $mref = shift;
  my $from = '';

  if ($mref->head->count('Return-Path') == 0) {
    if ($from =
	$mref->get('Reply-To') ||
	$mref->get('From') ||
	$mref->get('Sender')) {	# this is dubious
      my @addrs = Mail::Address->parse($from);
      $from = $addrs[0]->address();
      $mref->add('Return-Path', "<$from>", 0);
    } else {
      croak "can't synthesize Return-Path";
    }
  }

  return $mref;
}

# this returns the name of a newly create file in the folder tmp
# directory following the qmail rules for it's creation.

sub _get_tmp_file {
  my $self = shift;
  my $folder = $self->foldername;
  my $filename = '';
  my $counter = $self->_bump_counter;

  my $hostname = hostname or croak "can't determine hostname: $!";
  # this loop duration should be configurable, but it's according to spec
  for my $num (1 .. 30) {
    my $time = time;
    $filename = "$time.$$" . "_$counter.$hostname";
    if (stat("$folder/tmp/$filename") || ($! != ENOENT)) {
      select(undef, undef, undef, 2.0);
      next;
    }
    my $fh = new IO::File "$folder/tmp/$filename", O_CREAT|O_WRONLY, 0600
      or croak "can't create $folder/tmp/$filename: $!";
    $fh->close;
    return $filename;
  }

  return undef;
}

sub _bump_counter {
  # my $self = shift;
  return $counter++;
}

sub _maildir_update_info {
  my $self = shift;

  my $foldername = $self->foldername;

  for my $msg ($self->message_list) {
    my $file = $self->{Messages}{$msg}{Filename};
    my $uniqpart = $file; $uniqpart =~ s/:.*$//;
    my $oldinfo = '';
    my $newinfo = '';
    $newinfo .= 'F' if ($self->label_exists($msg, 'flagged'));
    $newinfo .= 'R' if ($self->label_exists($msg, 'replied'));
    $newinfo .= 'S' if ($self->label_exists($msg, 'seen'));
    next if (($file =~ /:/) && ($file !~ /:2,/));
    if ($file =~ /:(.*)/) {
      $oldinfo = $1;
    }
    if ($oldinfo ne $newinfo) {
      my $newfile = "$uniqpart:2,$newinfo";
      croak "can't rename $foldername/$file to $foldername/$newfile: $!"
	unless (rename("$foldername/$file", "$foldername/$newfile"));
      $self->{Messages}{$msg}{Filename} = $newfile;
      delete $self->{MAILDIR_MsgFiles}{$file};
      $self->{MAILDIR_MsgFiles}{$newfile} = $msg;
    }
  }
}

sub _maildir_clean {
  my $foldername = shift;

  my @statary;
  my $time = time;
  my $tmpdir = "$foldername/tmp";

  my $dir = new DirHandle $tmpdir or croak "can't open $tmpdir: $!";
  my @files = $dir->read;
  $dir->close;

  for my $file (@files) {
    next if ($file =~ /^\./);	# per djb, skip filenames that start with "."
    unlink("$tmpdir/$file") if ((@statary = stat("$tmpdir/$file")) &&
				($statary[9] + 129600) < $time);
  }
}

sub _maildir_move_new_to_cur {
  my $foldername = shift;

  my @newfiles;

  my $dir = new DirHandle "$foldername/new"
    or croak"can't open $foldername/new: $!";
  my @files = $dir->read;
  $dir->close;

  for my $file (@files) {
    next if ($file =~ /^\./);
    unlink("$foldername/new/$file")
      if (link("$foldername/new/$file", "$foldername/cur/$file"));
    push(@newfiles, $file);
  }
  return(@newfiles);
}

sub _absorb_folder {
  my $self = shift;
  my $folder_dir = shift;
  my $msg_num = $self->last_message;
  
  _maildir_clean($folder_dir);

  _maildir_move_new_to_cur($folder_dir);

  my $dir = new DirHandle "$folder_dir/cur"
    or croak "can't open $folder_dir/cur: $!";
  my @files = sort map { "cur/$_" } grep((!/^\./ &&
					  !/^RCS$/ &&
					  -f "$folder_dir/cur/$_"),
					 $dir->read);
  $dir->close;
  if (0) {
    $dir = new DirHandle "$folder_dir/new"
      or croak "can't open $folder_dir/new: $!";
    push @files, sort map { "new/$_" } grep((!/^\./ &&
					     !/^RCS$/ &&
					     -f "$folder_dir/new/$_"),
					    $dir->read);
    $dir->close;
  }

  for my $file (@files) {
    next if defined($self->{MAILDIR_MsgFiles}{$file});
    $msg_num++;
    $self->remember_message($msg_num);
    $self->{MAILDIR_MsgFiles}{$file} = $msg_num; # file-to-msgnum mapping
    $self->{Messages}{$msg_num}{Filename} = $file;

    next unless ($file =~ /:(.+)$/); # no info field

    my $info = $1;
    next unless ($info =~ /^2,/); # do we know this info field structure?

    $self->add_label($msg_num, 'flagged') if ($info =~ /F/);
    $self->add_label($msg_num, 'replied') if ($info =~ /R/);
    $self->add_label($msg_num, 'seen') if ($info =~ /S/);
    $self->delete_message($msg_num) if ($info =~ /T/);
				# Not convinced we should do this...
  }
}

###############################################################################

=head1 AUTHOR

Kevin Johnson E<lt>F<kjj@pobox.com>E<gt>

=head1 COPYRIGHT

Copyright (c) 1996-1998 Kevin Johnson <kjj@pobox.com>.

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;

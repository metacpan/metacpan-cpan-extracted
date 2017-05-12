# -*-perl-*-
#
# Copyright (c) 1996-1998 Kevin Johnson <kjj@pobox.com>.
#
# All rights reserved. This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.
#
# $Id: Emaul.pm,v 1.7 1998/04/05 17:21:53 kjj Exp $

require 5.00397;
package Mail::Folder::Emaul;
use strict;
use vars qw($VERSION @ISA);
@ISA = qw(Mail::Folder);
$VERSION = "0.07";

Mail::Folder->register_type('emaul');

=head1 NAME

Mail::Folder::Emaul - An Emaul folder interface for Mail::Folder.

B<WARNING: This code is in alpha release. Expect the interface to
change.>

=head1 SYNOPSIS

C<use Mail::Folder::Emaul;>

=head1 DESCRIPTION

This module provides an interface to the B<emaul> folder mechanism.
It is currently intended to be used as an example of hooking a folder
interface into Mail::Folder.

The folder structure of B<Emaul> is styled after B<mh>.  It uses
directories for folders and numerically-named files for the individual
mail messages.  The current message for a particular folder is stored
in a file C<.current_msg> in the folder directory.

Folder locking is accomplished through the use of a .lock file in the
folder directory.

If a C<Timeout> option is specified when the object is created, that
value will be used to determine the timeout for attempting to aquire
a folder lock.  The default is 10 seconds.

=cut

use Mail::Folder;
use Mail::Internet;
use Mail::Header;
use IO::File;
use DirHandle;
use Sys::Hostname;
use Carp;

=head1 METHODS

=head2 open($folder_name)

Populates the C<Mail::Folder> object with information about the
folder.

=over 2

=item * Call the superclass C<open> method.

=item * Make sure it is a valid mbox folder.

=item * Check to see it it is readonly

=item * Lock the folder if it is not readonly.  (This is dubious)

=item * For every message file in the C<$folder_name> directory, add
the message_number to the list of messages in the object.

=item * Load the contents of C<$folder_dir/.current_msg> into
C<$self-E<gt>{Current}>.

=item * Set C<current_message>.

=item * Load message labels.

=item * Unlock the folder if it is not readonly.

=back

=cut

sub open {
  my $self = shift;
  my $foldername = shift;

  return 0 unless $self->SUPER::open($foldername);

  is_valid_folder_format($foldername)
    or croak "$foldername isn't an emaul folder";

  if (($< == 0) || ($> == 0)) {	# if we're root we have to check it by hand
    $self->set_readonly unless ((stat($foldername))[2] & 0200);
  } else {
    $self->set_readonly unless (-w $foldername);
  }

  return 0 unless ($self->is_readonly || $self->_lock_folder);

  for my $msg (_get_folder_msgs($foldername)) {
    $self->remember_message($msg);
  }

  $self->current_message(_load_current_msg($foldername));
  $self->_load_message_labels;

  $self->_unlock_folder unless ($self->is_readonly);

  return 1;
}

=head2 sync

Flushes any pending changes out to the original folder.

=over 2

=item * Call the superclass C<sync> method.

=item * Return C<-1> if the folder is readonly.

=item * Return C<-1> if the folder cannot be locked.

=item * Scan the folder directory for message files that were not
present the last time the folder was either C<open>ed or C<sync>ed
and absorb them.

=item * For every pending delete, unlink that file in the folder
directory

=item * Clear out the 'pending delete' list.

=item * Update the C<.current_msg> file and the C<.msg_labels> file if
the C<NotMUA> option is not set.

=item * Return the number of new messages found.

=back

=cut

sub sync {
  my $self = shift;
  
  my $current_message = $self->current_message;
  my $qty_new_messages = 0;
  my $foldername = $self->foldername;
  
  return -1 if ($self->SUPER::sync == -1);

  return -1 unless ($self->is_readonly || $self->_lock_folder);

  for my $msg (_get_folder_msgs($foldername)) {
    unless (defined($self->{Messages}{$msg})) {
      $self->remember_message($msg);
      $qty_new_messages++;
    }
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
      unlink("$foldername/$msg");
      $self->forget_message($msg);
    }
    $self->clear_label('deleted');
  }

  unless ($self->is_readonly || $self->get_option('NotMUA')) {
    _store_current_msg($foldername, $current_message);
    $self->_store_message_labels($foldername);
  }

  $self->_unlock_folder unless ($self->is_readonly);
  
  return $qty_new_messages;
}

=head2 pack

Calls the superclass C<pack> method.

Return C<0> if the folder is readonly.

Return C<0> if the folder cannot be locked.

Renames the message files in the folder so that there are no gaps in
the numbering sequence.  It will tweak C<current_message> accordingly.

Old deleted message files (ones that start with C<,>) are also renamed
as necessary.

It will abandon the operation and return C<0> if a C<rename> fails,
otherwise it returns C<1>.

Please note that C<pack> acts on the real folder.

=cut

sub pack {
  my $self = shift;
  
  my $newmsg = 0;
  my $folder = $self->foldername;
  my $current_message = $self->current_message;
  
  return 0 if (!$self->SUPER::pack || $self->is_readonly);

  return 0 unless ($self->_lock_folder);

  for my $msg (sort { $a <=> $b } $self->message_list) {
    $newmsg++;
    if ($msg > $newmsg) {
      return 0 if (!rename("$folder/$msg", "$folder/$newmsg") ||
		    (-e "$folder/,$msg" &&
		     !rename("$folder/,$msg", "$folder/,$newmsg")));
      $self->current_message($newmsg) if ($msg == $current_message);
      $self->remember_message($newmsg);
      $self->cache_header($newmsg, $self->{Messages}{$msg}{Header});
      $self->forget_message($msg);
    }
  }
  $self->_unlock_folder;
  return 1;
}

=head2 get_message($msg_number)

Calls the superclass C<get_message> method.

Retrieves the given mail message file into a B<Mail::Internet> object
reference and returns the reference.

It will coerce the C<From_> field into a C<Mail-From> field, add the
'C<seen>' label to the message, remove the C<Content-Length> field
if present, and cache the header.

Returns C<undef> on failure.

=cut

sub get_message {
  my $self = shift;
  my $key = shift;

  my $filename = $self->foldername . "/$key";
  
  return undef unless $self->SUPER::get_message($key);

  my $fh = new IO::File $filename
    or croak "can't open $filename: $!";
  my $mref = new Mail::Internet($fh,
				Modify => 0,
				MailFrom => 'COERCE');
  $fh->close;
  $mref->delete('Content-Length');

  my $href = $mref->head;
  $self->cache_header($key, $href);
  $self->add_label($key, 'seen');
  
  return $mref;
}

=head2 get_message_file($msg_number)

Calls the superclass C<get_message_file> method.

Retrieves the given mail message file and returns the name of the file.

Returns C<undef> on failure.

=cut

sub get_message_file {
  my $self = shift;
  my $key = shift;
  
  return undef unless $self->SUPER::get_message_file($key);

  return($self->foldername . "/$key");
}

=head2 get_header($msg_number)

Calls the superclass C<get_header> method.

If the particular header has never been retrieved then C<get_header>
loads the header of the given mail message into a member of
C<$self-E<gt>{Messages}{$msg_number}> and returns the object reference

If the header for the given mail message has already been retrieved in
a prior call to C<get_header>, then the cached entry is returned.

The C<Content-Length> field is deleted from the header object it
returns.

=cut

sub get_header {
  my $self = shift;
  my $key = shift;

  my $hdr = $self->SUPER::get_header($key);
  return $hdr if defined($hdr);
  
  # return undef unless $self->SUPER::get_header($key);
  
  # return $self->{Messages}{$key}{Header} if ($self->{Messages}{$key}{Header});

  my $fh = new IO::File $self->foldername . "/$key" or return undef;
  my $href = new Mail::Header($fh,
			      Modify => 0,
			      MailFrom => 'COERCE');
  $fh->close;
  $href->delete('Content-Length');
  $self->cache_header($key, $href);
  return $href;
}

=head2 append_message($mref)

Calls the superclass C<append_message> method.

Returns C<0> if it cannot lock the folder.

Appends the contents of the mail message contained C<$mref> to
the the folder.

It also caches the header.

Please note that, contrary to other documentation for B<Mail::Folder>,
the Emaul C<append_message> method actually updates the real folder,
rather than queueing it up for a subsequent sync.  The C<dup> and
C<refile> methods are also affected. This will be fixed soon.

=cut

sub append_message {
  my $self = shift;
  my $mref = shift;

  my $dup_mref = $mref->dup;
  my $msgnum = $self->last_message;
  
  return 0 unless $self->SUPER::append_message($dup_mref);

  return 0 unless $self->_lock_folder;

  $msgnum++;
  $dup_mref->delete('From ');
  _write_message($self->foldername, $msgnum, $dup_mref);

  $self->_unlock_folder;

  $self->remember_message($msgnum);
  $self->cache_header($msgnum, $dup_mref->head);

  return 1;
}

=head2 update_message($msg_number, $mref)

Calls the superclass C<update_message> method.

It returns C<0> if it cannot lock the folder.

Replaces the message pointed to by C<$msg_number> with the contents of
the C<Mail::Internet> object reference C<$mref>.

Please note that, contrary to other documentation for B<Mail::Folder>,
the Emaul C<update_message> method actually updates the real folder,
rather than queueing it up for a subsequent sync.  This will be fixed
soon.

=cut

sub update_message {
  my $self = shift;
  my $key = shift;
  my $mref = shift;

  my $dup_mref = $mref->dup;

  $dup_mref->delete('From ');
  
  return 0 unless $self->SUPER::update_message($key, $dup_mref);

  return 0 unless $self->_lock_folder;

  _write_message($self->foldername, $key, $dup_mref);

  $self->_unlock_folder;
  
  return 1;
}

=head2 is_valid_folder_format($foldername)

Returns C<0> if the folder is not a directory or looks like a maildir
folder.  The current logic allows it to handle MH directories, but
watch out; you should probably set the C<NotMUA> option so the
interface doesn't create it's own little folder droppings like
C<.msg_labels> and such.

=cut

sub is_valid_folder_format {
  my $foldername = shift;

  return 0 unless (-d $foldername);
  return 0 if (-d "$foldername/tmp" &&
		-d "$foldername/cur" &&
		-d "$foldername/new"); # make sure it isn't a maildir folder
  return 1 if (-f "$foldername/.current_msg");
  return 1;			# NOTE: this is a leap of faith - if there's
				# ever an MH interface, this will have to be
				# tweaked...
}

=head2 create($foldername)

Returns C<0> if the folder already exists.

Creates a new folder named C<$foldername> with mode C<0700> and then
returns C<1>.


=cut

sub create {
  my $self = shift;
  my $foldername = shift;

  return 0 if (-e $foldername);

  mkdir($foldername, 0700) or croak "can't create $foldername: $!";
  return 1;
}

###############################################################################

sub _get_folder_msgs {
  my $folder_dir = shift;
  
  my $dir = new DirHandle $folder_dir or croak "can't open $folder_dir: $!";
  my @files = grep(/^\d+$/, $dir->read);
  $dir->close;

  return(@files);
}

sub _lock_folder {
  my $self = shift;
  my $folder = $self->foldername;

  my $fh;
  my $timeout = $self->get_option('Timeout');
  $timeout ||= 10;
  my $sleep = 1.0;		# maybe this should be configurable

  my $lockfile = "$folder/.lock";
  my $nfshack = 0;
  if ($self->get_option('NFSLock')) {
    $nfshack++;
    my $host = hostname;
    my $time = time;
    $lockfile .= ".$time.$$.$host";
  }

  for my $num (1 .. int($timeout / $sleep)) {
    if ($fh = new IO::File $lockfile, O_CREAT|O_EXCL|O_WRONLY, 0644) {
      $fh->close;
      if ($nfshack) {
	# Whhheeeee!!!!!
	# In NFS, the O_CREAT|O_EXCL isn't guaranteed to be atomic.
	# So we create a temp file that is probably unique in space
	# and time ($folder.lock.$time.$pid.$host).
	# Then we use link to create the real lock file. Since link
	# is atomic across nfs, this works.
	# It loses if it's on a filesystem that doesn't do long filenames.
	link $lockfile, "$folder/.lock"
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
    select(undef, undef, undef, $sleep);
  }
  carp("can't lock $folder folder: $!");
  return 0;
}

sub _unlock_folder {
  my $self = shift;
  my $folder = $self->foldername;
  return unlink("$folder/.lock");
}

sub _write_message {
  my $folder_dir = shift;
  my $key = shift;
  my $mref = shift;
 
  rename("$folder_dir/$key", "$folder_dir/,$key") if (-e "$folder_dir/$key");

  my $fh = new IO::File "$folder_dir/$key", O_CREAT|O_WRONLY, 0600
    or croak "can't create $folder_dir/$key: $!";
  $mref->print($fh);
  $fh->close;
  
  return 1;
}

sub _load_current_msg {
  my $foldername = shift;
  my $current_msg = 0;

  if (my $fh = new IO::File "$foldername/.current_msg") {
    $current_msg = <$fh>;
    $fh->close;
    chomp($current_msg);
    croak "non-numeric content in $foldername/.current_msg"
      if ($current_msg !~ /^\d+$/);
  }

  return $current_msg;
}

sub _store_current_msg {
  my $foldername = shift;
  my $current_msg = shift;

  my $fh = new IO::File ">$foldername/.current_msg"
    or croak "can't write $foldername/.current_msg: $!";
  $fh->print("$current_msg\n");
  $fh->close;
}

sub _store_message_labels {
  my $self = shift;
  my @alllabels = $self->list_all_labels;
  my @labels;
  my $folder = $self->foldername;
  my $fh;

  if (@alllabels) {
    unlink("$folder/.msg_labels");
    $fh = new IO::File ">$folder/.msg_labels"
      or croak "can't create $folder/.msg_labels: $!";
    for my $label (@alllabels) {
      @labels = $self->select_label($label);
      $fh->print("$label: ", _collapse_select_list(@labels), "\n");
    }
    $fh->close;
  }
}

sub _collapse_select_list {
  my @list = sort { $a <=> $b } @_;
  my @commalist;
  my $low = $list[0];
  my $high = $low;

  for my $item (@list) {
    if ($item > ($high + 1)) {
      push(@commalist, ($low != $high) ? "$low-$high" : $low);
      $low = $item;
    }
    $high = $item;
  }
  push(@commalist, ($low != $high) ? "$low-$high" : $low);
  return join(',', @commalist);
}

sub _load_message_labels {
  my $self = shift;

  my %labels;
  my ($label, $value);
  my ($low, $high);

  if (my $fh = new IO::File $self->foldername . "/.msg_labels") {
    while (<$fh>) {
      chomp;
      next if (/^\s*$/);
      next if (/^\s*\#/);
      ($label, $value) = split(/\s*:\s*/, $_, 2);
      $labels{$label} = $value;
      for my $commachunk (split(',', $value)) {
	if ($commachunk =~ /-/) {
	  ($low, $high) = split(/-/, $commachunk, 2);
	} else { $low = $high = $commachunk; }
	($low <= $high) or croak "bad message spec: $low > $high: $value";
	(($low =~ /^\d+$/) && ($high =~ /^\d+$/))
	  or croak "bad message spec: $value";
	for (; $low <= $high; $low++) {
	  ($self->add_label($low, $label))
	    if (defined($self->{Messages}{$low}));
	}
      }
    }
    $fh->close;
  }
}

=head1 AUTHOR

Kevin Johnson E<lt>F<kjj@pobox.com>E<gt>

=head1 COPYRIGHT

Copyright (c) 1996-1998 Kevin Johnson <kjj@pobox.com>.

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;

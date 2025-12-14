# This code is part of Perl distribution Mail-Box version 4.01.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::MH;{
our $VERSION = '4.01';
}

use parent 'Mail::Box::Dir';

use strict;
use warnings;

use Log::Report      'mail-box', import => [ qw/__x error fault trace/ ];

use Mail::Box::MH::Index   ();
use Mail::Box::MH::Message ();
use Mail::Box::MH::Labels  ();

use File::Spec::Functions  qw/rel2abs/;
use File::Basename         qw/basename/;

# Since MailBox 2.052, the use of File::Spec is reduced to the minimum,
# because it is too slow.  The '/' directory separators do work on
# Windows too.

#--------------------

my $default_folder_dir = exists $ENV{HOME} ? "$ENV{HOME}/.mh" : '.';

sub init($)
{	my ($self, $args) = @_;
	$args->{folderdir}     ||= $default_folder_dir;
	$args->{lock_file}     ||= $args->{index_filename};

	$self->SUPER::init($args);

	my $folderdir            = $self->folderdir;
	my $directory            = $self->directory;
	-d $directory or return;

	# About the index

	$self->{MBM_keep_index}  = $args->{keep_index} || 0;
	$self->{MBM_index}       = $args->{index};
	$self->{MBM_index_type}  = $args->{index_type} || 'Mail::Box::MH::Index';

	my $ifn = $args->{index_filename} //= '.index';
	$self->{MBM_index_filename} = rel2abs $ifn, $directory;

	# About labels

	$self->{MBM_labels}      = $args->{labels};
	$self->{MBM_labels_type} = $args->{labels_type} || 'Mail::Box::MH::Labels';

	my $lfn = $args->{labels_filename} //= '.mh_sequences';
	$self->{MBM_labels_filename} = rel2abs $lfn, $directory;

	$self;
}


sub create($@)
{	my ($thingy, $name, %args) = @_;
	my $class     = ref $thingy      || $thingy;
	my $folderdir = $args{folderdir} || $default_folder_dir;
	my $directory = $class->folderToDirectory($name, $folderdir);

	return $class if -d $directory;

	mkdir $directory, 0700
		or fault __x"cannot create MH folder {name}", name => $name;

	trace "Created folder $name.";
	$class;
}

#--------------------

sub type() {'mh'}

sub foundIn($@)
{	my $class = shift;
	my $name  = @_ % 2 ? shift : undef;
	my %args  = @_;
	my $folderdir = $args{folderdir} || $default_folder_dir;
	my $directory = $class->folderToDirectory($name, $folderdir);

	-d $directory or return 0;
	-f "$directory/1" and return 1;  # cheap

	# More thorough search required in case some numbered messages
	# disappeared (lost at fsck or copy?)

	opendir my $dh, $directory or return 0;
	foreach (readdir $dh)
	{	m/^[0-9]+$/ or next;   # Look for filename which is a number.
		closedir $dh;
		return 1;
	}

	closedir $dh;
	0;
}

sub listSubFolders(@)
{	my ($class, %args) = @_;
	my $dir;
	if(ref $class)
	{	$dir   = $class->directory;
		$class = ref $class;
	}
	else
	{	my $folder    = $args{folder}    || '=';
		my $folderdir = $args{folderdir} || $default_folder_dir;
		$dir   = $class->folderToDirectory($folder, $folderdir);
	}

	$args{skip_empty} ||= 0;
	$args{check}      ||= 0;

	# Read the directories from the directory, to find all folders
	# stored here.  Some directories have to be removed because they
	# are created by all kinds of programs, but are no folders.

	-d $dir && opendir my $dh, $dir or return ();
	my @dirs = grep { !/^\d+$|^\./ && -d "$dir/$_" } readdir $dh;
	closedir $dh;

	# Skip empty folders.  If a folder has sub-folders, then it is not
	# empty.
	if($args{skip_empty})
	{	my @not_empty;

		foreach my $subdir (@dirs)
		{	if(-f "$dir/$subdir/1")
			{	# Fast found: the first message of a filled folder.
				push @not_empty, $subdir;
				next;
			}

			opendir my $dh, "$dir/$subdir" or next;
			my @entities = grep !/^\./, readdir $dh;
			closedir $dh;

			if(grep /^\d+$/, @entities)   # message 1 was not there, but
			{	push @not_empty, $subdir; # other message-numbers exist.
				next;
			}

			foreach (@entities)
			{	-d "$dir/$subdir/$_" or next;
				push @not_empty, $subdir;
				last;
			}
		}

		@dirs = @not_empty;
	}

	# Check if the files we want to return are really folders.

	@dirs = map { m/(.*)/ && $1 ? $1 : () } @dirs;   # untaint
	$args{check} or return @dirs;

	grep $class->foundIn("$dir/$_"), @dirs;
}

#-------------

sub topFolderWithMessages() { 1 }


sub appendMessages(@)
{	my $class  = shift;
	my %args   = @_;

	my @messages
	  = exists $args{message}  ? $args{message}
	  : exists $args{messages} ? @{$args{messages}}
	  :   return ();

	my $self     = $class->new(@_, access => 'r')
		or return ();

	my $locker   = $self->locker;
	$locker->lock
		or error __x"cannot append message without lock on {folder}.", folder => $self->name;

	my $msgnr    = $self->highestMessageNumber +1;

	my $directory= $self->directory;
	foreach my $message (@messages)
	{	my $filename = "$directory/$msgnr";
		$message->create($filename);
		$msgnr++;
	}

	$self->labels->append(@messages);
	$self->index->append(@messages);

	$locker->unlock;
	$self->close(write => 'NEVER');

	@messages;
}

#--------------------

sub openSubFolder($)
{	my ($self, $name) = @_;

	my $subdir = $self->nameOfSubFolder($name);
	-d $subdir || mkdir $subdir, 0755
		or fault __x"cannot create directory {dir} for subfolder {name}", dir => $subdir, name => $name;

	$self->SUPER::openSubFolder($name, @_);
}

#--------------------

sub highestMessageNumber()
{	my $self = shift;

	return $self->{MBM_highest_msgnr}
		if exists $self->{MBM_highest_msgnr};

	my $directory = $self->directory;

	opendir my $dh, $directory or return;
	my @messages = sort {$a <=> $b} grep /^[0-9]+$/, readdir $dh;
	closedir $dh;

	$messages[-1];
}


sub index()
{	my $self  = shift;
	$self->{MBM_keep_index} or return ();

	$self->{MBM_index} //= $self->{MBM_index_type}->new(filename => $self->{MBM_index_filename});
}


sub labels()
{	my $self = shift;
	$self->{MBM_labels} //= $self->{MBM_labels_type}->new(filename => $self->{MBM_labels_filename});
}

sub readMessageFilenames
{	my ($self, $dirname) = @_;

	opendir my $dh, $dirname or return;

	# list of numerically sorted, untainted filenames.
	my @msgnrs = sort {$a <=> $b}
		map { /^(\d+)$/ && -f "$dirname/$1" ? $1 : () } readdir $dh;

	closedir $dh;
	@msgnrs;
}

sub readMessages(@)
{	my ($self, %args) = @_;

	my $directory = $self->directory;
	-d $directory or return;

	my $locker    = $self->locker;
	$locker->lock or return;

	my @msgnrs    = $self->readMessageFilenames($directory);

	my $index     = $self->{MBM_index};
	unless($index)
	{	$index = $self->index;
		$index->read if $index;
	}

	my $labels = $self->{MBM_labels};
	unless($labels)
	{	$labels = $self->labels;
		$labels->read if $labels;
	}

	my $body_type   = $args{body_delayed_type};
	my $head_type   = $args{head_delayed_type};

	foreach my $msgnr (@msgnrs)
	{	my $msgfile = "$directory/$msgnr";

		my $head;
		$head       = $index->get($msgfile) if $index;
		$head     ||= $head_type->new;

		my $message = $args{message_type}->new(
			head       => $head,
			filename   => $msgfile,
			folder     => $self,
			fix_header => $self->fixHeaders,
		);

		my $labref  = $labels ? $labels->get($msgnr) : ();
		$message->label(seen => 1, $labref ? @$labref : ());

		$message->storeBody($body_type->new(message => $message));
		$self->storeMessage($message);
	}

	$self->{MBM_highest_msgnr}  = $msgnrs[-1];
	$locker->unlock;
	$self;
}

sub delete(@)
{	my $self = shift;
	$self->SUPER::delete(@_);

	my $dir = $self->directory;
	opendir my $dh, $dir or return 1;
	untaint $dh;

	# directories (subfolders) are not removed, as planned
	unlink "$dir/$_" for readdir $dh;
	closedir $dh;

	rmdir $dir;    # fails when there are subdirs (without recurse)
}



sub writeMessages($)
{	my ($self, $args) = @_;
	my $renumber = exists $args->{renumber} ? $args->{renumber} : 1;

	# Write each message.  Two things complicate life:
	#   1 - we may have a huge folder, which should not be on disk twice
	#   2 - we may have to replace a message, but it is unacceptable
	#       to remove the original before we are sure that the new version
	#       is on disk.

	my $locker    = $self->locker;
	$locker->lock
		or error __x"cannot write folder {name} without lock.", name => $self->name;

	my $directory = $self->directory;
	my @messages  = @{$args->{messages}};

	my $writer    = 0;
	foreach my $message (@messages)
	{	my $filename = $message->filename;

		my $newfile;
		if($renumber || !$filename)
		{	$newfile = $directory . '/' . ++$writer;
		}
		else
		{	$newfile = $filename;
			$writer  = basename $filename;
		}

		$message->create($newfile);
	}

	# Write the labels- and the index-file.

	my $labels = $self->labels;
	$labels->write(@messages) if $labels;

	my $index  = $self->index;
	$index->write(@messages)  if $index;

	$locker->unlock;

	# Remove an empty folder.  This is done last, because the code before
	# in this method will have cleared the contents of the directory.
	# If something else is still in the directory, this will fail, but I don't mind.
	rmdir $directory
		if !@messages && $self->removeEmpty;

	$self;
}

#--------------------

1;

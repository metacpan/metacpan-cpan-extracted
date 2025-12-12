# This code is part of Perl distribution Mail-Box version 4.00.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::Maildir;{
our $VERSION = '4.00';
}

use parent 'Mail::Box::Dir';

use strict;
use warnings;

use Log::Report      'mail-box', import => [ qw/__x error fault info trace/ ];

use Mail::Box::Maildir::Message;

use File::Copy       qw/move/;
use File::Basename   qw/basename/;
use Sys::Hostname    qw/hostname/;
use File::Remove     qw/remove/;

# Maildir is only supported on UNIX, because the filenames probably
# do not work on other platforms.  Since MailBox 2.052, the use of
# File::Spec to create filenames has been removed: benchmarks showed
# that catfile() consumed 20% of the time of a folder open().  And
# '/' file separators work on Windows too!

#--------------------

my $default_folder_dir = exists $ENV{HOME} ? "$ENV{HOME}/.maildir" : '.';

sub init($)
{	my ($self, $args) = @_;

	! exists $args->{locker} && (! defined $args->{lock_type} || $args->{lock_type} eq 'NONE')
		or error __x"no locking possible for maildir folders.";

	$args->{lock_type}   = 'NONE';
	$args->{folderdir} ||= $default_folder_dir;

	$self->SUPER::init($args);

	$self->acceptMessages if $args->{accept_new};
	$self;
}


sub create($@)
{	my ($thingy, $name, %args) = @_;
	my $class     = ref $thingy      || $thingy;
	my $folderdir = $args{folderdir} || $default_folder_dir;
	my $directory = $class->folderToDirectory($name, $folderdir);

	$class->createDirs($directory);
	trace "created folder Maildir $name.";
	$directory;
}

sub foundIn($@)
{	my $class = shift;
	my $name  = @_ % 2 ? shift : undef;
	my %args  = @_;
	my $folderdir = $args{folderdir} || $default_folder_dir;
	my $directory = $class->folderToDirectory($name, $folderdir);

	-d "$directory/cur";
}

sub type() { 'maildir' }

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

	-d $dir && opendir my $dh, $dir
		or return ();

	my @dirs;
	while(my $d = readdir $dh)
	{	next if $d =~ m/^(new|tmp|cur|\.\.?)$/;

		my $dir = "$dir/$d";
		push @dirs, $d if -d $dir;
	}

	closedir $dh;

	# Skip empty folders.

	@dirs = grep !$class->folderIsEmpty("$dir/$_"), @dirs
		if $args{skip_empty};

	# Check if the files we want to return are really folders.

	@dirs = map { m/(.*)/ && $1 } @dirs;  # untaint
	$args{check} or return @dirs;

	grep $class->foundIn("$dir/$_"), @dirs;
}

sub openSubFolder($@)
{	my ($self, $name) = (shift, shift);
	$self->createDirs($self->nameOfSubFolder($name));
	$self->SUPER::openSubFolder($name, @_);
}

sub topFolderWithMessages() { 1 }

my $uniq = rand 1000;


sub coerce($)
{	my ($self, $message) = (shift, shift);

	my $is_native = $message->isa('Mail::Box::Maildir::Message');
	my $coerced   = $self->SUPER::coerce($message, @_);

	my $basename  = $is_native ? basename($message->filename)
	  : ($message->timestamp || time) .'.'. hostname .'.'. $uniq++;

	my $dir = $self->directory;
	$coerced->create("$dir/tmp/$basename");
	my $new = $coerced->create("$dir/new/$basename");

	trace "Added Maildir message in $new";
	$coerced->labelsToFilename unless $is_native;
	$coerced;
}

#--------------------

sub createDirs($)
{	my ($thing, $dir) = @_;

	-d $dir || mkdir $dir
		or fault __x"cannot create Maildir folder directory {dir}", dir => $dir;

	foreach my $sub (qw/tmp new cur/)
	{	my $subdir = "$dir/$sub";
		-d $subdir || mkdir $subdir
			or fault __x"cannot create Maildir folder subdir {dir}", dir => $subdir;
	}

	$thing;
}


sub folderIsEmpty($)
{	my ($self, $dir) = @_;
	return 1 unless -d $dir;

	foreach my $sub (qw/tmp new cur/)
	{	my $subdir = "$dir/$sub";
		-d $subdir or next;

		opendir my $dh, $subdir or return 0;
		my $first  = readdir $dh;
		closedir $dh;

		return 0 if defined $first;
	}

	opendir my $dh, $dir or return 1;
	while(my $entry = readdir $dh)
	{	next if $entry =~ m/^(?:tmp|cur|new|bulletin(?:time|lock)|seriallock|\..?)$/;
		closedir $dh;
		return 0;
	}

	closedir $dh;
	1;
}

sub delete(@)
{	my $self = shift;

	# Subfolders are not nested in the directory structure
	remove \1, $self->directory;
}

sub readMessageFilenames
{	my ($self, $dirname) = @_;

	opendir my $dh, $dirname or return ();

	my @files;
	if(${^TAINT})
	{	# unsorted list of untainted filenames.
		@files = map +(m/^([0-9][\w.:,=\-]+)$/ && -f "$dirname/$1" ? $1 : ()), readdir $dh;
	}
	else
	{	# not running tainted
		@files = grep m/^([0-9][\w.:,=\-]+)$/ && -f "$dirname/$1", readdir $dh;
	}
	closedir $dh;

	# Sort the names.  Solve the Y2K (actually the 1 billion seconds
	# since 1970 bug) which hunts Maildir.  The timestamp, which is
	# the start of the filename will have some 0's in front, so each
	# timestamp has the same length.

	my %unified;
	m/^(\d+)/ and $unified{ ('0' x (10-length($1))).$_ } = $_
		for @files;

	map "$dirname/$unified{$_}", sort keys %unified;
}

sub readMessages(@)
{	my ($self, %args) = @_;

	my $directory = $self->directory;
	-d $directory or return;

	#
	# Read all messages
	#

	my $curdir  = "$directory/cur";
	my @cur     = map +[$_, 1], $self->readMessageFilenames($curdir);

	my $newdir  = "$directory/new";
	my @new     = map +[$_, 0], $self->readMessageFilenames($newdir);

	foreach (@cur, @new)
	{	my ($filename, $accepted) = @$_;
		my $message = $args{message_type}->new(
			head      => $args{head_delayed_type}->new,
			filename  => $filename,
			folder    => $self,
			fix_header=> $self->fixHeaders,
			labels    => [ accepted => $accepted ],
		);

		my $body    = $args{body_delayed_type}->new(message => $message);
		$message->storeBody($body) if $body;
		$self->storeMessage($message);
	}

	$self;
}


sub acceptMessages($)
{	my ($self, %args) = @_;
	my @accept = $self->messages('!accepted');
	$_->accept foreach @accept;
	@accept;
}


sub writeMessages($)
{	my ($self, $args) = @_;

	# Write each message.  Two things complicate life:
	#   1 - we may have a huge folder, which should not be on disk twice
	#   2 - we may have to replace a message, but it is unacceptable
	#       to remove the original before we are sure that the new version
	#       is on disk.

	my $writer    = 0;

	my $directory = $self->directory;
	my @messages  = @{$args->{messages}};

	my $tmpdir    = "$directory/tmp";
	-d $tmpdir || mkdir $tmpdir
		or fault __x"cannot create directory {dir}", dir => $tmpdir;

	foreach my $message (@messages)
	{	$message->isModified or next;

		my $filename = $message->filename;
		my $basename = basename $filename;

		my $newtmp   = "$directory/tmp/$basename";
		open my $new, '>:raw', $newtmp
			or fault __x"cannot create file {file}", file => $newtmp;

		$message->write($new);
		close $new;

		unlink $filename;
		move $newtmp, $filename
			or fault __x"cannot rename {from} to {to}", from => $newtmp, to => $filename;
	}

	# Remove an empty folder.  This is done last, because the code before
	# in this method will have cleared the contents of the directory.

	if(!@messages && $self->removeEmpty)
	{	# If something is still in the directory, this will fail, but I
		# don't mind.
		rmdir "$directory/cur";
		rmdir "$directory/tmp";
		rmdir "$directory/new";
		rmdir $directory;
	}

	$self;
}


sub appendMessages(@)
{	my $class  = shift;
	my %args   = @_;

	my @messages
	  = exists $args{message}  ?   $args{message}
	  : exists $args{messages} ? @{$args{messages}}
	  :    return ();

	my $self     = $class->new(@_, access => 'a');
	my $directory= $self->directory;
	-d $directory or return;

	my $tmpdir   = "$directory/tmp";
	-d $tmpdir || mkdir $tmpdir
		or fault __x"cannot create directory {dir}", dir => $tmpdir;

	my $msgtype  = $args{message_type} || 'Mail::Box::Maildir::Message';

	foreach my $message (@messages)
	{	my $is_native = $message->isa($msgtype);
		my ($basename, $coerced);

		if($is_native)
		{	$coerced  = $message;
			$basename = basename $message->filename;
		}
		else
		{	$coerced  = $self->SUPER::coerce($message);
			$basename = ($message->timestamp||time).'.'. hostname.'.'.$uniq++;
		}

		my $dir = $self->directory;
		$coerced->create("$dir/tmp/$basename");
		my $new = $coerced->create("$dir/new/$basename");
		trace "Appended Maildir message in $new";
	}

	$self->close;
	@messages;
}

#--------------------

1;

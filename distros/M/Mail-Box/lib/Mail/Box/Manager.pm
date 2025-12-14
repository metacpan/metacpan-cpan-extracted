# This code is part of Perl distribution Mail-Box version 4.01.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::Manager;{
our $VERSION = '4.01';
}

use parent 'Mail::Reporter';

use strict;
use warnings;

use Log::Report  'mail-box', import => [ qw/__x error info trace warning/ ];

use Mail::Box    ();

use List::Util   qw/first/;
use Scalar::Util qw/weaken blessed/;

# failed compilation will not complain a second time
# so we need to keep track.
my %require_failed;

#--------------------

my @basic_folder_types = (
	[ mbox    => 'Mail::Box::Mbox'    ],
	[ mh      => 'Mail::Box::MH'      ],
	[ maildir => 'Mail::Box::Maildir' ],
	[ pop     => 'Mail::Box::POP3'    ],
	[ pop3    => 'Mail::Box::POP3'    ],
	[ pops    => 'Mail::Box::POP3s'   ],
	[ pop3s   => 'Mail::Box::POP3s'   ],
	[ imap    => 'Mail::Box::IMAP4'   ],
	[ imap4   => 'Mail::Box::IMAP4'   ],
	[ imaps   => 'Mail::Box::IMAP4s'  ],
	[ imap4s  => 'Mail::Box::IMAP4s'  ],
);

my @managers;  # usually only one, but there may be more around :(

sub init($)
{	my ($self, $args) = @_;
	$self->SUPER::init($args);

	# Register all folder-types.  There may be some added later.

	my @new_types;
	if(my $ft = $args->{folder_types})
	{	@new_types = ref($ft->[0]) eq 'ARRAY' ? @$ft : $ft;
	}

	my @basic_types = reverse @basic_folder_types;
	if(my $basic = $args->{autodetect})
	{	my %types = map +($_ => 1), ref $basic ? @$basic : $basic;
		@basic_types = grep $types{$_->[0]}, @basic_types;
	}

	$self->{MBM_folder_types} = [];
	$self->registerType(@$_) for @new_types, @basic_types;

	$self->{MBM_default_type} = $args->{default_folder_type} || 'mbox';

	# Inventory on existing folder-directories.
	my $fd = $self->{MBM_folderdirs} = [ ];
	if(exists $args->{folderdir})
	{	my @dirs = $args->{folderdir};
		@dirs = @{$dirs[0]} if ref $dirs[0] eq 'ARRAY';
		push @$fd, @dirs;
	}

	if(exists $args->{folderdirs})
	{	my @dirs = $args->{folderdirs};
		@dirs = @{$dirs[0]} if ref $dirs[0];
		push @$fd, @dirs;
	}
	push @$fd, '.';

	$self->{MBM_folders} = [];
	$self->{MBM_threads} = [];

	push @managers, $self;
	weaken $managers[-1];

	$self;
}

#--------------------

sub registerType($$@)
{	my ($self, $name, $class, @options) = @_;
	unshift @{$self->{MBM_folder_types}}, [$name, $class, @options];
	$self;
}


sub folderdir()
{	my $dirs = shift->{MBM_folderdirs} or return ();
	wantarray ? @$dirs : $dirs->[0];
}


sub folderTypes()
{	my $self = shift;
	my %uniq;
	$uniq{$_->[0]}++ for $self->folderTypeDefs;
	sort keys %uniq;
}


sub defaultFolderType()
{	my $self = shift;
	my $name = $self->{MBM_default_type};
	return $name if $name =~ m/\:\:/;  # obviously a class name

	foreach my $def ($self->folderTypeDefs)
	{	return $def->[1] if $def->[0] eq $name || $def->[1] eq $name;
	}

	undef;
}


sub threads(@) { my $self = shift; @_ ? $self->discoverThreads(@_) : @{$self->{MBM_threads}} }


sub folderTypeDefs() { @{$_[0]->{MBM_folder_types}} }

#--------------------

sub open(@)
{	my $self = shift;
	my $name = @_ % 2 ? shift : undef;
	my %args = @_;

	$args{authentication} ||= 'AUTO';
	$name  //= defined $args{folder} ? $args{folder} : ($ENV{MAIL} || '');

	if($name =~ m/^(\w+)\:/ && grep $_ eq $1, $self->folderTypes)
	{	# Complicated folder URL
		my %decoded = $self->decodeFolderURL($name);
		keys %decoded
			or error __x"illegal folder URL '{name}'.", name => $name;

		# accept decoded info
		@args{keys %decoded} = values %decoded;
	}
	else
	{	# Simple folder name
		$args{folder} = $name;
	}

	# Do not show password in folder name
	my $type = $args{type};
	   if(!defined $type) { ; }
	elsif($type eq 'pop3' || $type eq 'pop')
	{	my $un   = $args{username}    ||= $ENV{USER} || $ENV{LOGIN};
		my $srv  = $args{server_name} ||= 'localhost';
		my $port = $args{server_port} ||= 110;
		$args{folderdir} = $name = "pop3://$un\@$srv:$port";
	}
	elsif($type eq 'pop3s' || $type eq 'pops')
	{	my $un   = $args{username}    ||= $ENV{USER} || $ENV{LOGIN};
		my $srv  = $args{server_name} ||= 'localhost';
		my $port = $args{server_port} ||= 995;
		$args{folderdir} = $name = "pop3s://$un\@$srv:$port";
	}
	elsif($type eq 'imap4' || $type eq 'imap')
	{	my $un   = $args{username}    ||= $ENV{USER} || $ENV{LOGIN};
		my $srv  = $args{server_name} ||= 'localhost';
		my $port = $args{server_port} ||= 143;
		$args{folderdir} = $name = "imap4://$un\@$srv:$port";
	}
	elsif($type eq 'imap4s' || $type eq 'imaps')
	{	my $un   = $args{username}    ||= $ENV{USER} || $ENV{LOGIN};
		my $srv  = $args{server_name} ||= 'localhost';
		my $port = $args{server_port} ||= 993;
		$args{folderdir} = $name = "imap4s://$un\@$srv:$port";
	}

	defined $name && length $name
		or error __x"no foldername specified to open.";

	$args{folderdir} ||= $self->{MBM_folderdirs}->[0]
		if $self->{MBM_folderdirs};

	$args{access} ||= 'r';

	if($args{create} && $args{access} !~ m/w|a/)
	{	warning __x"will never create a folder {name} without having write access.", name => $name;
		undef $args{create};
	}

	# Do not open twice.
	my $folder = $self->isOpenFolder($name)
		and error __x"folder {name} is already open.", name => $name;

	#
	# Which folder type do we need?
	#

	my ($folder_type, $class, @defaults);
	my @typedefs = $self->folderTypeDefs;
	if($type)
	{	# User-specified foldertype prevails.
		foreach (@typedefs)
		{	(my $abbrev, $class, @defaults) = @$_;

			if($type eq $abbrev || $type eq $class)
			{	$folder_type = $abbrev;
				last;
			}
		}

		$folder_type
			or warning __x"folder type {type} is unknown, using autodetect.", $type => $type;
	}

	unless($folder_type)
	{	# Try to autodetect foldertype.
		foreach (@typedefs)
		{	(my $abbrev, $class, @defaults) = @$_;
			next if $require_failed{$class};

			eval "require $class";
			if($@)
			{	$require_failed{$class}++;
				next;
			}

			if($class->foundIn($name, @defaults, %args))
			{	$folder_type = $abbrev;
				last;
			}
		}
	}

	unless($folder_type)
	{	# Use specified default
		if(my $type = $self->{MBM_default_type})
		{	foreach (@typedefs)
			{	(my $abbrev, $class, @defaults) = @$_;
				if($type eq $abbrev || $type eq $class)
				{	$folder_type = $abbrev;
					last;
				}
			}
		}
	}

	unless($folder_type)
	{	# use first type (last defined)
		($folder_type, $class, @defaults) = @{$typedefs[0]};
	}

	#
	# Try to open the folder
	#

	return if $require_failed{$class};
	eval "require $class";
	if($@)
	{	error __x"failed for folder default {class}: {errors}", class => $class, errors => $@;
		$require_failed{$class}++;
		return ();
	}

	push @defaults, manager => $self;
	$folder = $class->new(@defaults, %args);
	unless(defined $folder)
	{	$args{access} eq 'd'
			or error __x"folder {name} does not exist, failed opening {type}.", type => $folder_type, name => $name;
		return;
	}

	trace "Opened folder $name ($folder_type).";
	push @{$self->{MBM_folders}}, $folder;
	$folder;
}


sub openFolders() { @{ $_[0]->{MBM_folders}} }


sub isOpenFolder($)
{	my ($self, $name) = @_;
	first { $name eq $_->name } $self->openFolders;
}


sub close($@)
{	my ($self, $folder, %options) = @_;
	return unless $folder;

	my $name      = $folder->name;
	my @folders   = $self->openFolders;
	my @remaining = grep $name ne $_->name, @folders;

	# folder opening failed:
	return if @folders == @remaining;

	$self->{MBM_folders} = [ @remaining ];
	$_->removeFolder($folder) for $self->threads;

	$options{close_by_self}
		or $folder->close(close_by_manager => 1, %options);

	$self;
}


sub closeAllFolders(@)
{	my ($self, @options) = @_;
	$_->close(@options) for $self->openFolders;
	$self;
}

END { map defined $_ && $_->closeAllFolders, @managers }

#--------------------

sub delete($@)
{	my ($self, $name, %args) = @_;
	my $recurse = delete $args{recursive};

	my $folder = $self->open(folder => $name, access => 'd', %args)
		or return $self;  # still successful

	$folder->delete(recursive => $recurse);
}

#--------------------

sub appendMessage(@)
{	my $self     = shift;
	my @appended = $self->appendMessages(@_);
	wantarray ? @appended : $appended[0];
}

sub appendMessages(@)
{	my $self = shift;
	my $folder;
	$folder  = shift if ! blessed $_[0] || $_[0]->isa('Mail::Box');

	my @messages;
	push @messages, shift while @_ && blessed $_[0];

	my %options = @_;
	$folder ||= $options{folder};

	# Try to resolve filenames into opened-files.
	$folder = $self->isOpenFolder($folder) || $folder
		unless blessed $folder;

	if(blessed $folder)
	{	# An open file.
		$folder->isa('Mail::Box')
			or error __x"folder {name} is not a Mail::Box; cannot add a message.", name => $folder;

		foreach my $msg (@messages)
		{	$msg->isa('Mail::Box::Message') && $msg->folder or next;
			warning __x"use moveMessage() or copyMessage() to move between open folders.";
		}

		return $folder->addMessages(@messages);
	}

	# Not an open file.
	# Try to autodetect the folder-type and then add the message.

	my ($name, $class, @gen_options, $found);
	my @typedefs = $self->folderTypeDefs;

	foreach (@typedefs)
	{	($name, $class, @gen_options) = @$_;
		next if $require_failed{$class};
		eval "require $class";
		if($@)
		{	$require_failed{$class}++;
			next;
		}

		if($class->foundIn($folder, @gen_options, access => 'a'))
		{	$found++;
			last;
		}
	}

	# The folder was not found at all, so we take the default folder-type.
	my $type = $self->{MBM_default_type};
	if(!$found && $type)
	{	foreach (@typedefs)
		{	($name, $class, @gen_options) = @$_;
			if($type eq $name || $type eq $class)
			{	$found++;
				last;
			}
		}
	}

	# Even the default foldertype was not found (or nor defined).
	($name, $class, @gen_options) = @{$typedefs[0]}
		unless $found;

	$class->appendMessages(
		type     => $name,
		messages => \@messages,
		@gen_options,
		%options,
		folder   => $folder,
	);
}



sub copyMessage(@)
{	my $self   = shift;
	my $folder;
	$folder    = shift if ! blessed $_[0] || $_[0]->isa('Mail::Box');

	my @messages;
	while(@_ && blessed $_[0])
	{	my $message = shift;
		$message->isa('Mail::Box::Message')
			or error __x"use appendMessage() to add messages which are not in a folder.";
		push @messages, $message;
	}

	my %args  = @_;

	$folder ||= $args{folder};
	my $share = exists $args{share} ? $args{share} : $args{_delete};

	# Try to resolve filenames into opened-files.
	$folder   = $self->isOpenFolder($folder) || $folder
		unless blessed $folder;

	unless(blessed $folder)
	{	my @c = $self->appendMessages(@messages, %args, folder => $folder);
		if($args{_delete})
		{	$_->label(deleted => 1) for @messages;
		}
		return @c;
	}

	my @coerced;
	foreach my $msg (@messages)
	{	if($msg->folder eq $folder)  # ignore move to same folder
		{	push @coerced, $msg;
			next;
		}
		push @coerced, $msg->copyTo($folder, share => $args{share});
		$msg->label(deleted => 1) if $args{_delete};
	}
	@coerced;
}



sub moveMessage(@)
{	my $self = shift;
	$self->copyMessage(@_, _delete => 1);
}

#--------------------

sub discoverThreads(@)
{	my $self    = shift;
	my @folders;
	push @folders, shift while @_ && ref $_[0] && $_[0]->isa('Mail::Box');
	my %args    = @_;

	my $base    = 'Mail::Box::Thread::Manager';
	my $type    = $args{threader_type} || $base;

	my $folders = delete $args{folder} || delete $args{folders};
	push @folders, ( !$folders ? () : ref $folders eq 'ARRAY' ? @$folders : $folders );

	my $threads;
	if(blessed $type)   # Already prepared object?
	{	$type->isa($base)
			or error __x"you need to pass a {base} derived threader, got {class}.", base => $base, class => ref $type;
		$threads = $type;
	}
	else
	{	# Create an object.  The code is compiled, which safes us the
		# need to compile Mail::Box::Thread::Manager when no threads are needed.
		eval "require $type";
		$@ and error __x"unusable threader {class}: {errors}", class => $type, errors => $@;

		$type->isa($base)
			or error __x"threader {class} is not derived from {base}.", class => $type, base => $base;

		$threads = $type->new(manager => $self, %args);
	}

	$threads->includeFolder($_) for @folders;
	push @{$self->{MBM_threads}}, $threads;
	$threads;
}

#--------------------

sub toBeThreaded($@)
{	my $self = shift;
	$_->toBeThreaded(@_) for $self->threads;
}


sub toBeUnthreaded($@)
{	my $self = shift;
	$_->toBeUnthreaded(@_) for $self->threads;
}


sub decodeFolderURL($)
{	my ($self, $name) = @_;

	return unless
		my ($type, $username, $password, $hostname, $port, $path)
		= $name =~ m!^
			(\w+) \:                   # protocol
			(?: \/\/
				(?: ([^:@/]* )         # username
					(?: \: ([^@/]*) )? # password
					\@
				)?
				([\w.-]+)?             # hostname
				(?: \: (\d+) )?        # port number
			)?
			(.*)                       # foldername
		!x;

	$username ||= $ENV{USER} || $ENV{LOGNAME};
	$password ||= '';

	for($username, $password)
	{	s/\+/ /g;
		s/\%([A-Fa-f0-9]{2})/chr hex $1/ge;
	}

	$hostname ||= 'localhost';
	$path     ||= '=';

	( type        => $type,     folder      => $path,
	  username    => $username, password    => $password,
	  server_name => $hostname, server_port => $port
	);
}

#--------------------

1;

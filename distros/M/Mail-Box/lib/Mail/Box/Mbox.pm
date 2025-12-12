# This code is part of Perl distribution Mail-Box version 4.00.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::Mbox;{
our $VERSION = '4.00';
}

use parent 'Mail::Box::File';

use strict;
use warnings;

use Log::Report      'mail-box', import => [ qw// ];

use Mail::Box::Mbox::Message ();

use File::Spec::Functions    qw/catdir catfile/;

#--------------------

our $default_folder_dir    = exists $ENV{HOME} ? $ENV{HOME} . '/Mail' : '.';
our $default_sub_extension = '.d';

sub init($)
{	my ($self, $args) = @_;
	$self->{MBM_sub_ext} = $args->{subfolder_extension} || $default_sub_extension;
	$self->SUPER::init($args);
}


sub create($@)
{	my ($thingy, $name, %args) = @_;
	my $class = ref $thingy    || $thingy;
	$args{folderdir}           ||= $default_folder_dir;
	$args{subfolder_extension} ||= $default_sub_extension;

	$class->SUPER::create($name, %args);
}

#--------------------

sub subfolderExtension() { $_[0]->{MBM_sub_ext} }

sub delete(@)
{	my $self = shift;
	$self->SUPER::delete(@_);

	my $subfdir = $self->filename . $default_sub_extension;
	rmdir $subfdir;   # may fail, when there are still subfolders (no recurse)
}

sub writeMessages($)
{	my ($self, $args) = @_;
	$self->SUPER::writeMessages($args);

	if($self->removeEmpty)
	{	# Can the sub-folder directory be removed?  Don't mind if this
		# doesn't work: probably no subdir or still something in it.  This
		# is a rather blunt approach...
		rmdir $self->filename . $self->subfolderExtension;
	}

	$self;
}

sub type() {'mbox'}

#--------------------

sub listSubFolders(@)
{	my ($thingy, %args)  = @_;
	my $class      = ref $thingy || $thingy;

	my $skip_empty = $args{skip_empty} || 0;
	my $check      = $args{check}      || 0;
	my $folder     = $args{folder}     // '=';
	my $folderdir  = $args{folderdir}  // $default_folder_dir;
	my $extension  = $args{subfolder_extension};

	my $dir;
	if(ref $thingy)   # Mail::Box::Mbox
	{	$extension ||= $thingy->subfolderExtension;
		$dir = $thingy->filename;
	}
	else
	{	$extension ||= $default_sub_extension;
		$dir = $class->folderToFilename($folder, $folderdir, $extension);
	}

	my $real  = -d $dir ? $dir : "$dir$extension";
	opendir my $dh, $real or return ();

	# Some files have to be removed because they are created by all
	# kinds of programs, but are no folders.

	my @entries = grep !m/\.lo?ck$|^\./, readdir $dh;
	closedir $dh;

	# Look for files in the folderdir.  They should be readable to
	# avoid warnings for usage later.  Furthermore, if we check on
	# the size too, we avoid a syscall especially to get the size
	# of the file by performing that check immediately.

	my %folders;  # hash to immediately un-double names.

	foreach my $b (@entries)
	{	my $entry = catfile $real, $b;
		if( -f $entry )
		{	next if $args{skip_empty} && ! -s _;
			next if $args{check} && !$class->foundIn($entry);
			$folders{$b}++;
		}
		elsif( -d _ )
		{	# Directories may create fake folders.
			if($args{skip_empty})
			{	opendir my $dh, $entry or next;
				my @sub = grep !/^\./, readdir $dh;
				closedir $dh;
				@sub or next;
			}

			my $folder = $b =~ s/$extension$//r;
			$folders{$folder}++;
		}
	}

	map +(m/(.*)/ && $1), keys %folders;   # untained names
}

sub openRelatedFolder(@)
{	my $self = shift;
	$self->SUPER::openRelatedFolder(subfolder_extension => $self->subfolderExtension, @_);
}

#--------------------

sub folderToFilename($$;$)
{	my ($thingy, $name, $folderdir, $extension) = @_;
	$extension ||= ref $thingy ? $thingy->subfolderExtension : $default_sub_extension;

	$name     =~ s#^=#$folderdir/#;
	my @parts = split m!/!, $name;

	my $real  = shift @parts;
	$real     = '/' if $real eq '';

	if(@parts)
	{	my $file  = pop @parts;
		$real = catdir  $real.(-d $real ? '' : $extension), $_ for @parts;
		$real = catfile $real.(-d $real ? '' : $extension), $file;
	}

	$real;
}


sub foundIn($@)
{	my $class = shift;
	my $name  = @_ % 2 ? shift : undef;
	my %args  = @_;
	$name   ||= $args{folder} or return;

	my $folderdir = $args{folderdir} || $default_folder_dir;
	my $extension = $args{subfolder_extension} || $default_sub_extension;
	my $filename  = $class->folderToFilename($name, $folderdir, $extension);

	if(-d $filename)
	{	# Maildir and MH Sylpheed have a 'new' sub-directory
		return 0 if -d catdir $filename, 'new';
		if(opendir my $dir, $filename)
		{	my @f = grep !/^\./, readdir $dir;   # skip . .. and hidden
			return 0 if @f && ! grep /\D/, @f;              # MH
			closedir $dir;
		}

		return 0                                             # Other MH
			if -f "$filename/.mh_sequences";

		return 1;      # faked empty Mbox sub-folder (with subsub-folders?)
	}

	return 0 unless -f $filename;
	return 1 if -z $filename;               # empty folder is ok

	open my $file, '<:raw', $filename or return 0;
	local $_;
	while(<$file>)
	{	next if /^\s*$/;                    # skip empty lines
		$file->close;
		return substr($_, 0, 5) eq 'From '; # found Mbox separator?
	}

	return 1;
}

#--------------------

1;

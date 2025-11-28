# This code is part of Perl distribution Mail-Box version 3.012.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::Dir;{
our $VERSION = '3.012';
}

use parent 'Mail::Box';

use strict;
use warnings;

use Mail::Box::Dir::Message        ();
use Mail::Message::Body::Lines     ();
use Mail::Message::Body::File      ();
use Mail::Message::Body::Delayed   ();
use Mail::Message::Body::Multipart ();
use Mail::Message::Head            ();
use Mail::Message::Head::Delayed   ();

use Carp;
use File::Spec::Functions           qw/rel2abs/;

#--------------------

sub init($)
{	my ($self, $args)    = @_;

	$args->{body_type} //= sub { 'Mail::Message::Body::Lines' };
	$self->SUPER::init($args) or return undef;

	my $class     = ref $self;
	my $directory = $self->{MBD_directory} = $args->{directory} || $self->directory;

		if(-d $directory) {;}
	elsif($args->{create} && $class->create($directory, %$args)) {;}
	else
	{	$self->log(WARNING => "No directory $directory for folder of $class");
		return undef;
	}

	# About locking

	my $lf = $args->{lock_file} // '.lock';
	$self->locker->filename(rel2abs $lf, $directory);

	# Check if we can write to the folder, if we need to.

	if($self->writable && -e $directory && ! -w $directory)
	{	$self->log(WARNING => "Folder directory $directory is write-protected.");
		$self->access('r');
	}

	$self;
}

#--------------------

sub organization() { 'DIRECTORY' }

#--------------------

sub directory()
{	my $self = shift;
	$self->{MBD_directory} ||= $self->folderToDirectory($self->name, $self->folderdir);
}

sub nameOfSubFolder($;$)
{	my ($thing, $name) = (shift, shift);
	my $parent = @_ ? shift : ref $thing ? $thing->directory : undef;
	defined $parent ? "$parent/$name" : $name;
}

#--------------------

sub folderToDirectory($$)
{	my ($class, $name, $folderdir) = @_;
	my $dir = ($name =~ m#^=\/?(.*)# ? "$folderdir/$1" : $name);
	$dir =~ s!/$!!r;
}

sub storeMessage($)
{	my ($self, $message) = @_;
	$self->SUPER::storeMessage($message);
	my $fn = $message->filename or return $message;
	$self->{MBD_by_fn}{$fn} = $message;
}


sub messageInFile($) { $_[0]->{MBD_by_fn}{$_[1]} }


sub readMessageFilenames() { $_[0]->notImplemented }

1;

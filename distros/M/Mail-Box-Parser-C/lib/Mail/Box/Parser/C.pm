# This code is part of Perl distribution Mail-Box-Parser-C version 3.013.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2002-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


#XXX WARNING: large overlap with Mail::Box::Parser:Perl; you may need to change both!

package Mail::Box::Parser::C;{
our $VERSION = '3.013';
}

use base qw/Mail::Box::Parser DynaLoader/;

our $VERSION = '3.013';

use strict;
use warnings;

use Mail::Message::Field ();

#--------------------

bootstrap Mail::Box::Parser::C $VERSION;

## Defined in the library
sub open_filename($$$);
sub open_filehandle($$$);
sub get_filehandle($);
sub close_file($);
sub push_separator($$);
sub pop_separator($);
sub get_position($);
sub set_position($$);
sub read_header($);
sub fold_header_line($$);
sub in_dosmode($);
sub read_separator($);
sub body_as_string($$$);
sub body_as_list($$$);
sub body_as_file($$$$);
sub body_delayed($$$);

# Not used yet.
#fold_header_line(char *original, int wrap)
#in_dosmode(int boxnr)

#--------------------

sub init(@)
{	my ($self, $args) = @_;
	$self->SUPER::init($args) or return;

	$self->{MBPC_mode}     = $args->{mode} || 'r';
	$self->{MBPC_filename} = $args->{filename} || ref $args->{file}
		or $self->log(ERROR => "Filename or handle required to create a parser."), return;

	$self->start(file => $args->{file});
	$self;
}

#--------------------

sub boxnr() { $_[0]->{MBPC_boxnr} }


sub filename() { $_[0]->{MBPC_filename} }
sub openMode() { $_[0]->{MBPC_mode} }
sub file()     { $_[0]->{MBPC_file} }

#--------------------

sub start(@)
{	my ($self, %args) = @_;
	$self->openFile(%args) or return;
	$self->takeFileInfo;

	$self->log(PROGRESS => "Opened folder ".$self->filename." to be parsed");
	$self;
}


sub stop()
{	my $self = shift;
	$self->log(NOTICE => "Close parser for file ".$self->filename);
	$self->closeFile;
}


sub restart()
{	my $self     = shift;
	$self->closeFile;
	$self->openFile(@_) or return;
	$self->takeFileInfo;
	$self->log(NOTICE => "Restarted parser for file ".$self->filename);
	$self;
}


sub fileChanged()
{	my $self = shift;
	my ($size, $mtime) = (stat $self->filename)[7,9];
	return 0 if !defined $size || !defined $mtime;
	$size != $self->{MBPC_size} || $mtime != $self->{MBPC_mtime};
}


sub filePosition(;$)
{	my $boxnr = shift->boxnr;
	@_ ? set_position($boxnr, shift) : get_position($boxnr);
}


sub takeFileInfo()
{	my $self = shift;
	@$self{ qw/MBPC_size MBPC_mtime/ } = (stat $self->filename)[7,9];
}


sub pushSeparator($)
{	my ($self, $sep) = @_;
	push_separator $self->boxnr, $sep;
}

sub popSeparator()  { pop_separator $_[0]->boxnr }

sub readHeader()    { read_header $_[0]->boxnr }

sub readSeparator() { read_separator $_[0]->boxnr }

sub bodyAsString(;$$)
{	my ($self, $exp_chars, $exp_lines) = @_;
	body_as_string $self->boxnr, $exp_chars // -1, $exp_lines // -1;
}

sub bodyAsList(;$$)
{	my ($self, $exp_chars, $exp_lines) = @_;
	body_as_list $self->boxnr, $exp_chars // -1, $exp_lines // -1;
}

sub bodyAsFile($;$$)
{	my ($self, $file, $exp_chars, $exp_lines) = @_;
	body_as_file $self->boxnr, $file, $exp_chars // -1, $exp_lines // -1;
}

sub bodyDelayed(;$$)
{	my ($self, $exp_chars, $exp_lines) = @_;
	body_delayed $self->boxnr, $exp_chars // -1, $exp_lines // -1;
}


sub openFile(%)
{	my ($self, %args) = @_;
	my %log = $self->logSettings;

	my $boxnr;
	my $name = $args{filename} || $self->filename;

	if(my $file = $args{file})
	{	$boxnr   = open_filehandle($file, $name // "$file", $log{trace});
	}
	else
	{	my $mode = $args{mode} || $self->openMode || 'r';
		$boxnr   = open_filename($name, $mode, $log{trace});
	}

	$self->{MBPC_boxnr} = $boxnr;
	defined $boxnr ? $self : undef;
}

sub closeFile() {
	my $boxnr = delete $_[0]->{MBPC_boxnr};
	defined $boxnr ? close_file $boxnr : ();
}

1;

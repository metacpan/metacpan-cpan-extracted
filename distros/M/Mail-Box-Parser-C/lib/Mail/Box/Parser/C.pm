# This code is part of Perl distribution Mail-Box-Parser-C version 4.00.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2002-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::Parser::C;{
our $VERSION = '4.00';
}

use parent qw/Mail::Box::Parser DynaLoader/;

our $VERSION = '4.00';

use strict;
use warnings;

use Log::Report   'mail-box-parser-c';

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

sub boxnr() { $_[0]->{MBPC_boxnr} }

sub pushSeparator($)
{	my ($self, $sep) = @_;
	push_separator $self->boxnr, $sep;
}

sub popSeparator()  { pop_separator $_[0]->boxnr }

sub filePosition(;$)
{	my $boxnr = shift->boxnr;
	@_ ? set_position($boxnr, shift) : get_position($boxnr);
}

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

sub openFile($)
{	my ($self, $args) = @_;
	my $trace = $args->{trace} || 0;

	my $boxnr;
	if(my $file = $args->{file})
	{	my $name = $args->{filename} || "$file";
		$boxnr   = open_filehandle($file, $name, $trace);
	}
	else
	{	$boxnr   = open_filename($args->{filename}, $args->{mode}, $trace);
	}

	$self->{MBPC_boxnr} = $boxnr;
	defined $boxnr ? $self : undef;
}

sub closeFile() {
	my $boxnr = delete $_[0]->{MBPC_boxnr};
	defined $boxnr ? close_file $boxnr : ();
}

1;

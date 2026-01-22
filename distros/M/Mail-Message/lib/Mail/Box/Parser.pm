# This code is part of Perl distribution Mail-Message version 4.02.
# The POD got stripped from this file by OODoc version 3.06.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2026 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::Parser;{
our $VERSION = '4.02';
}

use parent 'Mail::Reporter';

use strict;
use warnings;

use Log::Report   'mail-message', import => [ qw/__x error/ ];

#--------------------

sub new(@)
{	my $class = shift;

	  $class eq __PACKAGE__
	? $class->defaultParserType->new(@_)   # bootstrap right parser
	: $class->SUPER::new(@_);
}

sub init(@)
{	my ($self, $args) = @_;
	$self->SUPER::init($args);

	$self->{MBP_trusted}  = $args->{trusted};
	$self->{MBP_fix}      = $args->{fix_header_errors};
	$self->{MBP_seps}     = [];
	$self;
}

#--------------------

sub fixHeaderErrors(;$)
{	my $self = shift;
	@_ ? ($self->{MBP_fix} = shift) : $self->{MBPL_fix};
}


sub trusted() { $_[0]->{MBP_trusted} }


my $parser_type;

sub defaultParserType(;$)
{	my $class = shift;

	# Select the parser manually?
	if(@_)
	{	$parser_type = shift;
		return $parser_type if $parser_type->isa( __PACKAGE__ );
		error __x"parser {type} does not extend {pkg}.", type => $parser_type, pkg => __PACKAGE__;
	}

	# Already determined which parser we want?
	$parser_type
		and return $parser_type;

	# Try to use C-based parser.
	eval 'require Mail::Box::Parser::C';
	$@ or return $parser_type = 'Mail::Box::Parser::C';

	# Fall-back on Perl-based parser.
	require Mail::Box::Parser::Perl;
	$parser_type = 'Mail::Box::Parser::Perl';
}

#--------------------

sub readHeader()    { $_[0]->notImplemented }


sub bodyAsString() { $_[0]->notImplemented }


sub bodyAsList() { $_[0]->notImplemented }


sub bodyAsFile() { $_[0]->notImplemented }


sub bodyDelayed() { $_[0]->notImplemented }


sub lineSeparator() { $_[0]->{MBP_linesep} }


sub stop() { }
sub filePosition() { undef }

#--------------------

sub readSeparator() { $_[0]->notImplemented }


sub pushSeparator($)
{	my ($self, $sep) = @_;
	unshift @{$self->{MBP_seps}}, $sep;
	$self->{MBP_strip_gt}++ if $sep eq 'From ';
	$self;
}


sub popSeparator()
{	my $self = shift;
	my $sep  = shift @{$self->{MBP_seps}};
	$self->{MBP_strip_gt}-- if $sep eq 'From ';
	$sep;
}


sub separators()      { $_[0]->{MBP_seps} }
sub activeSeparator() { $_[0]->separators->[0] }
sub resetSeparators() { $_[0]->{MBP_seps} = []; $_[0]->{MBP_strip_gt} = 0 }
sub stripGt           { $_[0]->{MBP_strip_gt} }

#--------------------

#--------------------

1;

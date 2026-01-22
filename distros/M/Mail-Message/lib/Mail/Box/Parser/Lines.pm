# This code is part of Perl distribution Mail-Message version 4.02.
# The POD got stripped from this file by OODoc version 3.06.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2026 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::Parser::Lines;{
our $VERSION = '4.02';
}

use parent 'Mail::Box::Parser';

use strict;
use warnings;

use Log::Report   'mail-message', import => [ qw/__x panic warning/ ];

use Mail::Message::Field   ();

#--------------------

sub init(@)
{	my ($self, $args) = @_;
	$self->SUPER::init($args);

	$self->{MBPL_lines}  = $args->{lines}  or panic "No lines";
	$self->{MBPL_source} = $args->{source} or panic "No source";
	$self;
}

#--------------------

sub lines()  { $_[0]->{MBPL_lines} }
sub source() { $_[0]->{MBPL_source} }

#--------------------

my $is_empty_line = qr/^\015?\012?$/;

sub readHeader()
{	my $self  = shift;
	my $lines = $self->lines;
	my @ret;

  LINE:
	while(@$lines)
	{	my $line = shift @$lines;
		last if $line =~ $is_empty_line;

		my ($name, $body) = split /\s*\:\s*/, $line, 2;

		unless(defined $body)
		{	warning __x"unexpected end of header in {source}:\n {line}", source => $self->source, line => $line;

			if(@ret && $self->fixHeaderErrors)
			{	$ret[-1][1] .= ' '.$line;  # glue err line to previous field
				next LINE;
			}

			unshift @$lines, $line;
			last LINE;
		}

		# Collect folded lines
		$body .= shift @$lines
			while @$lines && $lines->[0] =~ m!^[ \t]!;

		push @ret, [ $name, $body ];
	}

	(undef, undef, @ret);
}

sub _is_good_end()
{	my $self  = shift;

	# No seps, then when have to trust it.
	my $sep = $self->activeSeparator // return 1;

	# Find first non-empty line on specified location.
	my $lines = $self->lines;
	my $skip  = 0;
	while($skip < @$lines && $lines->[$skip] =~ $is_empty_line) { $skip++ }
	$skip < @$lines or return 1;

	my $line = $lines->[$skip];

		substr($line, 0, length $sep) eq $sep
	&& ($sep ne 'From ' || $line =~ m/ (?:19[6-9]|20[0-3])[0-9]\b/ );
}

sub readSeparator()
{	my $self  = shift;
	my $sep   = $self->activeSeparator // return ();
	my $lines = $self->lines;

	my $skip  = 0;
	while($skip < @$lines && $lines->[$skip] =~ $is_empty_line) { $skip++ }

	$skip < @$lines
		or return ();

	my $line  = $lines->[$skip];
	substr($line, 0, length $sep) eq $sep
		or return ();

	splice @$lines, 0, $skip+1;
	(undef, $line);
}

sub _read_stripped_lines(;$$)
{	my ($self, $exp_chars, $exp_lines) = @_;
	my $seps    = $self->separators;
	my $lines   = $self->lines;
	my $take    = [];

	if(@$seps)
	{
	  LINE:
		while(1)
		{	my $line  = shift @$lines or last LINE;

			foreach my $sep (@$seps)
			{	substr($line, 0, length $sep) eq $sep or next;

				# Some apps fail to escape take starting with From
				next if $sep eq 'From ' && $line !~ m/ 19[789][0-9]| 20[0-9][0-9]/;

				unshift @$lines, $line;   # keep separator
				last LINE;
			}

			push @$take, $line;
		}

		if(@$take && $take->[-1] =~ s/\015?\012\z//)
		{	# Keep an empty line to signal the existence of a preamble, but
			# remove a second.
			pop @$take if @$seps==1 && @$take > 1 && length($take->[-1])==0;
		}
	}
	else # File without separators.
	{	$take = $lines;
	}

	if($self->stripGt)
	{	s/^\>(\>*From\s)/$1/ for @$take;
	}

	unless($self->trusted)
	{	s/\015// for @$take;
	}

	$take;
}

sub bodyAsString(;$$)
{	my ($self, $exp_chars, $exp_lines) = @_;
	my $take = $self->_read_stripped_lines($exp_chars, $exp_lines);
	return (undef, undef, join('', @$take));
}

sub bodyAsList(;$$)
{	my ($self, $exp_chars, $exp_lines) = @_;
	my $take = $self->_read_stripped_lines($exp_chars, $exp_lines);
	(undef, undef, $take);
}

sub bodyAsFile($;$$)
{	my ($self, $out, $exp_chars, $exp_lines) = @_;
	my $take = $self->_read_stripped_lines($exp_chars, $exp_lines);
	$out->print($_) for @$take;
	(undef, undef, scalar @$take);
}

1;

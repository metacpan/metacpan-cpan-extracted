package Log::Deep::Line;

# Created on: 2009-05-30 21:19:07
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Carp;
use Readonly;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use base qw/Exporter/;
use Term::ANSIColor;

our $VERSION     = version->new('0.3.5');
our @EXPORT_OK   = qw//;
our %EXPORT_TAGS = ();

Readonly my $LEVEL_COLOURS => {
		info     => '',
		message  => '',
		debug    => '',
		warn  => 'yellow',
		error    => 'red',
		fatal    => 'bold red',
		security => '',
	};

sub new {
	my $caller = shift;
	my $class  = ref $caller ? ref $caller : $caller;
	my ($self, $line, $file) = @_;

	if (ref $self ne 'HASH') {
		$file = $line;
		$line = $self;
		$self = {};
	}

	bless $self, $class;

	$self->parse($line, $file) if $line && $file;

	return $self;
}

sub parse {
	my ($self, $line, $file) = @_;

	# split the line into 5 parts
	# TODO this might cause some problems if the message happens to have a \, in it
	my @log = split /(?<!\\),/, $line, 5;

	if ( @log != 5 && $self->{verbose} ) {
		# get the file name and line number
		my $name    = $file->{name};
		my $line_no = $file->{handle}->input_line_number;

		# output the warnings about the bad line
		warn "The log $name line ($line_no) did not contain 4 columns! Got ". (scalar @log) . " columns\n";
		warn $line if $self->{verbose} > 1;
	}

	# un-quote the individual columns
	for my $col (@log) {
		$col =~ s/ \\ \\ /\\/gxms;
		$col =~ s/ (?<!\\) \\n /\n/gxms;
		$col =~ s/ (?<!\\) \\, /,/gxms;
	}

	# re-process the data so we can display what is needed.
	my $DATA;
	if ( $log[-1] =~ /;$/xms && length $log[-1] < 1_000_000 ) {
		local $SIG{__WARN__} = sub {};
		eval $log[-1];  ## no critic
	}
	else {
		warn '' . (length $log[-1] < 1_000_000 ? 'The data is too large to process' : 'There appears to be a problem with the data' ) . ' on line ' . $file->{handle}->input_line_number . "\n";
		$DATA = {};
	}

	$self->{date}    = $log[0];
	$self->{session} = $log[1];
	$self->{level}   = $log[2];
	$self->{message} = $log[3];
	$self->{DATA}    = $DATA;

	$self->{file}     = $file;
	$self->{position} = $file->{handle} ? tell $file->{handle} : 0;

	return $self;
}

sub id { $_[0]->{session} };

sub colour {
	my ($self, $colour) = @_;

	if ($colour) {
		my ($foreground, $background) = $colour =~ /^ ( \w+ ) \s+ on_ ( \w+ ) $/xms;
		$self->{fg} = $foreground;
		$self->{bg} = $background;
	}

	return "$self->{fg} on_$self->{bg}";
}

sub show {
	my ($self) = @_;

	# TODO add real filtering body here
	return 0 if !$self->{date} || !$self->{session};

	return 1;
}

sub text {
	my ($self) = @_;
	my $out = '';

#	my $last = $self->{last_line_time} || 0;
#	my $now  = time;
#
#	# check if we are putting line breaks when there is a large time between followed file output
#	if ( $self->{breaks} && $now > $last + $self->{short_break} ) {
#		my $lines = $now > $last + $self->{long_break} ? $self->{long_lines} : $self->{short_lines};
#		$out .= "\n" x $lines;
#	}
#	$self->{last_line_time} = $now;

	# construct the log line determining colours to use etc
	my $level = $self->{mono} ? $self->{level} : colored $self->{level}, $LEVEL_COLOURS->{$self->{level}};
	$out .= $self->{mono} ? '' : color $self->colour();
	$out .= "[$self->{date}]";

	if ( !$self->{verbose} ) {
		# add the session id if the user cares
		$out .= " $self->{session}";
	}
	if ( !$self->{mono} ) {
		# reset the colour if we are not in mono
		$out .= color 'reset';
	}

	# finish constructing the log line
	$out .= " $level - $self->{message}\n";

	return $out;
}

sub data {
	my ($self) = @_;
	my $display = $self->{display};
	my @fields;
	my @out;
	my $data = $self->{DATA};

	$display->{data} = defined $display->{data} ? $display->{data} : 1;

	# check for any fields that should be displayed
	FIELD:
	for my $field ( sort keys %{ $display } ) {
		push @out,
			  $display->{$field} eq 0                                      ? ()
			: !defined $data->{$field}                                     ? data_missing($field, $data)
			: ref $display->{$field} eq 'ARRAY' || $display->{$field} ne 1 ? data_sub_fields($field, $data->{$field})
			: !ref $data->{$field}                                         ? data_scalar($field, $data->{$field})
			: $field ne 'data' || %{ $data->{$field} }                     ? $self->{dump}->Names($field)->Data($data->{$field})->Out()
			:                                                                ();
	}

	return @out;
}

sub data_missing {
	my ( $self, $field, $data ) = @_;
	return if ref $field;
	return if $field eq 'data';
	return "\$$field = " . (exists $data->{field} ? 'undef' : 'missing') . "\n";
}

sub data_sub_fields {
	my ( $self, $field, $data ) = @_;
	my $display = $self->{display};
	my @out;

	# select the specified sub keys of $field
	if ( !ref $display->{$field} ) {
		# convert the display field into an array so that we can select it's sub fields
		$display->{$field} = [ split /,/, $display->{$field} ];
	}

	# out put each named sub field of $field
	for my $sub_field ( @{ $display->{$field} } ) {
		push @out, $self->{dump}->Names( $field . '_' . $sub_field )->Data( $data->{$sub_field} )->Out();
	}

	return @out;
}

sub data_scalar {
	my ( $self, $field, $data ) = @_;

	# out put scalar values with out the DDS formatting
	my $out .= "\$$field = " . ( defined $data ? $data : 'undef' );

	# safely guarentee that there is a new line at the end of this line
	chomp $out;
	$out .= "\n";
	return $out;
}

1;

__END__

=head1 NAME

Log::Deep::Line - Encapsulates one line from a log file

=head1 VERSION

This documentation refers to Log::Deep::Line version 0.3.5.

=head1 SYNOPSIS

   use Log::Deep::Line;

   # create a new line object
   my $line = Log::Deep::Line->new( { show => {}, ... }, $line_text, $file );

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head3 C<new ( $options, $line, $file )>

Param: C<$options> - hash ref - Configuration options for this line

Param: C<$line> - string - The original text of the log line

Param: C<$file> - Log::Deep::File - Object continuing the log file of interest

Return: Log::Deep::Line - New log deep object

Description: Create a new object from a line (C<$line>) of the log file (C<$file>)

=head3 C<parse ( $line, $file )>

Param: C<$line> - string - The original text of the log line

Param: C<$file> - Log::Deep::File - Object continuing the log file of interest

Description: Parses the log line

=head3 C<id ( )>

Return: The session id for this log line

Description: Gets the session id for the log line. Will be undef if the log
line did not parse correctly.

=head3 C<colour ( [ $colour ] )>

Param: C<$colour> - string - A string containing the foreground and background
colour to use for this line. The format is 'I<colour> on_I<colour>'.

Return: string - The colour set for this log line

Description: Gets the current colour for this log line and optionally sets the
colour.

=head3 C<show ( )>

Return: bool - True if the log line should be shown.

Description: Determines if the log line should be shown.

=head3 C<text ( )>

Return: The processed text of the line (sans the DATA section).

Description: Processes log line for out putting to a terminal.

=head3 C<data ( )>

Return: The contents of the DATA section as specified by the display option

Description: Out puts the DATA section of the log line.

=head3 C<data_missing ($field, $data)>

Param: C<$field> - string - The name of the field of data

Param: C<$data> - any - All the data

Return: Array - all the lines to be out put

Description: Returns that there was no data or that the data was undefined

=head3 C<data_sub_fields ($field, $data)>

Param: C<$field> - string - The name of the field of data

Param: C<$data> - any - The data being displayed

Return: Array - all the lines to be out put

Description: Shows only the sub keys of $data that are defined to be displayed

=head3 C<data_scalar ($field, $data)>

Param: C<$field> - string - The name of the field of data

Param: C<$data> - any - The data being displayed

Return: Array - all the lines to be out put

Description: Just shows the simple data

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut

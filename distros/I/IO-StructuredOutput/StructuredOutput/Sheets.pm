package IO::StructuredOutput::Sheets;

use 5.00503;
use strict;

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);

use Carp qw(croak);
use Text::CSV_XS;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use test1 ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
%EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw(
	
);

$VERSION = sprintf "%d.%03d", q$Revision: 1.8 $ =~ /(\d+)/g;

# Preloaded methods go here.

sub addsheet
{
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $attr = shift;
	my $name = $attr->{name} || 'Sheet';
	my $format = $attr->{format} || 'html';
	my $default_style = $attr->{style};
	my $wb = $attr->{wb} || "";

	if ($format eq 'csv')
	{
		my $csv = Text::CSV_XS->new();
		my $newsheet = { ws => "", name => $name, format => $format, style => $default_style, csv => $csv };
		bless $newsheet, $class;
		return $newsheet;
	} elsif ($format eq 'html') {
		# we'll be encapsulating the output w/ <TABLE> && </TABLE> when
		# output is requested, so no need to do anything here
		my $newsheet = { ws => "", name => $name, format => $format, style => $default_style };
		bless $newsheet, $class;
		return $newsheet;
	} elsif ($format eq 'xls') {
		my $ws = $wb->add_worksheet($name);
		my $newsheet = { ws => $ws, name => $name, format => $format, style => $default_style };
		bless $newsheet, $class;
		return $newsheet;
	} else {
		croak "invalid or missing format";
	}
}

sub name
{
	ref(my $self = shift) or croak "instance variable needed";
	# can't change name once set (limit of excel module)
#	croak "instance isn't a sheet object" unless ($self->isa("Sheet"));
	return $self->{name};
}

sub sheet
{
	ref(my $self = shift) or croak "instance variable needed";
	return $self->{ws};
}

sub addrow
{
	ref(my $self = shift) or croak "instance variable needed";

	return unless (ref(@_[0]) eq 'ARRAY');	# need to pass in some data to add
	my $data = shift;
	my $styles = shift;
	my $style = $styles ? $styles : $self->{style};

	my $format = $self->format();	# cut down on method calls
	if ($format eq 'csv')
	{
		my @row;
		for (my $i = 0; $i < @{$data}; $i++)
		{
			my $column = $data->[$i];
#			my $thisstyle = ref($style) ? $style->[$i] : $style;
#			$thisstyle = $self->{style} unless ($thisstyle);
			
			# column may also be an array ref, indicating data spanning
			# multiple columns. csv doesn't support that, but we'll
			# handle it anyway.
			if (ref($column) eq 'ARRAY')
			{
#				push(@row, shift(@{$column}) );
				push(@row,@{$column});
			} elsif (ref($column)) {
				# skip. Hash and subroutine referances not supported
			} else {
				push(@row,$column);
			}
		}
		$self->{csv}->combine(@row);
		$self->{ws} .= $self->{csv}->string() . "\n";
		$self->{rowcount}++;
	} elsif ($format eq 'html') {
		my $row;
		for (my $i = 0; $i < @{$data}; $i++)
		{
			my $column = $data->[$i];
			my $thisstyle = (ref($style) eq 'ARRAY') ? $style->[$i] : $style;
			$thisstyle = $self->{style} unless ($thisstyle);
			# column may also be an array ref, indicating data spanning
			# multiple columns.
			if (ref($column) eq 'ARRAY')
			{
				$row .= $thisstyle->output_style($column->[0], scalar(@{$column}) );
			} elsif (ref($column)) {
				# skip. Hash and subroutine referances not supported
			} else {
				$row .= $thisstyle->output_style($column);
			}
		}
		$self->{ws} .= "<TR>\n" . $row . "</TR>\n";
		$self->{rowcount}++;
	} elsif ($format eq 'xls') {
		$self->{rowcount}++;
		my $row = ($self->{rowcount} - 1);
		my $col = 0;
		for (my $i = 0; $i < @{$data}; $i++)
		{
			my $column = $data->[$i];
			my $thisstyle = (ref($style) eq 'ARRAY') ? $style->[$i] : $style;
			$thisstyle = $self->{style} unless ($thisstyle);
			# column may also be an array ref, indicating data spanning
			# multiple columns.
			if (ref($column) eq 'ARRAY')
			{
				my $span = scalar(@{$column});
				$self->{ws}->merge_range($row,$col,$row,($col + $span - 1),$column->[0], $thisstyle->output_style() );
				$col += $span;
			} elsif (ref($column)) {
				# skip. Hash and subroutine referances not supported
			} else {
				$self->{ws}->write($row,$col,$column,$thisstyle->output_style() );
				$col++;
			}
		}
	} else {
		croak "invalid or missing format";
	}
}

sub setwidth
{
	ref(my $self = shift) or croak "instance variable needed";
	if ($self->format() eq 'xls')
	{	# setting width of a column currently only supported in xls
		my $first_column = shift;
		my $second_column = shift;
		my $width = shift;
		$self->{ws}->set_column($first_column,$second_column,$width);
	}
}

sub freeze_panes
{
	ref(my $self = shift) or croak "instance variable needed";
	if ($self->format() eq 'xls')
	{	# this thing will never be supported in html or csv
		# but I needed it for some excel output.
		# see Spreadsheet::WriteExcel for docs
		my @args = @_;
		$self->{ws}->freeze_panes(@_);
	}
}

sub rowcount
{
	ref(my $self = shift) or croak "instance variable needed";
	return $self->{rowcount};
}

sub format
{
	ref(my $self = shift) or croak "instance variable needed";
	return $self->{format};
}

1;
__END__

=head1 NAME

Sheets - Perl extension to IO::StructuredData to handle pages/sheets in an IO::STructuredOutput object.

=head1 SYNOPSIS

  use IO::StructuredOutput::Sheets;

  ### See IO::StructuredOutput for details

=head1 DESCRIPTION

This class implements objects to create pages/sheets for IO::StructuredOutput objects.

=head2 EXPORT

None by default.

=head1 SEE ALSO

IO::StructuredOutput

=head1 AUTHOR

Joshua I. Miller E<lt>jmiller@purifieddata.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Joshua I. Miller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

package IO::StructuredOutput;


# I think I need to create a worksheet package, that this will inherit from.
# the worksheet will have most of the shit in it.
# I don't know how of if that'll work, but I can't figure out any way
# to make this work right now.
# I should make some test modules to do something similar to what I want,
# but just stick to one output or something.

use 5.00503;
use strict;
use Carp qw(croak);
use Spreadsheet::WriteExcel;
use IO::Scalar;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

require Exporter;
use IO::StructuredOutput::Sheets;
use IO::StructuredOutput::Styles;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use IO::StructuredOutput ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
%EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw(
	
);

#$VERSION = do { my @r = (q$Revision: 1.8 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker
$VERSION = sprintf '%d.%03d', q$Revision: 1.8 $ =~ /(\d+)/g;

# valid output formats
my %valid_output_format = (
	'html'	=> 1,
	'csv'	=> 1,
	'xls'	=> 1
	);

# Preloaded methods go here.

sub new
{
	my $proto = shift;
	my $class = ref($proto) || $proto;
#	ref(my $class = shift) and croak "class name needed";
	my $self = {
		Format	=> 'html',	# default format
		Sytle	=> '',
		wb   	=> "",
		Sheets	=> [ ]
		};
	bless $self, $class;
}

sub addsheet
{
	ref(my $self = shift) or croak "instance variable needed";
	my $sheetnum = $_[0] || "";
	$sheetnum =~ s/[:*?\/\\]//g;	# get rid of invalid chars
	if ( ($self->format() eq 'xls') && (length($sheetnum) > 31) )
	{	# max length for excel is 31 chars
		$sheetnum = substr($sheetnum,0,31);
	}
	my $sheetcount = $self->sheetcount();
	unless ($sheetnum)
	{
		$sheetnum = "Sheet " . ($sheetcount + 1);
	}
	if ($self->sheetnames($sheetnum))
	{	# name already in use
		croak "Sheet '$sheetnum' already exists";
	}

	$self->add_sheetname($sheetnum);

	my $wb;
	if ( ($self->format() eq 'xls') && (! ref($self->{wb})) )
	{	# need to create a workbook if we haven't already
		my $datablob;
		$self->{wb} = Spreadsheet::WriteExcel->new( IO::Scalar->new_tie(\$datablob) );
		$self->{datablob} = \$datablob;
#	} elsif ( ($self->format() eq 'html') && (! ref($self->{wb})) ){
#		# first sheet added.
#		# may need to do something here
	}

	# need to setup the default style if we haven't already
	if (! $self->defaultstyle())
	{
		$self->{Style} = $self->addstyle();
	}

	my $sheet = IO::StructuredOutput::Sheets->addsheet(
					{
						name	=> $sheetnum,
						format	=> $self->format(),
						style	=> $self->defaultstyle(),
						wb   	=> $self->{wb} } );
	push( @{ $self->{Sheets} }, $sheet);
	return $sheet;
}

sub output
{
	ref(my $self = shift) or croak "instance variable needed";
	# need to do this still
	my $format = $self->format();
	if ($format eq 'csv')
	{	# zip up all "sheets", return zip file
		my $zip = Archive::Zip->new();
		foreach my $sheet ($self->sheets())
		{
			my $member = $zip->addString($sheet->sheet(),$sheet->name());
			$member->desiredCompressionMethod( COMPRESSION_DEFLATED );
		}
		my $zipfile;
		my $zipfh = IO::Scalar->new(\$zipfile);
		$zip->writeToFileHandle( $zipfh );
		return \$zipfile;
	} elsif ($format eq 'html') {
		my $output;
		foreach my $sheet ($self->sheets())
		{
 			$output .= "<HR><B>" . $sheet->name() . 
			           "</B><BR>\n<TABLE BORDER=1>\n";
			$output .= $sheet->sheet();
			$output .= "</TABLE>\n<BR>\n";
		}
		return \$output;
	} elsif ($format eq 'xls') {
		$self->{wb}->close;
		return $self->{datablob};
	}
}

sub format
{	# set output format
	ref(my $self = shift) or croak "instance variable needed";
	if (@_)
	{   # are there any more parameters? (it's a setter)
		my $newformat = shift;
		if ($self->_valid_output_format($newformat))
		{	# it's a valid format, set it
			$self->{Format} = $newformat;
			return $self->{Format};
		} else {
			# invalid output format, return undef
			return;
		}
	} else { # no, it's a getter:
		return $self->{Format};
	}
}

sub defaultstyle
{
	ref(my $self = shift) or croak "instance variable needed";
	if (@_)
	{   # are there any more parameters? (it's a setter)
		my $info = shift;
		$self->{Style} = $self->addstyle($info);
		return $self->{Style};
	} else {
		return $self->{Style};
	}
}

sub addstyle
{
	ref(my $self = shift) or croak "instance variable needed";
	my $info = shift;

	if ( ($self->format() eq 'xls') && (! ref($self->{wb})) )
	{	# need to create a workbook if we haven't already
		my $datablob;
		$self->{wb} = Spreadsheet::WriteExcel->new( IO::Scalar->new_tie(\$datablob) );
		$self->{datablob} = \$datablob;
	}

	my $wbformat;
	if ($self->format() eq 'xls')
	{
		$wbformat = $self->{wb}->add_format();
	}

	my $style = IO::StructuredOutput::Styles->addstyle(
					{
						format	=> $self->format(),
						wbformat => $wbformat,
						wb => $self->{wb}
					} );
	# if they gave us some params, set them up for them
	$style->modify($info) if $info;

	# give them the style object back
	return $style;
}

sub sheetnames
{
	ref(my $self = shift) or croak "instance variable needed";
	if ($_[0])
	{
		return 1 if ($self->{Sheetnames}{$_[0]});
		return;
	} else {
		return keys %{ $self->{Sheetnames} };
	}
}

sub add_sheetname
{
	ref(my $self = shift) or croak "instance variable needed";
	if ($_[0])
	{
		$self->{Sheetnames}{$_[0]}++;
	}
}

sub _valid_output_format
{	# internal method. Can be useful from the outside, but &format
	# already checks this, and they should be using that anyway
	my $either = shift;
	if (ref($either))
	{	# called from instance
		my $testformat = shift;
		return $valid_output_format{$testformat};
	} else {
		return $valid_output_format{$either};
	}
}

sub sheets
{	# returns an array of all sheet objects
	ref(my $self = shift) or croak "instance variable needed";
	return @{ $self->{Sheets} };
}

sub sheetcount
{
	ref(my $self = shift) or croak "instance variable needed";
	return scalar(@{ $self->{Sheets} });
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

IO::StructuredOutput - Perl OO extension to ease creation of structured data output (html tables, csv files, excel spreadsheets, etc)

=head1 SYNOPSIS

  use IO::StructuredOutput;
  my $io_so = IO::StructuredOutput->new;
  $io_so->format('xls'); # or 'html' or 'csv'

  # optionally setup some styles
  $io_so->defaultstyle( { bold => 1,
                          font => 'arial',
                          underline => 1 } );
  my $style_italic = $io_so->addstyle( { italic => 1 } );
  my $style_align = $io_so->addstyle( { align => 'right',
                                        bg_color => '24#AAAAAA',
                                        color => '25#FF0000' } );

  my $ws = $io_so->addsheet('some title');
  my $number_of_sheets_currently = $io_so->sheetcount();
  my $current_sheet_name = $ws->name();

  my $ws2 = $io_so->addsheet('new page');

  # add row with default styles
  $ws->addrow( ['some data','another cell','etc'] );

  # add row, with one cell that spans multiple columns
  $ws->addrow( [ ['data that spans 2 cells/columns',''], 'third cell'] );

  # set the style for the whole row
  $ws2->addrow( ['data','in','the','other','sheet'], $style_italic );

  # different style for each cell (undef to use default style)
  $ws2->addrow( ['more','data','in','this','sheet'],
                [$style_italic, $style_align, undef,
                 $style_italic, $style_align ] );

  my $rows_added_to_first_sheet = $ws->rowcount();

  my $output = $io_so->output();

=head1 ABSTRACT

IO::StructuredOutput provides a high level abstraction from creating output that is formatted in a structured way (like in tables). Currently, excel, csv, and html table output are supported.

  csv data is returned in a zip archive
  xls data is returned as an excel spreadsheet
  html data is returned as plain text w/ html formatting
  
=head1 DESCRIPTION

Provides a high level abstraction from creating output that is formatted in a structured way (like in tables). Currently, excel, csv, and html table output are supported.

=head2 REQUIRES

    IO::Scalar
    Spreadsheet::WriteExcel
    Archive::Zip
    Text::CSV_XS

=head2 EXPORT

None.

=head1 METHODS

=over

=item C<$io_so = IO::StructuredOutput-E<gt>new;>

This creates a new IO::StructuredOutput object.

=item C<$io_so-E<gt>format( $output_format );>

Sets the output format for this instance. Valid output formats are 'html', 'csv', or 'xls', for HTML, Comma Separated Values files in a Zip archive, or an Excel spreadsheet respectively.  Defaults to 'html'.

MUST be called before any other methods if using anything but 'html'.

=item C<$io_so-E<gt>defaultstyle( \%options );>

This method sets the default style for the output. For 'csv' format, it's basically ignored. Uses the same options as addstyle().

=item C<$style = $io_so-E<gt>addstyle( \%options );>

Create a new Style object.
The following options are supported:

=over

=item C<font =E<gt> $fontname>

$fontname can be anything you want, but it's suggested you use font names that will likely be available on the end users systems, such as 'arial', 'helvetica', 'Times New Roman', etc.

=item C<size =E<gt> $fontsize>

$fontsize should be an integer value.

=item C<bg_color =E<gt> "$index#$hex">

=item C<color =E<gt> "$index#$hex">

B<bg_color> set's the cells background color.

B<color> set's the font color.

$index should be a number between 8 and 63 inclusively (a limit imposed by excel output). For each unique color passed into an IO::StructuredOutput instance, a unique index number should be used. The index is ignored in csv and html output formats.

$hex should consist of three 2 character hex numbers (ie. FFFFFF for white, or 000000 for black). Order is red, green, blue.

=item C<bold =E<gt> $bool>

=item C<italic =E<gt> $bool>

=item C<underline =E<gt> $bool>

=item C<num_format =E<gt> $bool>

=item C<text_wrap =E<gt> $bool>

=item C<border =E<gt> $bool>

Set to true (1) to turn option on, or false (0) to turn if off.

B<num_format>, B<text_wrap>, and B<border> are currently only effective under the 'xls' format.

=item C<align =E<gt> $horizontal_alignment>

Sets the alignment of text in the cells.
'horizontal alignment' should be one of 'center','left', or 'right'

=item C<valign =E<gt> $vertical_alignment>

Sets the alignment of text in the cells.
'vertical alignment' should be one of 'top','center', or 'bottom'

=back

=item C<$ws = $io_so-E<gt>addsheet($title);>

Creates a new Sheet object.
Adds a new page/sheet/file/table as appropriate for the format being used.
$title is optional, but if supplied it must be unique the the IO::StructuredOutput instance, and will be truncated to 31 characters (a limit of Excel spreadsheets).

=item C<$number_of_sheets_currently = $io_so-E<gt>sheetcount();>

Returns the current number of pages/sheets/files/tables in the document.

=item C<$current_sheet_name = $ws-E<gt>name();>

Returns the name (title) of the sheet object.

=item C<$ws-E<gt>addrow( \@data );>

=item C<$ws-E<gt>addrow( \@data, $style );>

=item C<$ws-E<gt>addrow( \@data, \@styles );>

=item C<$ws-E<gt>addrow( [$data1, [$data_for_two_columns,undef] ], \@styles );>

Adds a row of cells to the page/sheet.

Each element of \@data represents one cell column that will be filled in.

If an item in \@data is an array referance, the first element of that array referance will be used to fill a cell that spans as many columns as there are elements in that array referance. In other words, the resulting row from the last example above would consist of the first column being filled with $data1, and $data_for_two_columns filling a cell that spans the two columns next to it.

If $style option is a scalar, that style will be applied to every cell in that row.

If $style is an array referance, it must contain the same number of elements as the \@data passed in.  $style->[0] will be applied the the data in the first cell which will be filed with the data from $data->[0].

=item C<$rows_added_to_first_sheet = $ws-E<gt>rowcount();>

Returns the number of rows added to that Sheet object.

=item C<$output = $io_so-E<gt>output();>

=over

=item *

Build the datafile, and returns a referance to it.

=item *

It can be accessed by dereferancing it, like so:

=over

=item C<print $$output;>

=back

=item *

A document of 'xls' format will return an Excel document.

=item *

A document of 'html' format will return an HTML page (without header|footer) as a scalar variable of plain text.

=item *

A document of 'csv' format will return a Zip file consisting of one file (with it's name set to the $title of the page) for each page added.

=back

=back

=head1 SEE ALSO

 IO::Scalar
 Spreadsheet::WriteExcel
 Archive::Zip
 Text::CSV_XS

=head1 AUTHOR

Josh Miller, E<lt>jmiller@purifieddata.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Josh Miller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

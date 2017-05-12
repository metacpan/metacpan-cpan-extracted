#!/usr/bin/perl

# this creates a simple document with each format supported

use strict;
use IO::StructuredOutput;

foreach my $format ( ('csv','xls','html') )
{
	print "working on format: $format\n";
	my $io_so = IO::StructuredOutput->new;
	$io_so->format($format); # or 'html' or 'csv'

	# try to setup a default style
	$io_so->defaultstyle( { bold => 1, font => 'arial', underline => 1 } );
	my $style_italic = $io_so->addstyle( { italic => 1 } );
	my $style_align = $io_so->addstyle( { align => 'right', bg_color => '24#AAAAAA', color => '25#FF0000' } );
	
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
	$ws2->addrow( ['data','in','the','other','sheet'], [$style_italic, $style_align, undef, $style_italic, $style_align ] );
	
	my $rows_added_to_first_sheet = $ws->rowcount();
	
	my $output = $io_so->output();
	
	# this is because csv output comes to us in a zip file
	my $fileextension = ($format eq 'csv') ? 'csv.zip' : $format;

	open(OUT,"> test.$fileextension");
	binmode(OUT);
	print OUT $$output;
	close(OUT);
}

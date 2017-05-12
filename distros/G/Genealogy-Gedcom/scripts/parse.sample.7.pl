#!/usr/bin/env perl

use open qw(:std :utf8);
use strict;
use warnings;

use File::Slurper qw/read_lines write_text/;

use HTML::TreeBuilder;

# ----------------------------------------------

my($input_file)  = 'data/GEDCOMANSELTable.xhtml';
my($output_file) = 'data/sample.7.ged';
my($root)        = HTML::TreeBuilder -> new();
my($content)     = join("\n", read_lines($input_file) );
my($result)      = $root -> parse_content($content);
my(@table)       = $root -> look_down(_tag => 'table');
my($count)       = 0;
my($rin)         = 0;

my($line);
my($s, @stack);

push @stack, <<EOS;
0 HEAD
1   SOUR Genealogy::Gedcom
2     NAME Genealogy::Gedcom
2     VERS V 1.00
2     CORP Ron Savage
3       ADDR Box 3055
4         STAE Vic
4         POST 3163
4         CTRY Australia
3       EMAIL ron\@savage.net.au
3       WWW http://savage.net.au
2     DATA Sample
1   NOTE
2     CONT This file is based on test data from the web site of Tamura Jones.
2     CONT The data is the UTF-8 equivalent of the ANSEL data on this page:
2     CONT http://www.tamurajones.net/GEDCOMANSELTable.xhtml
1   GEDC
2     VERS 5.5.1-5
1   DATE 15 Nov 2015
1   CHAR UTF-8
EOS

for my $table_count (0, 1)
{
	for my $td ($table[$table_count] -> look_down(_tag => 'td') )
	{
		$count++;

		$s = $td -> as_text || '-';

		if ($count == 5)
		{
			$rin++;

			$line = "0 \@$rin\@ INDI\n1   NAME $s ";
		}
		elsif ($count == 6)
		{
			$line  .= "/$s/\n";
			$count = 0;

			push @stack, $line;
		}
	}
}

$root -> delete();

push @stack, '0 TRLR';

write_text($output_file, join("\n", @stack), 'utf-8', 0);

#!/usr/bin/env perl

use strict;
use warnings;

use File::Slurper 'read_lines';

use Genealogy::Gedcom::Date;

# ------------------------------------------------

sub process
{
	my($parser, $file_name) = @_;

	print "Processing $file_name. \n";

	my(%count) = (dates => 0, errors => 0);
	my($lines) = [map{s/^\s+//; s/\s+$//; $_} read_lines($file_name)];

	for my $i (0 .. $#$lines)
	{
		if ($$lines[$i] =~ /^\d+\s+DATE\s+(.+)$/)
		{
			$count{dates}++;

			$parser -> parse(date => $1);

			if ($parser -> error)
			{
				$count{errors}++;

				print "Error at line @{[$i + 1]}: ", $parser -> error;
			}
		}
	}

	print "Lines  in file: @{[$#$lines + 1]}. Dates: $count{dates}. Errors: $count{errors}. \n";

} # End of process.

# ------------------------------------------------

my($parser) = Genealogy::Gedcom::Date -> new;

process($parser, 'data/royal.ged');
process($parser, 'data/sample.1.ged');
process($parser, 'data/sample.2.ged');
process($parser, 'data/sample.3.ged');
process($parser, 'data/sample.4.ged');
process($parser, 'data/sample.5.ged');
process($parser, 'data/sample.6.ged');
process($parser, 'data/sample.7.ged');

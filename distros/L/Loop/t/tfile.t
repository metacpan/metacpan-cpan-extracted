#!/usr/local/bin/perl

use Test::More tests => 3;
BEGIN { use_ok('Loop') };

use warnings;
use strict;

use Data::Dumper;

# create a file, and write some known text into it.

my $filename = $0.'.txt';

print "creating file '$filename' so that I can read it later\n";

open(my $out, '>'.$filename) or die "Error: could not open $filename for write";

print $out <<'BLOCK';

Once upon a midnight dreary, while I
pondered, weak and weary, Over
many a quaint and curious volume of
forgotten lore- While I nodded,
nearly napping, suddenly there came
a tapping, As of some one gently
rapping, rapping at my chamber
door. "'T is some visitor," I muttered,
"tapping at my chamber door- Only
this and nothing more."

BLOCK
;

close($out) or die "Error: could not close $filename after writing";

#########################################################################
# Loop through the file and return lines that a keyword in them.
# this will test line number, line string, and map function.
# (pick a keyword that occurs in multiple lines)
#########################################################################
my $keyword = 'and';

my @grep = Loop::File $filename, sub
	{	
	my ($number,$line)=@_;
	chomp($line);

	if($line =~ m{$keyword})
		{ return ($number .": ".$line); }
	else
		{return;}

	};

my @exp_grep = 
	(
          '3: pondered, weak and weary, Over',
          '4: many a quaint and curious volume of',
          '11: this and nothing more."'
	);

is_deeply(\@grep,\@exp_grep,"Loop::File linenum, value, map");

#########################################################################
# Get just the first match. This will test 'last' flow control
#########################################################################

my @first;
Loop::File $filename, sub
	{	
	my ($number,$line)=@_;
	chomp($line);

	if($line =~ m{$keyword})
		{
		push(@first,$number .": ".$line);
		$_[-1]='last';
		}
	};

my @exp_first = 
	(
          '3: pondered, weak and weary, Over',
	);

is_deeply(\@first,\@exp_first,"Loop::File 'last' control flow, non-mapping");






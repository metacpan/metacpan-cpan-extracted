#!/usr/bin/env perl

use strict;
use utf8;
use warnings;
use warnings qw(FATAL utf8);	   # Fatalize encoding glitches.
use open qw(:std :utf8);	   # Undeclared streams in UTF-8.
use charnames qw(:full :short);	# Unneeded in v5.16.

use File::Spec;
use File::Temp;

use GraphViz2;

use Test::More;

# ------------------------------------------------

# The EXLOCK option is for BSD-based systems.

my($temp_dir)	= File::Temp -> newdir('temp.XXXX', CLEANUP => 1, EXLOCK => 0, TMPDIR => 1);
my($count)		= 0;
my($GraphViz2)	= GraphViz2->new
(
	im_meta => {URL => 'http://savage.net.au/maps/demo.4.html'}
);
my(%methods)	=
(
	add_node => { id => 1, args => { name => 'TestNode1', label => 'n1' } },
	add_edge => { id => 2, args => { from => 'TestNode1', to	=> '' } },
	default_subgraph  => { id => 3, args => {} },
	escape_some_chars => { id => 4, args => { $GraphViz2, "abc123[]()" } },
	push_subgraph =>
	{
		id   => 5,
		args =>
		{
			name  => 'subgraph_test',
			edge  => {},
			graph => { bgcolor => 'grey', label => 'subgraph_test' }
		}
	},
	pop_subgraph => { id => 6,  args => {} },
	report_valid_attributes => { id => 7,  args => {} },
	run_map =>
	{
		id => 8,
		subname => 'run',
		args =>
		{
			format => 'png',
			output_file => File::Spec -> catfile($temp_dir, 'test_more_run_map.png'),
			im_output_file => File::Spec -> catfile($temp_dir, 'test_more_run_map.map'),
			im_format => 'cmapx',
		},
	},
	run_mapless =>
	{
		id => 9,
		subname => 'run',
		args =>
		{
			format => 'png',
			output_file => File::Spec -> catfile($temp_dir, 'test_more_run_mapless.png'),
		},
	},
);

foreach my $sub ( sort { $methods{$a}{id} <=> $methods{$b}{id} } keys %methods )
{
	my($subname) = defined $methods{$sub}{'subname'} ? $methods{$sub}{'subname'} : $sub;

	# Check we can call this function/method/sub.

	$count++;

	can_ok( $GraphViz2, $subname );

	$count++;

	ok
	(
		$GraphViz2->$subname( %{ $methods{$sub}{'args'} } ),
		"Run $subname with -> "
		  . join(", ", map { "$_:$methods{$sub}{'args'}{$_}" } keys %{ $methods{$sub}{'args'} })
	);
}

done_testing($count);

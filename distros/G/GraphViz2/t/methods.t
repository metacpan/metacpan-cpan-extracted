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
my $GraphViz2	= GraphViz2->new(
	im_meta => {URL => 'http://savage.net.au/maps/demo.4.html'}
);
my @methods	= (
	[ add_node => { args => [ name => 'TestNode1', label => 'n1' ] } ],
	[ add_edge => { args => [ from => 'TestNode1', to	=> '' ] } ],
	[ default_subgraph  => { } ],
	[ escape_some_chars => { args => [ "abc123[]()" ] } ],
	[ push_subgraph => {
		args => [
			name  => 'subgraph_test',
			edge  => {},
			graph => { bgcolor => 'grey', label => 'subgraph_test' }
		]
	} ],
	[ pop_subgraph => { } ],
	[ valid_attributes => { } ],
	[ run_map => {
		subname => 'run',
		args => [
			format => 'png',
			output_file => File::Spec -> catfile($temp_dir, 'test_more_run_map.png'),
			im_output_file => File::Spec -> catfile($temp_dir, 'test_more_run_map.map'),
			im_format => 'cmapx',
		],
	} ],
	[ run_mapless => {
		subname => 'run',
		args => [
			format => 'png',
			output_file => File::Spec -> catfile($temp_dir, 'test_more_run_mapless.png'),
		],
	} ],
);

foreach my $tuple ( @methods ) {
        my ($sub, $data) = @$tuple;
	my $subname = $data->{subname} // $sub;
	can_ok( $GraphViz2, $subname );
	ok
		$GraphViz2->$subname( @{ $data->{args} || [] } ),
		"Run $subname with -> " . ((explain $data->{args})[0] || '')
		;
}

done_testing;

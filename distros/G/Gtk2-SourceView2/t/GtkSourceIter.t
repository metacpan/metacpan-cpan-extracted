#!/usr/bin/perl

use strict;
use warnings;

use Gtk2::TestHelper tests => 24;

use FindBin;
use lib "$FindBin::Bin";
use my_helper;
use Test::Builder;

use Glib qw(TRUE FALSE);
use Gtk2::SourceView2;

exit tests();


sub tests {
	test_search();
	return 0;
}


sub test_search {
	my $buffer = get_buffer();
	
	my @results;
	my $start = $buffer->get_start_iter;
	
	# Forward search from the start
	@results = Gtk2::SourceView2::Iter->forward_search($start, "Atreus", [ 'text-only' ]);
	is_text_at(
		[ @results ],
		{
			start_line   => 4,
			start_offset => 43,
			end_line     => 4,
			end_offset   => 49,
		},
		"Forward search"
	);

	
	# Forward search from the start for a non existing word
	@results = Gtk2::SourceView2::Iter->forward_search($start, "Homer", [ 'text-only' ]);
	is_text_at(
		[ @results ],
		undef,
		"Forward search not found"
	);


	# Multi line
	@results = Gtk2::SourceView2::Iter->forward_search(
		$start, "a\nprey to Dogs", [ 'text-only', 'case-insensitive' ]
	);
	is_text_at(
		[ @results ],
		{
			start_line   => 2,
			start_offset => 61,
			end_line     => 3,
			end_offset   => 12,
		},
		"Forward search multi-line"
	);



	my $end = $buffer->get_end_iter;
	# Look backwards for a word that's not there
	@results = Gtk2::SourceView2::Iter->backward_search($end, "Homer", [ 'text-only' ]);
	is_text_at(
		[ @results ],
		undef,
		"Backward search not found"
	);
	
	# Look backwards for a word
	@results = Gtk2::SourceView2::Iter->backward_search($end, "Achilles", [ ]);
	is_text_at(
		[ @results ],
		{
			start_line   => 5,
			start_offset => 10,
			end_line     => 5,
			end_offset   => 18,
		},
		"Backward search for Achilles"
	);
	
	# Look forwards for the same word as before
	@results = Gtk2::SourceView2::Iter->forward_search($start, "Achilles", [ ]);
	is_text_at(
		[ @results ],
		{
			start_line   => 0,
			start_offset => 30,
			end_line     => 0,
			end_offset   => 38,
		},
		"Forward search for Achilles"
	);
}


sub is_text_at {
	my ($iters, $positions, $message) = @_;
	my ($start, $end) = @{ $iters };

	my $tester = Test::Builder->new();
	
	if ($start && $positions) {
		$tester->is_num($start->get_line, $positions->{start_line}, "$message (start line)");
		$tester->is_num($start->get_line_offset, $positions->{start_offset}, "$message (start offset)");
	}
	else {
		$tester->ok(! defined $start, "Start line for undef");
		$tester->ok(! defined $positions, "Start offset for undef");
	}
	
	if ($end && $positions) {
		$tester->is_num($end->get_line, $positions->{end_line}, "$message (end line)");
		$tester->is_num($end->get_line_offset, $positions->{end_offset}, "$message (end offset)");
	}
	else {
		$tester->ok(! defined $end, "$message (end line for undef)");
		$tester->ok(! defined $positions, "$message (end offset for undef)");
	}
}


sub get_buffer {
	my $buffer = Gtk2::SourceView2::Buffer->new(undef);
	$buffer->set_text(<<'__ILLIAD__');
Sing, O goddess, the anger of Achilles son of Peleus, that
brought countless ills upon the Achaeans. Many a brave soul did
it send hurrying down to Hades, and many a hero did it yield a
prey to dogs and vultures, for so were the counsels of Jove
fulfilled from the day on which the son of Atreus, king of men,
and great Achilles, first fell out with one another.
__ILLIAD__

	return $buffer;
}

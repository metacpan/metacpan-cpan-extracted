#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use utf8;

use FindBin qw($Bin);
use JSON::PP ();

use Locale::Simple;

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw( output failure_output todo_output );

# The sprintf of the translation functions, row by row, from the shared
# t/data/sprintf.json: "rows" hold the conversions, flags, width, precision and
# N$ position of mo-reader.md §5 that every runtime meets, "perl_python_rows"
# the * width or precision, the # flag and i, E, g and G on top. A placeholder
# without an argument stays as it is, extra arguments are ignored, and neither
# warns. python/test.py runs the same rows.

my $vectors = do {
	open my $fh, '<:raw', $Bin.'/data/sprintf.json' or die 'sprintf.json: '.$!;
	local $/;
	JSON::PP->new->utf8->decode(<$fh>);
};
my @rows = ( @{ $vectors->{rows} }, @{ $vectors->{perl_python_rows} } );

l_nolocales(1);

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

# Called through a reference, so the scraper of t/50 reads no msgid here.
my $translate = \&l;
for my $row (@rows) {
	is( $translate->( $row->{format}, @{ $row->{args} } ), $row->{want}, 'sprintf '.$row->{format} );
}

is_deeply( \@warnings, [], 'missing and extra arguments give no warning' );

done_testing;

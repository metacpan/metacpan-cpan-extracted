#!/usr/bin/env perl

use 5.010;
use warnings;
use strict;
use English qw( -no_match_vars );

use Data::RenderAsTree;

use Marpa::R2;

# ------------------------------------------------

die "Usage: $0 grammar input" if scalar @ARGV != 2;
my $grammar_file = do { local $RS = undef; open my $fh, q{<}, $ARGV[0]; my $file = <$fh>; close $fh; \$file };
my $input_file = do { local $RS = undef; open my $fh, q{<}, $ARGV[1]; my $file = <$fh>; close $fh; \$file };
my $slg = Marpa::R2::Scanless::G->new( { source => $grammar_file, bless_package => 'MarpaX::Grammar::Parser' } );
my $slr = Marpa::R2::Scanless::R->new( { grammar => $slg } );

$slr->read($input_file);

my($renderer) = Data::RenderAsTree -> new
	(
		attributes       => 0,
		max_key_length   => 100,
		max_value_length => 100,
		title            => 'Marpa value()',
		verbose          => 0,
	);
my($output) = $renderer -> render($slr -> value);

print join("\n", @$output), "\n";

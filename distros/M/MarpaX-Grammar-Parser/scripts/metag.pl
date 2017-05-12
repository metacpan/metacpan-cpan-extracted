#!/usr/bin/env perl

use 5.010;
use warnings;
use strict;
use English qw( -no_match_vars );

use Data::TreeDumper; # For DumpTree().

use Marpa::R2;

# ------------------------------------------------

die "usage: $0 grammar input" if scalar @ARGV != 2;
my $grammar_file = do { local $RS = undef; open my $fh, q{<}, $ARGV[0]; my $file = <$fh>; close $fh; \$file };
my $input_file = do { local $RS = undef; open my $fh, q{<}, $ARGV[1]; my $file = <$fh>; close $fh; \$file };
my $slg = Marpa::R2::Scanless::G->new( { source => $grammar_file, bless_package => 'MarpaX::Grammar::Parser::Dummy' } );
my $slr = Marpa::R2::Scanless::R->new( { grammar => $slg } );

$slr->read($input_file);

say DumpTree
(
	$slr -> value,
	$ARGV[1], # Title is input bnf file name.
	#DISPLAY_OBJECT_TYPE  => 0, # Suppresses class names.
	DISPLAY_ROOT_ADDRESS => 1,
	#NO_PACKAGE_SETUP    => 1,  # Does nothing for me.
	NO_WRAP              => 1,
);

# ------------------------------------------------

package MarpaX::Grammar::Parser::Dummy;

sub new
{
	return {};
}

1;

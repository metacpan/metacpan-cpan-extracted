#!perl

use strict;
use warnings;

use Test::Most;    # plan is down at bottom

my $deeply = \&eq_or_diff;

use Lingua::Awkwords::Subpattern;
use Lingua::Awkwords::String;

my $picker = Lingua::Awkwords::Subpattern->new( pattern => 'V' );
my @vowels = map { $picker->render } 1 .. 30;
my %uniq;
@uniq{@vowels} = ();
$deeply->( \%uniq, { a => undef, i => undef, u => undef } );

# these must be key => arrayref pairs; update_pattern is more flexible
isa_ok( Lingua::Awkwords::Subpattern->set_patterns( X => ['x'] ),
    'Lingua::Awkwords::Subpattern' );

$picker = Lingua::Awkwords::Subpattern->new( pattern => 'X' );
is( $picker->render, 'x' );

# ref form
isa_ok( Lingua::Awkwords::Subpattern->update_pattern( X => ['y'] ),
    'Lingua::Awkwords::Subpattern' );

# prior to 0.03 the target would be looked up from patterns on each call
# so would differ following an update_pattern or set_patterns call; in
# 0.03 and onwards expect the original
is( $picker->render, 'x' );
$picker = Lingua::Awkwords::Subpattern->new( pattern => 'X' );
is( $picker->render, 'y' );

# list form
Lingua::Awkwords::Subpattern->update_pattern( X => 'z' );
is( $picker->render, 'y' );
$picker = Lingua::Awkwords::Subpattern->new( pattern => 'X' );
is( $picker->render, 'z' );

# this is certainly not a new or dare I say Neo test...
dies_ok { $picker->pattern('there is no spoon') } 'unknown pattern';

ok( Lingua::Awkwords::Subpattern->is_pattern('X'), 'X exists' );
ok( !Lingua::Awkwords::Subpattern->is_pattern('there is no spoon'), 'spoon' );

dies_ok { Lingua::Awkwords::Subpattern->update_pattern('D') };
dies_ok { Lingua::Awkwords::Subpattern->update_pattern( D => undef ) };

# patterns within patterns, where the value is not just a simple string;
# in 0.01 of this module this would instead return something like
# Lingua::Awkwords::String=HASH(0x7f...)
my $pattern = Lingua::Awkwords::String->new( string => 'pattern' );

Lingua::Awkwords::Subpattern->update_pattern( P => $pattern );
$picker = Lingua::Awkwords::Subpattern->new( pattern => 'P' );
is( $picker->render, 'pattern' );

plan tests => 14;

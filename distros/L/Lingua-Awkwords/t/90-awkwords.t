#!perl
#
# and finally the main module itself

use strict;
use warnings;

use Test::Most;    # plan is down at bottom

my $deeply = \&eq_or_diff;

use Lingua::Awkwords;
use Lingua::Awkwords::Subpattern;

my $la = Lingua::Awkwords->new;

dies_ok { $la->render };
dies_ok { $la->walk };

$la->pattern(q{ aaa });
is( $la->render, 'aaa' );

$la = Lingua::Awkwords->new( pattern => q{ V/catC } );
my @findings;
$la->walk(
    sub {
        my $self = shift;
        push @findings, ref $self;
    }
);

$deeply->(
    [ map { s/Lingua::Awkwords:://r } @findings ],
    # TODO ListOf with a single choice could be replaced with that
    # single choice, to simplify the tree
    #   /     LHS    V          RHS    "cat"  C
    [qw{OneOf ListOf Subpattern ListOf String Subpattern}]
);

# ->walk on subtrees attached to a parent parse tree to confirm subtrees
# are properly modified through a ->walk done on the parent
{
    Lingua::Awkwords::Subpattern->set_patterns(
        O => 'x',
        P => 'a',
    );

    my $subtree1 = Lingua::Awkwords->parse_string(q{ OP^xa });
    isa_ok( $subtree1, 'Lingua::Awkwords::ListOf' );

    my $subtree2 = Lingua::Awkwords->parse_string(q{ y/b^y^b });
    isa_ok( $subtree2, 'Lingua::Awkwords::OneOf' );

    $subtree1->walk( Lingua::Awkwords::set_filter('xxx') );
    is( $subtree1->render, 'xxx' );

    $subtree2->walk( Lingua::Awkwords::set_filter('yyy') );
    is( $subtree2->render, 'yyy' );

    Lingua::Awkwords::Subpattern->update_pattern( J => $subtree1 );
    Lingua::Awkwords::Subpattern->update_pattern( K => $subtree2 );

    $la->pattern(q{ JK });
    $la->walk( Lingua::Awkwords::set_filter('z') );

    # OP -> z and y|b also now -> z
    is( $la->render, 'zz' );
}

plan tests => 9;

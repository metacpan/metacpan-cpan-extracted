#!perl
#
# and finally the main module itself

use strict;
use warnings;

use Test::Most;    # plan is down at bottom

my $deeply = \&eq_or_diff;

use Lingua::Awkwords qw(weights2str weights_from);
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

# corpus to weight utility routines
{
    my $expected = [
        { d => 1, k => 1, b => 3, m => 1, g => 1 },
        {   t => 1,
            a => 2,
            r => 2,
            u => 1,
            b => 1,
            e => 1,
            c => 1,
            k => 1,
            d => 1,
            v => 1
        },
        { u => 2, o => 3, a => 1, e => 1 },
        {   e => 2,
            g => 1,
            c => 1,
            k => 2,
            v => 1,
            d => 2,
            r => 2,
            a => 3,
            o => 3,
            t => 1,
            m => 1,
            u => 3,
            b => 4
        }
    ];

    my ( $first, $mid, $last, $all ) =
      Lingua::Awkwords::weights_from("do mutce bo barda gerku bo kavbu");
    $deeply->( [ $first, $mid, $last, $all ], $expected );

    open my $fh, '<', 't/phrase' or die "t/phrase not found: $!\n";
    ( $first, $mid, $last, $all ) = Lingua::Awkwords::weights_from($fh);
    $deeply->( [ $first, $mid, $last, $all ], $expected );

    Lingua::Awkwords::percentize($last);
    # tape over any floating point differences between platforms
    for my $v ( values %$last ) {
        $v = sprintf "%.1f", $v;
    }
    $deeply->( $last, { a => 14.3, e => 14.3, o => 42.9, u => 28.6 } );

    is( weights2str( ( weights_from("toki sin li toki pona") )[-1] ),
        'a*1/i*4/k*2/l*1/n*2/o*3/p*1/s*1/t*2' );
}

plan tests => 13;

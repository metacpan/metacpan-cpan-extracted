#!perl
#
# Food::Ratio tests

use 5.26.0;
use Test2::V0;
use Food::Ratio;

my $fr = Food::Ratio->new;

like dies { $fr->add( undef, 'egg' ) },      qr/mass must be positive/;
like dies { $fr->add( 'li vo re', 'egg' ) }, qr/mass must be positive/;
like dies { $fr->add( -1, 'egg' ) },         qr/mass must be positive/;
like dies { $fr->add( 42, undef ) },         qr/things must be something/;
like dies { $fr->add( 42, '' ) },            qr/things must be something/;
like dies { $fr->add( 42, 'egg', undef ) },  qr/groups must be something/;
like dies { $fr->add( 42, 'egg', '' ) },     qr/groups must be something/;

# there are simpler ways to make cornmeal muffins, but the things we do
# for science...
for my $ref (
    [qw(160 cornmeal flour dry)],    # ~1 cup to grams
    [qw(150 flour flour dry)],       # ~1 cup
    [qw(11 bpowder dry)],            # 1 tablespoon
    [qw(3.5 salt dry)],
    [qw(30 sugar dry)],    # 1/4 cup loose packed
    [qw(250 milk wet)],    # 2% reduced fat, so oil percent is a bit higher
    [qw(70 oil fat wet)],
    [qw(58 egg wet)],      # 1x jumbo
) {
    $fr->add( $ref->@* );
}

like dies { $fr->ratio( id    => undef ) },       qr/id must be something/;
like dies { $fr->ratio( id    => '' ) },          qr/id must be something/;
like dies { $fr->ratio( id    => "'Iwghargh" ) }, qr/no such id/;
like dies { $fr->ratio( group => undef ) },       qr/group must be something/;
like dies { $fr->ratio( group => '' ) },          qr/group must be something/;
like dies { $fr->ratio( group => "'Iwghargh" ) }, qr/no such group/;

my $s = $fr->ratio->string;
# PORTABILITY may need to sprintf more things if that .5 is troublesome?
like $s, qr/732.5\t100%\t\*total/;

# SYNOPSIS code
my $bread = Food::Ratio->new;
$bread->add( 500,  'flour' );
$bread->add( 360,  'water' );
$bread->add( 11.5, 'salt' );
$bread->add( 2,    'yeast' );
like dies { $bread->details },   qr/ratio has not been called/;
like dies { $bread->string },    qr/ratio has not been called/;
like dies { $bread->weigh(42) }, qr/ratio has not been called/;

$bread->ratio( id => 'flour' );

#diag $bread->string;
$s = $bread->string;
like $s, qr/2\t0.4%\tyeast/;

like dies { $bread->weigh(undef) },      qr/mass must be positive/;
like dies { $bread->weigh('li vo re') }, qr/mass must be positive/;
like dies { $bread->weigh(-1) },         qr/mass must be positive/;
like dies { $bread->weigh( 42, id => undef ) },       qr/id must be something/;
like dies { $bread->weigh( 42, id => '' ) },          qr/id must be something/;
like dies { $bread->weigh( 42, id => "'Iwghargh" ) }, qr/no such id/;
like dies { $bread->weigh( 42, group => undef ) }, qr/group must be something/;
like dies { $bread->weigh( 42, group => '' ) },    qr/group must be something/;
like dies { $bread->weigh( 42, group => "'Iwghargh" ) }, qr/no such group/;

# double the yeast...
$bread->weigh( 4, id => 'yeast' );
$s = $bread->string;
like $s, qr/1000\t100%\tflour/;
#diag $bread->string;

# redo the ratio with a new key NOTE this breaks the expected ratios
# away from the Baker's Percentage
$bread->ratio;
$s = $bread->string;
like $s, qr/100%\t\*total/;

my $simple = Food::Ratio->new;
$simple->add( 1, 'egg', 'food' );
$simple->add( 3, 'water', 'food', 'notegg' );
$simple->ratio( group => 'food' );
$simple->weigh( 100, group => 'food' );
my $ref = $simple->details;
is $ref,
  { groups => [
        {   mass  => 100,
            name  => 'food',
            order => 0,
            ratio => 100,
        },
        {   mass  => 75,
            name  => 'notegg',
            order => 1,
            ratio => 75,
        }
    ],
    ingredients => [
        {   groups => ['food'],
            mass   => 25,
            name   => 'egg',
            ratio  => 25,
        },
        {   groups => [ 'food', 'notegg' ],
            mass   => 75,
            name   => 'water',
            ratio  => 75,
        },
    ],
    total => {
        mass  => 100,
        ratio => 100
    }
  };

# :reader attributes
# NOTE these tests will break should the internals change
is $simple->key, [ 100, 'food', undef, 0, 100 ];    # the food group
is $simple->things,
  [ [ 25, 'egg',   ['food'],          undef, 25 ],
    [ 75, 'water', [qw(food notegg)], undef, 75 ]
  ];
is $simple->groups,
  { food   => [ 100, 'food',   undef, 0, 100 ],
    notegg => [ 75,  'notegg', undef, 1, 75 ]
  };
#is $simple->total, [ 100, undef, undef, undef, 100 ];

# code coverage
$simple->weigh(10);
is $simple->total, [ 10, undef, undef, undef, 100 ];

done_testing

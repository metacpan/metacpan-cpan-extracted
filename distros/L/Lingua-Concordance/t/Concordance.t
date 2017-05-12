use Test::More tests => 29;
use strict;

# Concordance.t - regression texts against Lingua::Concordance

# Eric Lease Morgan <eric_morgan@infomotions.com>
# June 7, 2009    - first cut
# June 8, 2009    - tweaking
# August 29, 2010 - added tests for methods scale, positions, and map


# configure defaults; should be defined same as in Lingua::Concordance.pm
use constant RADIUS  => 20;
use constant SORT    => 'none';
use constant ORDINAL => 1;

# use 
use_ok( 'Lingua::Concordance' );

# constructor
my $concordance = Lingua::Concordance->new;
isa_ok( $concordance, 'Lingua::Concordance' );

# default configurations
is( $concordance->sort, 'none', 'default sort' );
is( $concordance->radius, 20, 'default radius' );
is( $concordance->ordinal, 1, 'default ordinal' );
is( $concordance->scale, 10, 'default scale' );

# slurp test data
my $text = do { local $/; <DATA> };

# set/get text
$concordance->text( $text );
like( $concordance->text, qr/^ 1854 WALDEN Or Life In The Woods by Henry David Thoreau/, 'set/get text' );

# set/get query
$concordance->query( 'woods' );
is( $concordance->query, 'woods', 'set/get query' );

# set/get radius
$concordance->radius( 5 );
is( $concordance->radius, 5, 'set/get radius' );

# set/get ordinal
$concordance->ordinal( 2 );
is( $concordance->ordinal, 2, 'set/get ordinal' );

# set/get sort
$concordance->sort( 'left' );
is( $concordance->sort, 'left', 'set/get sort (left)' );
$concordance->sort( 'right' );
is( $concordance->sort, 'right', 'set/get sort (right)' );
$concordance->sort( 'query' );
is( $concordance->sort, 'query', 'set/get sort (query)' );
$concordance->sort( 'none' );
is( $concordance->sort, 'none', 'set/get sort (none)' );

# remove punctuation
is( $concordance->_remove_punctuation( '.!@#$%^&*()_Eric was here.!@#$%^&*()_' ), 'eric was here', 'remove punctuation' );

# on left: 1
$concordance->radius( RADIUS );
$concordance->ordinal( ORDINAL );
is( $concordance->_on_left( 'Or Life In The Woods by Henry David Thor' ), 'the', 'on left: 1' );

# on left: 2
$concordance->ordinal( 2 );
is( $concordance->_on_left( 'Or Life In The Woods by Henry David Thor' ), 'in', 'on left: 2' );

# on right: 1
$concordance->ordinal( ORDINAL );
is( $concordance->_on_right( 'Or Life In The Woods by Henry David Thor' ), 'by', 'on right: 1' );

# on right: 2
$concordance->ordinal( 2 );
is( $concordance->_on_right( 'Or Life In The Woods by Henry David Thor' ), 'henry', 'on right: 2' );

# lines; sort: default
$concordance->sort( SORT );
$concordance->query( 'woods' );
my @lines = $concordance->lines;
is( scalar( $concordance->lines ), 2, 'lines (number of lines returned)' );
is( $lines[ 0 ], 'Or Life In The Woods by Henry David Thor', 'lines (default sort)' );

# lines sort: left; ordinal: 1
$concordance->sort( 'left' );
$concordance->ordinal( 1 );
@lines = $concordance->lines;
is( $lines[ 0 ], 'Or Life In The Woods by Henry David Thor', 'lines (sort: left; ordinal: 1)' );

# lines sort: left; ordinal: 2
$concordance->ordinal( 2 );
@lines = $concordance->lines;
is( $lines[ 0 ], 'Or Life In The Woods by Henry David Thor', 'lines (sort: left; ordinal: 2)' );

# lines sort: right; ordinal: 1
$concordance->sort( 'right' );
$concordance->ordinal( 1 );
@lines = $concordance->lines;
is( $lines[ 0 ], ' alone, in the woods, a mile from any ne', 'lines (sort: right; ordinal: 1)' );

# lines sort: right; ordinal: 2
$concordance->ordinal( 2 );
@lines = $concordance->lines;
is( $lines[ 0 ], 'Or Life In The Woods by Henry David Thor', 'lines (sort: right; ordinal: 2)' );

# lines sort: match
$concordance->sort( 'match' );
@lines = $concordance->lines;
is( $lines[ 1 ], ' alone, in the woods, a mile from any ne', 'lines (sort: match)' );

# set/get scale
$concordance->scale( 5 );
is( $concordance->scale, 5, 'set/get scale' );

# get positions
my @positions = $concordance->positions;
is( $positions[ 0 ], 33, 'get positions' );

# get map
my $map = $concordance->map;
is( $$map{ '20' }, 2, 'get map' );

# done, whew!
exit;

# sample data
__DATA__
                                      1854

                                     WALDEN

                              Or Life In The Woods

                             by Henry David Thoreau
ECONOMY

                             ECONOMY

  WHEN I WROTE the following pages, or rather the bulk of them, I
lived alone, in the woods, a mile from any neighbor, in a house
which I had built myself, on the shore of Walden Pond, in Concord,
Massachusetts, and earned my living by the labor of my hands only. I
lived there two years and two months. At present I am a sojourner in
civilized life again.

  I should not obtrude my affairs so much on the notice of my
readers if very particular inquiries had not been made by my
townsmen concerning my mode of life, which some would call
impertinent, though they do not appear to me at all impertinent,
but, considering the circumstances, very natural and pertinent. Some
have asked what I got to eat; if I did not feel lonesome; if I was not
afraid; and the like. Others have been curious to learn what portion
of my income I devoted to charitable purposes; and some, who have
large families, how many poor children I maintained. I will
therefore ask those of my readers who feel no particular interest in
me to pardon me if I undertake to answer some of these questions in
this book. In most books, the I, or first person, is omitted; in
this it will be retained; that, in respect to egotism, is the main
difference. We commonly do not remember that it is, after all,
always the first person that is speaking. I should not talk so much
about myself if there were anybody else whom I knew as well.
Unfortunately, I am confined to this theme by the narrowness of my
experience. Moreover, I, on my side, require of every writer, first or
last, a simple and sincere account of his own life, and not merely
what he has heard of other men's lives; some such account as he
would send to his kindred from a distant land; for if he has lived
sincerely, it must have been in a distant land to me. Perhaps these
pages are more particularly addressed to poor students. As for the
rest of my readers, they will accept such portions as apply to them. I
trust that none will stretch the seams in putting on the coat, for
it may do good service to him whom it fits.

  I would fain say something, not so much concerning the Chinese and
Sandwich Islanders as you who read these pages, who are said to live
in New England; something about your condition, especially your
outward condition or circumstances in this world, in this town, what
it is, whether it is necessary that it be as bad as it is, whether
it cannot be improved as well as not. I have travelled a good deal
in Concord; and everywhere, in shops, and offices, and fields, the
inhabitants have appeared to me to be doing penance in a thousand
remarkable ways. What I have heard of Bramins sitting exposed to
four fires and looking in the face of the sun; or hanging suspended,
with their heads downward, over flames; or looking at the heavens over
their shoulders "until it becomes impossible for them to resume
their natural position, while from the twist of the neck nothing but
liquids can pass into the stomach"; or dwelling, chained for life,
at the foot of a tree; or measuring with their bodies, like
caterpillars, the breadth of vast empires; or standing on one leg on
the tops of pillars- even these forms of conscious penance are
hardly more incredible and astonishing than the scenes which I daily
witness. The twelve labors of Hercules were trifling in comparison
with those which my neighbors have undertaken; for they were only
twelve, and had an end; but I could never see that these men slew or
captured any monster or finished any labor. They have no friend Iolaus
to burn with a hot iron the root of the hydra's head, but as soon as
one head is crushed, two spring up.

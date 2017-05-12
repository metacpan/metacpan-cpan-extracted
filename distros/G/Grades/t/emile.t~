use strict;
use warnings;
use Test::More;
use FindBin qw/$Bin/;

plan skip_all => 'unset env var NO_TEST to enable this test' if $ENV{NO_TEST};
plan tests => 47;

use lib 'lib';
use Grades;

my $l = League->new( leagues => 't', id => 'emile' );
my $g = Grades->new({ league => $l });

# groupwork

my $gp = $g->classwork;
is_deeply( $gp->totalPercent,
	{ 34113 => '100.00', S09413 => '100.00', 1 => 66.67, 222, 66.67},
	"Classwork role delegates classworkPercent to Groupwork role" );
is( $gp->groupworkdirs, 't/emile/classwork', 'groupwork location' );
is_deeply( $gp->series, [ 1 .. 4 ], '4-session series' );
is_deeply($gp->beancanseries, {
	   1 => { one  => [qw/Emile Sophie/], two => [qw/Rousseau Therese/] },
           2 => { one  => [qw/Emile Sophie/], Absent=>[qw/Rousseau Therese/] },
           3 => { one  => [qw/Emile Sophie/], two => [qw/Rousseau Therese/] },
           4 => { one  => [qw/Emile Sophie/], two => [qw/Rousseau Therese/] },
         }, 'beancans for 4 sessions' ); 
is_deeply( $gp->allfiles, [ qw[
	t/emile/classwork/10.yaml t/emile/classwork/11.yaml
	t/emile/classwork/12.yaml t/emile/classwork/14.yaml
	t/emile/classwork/15.yaml t/emile/classwork/16.yaml
	t/emile/classwork/2.yaml t/emile/classwork/3.yaml
	t/emile/classwork/5.yaml t/emile/classwork/6.yaml
	t/emile/classwork/7.yaml t/emile/classwork/8.yaml
	] ], 'all 12 files in classwork');
is_deeply( $gp->all_events, [2,3,5,6,7,8,10..12,14..16], "all 12 weeks");
is_deeply( $gp->lastweek, 16, "last week");
is_deeply( $gp->beancan_names('3'),
	{ one  => [qw/Emile Sophie/], two => [qw/Rousseau Therese/] },
	"beancans" );
is_deeply( $gp->weeks('4'), [14..16], 'weeks in fourth session');
is( $gp->lastweek, 16, "Last week beans were awarded");
is( $gp->week2session(15), '4', '15th week in fourth session');
is_deeply( $gp->names2beancans('4'),
	{ Emile => 'one', Sophie => 'one', Rousseau => 'two', Therese => 'two'},
	'names2beancans in 4th session');
is( $gp->name2beancan(12, 'Emile'), 'one', 'beancan of Emile in week12');
is( $gp->name2beancan(6, 'Sophie'), 'one', 'beancan of Sophie in week 6');
is( eval{ $gp->name2beancan(3, 'KarlMarx') }, undef, 'Which group is Karl Marx in in week 3, but dies.');
is_deeply( $gp->merits(14), { one => 3, two => 3 }, "merits in Week 14");
is_deeply( $gp->absences(2), {  one => 1, two => 1 }, "absences in week 2");
is_deeply( $gp->tardies(2), { one => 1, two => 1 }, "people late in week 2");
# is( $gp->payout('2'), 5, "If the total paid to players each week in session 2 is 5, the average grade over the semester should be 80.");
# is_deeply( $gp->demerits(3), { one => 3, two => 3 }, "2*absences+tardies");
# is_deeply( $gp->favor(2), { one => 1, two => 1 }, "favor to avoid 0");
# is( $gp->maxDemerit(2), 3, "demerits of group(s) with most absences, tardies");
# is_deeply( $gp->meritDemerit(2), { one => 4, two => 4 }, "merits - demerits");

# homework

is( $g->hwdir, 't/emile/homework', 'hwdirectory' );
is_deeply( $g->rounds, [6..14,16,17], 'homework rounds' );
is_deeply( $g->hwbyround, {
           6  => { 34113 => 0, S09413 => 1, 1 => 2, 222 => 1, },
           7  => { 34113 => 0, S09413 => 1, 1 => 2, 222 => 1, },
           8  => { 34113 => 0, S09413 => 1, 1 => 2, 222 => 1, },
           9  => { 34113 => 0, S09413 => 1, 1 => 2, 222 => 1, },
           10  => { 34113 => 0, S09413 => 1, 1 => 2, 222 => 1, },
           11  => { 34113 => 0, S09413 => 1, 1 => 2, 222 => 1, },
           12  => { 34113 => 0, S09413 => 1, 1 => 2, 222 => 1, },
           13  => { 34113 => 0, S09413 => 1, 1 => 2, 222 => 1, },
           14  => { 34113 => 0, S09413 => 1, 1 => 2, 222 => 1, },
           16  => { 34113 => 0, S09413 => 1, 1 => 2, 222 => 1, },
           17  => { 34113 => 0, S09413 => 1, 1 => 2, 222 => 1, },
         }, 'homework' );
is($g->roundMax, 2, 'max hw score per round');
is($g->totalMax, 22, 'maximum possible homework score');
is_deeply($g->hwforid(34113), [ (0) x 11 ], 'no hw score for Emile');
is_deeply($g->homework, { 34113 => 0, S09413 => 11, 1 => 22, 222 => 11 },
	"total homework / 22", );
is_deeply($g->homeworkPercent, { 34113=>0, S09413=>50, 1=>100, 222=>50 },
	"total %homework");

# jigsaw

is_deeply( $g->config( 'Jigsaw', '2'), $g->inspect('t/emile/exams/2/round.yaml'), 'Config file.');
is( $g->topic( '2', 'Brown' ), 'internet', 'Topic of exam text');
is( $g->form( '3', 'Brown' ), 2, 'Form of exam text');

my $quizfile = "t/emile/activities.yaml";

is( $g->quizfile( '1' ), $quizfile, 'Location of exam text');
is( $g->quizfile( '4' ), $quizfile, 'Location of exam text');
is_deeply($g->quiz( '4', 'Brown' ),
	$g->inspect($quizfile)->{cars}->{jigsaw}->{2}->{quiz},
	'Quiz content');
is_deeply( $g->options( '1', 'Brown', 0 ), ['True','False'],
	'Options');
is( $g->qn( '1', 'Brown' ), 8, 'Number of exam questions' );

my ($emile, $rousseau, $sophie, $therese);
@$emile{1..9} = ( (0,1) x 4, 0 ); @$rousseau{1..9} = (0,0,1) x 3;
@$sophie{1..9} = ( (0,0,0,1) x 2, 0 ); @$therese{1..9} = ( (0) x 4, 1, (0) x 4);
is_deeply( $g->responses( '4/2', 'Brown' ),
	{ 34113 => $emile, 1 => $rousseau, S09413 => $sophie, 222 => $therese },
	"Question responses" );
is_deeply( $g->jigsawGroups( '2/2'),
	{ Brown => [ 'Emile', 'Rousseau', 'Sophie', 'Therese' ] }, "Jigsaw groups");
is_deeply( $g->jigsawGroupMembers( '3/1', 'Brown' ),
	[ 'Emile', 'Rousseau', 'Sophie', 'Therese' ], "Jigsaw groups" );
is_deeply( $g->idsbyRole( '2/1', 'Brown' ),
	[ 34113, 1, 'S09413', 222 ], 'Ids in array, in A-D role order' );

is_deeply( $g->jigsawGroupRole('1/2', 'Brown' ),
	{ Emile => 'A', Rousseau => 'B', Sophie => 'C', Therese => 'D' },
	 "Members' roles" );
is_deeply( $g->id2jigsawGroupRole('3/2', 'Brown' ),
	{ 34113 => 'A', 1 => 'B', S09413 => 'C', 222 => 'D' }, 'Id to role' );
is_deeply( $g->name2jigsawGroup('3/1', 'Rousseau'), [ 'Brown' ],
	'Name in which groups?');
is_deeply( $g->rawJigsawScores('3/1', 'Brown'),
	{ 1 => 4, 222 => 4, 34113 => 6, S09413 => 2 }, 'Raw scores');
is_deeply( $g->rawJigsawScores('4/2', 'Brown'),
	{ 34113 => 5, 1 => 5, S09413 => 3, 222 => 2 }, 'Jigsaw scores' );

# exams
is( $g->examdirs, qw{t/emile/exams}, 'examdirs' );
is_deeply( $g->examids, [ 1 .. 4 ], 'examids' );

# compcomp

my $c = Compcomp->new( league => $l );
is( $c->compcompdirs, 't/emile/comp', 'compcompdirs' );
is_deeply( $c->all_events, [ 1..2 ], 'conversations' );

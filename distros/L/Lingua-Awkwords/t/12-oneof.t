#!perl

use 5.14.0;
use warnings;

use Test::Most;    # plan is down at bottom

my $deeply = \&eq_or_diff;

use Lingua::Awkwords::OneOf;
use Lingua::Awkwords::String;

my @strings =
  map { Lingua::Awkwords::String->new( string => $_ ) } qw/blah i/;

my $oneof = Lingua::Awkwords::OneOf->new;

dies_ok { $oneof->render };

$oneof->add_choice( $strings[0], 1 );
is( $oneof->render, 'blah' );

$oneof->add_filters('b');
is( $oneof->render, 'lah' );

$oneof->add_filters(qw/l a/);
is( $oneof->render, 'h' );

$oneof->filter_with('qq');
is( $oneof->render, 'qqqqqqh' );
$oneof->filter_with('');

$oneof->add_choice( $strings[1], 3 );

# thanks to the filters and weight, this should produce only 'h' or 'i'
# at 1:3 odds, roughly
my %results;
for ( 1 .. 300 ) {
    $results{ $oneof->render }++;
}
$deeply->( [ sort keys %results ], [qw/h i/] );

diag( "srand seed " . srand );
ok( $results{i} > 200 && $results{i} < 250, '3:1 odds within tolerance' );

plan tests => 7;

use strict;
use Test::More tests => 15;
use JSON::HPack;


can_ok( 'JSON::HPack', 'pack' );
can_ok( 'JSON::HPack', 'unpack' );
can_ok( 'JSON::HPack', 'load' );
can_ok( 'JSON::HPack', 'dump' );


my $struct = [
  {
    qw/foo bar moodle doodle try this/
  },

  {
    qw/foo barbar moodle doubledoodle try that/
  }
];

my $packed = JSON::HPack->pack( $struct );

cmp_ok( scalar( @$packed ), '==', ( 1 + ( 3 * 3 ) ) );
cmp_ok( $packed->[0], '==', 3 );

my @keys = qw/foo moodle try/;
for my $num ( 1..3 ) {
  ok( grep { $_ eq $packed->[ $num ] } @keys );
}

my @val1 = qw/bar doodle this/;
for my $num ( 4..6 ) {
  ok( grep { $_ eq $packed->[ $num ] } @val1);
}

my @val2 = qw/barbar doubledoodle that/;
for my $num ( 7..9 ) {
  ok( grep { $_ eq $packed->[ $num ] } @val2);
}





use strict;
use Test::More tests => 23;

BEGIN{ use_ok("FormValidator::Simple::Constraint") }

my $c1 = FormValidator::Simple::Constraint->new( ['NOT_BLANK'] );

is( $c1->name,    'NOT_BLANK' );
is( $c1->command, 'BLANK'     );
ok( $c1->negative );

my $c2 = FormValidator::Simple::Constraint->new( 'NOT_BLANK' );

is( $c2->name,    'NOT_BLANK' );
is( $c2->command, 'BLANK'     );
ok( $c2->negative );

my $c3 = FormValidator::Simple::Constraint->new( ['INT'] );

is( $c3->name,    'INT'   );
is( $c3->command, 'INT'   );
ok( !$c3->negative );

my $c4 = FormValidator::Simple::Constraint->new( 'ASCII' );

is( $c4->name,    'ASCII'   );
is( $c4->command, 'ASCII'   );
ok( !$c4->negative );

my $c5 = FormValidator::Simple::Constraint->new( [qw/LENGTH 3 10/] );

is( $c5->name,    'LENGTH' );
is( $c5->command, 'LENGTH' );
ok( !$c5->negative );

my $args5 = $c5->args;

is( $args5->[0], 3  );
is( $args5->[1], 10 );

my $c6 = FormValidator::Simple::Constraint->new( [qw/NOT_LENGTH 2 5/] );

is( $c6->name,    'NOT_LENGTH' );
is( $c6->command, 'LENGTH'     );
ok( $c6->negative );

my $args6 = $c6->args;

is( $args6->[0], 2 );
is( $args6->[1], 5 );


use strict;
use Test::More tests => 11;

BEGIN{ use_ok("FormValidator::Simple::Constraints") }

my $constraints = FormValidator::Simple::Constraints->new;

ok( !$constraints->needs_blank_check );

require FormValidator::Simple::Constraint;
my $c1 = FormValidator::Simple::Constraint->new('INT');
my $c2 = FormValidator::Simple::Constraint->new('ASCII');
my $c3 = FormValidator::Simple::Constraint->new([qw/LENGTH 5 10/]);

is( $constraints->records_count, 0 );

$constraints->append($c1);
$constraints->append($c2);
$constraints->append($c3);

is( $constraints->records_count, 3 );

my $c4 = $constraints->get_record_at(1);

is( $c4->name, 'ASCII' );

my $ite = $constraints->iterator;

isa_ok( $ite, "FormValidator::Simple::Constraint::Iterator" );

my $c5 = $ite->next;
my $c6 = $ite->next;
my $c7 = $ite->next;
my $c8 = $ite->next;

is( $c5->name, 'INT'    );
is( $c6->name, 'ASCII'  );
is( $c7->name, 'LENGTH' );
is( $c8, undef );

$ite->reset;
my $c9 = $ite->next;

is( $c9->name, 'INT' );


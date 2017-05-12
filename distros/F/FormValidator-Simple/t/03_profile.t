use strict;
use Test::More tests => 42;

BEGIN{ use_ok("FormValidator::Simple::Profile") }

my $rec = FormValidator::Simple::Profile::Record->new;

$rec->set_keys( { id =>  ['key'] } );

is( $rec->name,      'id'  );
is( $rec->keys->[0], 'key' );

$rec->set_keys( { 'id2' => 'key2' } );

is( $rec->name,      'id2'  );
is( $rec->keys->[0], 'key2' );

$rec->set_keys( { 'id3' => [qw/key3 key4 key5/] } );

is( $rec->name,      'id3'  );
is( $rec->keys->[0], 'key3' );
is( $rec->keys->[1], 'key4' );
is( $rec->keys->[2], 'key5' );

$rec->set_keys( 'id4' );

is( $rec->name,      'id4' );
is( $rec->keys->[0], 'id4' );

isa_ok( $rec->constraints, "FormValidator::Simple::Constraints" );

$rec->set_constraints( ['INT'] );

my $c1 = $rec->constraints->get_record_at(0);

is( $c1->name, 'INT' );

$rec->set_constraints( [qw/ASCII INT/,[qw/LENGTH 4 10/]] );

my $c2 = $rec->constraints->get_record_at(0);
my $c3 = $rec->constraints->get_record_at(1);
my $c4 = $rec->constraints->get_record_at(2);

is( $rec->constraints->records_count, 3 );
ok( !$rec->constraints->needs_blank_check );
is( $c2->name, 'ASCII'  );
is( $c3->name, 'INT'    );
is( $c4->name, 'LENGTH' );
is( $c4->args->[0], 4   );
is( $c4->args->[1], 10  );

$rec->set_constraints( [qw/NOT_BLANK ASCII INT/] );

my $c5 = $rec->constraints->get_record_at(0);
my $c6 = $rec->constraints->get_record_at(1);

is( $rec->constraints->records_count, 2 );
ok( $rec->constraints->needs_blank_check );
is( $c5->name, 'ASCII' );
is( $c6->name, 'INT'   );

$rec->set_constraints('INT');

my $c7 = $rec->constraints->get_record_at(0);

is( $c7->name, 'INT' );

$rec->set_constraints( ['NOT_BLANK'] );

is( $rec->constraints->records_count, 0 );
ok( $rec->constraints->needs_blank_check );

my $prof = FormValidator::Simple::Profile->new( [
	id   => [qw/NOT_BLANK/],
	{ name => [qw/name1 name2/] } => [qw/ANY/],
	pass => [qw/NOT_BLANK ASCII/,['LENGTH', 4, 10]]
] );

my $prec1 = $prof->get_record_at(0);
my $prec2 = $prof->get_record_at(1);
my $prec3 = $prof->get_record_at(2);

is( $prof->records_count, 3 );

isa_ok( $prec1, "FormValidator::Simple::Profile::Record" );
isa_ok( $prec2, "FormValidator::Simple::Profile::Record" );
isa_ok( $prec3, "FormValidator::Simple::Profile::Record" );

ok( $prec1->constraints->needs_blank_check  );
is( $prec1->constraints->records_count, 0  );
ok( !$prec2->constraints->needs_blank_check );
is( $prec2->constraints->records_count, 1  );
ok( $prec3->constraints->needs_blank_check  );
is( $prec3->constraints->records_count, 2  );

my $ite = $prof->iterator;

isa_ok( $ite, "FormValidator::Simple::Profile::Iterator" );

my $prec4 = $ite->next;
my $prec5 = $ite->next;
my $prec6 = $ite->next;
my $prec7 = $ite->next;

is( $prec7, undef );

is( $prec4->name, 'id'   );
is( $prec5->name, 'name' );
is( $prec6->name, 'pass' );


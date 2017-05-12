use strict;
use Test::More tests => 13;

BEGIN{ use_ok("FormValidator::Simple::Result") }

my $r1 = FormValidator::Simple::Result->new('id1');

is( $r1->name, 'id1' );
ok( !$r1->is_blank );

$r1->set('ASCII',  1     );

ok( $r1->is_valid    );
ok( !$r1->is_invalid );

$r1->set('INT',    undef );
$r1->set('LENGTH', undef );

ok( !$r1->is_valid  );
ok( $r1->is_invalid );

ok( $r1->is_valid_for('ASCII')   );
ok( !$r1->is_valid_for('INT')    );
ok( !$r1->is_valid_for('LENGTH') );

ok( !$r1->is_invalid_for('ASCII') );
ok( $r1->is_invalid_for('INT')    );
ok( $r1->is_invalid_for('LENGTH') );


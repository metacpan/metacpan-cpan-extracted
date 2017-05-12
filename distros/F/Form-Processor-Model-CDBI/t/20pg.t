use strict;
use warnings;
use Test::More;
use lib 't/lib';

my $db = 'PG';

my ($dsn, $user, $pass) = @ENV{map { "${db}_${_}" } qw/DSN USER PASS/};

plan skip_all => "Skipping test with $db: Set env ${db}_DSN  ${db}_USER and  ${db}_PASS"
  unless ($dsn && $user);


plan tests => 12;

use_ok( 'MyForm' );


TODO: {
    todo_skip 'Must setup database and CDBI', 11;
    fail('create tables');
    fail('add data to tables');
    use_ok( 'CDBI::User' );
    fail('create form object');
    fail('make sure lookup options are found for select');
    fail('make sure many-to-many lookups are found');
    fail('pass form data');
    fail('check validation');
    fail('run update_from_form');
    fail('test that select populated correctly');
    fail('check that many-to-many link table updated')
}


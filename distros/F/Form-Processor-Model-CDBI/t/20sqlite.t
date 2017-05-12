use strict;
use warnings;
use Test::More;
use lib 't/lib';

my $db = 'SQLITE';

my ($dsn, $user, $pass) = @ENV{map { "${db}_${_}" } qw/DSN USER PASS/};

plan skip_all => "Skipping test with $db: Set env ${db}_DSN  ${db}_USER and  ${db}_PASS"
  unless ($dsn && $user);


plan tests => 2;

use_ok( 'MyForm' );


TODO: {
    use_ok( 'CDBI::User' );
}


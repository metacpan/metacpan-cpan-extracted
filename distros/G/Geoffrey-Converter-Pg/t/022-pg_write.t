
use DBI;
use strict;
use warnings;
use Geoffrey;
 
use Test::More tests => 2;

$ENV{POSTGRES_HOME} = '/tmp/test/pgsql/geoffrey';

require_ok('Geoffrey::Converter::Pg');
use_ok 'Geoffrey::Converter::Pg';

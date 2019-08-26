use DBI;
use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;

$ENV{POSTGRES_HOME} = '/tmp/test/pgsql/geoffrey';

require_ok('Geoffrey::Converter::Pg');
use_ok 'Geoffrey::Converter::Pg';

require_ok('Geoffrey::Action::Constraint::Default');
use_ok 'Geoffrey::Action::Constraint::Default';

my $converter = Geoffrey::Converter::Pg->new();
my $object = new_ok( 'Geoffrey::Action::Constraint::Default', [ 'converter', $converter ] );

SKIP: {
    eval "use Test::PostgreSQL";
    if ($@) {
        skip "Test::PostgreSQL not installed: $@", 2;
    }
    my $pg = Test::PostgreSQL->new();
    my $dbh = DBI->connect( $pg->dsn( dbname => 'test' ), q~~, q~~, { AutoCommit => 1, RaiseError => 1, }, );
    $object = Geoffrey::Action::Constraint::Default->new(
        converter => $converter,
        dbh       => $dbh
    );

    is(
        $object->add( { default => 'autoincrement', table => 'test', name => 'seq_test' } ),
        q~DEFAULT nextval('seq_test_seq_test'::regclass)~,
        'Add sequence is failing!'
    );

    $dbh->disconnect();
}
done_testing;

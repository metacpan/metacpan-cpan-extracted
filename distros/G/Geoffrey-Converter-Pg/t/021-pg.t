use DBI;
use strict;
use warnings;

use Test::More tests => 9;
use Test::Exception;

require_ok('Geoffrey::Converter::Pg');
use_ok 'Geoffrey::Converter::Pg';

my $converter = Geoffrey::Converter::Pg->new();
dies_ok { $converter->check_version('3.0') } 'underneath min version expecting to die';
is( $converter->check_version('9.1'), 1, 'min version check' );
is( $converter->check_version('9.6'), 1, 'min version check' );

require_ok('Geoffrey::Action::Constraint::Default');
my $object = new_ok( 'Geoffrey::Action::Constraint::Default', [ 'converter', $converter ] );

SKIP: {
    eval { require Test::PostgreSQL };
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

#my $dbh = DBI->connect("dbi:Pg:database=.tmp.sqlite");
#my $object = new_ok( 'Geoffrey' => [ dbh => $dbh ] ) or plan skip_all => "";
#throws_ok { $object->read( File::Spec->catfile( $FindBin::Bin, 'data', 'changelog' ) ) }
#'Geoffrey::Exception::NotSupportedException::Column', 'Not supportet thrown';
#throws_ok { $converter->index->drop() } 'Geoffrey::Exception::RequiredValue::IndexName',
#    'Drop index needs a name';
#$object->disconnect();

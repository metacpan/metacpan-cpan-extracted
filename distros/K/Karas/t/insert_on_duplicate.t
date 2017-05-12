use strict;
use warnings;
use utf8;
use Test::More;
use Test::Requires 'Test::mysqld';
use Karas;
use Karas::Loader;
use Test::Time;

my $mysqld = Test::mysqld->new(
    my_cnf => {
        'skip-networking' => '',    # no TCP socket
    }
) or plan skip_all => $Test::mysqld::errstr;

{
    package MyDB;
    use parent qw/Karas/;
    __PACKAGE__->load_plugin('Timestamp');
}

my $dbh = DBI->connect( $mysqld->dsn(dbname => 'test'), {RaiseError => 1} );
$dbh->do(q{CREATE TABLE counter (date date primary key, n int unsigned not null)});
$dbh->do(q{CREATE TABLE member (
    id integer primary key auto_increment,
    name varchar(255) not null,
    email varchar(255) binary not null,
    login_cnt int unsigned not null DEFAULT 1,
    created_on int unsigned not null,
    updated_on int unsigned not null,
    unique (email)
)});
my $db = Karas::Loader->load(
    connect_info => [
        'dbi:PassThrough:', '', '', {
            pass_through_source => $dbh
        },
    ],
    namespace => 'MyDB',
);

subtest 'insert-on-duplicate' => sub {
    $db->insert_on_duplicate(counter => { date => '2012-11-11', n => 1 }, { n => \"n + 1"});
    $db->insert_on_duplicate(counter => { date => '2012-11-11', n => 1 }, { n => \"n + 1"});
    $db->insert_on_duplicate(counter => { date => '2012-11-11', n => 1 }, { n => \"n + 1"});
    $db->insert_on_duplicate(counter => { date => '2012-11-11', n => 1 }, { n => \"n + 1"});
    my $row = ($db->search('counter', { date => '2012-11-11' }))[0];
    is($row->n, 4);
};
subtest 'timestamp' => sub {
    subtest 'created_on' => sub {
        my $t1 = time();
        {
            $db->insert_on_duplicate(member => { name => 'John', email => 'foo@example.com' }, { login_cnt => \"login_cnt + 1"});
            my ($row, ) = $db->search(member => {email => 'foo@example.com'});
            is($row->created_on, $t1);
            is($row->updated_on, $t1);
            is($row->login_cnt, 1);
        }
        sleep 2;
        {
            my $t2 = time();
            $db->insert_on_duplicate(member => { name => 'John', email => 'foo@example.com' }, { login_cnt => \"login_cnt + 1"});
            my ($row, ) = $db->search(member => {email => 'foo@example.com'});
            is($row->created_on, $t1);
            is($row->updated_on, $t2);
            is($row->login_cnt, 2);
        }
    };
};

done_testing;


use strict;
use Test::More;
use Test::Exception;
use Class::Load ':all';

BEGIN {
    try_load_class('DBI')
       or plan skip_all => "DBI required to run these tests";
    try_load_class('DBD::SQLite')
       or plan skip_all => "DBD::SQLite required to run these tests";

    plan qw/no_plan/;

    use_ok 'IOC::Slinky::Container';
}

my $conf;
my $c;
my $o;
my $p;

$conf = {
    container => {
        db_dsn      => "DBI:SQLite:dbname=:memory:",
        db_user     => "",
        db_pass     => "",
        dbh1 => {
            _class              => "DBI" ,
            _constructor        => "connect",
            _constructor_args   => [
                { _ref => "db_dsn" },
                { _ref => "db_user" },
                { _ref => "db_pass" },
                { RaiseError => 1 },
            ],
        },
        dbh2 => {
            _singleton          => 0,
            _class              => "DBI",
            _constructor        => "connect",
            _constructor_args   => [
                { _ref => "db_dsn" },
                { _ref => "db_user" },
                { _ref => "db_pass" },
                { RaiseError => 1 },
            ],
        },
        ptr1 => { _ref => 'dbh1' },
        aref1 => [
            1,
            2,
            { 
                'nested_href_here' => {
                    hello => 'world',
                    some_dbh_ref => { _ref => 'dbh1' },
                },
            },
        ],
    },
};

$c = IOC::Slinky::Container->new( config => $conf );

# singleton
$o = $c->lookup('dbh1');
isa_ok $c->lookup('dbh1'), 'DBI::db';
is $o, $c->lookup('dbh1'), 'singleton dbh1';

 
$o = $c->lookup('dbh2');
isa_ok $o, 'DBI::db';
$p = $c->lookup('dbh2');
isnt $o, $p, 'non-singleton dbh2';

$o = $c->lookup('ptr1');
is $o, $c->lookup('dbh1'), 'ref-to-objects';

$o = $c->lookup('aref1');
is $o->[2]->{nested_href_here}->{some_dbh_ref}, $c->lookup('dbh1'), 'nested-ref-to-objects';

pass "done";

__END__

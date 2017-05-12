#!/usr/bin/perl -w
use strict;

use Test::More;#  tests => 17;
use Labyrinth::DBUtils;
use Data::Dumper;

eval "use Test::Database";
plan skip_all => "Test::Database required for DB testing" if($@);

plan 'no_plan';

#my @handles = Test::Database->handles();
#diag("handle: ".$_->dbd)    for(@handles);
#diag("drivers all: ".$_)    for(Test::Database->list_drivers('all'));
#diag("drivers ava: ".$_)    for(Test::Database->list_drivers('available'));

#diag("rcfile=".Test::Database->_rcfile());

# may expand DBs later
my $td;
if($td = Test::Database->handle( 'mysql' )) {
    create_mysql_databases($td);
#} elsif($td = Test::Database->handle( 'SQLite' )) {
#    create_sqlite_databases($td);
}

SKIP: {
    skip "No supported databases available", 21  unless($td);

#diag(Dumper($td->connection_info()));

    my %opts;
    ($opts{dsn}, $opts{dbuser}, $opts{dbpass}) =  $td->connection_info();
    ($opts{driver})    = $opts{dsn} =~ /dbi:([^;:]+)/;
    ($opts{database})  = $opts{dsn} =~ /database=([^;]+)/;
    ($opts{database})  = $opts{dsn} =~ /dbname=([^;]+)/     unless($opts{database});
    ($opts{dbhost})    = $opts{dsn} =~ /host=([^;]+)/;
    ($opts{dbport})    = $opts{dsn} =~ /port=([^;]+)/;
    my %options = map {my $v = $opts{$_}; defined($v) ? ($_ => $v) : () }
                        qw(driver database dbfile dbhost dbport dbuser dbpass);

    $options{phrasebook} = 't/samples/phrasebook.ini';

#diag(Dumper(\%options));

    # create new instance from Test::Database object
    my $ct = Labyrinth::DBUtils->new(\%options);
    isa_ok($ct,'Labyrinth::DBUtils');

    # test hash
    is( $ct->driver, $td->dbd, 'driver matches: ' . $ct->driver );

    # insert records
    $ct->DoQuery( 'Insert', 'data', 1, 'record1');
    $ct->DoQuery( 'Insert', 'data', 2, 'record2');
    $ct->DoQuery( 'Insert', 'data', 1, 'record3');
    $ct->DoQuery( 'Insert', 'data', 2, 'record4');

    # select records
    my @arr = $ct->GetQuery('array','CountAll');
    is($arr[0]->[0], 4, '.. count all records');
    @arr = $ct->GetQuery('hash','CountByNum',1);
    is($arr[0]->{count}, 2, '.. count selected records');

    @arr = $ct->GetQuery('array','SelectAll');
    is(@arr, 4, '.. retrieved all records');

    # interate over records
    my $next = $ct->Iterator('hash','SelectAll');
    my $rows = 0;
    while(my $row = $next->()) {
        $rows++;
        is($row->{field1},'data','.. matched type');
    }
    is($rows, 4, '.. iterated over all records');

    $next = $ct->Iterator('array','SelectAll');
    $rows = 0;
    while(my $row = $next->()) {
        $rows++;
        is($row->[1],'data','.. matched type');
    }
    is($rows, 4, '.. iterated over all records');

    # insert using auto increment
    SKIP: {
        skip "skipping MySQL tests", 3  unless($opts{driver} eq 'mysql');

        my $id = $ct->IDQuery( 'Insert','data',3,'record5');
#diag("id=$id");
        ok($id,'.. got back an id');
        @arr = $ct->GetQuery('hash','SelectByID',$id);
        is($arr[0]->{field3}, 'record5', '.. added record');
        @arr = $ct->GetQuery('array','SelectAll');
        is(@arr, 5, '.. inserted all records');
#diag(Dumper(\@arr));
    }

    # test quote
    my $text = "Don't 'Quote' Me";
    like($ct->Quote($text), qr{'Don(\\'|'')t (\\'|'')Quote(\\'|'') Me'}, '.. quoted');

    # clean up
    $td->{driver}->drop_database($td->name);
}

sub create_sqlite_databases {
    my $db = shift;

    my @create_example = (
        'PRAGMA auto_vacuum = 1',
        'DROP TABLE IF EXISTS example',
        'CREATE TABLE example (
            id      INTEGER PRIMARY KEY AUTOINCREMENT,
            field1  TEXT,
            field2  INTEGER,
            field3  TEXT
        )'
    );

    dosql($db,\@create_example);
}

sub create_mysql_databases {
    my $db = shift;

    my @create_example = (
        'DROP TABLE IF EXISTS example',
        q{CREATE TABLE example (
            `id`        int(10) unsigned NOT NULL AUTO_INCREMENT,
            `field1`    varchar(32)     DEFAULT NULL,
            `field2`    int(2)          DEFAULT '0',
            `field3`    varchar(32)     DEFAULT NULL,
            PRIMARY KEY (`id`)
        )}
    );

    dosql($db,\@create_example);
}

sub dosql {
    my ($db,$sql) = @_;

    for(@$sql) {
        #diag "SQL: [$db] $_";
        eval { $db->dbh->do($_); };
        if($@) {
            diag $@;
            return 1;
        }
    }

    return 0;
}

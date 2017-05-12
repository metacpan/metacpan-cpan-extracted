#!/usr/bin/perl -w
use strict;

use Data::Dumper;
use Test::More;#  tests => 13;

use Labyrinth::Audit;
use Labyrinth::IPAddr;
use Labyrinth::DBUtils;
use Labyrinth::Variables;

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
    skip "No supported databases available", 13  unless($td);

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

#    SetLogFile( FILE   => 'audit.log',
#                USER   => 'labyrinth',
#                LEVEL  => 4,
#                CLEAR  => 1,
#                CALLER => 1
#        );

    # create new instance from Test::Database object
    $dbi = Labyrinth::DBUtils->new(\%options);
    isa_ok($dbi,'Labyrinth::DBUtils');

    $settings{blockurl} = undef;
    $settings{ipaddr} = '127.0.0.1';
    is(CheckIP(),0);
    is(BlockIP('test',$settings{ipaddr}),1);
    is(CheckIP(),1);
    is(AllowIP('test',$settings{ipaddr}),1);
    is(CheckIP(),2);

    $settings{ipaddr} = '127.0.0.2';
    is(CheckIP(),0);
    is(AllowIP(undef,$settings{ipaddr}),1);
    is(CheckIP(),2);
    is(BlockIP(undef,$settings{ipaddr}),1);
    is(CheckIP(),1);

    is(AllowIP(),undef);
    is(BlockIP(),undef);

    # clean up
    $td->{driver}->drop_database($td->name);
}

sub create_sqlite_databases {
    my $db = shift;

    my @create_example = (
        'PRAGMA auto_vacuum = 1',
        'DROP TABLE IF EXISTS ipindex',
        'CREATE TABLE ipindex (
            ipaddr  TEXT,
            author  TEXT,
            type    INTEGER
        )'
    );

    dosql($db,\@create_example);
}

sub create_mysql_databases {
    my $db = shift;

    my @create_example = (
        'DROP TABLE IF EXISTS ipindex',
        q|CREATE TABLE ipindex (
          ipaddr varchar(255) NOT NULL DEFAULT '',
          author varchar(255) NOT NULL DEFAULT '',
          type int(1) NOT NULL DEFAULT '0',
          PRIMARY KEY (ipaddr)
        ) ENGINE=MyISAM DEFAULT CHARSET=utf8|
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

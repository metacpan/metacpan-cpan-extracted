#!/usr/bin/perl -w
use strict;

use Data::Dumper;
use Test::More;#  tests => 14;

use Labyrinth::Audit;
use Labyrinth::Groups;
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
    skip "No supported databases available", 14  unless($td);

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

    is(GetGroupID(),undef);
    is(GetGroupID('public'),1);
    is(GetGroupID('admins'),5);

    is(UserInGroup(),undef);
    is(UserInGroup(1),0);
    is(UserInGroup(1,1),1);
    is(UserInGroup(7,2),0);
    is(UserInGroup(4,1),1);
    
    $tvars{loginid} = 1;
    is(UserInGroup(1),1);

    is(GroupSelect(),'<select id="groups" name="groups"><option value="0">Select A Group</option><option value="5">admins</option><option value="3">editors</option><option value="9">masters</option><option value="1">public</option><option value="4">sponsors</option><option value="2">users</option></select>');
    is(GroupSelect(2),'<select id="groups" name="groups"><option value="0">Select A Group</option><option value="5">admins</option><option value="3">editors</option><option value="9">masters</option><option value="1">public</option><option value="4">sponsors</option><option value="2" selected="selected">users</option></select>');

    is(GroupSelectMulti(),'<select id="groups" name="groups" multiple="multiple" size="5"><option value="0">Select A Group</option><option value="5">admins</option><option value="3">editors</option><option value="9">masters</option><option value="1">public</option><option value="4">sponsors</option><option value="2">users</option></select>');
    is(GroupSelectMulti(2,2),'<select id="groups" name="groups" multiple="multiple" size="2"><option value="0">Select A Group</option><option value="5">admins</option><option value="3">editors</option><option value="9">masters</option><option value="1">public</option><option value="4">sponsors</option><option value="2" selected="selected">users</option></select>');

    # clean up
    $td->{driver}->drop_database($td->name);
}

sub create_sqlite_databases {
    my $db = shift;

    my @create_example = (
        'PRAGMA auto_vacuum = 1',
        q|DROP TABLE IF EXISTS groups|,
        q|CREATE TABLE groups (
          groupid   INTEGER,
          groupname TEST,
          master    INTEGER,
          member    TEST,
          PRIMARY KEY (groupid)
        )|,

        q|INSERT INTO groups VALUES (1,'public',1,'Guest')|,
        q|INSERT INTO groups VALUES (2,'users',1,'User')|,
        q|INSERT INTO groups VALUES (3,'editors',1,'Editor')|,
        q|INSERT INTO groups VALUES (4,'sponsors',1,'Sponsor')|,
        q|INSERT INTO groups VALUES (5,'admins',1,'Admin')|,
        q|INSERT INTO groups VALUES (9,'masters',1,'Master')|,

        q|DROP TABLE IF EXISTS ixusergroup|,
        q|CREATE TABLE ixusergroup (
          indexid   INTEGER,
          type      INTEGER,
          linkid    INTEGER,
          groupid   INTEGER,
          PRIMARY KEY (indexid)
        )|,

        q|INSERT INTO ixusergroup VALUES (1,1,1,1)|,
        q|INSERT INTO ixusergroup VALUES (2,1,1,9)|,
        q|INSERT INTO ixusergroup VALUES (3,1,2,2)|,
        q|INSERT INTO ixusergroup VALUES (4,1,2,3)|,
        q|INSERT INTO ixusergroup VALUES (5,1,2,4)|,
        q|INSERT INTO ixusergroup VALUES (6,2,9,5)|,
        q|INSERT INTO ixusergroup VALUES (7,2,9,4)|,
        q|INSERT INTO ixusergroup VALUES (8,2,9,3)|,
        q|INSERT INTO ixusergroup VALUES (9,2,9,2)|,
    );

    dosql($db,\@create_example);
}

sub create_mysql_databases {
    my $db = shift;

    my @create_example = (
        q|DROP TABLE IF EXISTS groups|,
        q|CREATE TABLE groups (
          groupid int(10) unsigned NOT NULL AUTO_INCREMENT,
          groupname varchar(255) DEFAULT NULL,
          master int(2) DEFAULT '0',
          member varchar(255) DEFAULT NULL,
          PRIMARY KEY (groupid)
        ) ENGINE=MyISAM AUTO_INCREMENT=10 DEFAULT CHARSET=utf8|,

        q|INSERT INTO groups VALUES (1,'public',1,'Guest')|,
        q|INSERT INTO groups VALUES (2,'users',1,'User')|,
        q|INSERT INTO groups VALUES (3,'editors',1,'Editor')|,
        q|INSERT INTO groups VALUES (4,'sponsors',1,'Sponsor')|,
        q|INSERT INTO groups VALUES (5,'admins',1,'Admin')|,
        q|INSERT INTO groups VALUES (9,'masters',1,'Master')|,

        q|DROP TABLE IF EXISTS ixusergroup|,
        q|CREATE TABLE ixusergroup (
          indexid int(10) unsigned NOT NULL AUTO_INCREMENT,
          type int(1) unsigned NOT NULL DEFAULT '0',
          linkid int(10) unsigned NOT NULL DEFAULT '0',
          groupid int(10) unsigned NOT NULL DEFAULT '0',
          PRIMARY KEY (indexid),
          INDEX TYPIX (type),
          INDEX LNKIX (linkid),
          INDEX GRPIX (groupid)
        ) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=utf8|,

        q|INSERT INTO ixusergroup VALUES (1,1,1,1)|,
        q|INSERT INTO ixusergroup VALUES (2,1,1,9)|,
        q|INSERT INTO ixusergroup VALUES (3,1,2,2)|,
        q|INSERT INTO ixusergroup VALUES (4,1,2,3)|,
        q|INSERT INTO ixusergroup VALUES (5,1,2,4)|,
        q|INSERT INTO ixusergroup VALUES (6,2,9,5)|,
        q|INSERT INTO ixusergroup VALUES (7,2,5,4)|,
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

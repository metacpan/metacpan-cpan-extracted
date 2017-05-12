#!/usr/bin/perl -w
use strict;

use Data::Dumper;
use Test::More;#  tests => 14;

use Labyrinth::Audit;
use Labyrinth::DBUtils;
use Labyrinth::Users;
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

    SetLogFile( FILE   => 'audit.log',
                USER   => 'labyrinth',
                LEVEL  => 4,
                CLEAR  => 1,
                CALLER => 1
        );

    # create new instance from Test::Database object
    $dbi = Labyrinth::DBUtils->new(\%options);
    isa_ok($dbi,'Labyrinth::DBUtils');

    is(GetUser(),undef);
    my $user = GetUser(1);
    is($user->{realname},'Guest');

    is(UserName(),undef);
    is(UserName(1),'Guest');
    is(UserName(2),'Master');
    is(UserID(),undef);
    is(UserID('Guest'),1);

    my $pass = FreshPassword();
    is(length $pass,10);

    is(PasswordCheck(),         6, '.. no string');
    is(PasswordCheck('a b c'),  4, '.. spaces');
    is(PasswordCheck('aaaa'),   5, '.. too few unique characters');

    $settings{minpasslen} = 4;
    is(PasswordCheck('abc'),    1, '.. too short');
    is(PasswordCheck('abcd'),   3, '.. only 1 type');

    $settings{maxpasslen} = 5;
    is(PasswordCheck('abcdef'), 2, '.. too long');
    is(PasswordCheck('4Bc;'),   0, '.. valid');

    is(UserSelect(),        '<select id="userid" name="userid" multiple="multiple" size="5"><option value="3">Test User</option></select>');
    is(UserSelect(2),       '<select id="userid" name="userid" multiple="multiple" size="5"><option value="3">Test User</option></select>');
    is(UserSelect(2,2),     '<select id="userid" name="userid" multiple="multiple" size="2"><option value="3">Test User</option></select>');
    is(UserSelect(2,1,1),   '<select id="userid" name="userid"><option value="0">Select Name</option><option value="3">Test User</option></select>');
    is(UserSelect(undef,1,1,'users'),           '<select id="users" name="users"><option value="0">Select Name</option><option value="3">Test User</option></select>');
    is(UserSelect(undef,1,1,'users','User'),    '<select id="users" name="users"><option value="0">Select User</option><option value="3">Test User</option></select>');
    is(UserSelect(undef,1,1,'users','User',1),  '<select id="users" name="users"><option value="0">Select User</option><option value="1">Guest (Guest)</option><option value="2">(Master)</option><option value="3">Test User</option></select>');

    my @sql = (
        q|INSERT INTO users VALUES (4,1,1,'','','who@example.com','public',SHA1('Who'),'','',1)|,
    );
    dosql($td,\@sql);
    is(UserSelect(undef,1,1,'users','User',1),  '<select id="users" name="users"><option value="0">Select User</option><option value="1">Guest (Guest)</option><option value="2">(Master)</option><option value="3">Test User</option><option value="4">No Name Given</option></select>');


    # clean up
    $td->{driver}->drop_database($td->name);
}

sub create_mysql_databases {
    my $db = shift;

    my @create_example = (
        q|DROP TABLE IF EXISTS users|,
        q|CREATE TABLE users (
          userid int(10) unsigned NOT NULL AUTO_INCREMENT,
          accessid int(10) unsigned NOT NULL DEFAULT '1',
          imageid int(10) unsigned NOT NULL DEFAULT '1',
          nickname varchar(255) DEFAULT NULL,
          realname varchar(255) DEFAULT NULL,
          email varchar(255) DEFAULT NULL,
          realm varchar(32) DEFAULT NULL,
          password varchar(255) DEFAULT NULL,
          url varchar(255) DEFAULT NULL,
          aboutme blob,
          search int(1) NOT NULL DEFAULT '1',
          PRIMARY KEY (userid),
          INDEX ACSIX (accessid),
          INDEX IMGIX (imageid),
          INDEX RLMIX (realm)
        ) ENGINE=MyISAM AUTO_INCREMENT=7 DEFAULT CHARSET=utf8|,

        q|INSERT INTO users VALUES (1,1,1,'Guest','Guest','GUEST','public',SHA1('GUEST'),NULL,NULL,0)|,
        q|INSERT INTO users VALUES (2,5,1,'Master',NULL,'master@example.com','admin',SHA1('Master'),'','',0)|,
        q|INSERT INTO users VALUES (3,1,1,'','Test User','testuser@example.com','public',SHA1('testUser'),'http://example.com','<p>test user</p>',1)|,

        q|DROP TABLE IF EXISTS images|,
        q|CREATE TABLE images (
          imageid int(10) unsigned NOT NULL AUTO_INCREMENT,
          tag varchar(255) DEFAULT NULL,
          link varchar(255) DEFAULT NULL,
          type int(4) DEFAULT NULL,
          href varchar(255) DEFAULT NULL,
          dimensions varchar(255) DEFAULT NULL,
          PRIMARY KEY (imageid),
          INDEX TYPIX (type)
        ) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=utf8|,

        q|INSERT INTO images VALUES (1,'a blank space','images/blank.png',1,NULL,NULL)|,
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


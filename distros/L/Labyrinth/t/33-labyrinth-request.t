#!/usr/bin/perl -w
use strict;

use Data::Dumper;
use Test::More;#  tests => 14;

use Labyrinth::Audit;
use Labyrinth::DBUtils;
use Labyrinth::Request;
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

    $settings{requests} = 'dbi';

    my $request = Labyrinth::Request->new('public','home-main');
    isa_ok($request,'Labyrinth::Request');

    is($request->next_action,'Content::GetVersion');
    is($request->next_action,'Hits::SetHits');
    is($request->next_action,'Menus::LoadMenus');
    is($request->next_action,undef);
    is($request->add_actions('Content::One','Content::Two','Content::Three'),3);
    is($request->next_action,'Content::One');
    $request->reset_request('home-admin');
    is($request->next_action,'Content::Admin');

    $request->reset_realm('admin');
    is($request->next_action,'Content::GetVersion');

    $ENV{HTTP_HOST}     = 'example.com';
    $ENV{REQUEST_URI}   = '/path';

    $request->redirect();
    is($tvars{redirect},undef);
    $request->redirect('http');
    is($tvars{redirect},'http://example.com/path');
    $request->redirect('http','/test');
    is($tvars{redirect},'http://example.com/test');
    $request->redirect('http',undef,'home-main');
    is($tvars{redirect},'http://example.com/path?act=home-main');
    $request->redirect('http',undef,'');
    is($tvars{redirect},'http://example.com/path');

    is($request->layout,    'admin/layout.html');
    is($request->content,   'admin/backend_index.html');

    $request->reset_request('home-test');
    is($request->onsuccess, 'home-main');
    is($request->onerror,   'error-badaccess');
    is($request->onfailure, 'error-badcmd');

    # clean up
    $td->{driver}->drop_database($td->name);
}

sub create_sqlite_databases {
    my $db = shift;

    my @create_example = (
        'PRAGMA auto_vacuum = 1',
        q|DROP TABLE IF EXISTS requests|,
        q|CREATE TABLE requests (
          section   TEXT,
          command   TEXT,
          actions   TEXT,
          layout    TEXT,
          content   TEXT,
          onsuccess TEXT,
          onerror   TEXT,
          onfailure TEXT,
          secure    TEXT,
          rewrite   TEXT,
          PRIMARY KEY (section,command)
        )|,

        q|INSERT INTO requests VALUES ('realm','admin','Content::GetVersion,Menus::LoadMenus','admin/layout.html','','','','','off','')|,
        q|INSERT INTO requests VALUES ('realm','popup','','public/popup.html','','','','','off','')|,
        q|INSERT INTO requests VALUES ('realm','public','Content::GetVersion,Hits::SetHits,Menus::LoadMenus','public/layout.html','','','','','off','')|,
        q|INSERT INTO requests VALUES ('error','badmail','','','public/badmail.html','','','','off','')|,
        q|INSERT INTO requests VALUES ('error','badcmd','','','public/badcommand.html','','','','off','')|,
        q|INSERT INTO requests VALUES ('error','banuser','','','public/banuser.html','','','','off','')|,
        q|INSERT INTO requests VALUES ('error','badaccess','Users::LoggedIn','','public/badaccess.html','','error-login','','off','')|,
        q|INSERT INTO requests VALUES ('error','baduser','','','public/baduser.html','','','','off','')|,
        q|INSERT INTO requests VALUES ('error','login','Users::Store','','users/user-login.html','','','','off','')|,
        q|INSERT INTO requests VALUES ('error','message','','','public/error_message.html','','','','off','')|,
        q|INSERT INTO requests VALUES ('home','admin','Content::Admin','','admin/backend_index.html','','','','off','')|,
        q|INSERT INTO requests VALUES ('home','main','Content::Home','','content/welcome.html','','','','off','')|,
        q|INSERT INTO requests VALUES ('home','test','Content::Test','','','home-main','error-badaccess','error-badcmd','off','')|,
    );

    dosql($db,\@create_example);
}

sub create_mysql_databases {
    my $db = shift;

    my @create_example = (
        q|DROP TABLE IF EXISTS requests|,
        q|CREATE TABLE requests (
          section varchar(15) NOT NULL,
          command varchar(15) NOT NULL,
          actions varchar(1000) DEFAULT NULL,
          layout varchar(255) DEFAULT NULL,
          content varchar(255) DEFAULT NULL,
          onsuccess varchar(32) DEFAULT NULL,
          onerror varchar(32) DEFAULT NULL,
          onfailure varchar(32) DEFAULT NULL,
          secure enum('off','on','either','both') DEFAULT 'off',
          rewrite varchar(255) DEFAULT NULL,
          PRIMARY KEY (section,command)
        ) ENGINE=MyISAM DEFAULT CHARSET=utf8|,

        q|INSERT INTO requests VALUES ('realm','admin','Content::GetVersion,Menus::LoadMenus','admin/layout.html','','','','','off','')|,
        q|INSERT INTO requests VALUES ('realm','popup','','public/popup.html','','','','','off','')|,
        q|INSERT INTO requests VALUES ('realm','public','Content::GetVersion,Hits::SetHits,Menus::LoadMenus','public/layout.html','','','','','off','')|,
        q|INSERT INTO requests VALUES ('error','badmail','','','public/badmail.html','','','','off','')|,
        q|INSERT INTO requests VALUES ('error','badcmd','','','public/badcommand.html','','','','off','')|,
        q|INSERT INTO requests VALUES ('error','banuser','','','public/banuser.html','','','','off','')|,
        q|INSERT INTO requests VALUES ('error','badaccess','Users::LoggedIn','','public/badaccess.html','','error-login','','off','')|,
        q|INSERT INTO requests VALUES ('error','baduser','','','public/baduser.html','','','','off','')|,
        q|INSERT INTO requests VALUES ('error','login','Users::Store','','users/user-login.html','','','','off','')|,
        q|INSERT INTO requests VALUES ('error','message','','','public/error_message.html','','','','off','')|,
        q|INSERT INTO requests VALUES ('home','admin','Content::Admin','','admin/backend_index.html','','','','off','')|,
        q|INSERT INTO requests VALUES ('home','main','Content::Home','','content/welcome.html','','','','off','')|,
        q|INSERT INTO requests VALUES ('home','test','Content::Test','','','home-main','error-badaccess','error-badcmd','off','')|,
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

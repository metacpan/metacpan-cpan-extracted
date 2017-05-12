#!/usr/bin/perl -w
use strict;

use Data::Dumper;
use Test::More;#  tests => 14;

use Labyrinth::Audit;
use Labyrinth::DBUtils;
use Labyrinth::Metadata;
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

    $tvars{cgipath} = 'http://test/cgi-bin';

    is(MetaSearch(),undef);
    is(MetaSearch( 'keys' => [] ),undef);
    is(MetaSearch( 'keys' => ['Image'] ),undef);
    is(MetaSearch( 'keys' => ['Image'], 'meta' => ['music'] ),2);
    is(MetaSearch( 'keys' => ['Image'], 'meta' => ['jodrell'] ),0);
    is(MetaSearch( 'keys' => ['Image'], 'meta' => ['jodrell'], full => 1 ),1);

    my @search = MetaSearch( 'keys' => ['Image'], 'meta' => ['cheshire'], sort => 'desc', order => 'tag' );
    is($search[0]->{tag},'joy division');
    is($search[1]->{tag},'jodrell bank');
    @search = MetaSearch( 'keys' => ['Image'], 'meta' => ['cheshire'], sort => 'asc', order => 'tag' );
    is($search[0]->{tag},'jodrell bank');
    is($search[1]->{tag},'joy division');

    is(MetaSave(),undef);
    is(MetaSave(1),undef);
    is(MetaGet(1,'Image'),'empty');
    is(MetaSave(1,['Image']),0);
    is(MetaGet(1,'Image'),undef);
    is(MetaSave(1,['Image'],'this','that'),2);
    is(MetaGet(1,'Image'),'that this');

    is(MetaGet(),undef);
    is(MetaGet(1),undef);
    is(MetaGet(undef,'Image'),undef);

    my @list = MetaGet(1);
    is_deeply(\@list,[]);

    @list = MetaGet(1,'Image');
    is_deeply(\@list,['that','this']);

    is(MetaCloud(),undef);
    is(MetaCloud( key => 'Image' ),undef);
    is(MetaCloud( key => 'Image', sectionid => 1 ),undef);
    is(MetaCloud( key => 'Image', sectionid => 1, actcode => 'meta-search' ),'<div id="htmltagcloud">
<span class="tagcloud5"><a href="http://test/cgi-bin/pages.cgi?act=meta-search&amp;data=cheshire">cheshire</a></span>
<span class="tagcloud5"><a href="http://test/cgi-bin/pages.cgi?act=meta-search&amp;data=music">music</a></span>
<span class="tagcloud0"><a href="http://test/cgi-bin/pages.cgi?act=meta-search&amp;data=science">science</a></span>
<span class="tagcloud0"><a href="http://test/cgi-bin/pages.cgi?act=meta-search&amp;data=that">that</a></span>
<span class="tagcloud0"><a href="http://test/cgi-bin/pages.cgi?act=meta-search&amp;data=this">this</a></span>
</div>');

    is(MetaTags(),undef);
    is(MetaTags( key => 'Image' ),undef);
    is(MetaTags( key => 'Image', sectionid => 1 ),5);

    # clean up
    $td->{driver}->drop_database($td->name);
}

sub create_sqlite_databases {
    my $db = shift;

    my @create_example = (
        'PRAGMA auto_vacuum = 1',
        q|DROP TABLE IF EXISTS images|,
        q|CREATE TABLE images (
          imageid       INTEGER,
          tag           TEXT,
          link          TEXT,
          type          INTEGER,
          href          TEXT,
          dimensions    TEXT,
          PRIMARY KEY (imageid)
        )|,

        q|INSERT INTO images VALUES (1,'a blank space','images/blank.png',1,NULL,NULL)|,
        q|INSERT INTO images VALUES (2,'nine inch nails','images/nineinchnails.png',1,NULL,NULL)|,
        q|INSERT INTO images VALUES (3,'jodrell bank','images/jodrellbank.png',1,'http://umist.ac.uk',NULL)|,
        q|INSERT INTO images VALUES (4,'joy division','images/joydivision.png',1,NULL,NULL)|,


        q|DROP TABLE IF EXISTS imetadata|,
        q|CREATE TABLE imetadata (
          imageid       INTEGER,
          tag           TEXT,
          PRIMARY KEY (imageid,tag)
        )|,

        q|INSERT INTO imetadata VALUES (1,'empty')|,
        q|INSERT INTO imetadata VALUES (2,'music')|,
        q|INSERT INTO imetadata VALUES (3,'cheshire')|,
        q|INSERT INTO imetadata VALUES (3,'science')|,
        q|INSERT INTO imetadata VALUES (4,'cheshire')|,
        q|INSERT INTO imetadata VALUES (4,'music')|,
    );

    dosql($db,\@create_example);
}

sub create_mysql_databases {
    my $db = shift;

    my @create_example = (
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
        q|INSERT INTO images VALUES (2,'nine inch nails','images/nineinchnails.png',1,NULL,NULL)|,
        q|INSERT INTO images VALUES (3,'jodrell bank','images/jodrellbank.png',1,'http://umist.ac.uk',NULL)|,
        q|INSERT INTO images VALUES (4,'joy division','images/joydivision.png',1,NULL,NULL)|,


        q|DROP TABLE IF EXISTS imetadata|,
        q|CREATE TABLE imetadata (
          imageid int(10) unsigned NOT NULL DEFAULT '0',
          tag varchar(255) NOT NULL DEFAULT '',
          PRIMARY KEY (imageid,tag)
        ) ENGINE=MyISAM DEFAULT CHARSET=utf8|,

        q|INSERT INTO imetadata VALUES (1,'empty')|,
        q|INSERT INTO imetadata VALUES (2,'music')|,
        q|INSERT INTO imetadata VALUES (3,'cheshire')|,
        q|INSERT INTO imetadata VALUES (3,'science')|,
        q|INSERT INTO imetadata VALUES (4,'cheshire')|,
        q|INSERT INTO imetadata VALUES (4,'music')|,
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

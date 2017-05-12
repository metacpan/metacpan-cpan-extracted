#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 32;

use Class::Load;
use Try::Tiny;
use Carp;
use Data::Dump qw( dump );

use_ok('Dezi::Test::Indexer');
use_ok('Dezi::Test::Searcher');

my $num_tests = 30;

# we use Rose::DBx::TestDB just for devel testing.
# don't expect normal users to have it.
SKIP: {

    my @required = qw(
        Dezi::Aggregator::DBI
        DBI
        Rose::DBx::TestDB
    );
    for my $cls (@required) {
        diag("Checking on $cls");
        my $missing;
        my $loaded = try {
            Class::Load::load_class($cls);
        }
        catch {
            warn $_;
            if ( $_ =~ m/Can't locate (\S+)/ ) {
                $missing = $1;
                $missing =~ s/\//::/g;
                $missing =~ s/\.pm//;
            }
            return 0;
        };
        if ( !$loaded ) {
            if ($missing) {
                diag( '-' x 40 );
                diag("Do you need to install $missing ?");
                diag( '-' x 40 );
            }
            skip "$cls required for spider test", $num_tests;
            last;
        }
    }

    # create db.
    my $db = Rose::DBx::TestDB->new;

    my $dbh = $db->retain_dbh;

    # put some data in it.
    $dbh->do( "
    CREATE TABLE foo (
        id      integer primary key autoincrement,
        myint   integer not null default 0,
        mychar  varchar(16),
        mydate  integer not null default 1
    );
    " )
        or croak "create failed: " . $dbh->errstr;

    $dbh->do( "
        INSERT INTO foo (myint, mychar, mydate) VALUES (100, 'hello', 1000000);
    " ) or croak "insert failed: " . $dbh->errstr;

    my $sth = $dbh->prepare("SELECT * from foo");
    $sth->execute;

    # index it
    ok( my $aggr = Dezi::Aggregator::DBI->new(
            db      => $dbh,
            indexer => Dezi::Test::Indexer->new( invindex => 't/dbi.index', ),
            schema  => {
                foo => {
                    id     => { type => 'int' },
                    myint  => { type => 'int', bias => 10 },
                    mychar => { type => 'char' },
                    mydate => { type => 'date' },
                    swishtitle       => 'id',
                    swishdescription => { mychar => 1, mydate => 1 },
                }
            },
        ),
        "new aggregator"
    );

    ok( $aggr->indexer->start, "indexer started" );

    is( $aggr->crawl(), 1, "row data indexed" );

    ok( $aggr->indexer->finish, "indexer finished" );

    my $invindex = $aggr->indexer->invindex;

    ok( my $searcher = Dezi::Test::Searcher->new(
            invindex      => $invindex,
            swish3_config => $aggr->indexer->swish3->get_config,
        ),
        "new searcher"
    );

    my $query = 'hello';
    ok( my $results
            = $searcher->search( $query, { order => 'swishdocpath ASC' } ),
        "do search"
    );
    is( $results->hits, 1, "1 hit" );
    ok( my $result = $results->next, "results->next" );
    diag( $result->swishdocpath );
    is( $result->swishtitle, '1', "get swishtitle" );
    is( $result->get_property('swishtitle'),
        $result->swishtitle, "get_property(swishtitle)" );

    # test all the built-in properties and their method shortcuts
    my @methods = qw(
        swishdocpath
        uri
        swishlastmodified
        mtime
        swishtitle
        title
        swishdescription
        summary
        swishrank
        score
    );

    for my $m (@methods) {
        ok( defined $result->$m,               "get $m" );
        ok( defined $result->get_property($m), "get_property($m)" );
    }

}

# clean up header so other test counts work
unlink('t/dbi.index/swish.xml') unless $ENV{DEZI_DEBUG};


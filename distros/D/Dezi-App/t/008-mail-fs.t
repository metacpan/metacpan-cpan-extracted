#!/usr/bin/env perl

# This test is nearly identical to 04_mail.t except
# that we don't create 'new' 'tmp' and 'cur'
# subdirs to mimic the maildir format
# and instead just assume every file in a tree
# is one email message.

use strict;
use warnings;
use Test::More tests => 12;
use Try::Tiny;
use Class::Load;
use Path::Class::Dir;
use Data::Dump qw( dump );

use_ok('Dezi::Test::Indexer');
use_ok('Dezi::Test::InvIndex');
use_ok('Dezi::Test::Searcher');

my $num_tests = 9;

SKIP: {

    my @required = qw(
        Mail::Box
        Dezi::Aggregator::MailFS
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

    # is executable present?
    my $indexer = Dezi::Test::Indexer->new(
        verbose  => $ENV{DEZI_DEBUG},
        debug    => $ENV{DEZI_DEBUG},
        invindex => Dezi::Test::InvIndex->new( path => 'no/such/path' ),
    );

    ok( my $mail = Dezi::Aggregator::MailFS->new(
            indexer => $indexer,
            verbose => $ENV{DEZI_DEBUG},
            debug   => $ENV{DEZI_DEBUG},
        ),
        "new mail aggregator"
    );

    $ENV{DEZI_DEBUG} and diag( dump($mail) );

    ok( $mail->indexer->start, "start" );
    is( $mail->crawl('t/mailfs'), 1, "crawl" );
    ok( $mail->indexer->finish, "finish" );

    # test with a search
    ok( my $searcher = Dezi::Test::Searcher->new(
            invindex      => $indexer->invindex,
            swish3_config => $indexer->swish3->get_config,
        ),
        "new searcher"
    );

    my $query = 'test';
    ok( my $results
            = $searcher->search( $query, { order => 'swishdocpath ASC' } ),
        "do search"
    );
    is( $results->hits, 1, "1 hits" );
    ok( my $result = $results->next, "results->next" );
    diag( $result->swishdocpath );
    like(
        $result->swishdescription,
        qr/Peter Karman/,
        "get swishdescription"
    );

}

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
use Path::Class::File;
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

    my $mailfs = Path::Class::Dir->new( 't', 'mailfs' );
    my $mail_subdir = Path::Class::Dir->new( $mailfs, 'somedir', 'cur' );
    $mail_subdir->mkpath;
    my $email_fname = Path::Class::File->new( $mail_subdir,
        '1201404060.V802I5f9e4M893922.louvin.peknet.com:2,');
    my $email_content = do { local $/; <DATA> };
    open my $fh, ">", $email_fname or die "Could not open $email_fname: $!";
    print $fh $email_content;
    close $fh;

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

    # clean up
    $mailfs->rmtree();

}

__DATA__
Return-Path: <peter@peknet.com>
X-Original-To: swishtest@peknet.com
Delivered-To: swishtest@peknet.com
Received: from localhost (localhost.localdomain [127.0.0.1])
	by peknet.com (Postfix) with ESMTP id BDADD126E23
	for <swishtest@peknet.com>; Sat, 26 Jan 2008 21:21:00 -0600 (CST)
X-Virus-Scanned: amavisd-new at peknet.com
Received: from peknet.com ([127.0.0.1])
	by localhost (louvin.peknet.com [127.0.0.1]) (amavisd-new, port 10024)
	with ESMTP id ep8nklPQNilk for <swishtest@peknet.com>;
	Sat, 26 Jan 2008 21:20:57 -0600 (CST)
Received: from cenn-smtp.mc.mpls.visi.com (cenn.mc.mpls.visi.com [208.42.156.9])
	by peknet.com (Postfix) with ESMTP id 23068126DDE
	for <swishtest@peknet.com>; Sat, 26 Jan 2008 21:20:57 -0600 (CST)
Received: from dhcp2.peknet.com (karman.dsl.visi.com [209.98.116.241])
	by cenn-smtp.mc.mpls.visi.com (Postfix) with ESMTP id 6CB808129
	for <swishtest@peknet.com>; Sat, 26 Jan 2008 21:21:01 -0600 (CST)
Message-ID: <479BF89A.20602@peknet.com>
Date: Sat, 26 Jan 2008 21:20:58 -0600
From: Peter Karman <peter@peknet.com>
Reply-To: peter@peknet.com
User-Agent: Thunderbird 2.0.0.9 (Macintosh/20071031)
MIME-Version: 1.0
To: swishtest@peknet.com
Subject: test
Content-Type: text/plain; charset=UTF-8; format=flowed
Content-Transfer-Encoding: 7bit

hello world.
-- 
Peter Karman  .  http://peknet.com/  .  peter@peknet.com

use strict;
use warnings;
use Test::More tests => 5;
use Path::Class::Dir;
use Path::Class::File;
use Class::Load;
use Try::Tiny;

use_ok('Dezi::Test::Indexer');

my $num_tests = 4;

SKIP: {

    my @required = qw(
        Mail::Box
        Dezi::Aggregator::Mail
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
    my $indexer = Dezi::Test::Indexer->new( 'invindex' => 't/mail.index' );

    # maildir requires the 'cur', 'tmp' and 'new' dirs to exist
    my $maildir = Path::Class::Dir->new('t', 'maildir');
    for my $dirname (qw( cur tmp new )) {
        Path::Class::Dir->new( $maildir, $dirname )->mkpath;
        Path::Class::Dir->new( $maildir, '.INBOX', $dirname )->mkpath;
    }

    my $email_fname = Path::Class::File->new( $maildir, '.INBOX', 'cur',
        '1201404060.V802I5f9e4M893922.louvin.peknet.com:2,' );
    my $email_content = do { local $/; <DATA> };
    open my $fh, ">", $email_fname or die "Could not open $email_fname: $!";
    print $fh $email_content;
    close $fh;

    ok( my $mail = Dezi::Aggregator::Mail->new(
            indexer => $indexer,
            verbose => $ENV{DEZI_DEBUG},
        ),
        "new mail aggregator"
    );

    ok( $mail->indexer->start, "start" );
    is( $mail->crawl('t/maildir'), 1, "crawl" );
    ok( $mail->indexer->finish, "finish" );

    # clean up
    $maildir->rmtree();

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

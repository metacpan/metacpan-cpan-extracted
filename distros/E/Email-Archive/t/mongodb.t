#!/usr/bin/perl
use strict;
use warnings;
use Email::MIME;

use Test::More;
use Try::Tiny;

use Email::Archive;
use Email::Archive::Storage::MongoDB;

my $test_host        = 'localhost';
my $test_port        = 27017;
my $mongo_database   = 'EmailArchiveTestMongoDB';
my $mongo_collection = 'emails';

sub check_for_mongo {
    my ($host, $port) = @_;
    try {
        require Net::Telnet;
        my $telnet = Net::Telnet->new(
            Timeout => 10,
        );

        my $ok = $telnet->open(
            Host    => $host,
            Port    => $port,
        );

        return $ok;
    }
    catch {
        return 0;
    }
}

SKIP: {
    skip 'no MongoDB running or Net::Telnet not installed', 1
        unless check_for_mongo($test_host, $test_port);

    my $email = Email::MIME->create(
      header => [
        From    => 'foo@example.com',
        To      => 'drain@example.com',
        Subject => 'Message in a bottle',
        'Message-ID' => 'helloworld',
      ],
      body => 'hello there!'
    );

    my $storage = Email::Archive::Storage::MongoDB->new(
      host       => $test_host,
      port       => $test_port,
      database   => $mongo_database,
      collection => $mongo_collection,
    );

    my $e = Email::Archive->new(
      storage => $storage,
    );

    $e->connect;
    $e->store($email);

    my $found = $e->retrieve('helloworld');

    $found = $e->retrieve('helloworld');
    cmp_ok($found->header('subject'), 'eq', "Message in a bottle",
      "can find stored message by ID");

    # cleanup
    my $conn = MongoDB::Connection->new(
        host => $test_host,
        port => $test_port,
    );

    $conn->$mongo_database->drop;

}

done_testing;


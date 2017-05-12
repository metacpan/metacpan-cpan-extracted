#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 8;

use DBI;
use File::Temp;
use FindBin '$Bin';

my $tf = File::Temp->new;

my $source = 'dbi:SQLite:' . $tf->filename;

# Prepare database
my $schema_file = "$Bin/../../schema/database.sqlite.sql";
open my $fh, '<:encoding(UTF-8)', $schema_file
  or die qq(Can't open schema "$schema_file": $!);
my $schema = do { local $/; <$fh> };
close $fh;

my $dbh = DBI->connect($source);
$dbh->{RaiseError} = 1;
my @sql = split /\s*;\s*/, $schema;
$dbh->do($_) foreach @sql;

use_ok 'JLogger::Storage::DB';

my $storage = new_ok 'JLogger::Storage::DB', [source => $source];

my $message = {
    'to'           => 'rec@server.com/res1',
    'from'         => 'sender@server.com',
    'type'         => 'message',
    'id'           => 'message_id',
    'message_type' => 'chat',
    'body'         => 'body text',
    'thread'       => 'thread1',
};
$storage->store($message);

my $sth = $dbh->prepare(<<'SQL');
SELECT 
    sender.jid || COALESCE('/' || sender_resource, '') AS sender,
    recipient.jid || COALESCE('/' || recipient_resource, '') AS recipient,
    message.id, message.type, message.body, message.thread
FROM messages message
JOIN identificators sender
    ON sender.id = message.sender
JOIN identificators recipient
    ON recipient.id = message.recipient
SQL

$sth->execute;
my $row = $sth->fetchrow_hashref;

is $row->{recipient}, $message->{to},           'message recipient';
is $row->{sender},    $message->{from},         'message sender';
is $row->{id},        $message->{id},           'message id';
is $row->{type},      $message->{message_type}, 'message type';
is $row->{body},      $message->{body},         'message body';
is $row->{thread},    $message->{thread},       'message thread';

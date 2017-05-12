#!/usr/bin/env perl
use warnings;
use strict;

use Jifty::Test::Dist tests => 4;

sub TestApp::Plugin::RecordHistory::Model::Book::__create {
    return 0;
}

my $book = TestApp::Plugin::RecordHistory::Model::Book->new;
$book->create(
    title => '1984',
);
ok(!$book->id, 'did not create a book');

isa_ok($book->changes, 'Jifty::Plugin::RecordHistory::Model::ChangeCollection');
is($book->changes->count, 0, 'no changes');

my $all_changes = Jifty::Plugin::RecordHistory::Model::ChangeCollection->new;
$all_changes->unlimit;
is($all_changes->count, 0, 'no changes at all');


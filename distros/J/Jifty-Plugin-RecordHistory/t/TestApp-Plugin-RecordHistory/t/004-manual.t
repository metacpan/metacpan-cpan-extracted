#!/usr/bin/env perl
use warnings;
use strict;

use Jifty::Test::Dist tests => 11;

my $book = TestApp::Plugin::RecordHistory::Model::Book->new;
$book->create(
    title  => '1984',
    author => 'George Orwell',
);
ok($book->id, 'created a book');

is($book->changes->count, 1);

$book->start_change;
$book->end_change;

is($book->changes->count, 1, 'a change with no updates should not create a Change');

$book->start_change;
$book->set_title('Brave New World');
$book->set_author('Aldous Huxley');
$book->end_change;
my $change = $book->changes->last;
is($change->type, 'update', 'second change is the update');
is($change->change_fields->count, 2, 'two fields updated');

my @change_fields = sort { $a->field cmp $b->field } @{ $change->change_fields->items_array_ref };
is($change_fields[0]->field, 'author', 'first update is to author');
is($change_fields[0]->old_value, 'George Orwell', 'old value of author is George');
is($change_fields[0]->new_value, 'Aldous Huxley', 'new value of author is Aldous');

is($change_fields[1]->field, 'title', 'second update is to title');
is($change_fields[1]->old_value, '1984', 'old value of author is 1984');
is($change_fields[1]->new_value, 'Brave New World', 'new value of author is BNW');


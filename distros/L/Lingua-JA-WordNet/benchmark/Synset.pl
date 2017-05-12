#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use DBI;
use Benchmark qw/cmpthese timethese/;

my $dbh = DBI->connect("dbi:SQLite:dbname=../share/wnjpn-1.1.db", '', '', {
    RaiseError     => 1,
    PrintError     => 0,
    AutoCommit     => 0,
    sqlite_unicode => 1,
});


cmpthese(
    timethese(-1, {
        'synset1' => sub { Synset1('相撲', 'jpn') },
        'synset2' => sub { Synset2('相撲', 'jpn') },
        'synset3' => sub { Synset3('相撲', 'jpn') },
    })
);


sub Synset1
{
    my ($word, $lang) = @_;

    my $sth
        = $dbh->prepare
        (
            'SELECT synset FROM word LEFT JOIN sense ON word.wordid = sense.wordid
              WHERE lemma      = ?
                AND sense.lang = ?'
        );

    $sth->execute($word, $lang);

    my (@synsets, $synset);

    $sth->bind_columns( \($synset) );

    while ($sth->fetchrow_arrayref)
    {
        push(@synsets, $synset);
    }

    Carp::carp "Synset: there are no synsets for $word in $lang" unless scalar @synsets;

    return @synsets;
}


sub Synset2
{
    my ($word, $lang) = @_;

    my $sth
        = $dbh->prepare
        (
            'SELECT synset FROM word LEFT JOIN sense ON word.wordid = sense.wordid
              WHERE lemma      = ?
                AND sense.lang = ?'
        );

    $sth->execute($word, $lang);

    my @synsets = map {$_->[0]} @{$sth->fetchall_arrayref};

    Carp::carp "Synset: there are no synsets for $word in $lang" unless scalar @synsets;

    return @synsets;
}


sub Synset3
{
    my ($word, $lang) = @_;

    my $sth
        = $dbh->prepare
        (
            'SELECT synset FROM word LEFT JOIN sense ON word.wordid = sense.wordid
              WHERE lemma      = ?
                AND sense.lang = ?'
        );

    $sth->execute($word, $lang);

    my @synsets;

    while (my $row = $sth->fetchrow_arrayref)
    {
        my $synset = $row->[0];
        push(@synsets, $synset);
    }

    Carp::carp "Synset: there are no synsets for $word in $lang" unless scalar @synsets;

    return @synsets;
}

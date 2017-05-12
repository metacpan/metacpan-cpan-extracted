#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use DBI;
use List::MoreUtils ();
use Benchmark qw/cmpthese timethese/;

my $dbh = DBI->connect("dbi:SQLite:dbname=../share/wnjpn-1.1_and_synonyms-1.0.db", '', '', {
    RaiseError     => 1,
    PrintError     => 0,
    AutoCommit     => 0,
    sqlite_unicode => 0,
});


cmpthese(
    timethese(-1, {
        'Synonyms'  => sub { Synonyms('167486')  },
        #'Synonyms0' => sub { Synonyms0('167486') },
        #'Synonyms1' => sub { Synonyms1('167486') },
        #'Synonyms2' => sub { Synonyms2('167486') },
        #'Synonyms3' => sub { Synonyms3('167486') },
        'Word'      => sub { Word('02799071-n')  },
    })
);


sub Synonyms
{
    my ($wordid) = @_;

    my $sth
        = $dbh->prepare
        (
            'SELECT lemma FROM word JOIN wordlink ON word.wordid = wordlink.wordid2
              WHERE wordid1 = ?
                AND link    = ?'
        );

    $sth->execute($wordid, 'syns');
    my @synonyms = map {$_->[0]} @{$sth->fetchall_arrayref};

    Carp::carp "Synonyms: there are no Synonyms for $wordid" unless scalar @synonyms;

    # 一応順番を保持したいのでハッシュスライスは使わない
    # uniq: The order of elements in the returned list is the same as in LIST.
    return List::MoreUtils::uniq @synonyms;
}

=begin
sub Synonyms0
{
    my ($wordid) = @_;

    my $sth
        = $dbh->prepare
        (
            'SELECT lemma FROM word JOIN wordlink ON word.wordid = wordlink.wordid2
              WHERE wordid1 = ?'
        );

    # ある文で「ごはん」を「めし」に書き換え可能ならば「めし」を「ごはん」に書き換えることも可能
    my $reverse_sth
        = $dbh->prepare
        (
            'SELECT lemma FROM word JOIN wordlink ON word.wordid = wordlink.wordid1
              WHERE wordid2 = ?'
        );

    $sth->execute($wordid);
    my @synonyms = map {$_->[0]} @{$sth->fetchall_arrayref};

    $reverse_sth->execute($wordid);
    push(@synonyms, map {$_->[0]} @{$reverse_sth->fetchall_arrayref});

    Carp::carp "Synonyms: there are no Synonyms for $wordid" unless scalar @synonyms;

    # 一応順番を保持したいのでハッシュスライスは使わない
    # uniq: The order of elements in the returned list is the same as in LIST.
    return List::MoreUtils::uniq @synonyms;
}

sub Synonyms1
{
    my ($wordid) = @_;

    my $sth
        = $dbh->prepare
        (
            'SELECT lemma FROM word JOIN wordlink ON word.wordid = wordlink.wordid2
              WHERE wordid1 = ?
                AND link    = ?'
        );

    # ある文で「ごはん」を「めし」に書き換え可能ならば「めし」を「ごはん」に書き換えることも可能
    my $reverse_sth
        = $dbh->prepare
        (
            'SELECT lemma FROM word JOIN wordlink ON word.wordid = wordlink.wordid1
              WHERE wordid2 = ?
                AND link    = ?'
        );

    $sth->execute($wordid, 'syns');
    my @synonyms = map {$_->[0]} @{$sth->fetchall_arrayref};

    $reverse_sth->execute($wordid, 'syns');
    push(@synonyms, map {$_->[0]} @{$reverse_sth->fetchall_arrayref});

    Carp::carp "Synonyms: there are no Synonyms for $wordid" unless scalar @synonyms;

    # 一応順番を保持したいのでハッシュスライスは使わない
    # uniq: The order of elements in the returned list is the same as in LIST.
    return List::MoreUtils::uniq @synonyms;
}


sub Synonyms2
{
    my ($wordid) = @_;

    my $sth
        = $dbh->prepare
        (
            'SELECT lemma FROM word JOIN wordlink ON word.wordid = wordlink.wordid2
              WHERE wordid1 = ?
                AND link    = ?
              UNION
             SELECT lemma FROM word JOIN wordlink ON word.wordid = wordlink.wordid1
              WHERE wordid2 = ?
                AND link    = ?'
        );

    $sth->execute($wordid, 'syns', $wordid, 'syns');
    my @synonyms = map {$_->[0]} @{$sth->fetchall_arrayref};

    Carp::carp "Synonyms: there are no Synonyms for $wordid" unless scalar @synonyms;

    # 一応順番を保持したいのでハッシュスライスは使わない
    # uniq: The order of elements in the returned list is the same as in LIST.
    return List::MoreUtils::uniq @synonyms;
}


sub Synonyms3
{
    my ($wordid) = @_;

    my $sth
        = $dbh->prepare
        (
            'SELECT lemma FROM word
              WHERE wordid IN (
                  SELECT wordid1 FROM wordlink
                   WHERE wordid2 = ?
                     AND link    = ?
                   UNION
                  SELECT wordid2 FROM wordlink
                   WHERE wordid1 = ?
                     AND link    = ?)'
        );

    $sth->execute($wordid, 'syns', $wordid, 'syns');
    my @synonyms = map {$_->[0]} @{$sth->fetchall_arrayref};

    Carp::carp "Synonyms: there are no Synonyms for $wordid" unless scalar @synonyms;

    # 一応順番を保持したいのでハッシュスライスは使わない
    # uniq: The order of elements in the returned list is the same as in LIST.
    return List::MoreUtils::uniq @synonyms;
}
=end
=cut


sub Word
{
    my ($synset, $lang) = @_;

    $lang = 'jpn' unless defined $lang;

    my $sth
        = $dbh->prepare
        (
            'SELECT lemma FROM word JOIN sense ON word.wordid = sense.wordid
              WHERE synset     = ?
                AND sense.lang = ?'
        );

    $sth->execute($synset, $lang);

    my @words = map { $_->[0] =~ tr/_/ /; $_->[0]; } @{$sth->fetchall_arrayref};

    Carp::carp "Word: there are no words for $synset in $lang" unless scalar @words;

    return @words;
}

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
        'AllSynsets1' => sub { my @synsets = AllSynsets1(); },
        'AllSynsets2' => sub { my $synsets = AllSynsets2(); },
    })
);


sub AllSynsets1
{
    my $sth = $dbh->prepare('SELECT synset FROM synset');
    $sth->execute;
    my @synsets = map {$_->[0]} @{$sth->fetchall_arrayref};
    return @synsets;
}


sub AllSynsets2
{
    my $sth = $dbh->prepare('SELECT synset FROM synset');
    $sth->execute;
    my @synsets = map {$_->[0]} @{$sth->fetchall_arrayref};
    return \@synsets;
}

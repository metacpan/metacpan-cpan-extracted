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
        'Def1' => sub { Def1('02799071-n', 'jpn') },
        'Def2' => sub { Def2('02799071-n', 'jpn') },
    })
);


sub Def1
{
    my ($synset, $lang) = @_;

    my $sth
        = $dbh->prepare
        (
            'SELECT sid, def FROM synset_def
              WHERE synset = ?
                AND lang   = ?'
        );

    $sth->execute($synset, $lang);

    my (@defs, $sid, $def);

    $sth->bind_columns( \($sid, $def) );

    while ($sth->fetchrow_arrayref)
    {
        $defs[$sid] = $def;
    }

    Carp::carp "Def: there are no definition sentences for $synset in $lang" unless scalar @defs;

    return @defs;
}


sub Def2
{
    my ($synset, $lang) = @_;

    my $sth
        = $dbh->prepare
        (
            'SELECT sid, def FROM synset_def
              WHERE synset = ?
                AND lang   = ?'
        );

    $sth->execute($synset, $lang);

    my @defs;

    while (my $row = $sth->fetchrow_arrayref)
    {
        my ($sid, $def) = @{$row};
        $defs[$sid] = $def;
    }

    Carp::carp "Def: there are no definition sentences for $synset in $lang" unless scalar @defs;

    return @defs;
}

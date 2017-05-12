use strict;
use warnings;
use utf8;
use DBI;
use Test::More;

my $dbh = DBI->connect("dbi:SQLite:dbname=./share/wnjpn-1.1_and_synonyms-1.0.db", '', '', {
    RaiseError     => 1,
    PrintError     => 0,
    AutoCommit     => 1,
    sqlite_unicode => 1,
});

my $sth = $dbh->prepare('SELECT wordid1, wordid2, link, src FROM wordlink');
$sth->execute;

my %dup;

while(my $row = $sth->fetchrow_arrayref)
{
    my ($wordid1, $wordid2, $link, $src) = @{$row};

    $dup{"${wordid1}${wordid2}"}++;

    like($wordid1, qr/^[0-9]+$/);
    like($wordid2, qr/^[0-9]+$/);
    is($link, 'syns');
    is($src, 'NICT Japanese WordNet Synonyms Database ver.1.0');
}

for my $key (keys %dup)
{
    is($dup{$key}, 1); # 重複は許さない
}

done_testing;

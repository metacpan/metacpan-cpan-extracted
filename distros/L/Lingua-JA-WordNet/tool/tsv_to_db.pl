#!/usr/bin/env perl

# 日本語 WordNet 同義対データベース ver.1.0
# のTSVデータをDB(SQLite3)に挿入します。

use strict;
use warnings;
use feature qw/say/;
use DBI;
use Smart::Comments;

my $DB_FILE  = './wnjpn.db';
my $TSV_FILE = './jwn_synonyms.ver.1.0';
my $SRC      = 'NICT Japanese WordNet Synonyms Database ver.1.0';

my $DBH = DBI->connect("dbi:SQLite:dbname=$DB_FILE", '', '', {
    RaiseError     => 1,
    PrintError     => 0,
    AutoCommit     => 1,
    sqlite_unicode => 0,
});

create_wordlink_table();
create_index();
#check_format();
insert_tsv_data();

exit;


sub create_wordlink_table
{
    $DBH->do("CREATE TABLE wordlink(
        wordid1 integer,
        wordid2 integer,
        link    text,
        src     text
    )");
}

sub create_index
{
    $DBH->do("CREATE INDEX wordlink_idx ON wordlink(wordid1, link)");
}

sub check_format
{
    open(my $fh, '<', $TSV_FILE) or die $!;
    chomp(my @lines = <$fh>);
    close($fh);

    my $cnt = 0;

    for my $line (@lines)
    {
        # $line

        my ($wordid1, undef, $wordid2, undef) = split(/\t/, $line);

        my @wordid1 = split(/\@/, $wordid1);
        my @wordid2 = split(/\@/, $wordid2);

        die if scalar @wordid1 > 2;
        die if scalar @wordid2 > 2;
        # @wordid1
        # @wordid2

        if (scalar @wordid1 == 2)
        {
            my $diff = abs($wordid1[0] - $wordid1[1]);

            if ($diff != 1)
            {
                ### @wordid1
                $cnt++;
            }
        }

        if (scalar @wordid2 == 2)
        {
            my $diff = abs($wordid2[0] - $wordid2[1]);

            if ($diff != 1)
            {
                ### @wordid2
                $cnt++;
            }
        }
    }

    ### $cnt
}

sub insert_tsv_data
{
    open(my $fh, '<', $TSV_FILE) or die $!;
    chomp(my @lines = <$fh>);
    close($fh);

    my $cnt = 0;

    for my $line (@lines)
    {
        # $line

        my ($wordid1, undef, $wordid2, undef) = split(/\t/, $line);

        # $wordid1
        # $wordid2

        my @wordid1 = split(/\@/, $wordid1);
        my @wordid2 = split(/\@/, $wordid2);

        if (scalar @wordid1 > 1)
        {
            die if @wordid1 > 2;
            @wordid1 = sort { $a <=> $b } @wordid1;
            @wordid1 = ($wordid1[0] .. $wordid1[1]);
        }

        if (scalar @wordid2 > 1)
        {
            die if @wordid2 > 2;
            @wordid2 = sort { $a <=> $b } @wordid2;
            @wordid2 = ($wordid2[0] .. $wordid2[1]);
        }

        if (@wordid1 > 2)
        {
            ### @wordid1
            $cnt++;
        }

        if (@wordid2 > 2)
        {
            ### @wordid2
            $cnt++;
        }

        for my $word_id1 (@wordid1)
        {
            for my $word_id2 (@wordid2)
            {
                $DBH->do("INSERT INTO wordlink VALUES($word_id1, $word_id2, 'syns', '$SRC')");
                $DBH->do("INSERT INTO wordlink VALUES($word_id2, $word_id1, 'syns', '$SRC')");
            }
        }
    }

    ### $cnt
}

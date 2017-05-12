#!/usr/bin/perl

use warnings;
use strict;

use Test::More;
use Data::Dumper;

use Lingua::NATools;
use Lingua::NATools::Client;
use Capture::Tiny 'capture';

use File::Path 'remove_tree';
use Cwd;
my $dir = getcwd;

END {
    return;
    for (qw{PT-EN.tmx PT-EN.tmx-EN PT-EN.tmx-PT server.cnf}) {
        unlink "t/$_" if -f "t/$_";
    }
    remove_tree "t/_" if -d "t/_";
}


capture { `$^X scripts/nat-pair2tmx t/input/PT-tok PT t/input/EN-tok EN > t/PT-EN.tmx` };
ok -f 't/PT-EN.tmx';

capture { `$^X scripts/nat-tmx2pair t/PT-EN.tmx` };
ok -f 't/PT-EN.tmx-EN';
ok -f 't/PT-EN.tmx-PT';

ok similar('t/input/EN-tok' => 't/PT-EN.tmx-EN');
ok similar('t/input/PT-tok' => 't/PT-EN.tmx-PT');

$Lingua::NATools::LOG = sub {};
is Lingua::NATools::count_sentences('t/PT-EN.tmx-EN','t/PT-EN.tmx-PT') => 414;

capture { `$^X scripts/nat-create -v -id=t/_ -i -langs=PT..EN -tmx t/PT-EN.tmx` };

ok -d 't/_';

ok -f 't/_/nat.cnf';

ok (-f 't/_/target.001' && similar('t/input/EN-tok' => 't/_/target.001'));
ok (-f 't/_/source.001' && similar('t/input/PT-tok' => 't/_/source.001'));

for (qw(source.001.crp.invidx source-target.001.bin source.001.crp.partials
	target.001.crp source-target.bin source.invidx target.001.crp.index
        source-target.dmp source.lex target.001.crp.invidx target-source.001.bin
	target.001.crp.partials source.001.crp target-source.bin target.invidx
        source.001.crp.index target-source.dmp target.lex)) {
    ok -f "t/_/$_", "$_ existence";
}

ok(open(F, ">t/server.cnf"), "Create server conf");
print F "$dir/t/_\n";
close F;

## Do ngrams
my $grams = { 2 => 'bigrams', 3 => 'trigrams', 4 => 'tetragrams' };
for my $n (keys %$grams) {
    `nat-ngrams -n $n t/_/source.001.crp t/_/s.$grams->{$n}.db`;
    ok -f "t/_/s.$grams->{$n}.db", "$n-grams for source";

    `nat-ngrams -o 1 -d t/_/s.$grams->{$n}.db t/_/source.lex > t/_/s.$grams->{$n}.txt`;
    unlink "t/_/s.$grams->{$n}.db";
    ok -f "t/_/s.$grams->{$n}.txt";

    Lingua::NATools::_ngrams_reorganize("t/_/s.$grams->{$n}.txt" => "t/_/_s.$grams->{$n}.txt");
    ok -f "t/_/_s.$grams->{$n}.txt";

    Lingua::NATools::_ngrams_tosqlite("t/_/_s.$grams->{$n}.txt" => "t/_/S.$n.ngrams", $n);
    ok -f "t/_/S.$n.ngrams";


    `nat-ngrams -n $n t/_/target.001.crp t/_/t.$grams->{$n}.db`;
    ok -f "t/_/t.$grams->{$n}.db", "$n-grams for target";

    `nat-ngrams -o 1 -d t/_/t.$grams->{$n}.db t/_/target.lex > t/_/t.$grams->{$n}.txt`;
    unlink "t/_/t.$grams->{$n}.db";
    ok -f "t/_/t.$grams->{$n}.txt";

    Lingua::NATools::_ngrams_reorganize("t/_/t.$grams->{$n}.txt" => "t/_/_t.$grams->{$n}.txt");
    ok -f "t/_/_t.$grams->{$n}.txt";

    Lingua::NATools::_ngrams_tosqlite("t/_/_t.$grams->{$n}.txt" => "t/_/T.$n.ngrams", $n);
    ok -f "t/_/T.$n.ngrams";

    open C, ">>", "t/_/nat.cnf" or die "Can't open file t/_/nat.cnf";
    print C "n-grams=1\n";
    close C;
}


my $pid;
if ($pid = fork()) {
    diag "Let the server start...";
    sleep 3;

    my $client = Lingua::NATools::Client->new(PeerAddr => '127.0.0.1',
                                              PeerPort => '4000');

    is_deeply($client->list, {'t/_'=>{source=>'PT',target=>'EN',id=>'1'}});

    $client->set_corpus(1);

    # Concordâncias
    {
        my $array = $client->conc("um");
        ok (scalar($array) > 0);
        for my $pair (@$array) {
            like $pair->[0] => qr/(^| )um( |$)/i;
        }

        my $oarray = $client->conc({direction=>'<='},"one");
        ok (scalar($oarray) > 0);
        for my $pair (@$oarray) {
            like $pair->[1] => qr/(^| )one( |$)/i;
        }
        my $yaarray = $client->conc({direction=>'<=>'},"um","one");
        ok (scalar($yaarray) > 0);
        for my $pair (@$yaarray) {
            like $pair->[0] => qr/(^| )um( |$)/i;
            like $pair->[1] => qr/(^| )one( |$)/i;
        }
    }

    # PTDs
    {
        my $ptd = $client->ptd("um");
        is ref($ptd), "ARRAY";
        is $ptd->[0] => 177;
        is $ptd->[2] => "um";
        is ref($ptd->[1]), "HASH";
        ok exists($ptd->[1]{an});
    }

    # NGRAMS
    {
        my $bi = $client->ngrams("um *");
        for my $b (@$bi) {
            is $b->[0], "um";
            like $b->[2], qr/^\d+$/;
        }
    }

    kill 9 => $pid;
    waitpid $pid => 0;

    done_testing();
} else {
    capture { exec "nat-server t/server.cnf" }
}



sub similar {
    my ($f1, $f2) = @_;
    $f1 = slurp($f1);
    $f2 = slurp($f2);
    $f1 =~ s/\s//g;
    $f2 =~ s/\s//g;
    $f1 eq $f2
}

sub slurp {
    my $filename = shift;
    open F, "<:utf8", $filename;
    my $r = join "" => (<F>);
    close F;
    return $r;
}




use strict;
use warnings;
use Test::More 0.98;

use Hash::Tabular::Markdown;

subtest flat => sub {
    my $hashref = { 1 => 2 };
    my $md = Hash::Tabular::Markdown->tabulate($hashref);
    use Data::Dumper;
    is( $md, <<"RESULT;");
|||
|:--|:--|
|1|2
RESULT;

};

subtest neted => sub {
    my $hashref = { 1 => { 2 => 3 } };
    my $md = Hash::Tabular::Markdown->tabulate($hashref);
    use Data::Dumper;
    is( $md, <<"RESULT;");
||||
|:--|:--|:--|
|1|2|3
RESULT;

};

subtest string => sub {
    my $hashref = { "hoge" => { "hogehoge" => "hogehoge" } };
    my $md = Hash::Tabular::Markdown->tabulate($hashref);
    use Data::Dumper;
    is( $md, <<"RESULT;");
||||
|:--|:--|:--|
|hoge|hogehoge|hogehoge
RESULT;

};

subtest complex1 => sub {
    my $hashref = { hogekey => { hogekey => [qw/a b c 1 2 3/] } };
    my $md = Hash::Tabular::Markdown->tabulate($hashref);
    use Data::Dumper;
    is( $md, <<"RESULT;");
||||
|:--|:--|:--|
|hogekey|hogekey|['a','b','c','1','2','3']
RESULT;

};

subtest complex2 => sub {
    my $hashref = {
        hogekey1 => [
            hogekey2  => [qw/a b c 1 2 3/],
            hogekey22 => { array => [qw/a b c 1 2 3/] },
        ],
    };
    my $md = Hash::Tabular::Markdown->tabulate($hashref);
    use Data::Dumper;
    is( $md, <<"RESULT;");
|||
|:--|:--|
|hogekey1|['hogekey2',['a','b','c','1','2','3'],'hogekey22',{'array' => ['a','b','c','1','2','3']}]
RESULT;

};

done_testing;


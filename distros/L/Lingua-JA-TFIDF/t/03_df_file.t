use strict;
use Lingua::JA::TFIDF;
use Test::More tests => 2;
require 't/TestServer.pm';

my $s        = TestServer->new;
my $url_root = $s->started_ok("starting a test server");

my %config = ( fetch_df => 1 );
my $calculator = Lingua::JA::TFIDF->new(%config);

&overwrite;

my $text = q(
我々は一人の英雄を失った。これは敗北を意味するのか？否！始まりなのだ！
地球連邦に比べ我がジオンの国力は３０分の１以下である。にも関わらず今日まで戦い抜いてこられたのは何故か！諸君！我がジオンの戦争目的が正しいからだ！
一握りのエリートが宇宙にまで膨れ上がった地球連邦を支配して５０余年、宇宙に住む我々が自由を要求して、何度連邦に踏みにじられたかを思い起こすがいい。ジオン公国の掲げる、人類一人一人の自由のための戦いを、神が見捨てる訳は無い。
私の弟、諸君らが愛してくれたガルマ・ザビは死んだ、何故だ！
戦いはやや落着いた。諸君らはこの戦争を対岸の火と見過ごしているのではないのか？しかし、それは重大な過ちである。地球連邦は聖なる唯一の地球を汚して生き残ろうとしている。我々はその愚かしさを地球連邦のエリート共に教えねばならんのだ。
ガルマは、諸君らの甘い考えを目覚めさせるために、死んだ！戦いはこれからである。
我々の軍備はますます復興しつつある。地球連邦軍とてこのままではあるまい。
諸君の父も兄も、連邦の無思慮な抵抗の前に死んでいったのだ。この悲しみも怒りも忘れてはならない！それをガルマは死を以って我々に示してくれたのだ！我々は今、この怒りを結集し、連邦軍に叩きつけて初めて真の勝利を得ることが出来る。この勝利こそ、戦死者全てへの最大の慰めとなる。
国民よ立て！悲しみを怒りに変えて、立てよ国民！ジオンは諸君等の力を欲しているのだ。
ジーク・ジオン！！
);

my $result = $calculator->tfidf($text);
is_deeply( $result->list(10), &correct,
    "tfidf() with fetch_df results deeply match" );

sub correct {
    return [
        { '連邦'             => '51.5824158847192' },
        { '諸君'             => '44.6736574508163' },
        { 'ジオン'          => '33.2472254467651' },
        { '地球'             => '25.6811539727557' },
        { 'ガルマ'          => '20.9896008544296' },
        { '怒り'             => '18.1728130488376' },
        { '戦い'             => '16.9994600697375' },
        { 'エリート'       => '14.5288604458417' },
        { '悲しみ'          => '13.444211864191' },
        { 'ガルマ・ザビ' => '11.654489029292' }
    ];
}

sub overwrite {

    *Lingua::JA::TFIDF::Fetcher::_prepare = sub {
        my $self                 = shift;
        my %LWP_UserAgent_config = ();
        if ( ref $self->config->{LWP_UserAgent} eq 'HASH' ) {
            %LWP_UserAgent_config = %{ $self->config->{LWP_UserAgent} };
        }
        $self->{user_agent} = LWP::UserAgent->new(%LWP_UserAgent_config);
        my %XML_TreePP_config = ();
        if ( ref $self->config->{XML_TreePP} eq 'HASH' ) {
            %XML_TreePP_config = %{ $self->config->{XML_TreePP} };
        }
        $self->{xml_treepp} = XML::TreePP->new(%XML_TreePP_config);
        my $yahoo_api_appid = $self->config->{yahoo_api_appid} || 'yahooDemo';
        $self->{url} =
            'http://localhost:8080?appid='
          . $yahoo_api_appid
          . '&results=1&adult_ok=1&query=';
    };

    *Lingua::JA::TFIDF::_calc_tf = sub {

        return {
            '国民'                => { 'tf' => 2 },
            '父'                   => { 'tf' => 1 },
            'ジーク・ジオン' => {
                'unknown' => 1,
                'tf'      => 1
            },
            'ガルマ・ザビ' => {
                'unknown' => 1,
                'tf'      => 1
            },
            '要求'    => { 'tf' => 1 },
            '最大'    => { 'tf' => 1 },
            '諸君'    => { 'tf' => 6 },
            '支配'    => { 'tf' => 1 },
            '戦い'    => { 'tf' => 3 },
            '人類'    => { 'tf' => 1 },
            '英雄'    => { 'tf' => 1 },
            '今'       => { 'tf' => 1 },
            '公国'    => { 'tf' => 1 },
            '国力'    => { 'tf' => 1 },
            '欲'       => { 'tf' => 1 },
            '今日'    => { 'tf' => 1 },
            '前'       => { 'tf' => 1 },
            '復興'    => { 'tf' => 1 },
            'ジオン' => {
                'unknown' => 1,
                'tf'      => 4
            },
            '戦死'    => { 'tf' => 1 },
            '神'       => { 'tf' => 1 },
            '宇宙'    => { 'tf' => 2 },
            '怒り'    => { 'tf' => 3 },
            'ガルマ' => {
                'unknown' => 1,
                'tf'      => 2
            },
            '立て'       => { 'tf' => 1 },
            '悲しみ'    => { 'tf' => 2 },
            '慰め'       => { 'tf' => 1 },
            '全て'       => { 'tf' => 1 },
            '無'          => { 'tf' => 1 },
            '力'          => { 'tf' => 1 },
            '落着'       => { 'tf' => 1 },
            '勝利'       => { 'tf' => 2 },
            '死'          => { 'tf' => 1 },
            '戦争'       => { 'tf' => 2 },
            '軍備'       => { 'tf' => 1 },
            'エリート' => { 'tf' => 2 },
            '考え'       => { 'tf' => 1 },
            '火'          => { 'tf' => 1 },
            '抵抗'       => { 'tf' => 1 },
            'てこ'       => { 'tf' => 1 },
            '過ち'       => { 'tf' => 1 },
            '思慮'       => { 'tf' => 1 },
            '敗北'       => { 'tf' => 1 },
            '以'          => {
                'unknown' => 1,
                'tf'      => 1
            },
            '地球'    => { 'tf' => 6 },
            '弟'       => { 'tf' => 1 },
            '兄'       => { 'tf' => 1 },
            '結集'    => { 'tf' => 1 },
            '目的'    => { 'tf' => 1 },
            '始まり' => { 'tf' => 1 },
            '連邦'    => { 'tf' => 8 },
            '対岸'    => { 'tf' => 1 },
            '意味'    => { 'tf' => 1 },
            '唯一'    => { 'tf' => 1 },
            '真'       => { 'tf' => 1 },
            '否'       => { 'tf' => 1 }
        };
    };
}
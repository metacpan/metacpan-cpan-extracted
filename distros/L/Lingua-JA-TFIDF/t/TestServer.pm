package TestServer;
use strict;
use warnings;
use base qw(Test::HTTP::Server::Simple HTTP::Server::Simple::CGI);

sub handle_request {
    my ( $self, $cgi ) = @_;
    my $params = $cgi->Vars;
    my $appid  = $params->{appid};
    my $query  = $params->{query};
    my $xml    = $self->response_xml->{$query};

    $cgi->header(
        -status       => '200',
        -content_type => 'text/xml; charset="utf-8"'
    );
    print $xml;
}

sub response_xml {
    my $self = shift;
    my $xmls = {
        'ジーク・ジオン' => q(
<?xml version="1.0" encoding="UTF-8"?>
<ResultSet xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="urn:yahoo:jp:srch" xsi:schemaLocation="urn:yahoo:jp:srch http://search.yahooapis.jp/WebSearchService/V1/WebSearchResponse.xsd" totalResultsAvailable="469000" totalResultsReturned="1" firstResultPosition="1" pgr="14254">
<Result><Title>ジーク・ジオン - 教えて!goo</Title><Summary>この間、知り合いが乾杯の時に「ジーク・ジオン」と言っていたんですが、何のことでしょうか?教えてください。 ... ジー>ク・ジオン. 質問者:dorico ... 世代が一回りしたので「ジーク・ジオン!」も他意もなく使われているのかもしれませんね。 ...</Summary><Url>http://oshiete1.goo.ne.jp/kotaeru.php3?q=1410227</Url><ClickUrl>http://wrs.search.yahoo.co.jp/l=WS1/R=1/wdm=0/IPC=jp/ln=ja/H=0/;_ylt=A3xTpnuhYQlJLjUBpZoDUAx.;_ylu=X3oDMTB2cXVjNTM5BGNvbG8DdwRsA1dTMQRwb3MDMQRzZWMDc3IEdnRpZAM-/SIG=124014eq1/EXP=1225437985/*-http%3A//oshiete1.goo.ne.jp/kotaeru.php3?q=1410227</ClickUrl><ModificationDate>1224514800</ModificationDate><MimeType>text/html</MimeType>
<Cache><Url>http://wrs.search.yahoo.co.jp/l=WS5/R=1/;_ylt=A3xTpnuhYQlJLjUBppoDUAx.;_ylu=X3oDMTBwOHA5a2tvBGNvbG8DdwRwb3MDMQRzZWMDc3IEdnRpZAM-/SIG=1996ijac9/EXP=1225437985/*-http%3A//cache.yahoofs.jp/search/cache?ei=UTF-8&amp;appid=YahooDemo&amp;query=%E3%82%B8%E3%83%BC%E3%82%AF%E3%83%BB%E3%82%B8%E3%82%AA%E3%83%B3&amp;results=1&amp;u=oshiete1.goo.ne.jp/kotaeru.php3%3Fq%3D1410227&amp;w=%E3%82%B8%E3%83%BC%E3%82%AF+%E3%82%B8%E3%82%AA%E3%83%B3&amp;d=D5udzkLURrya&amp;icp=1&amp;.intl=jp</Url><Size>38756</Size></Cache>

</Result>
</ResultSet>
),
        'ジオン' => q(
<?xml version="1.0" encoding="UTF-8"?>
<ResultSet xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="urn:yahoo:jp:srch" xsi:schemaLocation="urn:yahoo:jp:srch http://search.yahooapis.jp/WebSearchService/V1/WebSearchResponse.xsd" totalResultsAvailable="6140000" totalResultsReturned="1" firstResultPosition="1" pgr="191878">
<Result><Title>株式会社ジオン</Title><Summary>システムのコンバージョン等。 ... 株式会社ジオンでは、高度情報通信社会における個人情報保護の重要性に鑑み、 会社方針に基づき個人情報の保護に努めます。 ... (2008/3/27)ジオンブログを追加致しました。 ジオンブログへ ...</Summary><Url>http://www.jion-g.co.jp/</Url><ClickUrl>http://wrs.search.yahoo.co.jp/l=WS1/R=1/wdm=0/IPC=jp/ln=ja/H=0/;_ylt=A3xThm2VYwlJaUgByDcDUAx.;_ylu=X3oDMTB2cXVjNTM5BGNvbG8DdwRsA1dTMQRwb3MDMQRzZWMDc3IEdnRpZAM-/SIG=11chuun4d/EXP=1225438485/*-http%3A//www.jion-g.co.jp/</ClickUrl><ModificationDate>1208185200</ModificationDate><MimeType>text/html</MimeType>
<Cache><Url>http://wrs.search.yahoo.co.jp/l=WS5/R=1/;_ylt=A3xThm2VYwlJaUgByTcDUAx.;_ylu=X3oDMTBwOHA5a2tvBGNvbG8DdwRwb3MDMQRzZWMDc3IEdnRpZAM-/SIG=16dqrnp93/EXP=1225438485/*-http%3A//cache.yahoofs.jp/search/cache?ei=UTF-8&amp;appid=YahooDemo&amp;query=%E3%82%B8%E3%82%AA%E3%83%B3&amp;results=1&amp;u=www.jion-g.co.jp/&amp;w=%E3%82%B8%E3%82%AA%E3%83%B3&amp;d=YzOX-0LURtnj&amp;icp=1&amp;.intl=jp</Url><Size>5072</Size></Cache>

</Result>
</ResultSet>
),
        'ガルマ' => q(
<?xml version="1.0" encoding="UTF-8"?>
<ResultSet xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="urn:yahoo:jp:srch" xsi:schemaLocation="urn:yahoo:jp:srch http://search.yahooapis.jp/WebSearchService/V1/WebSearchResponse.xsd" totalResultsAvailable="692000" totalResultsReturned="1" firstResultPosition="1" pgr="21359">
<Result><Title>機動戦士ガンダム公式Web | CHARACTER</Title><Summary>ガルマ・ザビ. ザビ家の四男で末弟。 地球方面軍司令。 シャアの友人。 ... ガルマの仇討ち部隊の隊長。 ゲリラ戦のスペシャリスト。 ... 弟ガルマの直接の上司でもある。 弟ドズルが罷免したシャアを拾うなど合理主義者 ...</Summary><Url>http://www.gundam.jp/chara/ze01.html</Url><ClickUrl>http://wrs.search.yahoo.co.jp/l=WS1/R=1/wdm=0/IPC=jp/ln=ja/H=0/;_ylt=A8vY5njbYwlJkMsANr4DUAx.;_ylu=X3oDMTB2cXVjNTM5BGNvbG8DdwRsA1dTMQRwb3MDMQRzZWMDc3IEdnRpZAM-/SIG=11oof2c27/EXP=1225438555/*-http%3A//www.gundam.jp/chara/ze01.html</ClickUrl><ModificationDate>1166281200</ModificationDate><MimeType>text/html</MimeType>
<Cache><Url>http://wrs.search.yahoo.co.jp/l=WS5/R=1/;_ylt=A8vY5njbYwlJkMsAN74DUAx.;_ylu=X3oDMTBwOHA5a2tvBGNvbG8DdwRwb3MDMQRzZWMDc3IEdnRpZAM-/SIG=16plkeq5p/EXP=1225438555/*-http%3A//cache.yahoofs.jp/search/cache?ei=UTF-8&amp;appid=YahooDemo&amp;query=%E3%82%AC%E3%83%AB%E3%83%9E&amp;results=1&amp;u=www.gundam.jp/chara/ze01.html&amp;w=%E3%82%AC%E3%83%AB%E3%83%9E&amp;d=L2ctWULURrmI&amp;icp=1&amp;.intl=jp</Url><Size>26732</Size></Cache>

</Result>
</ResultSet>
),
        'ガルマ・ザビ' => q(
<?xml version="1.0" encoding="UTF-8"?>
<ResultSet xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="urn:yahoo:jp:srch" xsi:schemaLocation="urn:yahoo:jp:srch http://search.yahooapis.jp/WebSearchService/V1/WebSearchResponse.xsd" totalResultsAvailable="217000" totalResultsReturned="1" firstResultPosition="1" pgr="7032">
<Result><Title>ザビ家 - Wikipedia</Title><Summary>... (総帥、長男)、サスロ(次男/三男)、ドズル(三男/次男)、キシリア(長女)、ガルマ(四男)の5人の子がいる(テレビ版の準備稿ではミハル・ザビという娘もいた)。妻はナルス(ナリスとする説あり)だが子の母親に関しては諸説ある。 ...</Summary><Url>http://ja.wikipedia.org/wiki/%E3%82%B6%E3%83%93%E5%AE%B6</Url><ClickUrl>http://wrs.search.yahoo.co.jp/l=WS1/R=1/wdm=0/IPC=jp/ln=ja/H=0/;_ylt=A8vY8msrZAlJjEcB9J4DUAx.;_ylu=X3oDMTB2cXVjNTM5BGNvbG8DdwRsA1dTMQRwb3MDMQRzZWMDc3IEdnRpZAM-/SIG=12cqd9qum/EXP=1225438635/*-http%3A//ja.wikipedia.org/wiki/%E3%82%B6%E3%83%93%E5%AE%B6</ClickUrl><ModificationDate>1223564400</ModificationDate><MimeType>text/html</MimeType>
<Cache><Url>http://wrs.search.yahoo.co.jp/l=WS5/R=1/;_ylt=A8vY8msrZAlJjEcB9Z4DUAx.;_ylu=X3oDMTBwOHA5a2tvBGNvbG8DdwRwb3MDMQRzZWMDc3IEdnRpZAM-/SIG=19djpmlkb/EXP=1225438635/*-http%3A//cache.yahoofs.jp/search/cache?ei=UTF-8&amp;appid=YahooDemo&amp;query=%E3%82%AC%E3%83%AB%E3%83%9E%E3%83%BB%E3%82%B6%E3%83%93&amp;results=1&amp;u=ja.wikipedia.org/wiki/%25E3%2582%25B6%25E3%2583%2593%25E5%25AE%25B6&amp;w=%E3%82%AC%E3%83%AB%E3%83%9E+%E3%82%B6%E3%83%93&amp;d=NxVRp0LURsq9&amp;icp=1&amp;.intl=jp</Url><Size>128923</Size></Cache>

</Result>
</ResultSet> 
),
        '以' => q(
<?xml version="1.0" encoding="UTF-8"?>
<ResultSet xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="urn:yahoo:jp:srch" xsi:schemaLocation="urn:yahoo:jp:srch http://search.yahooapis.jp/WebSearchService/V1/WebSearchResponse.xsd" totalResultsAvailable="2290000000" totalResultsReturned="1" firstResultPosition="1" pgr="77562538">
<Result><Title>以 - ウィクショナリー日本語版</Title><Summary>以. 出典: フリー多機能辞典『ウィクショナリー日本語版(Wiktionary) ... 以. 部首: 人 + 3 画. 総画: 5画. 筆順 : [編集] 字源. 会意形声。 ... 以 * ローマ字表記. 普通話. ピンイン: yǐ (yi3) ...</Summary><Url>http://ja.wiktionary.org/wiki/%E4%BB%A5</Url><ClickUrl>http://wrs.search.yahoo.co.jp/l=WS1/R=1/wdm=0/IPC=jp/ln=ja/H=0/;_ylt=A3xTpnX6ZQlJC38AoNYDUAx.;_ylu=X3oDMTB2cXVjNTM5BGNvbG8DdwRsA1dTMQRwb3MDMQRzZWMDc3IEdnRpZAM-/SIG=11rs0ktgs/EXP=1225439098/*-http%3A//ja.wiktionary.org/wiki/%E4%BB%A5</ClickUrl><ModificationDate>1222527600</ModificationDate><MimeType>text/html</MimeType>
<Cache><Url>http://wrs.search.yahoo.co.jp/l=WS5/R=1/;_ylt=A3xTpnX6ZQlJC38AodYDUAx.;_ylu=X3oDMTBwOHA5a2tvBGNvbG8DdwRwb3MDMQRzZWMDc3IEdnRpZAM-/SIG=15u02v3ti/EXP=1225439098/*-http%3A//cache.yahoofs.jp/search/cache?ei=UTF-8&amp;appid=YahooDemo&amp;query=%E4%BB%A5&amp;results=1&amp;u=ja.wiktionary.org/wiki/%25E4%25BB%25A5&amp;w=%E4%BB%A5&amp;d=Fcf_G0LURqpg&amp;icp=1&amp;.intl=jp</Url><Size>27110</Size></Cache>

</Result>
</ResultSet>
),
    };
    return $xmls;
}

1;
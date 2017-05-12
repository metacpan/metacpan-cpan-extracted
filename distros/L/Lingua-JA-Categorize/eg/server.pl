use strict;
use blib;
use POE;
use POE::Component::Server::HTTP;
use Lingua::JA::Categorize;
use Lingua::JA::Expand;
use HTML::Feature;
use YAML;
use Template;
use CGI;
use HTTP::Request::AsCGI;
use FindBin;
use List::MoreUtils qw(any);
use lib "$FindBin::RealBin/more_train/lib";

#-- Lingua::JA::Expand のためのYahooAPI appid の入力促進
print
    "Yahoo API appIDを入力してください（2011年4月以降、有料版でないとうまく動作しなくなりました) : ";
my $appid = <STDIN>;
chomp $appid;
die("Yahoo API appIDが入力されていません") if !$appid;

# configなど
my $yaml     = YAML::Load( join '', <DATA> );
my $config   = $yaml->{config};
my $template = $yaml->{template};

# HTTPサーバ生成
my $server = POE::Component::Server::HTTP->new(
    Port           => 80,
    ContentHandler => {
        '/'           => \&index,
        '/my.js'      => \&js,
        '/feature'    => \&feature,
        '/categorize' => \&categorize,
        '/train'      => \&train,
    }
);

# POE メインセッション
POE::Session->create(
    inline_states => {
        _start => sub {
            $_[KERNEL]->alias_set("main");
            my $heap = @_[HEAP];
            $heap->{categorizer} = Lingua::JA::Categorize->new(%$config);
            $heap->{categorizer}->load( $config->{state_file} );
            $heap->{extractor} = HTML::Feature->new(
                engines => [
                    'MyEngine::Oshiete',    # 教えてgoo 専用
                    'HTML::Feature::Engine::LDRFullFeed',
                    'HTML::Feature::Engine::GoogleADSection',
                    'HTML::Feature::Engine::TagStructure',
                ]
            );
            $heap->{tt} = Template->new;
        },
    }
);

# ループ開始
POE::Kernel->run();

#-- 以下サブルーチン
sub index {
    my ( $req, $res ) = @_;
    my $heap     = $poe_kernel->alias_resolve("main")->get_heap();
    my $tt       = $heap->{tt};
    my $template = $template->{index};
    $tt->process( \$template, "", \my $content );
    $res->code(RC_OK);
    $res->content_type('text/html; charset=UTF-8');
    $res->content($content);
}

sub js {
    my ( $req, $res ) = @_;
    my $heap     = $poe_kernel->alias_resolve("main")->get_heap();
    my $tt       = $heap->{tt};
    my $template = $template->{js};
    $tt->process( \$template, "", \my $content );
    $res->code(RC_OK);
    $res->content_type('text/javascript; charset=UTF-8');
    $res->content($content);
}

sub feature {
    my ( $req, $res ) = @_;
    my $q;
    {
        my $cgi = HTTP::Request::AsCGI->new($req)->setup;
        $q = CGI->new;
    }
    my $url       = $q->param("url");
    my $heap      = $poe_kernel->alias_resolve("main")->get_heap();
    my $extractor = $heap->{extractor};
    my $text      = $extractor->parse($url)->text;
    $res->code(RC_OK);
    $res->headers->header( "Connection" => 'Keep-Alive' );
    $res->content_type('text/html; charset=UTF-8');
    $res->content($text);
}

sub categorize {
    my ( $req, $res ) = @_;
    my $q;
    {
        my $cgi = HTTP::Request::AsCGI->new($req)->setup;
        $q = CGI->new;
    }
    my $text        = $q->param("text");
    my $heap        = $poe_kernel->alias_resolve("main")->get_heap();
    my $categorizer = $heap->{categorizer};
    my $result;
    if ( $q->param("expand") ) {
        my $expander = Lingua::JA::Expand->new(
            yahoo_api_appid   => $appid,
            yahoo_api_premium => 1
        );
        my $word_set = $expander->expand( $text, 20 );
        my $parsed = $categorizer->categorizer->categorize($word_set);
        $result = Lingua::JA::Categorize::Result->new(
            word_set   => $word_set,
            score      => $parsed->{score},
            no_matches => $parsed->{no_matches},
            matches    => $parsed->{matches},
        );
    }
    else {
        $result = $categorizer->categorize($text);
    }
    my $tt       = $heap->{tt};
    my $template = $template->{score_table};

    my $word_set   = $result->word_set;
    my $score      = $result->score;
    my $matches    = $result->matches;
    my $no_matches = $result->no_matches;

    #-- word_setの整形処理
    my @word_set;
    for (@$word_set) {
        my ( $key, $value ) = each %$_;
        my $item;
        $item->{word}     = $key;
        $item->{count}    = $value;
        $item->{no_match} = 1 if any { $_ eq $key } @$no_matches;
        push( @word_set, $item );
    }

    #-- scoreの整形処理
    my @score;
    for (@$score) {
        my ( $key, $value ) = each %$_;
        my $item;
        $item->{label} = $key;
        $item->{score} = $value;
        push( @score, $item );
    }

    #-- categories の整形処理
    my @categories
        = keys
        %{ $categorizer->categorizer->{brain}->{'model'}->{'prior_probs'} };
    @categories = sort @categories;
    $tt->process(
        \$template,
        {   score      => \@score,
            word_set   => \@word_set,
            categories => \@categories,
            expand     => $q->param("expand")
        },
        \my $content
    );
    $res->code(RC_OK);
    $res->headers->header( "Connection" => 'Keep-Alive' );
    $res->content_type('text/html; charset=UTF-8');
    $res->content($content);
}

sub expand {
    my ( $req, $res ) = @_;
    my $q;
    {
        my $cgi = HTTP::Request::AsCGI->new($req)->setup;
        $q = CGI->new;
    }
    my $text = $q->param("text");

}

sub train {
    my ( $req, $res ) = @_;
    my $q;
    {
        my $cgi = HTTP::Request::AsCGI->new($req)->setup;
        $q = CGI->new;
    }
    my $text        = $q->param("text");
    my $category    = $q->param("category");
    my $num         = $q->param("num");
    my $expand      = $q->param("expand");
    my $heap        = $poe_kernel->alias_resolve("main")->get_heap();
    my $categorizer = $heap->{categorizer};
    my $brain       = $categorizer->categorizer->brain;
    $num ||= 1;

    my $word_set;

    if ( $q->param("expand") ) {
        my $expander = Lingua::JA::Expand->new(
            yahoo_api_appid => $config->{'yahoo_api_appid'} );
        $word_set = $expander->expand( $text, 20 );
    }
    else {
        $word_set = $categorizer->tokenizer->tokenize( \$text );
    }
    $brain->add_instance( attributes => $word_set, label => $category );
    for ( 1 .. $num ) {
        $brain->add_instance(
            attributes => { dummy => 0 },
            label      => $category
        );
    }
    $brain->train;
    $categorizer->save( $config->{state_file} );
    $res->code(RC_OK);
    $res->headers->header( "Connection" => 'Keep-Alive' );
    $res->content_type('text/html; charset=UTF-8');
    $res->content("学習成功");
}

__DATA__
---
config:
    state_file: 'sample.bin'
    tokenizer_config:
        threshold: 30
template:
    index: |
        <html>
        <head>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
        <script type="text/javascript" src="http://jqueryjs.googlecode.com/files/jquery-1.3.2.min.js"></script>
        <script type="text/javascript" src="/my.js"></script>
        <script type="text/javascript">
        $(document).ready(function()
        {
            //-------------------------------------------------------
            /*shows the loading div every time we have an Ajax call*/
            $("#loading").bind("ajaxSend", function(){
                $(this).show();
            }).bind("ajaxComplete", function(){
                $(this).hide();
            });
            //-------------------------------------------------------
        })
        </script>
        <style type="text/css">
        #loading{
            position: fixed;
            top: 0;
            left: 0; /*set it to "right: 0;" to have the bar displaying on the top right corner*/
            z-index: 5000;
            background-color: red;
            font-size: 150%;
            color: white;
            padding: 2px;
        }
        .box{
            margin:10px 0 20px 0;
        }
        .rightPos{
            float:right;
        }
        </style>

        <title>Lingua::JA::Categorize</title>
        </head>
        <body>
        <div id="loading" style="display: none;">Loading content...</div>
        <h1 style="margin-top:40px;">日本語意味分類エンジン</h1>
        <hr />

        <div class="box">
            <table width=800>
                <tr>
                    <td>
                        URL<input type="text" name="url" id="url" size="83">
                        <button type="submit" onclick="javascript:do_extract()">重要部分抽出</button>
                        <button type="submit" onclick="javascript:do_clear()">クリア</button>
        
                    </td>
                </tr>
                <tr>
                    <td>
                        <textarea name="featured" id="featured" cols=90 rows=10></textarea>
                    </td>
                </tr>
                <tr>
        
                    <td>
                    </td>
                </tr>
            </table>
        </div>

        <table width=800>
            <tr>
                <td><button type="submit" class="rightPos" onclick="javascript:do_categorize()">分野判定</button></td>
            </tr>
            <tr>
                <td><button type="submit" class="rightPos" onclick="javascript:do_expand()">単語拡張</button></td>
            </tr>
        </table>
        
        <div class="box" id="score">
        </div>
        
        <div class="box" id="learn">
        </div>
        
        </body>
        </html>


    score_table: |
        <h2>特徴語（ use Lingua::JA::TFIDF ）</h2>
        <table border=2px width=800>
            [% FOREACH item IN word_set %]
            <tr><td><a href="javascript:void(0)" onclick="do_expand('[% item.word %]');"> [% item.word %] </a>[% IF item.no_match %] 　　( no match !! )[% END %]</td><td> [% item.count %] </td></tr>
            [% END %]
        </table>
        <br><br>
        <h2>分野（ use Algorithm::NaiveBayes ）</h2>
        <table border=2px width=800>
        [% FOREACH item IN score %]
        <tr>
            <td> [% item.label %] </td><td> [% item.score %] </td>
        </tr>
        [% END %]
        </table>
        <br><br>
        <table width=800>
            <tr>
                <td>
                    補正候補
                    <select id="train_category">
                        [% FOREACH item IN categories %]
                            <option value="[% item %]">[% item %]</option>
                        [% END %]
                    </select>
                    <input type="text" onkeyup="search(this.value)">
                </td>
                <td><div id="train"></div></td>
            </tr>
            <tr>
                <td>
                    補正回数<input id="train_num" type="text" size="10" value="1">回
                    <input type="hidden" id="expand" value="[% expand %]">
                </td>
                <td>
                    <button class="rightPos" type="submit" onclick="javascript:do_train()">学習</button>
                </td>
            </tr>
        </table>

    js: |
        function do_extract(){
            var url = encodeURIComponent($("#url").val());
            if(url.length == 0){
                alert("からっぽだよ");
                return;
            }
            $.ajax({
                procmsg: 'now loading',
                type: "POST",
                url: "feature",
                data: "url=" + url,
                success: function(msg){
                    $("#featured").val(msg);
                }
            });
        }
        function do_categorize(){
            var text = encodeURIComponent($("#featured").val());
            $.ajax({
                type: "POST",
                url: "categorize",
                data: "text=" + text,
                success: function(msg){
                    $("#score").html(msg);
                }
            });
           
        }
        function do_expand(keyword){
            if(!keyword){
                keyword = $("#featured").val();
            }
            var text = encodeURIComponent(keyword);

            if(text.length > 500){
                alert("単語拡張するには大きすぎます");
                return;
            }

            $("#featured").val(keyword);
            $.ajax({
                type: "POST",
                url: "categorize",
                data: "text=" + text + "&expand=1",
                success: function(msg){
                    $("#score").html(msg);
                }
            });
        }
        function do_train(expand){
            var text     = $("#featured").val();
            var category = $("#train_category").val();
            var num      = $("#train_num").val();
            var expand   = $("#expand").val();
            $("train").val="";
            $.ajax({
                type: "POST",
                url: "train",
                data: "category=" + category + "&num=" + num + "&text=" + text + "&expand=" + expand,
                success: function(msg){
                    $("#train").text("学習成功");
                    if(expand){
                        do_expand(text);
                    }
                    else{
                        do_categorize();
                    }
                    setTimeout(function(){
                        $("#train_category").val(category);
                    },1000);
                }
            });
        }
        function do_clear(){
            $("#url").val("");
            $("#featured").val("");
        }
        function search(pattern)
        {
            var pulldown = document.getElementById('train_category');
           
            if (!pulldown.a)
            {
                pulldown.a = [];
                for (var i = 0; i < pulldown.options.length; i++)
                {
                    pulldown.a[i] = pulldown.options.item(i);
                }
            }
           
            pulldown.length = 0;
            var matcheCount = 0;
            for (var i = 0; i < pulldown.a.length; i++)
            {
                if (-1 != (pulldown.a[i].text).toLowerCase().indexOf(pattern))
                {
                    pulldown[matcheCount] = pulldown.a[i];
                    matcheCount++;
                }
            }
           
            if (pattern.length == 0)
            {
                pulldown.a = null;
            };
        }


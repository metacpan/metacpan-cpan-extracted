use utf8;
use Test::More tests => 1;
use Test::LongString;
use Encode qw( encode_utf8 );
use URI;
use Mojolicious::Renderer;
use HTML::LinkFilter;

my $r = Mojolicious::Renderer->new;
my( $wish, $html ) = map { $r->get_data_template( { }, $_ ) } qw( wish.html index.html );

#print( encode_utf8( $html ), "\n" );
#print( encode_utf8( $wish ), "\n" );

sub callback {
    my( $tagname, $attr_ref, $value ) = @_;

    return unless grep { 0 == index $value, $_ } qw( /css /img /js );

    my $host = "foo.forkn.jp";

    my $uri = URI->new;
    $uri->scheme( "http" );
    $uri->host( $host );
    $uri->path( $value );

    return $uri->as_string;
}

my $filter = HTML::LinkFilter->new;
$filter->change( $html, \&callback );

( my $got = $filter->html ) =~ s{ \s* \z}{}msx;
$wish =~ s{ \s* \z}{}msx;

is_string( encode_utf8( $got ), encode_utf8( $wish ) );

__DATA__
@@ wish.html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<meta http-equiv="Content-Script-Type" content="text/javascript" />
<meta http-equiv="Content-Style-Type" content="text/css" />
<link href="http://foo.forkn.jp/js/jquery-ui/css/eggplant/jquery-ui-1.8.12.custom.css" rel="stylesheet" type="text/css" />
<link href="http://foo.forkn.jp/css/styles.css" media="screen" rel="stylesheet" type="text/css" />
<link href="http://foo.forkn.jp/css/main.css" media="screen" rel="stylesheet" type="text/css" />
<link href="http://foo.forkn.jp/css/portal.css" media="screen" rel="stylesheet" type="text/css" />
<link href="http://foo.forkn.jp/css/member.css" media="screen" rel="stylesheet" type="text/css" />
<link href="http://foo.forkn.jp/css/editor.css" media="screen" rel="stylesheet" type="text/css" />
<link href="http://foo.forkn.jp/css/book.css" media="screen" rel="stylesheet" type="text/css" />
<link href="http://foo.forkn.jp/css/user.css" media="screen" rel="stylesheet" type="text/css" />
<link href="http://foo.forkn.jp/css/about.css" media="screen" rel="stylesheet" type="text/css" />
<link href="http://foo.forkn.jp/css/special.css" media="screen" rel="stylesheet" type="text/css" />
<link href="http://foo.forkn.jp/css/jquery.cleditor.css" rel="stylesheet" type="text/css" />
<title>電子書籍の出版・販売サービス forkN</title>
<meta name="description" content="電子書籍の出版、販売、閲覧、共有ができるサービスです。マンガ、小説、イラスト、写真集などをEPUBやPDFで販売でき、iPadやiPhone,androidでも読むことができます" />
<meta name="keywords" content="電子書籍,電子ブック,電子出版,ebook,eブック,EPUB,iphone,android,電子ブックリーダー,SNS,自費出版,無料,小説.コミック,マンガ,人誌,BL" />
</head>
<body>
<div id="container">

<div id="wrap">
<a name="pagetop" id="pagetop"></a>
<div id="header" class="clearfix">
  <h1 id="logo"><a href="http://forkn.jp/"><img alt="forkN" src="http://foo.forkn.jp/img/main/logo.png" /></a></h1>
  <ul id="navigation" class="clearfix">
    <li class="navigation-01"><a href="">おすすめ</a></li>
    <li class="navigation-02"><a href="http://forkn.jp/pages/ranking/">ランキング</a></li>
    <li class="navigation-03"><a href="http://forkn.jp/pages/search/books/">作品検索</a></li>
    <li class="navigation-04"><a href="http://forkn.jp/pages/search/authors/">作家検索</a></li>
  </ul>
  
  
        <ul id="navigation-login-button" class="clearfix">
      <li><a href="https://forkn.jp/pages/login/"><img alt="ログイン" src="http://foo.forkn.jp/img/main/header_button_login.png" /></a></li>
      <li><a href="https://forkn.jp/pages/new_member/input"><img alt="新規投稿" src="http://foo.forkn.jp/img/main/header_button_newmember.png" /></a></li>
    </ul>
    
</div>

<div id="contents" class="clearfix">
<div id="portal-top">
  <div id="portal-service" class="clearfix">
    <div id="portal-service-read">
      <h2><img alt="本を読む" src="http://foo.forkn.jp/img/main/portal_servie_h2_read.png" /></h2>
      <ul class="clearfix">
        <li>ランキング</li>
        <li class="portal-service-read-left">作品検索</li>
        <li class="portal-service-read-right">作家検索</li>
      </ul>
    </div>

    <div id="portal-service-public">
      <h2><img alt="本を書く" src="http://foo.forkn.jp/img/main/portal_servie_h2_public.png" /></h2>
      <ul>
        <li>電子書籍を書く</li>
        <li>電子書籍を販売する</li>
      </ul>
    </div>
    
    <div id="portal-service-social">
      <h2><img alt="共有する" src="http://foo.forkn.jp/img/main/portal_servie_h2_social.png" /></h2>
      <ul>
        <li>読んだ本を共有する</li>
        <li>ふせんでコメントを共有する</li>
      </ul>
    </div>
  </div>
  
  <div id="portal-top-new">
    <h2 class="portal-top-h2">新しい本</h2>
    <div class="portal-top-category">
      <dl class="portal-top-category-now clearfix">
        <dt>カテゴリ:</dt><dd class="toggle-all">すべて</dd>
      </dl>
      <ul class="portal-top-category-select clearfix">
        <li><a href="?c=">すべて</a></li>	    
                <li><a href="?c=1">小説</a></li>
                <li><a href="?c=11">マンガ</a></li>
                <li><a href="?c=19">実用</a></li>
                <li><a href="?c=30">趣味</a></li>
                <li><a href="?c=40">ノンフィクション</a></li>
                <li><a href="?c=48">絵本/写真</a></li>
                <li><a href="?c=51">ゲームブック</a></li>
                <li><a href="?c=53">教科書</a></li>
                <li><a href="?c=57">社会科学</a></li>
                <li><a href="?c=67">自然科学</a></li>
                <li><a href="?c=77">芸術</a></li>
                <li><a href="?c=85">ＡＶ</a></li>
                <li><a href="?c=88">Ｒ-18</a></li>
              </ul>
    </div>
    <div class="portal-top-booklist-container">
      <ul class="portal-top-booklist">
                			        <li>
          <div class="portal-top-booklist-box clearfix">
            <p class="portal-top-booklist-cover">
              <a href="http://forkn.jp/book/18/"><img border="0" src="http://foo.forkn.jp/img/cover_image/60x.png" />
</a>
	            <span class="portal-top-booklist-price">無料</span>
            </p>
            <p>
              <span class="portal-top-booklist-title fw-bold"><a href="http://forkn.jp/book/18/">シニアライフ</a></span>
              <br />
              <span class="portal-top-booklist-autor fs-small"><a href="http://forkn.jp/user/musosha/">無双舎</a></span>
            </p>
          </div>
          <div class="portal-top-booklist-description">
            <p>
              現代の異端児・ヒロＮが、
セカンドライフをスタートするにあたって考えた。
人生を楽しく過ごすコツ。中高年うつから逃れる方法や
若い女の子との付き合い方。新しい趣味の持ち方、
ファッション論など、シニ…
            </p>
          </div>
          			        <li>
          <div class="portal-top-booklist-box clearfix">
            <p class="portal-top-booklist-cover">
              <a href="http://forkn.jp/book/17/"><img border="0" src="http://foo.forkn.jp/img/cover_image/60x.png" />
</a>
	            <span class="portal-top-booklist-price">無料</span>
            </p>
            <p>
              <span class="portal-top-booklist-title fw-bold"><a href="http://forkn.jp/book/17/">男のダイエット</a></span>
              <br />
              <span class="portal-top-booklist-autor fs-small"><a href="http://forkn.jp/user/musosha/">無双舎</a></span>
            </p>
          </div>
          <div class="portal-top-booklist-description">
            <p>
              体重９２キロの超メタボから３０キロの減量に成功した奇跡の中年。
自制心なし、根性なしのヒロＮが、まさに、死のふちに立って、
必死の思いでつかんだダイエットの極意を大公開！
ヒトが陥るダイエットの罠、…
            </p>
          </div>
          			        <li>
          <div class="portal-top-booklist-box clearfix">
            <p class="portal-top-booklist-cover">
              <a href="http://forkn.jp/book/16/"><img border="0" src="http://foo.forkn.jp/img/cover_image/60x.png" />
</a>
	            <span class="portal-top-booklist-price">無料</span>
            </p>
            <p>
              <span class="portal-top-booklist-title fw-bold"><a href="http://forkn.jp/book/16/">女の子の取扱説明書　１</a></span>
              <br />
              <span class="portal-top-booklist-autor fs-small"><a href="http://forkn.jp/user/musosha/">無双舎</a></span>
            </p>
          </div>
          <div class="portal-top-booklist-description">
            <p>
              ヒロＮのデビュー作。
新しい恋愛指南本として大人気！
メイド喫茶時代の経験を活かし、女の子の行動の裏にある心理を
解き明かし、モテる男子になるためには、どうふるまったらいいのかを懇切丁寧に説明。
彼…
            </p>
          </div>
          			        <li>
          <div class="portal-top-booklist-box clearfix">
            <p class="portal-top-booklist-cover">
              <a href="http://forkn.jp/book/15/"><img border="0" src="http://foo.forkn.jp/img/cover_image/60x.png" />
</a>
	            <span class="portal-top-booklist-price">無料</span>
            </p>
            <p>
              <span class="portal-top-booklist-title fw-bold"><a href="http://forkn.jp/book/15/">カフェオレ・ライターのforkN出張エ…</a></span>
              <br />
              <span class="portal-top-booklist-autor fs-small"><a href="http://forkn.jp/user/yamadai/">マルコ</a></span>
            </p>
          </div>
          <div class="portal-top-booklist-description">
            <p>
              普段は画像や動画を使って面白ネタを紹介することが多いのですが、今回はそうしたブログの厳選ログに加え、forkN限定の書き下ろしエッセイを2本収録しました。こちらはテキストサイトの原点に立ち返って、テ…
            </p>
          </div>
          			        <li>
          <div class="portal-top-booklist-box clearfix">
            <p class="portal-top-booklist-cover">
              <a href="http://forkn.jp/book/14/"><img border="0" src="http://foo.forkn.jp/img/cover_image/60x.png" />
</a>
	            <span class="portal-top-booklist-price">無料</span>
            </p>
            <p>
              <span class="portal-top-booklist-title fw-bold"><a href="http://forkn.jp/book/14/">BLACK徒然草～グルメチャレンジ編～</a></span>
              <br />
              <span class="portal-top-booklist-autor fs-small"><a href="http://forkn.jp/user/jkun/">J君</a></span>
            </p>
          </div>
          <div class="portal-top-booklist-description">
            <p>
              BLACK徒然草で過去に紹介したB級グルメやお店のレビュー記事を加筆修正して電子書籍化したものです。
ずいぶん昔に書いたものが多いのでクオリティ的にはかなりアレですが、ひまつぶしとして読めばまあ読め…
            </p>
          </div>
          																								        </li>
      </ul>
      <p>
        <span class="portal-top-button-more"><a href="/pages/search/books/?s=recent&c=">新しい本をもっと見る</a></span>
      </p>
    </div>
  </div>

  <div id="portal-top-popular">
    <h2 class="portal-top-h2">人気の本</h2>
    <div class="portal-top-category">
      <dl class="portal-top-category-now clearfix">
        <dt>カテゴリ:</dt><dd class="toggle-all">すべて</dd>
      </dl>
      <ul class="portal-top-category-select clearfix">
        <li><a href="?c=">すべて</a></li>
                <li><a href="?c=1">小説</a></li>
                <li><a href="?c=11">マンガ</a></li>
                <li><a href="?c=19">実用</a></li>
                <li><a href="?c=30">趣味</a></li>
                <li><a href="?c=40">ノンフィクション</a></li>
                <li><a href="?c=48">絵本/写真</a></li>
                <li><a href="?c=51">ゲームブック</a></li>
                <li><a href="?c=53">教科書</a></li>
                <li><a href="?c=57">社会科学</a></li>
                <li><a href="?c=67">自然科学</a></li>
                <li><a href="?c=77">芸術</a></li>
                <li><a href="?c=85">ＡＶ</a></li>
                <li><a href="?c=88">Ｒ-18</a></li>
              </ul>
    </div>
    <div class="portal-top-booklist-container">
    <ul class="portal-top-booklist">
                			        <li>
          <div class="portal-top-booklist-box clearfix">
            <p class="portal-top-booklist-cover">
              <a href="http://forkn.jp/book/2/"><img border="0" src="http://forkn.jp/book/2/image/HJuMNJMG?thumb=60&t=1305633720" />
</a>
              <span class="portal-top-booklist-price">無料</span>
            </p>
            <p>
              <span class="portal-top-booklist-title fw-bold"><a href="http://forkn.jp/book/2/">ボールを保持するための大切な事は、すべ…</a></span>
              <br />
              <span class="portal-top-booklist-autor fs-small"><a href="http://forkn.jp/user/josepgualdiola7/">らいかーると</a></span>
            </p>
          </div>
          <div class="portal-top-booklist-description">
            <p>
              カテゴリーを問わずに、ボールを大切にするサッカーを目指すチームは増えてきていると感じます。そんな志の高いチームに参考になればと、バルセロナのサッカーをまとめてみました。
            </p>
          </div>
          			        <li>
          <div class="portal-top-booklist-box clearfix">
            <p class="portal-top-booklist-cover">
              <a href="http://forkn.jp/book/3/"><img border="0" src="http://forkn.jp/book/3/image/O95Hdnqc?thumb=60&t=1305633720" />
</a>
              <span class="portal-top-booklist-price">無料</span>
            </p>
            <p>
              <span class="portal-top-booklist-title fw-bold"><a href="http://forkn.jp/book/3/">2009ヤンキース（仮称）</a></span>
              <br />
              <span class="portal-top-booklist-autor fs-small"><a href="http://forkn.jp/user/daisukesugiura/">杉浦大介</a></span>
            </p>
          </div>
          <div class="portal-top-booklist-description">
            <p>
              新ヤンキースタジアム開場直後の2009年は、ヤンキースファンにとってはまさに夢のような１年になりました。その戦いぶりを間近で見守り続けたフリーライターのコラムをまとめて収録。さらに書き下ろしのサイド…
            </p>
          </div>
          			        <li>
          <div class="portal-top-booklist-box clearfix">
            <p class="portal-top-booklist-cover">
              <a href="http://forkn.jp/book/4/"><img border="0" src="http://forkn.jp/book/4/image/tLbVuL8Q?thumb=60&t=1305633722" />
</a>
              <span class="portal-top-booklist-price">無料</span>
            </p>
            <p>
              <span class="portal-top-booklist-title fw-bold"><a href="http://forkn.jp/book/4/">キノコと48手と相変わらずな私の日常</a></span>
              <br />
              <span class="portal-top-booklist-autor fs-small"><a href="http://forkn.jp/user/logipara/">ろじぱら　ワタナベ</a></span>
            </p>
          </div>
          <div class="portal-top-booklist-description">
            <p>
              日本古来より伝わる性行為の体位である48手を、なぜかキノコのイラストで表現した「キノコ48手アイコン」。とあるイベントで使ったものの、ほかに使い回しができないこの素材を、あえてコラムの題材として使っ…
            </p>
          </div>
          			        <li>
          <div class="portal-top-booklist-box clearfix">
            <p class="portal-top-booklist-cover">
              <a href="http://forkn.jp/book/5/"><img border="0" src="http://forkn.jp/book/5/image/2rPHDHuR?thumb=60&t=1305633722" />
</a>
              <span class="portal-top-booklist-price">無料</span>
            </p>
            <p>
              <span class="portal-top-booklist-title fw-bold"><a href="http://forkn.jp/book/5/">戦国初級列伝 浅井長政・初・江～201…</a></span>
              <br />
              <span class="portal-top-booklist-autor fs-small"><a href="http://forkn.jp/user/fronts/">フロンツ</a></span>
            </p>
          </div>
          <div class="portal-top-booklist-description">
            <p>
              アクションゲームやドラマなど、戦国時代をご存知ない方が
ちょっと興味を持つ切っ掛けになる作品は数多くありますし、
シミュレーションゲームや歴史小説のように既にある程度知識を持っている方が楽しむための…
            </p>
          </div>
          			        <li>
          <div class="portal-top-booklist-box clearfix">
            <p class="portal-top-booklist-cover">
              <a href="http://forkn.jp/book/6/"><img border="0" src="http://forkn.jp/book/6/image/sT8J9HiU?thumb=60&t=1305633733" />
</a>
              <span class="portal-top-booklist-price">無料</span>
            </p>
            <p>
              <span class="portal-top-booklist-title fw-bold"><a href="http://forkn.jp/book/6/">女の子の取扱説明書　２</a></span>
              <br />
              <span class="portal-top-booklist-autor fs-small"><a href="http://forkn.jp/user/hiroN/">ヒロＮ</a></span>
            </p>
          </div>
          <div class="portal-top-booklist-description">
            <p>
              メイド喫茶元オーナーとして、サブカル系恋愛指南役として、
活躍するヒロＮが、女の子のココロとカラダの秘密を徹底解剖。そこから、女の子つき合い方のノウハウを徹底的にご教授します。
さらに、ヒロＮのメイ…
            </p>
          </div>
                  </li>
      </ul>
      <p>
        <span class="portal-top-button-more"><a href="/pages/search/books/?s=popular&c=">人気の本をもっと見る</a></span>
      </p>
    </div>
  </div>

    <div id="portal-top-tl">
    <ul>
          </ul>
  </div>
  </div>

<div id="portal-side">
    <p class="m-b10">
    <a href="https://forkn.jp/pages/new_member/input"><img alt="新規登録" src="http://foo.forkn.jp/img/main/button_newmember.png" /></a>
  </p>
  <div id="portal-side-login">
    <h3 class="m-b10"><img alt="ログイン" src="http://foo.forkn.jp/img/main/title_portal_login.png" /></h3>
    <form action="https://forkn.jp/pages/login/" method="POST">
      <p class="m-b5 portal-side-login-form">
        ユーザーID<br />
        <input type="text" name="login_screen_name" />
      </p>
      <p class="m-b5 portal-side-login-form">
        パスワード<br />
        <input type="password" name="login_password" />
      </p>
      <input type="hidden" name="return_path" value="/pages/member/home/" />
      <p class="m-b10 portal-side-login-button">
        <input type="submit" value="ログイン" />
      </p>
    </form>
    <ul>
      <li><a href="">ユーザーIDを忘れた方</a></li>
      <li><a href="https://forkn.jp/pages/password_reminder/activation/input">パスワードを忘れた方</a></li>
    </ul>
  </div>
    
  <ul id="portal-side-futured">
    <li><a href="/special/special_1.html"><img alt="マンガを楽しむ" src="http://foo.forkn.jp/img/futured/001.jpg" /></a></li>
    <li><a href="/special/special_2.html"><img alt="スポーツの裏側みたいですか？" src="http://foo.forkn.jp/img/futured/002.jpg" /></a></li>
    <li><a href="/special/hiro_N.html"><img alt="ヒロN式の小説・エッセイ7作品" src="http://foo.forkn.jp/img/futured/003.jpg" /></a></li>
    <li><a href="/special/special_3.html"><img alt="伝説のテキストサイトが電子書籍に降臨" src="http://foo.forkn.jp/img/futured/004.jpg" /></a></li>
  </ul>

  
<h2><img alt="お知らせ" src="http://foo.forkn.jp/img/main/title_side_info.png" /></h2>

<div id="portal-side-info">
  
<p>
  <a href="/pages/information/list?page=1&target_page=member">過去のお知らせを見る</a>
</p>

</div>
</div>

</div>
</div>


<div id="footer" name="footer">
<div id="footer-main">
  <p class="clearfix">
    <span id="go-top"><a class="bg btn_pgtop" href="#pagetop">ページトップへ</a></span>
  </p>
  <ul id="footer-navi-service" class="clearfix">
	  <li><a href="about.html">forkNで、できること</a></li>
		<li><a href="/pages/information/list">facebook</a></li>
	  <li><a href="http://twitter.com/forkn_jp">forkN公式Twitter</a></li>
	  <li><a href="terms.html">利用規約</a></li>
	  <li><a href="/help/">ヘルプ</a></li>
	</ul>
  <ul id="footer-navi-corp" class="clearfix">
	  <li class="separate-disable"><a href="/"><img alt="forkN" src="http://foo.forkn.jp/img/main/logo.png" /></a></li>
	  <li><a href="/">トップ</a></li>
		<li><a href="http://www.seesaa.co.jp/">運営会社</a></li>
	  <li><a href="http://kiyaku.seesaa.net/category/548011-1.html ">プライバシーポリシー</a></li>
	  <li><a href="http://www.seesaa.co.jp/pages/enq/input.pl?enq=23">お問い合わせ</a></li>
	  <li><a href="/notation.html">特定商取引法に基づく表示</a></li>
	  <li class="separate-disable"><a href="http://www.seesaa.co.jp/recruit/index.html">採用情報</a></li>
	</ul>
	<p id="footer-copyright">
    <span id="copyright">Copyright &copy; 2011 Seesaa Inc. All Rights Reserved.</span>
  </p>
</div>
</div>

<div id="message-board" style="display:none;">
  <div id="message-board-message"></div>
  <div id="message-board-close-btn">close</div>
</div>
<script src="http://foo.forkn.jp/js/swfobject.js" type="text/javascript"></script>
<script src="http://foo.forkn.jp/js/jquery.js" type="text/javascript"></script>
<script src="http://foo.forkn.jp/js/jquery-ui.js" type="text/javascript"></script>
<script src="http://foo.forkn.jp/js/jquery-plugins/jquery.ba-bbq.min.js" type="text/javascript"></script>
<script src="http://foo.forkn.jp/js/jquery-plugins/jquery.uploadify.min.js" type="text/javascript"></script>
<script src="http://foo.forkn.jp/js/jquery-plugins/jquery.cleditor.js" type="text/javascript"></script>
<script src="http://foo.forkn.jp/js/jquery-plugins/jquery.jtemplates.js" type="text/javascript"></script>
<script src="http://foo.forkn.jp/js/jquery-plugins/jquery.autoSuggest.js" type="text/javascript"></script>
<script src="http://foo.forkn.jp/js/jquery-plugins/jquery.prettyPopin.js" type="text/javascript"></script>
<script src="http://foo.forkn.jp/js/jquery-plugins/jquery.simple-color-picker.js" type="text/javascript"></script>
<script src="http://foo.forkn.jp/js/jquery-plugins/jquery.tools.min.js" type="text/javascript"></script>
<script src="http://foo.forkn.jp/js/jquery-plugins/jquery.hotkeys.min.js" type="text/javascript"></script>
<script src="http://foo.forkn.jp/js/jquery-plugins/jquery.scrollTo-1.4.2-min.js" type="text/javascript"></script>
<script src="http://foo.forkn.jp/js/jquery-plugins/jquery.autopager-1.0.0.js" type="text/javascript"></script>
<script src="http://foo.forkn.jp/js/jquery-plugins/jquery.pagination.js" type="text/javascript"></script>
<script src="http://foo.forkn.jp/js/jquery-plugins/jquery.wordbreak.js" type="text/javascript"></script>
<script src="http://foo.forkn.jp/js/common.js" type="text/javascript"></script>
<script src="http://foo.forkn.jp/js/controls.js" type="text/javascript"></script>
<script type="text/javascript">//<![CDATA[
$(function () {
    var app = new appControl({ url : '/pages/index' });
    app.common(); app.start();
});
//]]></script>

<script type="text/javascript">//<![CDATA[
var accessToken = 'session::eb::1f21e0989499766eb6b84f74046e344e';
//]]></script>
<script type="text/javascript">
var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));
</script>
<script type="text/javascript">
try {
var pageTracker = _gat._getTracker("");
pageTracker._trackPageview();
} catch(err) {}</script>

</div>

</body>
</html>

@@ index.html
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<meta http-equiv="Content-Script-Type" content="text/javascript" />
<meta http-equiv="Content-Style-Type" content="text/css" />
<link href="/js/jquery-ui/css/eggplant/jquery-ui-1.8.12.custom.css" rel="stylesheet" type="text/css" />
<link href="/css/styles.css" rel="stylesheet" type="text/css" media="screen" />
<link href="/css/main.css" rel="stylesheet" type="text/css" media="screen" />
<link href="/css/portal.css" rel="stylesheet" type="text/css" media="screen" />
<link href="/css/member.css" rel="stylesheet" type="text/css" media="screen" />
<link href="/css/editor.css" rel="stylesheet" type="text/css" media="screen" />
<link href="/css/book.css" rel="stylesheet" type="text/css" media="screen" />
<link href="/css/user.css" rel="stylesheet" type="text/css" media="screen" />
<link href="/css/about.css" rel="stylesheet" type="text/css" media="screen" />
<link href="/css/special.css" rel="stylesheet" type="text/css" media="screen" />
<link href="/css/jquery.cleditor.css" rel="stylesheet" type="text/css" />
<title>電子書籍の出版・販売サービス forkN</title>
<meta name="description" content="電子書籍の出版、販売、閲覧、共有ができるサービスです。マンガ、小説、イラスト、写真集などをEPUBやPDFで販売でき、iPadやiPhone,androidでも読むことができます" />
<meta name="keywords" content="電子書籍,電子ブック,電子出版,ebook,eブック,EPUB,iphone,android,電子ブックリーダー,SNS,自費出版,無料,小説.コミック,マンガ,人誌,BL" />
</head>
<body>
<div id="container">

<div id="wrap">
<a name="pagetop" id="pagetop"></a>
<div id="header" class="clearfix">
  <h1 id="logo"><a href="http://forkn.jp/"><img src="/img/main/logo.png" alt="forkN" /></a></h1>
  <ul id="navigation" class="clearfix">
    <li class="navigation-01"><a href="">おすすめ</a></li>
    <li class="navigation-02"><a href="http://forkn.jp/pages/ranking/">ランキング</a></li>
    <li class="navigation-03"><a href="http://forkn.jp/pages/search/books/">作品検索</a></li>
    <li class="navigation-04"><a href="http://forkn.jp/pages/search/authors/">作家検索</a></li>
  </ul>
  
  
        <ul id="navigation-login-button" class="clearfix">
      <li><a href="https://forkn.jp/pages/login/"><img src="/img/main/header_button_login.png" alt="ログイン" /></a></li>
      <li><a href="https://forkn.jp/pages/new_member/input"><img src="/img/main/header_button_newmember.png" alt="新規投稿" /></a></li>
    </ul>
    
</div>

<div id="contents" class="clearfix">
<div id="portal-top">
  <div id="portal-service" class="clearfix">
    <div id="portal-service-read">
      <h2><img src="/img/main/portal_servie_h2_read.png" alt="本を読む" /></h2>
      <ul class="clearfix">
        <li>ランキング</li>
        <li class="portal-service-read-left">作品検索</li>
        <li class="portal-service-read-right">作家検索</li>
      </ul>
    </div>

    <div id="portal-service-public">
      <h2><img src="/img/main/portal_servie_h2_public.png" alt="本を書く" /></h2>
      <ul>
        <li>電子書籍を書く</li>
        <li>電子書籍を販売する</li>
      </ul>
    </div>
    
    <div id="portal-service-social">
      <h2><img src="/img/main/portal_servie_h2_social.png" alt="共有する" /></h2>
      <ul>
        <li>読んだ本を共有する</li>
        <li>ふせんでコメントを共有する</li>
      </ul>
    </div>
  </div>
  
  <div id="portal-top-new">
    <h2 class="portal-top-h2">新しい本</h2>
    <div class="portal-top-category">
      <dl class="portal-top-category-now clearfix">
        <dt>カテゴリ:</dt><dd class="toggle-all">すべて</dd>
      </dl>
      <ul class="portal-top-category-select clearfix">
        <li><a href="?c=">すべて</a></li>	    
                <li><a href="?c=1">小説</a></li>
                <li><a href="?c=11">マンガ</a></li>
                <li><a href="?c=19">実用</a></li>
                <li><a href="?c=30">趣味</a></li>
                <li><a href="?c=40">ノンフィクション</a></li>
                <li><a href="?c=48">絵本/写真</a></li>
                <li><a href="?c=51">ゲームブック</a></li>
                <li><a href="?c=53">教科書</a></li>
                <li><a href="?c=57">社会科学</a></li>
                <li><a href="?c=67">自然科学</a></li>
                <li><a href="?c=77">芸術</a></li>
                <li><a href="?c=85">ＡＶ</a></li>
                <li><a href="?c=88">Ｒ-18</a></li>
              </ul>
    </div>
    <div class="portal-top-booklist-container">
      <ul class="portal-top-booklist">
                			        <li>
          <div class="portal-top-booklist-box clearfix">
            <p class="portal-top-booklist-cover">
              <a href="http://forkn.jp/book/18/"><img src="/img/cover_image/60x.png" border="0" />
</a>
	            <span class="portal-top-booklist-price">無料</span>
            </p>
            <p>
              <span class="portal-top-booklist-title fw-bold"><a href="http://forkn.jp/book/18/">シニアライフ</a></span>
              <br />
              <span class="portal-top-booklist-autor fs-small"><a href="http://forkn.jp/user/musosha/">無双舎</a></span>
            </p>
          </div>
          <div class="portal-top-booklist-description">
            <p>
              現代の異端児・ヒロＮが、
セカンドライフをスタートするにあたって考えた。
人生を楽しく過ごすコツ。中高年うつから逃れる方法や
若い女の子との付き合い方。新しい趣味の持ち方、
ファッション論など、シニ…
            </p>
          </div>
          			        <li>
          <div class="portal-top-booklist-box clearfix">
            <p class="portal-top-booklist-cover">
              <a href="http://forkn.jp/book/17/"><img src="/img/cover_image/60x.png" border="0" />
</a>
	            <span class="portal-top-booklist-price">無料</span>
            </p>
            <p>
              <span class="portal-top-booklist-title fw-bold"><a href="http://forkn.jp/book/17/">男のダイエット</a></span>
              <br />
              <span class="portal-top-booklist-autor fs-small"><a href="http://forkn.jp/user/musosha/">無双舎</a></span>
            </p>
          </div>
          <div class="portal-top-booklist-description">
            <p>
              体重９２キロの超メタボから３０キロの減量に成功した奇跡の中年。
自制心なし、根性なしのヒロＮが、まさに、死のふちに立って、
必死の思いでつかんだダイエットの極意を大公開！
ヒトが陥るダイエットの罠、…
            </p>
          </div>
          			        <li>
          <div class="portal-top-booklist-box clearfix">
            <p class="portal-top-booklist-cover">
              <a href="http://forkn.jp/book/16/"><img src="/img/cover_image/60x.png" border="0" />
</a>
	            <span class="portal-top-booklist-price">無料</span>
            </p>
            <p>
              <span class="portal-top-booklist-title fw-bold"><a href="http://forkn.jp/book/16/">女の子の取扱説明書　１</a></span>
              <br />
              <span class="portal-top-booklist-autor fs-small"><a href="http://forkn.jp/user/musosha/">無双舎</a></span>
            </p>
          </div>
          <div class="portal-top-booklist-description">
            <p>
              ヒロＮのデビュー作。
新しい恋愛指南本として大人気！
メイド喫茶時代の経験を活かし、女の子の行動の裏にある心理を
解き明かし、モテる男子になるためには、どうふるまったらいいのかを懇切丁寧に説明。
彼…
            </p>
          </div>
          			        <li>
          <div class="portal-top-booklist-box clearfix">
            <p class="portal-top-booklist-cover">
              <a href="http://forkn.jp/book/15/"><img src="/img/cover_image/60x.png" border="0" />
</a>
	            <span class="portal-top-booklist-price">無料</span>
            </p>
            <p>
              <span class="portal-top-booklist-title fw-bold"><a href="http://forkn.jp/book/15/">カフェオレ・ライターのforkN出張エ…</a></span>
              <br />
              <span class="portal-top-booklist-autor fs-small"><a href="http://forkn.jp/user/yamadai/">マルコ</a></span>
            </p>
          </div>
          <div class="portal-top-booklist-description">
            <p>
              普段は画像や動画を使って面白ネタを紹介することが多いのですが、今回はそうしたブログの厳選ログに加え、forkN限定の書き下ろしエッセイを2本収録しました。こちらはテキストサイトの原点に立ち返って、テ…
            </p>
          </div>
          			        <li>
          <div class="portal-top-booklist-box clearfix">
            <p class="portal-top-booklist-cover">
              <a href="http://forkn.jp/book/14/"><img src="/img/cover_image/60x.png" border="0" />
</a>
	            <span class="portal-top-booklist-price">無料</span>
            </p>
            <p>
              <span class="portal-top-booklist-title fw-bold"><a href="http://forkn.jp/book/14/">BLACK徒然草～グルメチャレンジ編～</a></span>
              <br />
              <span class="portal-top-booklist-autor fs-small"><a href="http://forkn.jp/user/jkun/">J君</a></span>
            </p>
          </div>
          <div class="portal-top-booklist-description">
            <p>
              BLACK徒然草で過去に紹介したB級グルメやお店のレビュー記事を加筆修正して電子書籍化したものです。
ずいぶん昔に書いたものが多いのでクオリティ的にはかなりアレですが、ひまつぶしとして読めばまあ読め…
            </p>
          </div>
          																								        </li>
      </ul>
      <p>
        <span class="portal-top-button-more"><a href="/pages/search/books/?s=recent&c=">新しい本をもっと見る</a></span>
      </p>
    </div>
  </div>

  <div id="portal-top-popular">
    <h2 class="portal-top-h2">人気の本</h2>
    <div class="portal-top-category">
      <dl class="portal-top-category-now clearfix">
        <dt>カテゴリ:</dt><dd class="toggle-all">すべて</dd>
      </dl>
      <ul class="portal-top-category-select clearfix">
        <li><a href="?c=">すべて</a></li>
                <li><a href="?c=1">小説</a></li>
                <li><a href="?c=11">マンガ</a></li>
                <li><a href="?c=19">実用</a></li>
                <li><a href="?c=30">趣味</a></li>
                <li><a href="?c=40">ノンフィクション</a></li>
                <li><a href="?c=48">絵本/写真</a></li>
                <li><a href="?c=51">ゲームブック</a></li>
                <li><a href="?c=53">教科書</a></li>
                <li><a href="?c=57">社会科学</a></li>
                <li><a href="?c=67">自然科学</a></li>
                <li><a href="?c=77">芸術</a></li>
                <li><a href="?c=85">ＡＶ</a></li>
                <li><a href="?c=88">Ｒ-18</a></li>
              </ul>
    </div>
    <div class="portal-top-booklist-container">
    <ul class="portal-top-booklist">
                			        <li>
          <div class="portal-top-booklist-box clearfix">
            <p class="portal-top-booklist-cover">
              <a href="http://forkn.jp/book/2/"><img src="http://forkn.jp/book/2/image/HJuMNJMG?thumb=60&t=1305633720" border="0" />
</a>
              <span class="portal-top-booklist-price">無料</span>
            </p>
            <p>
              <span class="portal-top-booklist-title fw-bold"><a href="http://forkn.jp/book/2/">ボールを保持するための大切な事は、すべ…</a></span>
              <br />
              <span class="portal-top-booklist-autor fs-small"><a href="http://forkn.jp/user/josepgualdiola7/">らいかーると</a></span>
            </p>
          </div>
          <div class="portal-top-booklist-description">
            <p>
              カテゴリーを問わずに、ボールを大切にするサッカーを目指すチームは増えてきていると感じます。そんな志の高いチームに参考になればと、バルセロナのサッカーをまとめてみました。
            </p>
          </div>
          			        <li>
          <div class="portal-top-booklist-box clearfix">
            <p class="portal-top-booklist-cover">
              <a href="http://forkn.jp/book/3/"><img src="http://forkn.jp/book/3/image/O95Hdnqc?thumb=60&t=1305633720" border="0" />
</a>
              <span class="portal-top-booklist-price">無料</span>
            </p>
            <p>
              <span class="portal-top-booklist-title fw-bold"><a href="http://forkn.jp/book/3/">2009ヤンキース（仮称）</a></span>
              <br />
              <span class="portal-top-booklist-autor fs-small"><a href="http://forkn.jp/user/daisukesugiura/">杉浦大介</a></span>
            </p>
          </div>
          <div class="portal-top-booklist-description">
            <p>
              新ヤンキースタジアム開場直後の2009年は、ヤンキースファンにとってはまさに夢のような１年になりました。その戦いぶりを間近で見守り続けたフリーライターのコラムをまとめて収録。さらに書き下ろしのサイド…
            </p>
          </div>
          			        <li>
          <div class="portal-top-booklist-box clearfix">
            <p class="portal-top-booklist-cover">
              <a href="http://forkn.jp/book/4/"><img src="http://forkn.jp/book/4/image/tLbVuL8Q?thumb=60&t=1305633722" border="0" />
</a>
              <span class="portal-top-booklist-price">無料</span>
            </p>
            <p>
              <span class="portal-top-booklist-title fw-bold"><a href="http://forkn.jp/book/4/">キノコと48手と相変わらずな私の日常</a></span>
              <br />
              <span class="portal-top-booklist-autor fs-small"><a href="http://forkn.jp/user/logipara/">ろじぱら　ワタナベ</a></span>
            </p>
          </div>
          <div class="portal-top-booklist-description">
            <p>
              日本古来より伝わる性行為の体位である48手を、なぜかキノコのイラストで表現した「キノコ48手アイコン」。とあるイベントで使ったものの、ほかに使い回しができないこの素材を、あえてコラムの題材として使っ…
            </p>
          </div>
          			        <li>
          <div class="portal-top-booklist-box clearfix">
            <p class="portal-top-booklist-cover">
              <a href="http://forkn.jp/book/5/"><img src="http://forkn.jp/book/5/image/2rPHDHuR?thumb=60&t=1305633722" border="0" />
</a>
              <span class="portal-top-booklist-price">無料</span>
            </p>
            <p>
              <span class="portal-top-booklist-title fw-bold"><a href="http://forkn.jp/book/5/">戦国初級列伝 浅井長政・初・江～201…</a></span>
              <br />
              <span class="portal-top-booklist-autor fs-small"><a href="http://forkn.jp/user/fronts/">フロンツ</a></span>
            </p>
          </div>
          <div class="portal-top-booklist-description">
            <p>
              アクションゲームやドラマなど、戦国時代をご存知ない方が
ちょっと興味を持つ切っ掛けになる作品は数多くありますし、
シミュレーションゲームや歴史小説のように既にある程度知識を持っている方が楽しむための…
            </p>
          </div>
          			        <li>
          <div class="portal-top-booklist-box clearfix">
            <p class="portal-top-booklist-cover">
              <a href="http://forkn.jp/book/6/"><img src="http://forkn.jp/book/6/image/sT8J9HiU?thumb=60&t=1305633733" border="0" />
</a>
              <span class="portal-top-booklist-price">無料</span>
            </p>
            <p>
              <span class="portal-top-booklist-title fw-bold"><a href="http://forkn.jp/book/6/">女の子の取扱説明書　２</a></span>
              <br />
              <span class="portal-top-booklist-autor fs-small"><a href="http://forkn.jp/user/hiroN/">ヒロＮ</a></span>
            </p>
          </div>
          <div class="portal-top-booklist-description">
            <p>
              メイド喫茶元オーナーとして、サブカル系恋愛指南役として、
活躍するヒロＮが、女の子のココロとカラダの秘密を徹底解剖。そこから、女の子つき合い方のノウハウを徹底的にご教授します。
さらに、ヒロＮのメイ…
            </p>
          </div>
                  </li>
      </ul>
      <p>
        <span class="portal-top-button-more"><a href="/pages/search/books/?s=popular&c=">人気の本をもっと見る</a></span>
      </p>
    </div>
  </div>

    <div id="portal-top-tl">
    <ul>
          </ul>
  </div>
  </div>

<div id="portal-side">
    <p class="m-b10">
    <a href="https://forkn.jp/pages/new_member/input"><img src="/img/main/button_newmember.png" alt="新規登録" /></a>
  </p>
  <div id="portal-side-login">
    <h3 class="m-b10"><img src="/img/main/title_portal_login.png" alt="ログイン" /></h3>
    <form action="https://forkn.jp/pages/login/" method="POST">
      <p class="m-b5 portal-side-login-form">
        ユーザーID<br />
        <input type="text" name="login_screen_name" />
      </p>
      <p class="m-b5 portal-side-login-form">
        パスワード<br />
        <input type="password" name="login_password" />
      </p>
      <input type="hidden" name="return_path" value="/pages/member/home/" />
      <p class="m-b10 portal-side-login-button">
        <input type="submit" value="ログイン" />
      </p>
    </form>
    <ul>
      <li><a href="">ユーザーIDを忘れた方</a></li>
      <li><a href="https://forkn.jp/pages/password_reminder/activation/input">パスワードを忘れた方</a></li>
    </ul>
  </div>
    
  <ul id="portal-side-futured">
    <li><a href="/special/special_1.html"><img src="/img/futured/001.jpg" alt="マンガを楽しむ" /></a></li>
    <li><a href="/special/special_2.html"><img src="/img/futured/002.jpg" alt="スポーツの裏側みたいですか？" /></a></li>
    <li><a href="/special/hiro_N.html"><img src="/img/futured/003.jpg" alt="ヒロN式の小説・エッセイ7作品" /></a></li>
    <li><a href="/special/special_3.html"><img src="/img/futured/004.jpg" alt="伝説のテキストサイトが電子書籍に降臨" /></a></li>
  </ul>

  
<h2><img src="/img/main/title_side_info.png" alt="お知らせ" /></h2>

<div id="portal-side-info">
  
<p>
  <a href="/pages/information/list?page=1&target_page=member">過去のお知らせを見る</a>
</p>

</div>
</div>

</div>
</div>


<div id="footer" name="footer">
<div id="footer-main">
  <p class="clearfix">
    <span id="go-top"><a href="#pagetop" class="bg btn_pgtop">ページトップへ</a></span>
  </p>
  <ul id="footer-navi-service" class="clearfix">
	  <li><a href="about.html">forkNで、できること</a></li>
		<li><a href="/pages/information/list">facebook</a></li>
	  <li><a href="http://twitter.com/forkn_jp">forkN公式Twitter</a></li>
	  <li><a href="terms.html">利用規約</a></li>
	  <li><a href="/help/">ヘルプ</a></li>
	</ul>
  <ul id="footer-navi-corp" class="clearfix">
	  <li class="separate-disable"><a href="/"><img src="/img/main/logo.png" alt="forkN" /></a></li>
	  <li><a href="/">トップ</a></li>
		<li><a href="http://www.seesaa.co.jp/">運営会社</a></li>
	  <li><a href="http://kiyaku.seesaa.net/category/548011-1.html ">プライバシーポリシー</a></li>
	  <li><a href="http://www.seesaa.co.jp/pages/enq/input.pl?enq=23">お問い合わせ</a></li>
	  <li><a href="/notation.html">特定商取引法に基づく表示</a></li>
	  <li class="separate-disable"><a href="http://www.seesaa.co.jp/recruit/index.html">採用情報</a></li>
	</ul>
	<p id="footer-copyright">
    <span id="copyright">Copyright &copy; 2011 Seesaa Inc. All Rights Reserved.</span>
  </p>
</div>
</div>

<div id="message-board" style="display:none;">
  <div id="message-board-message"></div>
  <div id="message-board-close-btn">close</div>
</div>
<script src="/js/swfobject.js" type="text/javascript"></script>
<script src="/js/jquery.js" type="text/javascript"></script>
<script src="/js/jquery-ui.js" type="text/javascript"></script>
<script src="/js/jquery-plugins/jquery.ba-bbq.min.js" type="text/javascript"></script>
<script src="/js/jquery-plugins/jquery.uploadify.min.js" type="text/javascript"></script>
<script src="/js/jquery-plugins/jquery.cleditor.js" type="text/javascript"></script>
<script src="/js/jquery-plugins/jquery.jtemplates.js" type="text/javascript"></script>
<script src="/js/jquery-plugins/jquery.autoSuggest.js" type="text/javascript"></script>
<script src="/js/jquery-plugins/jquery.prettyPopin.js" type="text/javascript"></script>
<script src="/js/jquery-plugins/jquery.simple-color-picker.js" type="text/javascript"></script>
<script src="/js/jquery-plugins/jquery.tools.min.js" type="text/javascript"></script>
<script src="/js/jquery-plugins/jquery.hotkeys.min.js" type="text/javascript"></script>
<script src="/js/jquery-plugins/jquery.scrollTo-1.4.2-min.js" type="text/javascript"></script>
<script src="/js/jquery-plugins/jquery.autopager-1.0.0.js" type="text/javascript"></script>
<script src="/js/jquery-plugins/jquery.pagination.js" type="text/javascript"></script>
<script src="/js/jquery-plugins/jquery.wordbreak.js" type="text/javascript"></script>
<script src="/js/common.js" type="text/javascript"></script>
<script type="text/javascript" src="/js/controls.js"></script>
<script type="text/javascript">//<![CDATA[
$(function () {
    var app = new appControl({ url : '/pages/index' });
    app.common(); app.start();
});
//]]></script>

<script type="text/javascript">//<![CDATA[
var accessToken = 'session::eb::1f21e0989499766eb6b84f74046e344e';
//]]></script>
<script type="text/javascript">
var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));
</script>
<script type="text/javascript">
try {
var pageTracker = _gat._getTracker("");
pageTracker._trackPageview();
} catch(err) {}</script>

</div>

</body>
</html>

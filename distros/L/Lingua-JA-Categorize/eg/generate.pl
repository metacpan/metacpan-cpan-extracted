use strict;
use warnings;
use blib;
use Lingua::JA::Categorize;
use YAML;

print "Input your 'Yahoo API appid':";
my $appid = <STDIN>;
chomp $appid;
warn(
"You must set your own yahoo_api_appid, but now this program will try to 'test' for temporary"
) if !$appid;
my %config = ( yahoo_api_appid => $appid, yahoo_api_premium => 1 );

my $data        = YAML::Load( join '', <DATA> );
my $generator   = Lingua::JA::Categorize->new( config => \%config);
my $save_file   = "sample.bin";

$generator->generate($data);
$generator->save($save_file);

__DATA__
--- 
"エンターテインメント :: TV :: CM": 
  keyword: 
    - CM
  weight: 1
"エンターテインメント :: TV :: CS・BS": 
  keyword: 
    - CS BS
  weight: 1
"エンターテインメント :: TV :: TV": 
  keyword: 
    - TV
  weight: 3
"エンターテインメント :: TV :: ドラマ": 
  keyword: 
    - ドラマ
  weight: 1
"エンターテインメント :: TV :: 国内お笑い芸人": 
  keyword: 
    - 国内お笑い芸人
  weight: 1
"エンターテインメント :: TV :: 国内芸能人・タレント": 
  keyword: 
    - 国内芸能人 タレント
  weight: 1
"エンターテインメント :: TV :: 懐かしの芸能人・TV": 
  keyword: 
    - 懐かしの芸能人 TV
  weight: 1
"エンターテインメント :: TV :: 欧米芸能人・タレント": 
  keyword: 
    - 欧米芸能人 タレント
  weight: 1
"エンターテインメント :: TV :: 番組": 
  keyword: 
    - 番組
  weight: 1
"エンターテインメント :: TV :: 華流芸能人・タレント": 
  keyword: 
    - 華流芸能人 タレント
  weight: 1
"エンターテインメント :: TV :: 韓流芸能人・タレント": 
  keyword: 
    - 韓流芸能人 タレント
  weight: 1
"エンターテインメント :: アニメ・声優 :: アニメ・声優": 
  keyword: 
    - アニメ 声優
  weight: 3
"エンターテインメント :: エンターテインメント :: エンターテインメント": 
  keyword: 
    - エンターテインメント
  weight: 3
"エンターテインメント :: ギャンブル :: ギャンブル": 
  keyword: 
    - ギャンブル
  weight: 3
"エンターテインメント :: ギャンブル :: パチンコ・スロット": 
  keyword: 
    - パチンコ スロット
  weight: 1
"エンターテインメント :: ギャンブル :: 競馬": 
  keyword: 
    - 競馬
  weight: 1
"エンターテインメント :: スポーツ :: ゴルフ": 
  keyword: 
    - ゴルフ
  weight: 1
"エンターテインメント :: スポーツ :: サッカー": 
  keyword: 
    - サッカー
  weight: 1
"エンターテインメント :: スポーツ :: スキー・スノーボード": 
  keyword: 
    - スキー スノーボード
  weight: 1
"エンターテインメント :: スポーツ :: スピードスケート": 
  keyword: 
    - スピードスケート
  weight: 1
"エンターテインメント :: スポーツ :: スポーツ": 
  keyword: 
    - スポーツ
  weight: 3
"エンターテインメント :: スポーツ :: ソフトボール": 
  keyword: 
    - ソフトボール
  weight: 1
"エンターテインメント :: スポーツ :: テニス": 
  keyword: 
    - テニス
  weight: 1
"エンターテインメント :: スポーツ :: バスケットボール": 
  keyword: 
    - バスケットボール
  weight: 1
"エンターテインメント :: スポーツ :: バドミントン": 
  keyword: 
    - バドミントン
  weight: 1
"エンターテインメント :: スポーツ :: バレーボール": 
  keyword: 
    - バレーボール
  weight: 1
"エンターテインメント :: スポーツ :: フィギュアスケート": 
  keyword: 
    - フィギュアスケート
  weight: 1
"エンターテインメント :: スポーツ :: マリンスポーツ": 
  keyword: 
    - マリンスポーツ
  weight: 1
"エンターテインメント :: スポーツ :: モータースポーツ": 
  keyword: 
    - モータースポーツ
  weight: 1
"エンターテインメント :: スポーツ :: ラグビー・アメリカンフットボール": 
  keyword: 
    - ラグビー アメリカンフットボール
  weight: 1
"エンターテインメント :: スポーツ :: 五輪": 
  keyword: 
    - 五輪
  weight: 1
"エンターテインメント :: スポーツ :: 体操・新体操": 
  keyword: 
    - 体操 新体操
  weight: 1
"エンターテインメント :: スポーツ :: 卓球": 
  keyword: 
    - 卓球
  weight: 1
"エンターテインメント :: スポーツ :: 格闘技": 
  keyword: 
    - 格闘技
  weight: 1
"エンターテインメント :: スポーツ :: 武道": 
  keyword: 
    - 武道
  weight: 1
"エンターテインメント :: スポーツ :: 水泳": 
  keyword: 
    - 水泳
  weight: 1
"エンターテインメント :: スポーツ :: 野球": 
  keyword: 
    - 野球
  weight: 1
"エンターテインメント :: スポーツ :: 陸上": 
  keyword: 
    - 陸上
  weight: 1
"エンターテインメント :: ラジオ :: ラジオ": 
  keyword: 
    - ラジオ
  weight: 3
"エンターテインメント :: 卓上ゲーム :: カードゲーム": 
  keyword: 
    - カードゲーム
  weight: 1
"エンターテインメント :: 卓上ゲーム :: 卓上ゲーム": 
  keyword: 
    - 卓上ゲーム
  weight: 3
"エンターテインメント :: 卓上ゲーム :: 囲碁・将棋": 
  keyword: 
    - 囲碁 将棋
  weight: 1
"エンターテインメント :: 卓上ゲーム :: 麻雀": 
  keyword: 
    - 麻雀
  weight: 1
"エンターテインメント :: 映画 :: アジア映画": 
  keyword: 
    - アジア映画
  weight: 1
"エンターテインメント :: 映画 :: 俳優・女優": 
  keyword: 
    - 俳優 女優
  weight: 1
"エンターテインメント :: 映画 :: 映画": 
  keyword: 
    - 映画
  weight: 3
"エンターテインメント :: 映画 :: 洋画": 
  keyword: 
    - 洋画
  weight: 1
"エンターテインメント :: 映画 :: 邦画": 
  keyword: 
    - 邦画
  weight: 1
"エンターテインメント :: 演劇・古典芸能 :: 演劇・古典芸能": 
  keyword: 
    - 演劇 古典芸能
  weight: 3
"エンターテインメント :: 特撮・VFX :: 特撮・VFX": 
  keyword: 
    - 特撮 VFX
  weight: 3
"エンターテインメント :: 音楽・ダンス :: インディーズ": 
  keyword: 
    - インディーズ
  weight: 1
"エンターテインメント :: 音楽・ダンス :: カラオケ": 
  keyword: 
    - カラオケ
  weight: 1
"エンターテインメント :: 音楽・ダンス :: クラシック": 
  keyword: 
    - クラシック
  weight: 1
"エンターテインメント :: 音楽・ダンス :: ダンス": 
  keyword: 
    - ダンス
  weight: 1
"エンターテインメント :: 音楽・ダンス :: ナツメロ": 
  keyword: 
    - ナツメロ
  weight: 1
"エンターテインメント :: 音楽・ダンス :: ライブ・コンサート": 
  keyword: 
    - ライブ コンサート
  weight: 1
"エンターテインメント :: 音楽・ダンス :: 作詞・作曲": 
  keyword: 
    - 作詞 作曲
  weight: 1
"エンターテインメント :: 音楽・ダンス :: 国内アーティスト": 
  keyword: 
    - 国内アーティスト
  weight: 1
"エンターテインメント :: 音楽・ダンス :: 楽器・演奏": 
  keyword: 
    - 楽器 演奏
  weight: 1
"エンターテインメント :: 音楽・ダンス :: 海外アーティスト": 
  keyword: 
    - 海外アーティスト
  weight: 1
"エンターテインメント :: 音楽・ダンス :: 現代音楽": 
  keyword: 
    - 現代音楽
  weight: 1
"エンターテインメント :: 音楽・ダンス :: 音楽・ダンス": 
  keyword: 
    - 音楽 ダンス
  weight: 3
"エンターテインメント :: 音楽・ダンス :: 音楽配信": 
  keyword: 
    - 音楽配信
  weight: 1
"コンピューター :: OS :: BSD系OS": 
  keyword: 
    - BSD系OS
  weight: 1
"コンピューター :: OS :: Linux系OS": 
  keyword: 
    - Linux系OS
  weight: 1
"コンピューター :: OS :: OS": 
  keyword: 
    - OS
  weight: 3
"コンピューター :: OS :: Solaris系OS": 
  keyword: 
    - Solaris系OS
  weight: 1
"コンピューター :: OS :: Windows系OS": 
  keyword: 
    - Windows系OS
  weight: 1
"コンピューター :: コンピューター :: コンピューター": 
  keyword: 
    - コンピューター
  weight: 3
"コンピューター :: データベース :: MySQL": 
  keyword: 
    - MySQL
  weight: 1
"コンピューター :: データベース :: Oracle": 
  keyword: 
    - Oracle
  weight: 1
"コンピューター :: データベース :: PostgreSQL": 
  keyword: 
    - PostgreSQL
  weight: 1
"コンピューター :: データベース :: SQL Server": 
  keyword: 
    - SQL Server
  weight: 1
"コンピューター :: データベース :: データベース": 
  keyword: 
    - データベース
  weight: 3
"コンピューター :: ネットワークセキュリティ :: ネットワークセキュリティ": 
  keyword: 
    - ネットワークセキュリティ
  weight: 3
"コンピューター :: ハードウェア(サーバー) :: ハードウェア(サーバー)": 
  keyword: 
    - ハードウェア(サーバー)
  weight: 3
"コンピューター :: プログラミング :: AJAX": 
  keyword: 
    - AJAX
  weight: 1
"コンピューター :: プログラミング :: C&amp;C++": 
  keyword: 
    - C&amp;C++
  weight: 1
"コンピューター :: プログラミング :: CGI": 
  keyword: 
    - CGI
  weight: 1
"コンピューター :: プログラミング :: Flash": 
  keyword: 
    - Flash
  weight: 1
"コンピューター :: プログラミング :: HTML": 
  keyword: 
    - HTML
  weight: 1
"コンピューター :: プログラミング :: Java": 
  keyword: 
    - Java
  weight: 1
"コンピューター :: プログラミング :: JavaScript": 
  keyword: 
    - JavaScript
  weight: 1
"コンピューター :: プログラミング :: Microsoft ASP": 
  keyword: 
    - Microsoft ASP
  weight: 1
"コンピューター :: プログラミング :: PHP": 
  keyword: 
    - PHP
  weight: 1
"コンピューター :: プログラミング :: Perl": 
  keyword: 
    - Perl
  weight: 1
"コンピューター :: プログラミング :: Ruby": 
  keyword: 
    - Ruby
  weight: 1
"コンピューター :: プログラミング :: Visual Basic": 
  keyword: 
    - Visual Basic
  weight: 1
"コンピューター :: プログラミング :: Webデザイン・CSS": 
  keyword: 
    - Webデザイン CSS
  weight: 1
"コンピューター :: プログラミング :: XML": 
  keyword: 
    - XML
  weight: 1
"コンピューター :: プログラミング :: プログラミング": 
  keyword: 
    - プログラミング
  weight: 3
"コンピューター :: 業務ソフトウェア :: CAD・DTP": 
  keyword: 
    - CAD DTP
  weight: 1
"コンピューター :: 業務ソフトウェア :: オープンソース": 
  keyword: 
    - オープンソース
  weight: 1
"コンピューター :: 業務ソフトウェア :: グラフィックソフト": 
  keyword: 
    - グラフィックソフト
  weight: 1
"コンピューター :: 業務ソフトウェア :: グループウェア": 
  keyword: 
    - グループウェア
  weight: 1
"コンピューター :: 業務ソフトウェア :: 会計ソフト": 
  keyword: 
    - 会計ソフト
  weight: 1
"コンピューター :: 業務ソフトウェア :: 業務ソフトウェア": 
  keyword: 
    - 業務ソフトウェア
  weight: 3
"コンピューター :: 運用・管理 :: 運用・管理": 
  keyword: 
    - 運用 管理
  weight: 3
"コンピューター :: 開発 :: オープンソース": 
  keyword: 
    - オープンソース
  weight: 1
"コンピューター :: 開発 :: スケーラビリティ": 
  keyword: 
    - スケーラビリティ
  weight: 1
"コンピューター :: 開発 :: 開発": 
  keyword: 
    - 開発
  weight: 3
"デジタルライフ :: E-Mail :: E-Mail": 
  keyword: 
    - E-Mail
  weight: 3
"デジタルライフ :: Macintosh :: Macintosh": 
  keyword: 
    - Macintosh
  weight: 3
"デジタルライフ :: PCパーツ・周辺機器 :: CPU・メモリ・マザーボード": 
  keyword: 
    - CPU メモリ マザーボード
  weight: 1
"デジタルライフ :: PCパーツ・周辺機器 :: PCパーツ・周辺機器": 
  keyword: 
    - PCパーツ 周辺機器
  weight: 3
"デジタルライフ :: PCパーツ・周辺機器 :: サウンドカード": 
  keyword: 
    - サウンドカード
  weight: 1
"デジタルライフ :: PCパーツ・周辺機器 :: ディスプレイ": 
  keyword: 
    - ディスプレイ
  weight: 1
"デジタルライフ :: PCパーツ・周辺機器 :: ドライブ・ストレージ": 
  keyword: 
    - ドライブ ストレージ
  weight: 1
"デジタルライフ :: PCパーツ・周辺機器 :: ネットワーク機器": 
  keyword: 
    - ネットワーク機器
  weight: 1
"デジタルライフ :: PCパーツ・周辺機器 :: ビデオカード": 
  keyword: 
    - ビデオカード
  weight: 1
"デジタルライフ :: PCパーツ・周辺機器 :: プリンター＆スキャナー": 
  keyword: 
    - プリンター スキャナー
  weight: 1
"デジタルライフ :: PCパーツ・周辺機器 :: マウス・キーボード": 
  keyword: 
    - マウス キーボード
  weight: 1
"デジタルライフ :: SNS :: SNS": 
  keyword: 
    - SNS
  weight: 3
"デジタルライフ :: Windows :: Windows": 
  keyword: 
    - Windows
  weight: 3
"デジタルライフ :: Windows :: Windows 7": 
  keyword: 
    - Windows 7
  weight: 1
"デジタルライフ :: Windows :: Windows 95/98": 
  keyword: 
    - Windows 95 98
  weight: 1
"デジタルライフ :: Windows :: Windows Me": 
  keyword: 
    - Windows Me
  weight: 1
"デジタルライフ :: Windows :: Windows NT/2000": 
  keyword: 
    - Windows NT 2000
  weight: 1
"デジタルライフ :: Windows :: Windows Vista": 
  keyword: 
    - Windows Vista
  weight: 1
"デジタルライフ :: Windows :: Windows XP": 
  keyword: 
    - Windows XP
  weight: 1
"デジタルライフ :: インターネット接続 :: ADSL": 
  keyword: 
    - ADSL
  weight: 1
"デジタルライフ :: インターネット接続 :: FTTH(光ファイバー)": 
  keyword: 
    - FTTH(光ファイバー)
  weight: 1
"デジタルライフ :: インターネット接続 :: ISDN": 
  keyword: 
    - ISDN
  weight: 1
"デジタルライフ :: インターネット接続 :: ISP(プロバイダ)": 
  keyword: 
    - ISP(プロバイダ)
  weight: 1
"デジタルライフ :: インターネット接続 :: インターネット接続": 
  keyword: 
    - インターネット接続
  weight: 3
"デジタルライフ :: インターネット接続 :: ホームページスペース・ASP": 
  keyword: 
    - ホームページスペース ASP
  weight: 1
"デジタルライフ :: インターネット接続 :: ワイヤレス・無線LAN": 
  keyword: 
    - ワイヤレス 無線LAN
  weight: 1
"デジタルライフ :: ウィルス対策 :: ウィルス対策": 
  keyword: 
    - ウィルス対策
  weight: 3
"デジタルライフ :: ゲーム :: オンラインゲーム": 
  keyword: 
    - オンラインゲーム
  weight: 1
"デジタルライフ :: ゲーム :: ゲーム": 
  keyword: 
    - ゲーム
  weight: 3
"デジタルライフ :: ゲーム :: ゲームソフト": 
  keyword: 
    - ゲームソフト
  weight: 1
"デジタルライフ :: ゲーム :: ゲーム機": 
  keyword: 
    - ゲーム機
  weight: 1
"デジタルライフ :: スパイウェア対策 :: スパイウェア対策": 
  keyword: 
    - スパイウェア対策
  weight: 3
"デジタルライフ :: ソフトウェア :: MS Office": 
  keyword: 
    - MS Office
  weight: 1
"デジタルライフ :: ソフトウェア :: Office系ソフト": 
  keyword: 
    - Office系ソフト
  weight: 1
"デジタルライフ :: ソフトウェア :: はがきソフト": 
  keyword: 
    - はがきソフト
  weight: 1
"デジタルライフ :: ソフトウェア :: ソフトウェア": 
  keyword: 
    - ソフトウェア
  weight: 3
"デジタルライフ :: ソフトウェア :: フリーウェア": 
  keyword: 
    - フリーウェア
  weight: 1
"デジタルライフ :: ソフトウェア :: ブラウザ": 
  keyword: 
    - ブラウザ
  weight: 1
"デジタルライフ :: ソフトウェア :: ホームページ作成ソフト": 
  keyword: 
    - ホームページ作成ソフト
  weight: 1
"デジタルライフ :: ソフトウェア :: 動画・画像処理": 
  keyword: 
    - 動画 画像処理
  weight: 1
"デジタルライフ :: デジタルライフ :: デジタルライフ": 
  keyword: 
    - デジタルライフ
  weight: 3
"デジタルライフ :: ネットショッピング :: オークション": 
  keyword: 
    - オークション
  weight: 1
"デジタルライフ :: ネットショッピング :: ネットショッピング": 
  keyword: 
    - ネットショッピング
  weight: 3
"デジタルライフ :: ネットショッピング :: ネット通販": 
  keyword: 
    - ネット通販
  weight: 1
"デジタルライフ :: ネットトラブル :: ネットトラブル": 
  keyword: 
    - ネットトラブル
  weight: 3
"デジタルライフ :: ハードウェア :: デスクトップPC": 
  keyword: 
    - デスクトップPC
  weight: 1
"デジタルライフ :: ハードウェア :: ノートPC": 
  keyword: 
    - ノートPC
  weight: 1
"デジタルライフ :: ハードウェア :: ハードウェア": 
  keyword: 
    - ハードウェア
  weight: 3
"デジタルライフ :: ハードウェア :: モバイル端末": 
  keyword: 
    - モバイル端末
  weight: 1
"デジタルライフ :: ブログ :: ブログ": 
  keyword: 
    - ブログ
  weight: 3
"デジタルライフ :: ポイントサービス :: ポイントサービス": 
  keyword: 
    - ポイントサービス
  weight: 3
"デジタルライフ :: マルチメディア :: デジタルカメラ": 
  keyword: 
    - デジタルカメラ
  weight: 1
"デジタルライフ :: マルチメディア :: ビデオカメラ": 
  keyword: 
    - ビデオカメラ
  weight: 1
"デジタルライフ :: マルチメディア :: マルチメディア": 
  keyword: 
    - マルチメディア
  weight: 3
"デジタルライフ :: マルチメディア :: メディア(記憶媒体)": 
  keyword: 
    - メディア(記憶媒体)
  weight: 1
"デジタルライフ :: ワンセグ放送 :: ワンセグ放送": 
  keyword: 
    - ワンセグ放送
  weight: 3
"デジタルライフ :: 動画サービス :: 動画サービス": 
  keyword: 
    - 動画サービス
  weight: 3
"デジタルライフ :: 携帯・PHS :: Android": 
  keyword: 
    - Android
  weight: 1
"デジタルライフ :: 携帯・PHS :: SoftBank": 
  keyword: 
    - SoftBank
  weight: 1
"デジタルライフ :: 携帯・PHS :: WILLCOM": 
  keyword: 
    - WILLCOM
  weight: 1
"デジタルライフ :: 携帯・PHS :: au": 
  keyword: 
    - au
  weight: 1
"デジタルライフ :: 携帯・PHS :: docomo": 
  keyword: 
    - docomo
  weight: 1
"デジタルライフ :: 携帯・PHS :: iPhone": 
  keyword: 
    - iPhone
  weight: 1
"デジタルライフ :: 携帯・PHS :: アバター": 
  keyword: 
    - アバター
  weight: 1
"デジタルライフ :: 携帯・PHS :: イーモバイル": 
  keyword: 
    - イーモバイル
  weight: 1
"デジタルライフ :: 携帯・PHS :: ケータイゲーム": 
  keyword: 
    - ケータイゲーム
  weight: 1
"デジタルライフ :: 携帯・PHS :: デコメ": 
  keyword: 
    - デコメ
  weight: 1
"デジタルライフ :: 携帯・PHS :: 携帯・PHS": 
  keyword: 
    - 携帯 PHS
  weight: 3
"デジタルライフ :: 携帯・PHS :: 着うた・着メロ・待受・動画": 
  keyword: 
    - 着うた 着メロ 待受 動画
  weight: 1
"デジタルライフ :: 携帯・PHS :: 電子書籍": 
  keyword: 
    - 電子書籍
  weight: 1
"デジタルライフ :: 通信 :: FAX": 
  keyword: 
    - FAX
  weight: 1
"デジタルライフ :: 通信 :: IP電話": 
  keyword: 
    - IP電話
  weight: 1
"デジタルライフ :: 通信 :: 固定電話": 
  keyword: 
    - 固定電話
  weight: 1
"デジタルライフ :: 通信 :: 通信": 
  keyword: 
    - 通信
  weight: 3
"ビジネス＆キャリア :: SEO対策 :: SEO対策": 
  keyword: 
    - SEO対策
  weight: 3
"ビジネス＆キャリア :: SOHO :: SOHO": 
  keyword: 
    - SOHO
  weight: 3
"ビジネス＆キャリア :: インターネットビジネス :: インターネットビジネス": 
  keyword: 
    - インターネットビジネス
  weight: 3
"ビジネス＆キャリア :: クリエイティブ :: クリエイティブ": 
  keyword: 
    - クリエイティブ
  weight: 3
"ビジネス＆キャリア :: コンサルティング :: コンサルティング": 
  keyword: 
    - コンサルティング
  weight: 3
"ビジネス＆キャリア :: システムエンジニアリング :: システムエンジニアリング": 
  keyword: 
    - システムエンジニアリング
  weight: 3
"ビジネス＆キャリア :: ビジネス＆キャリア :: ビジネス＆キャリア": 
  keyword: 
    - ビジネス キャリア
  weight: 3
"ビジネス＆キャリア :: マーケティング :: マーケティング": 
  keyword: 
    - マーケティング
  weight: 3
"ビジネス＆キャリア :: 就職・転職 :: アルバイト・パート": 
  keyword: 
    - アルバイト パート
  weight: 1
"ビジネス＆キャリア :: 就職・転職 :: 失業・リストラ": 
  keyword: 
    - 失業 リストラ
  weight: 1
"ビジネス＆キャリア :: 就職・転職 :: 就職": 
  keyword: 
    - 就職
  weight: 1
"ビジネス＆キャリア :: 就職・転職 :: 就職・転職": 
  keyword: 
    - 就職 転職
  weight: 3
"ビジネス＆キャリア :: 就職・転職 :: 履歴書": 
  keyword: 
    - 履歴書
  weight: 1
"ビジネス＆キャリア :: 就職・転職 :: 派遣": 
  keyword: 
    - 派遣
  weight: 1
"ビジネス＆キャリア :: 就職・転職 :: 転職": 
  keyword: 
    - 転職
  weight: 1
"ビジネス＆キャリア :: 特許 :: 特許": 
  keyword: 
    - 特許
  weight: 3
"ビジネス＆キャリア :: 経営情報システム :: 経営情報システム": 
  keyword: 
    - 経営情報システム
  weight: 3
"ビジネス＆キャリア :: 財務・会計・経理 :: 財務・会計・経理": 
  keyword: 
    - 財務 会計 経理
  weight: 3
"ビジネス＆キャリア :: 資格 :: Microsoft認定資格": 
  keyword: 
    - Microsoft認定資格
  weight: 1
"ビジネス＆キャリア :: 資格 :: TOEFL・TOEIC・英語検定": 
  keyword: 
    - TOEFL TOEIC 英語検定
  weight: 1
"ビジネス＆キャリア :: 資格 :: フィナンシャルプランナー": 
  keyword: 
    - フィナンシャルプランナー
  weight: 1
"ビジネス＆キャリア :: 資格 :: 介護士・ケアマネージャー": 
  keyword: 
    - 介護士 ケアマネージャー
  weight: 1
"ビジネス＆キャリア :: 資格 :: 公務員試験": 
  keyword: 
    - 公務員試験
  weight: 1
"ビジネス＆キャリア :: 資格 :: 公認会計士": 
  keyword: 
    - 公認会計士
  weight: 1
"ビジネス＆キャリア :: 資格 :: 建築士": 
  keyword: 
    - 建築士
  weight: 1
"ビジネス＆キャリア :: 資格 :: 弁護士": 
  keyword: 
    - 弁護士
  weight: 1
"ビジネス＆キャリア :: 資格 :: 情報処理技術者": 
  keyword: 
    - 情報処理技術者
  weight: 1
"ビジネス＆キャリア :: 資格 :: 旅行業務取扱管理者": 
  keyword: 
    - 旅行業務取扱管理者
  weight: 1
"ビジネス＆キャリア :: 資格 :: 栄養士": 
  keyword: 
    - 栄養士
  weight: 1
"ビジネス＆キャリア :: 資格 :: 看護師": 
  keyword: 
    - 看護師
  weight: 1
"ビジネス＆キャリア :: 資格 :: 簿記": 
  keyword: 
    - 簿記
  weight: 1
"ビジネス＆キャリア :: 資格 :: 美容師・理容師": 
  keyword: 
    - 美容師 理容師
  weight: 1
"ビジネス＆キャリア :: 資格 :: 自動車免許": 
  keyword: 
    - 自動車免許
  weight: 1
"ビジネス＆キャリア :: 資格 :: 薬剤師": 
  keyword: 
    - 薬剤師
  weight: 1
"ビジネス＆キャリア :: 資格 :: 行政書士・司法書士": 
  keyword: 
    - 行政書士 司法書士
  weight: 1
"ビジネス＆キャリア :: 資格 :: 販売士": 
  keyword: 
    - 販売士
  weight: 1
"ビジネス＆キャリア :: 資格 :: 資格": 
  keyword: 
    - 資格
  weight: 3
"ビジネス＆キャリア :: 起業 :: 起業": 
  keyword: 
    - 起業
  weight: 3
"マネー :: マネー :: マネー": 
  keyword: 
    - マネー
  weight: 3
"マネー :: 保険 :: 保険": 
  keyword: 
    - 保険
  weight: 3
"マネー :: 保険 :: 健康保険": 
  keyword: 
    - 健康保険
  weight: 1
"マネー :: 保険 :: 医療保険": 
  keyword: 
    - 医療保険
  weight: 1
"マネー :: 保険 :: 損害保険": 
  keyword: 
    - 損害保険
  weight: 1
"マネー :: 保険 :: 生命保険": 
  keyword: 
    - 生命保険
  weight: 1
"マネー :: 保険 :: 雇用保険": 
  keyword: 
    - 雇用保険
  weight: 1
"マネー :: 投資・融資 :: BRICs・VISTA": 
  keyword: 
    - BRICs VISTA
  weight: 1
"マネー :: 投資・融資 :: ETF・REIT": 
  keyword: 
    - ETF REIT
  weight: 1
"マネー :: 投資・融資 :: 債券": 
  keyword: 
    - 債券
  weight: 1
"マネー :: 投資・融資 :: 先物": 
  keyword: 
    - 先物
  weight: 1
"マネー :: 投資・融資 :: 国内株": 
  keyword: 
    - 国内株
  weight: 1
"マネー :: 投資・融資 :: 投資・融資": 
  keyword: 
    - 投資 融資
  weight: 3
"マネー :: 投資・融資 :: 株式全般": 
  keyword: 
    - 株式全般
  weight: 1
"マネー :: 投資・融資 :: 海外株": 
  keyword: 
    - 海外株
  weight: 1
"マネー :: 投資・融資 :: 為替・FX": 
  keyword: 
    - 為替 FX
  weight: 1
"マネー :: 投資・融資 :: 融資": 
  keyword: 
    - 融資
  weight: 1
"マネー :: 投資・融資 :: 資産運用・投資信託": 
  keyword: 
    - 資産運用 投資信託
  weight: 1
"マネー :: 暮らしのマネー :: ネットバンキング": 
  keyword: 
    - ネットバンキング
  weight: 1
"マネー :: 暮らしのマネー :: ローン": 
  keyword: 
    - ローン
  weight: 1
"マネー :: 暮らしのマネー :: 家計の相談・家計診断": 
  keyword: 
    - 家計の相談 家計診断
  weight: 1
"マネー :: 暮らしのマネー :: 年金": 
  keyword: 
    - 年金
  weight: 1
"マネー :: 暮らしのマネー :: 暮らしのマネー": 
  keyword: 
    - 暮らしのマネー
  weight: 3
"マネー :: 暮らしのマネー :: 消費者金融・債務整理": 
  keyword: 
    - 消費者金融 債務整理
  weight: 1
"マネー :: 暮らしのマネー :: 税金": 
  keyword: 
    - 税金
  weight: 1
"マネー :: 暮らしのマネー :: 貯蓄": 
  keyword: 
    - 貯蓄
  weight: 1
"マネー :: 暮らしのマネー :: 電子マネー": 
  keyword: 
    - 電子マネー
  weight: 1
"ライフ :: ペット :: ペット": 
  keyword: 
    - ペット
  weight: 3
"ライフ :: ペット :: 小動物": 
  keyword: 
    - 小動物
  weight: 1
"ライフ :: ペット :: 昆虫": 
  keyword: 
    - 昆虫
  weight: 1
"ライフ :: ペット :: 爬虫類・両生類": 
  keyword: 
    - 爬虫類 両生類
  weight: 1
"ライフ :: ペット :: 犬": 
  keyword: 
    - 犬
  weight: 1
"ライフ :: ペット :: 猫": 
  keyword: 
    - 猫
  weight: 1
"ライフ :: ペット :: 魚": 
  keyword: 
    - 魚
  weight: 1
"ライフ :: ペット :: 鳥": 
  keyword: 
    - 鳥
  weight: 1
"ライフ :: ライフ :: ライフ": 
  keyword: 
    - ライフ
  weight: 3
"ライフ :: 住まい :: DIY(日曜大工)": 
  keyword: 
    - DIY(日曜大工)
  weight: 1
"ライフ :: 住まい :: インテリア・エクステリア": 
  keyword: 
    - インテリア エクステリア
  weight: 1
"ライフ :: 住まい :: ガーデニング": 
  keyword: 
    - ガーデニング
  weight: 1
"ライフ :: 住まい :: 不動産売買": 
  keyword: 
    - 不動産売買
  weight: 1
"ライフ :: 住まい :: 不動産賃貸": 
  keyword: 
    - 不動産賃貸
  weight: 1
"ライフ :: 住まい :: 住まい": 
  keyword: 
    - 住まい
  weight: 3
"ライフ :: 住まい :: 建築・リフォーム": 
  keyword: 
    - 建築 リフォーム
  weight: 1
"ライフ :: 住まい :: 引越し": 
  keyword: 
    - 引越し
  weight: 1
"ライフ :: 出産・育児 :: 不妊": 
  keyword: 
    - 不妊
  weight: 1
"ライフ :: 出産・育児 :: 出産": 
  keyword: 
    - 出産
  weight: 1
"ライフ :: 出産・育児 :: 出産・育児": 
  keyword: 
    - 出産 育児
  weight: 3
"ライフ :: 出産・育児 :: 妊娠": 
  keyword: 
    - 妊娠
  weight: 1
"ライフ :: 出産・育児 :: 育児": 
  keyword: 
    - 育児
  weight: 1
"ライフ :: 家電製品 :: その他（家電製品）": 
  keyword: 
    - その他（家電製品）
  weight: 1
"ライフ :: 家電製品 :: エアコン・空調": 
  keyword: 
    - エアコン 空調
  weight: 1
"ライフ :: 家電製品 :: 健康家電": 
  keyword: 
    - 健康家電
  weight: 1
"ライフ :: 家電製品 :: 冷蔵庫": 
  keyword: 
    - 冷蔵庫
  weight: 1
"ライフ :: 家電製品 :: 家電製品": 
  keyword: 
    - 家電製品
  weight: 3
"ライフ :: 家電製品 :: 掃除機": 
  keyword: 
    - 掃除機
  weight: 1
"ライフ :: 家電製品 :: 洗濯機": 
  keyword: 
    - 洗濯機
  weight: 1
"ライフ :: 家電製品 :: 照明": 
  keyword: 
    - 照明
  weight: 1
"ライフ :: 家電製品 :: 調理器具": 
  keyword: 
    - 調理器具
  weight: 1
"ライフ :: 恋愛・人生相談 :: いじめ相談": 
  keyword: 
    - いじめ相談
  weight: 1
"ライフ :: 恋愛・人生相談 :: シニアライフ": 
  keyword: 
    - シニアライフ
  weight: 1
"ライフ :: 恋愛・人生相談 :: 友達・仲間関係": 
  keyword: 
    - 友達 仲間関係
  weight: 1
"ライフ :: 恋愛・人生相談 :: 夫婦・家族": 
  keyword: 
    - 夫婦 家族
  weight: 1
"ライフ :: 恋愛・人生相談 :: 恋愛・人生相談": 
  keyword: 
    - 恋愛 人生相談
  weight: 3
"ライフ :: 恋愛・人生相談 :: 恋愛相談": 
  keyword: 
    - 恋愛相談
  weight: 1
"ライフ :: 恋愛・人生相談 :: 社会・職場": 
  keyword: 
    - 社会 職場
  weight: 1
"ライフ :: 料理・グルメ :: お茶・ドリンク": 
  keyword: 
    - お茶 ドリンク
  weight: 1
"ライフ :: 料理・グルメ :: お酒": 
  keyword: 
    - お酒
  weight: 1
"ライフ :: 料理・グルメ :: スイーツ": 
  keyword: 
    - スイーツ
  weight: 1
"ライフ :: 料理・グルメ :: 地方特産・名産": 
  keyword: 
    - 地方特産 名産
  weight: 1
"ライフ :: 料理・グルメ :: 料理レシピ": 
  keyword: 
    - 料理レシピ
  weight: 1
"ライフ :: 料理・グルメ :: 料理・グルメ": 
  keyword: 
    - 料理 グルメ
  weight: 3
"ライフ :: 料理・グルメ :: 素材・食材": 
  keyword: 
    - 素材 食材
  weight: 1
"ライフ :: 料理・グルメ :: 食器・キッチン用品": 
  keyword: 
    - 食器 キッチン用品
  weight: 1
"ライフ :: 生活お役立ち :: コンビニ・ファーストフード": 
  keyword: 
    - コンビニ ファーストフード
  weight: 1
"ライフ :: 生活お役立ち :: マナー・冠婚葬祭": 
  keyword: 
    - マナー 冠婚葬祭
  weight: 1
"ライフ :: 生活お役立ち :: リサイクル": 
  keyword: 
    - リサイクル
  weight: 1
"ライフ :: 生活お役立ち :: 季節の行事": 
  keyword: 
    - 季節の行事
  weight: 1
"ライフ :: 生活お役立ち :: 手紙・文例": 
  keyword: 
    - 手紙 文例
  weight: 1
"ライフ :: 生活お役立ち :: 掃除・洗濯・家事全般": 
  keyword: 
    - 掃除 洗濯 家事全般
  weight: 1
"ライフ :: 生活お役立ち :: 正月・年末年始": 
  keyword: 
    - 正月 年末年始
  weight: 1
"ライフ :: 生活お役立ち :: 生活お役立ち": 
  keyword: 
    - 生活お役立ち
  weight: 3
"ライフ :: 生活お役立ち :: 郵便・宅配": 
  keyword: 
    - 郵便 宅配
  weight: 1
"ライフ :: 生活お役立ち :: 防犯・セキュリティ": 
  keyword: 
    - 防犯 セキュリティ
  weight: 1
"ライフ :: 生活お役立ち :: 電気・ガス・水道": 
  keyword: 
    - 電気 ガス 水道
  weight: 1
"ライフ :: 結婚 :: ハネムーン・新生活": 
  keyword: 
    - ハネムーン 新生活
  weight: 1
"ライフ :: 結婚 :: 挙式・披露宴": 
  keyword: 
    - 挙式 披露宴
  weight: 1
"ライフ :: 結婚 :: 段取り・結婚準備": 
  keyword: 
    - 段取り 結婚準備
  weight: 1
"ライフ :: 結婚 :: 結婚": 
  keyword: 
    - 結婚
  weight: 3
"大規模災害 :: 東日本大震災情報 :: その他（東日本大震災）": 
  keyword: 
    - その他（東日本大震災）
  weight: 1
"大規模災害 :: 東日本大震災情報 :: 交通・運行情報": 
  keyword: 
    - 交通 運行情報
  weight: 1
"大規模災害 :: 東日本大震災情報 :: 募金・ボランティア・物資支援": 
  keyword: 
    - 募金 ボランティア 物資支援
  weight: 1
"大規模災害 :: 東日本大震災情報 :: 地震の知識": 
  keyword: 
    - 地震の知識
  weight: 1
"大規模災害 :: 東日本大震災情報 :: 外国の方からの相談": 
  keyword: 
    - 外国の方からの相談
  weight: 1
"大規模災害 :: 東日本大震災情報 :: 妊婦・出産・子供の相談": 
  keyword: 
    - 妊婦 出産 子供の相談
  weight: 1
"大規模災害 :: 東日本大震災情報 :: 安否確認：その他の地域": 
  keyword: 
    - 安否確認：その他の地域
  weight: 1
"大規模災害 :: 東日本大震災情報 :: 安否確認：北海道": 
  keyword: 
    - 安否確認：北海道
  weight: 1
"大規模災害 :: 東日本大震災情報 :: 安否確認：千葉": 
  keyword: 
    - 安否確認：千葉
  weight: 1
"大規模災害 :: 東日本大震災情報 :: 安否確認：宮城": 
  keyword: 
    - 安否確認：宮城
  weight: 1
"大規模災害 :: 東日本大震災情報 :: 安否確認：山形": 
  keyword: 
    - 安否確認：山形
  weight: 1
"大規模災害 :: 東日本大震災情報 :: 安否確認：岩手": 
  keyword: 
    - 安否確認：岩手
  weight: 1
"大規模災害 :: 東日本大震災情報 :: 安否確認：新潟": 
  keyword: 
    - 安否確認：新潟
  weight: 1
"大規模災害 :: 東日本大震災情報 :: 安否確認：栃木": 
  keyword: 
    - 安否確認：栃木
  weight: 1
"大規模災害 :: 東日本大震災情報 :: 安否確認：福島": 
  keyword: 
    - 安否確認：福島
  weight: 1
"大規模災害 :: 東日本大震災情報 :: 安否確認：秋田": 
  keyword: 
    - 安否確認：秋田
  weight: 1
"大規模災害 :: 東日本大震災情報 :: 安否確認：群馬": 
  keyword: 
    - 安否確認：群馬
  weight: 1
"大規模災害 :: 東日本大震災情報 :: 安否確認：茨城": 
  keyword: 
    - 安否確認：茨城
  weight: 1
"大規模災害 :: 東日本大震災情報 :: 安否確認：長野": 
  keyword: 
    - 安否確認：長野
  weight: 1
"大規模災害 :: 東日本大震災情報 :: 安否確認：青森": 
  keyword: 
    - 安否確認：青森
  weight: 1
"大規模災害 :: 東日本大震災情報 :: 応援メッセージ": 
  keyword: 
    - 応援メッセージ
  weight: 1
"大規模災害 :: 東日本大震災情報 :: 東日本大震災情報": 
  keyword: 
    - 東日本大震災情報
  weight: 3
"大規模災害 :: 東日本大震災情報 :: 災害対策": 
  keyword: 
    - 災害対策
  weight: 1
"大規模災害 :: 東日本大震災情報 :: 物資・支援情報：その他の地域": 
  keyword: 
    - 物資 支援情報：その他の地域
  weight: 1
"大規模災害 :: 東日本大震災情報 :: 物資・支援情報：北海道": 
  keyword: 
    - 物資 支援情報：北海道
  weight: 1
"大規模災害 :: 東日本大震災情報 :: 物資・支援情報：千葉": 
  keyword: 
    - 物資 支援情報：千葉
  weight: 1
"大規模災害 :: 東日本大震災情報 :: 物資・支援情報：宮城": 
  keyword: 
    - 物資 支援情報：宮城
  weight: 1
"大規模災害 :: 東日本大震災情報 :: 物資・支援情報：山形": 
  keyword: 
    - 物資 支援情報：山形
  weight: 1
"大規模災害 :: 東日本大震災情報 :: 物資・支援情報：岩手": 
  keyword: 
    - 物資 支援情報：岩手
  weight: 1
"大規模災害 :: 東日本大震災情報 :: 物資・支援情報：新潟": 
  keyword: 
    - 物資 支援情報：新潟
  weight: 1
"大規模災害 :: 東日本大震災情報 :: 物資・支援情報：栃木": 
  keyword: 
    - 物資 支援情報：栃木
  weight: 1
"大規模災害 :: 東日本大震災情報 :: 物資・支援情報：福島": 
  keyword: 
    - 物資 支援情報：福島
  weight: 1
"大規模災害 :: 東日本大震災情報 :: 物資・支援情報：秋田": 
  keyword: 
    - 物資 支援情報：秋田
  weight: 1
"大規模災害 :: 東日本大震災情報 :: 物資・支援情報：群馬": 
  keyword: 
    - 物資 支援情報：群馬
  weight: 1
"大規模災害 :: 東日本大震災情報 :: 物資・支援情報：茨城": 
  keyword: 
    - 物資 支援情報：茨城
  weight: 1
"大規模災害 :: 東日本大震災情報 :: 物資・支援情報：長野": 
  keyword: 
    - 物資 支援情報：長野
  weight: 1
"大規模災害 :: 東日本大震災情報 :: 物資・支援情報：青森": 
  keyword: 
    - 物資 支援情報：青森
  weight: 1
"大規模災害 :: 東日本大震災情報 :: 節電": 
  keyword: 
    - 節電
  weight: 1
"大規模災害 :: 東日本大震災情報 :: 避難所のくらし・工夫": 
  keyword: 
    - 避難所のくらし 工夫
  weight: 1
"学問＆教育 :: 中国語 :: 中国語": 
  keyword: 
    - 中国語
  weight: 3
"学問＆教育 :: 化学 :: 化学": 
  keyword: 
    - 化学
  weight: 3
"学問＆教育 :: 哲学 :: 哲学": 
  keyword: 
    - 哲学
  weight: 3
"学問＆教育 :: 国語 :: 国語": 
  keyword: 
    - 国語
  weight: 3
"学問＆教育 :: 地学 :: 地学": 
  keyword: 
    - 地学
  weight: 3
"学問＆教育 :: 地理 :: 地理": 
  keyword: 
    - 地理
  weight: 3
"学問＆教育 :: 外国語 :: 外国語": 
  keyword: 
    - 外国語
  weight: 3
"学問＆教育 :: 天文学 :: 天文学": 
  keyword: 
    - 天文学
  weight: 3
"学問＆教育 :: 学問＆教育 :: 学問＆教育": 
  keyword: 
    - 学問 教育
  weight: 3
"学問＆教育 :: 学校 :: イベント": 
  keyword: 
    - イベント
  weight: 1
"学問＆教育 :: 学校 :: 中学校": 
  keyword: 
    - 中学校
  weight: 1
"学問＆教育 :: 学校 :: 大学・短大": 
  keyword: 
    - 大学 短大
  weight: 1
"学問＆教育 :: 学校 :: 大学院": 
  keyword: 
    - 大学院
  weight: 1
"学問＆教育 :: 学校 :: 学校": 
  keyword: 
    - 学校
  weight: 3
"学問＆教育 :: 学校 :: 専門学校": 
  keyword: 
    - 専門学校
  weight: 1
"学問＆教育 :: 学校 :: 小学校": 
  keyword: 
    - 小学校
  weight: 1
"学問＆教育 :: 学校 :: 幼稚園・保育所": 
  keyword: 
    - 幼稚園 保育所
  weight: 1
"学問＆教育 :: 学校 :: 施設": 
  keyword: 
    - 施設
  weight: 1
"学問＆教育 :: 学校 :: 高校": 
  keyword: 
    - 高校
  weight: 1
"学問＆教育 :: 心理学 :: 心理学": 
  keyword: 
    - 心理学
  weight: 3
"学問＆教育 :: 数学 :: 数学": 
  keyword: 
    - 数学
  weight: 3
"学問＆教育 :: 文学 :: 文学": 
  keyword: 
    - 文学
  weight: 3
"学問＆教育 :: 歴史 :: 歴史": 
  keyword: 
    - 歴史
  weight: 3
"学問＆教育 :: 物理学 :: 物理学": 
  keyword: 
    - 物理学
  weight: 3
"学問＆教育 :: 環境学・エコロジー :: 環境学・エコロジー": 
  keyword: 
    - 環境学 エコロジー
  weight: 3
"学問＆教育 :: 生物学 :: 生物学": 
  keyword: 
    - 生物学
  weight: 3
"学問＆教育 :: 留学 :: 留学": 
  keyword: 
    - 留学
  weight: 3
"学問＆教育 :: 科学 :: 科学": 
  keyword: 
    - 科学
  weight: 3
"学問＆教育 :: 経済学 :: 経済学": 
  keyword: 
    - 経済学
  weight: 3
"学問＆教育 :: 美術 :: 美術": 
  keyword: 
    - 美術
  weight: 3
"学問＆教育 :: 考古学 :: 考古学": 
  keyword: 
    - 考古学
  weight: 3
"学問＆教育 :: 英語 :: 英語": 
  keyword: 
    - 英語
  weight: 3
"学問＆教育 :: 農学 :: 農学": 
  keyword: 
    - 農学
  weight: 3
"学問＆教育 :: 韓国語 :: 韓国語": 
  keyword: 
    - 韓国語
  weight: 3
"学問＆教育 :: 音楽 :: 音楽": 
  keyword: 
    - 音楽
  weight: 3
"旅行・レジャー :: 国内 :: 中国・四国": 
  keyword: 
    - 中国 四国
  weight: 1
"旅行・レジャー :: 国内 :: 九州・沖縄": 
  keyword: 
    - 九州 沖縄
  weight: 1
"旅行・レジャー :: 国内 :: 北海道": 
  keyword: 
    - 北海道
  weight: 1
"旅行・レジャー :: 国内 :: 国内": 
  keyword: 
    - 国内
  weight: 3
"旅行・レジャー :: 国内 :: 国内旅行(全国)": 
  keyword: 
    - 国内旅行(全国)
  weight: 1
"旅行・レジャー :: 国内 :: 東北": 
  keyword: 
    - 東北
  weight: 1
"旅行・レジャー :: 国内 :: 東海": 
  keyword: 
    - 東海
  weight: 1
"旅行・レジャー :: 国内 :: 甲信越・北陸": 
  keyword: 
    - 甲信越 北陸
  weight: 1
"旅行・レジャー :: 国内 :: 遊園地・テーマパーク(全国)": 
  keyword: 
    - 遊園地 テーマパーク(全国)
  weight: 1
"旅行・レジャー :: 国内 :: 関東": 
  keyword: 
    - 関東
  weight: 1
"旅行・レジャー :: 国内 :: 関西": 
  keyword: 
    - 関西
  weight: 1
"旅行・レジャー :: 国内 :: 食べ歩き(全国)": 
  keyword: 
    - 食べ歩き(全国)
  weight: 1
"旅行・レジャー :: 旅行・レジャー :: 旅行・レジャー": 
  keyword: 
    - 旅行 レジャー
  weight: 3
"旅行・レジャー :: 海外 :: アジア": 
  keyword: 
    - アジア
  weight: 1
"旅行・レジャー :: 海外 :: アフリカ": 
  keyword: 
    - アフリカ
  weight: 1
"旅行・レジャー :: 海外 :: オセアニア": 
  keyword: 
    - オセアニア
  weight: 1
"旅行・レジャー :: 海外 :: ヨーロッパ": 
  keyword: 
    - ヨーロッパ
  weight: 1
"旅行・レジャー :: 海外 :: 中南米・カリブ": 
  keyword: 
    - 中南米 カリブ
  weight: 1
"旅行・レジャー :: 海外 :: 中東": 
  keyword: 
    - 中東
  weight: 1
"旅行・レジャー :: 海外 :: 北アメリカ": 
  keyword: 
    - 北アメリカ
  weight: 1
"旅行・レジャー :: 海外 :: 海外": 
  keyword: 
    - 海外
  weight: 3
"旅行・レジャー :: 海外 :: 海外旅行(全般)": 
  keyword: 
    - 海外旅行(全般)
  weight: 1
"社会 :: エネルギー :: エコロジー": 
  keyword: 
    - エコロジー
  weight: 1
"社会 :: エネルギー :: エネルギー": 
  keyword: 
    - エネルギー
  weight: 3
"社会 :: エネルギー :: 電力発電": 
  keyword: 
    - 電力発電
  weight: 1
"社会 :: カルチャー :: カルチャー": 
  keyword: 
    - カルチャー
  weight: 3
"社会 :: カルチャー :: 伝統文化・行事": 
  keyword: 
    - 伝統文化 行事
  weight: 1
"社会 :: カルチャー :: 流行・カルチャー": 
  keyword: 
    - 流行 カルチャー
  weight: 1
"社会 :: ボランティア :: ボランティア": 
  keyword: 
    - ボランティア
  weight: 3
"社会 :: 医療 :: 医療": 
  keyword: 
    - 医療
  weight: 3
"社会 :: 政治 :: 政治": 
  keyword: 
    - 政治
  weight: 3
"社会 :: 法律 :: 法律": 
  keyword: 
    - 法律
  weight: 3
"社会 :: 社会 :: 社会": 
  keyword: 
    - 社会
  weight: 3
"社会 :: 社会問題 :: ニュース・時事問題": 
  keyword: 
    - ニュース 時事問題
  weight: 1
"社会 :: 社会問題 :: メディア・マスコミ": 
  keyword: 
    - メディア マスコミ
  weight: 1
"社会 :: 社会問題 :: 国際問題": 
  keyword: 
    - 国際問題
  weight: 1
"社会 :: 社会問題 :: 教育問題": 
  keyword: 
    - 教育問題
  weight: 1
"社会 :: 社会問題 :: 社会問題": 
  keyword: 
    - 社会問題
  weight: 3
"社会 :: 社会問題 :: 自然環境問題": 
  keyword: 
    - 自然環境問題
  weight: 1
"社会 :: 社会問題 :: 防災 ・災害": 
  keyword: 
    - 防災  災害
  weight: 1
"社会 :: 福祉 :: 介護": 
  keyword: 
    - 介護
  weight: 1
"社会 :: 福祉 :: 施設": 
  keyword: 
    - 施設
  weight: 1
"社会 :: 福祉 :: 福祉": 
  keyword: 
    - 福祉
  weight: 3
"社会 :: 経済 :: 経済": 
  keyword: 
    - 経済
  weight: 3
"社会 :: 行政 :: 行政": 
  keyword: 
    - 行政
  weight: 3
"美容＆健康 :: コスメティック :: コスメティック": 
  keyword: 
    - コスメティック
  weight: 3
"美容＆健康 :: スキンケア :: スキンケア": 
  keyword: 
    - スキンケア
  weight: 3
"美容＆健康 :: ダイエット＆フィットネス :: ダイエット＆フィットネス": 
  keyword: 
    - ダイエット フィットネス
  weight: 3
"美容＆健康 :: デンタルケア :: デンタルケア": 
  keyword: 
    - デンタルケア
  weight: 3
"美容＆健康 :: ファッション :: キッズ": 
  keyword: 
    - キッズ
  weight: 1
"美容＆健康 :: ファッション :: ファッション": 
  keyword: 
    - ファッション
  weight: 3
"美容＆健康 :: ファッション :: メンズ": 
  keyword: 
    - メンズ
  weight: 1
"美容＆健康 :: ファッション :: レディース": 
  keyword: 
    - レディース
  weight: 1
"美容＆健康 :: ファッション :: 着物・和服": 
  keyword: 
    - 着物 和服
  weight: 1
"美容＆健康 :: ヘアケア・ヘアスタイル :: ヘアケア・ヘアスタイル": 
  keyword: 
    - ヘアケア ヘアスタイル
  weight: 3
"美容＆健康 :: 健康 :: アレルギー・花粉症": 
  keyword: 
    - アレルギー 花粉症
  weight: 1
"美容＆健康 :: 健康 :: インフルエンザ": 
  keyword: 
    - インフルエンザ
  weight: 1
"美容＆健康 :: 健康 :: ヘルスケア(健康管理)": 
  keyword: 
    - ヘルスケア(健康管理)
  weight: 1
"美容＆健康 :: 健康 :: メンタルヘルス": 
  keyword: 
    - メンタルヘルス
  weight: 1
"美容＆健康 :: 健康 :: 健康": 
  keyword: 
    - 健康
  weight: 3
"美容＆健康 :: 健康 :: 女性の病気": 
  keyword: 
    - 女性の病気
  weight: 1
"美容＆健康 :: 健康 :: 性の悩み": 
  keyword: 
    - 性の悩み
  weight: 1
"美容＆健康 :: 健康 :: 栄養": 
  keyword: 
    - 栄養
  weight: 1
"美容＆健康 :: 健康 :: 病気": 
  keyword: 
    - 病気
  weight: 1
"美容＆健康 :: 健康 :: 病院": 
  keyword: 
    - 病院
  weight: 1
"美容＆健康 :: 健康 :: 癌": 
  keyword: 
    - 癌
  weight: 1
"美容＆健康 :: 健康 :: 禁煙・禁酒": 
  keyword: 
    - 禁煙 禁酒
  weight: 1
"美容＆健康 :: 健康 :: 薄毛・抜け毛": 
  keyword: 
    - 薄毛 抜け毛
  weight: 1
"美容＆健康 :: 美容＆健康 :: 美容＆健康": 
  keyword: 
    - 美容 健康
  weight: 3
"趣味 :: AV機器 :: AV機器": 
  keyword: 
    - AV機器
  weight: 3
"趣味 :: AV機器 :: Bluray・DVDプレーヤー": 
  keyword: 
    - Bluray DVDプレーヤー
  weight: 1
"趣味 :: AV機器 :: iPod・携帯音楽プレーヤー": 
  keyword: 
    - iPod 携帯音楽プレーヤー
  weight: 1
"趣味 :: AV機器 :: オーディオ": 
  keyword: 
    - オーディオ
  weight: 1
"趣味 :: AV機器 :: カメラ全般": 
  keyword: 
    - カメラ全般
  weight: 1
"趣味 :: AV機器 :: テレビ・レコーダー": 
  keyword: 
    - テレビ レコーダー
  weight: 1
"趣味 :: アウトドア :: BBQ・アウトドア料理": 
  keyword: 
    - BBQ アウトドア料理
  weight: 1
"趣味 :: アウトドア :: アウトドア": 
  keyword: 
    - アウトドア
  weight: 3
"趣味 :: アウトドア :: フィッシング": 
  keyword: 
    - フィッシング
  weight: 1
"趣味 :: アウトドア :: 登山・キャンプ": 
  keyword: 
    - 登山 キャンプ
  weight: 1
"趣味 :: アウトドア :: 鉄道＆路線": 
  keyword: 
    - 鉄道 路線
  weight: 1
"趣味 :: ラジコン・模型・フィギュア :: ラジコン・模型・フィギュア": 
  keyword: 
    - ラジコン 模型 フィギュア
  weight: 3
"趣味 :: 占い :: 占い": 
  keyword: 
    - 占い
  weight: 3
"趣味 :: 芸術・アート :: 手芸・ホビークラフト": 
  keyword: 
    - 手芸 ホビークラフト
  weight: 1
"趣味 :: 芸術・アート :: 書道": 
  keyword: 
    - 書道
  weight: 1
"趣味 :: 芸術・アート :: 絵画・写真・オブジェ": 
  keyword: 
    - 絵画 写真 オブジェ
  weight: 1
"趣味 :: 芸術・アート :: 芸術・アート": 
  keyword: 
    - 芸術 アート
  weight: 3
"趣味 :: 芸術・アート :: 茶道・華道": 
  keyword: 
    - 茶道 華道
  weight: 1
"趣味 :: 読書 :: コミック": 
  keyword: 
    - コミック
  weight: 1
"趣味 :: 読書 :: 書籍・文庫": 
  keyword: 
    - 書籍 文庫
  weight: 1
"趣味 :: 読書 :: 画集・写真集": 
  keyword: 
    - 画集 写真集
  weight: 1
"趣味 :: 読書 :: 絵本・子供の本": 
  keyword: 
    - 絵本 子供の本
  weight: 1
"趣味 :: 読書 :: 読書": 
  keyword: 
    - 読書
  weight: 3
"趣味 :: 読書 :: 雑誌": 
  keyword: 
    - 雑誌
  weight: 1
"趣味 :: 趣味 :: 趣味": 
  keyword: 
    - 趣味
  weight: 3
"趣味 :: 車 :: バイク": 
  keyword: 
    - バイク
  weight: 1
"趣味 :: 車 :: 中古車売買": 
  keyword: 
    - 中古車売買
  weight: 1
"趣味 :: 車 :: 国産車": 
  keyword: 
    - 国産車
  weight: 1
"趣味 :: 車 :: 自転車・マウンテンバイク": 
  keyword: 
    - 自転車 マウンテンバイク
  weight: 1
"趣味 :: 車 :: 車": 
  keyword: 
    - 車
  weight: 3
"趣味 :: 車 :: 輸入車": 
  keyword: 
    - 輸入車
  weight: 1

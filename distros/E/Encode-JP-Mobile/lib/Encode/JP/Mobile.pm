package Encode::JP::Mobile;
use strict;
our $VERSION = "0.30";

use Carp;
use Encode;
use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

use base qw( Exporter );
our @EXPORT_OK = qw( InDoCoMoPictograms InKDDIPictograms InSoftBankPictograms InAirEdgePictograms InMobileJPPictograms InKDDISoftBankConflicts InKDDICP932Pictograms InKDDIAutoPictograms);
our %EXPORT_TAGS = ( props => [@EXPORT_OK] );

use Encode::Alias;

# sjis-raw
define_alias( 'x-sjis-imode-raw'         => 'x-sjis-docomo-raw' );
define_alias( 'x-sjis-airedge-raw'       => 'x-sjis-airh-raw' );
define_alias( 'x-sjis-vodafone-auto-raw' => 'x-sjis-softbank-auto-raw' );

define_alias( 'x-sjis-kddi'              => 'x-sjis-kddi-cp932-raw' );
define_alias( 'x-sjis-ezweb'             => 'x-sjis-kddi-cp932-raw' );
define_alias( 'x-sjis-ezweb-cp932-raw'   => 'x-sjis-kddi-cp932-raw' );
define_alias( 'x-sjis-ezweb-auto-raw'    => 'x-sjis-kddi-auto-raw' );

# backward compatiblity
define_alias('shift_jis-kddi'       => 'x-sjis-kddi-cp932-raw');

# utf8
define_alias( 'x-utf8-imode'    => 'x-utf8-docomo' );
define_alias( 'x-utf8-ezweb'    => 'x-utf8-kddi' );
define_alias( 'x-utf8-vodafone' => 'x-utf8-softbank' );

use Encode::JP::Mobile::Vodafone;
use Encode::JP::Mobile::KDDIJIS;
use Encode::JP::Mobile::AirHJIS;
use Encode::JP::Mobile::ConvertPictogramSJIS;

use Encode::JP::Mobile::MIME::DoCoMo;
use Encode::JP::Mobile::MIME::KDDI;
use Encode::JP::Mobile::MIME::SoftBank;
use Encode::JP::Mobile::MIME::AirH;

require Encode::JP::Mobile::Fallback;
require Encode::JP::Mobile::Character;

use Encode::MIME::Name;

for (Encode->encodings('JP::Mobile')) {
    next if defined $Encode::MIME::Name::MIME_NAME_OF{$_};
    my $mime_name = $_ =~ /utf8/i ? 'UTF-8'
                  : $_ =~ /sjis/i ? 'Shift_JIS'
                  : $_ =~ /2022/i ? 'ISO-2022-JP'
                  : undef;
    $Encode::MIME::Name::MIME_NAME_OF{$_} = $mime_name if $mime_name;
}

sub InDoCoMoPictograms {
    return <<END;
E63E\tE6A5
E6AC\tE6AE
E6B1\tE6B3
E6B7\tE6BA
E6CE\tE757
END
}

sub InKDDICP932Pictograms {
    return <<END;
E468\tE5DF
EA80\tEB88
END
}

sub InKDDIAutoPictograms {
    return <<END;
EC40\tEC7E
EC80\tECFC
ED40\tED7E
ED80\tED8D
EF40\tEF7E
EF80\tEFFC
F040\tF07E
F080\tF0FC
END
}

sub InKDDIPictograms {
    return join "\n", InKDDICP932Pictograms(), InKDDIAutoPictograms();
}

sub InSoftBankPictograms {
    return <<END;
E001\tE05A
E101\tE15A
E201\tE253
E255\tE257
E301\tE34D
E401\tE44C
E501\tE537
END
}

sub InAirEdgePictograms {
    return <<END;
E000\tE096
E098
E09A
E09F
E0A2
E0A6
E0A8
E0AF
E0BB
E0C4
E0C9
END
}

sub InMobileJPPictograms {
    # +utf8::InDoCoMoPictograms etc. don't work here
    return join "\n", InDoCoMoPictograms, InKDDIPictograms, InSoftBankPictograms, InAirEdgePictograms;
}

sub InKDDISoftBankConflicts {
    return <<END;
E501\tE537
END
}

1;
__END__

=encoding utf-8

=head1 NAME

Encode::JP::Mobile - 日本の携帯電話向け Shift_JIS (CP932) / UTF-8 エンコーディング

=head1 SYNOPSIS

  use Encode;
  use Encode::JP::Mobile;

  my $bytes = "\x82\xb1\xf9\x5d\xf8\xa0\x82\xb1"; # NTT DoCoMo 絵文字を含んだ Shift_JIS バイト列
  my $chars = decode("x-sjis-imode", $bytes);     # \x{3053}\x{e6b9}\x{e63f}\x{3053}

  use Encode::JP::Mobile ':props';
  if ($chars =~ /\p{InDoCoMoPictograms}/) {
      warn "It has DoCoMo pictogram characters!";
  }

=head1 DESCRIPTION

Encode::JP::Mobile は Encode 用の拡張モジュールで、日本の携帯電話用絵文字を Unicode の私用領域 (PRIVATE AREA) にマッピングします。

このモジュールの実装は B<EXPERIMENTAL> です。APIや実装は将来のバージョンで変更される可能性があります。

=head1 ENCODINGS

このモジュールは以下のエンコーディングをサポートしています。

=over 4

=item x-sjis-imode

NTT DoCoMo の i-mode 端末用のマッピング。絵文字は Shift_JIS の私用領域でエンコードされ、Unicode の私用領域にマッピングされます。この際の変換ルールは CP932 と同様です。

例えば、C<U+E64E> は I<晴れ> の絵文字で、このエンコーディングでは C<\xF8\X9F> にエンコードされます。

このエンコーディングは CP932 の完全なサブセットです。現状のバージョンでは、(x-sjis-kddi-autoでdecodeした)KDDI/AU の絵文字および SoftBank の絵文字をマップした Unicode 私用領域からDoCoMo 絵文字へのマッピングもサポートしています。例えば、

  my $kddi  = "\xf6\x59"; # KDDI/AU の SJIS で [!]
  my $char  = decode("x-sjis-kddi-auto-raw", $bytes); # \x{EF59}
  my $imode = encode("x-sjis-imode", $char); # \xf9\xdc -- DoCoMo の SJIS で [!]

のように相互変換されます。

I<x-sjis-docomo> をエイリアスとして利用できます。

=item x-sjis-softbank

SoftBank 絵文字をエンコードするためのエスケープシーケンスがベースの Shift_JIS エンコーディングです。エンコード・デコードのアルゴリズムは UCM ファイルではなく、Perl コードで実装されています。

I<x-sjis-vodafone> をエイリアスとして利用できます。

例えば、C<U+E001> は I<男の子> の絵文字で、このエンコーディングでは C<\x1b$G!\x0f> のようにエンコードされます。(C<\x1b> がエスケープシーケンス開始、C<\x0f> が終了を示す）

DoCoMo および (x-sjis-kddi-autoでdecodeした)KDDI/AU の絵文字は適切な SoftBank 絵文字にマッピングされます。

=item x-sjis-softbank-auto

Unicode 私用領域にマップされた SoftBank 絵文字と Shift_JIS 私用領域（外字）をマッピングします。このエンコーディングは 3GC 端末を利用して Shift_JIS でエンコードされた Web フォームに絵文字を入力し、サブミットしたときに送信されるエンコードです。実機端末では HTML 内にこのエンコーディングでエンコードした絵文字をデコードして表示できることが確認されています。

I<x-sjis-vodafone-auto> をエイリアスとして利用できます。

Shift_JIS 私用領域のマッピングは CP932 に似ていますが、若干ずれている場所があります。

例えば、 C<U+E001> は I<男の子> 絵文字 (I<x-sjis-softbank> と同様) で、このエンコーディングでは I<\xF9\x41> とエンコードされます。

DoCoMo および KDDI/AU の絵文字は適切な SoftBank 絵文字にマッピングされます。

=item x-sjis-kddi-cp932-raw

KDDI/AU 絵文字のマッピング。（おそらく）CP932 をベースにしていますが、CP932.TXT には含まれない私用領域文字を多く含んでいます。

例えば、I<U+E481> は I<!> （ビックリマーク）絵文字で、このエンコーディングでは I<\xF6\x59> のようにエンコードされ、これは CP932 と同様です。 I<U+EB88> は I<怒る> 絵文字で、I<\xF4\x8D> のようにエンコードされますが、CP932 はこの文字に対するマッピングを含んでいません。

このエンコーディングに含まれる一部の絵文字は、SoftBank の私用領域と重複しています。

このエンコーディングでは、絵文字の相互変換がおこなわれないことに注意してください。これは、KDDI-CP932 の Unicode の領域が SoftBank の絵文字領域と重複しているため、ただしく相互変換することができないためです。絵文字相互変換機能を利用したい場合には x-sjis-kddi-auto を使用してください。

I<x-sjis-ezweb> をエイリアスとして利用できます。

=item x-sjis-kddi-auto

KDDI/AU 絵文字のマッピングで、端末内部の Shift_JIS - UTF-8 間の変換表を元にしています。

KDDI端末から、UTF-8 ページ内の Web フォームに絵文字を入力して送信した場合、x-sjis-kddi でマップされる Unicode 私用領域 (CP932 ベース) とは異なる領域（通称 裏KDDI Unicode）が利用されます。x-sjis-kddi-auto は、この領域と、KDDI 端末の Shift_JIS 外字バイト列とをマッピングしたものです。

現状のバージョンでは、DoCoMo の絵文字をマップした Unicode 私用領域から KDDI/AU 絵文字、SoftBank 絵文字へのマッピングもサポートしています。

C<x-sjis-ezweb-auto> をエイリアスとして利用できます。

=item x-iso-2022-jp-kddi

KDDI/AU の絵文字を Email 内で利用する際のエンコーディング。日本語でメールを送信する際、依然としてデファクトスタンダードである I<iso-2022-jp> をベースにしています。

実際には、ほとんどの KDDI/AU 携帯電話端末は Shift_JIS でエンコードされた Email を受信することができるため、I<x-sjis-kddi> （または -auto）を利用してメールを送信すれば問題はないでしょう。このエンコーディングは携帯端末から送られた絵文字を含むメールを受信し、デコードする際に必要になります。

C<x-iso-2022-jp-ezweb> をエイリアスとして利用できます。

=item x-iso-2022-jp-kddi-auto

I<x-iso-2022-jp-kddi> と同様ですが、絵文字を KDDI-Auto の Unicode 領域にデコードします。

=item x-sjis-airedge

AirEDGE の絵文字をマッピングします。cp932 の完全なサブセットで、I<x-sjis-airh> をエイリアスとして利用できます。

AirEDGE 独自の文字コードでは、絵文字は E000 - E0C9 にマップされ、CP932 と同様のエンコーディングですが、実際にはこのエンコーディングを利用することはまずないと思われます。AirEDGE 端末から「ウェブ用絵文字」を利用して送信したデータは、DoCoMo 用絵文字と同様のエンコーディングで送信され、CP932 互換のマッピングで DoCoMo 用絵文字のコードポイントにマッピングされます。また、AirEDGE 独自の絵文字私用領域は SoftBank の私用領域とも重複しており、相互変換の上でも問題があります。

I<x-sjis-airedge> は I<x-sjis-docomo> の別名、として考えておくとよいでしょう。

SoftBank および KDDI/AU の絵文字は適切な DoCoMo 絵文字(ウェブ入力用絵文字)にマッピングされます。

=item x-iso-2022-jp-airh

AirEDGE から送られる絵文字入りのメールを変換するためのエンコーディングです。

AirEDGE から送られるメールは通常のメールと同様に I<iso-2022-jp> がベースとなっていますが、絵文字部分のみ I<x-sjis-docomo-raw> という独自仕様になっており、これはその混在したメールを変換するためのエンコーディングになります。

C<x-iso-2022-jp-airedge>をエイリアスとして利用できます。

=item x-utf8-docomo, x-utf8-softbank, x-utf8-kddi

これらのエンコーディングは、Unicode 私用領域にある各キャリアの絵文字を相互変換しながら UTF-8 互換のエンコーディングにエンコードするのに使用します。utf-8 という名前がついていますが、実際にはすべての Unicode 文字をエンコードするわけではなく、サブセットとして、

  cp932 + x-sjis-{キャリア} + (他キャリアからのマッピング)

に含まれる文字セットをエンコードし、他キャリアの分は自動で自キャリアの対応する絵文字に変換します。

例えば、

  # UTF-8 で KDDI の "晴れ" 絵文字
  my $bytes = "\xEE\xBD\xA0";
  Encode::from_to($bytes, "utf-8" => "x-utf8-docomo");
  # $bytes は DoCoMo の "晴れ" 絵文字を UTF-8 でエンコードしたもの

これらのエンコードは基本的にラウンドトリップ可能ですが、UTF-8のサブセットであるため、CP932 および携帯絵文字以外の文字をエンコード・デコードすることはできません。また、各キャリア間で変換不可能な文字についても対応するマッピングが存在しない場合がありますので、L<Encode::JP::Mobile::FB_CHARACTER> や カスタムコールバックなどを利用して代替文字を表示する必要があります。

I<x-utf8-airh>, I<x-utf8-airedge> は存在しません。Willcom 端末は utf8 でページを表示している場合には絵文字の表示ができないようです。詳しくは L<http://mobilehacker.g.hatena.ne.jp/tokuhirom/20080118/1200637282> を参照。Willcom 端末で絵文字を表示させたい場合には I<x-sjis-airh>, I<x-sjis-airedge> をご利用ください。

=item x-sjis-docomo-raw, x-sjis-softbank-raw, x-sjis-softbank-auto-raw, x-sjis-kddi-cp932-raw, x-sjis-kddi-auto-raw, x-sjis-airh-raw

x-sjis-* のエンコーディングには -raw suffix がついたバージョンのエンコーディングも用意されています。

これは、FALLBACK によって文字コードを判定するような用途を想定しています。

x-utf8-*-raw が用意されていないのは、utf-8 エンコーディングがそれにあたるからです。

=item MIME-Header-JP-Mobile-DoCoMo, MIME-Header-JP-Mobile-DoCoMo-SJIS, MIME-Header-JP-Mobile-KDDI, MIME-Header-JP-Mobile-KDDI-SJIS, MIME-Header-JP-Mobile-SoftBank, MIME-Header-JP-Mobile-SoftBank-UTF8, MIME-Header-JP-Mobile-SoftBank-SJIS, MIME-Header-JP-Mobile-AirH, MIME-Header-JP-Mobile-AirH-SJIS

これらはメールの件名などで利用する MIME エンコーディング用です。詳細は L<Encode::JP::Mobile::MIME> をご覧下さい。

=back

=head1 UNICODE PROPERTIES

モジュールを ':props' フラグつきで import すると、以下のUnicode プロパティが利用できるようになります。

=over 4

=item * InMobileJPPictograms

Encode::JP::Mobile であつかうすべての絵文字にマッチします。

=item * InDoCoMoPictograms

=item * InKDDIPictograms

=item * InSoftBankPictograms

=item * InAirEdgePictograms

これらはそれぞれそのキャリアの表示できる絵文字にマッチします。

=item * InKDDICP932Pictograms

=item * InKDDIAutoPictograms

I<InKDDICP932Pictograms>, I<InKDDIAutoPictograms> はそれぞれ、I<x-sjis-kddi>, I<x-sjis-kddi-auto> のマッピングによって得られる Unicode 私用領域のレンジをあらわし、I<InKDDIPictograms> はその双方を含みます。

=item * InKDDISoftBankConflicts

SoftBank と KDDI (x-sjis-kddi を利用した場合) の Unicode 私用領域の重複する文字列を含んでいます。

=back

=head1 BACKWARD COMPATIBLITY

バージョン 0.07 から、モジュールで利用するエンコーディング名を I<x-sjis-*> のように変更しました。以前の I<shift_jis-*> というエイリアスも残してありますが、将来のリリースで削除される予定です。

バージョン 0.25 から、x-sjis-kddi-cp932-raw(旧称 x-sjis-kddi)は DoCoMo との絵文字相互変換をおこなわなくなりました。

=head1 AUTHORS

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt> with contributions from:

Tokuhiro Matsuno

Naoki Tomita

Masahiro Chiba

=head1 LICENSE

This library is free software, licensed under the same terms with Perl.

=head1 SEE ALSO

L<Encode>, L<HTML::Entities::ImodePictogram>, L<Unicode::Japanese>

L<http://coderepos.org/share/wiki/Mobile/Encoding>
L<http://www.nttdocomo.co.jp/service/imode/make/content/pictograph/basic/>
L<http://www.nttdocomo.co.jp/service/imode/make/content/pictograph/extention/>
L<http://www.au.kddi.com/ezfactory/tec/spec/3.html>
L<http://developers.softbankmobile.co.jp/dp/tool_dl/web/picword_top.php>
L<http://www.willcom-inc.com/ja/service/contents_service/club_air_edge/for_phone/homepage/index.html>
L<http://www.nttdocomo.co.jp/service/mail/imode_mail/emoji_convert/>
L<http://www.nttdocomo.co.jp/binary/pdf/service/mail/imode_mail/emoji_convert/pictogram.pdf>
L<http://broadband.mb.softbank.jp/service/3G/mail/pictogram/convert.pdf>

=cut

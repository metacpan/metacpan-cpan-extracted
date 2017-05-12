package Email::Address::JP::Mobile;
use strict;
use warnings;
use 5.008000;
our $VERSION = '0.08';
use Email::Address::Loose;

sub _carriers { qw(
    DoCoMo
    EZweb
    AirH
    SoftBank
    NonMobile
) }

BEGIN {
    for (_carriers) {
        eval "use Email::Address::JP::Mobile::$_;"; ## no critic
        die $@ if $@;
    }
};

sub new {
    my ($class, $address) = @_;
    my ($email) = Email::Address::Loose->parse($address);
    return unless $email;
     
    my ($carrier) =
        grep { $_->matches($email) }
            map { "Email::Address::JP::Mobile::$_" }
                _carriers;

    $carrier->new;
}

sub Email::Address::carrier {
    __PACKAGE__->new(shift->address);
}

1;
__END__

=encoding utf-8

=head1 NAME

Email::Address::JP::Mobile - Japanese carrier email class

=head1 SYNOPSIS
  
  use Email::Address::JP::Mobile;
  
  my $carrier = Email::Address::JP::Mobile->new('docomo.taro.@docomo.ne.jp');
  $carrier->is_mobile;      # => true
  $carrier->name;           # => "DoCoMo"
  $carrier->carrier_letter; # => "I"
  
  $body    = $carrier->send_encoding->encode($body);
  $subject = $carrier->mime_encoding->encode($subject);

or, via Email::Address object

  use Email::Address;
  use Email::Address::Loose -override;
  use Email::Address::JP::Mobile;
  
  my ($email) = Email::Address->parse('docomo.taro.@docomo.ne.jp');
  my $carrier = $email->carrier;
  $carrier->is_mobile; # => true

=head1 DESCRIPTION

Email::Address::JP::Mobile is for Japanese web developers.

このモジュールは要するに L<HTTP::MobileAgent> のメール版です。
メールアドレスから、それがどのキャリアで発行されたメールアドレスかを判別します。

同様のことができるモジュールに L<Mail::Address::MobileJp> があります。
Email::Address::JP::Mobile は L<Email::Address> オブジェクトを拡張する点や、
C<is_mobile($email)> ではなく C<< $carrier->is_mobile() >> というインターフェースである点が違います。

=head1 USAGE

=over 4

=item $carrier = Email::Address::JP::Mobile->new( $address )

メールアドレスから、Email::Address::JP::Mobile::* の対応したクラスを返します。

  my $carrier = Email::Address::JP::Mobile->new('docomo.taro.@docomo.ne.jp');
  # $carrier is a Email::Address::JP::Mobile::DoCoMo
  $carrier->is_mobile;      # => true
  $carrier->name;           # => "DoCoMo"
  $carrier->carrier_letter; # => "I"

携帯のメールアドレスではないと判断した場合は Email::Address::JP::Mobile::NonMobile クラスを返します。

=item $carrier = $email->carrier()

Email::Address::JP::Mobile は L<Email::Address> オブジェクトに、対応したクラスを返す
C<carrier()> というメソッドを拡張します。

  use Email::Address;
  use Email::Address::Loose -override;
  use Email::Address::JP::Mobile;
  my ($email) = Email::Address->parse('docomo.taro@docomo.ne.jp');
  $email->carrier->carrier_letter; # "I"

ご存知のように日本の携帯は変なアドレスが許可されている期間が長かったので、
携帯アドレスをパースする可能性があるのであれば L<Email::Address::Loose> を
併用した方がよいです。

=back

=head1 CARRIER CLASS METHODS

=over 4

=item $carrier->is_mobile()

=item $carrier->name()

=item $carrier->carrier_letter()

各メソッドが返す値は以下のとおりです。

             is_mobile  name         carrier_letter
  -------------------------------------------------
  DoCoMo     true       "DoCoMo"     "I"
  au         true       "EZweb"      "E"
  SoftBank   true       "SoftBank"   "V"
  WILLCOM    true       "AirH"       "H"
  NonMobile  false      "NonMobile"  "N"

C<carrier_letter()> が返す値は L<HTTP::MobileAgent> の C<carrier()> が返す値と同じです。ただし、このモジュールが返す C<name()> の値は L<HTTP::MobileAgent> の C<carrier_longname()> が返す値とは少し異なりますので注意してください。

=item $carrier->mime_encoding()

  $subject = $carrier->mime_encoding->encode($subject);
  $subject = $carrier->mime_encoding->decode($subject);

そのキャリア向けにメールを送信する際、絵文字を含んだ Subject を MIME encode するためのエンコーディングを返します。何を返すかは L</ENCODINGS> を参照してください。

携帯の場合は、そのキャリアの端末から受信したメールの Subject を MIME decode するためにも利用できます。ただし DoCoMo や SoftBank からの場合絵文字は最初からゲタになっているため取れないでしょう。

NonMobile の場合には C<MIME-Header-ISO_2022_JP> エンコーディングを返しますが、これは現状 decode に対応していません。代わりに C<MIME-Header> というエンコーディングで decode する必要があるので注意してください。

=item $carrier->send_encoding()

  $body = $carrier->send_encoding->encode($body);

そのキャリア向けにメールを送信する際、絵文字を含んだメール本文を encode するためのエンコーディングを返します。何を返すかは L</ENCODINGS> を参照してください。

=item $carrier->parse_encoding()

  $body = $carrier->parse_encoding->decode($body);

そのキャリアから受信したメールの絵文字を含んだメール本文を decode するためのエンコーディングを返します。が、これはメール本文の C<Content-Type> をチェックしているわけではなく、そのキャリアの場合このエンコーディングで送ってくるだろうというものを返しているだけである点に留意してください。また、DoCoMo や SoftBank からの場合絵文字は最初からゲタになり取れないため、C<iso-2022-jp> を返します。

そのため、受信の場合は絵文字のことは忘れて L<Email::MIME> の C<header()> や C<body_str()> を使って decode すると良いでしょう。

=back

=head2 ENCODINGS

上記の各メソッドが返すエンコーディングは以下のとおりです。（返すのは文字列ではなく L<Encode::Encoding> です）

             mime_encoding                   send_encoding     parse_encoding
  ------------------------------------------------------------------------------------
  DoCoMo     MIME-Header-JP-Mobile-DoCoMo    x-sjis-docomo     iso-2022-jp
  au         MIME-Header-JP-Mobile-KDDI      x-sjis-kddi-auto  x-iso-2022-jp-kddi-auto
  SoftBank   MIME-Header-JP-Mobile-SoftBank  x-utf8-softbank   iso-2022-jp
  WILLCOM    MIME-Header-JP-Mobile-AirH      x-sjis-airh       x-iso-2022-jp-airh
  NonMobile  MIME-Header-ISO_2022_JP         iso-2022-jp       iso-2022-jp

MIME-Header-JP-Mobile-* や x-* のエンコーディングは L<Encode::JP::Mobile> が提供するエンコーディングです。

=over 4

=item $Email::Address::JP::Mobile::NonMobile::Encoding

  local $Email::Address::JP::Mobile::NonMobile::Encoding = 'utf-8';

  my $carrier = Email::Address::JP::Mobile->new('tomita@example.com');
  $carrier->mime_encoding;  # MIME-Header encoding
  $carrier->send_encoding;  # utf-8 encoding
  $carrier->parse_encoding; # utf-8 encoding

NonMobile の場合のデフォルトエンコーディングは C<iso-2022-jp> ですが、この変数で C<utf-8> を指定すると上記のようなエンコーディングを返します。

=back

=head1 SEE ALSO

L<http://coderepos.org/share/wiki/Mobile/Encoding>

L<Email::Address::Loose>, L<Encode::JP::Mobile>

L<Email::MIME::MobileJP> - 具体的な利用例

#mobilejp on irc.freenode.net (I've joined as "tomi-ru")

=head1 AUTHOR

Naoki Tomita E<lt>tomita@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

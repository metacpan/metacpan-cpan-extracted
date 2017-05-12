package Encode::JP::Mobile::MIME;
use strict;
use warnings;
use base 'Encode::Encoding';

use Encode ();
use Encode::JP::Mobile;
use MIME::Words;

sub subject_encoding {
    Encode::find_encoding('utf-8');
}

sub charset_to_encoding {
    my ($self, $charset) = @_;
    Encode::find_encoding($charset);
}

sub encode($$;$){
    my ($self, $str, $check) = @_;
    my $encoding = $self->subject_encoding
        or die "encoding is not found.";
   
    $str = $encoding->encode($str, $check);
    $str = MIME::Words::encode_mimeword($str, 'B', $encoding->mime_name);
    return $str;
}

sub decode($$;$){
    my ($self, $str, $check) = @_;
    
    my $ret = "";
    for my $part (MIME::Words::decode_mimewords($str)) {
        my ($bytes, $charset) = @$part;
        my $encoding = $self->charset_to_encoding($charset)
            or die "encoding is not found for $charset.";
        
        $ret .= $encoding->decode($bytes, $check);
    }
    
    return $ret;
}

1;
__END__

=encoding utf-8

=head1 NAME

Encode::JP::Mobile::MIME - 絵文字を含んだメールのSubject用MIMEエンコーディング

=head1 SYNOPSIS

  Encode::decode('MIME-Header-JP-Mobile-DoCoMo', $email->header('subject'));
  Encode::encode('MIME-Header-JP-Mobile-DoCoMo', "\x{E63E}です");        # =?SHIFT_JIS?B?+J+CxYK3?=
  Encode::encode('MIME-Header-JP-Mobile-DoCoMo-SJIS', "\x{E63E}です");   # =?SHIFT_JIS?B?+J+CxYK3?=
  
  Encode::decode('MIME-Header-JP-Mobile-KDDI', $email->header('subject'));
  Encode::encode('MIME-Header-JP-Mobile-KDDI', "\x{E63E}です");          # "\xF6\x60\x82\xC5\x82\xB7"
  Encode::encode('MIME-Header-JP-Mobile-KDDI-SJIS', "\x{E63E}です");     # "\xF6\x60\x82\xC5\x82\xB7"
  
  Encode::decode('MIME-Header-JP-Mobile-SoftBank', $email->header('subject'));
  Encode::encode('MIME-Header-JP-Mobile-SoftBank', "\x{E63E}です");      # =?UTF-8?B?7oGK44Gn44GZ?=
  Encode::encode('MIME-Header-JP-Mobile-SoftBank-UTF8', "\x{E63E}です"); # =?UTF-8?B?7oGK44Gn44GZ?=
  Encode::encode('MIME-Header-JP-Mobile-SoftBank-SJIS', "\x{E63E}です"); # =?SHIFT_JIS?B?GyRHag+CxYK3?=
  
  Encode::decode('MIME-Header-JP-Mobile-AirH', $email->header('subject'));
  Encode::encode('MIME-Header-JP-Mobile-AirH', "\x{E63E}です");          # =?SHIFT_JIS?B?+J+CxYK3?=
  Encode::encode('MIME-Header-JP-Mobile-AirH-SJIS', "\x{E63E}です");     # =?SHIFT_JIS?B?+J+CxYK3?=

=head1 ENCODINGS

=over 4

=item DoCoMo 向け

=over 4

=item MIME-Header-JP-Mobile-DoCoMo, MIME-Header-JP-Mobile-iMode

次項の C<MIME-Header-JP-Mobile-DoCoMo-SJIS> へのエイリアスです。

=item MIME-Header-JP-Mobile-DoCoMo-SJIS, MIME-Header-JP-Mobile-iMode-SJIS

decode は shift_jis の場合 C<x-sjis-docomo> を利用し絵文字をマッピングします。
が、現在実際のところ（gmail.com などの特別な場合を除き）絵文字はゲタとなって
送られてくるので、このエンコーディングで絵文字を取ることはできないでしょう。

encode は C<x-sjis-docomo> で encode してから MIME エンコードします。

=back

=item KDDI 向け

=over 4

=item MIME-Header-JP-Mobile-KDDI, MIME-Header-JP-Mobile-EZweb

C<MIME-Header-JP-Mobile-KDDI-SJIS> へのエイリアスです。

=item MIME-Header-JP-Mobile-KDDI-SJIS, MIME-Header-JP-Mobile-EZweb-SJIS

decode は iso-2022-jp や shift_jis の場合 C<x-iso-2022-jp-kddi-auto> や
C<x-sjis-kddi-auto> を利用し絵文字をマッピングします。

encode は C<x-sjis-kddi-auto> で encode し、au は MIME エンコーディングをすると
化けるためそのまま出力します。

=back

=item SoftBank 向け

=over 4

=item MIME-Header-JP-Mobile-SoftBank, MIME-Header-JP-Mobile-Vodafone

次項の C<MIME-Header-JP-Mobile-SoftBank-UTF8> へのエイリアスです。

=item MIME-Header-JP-Mobile-SoftBank-UTF8, MIME-Header-JP-Mobile-Vodafone-UTF8

decode は utf-8 や shift_jis の場合 C<x-utf8-softbank> や
C<x-sjis-softbank> を利用し絵文字をマッピングします。
が、現在実際のところ（gmail.com などの特別な場合を除き）絵文字はゲタとなって
送られてくるので、このエンコーディングで絵文字を取ることはできないでしょう。

encode は C<x-utf8-softbank> で encode してから MIME エンコードします。

=item MIME-Header-JP-Mobile-SoftBank-SJIS, MIME-Header-JP-Mobile-Vodafone-SJIS

decode は C<MIME-Header-JP-Mobile-SoftBank-UTF8> と同じです。

encode は C<x-sjis-softbank> で encode してから MIME エンコードします。
fold はしません。

=back

=item WILLCOM 向け

=over 4

=item MIME-Header-JP-Mobile-AirH, MIME-Header-JP-Mobile-Airedge

次項の C<MIME-Header-JP-Mobile-AirH-SJIS> へのエイリアスです。

=item MIME-Header-JP-Mobile-AirH-SJIS, MIME-Header-JP-Mobile-Airedge-SJIS

decode は iso-2022-jp や shift_jis の場合 C<x-iso-2022-jp-airh> や
C<x-sjis-airh> を利用し絵文字をマッピングします。

encode は C<x-sjis-airh> で encode してから MIME エンコードします。

=back

=back

=head1 AUTHOR

Naoki Tomita E<lt>tomita@cpan.orgE<gt>

=head1 SEE ALSO

L<Encode::JP::Mobile>, L<http://codezine.jp/a/article/aid/1262.aspx>

=cut


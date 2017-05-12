package Encode::JP::Mobile::Fallback;
use strict;
use warnings;
use Encode;
use Encode::JP::Mobile ':props';

sub Encode::JP::Mobile::FB_CHARACTER { 
    my $check = @_ ? shift : Encode::FB_DEFAULT;

    return sub {
        my $code = shift;
        my $char = chr $code;
        my $fallback_name;
        if ($char =~ /^\p{InMobileJPPictograms}$/) {
            my $obj = Encode::JP::Mobile::Character->from_unicode($code);
            for (qw( I V E )) {
                my $f = $obj->fallback_name($_);
                $fallback_name = $f if defined $f;
            }
        }
        return defined $fallback_name 
            ? encode('utf-8', $fallback_name)
            : encode('x-utf8-docomo', $char, $check);
            # using x-utf8-docomo for "utf8 but that has cp932 chars only"
    }; 
}

1;
__END__

=encoding utf-8

=head1 NAME

Encode::JP::Mobile::Fallback - custom callback for pictogram convert

=head1 SYNOPSIS

  use Encode;
  use Encode::JP::Mobile;
  
  encode('x-utf8-docomo', "\x{ECA2}", Encode::JP::Mobile::FB_CHARACTER); # => (>３<)

=head1 FALLBACK

=over 4

=item Encode::JP::Mobile::FB_CHARACTER

キャリアがメール送信時に行なっている絵文字の相互変換をエミュレートするためのコールバックです。

Encode::JP::Mobile で定義されたエンコーディングはキャリア間の 絵文字 => 絵文字（場合によっては複数の絵文字）相互変換をサポートしていますが、絵文字 => 文字 と変換されるものは含まれていません。C<Encode::JP::Mobile::FB_CHARACTER> を C<Encode::encode> の引数として渡すことでキャリアが行なう相互変換と同じことを行ないます。

  my $char = "\x{EFC5}\x{ED8B}"; # au の宇宙人とバンザイ
  encode('x-utf8-docomo', $char, Encode::JP::Mobile::FB_CHARACTER); # => [宇宙人]＼(^o^)／
   
絵文字以外についての fallback の扱いについては、C<Encode::JP::Mobile::FB_CHARACTER> に引数として渡すことができます。
  
  my $char = "\x{2668}\x{ED8B}"; # 温泉マーク（x-utf8-docomoに含まれない）とバンザイ
  encode('x-utf8-docomo', $char, Encode::JP::Mobile::FB_CHARACTER); # => ? ＼(^o^)／ 
  
  encode('x-utf8-docomo', $char, Encode::JP::Mobile::FB_CHARACTER(Encode::FB_XMLCREF)); # => &#x2668;＼(^o^)／
  
  my $fb_callback = Encode::JP::Mobile::FB_CHARACTER(sub {"[x]"});
  encode('x-utf8-docomo', $char, $fb_callback); # [x]＼(^o^)／

C<Encode::JP::Mobile::FB_CHARACTER> は C<use Encode::JP::Mobile;> で利用できます。C<use Encode::JP::Mobile::Fallback;> する必要はありません。
   
=back

=head1 AUTHOR

Naoki Tomita E<lt>tomita@cpan.orgE<gt>

=head1 SEE ALSO

L<Encode::JP::Mobile>

=cut

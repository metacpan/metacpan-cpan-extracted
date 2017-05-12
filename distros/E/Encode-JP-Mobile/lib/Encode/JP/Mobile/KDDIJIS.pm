package Encode::JP::Mobile::KDDIJIS;
use strict;
use warnings;
use base qw(Encode::Encoding);
use Encode::Alias;
use Encode::CJKConstants qw(:all);
use Encode qw(:fallbacks);
use Encode::JP::Mobile;
use POSIX 'ceil';
use Carp;

define_alias('x-iso-2022-jp-ezweb' => 'x-iso-2022-jp-kddi');
__PACKAGE__->Define(qw(x-iso-2022-jp-kddi));

my $re_scan_jis = qr{
   (?:($RE{JIS_0212})|$RE{JIS_0208}|($RE{ISO_ASC})|($RE{JIS_KANA}))([^\e]*)
}x;

sub _encoding() { 'x-sjis-kddi-cp932-raw' }

sub decode($$;$) {
    my ($self, $str, $chk) = @_;

    my $residue = '';
    if ($chk) {
        $str =~ s/([^\x00-\x7f].*)$//so and $residue = $1;
    }
    $residue .= _jis_sjis( \$str );
    $_[1] = $residue if $chk;

    return Encode::decode( $self->_encoding, $str, FB_PERLQQ );
}

sub encode($$;$) {
    my ( $obj, $utf8, $chk ) = @_;
    my $octet = Encode::encode( $obj->_encoding, $utf8, $chk );
    return _sjis_jis( $octet );
}

sub ASC () { 1 }
sub JIS_0208 () { 2 }
sub KANA () { 3 }
sub _sjis_jis {
    my $octet = shift;

    use bytes;

    my @chars = split //, $octet;
    my $mode = ASC;
    my $res = '';

    for (my $i=0; $i<@chars; $i++) {
        my $x = ord $chars[$i];
        if ($x < 0x80) {
            if ($mode != ASC) {
                $res .= $ESC{ASC};
                $mode = ASC;
            }
            $res .= chr $x;
        } elsif (0xA1 <= $x && $x <= 0xDF) {
            if ($mode != KANA) {
                $res .= $ESC{KANA};
                $mode = KANA;
            }
            $mode = KANA;
            $res .= chr($x - 0x80);
        } else {
            if ($mode != JIS_0208) {
                $res .= $ESC{JIS_0208};
                $mode = JIS_0208;
            }
            $i++;
            last unless $i<@chars;
            my ($c1, $c2) = _sjis2jis_one($x, ord $chars[$i]);
            $res .= chr($c1).chr($c2);
        }
    }

    if ($mode != ASC) {
        $res .= $ESC{ASC};
    }

    $res;
}
sub _sjis2jis_one {
    my ($c1, $c2) = @_;

    # 0x0600 : 0xF340 - 0xF48D
    # 0x0B00 : 0xF640 - 0xF7FC

    my $c = ($c1<<8) + $c2;
    if (0xF340 <= $c && $c <= 0xF48D) {
        $c1 -= 0x06;
    } elsif (0xF640 <= $c && $c <= 0xF7FC) {
        $c1 -= 0x0B;
    }

    $c1 -= ($c1 <= 0x9f) ? 0x71 : 0xB1;
    $c1 = $c1*2 + 1;

    if ($c2 > 0x7F) {
        $c2 -= 0x01;
    }

    if ($c2>=0x9E) {
        $c2  = $c2-0x7D;
        $c1++;
    } else {
        $c2 -= 0x1F;
    }

    return ($c1, $c2);
}

sub _jis_sjis {
    local ${^ENCODING};

    my $r_str = shift;
    $$r_str =~ s($re_scan_jis){
        my ($esc_0212, $esc_asc, $esc_kana, $chunk) = ($1, $2, $3, $4);

        if ($esc_kana) {
            $chunk =~ s{(.)}{
                pack "H*", sprintf "%X", (0x80 + (hex unpack "H*", $1));
            }geox;
            $chunk;
        } elsif ($esc_asc) {
            $chunk;
        } else {
            $chunk =~ s((..)){
                pack "H*", sprintf"%X", _jis2sjis_one(hex(unpack "H*", $1));
            }geox;
            $chunk;
        }

    }geox;

    my ($residue) = ( $$r_str =~ s/(\e.*)$//so );

    return $residue;
}

sub _jis2sjis_one { my $x = shift; return ( _xy($x) << 8 ) + _zu($x) } # input is binary

sub _high { my $x = shift; $x >> 8 }
sub _low  { my $x = shift; $x & 0xff }

sub _xy {
    my $jis = shift;

    my $pq = _high($jis);
    my $t  = ceil( $pq / 2 ) + 0x70;
    my $ans = ($t <= 0x9F) ? $t : $t+0x40;

    # XXX !!!
    if (0xED == $ans || $ans == 0xEE) {
        return $ans + 0x06;
    } elsif (0xEB == $ans || $ans == 0xEC) {
        return $ans + 0x0b;
    } else {
        return $ans;
    }
}

sub _zu {
    my $jis = shift;
    my $pq  = _high($jis);
    my $rs  = _low($jis);

    if ( $pq % 2 ) {    # odd
        my $t = $rs + 0x20;
        return ( $t > 0x7f ) ? $t : $t - 1;
    }
    else {              # even
        return $rs + 0x7E;
    }
}

package # hide from PAUSE
    Encode::JP::Mobile::KDDIJIS::Auto;
use base 'Encode::JP::Mobile::KDDIJIS';
use Encode::Alias;

define_alias('x-iso-2022-jp-ezweb-auto' => 'x-iso-2022-jp-kddi-auto');
__PACKAGE__->Define(qw(x-iso-2022-jp-kddi-auto));

sub _encoding() { 'x-sjis-kddi-auto-raw' }

1;

__END__

=encoding utf-8

=head1 NAME

Encode::JP::Mobile::KDDIJIS - KDDI のメール受信で絵文字つかう

=head1 DESCRIPTION

KDDI のメールで送信される iso-2022-jp にのってやってくるメール用絵文字JISコードを decode するためのアレ。

この実装の根拠は、絵文字用 JIS コードと他の文字コードの間にはとくに法則性はない

絵文字用JISコードを素直に一般に知られている SJIS に変換する方式にしたがってずらしたものが絵文字用SJISコード。
絵文字用SJISコードは

 * 0xED40 から 0xEE8D の区間では、0x0600 足す
 * 0xEB59から0xECE4の区間では 0x0b00 足す

というルールにより通常の sjis 時の区画にもっていくことができる。この手法が非常に簡単に実装可能であることから、
実機もこのような方法で実装されているのではないかと想像している(私見)

この後で、x-sjis-kddi で decode すれば OK.

encode の場合はこの逆をやればよい。unicode 文字列を sjis のバイト列に encode してやり、
下記のエリアにある文字列をシフトしてやる。

 * 0x0600 : 0xF340 - 0xF48D
 * 0x0B00 : 0xF640 - 0xF7FC

こうしてシフトしつつ、iso-2022-jp に変換してやればよい。

=head1 ENCODINGS

x-iso-2022-jp-kddi, x-iso-2022-jp-ezweb で表 utf-8 に decode。x-iso-2022-jp-ezweb-auto,
x-iso-2022-jp-kddi-auto で裏 utf-8 に decode できます。

=head1 TODO

JIS X 0212 に対応してない。けどそもそも ezweb で使えるのかね。そこがまず疑問ではあるよ。

=head1 AUTHOR

Tokuhiro Matsuno <tokuhirom at mobile factory dot jp>

=head1 SEE ALSO

L<http://www.cc.kurume-it.ac.jp/home/general/sibhome/moji/moji11.html>


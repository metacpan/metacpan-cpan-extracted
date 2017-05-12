package Encode::JP::Mobile::AirHJIS;
use strict;
use warnings;
use base qw(Encode::Encoding);
use Encode::Alias;
use Encode::CJKConstants qw(:all);
use Encode qw(:fallbacks);
use Encode::JP::Mobile;
use POSIX 'ceil';
use Carp;

define_alias('x-iso-2022-jp-airedge' => 'x-iso-2022-jp-airh');
__PACKAGE__->Define(qw(x-iso-2022-jp-airh));

my $re_scan_sjis = qr{
    $RE{SJIS_KANA}|$RE{SJIS_C}
}x;

my $re_scan_jis = qr{
   (?:($RE{JIS_0212})|$RE{JIS_0208}|($RE{ISO_ASC})|($RE{JIS_KANA}))([^\e]*)
}x;

sub _encoding() { 'x-sjis-docomo-raw' }

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
            $res .= $c2 ? chr($c1).chr($c2) : $c1;
        }
    }

    if ($mode != ASC) {
        $res .= $ESC{ASC};
    }

    $res;
}
sub _sjis2jis_one {
    my ($c1, $c2) = @_;

    # 0xF89F - 0xF949
    # 0xF950 - 0xF952
    # 0xF955 - 0xF957
    # 0xF95B - 0xF95E
    # 0xF972 - 0xF9FC
    my $c = ($c1<<8) + $c2;
    if (0xF89F <= $c && $c <= 0xF949 ||
        0xF950 <= $c && $c <= 0xF952 ||
        0xF955 <= $c && $c <= 0xF957 ||
        0xF95B <= $c && $c <= 0xF95E ||
        0xF972 <= $c && $c <= 0xF9FC) {
        return pack('H*', sprintf('%X', $c));
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
            $chunk =~ s{(?:($re_scan_sjis)|(..))}{
                $1 ? $1 : pack "H*", sprintf "%X", _jis2sjis_one(hex(unpack "H*", $2))
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

1;

__END__

=encoding utf-8

=head1 NAME

Encode::JP::Mobile::AirHJIS - AirHPhone のメール受信で絵文字つかう

=head1 DESCRIPTION

AirHPhone より送信されるメールの中に埋めこまれているドコモの絵文字を decode する。

AirH オリジナル絵文字には対応していないことに注意してください。

=head1 ENCODINGS

    x-iso-2022-jp-airh
    x-iso-2022-jp-airedge

=head1 AUTHOR

Yoshiki Kurihara

=head1 SEE ALSO

L<http://mobilehacker.g.hatena.ne.jp/clouder/20080226/1204031956>,
L<http://mobilehacker.g.hatena.ne.jp/clouder/20080519/1211195839>,
L<Encode::JP::Mobile>

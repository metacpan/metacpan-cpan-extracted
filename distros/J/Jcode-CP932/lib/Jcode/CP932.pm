package Jcode::CP932;
require 5.008001;
our $VERSION = '0.08';

use warnings;
use strict;
use Carp;

use base qw/Jcode/;
our @EXPORT      = qw(jcode getcode);
our @EXPORT_OK   = qw($VERSION $DEBUG);
our %EXPORT_TAGS = ( all       => [ @EXPORT, @EXPORT_OK ] );

our $DEBUG;
our $FALLBACK;
our $NORMALIZE;
*DEBUG    = \$Jcode::DEBUG;
*FALLBACK = \$Jcode::FALLBACK;

$NORMALIZE = \&normalize_cp932;

use overload 
    q("") => sub { $_[0]->euc },
    q(==) => sub { overload::StrVal($_[0]) eq overload::StrVal($_[1]) },
    q(.=) => sub { $_[0]->append( $_[1] ) },
    fallback => 1,
    ;

my $pkg = __PACKAGE__;
use Encode;
use Encode::Alias;
use Encode::Guess;
use Encode::JP::H2Z;
use Scalar::Util; # to resolve from_to() vs. 'constant' issue.

use Encode::EUCJPMS;
sub default_encode_mapping {
    sjis        => 'cp932',
    euc         => 'cp51932',
    jis         => 'cp50221',
    iso_2022_jp => 'cp50220',
    ucs2        => 'UTF-16BE',
}

$pkg->set_jname2e( default_encode_mapping() );
my %jname2e;
my %ename2j;

sub set_jname2e {
    my $class = shift;
    my %new_jname2e = @_;
    foreach my $enc (keys %new_jname2e) {
        my $name = $new_jname2e{$enc} || $enc;
        my $e = find_encoding($name) or croak "$enc not supported";

        $jname2e{$enc}  = $name;
        $ename2j{$name} = $enc;

        no strict 'refs';
        no warnings 'redefine';
        *{"$class\::$enc"} = sub {
            my $r_str = $_[0]->{r_str};
            $_[0]->{normalize} and $_[0]->{normalize}->( $r_str );
            Encode::is_utf8($$r_str) ? $e->encode($$r_str, $_[0]->{fallback})
                                     : $$r_str;
        };
    }
}

sub jcode {
    $pkg->new(@_)
}

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    $self->{normalize} = $NORMALIZE;
    $self;
}

## from original Jcode
my %_0208 = (
       1978 => '\e\$\@',
       1983 => '\e\$B',
       1990 => '\e&\@\e\$B',
);
my %RE = (
       ASCII     => '[\x00-\x7f]',
       BIN       => '[\x00-\x06\x7f\xff]',
       EUC_0212  => '\x8f[\xa1-\xfe][\xa1-\xfe]',
       EUC_C     => '[\xa1-\xfe][\xa1-\xfe]',
       EUC_KANA  => '\x8e[\xa1-\xdf]',
       JIS_0208  =>  "$_0208{1978}|$_0208{1983}|$_0208{1990}",
       JIS_0212  => "\e" . '\$\(D',
       JIS_ASC   => "\e" . '\([BJ]',     
       JIS_KANA  => "\e" . '\(I',
       SJIS_C    => '[\x81-\x9f\xe0-\xfc][\x40-\x7e\x80-\xfc]',
       SJIS_KANA => '[\xa1-\xdf]',
       UTF8      => '[\xc0-\xdf][\x80-\xbf]|[\xe0-\xef][\x80-\xbf][\x80-\xbf]'
);

use B::Deparse;
my $deparse = B::Deparse->new();
$deparse->ambient_pragmas(strict => 'all');
foreach my $func (qw/convert append getcode set _max/) {
    my $body = $deparse->coderef2text( \&{"Jcode::$func"} );
    eval "sub $func $body";
    die if $@;
}

##
sub utf8 {
    my $str_ref = $_[0]->{r_str};
    $_[0]->{normalize} and $_[0]->{normalize}->( $str_ref );
    encode_utf8( $$str_ref )
}

sub get {
    ${$_[0]->{r_str}};
}


## Normalize
sub normalize {
    my $self = shift;
    @_ or return $self->{normalize};
    $self->{normalize} = $_[0];
    return $self;
}

my %jis_cp932;
my $j2c_jis;
my $j2c_cp932;

# YEN SIGN,        EM DASH,        OVERLINE,         MIDLINE HORIZONTAL ELLIPSIS
my $other_mapping = "\x{00A5}\x{2014}\x{203E}\x{22EF}";
# REVERSE SOLIDUS, HORIZONTAL BAR, FULLWIDTH MACRON, HORIZONTAL ELLIPSIS
my $jis_mapping   = "\x{005C}\x{2015}\x{FFE3}\x{2026}";

sub set_jis_cp932 {
    my $class = shift;
    %jis_cp932 = @_;

    $j2c_jis   = join '', keys   %jis_cp932;
    $j2c_cp932 = join '', values %jis_cp932;

    $j2c_jis   =~ s,\\,\\\\,og; $j2c_jis   =~ s,/,\\/,og;
    $j2c_cp932 =~ s,\\,\\\\,og; $j2c_cp932 =~ s,/,\\/,og;

    no strict 'refs';
    no warnings 'redefine';
    *{"$class\::normalize_cp932"} = eval qq{
      sub {
        my \$str_ref = ref \$_[0]? \$_[0]: \\\$_[0];
        if (defined \$\$str_ref and Encode::is_utf8(\$\$str_ref)) {
            \$\$str_ref =~ tr/$j2c_jis$other_mapping/$j2c_cp932$jis_mapping/;
        }
        \$\$str_ref;
      }
    };
    die $@ if $@;

    *{"$class\::normalize_jis"} = eval qq{
      sub {
        my \$str_ref = ref \$_[0]? \$_[0]: \\\$_[0];
        if (defined \$\$str_ref and Encode::is_utf8(\$\$str_ref)) {
            \$\$str_ref =~ tr/$j2c_cp932$other_mapping/$j2c_jis$jis_mapping/;
        }
        \$\$str_ref;
      }
    };
    die $@ if $@;
}
                                # JIS => CP932 
$pkg->set_jis_cp932(
    "\x{2016}" => "\x{2225}",   # DOBULE VERTICAL LINE => PARALLEL TO
    "\x{2212}" => "\x{FF0D}",   # MINUS SIGN => FULLWIDTH HYPHEN-MINUS
    "\x{301C}" => "\x{FF5E}",   # WAVE DASH  => FULLWIDTH TILDE
    "\x{00A2}" => "\x{FFE0}",   # CENT SIGN  => FULLWIDTH CENT SIGN
    "\x{00A3}" => "\x{FFE1}",   # POUND SIGN => FULLWIDTH POUND SIGN
    "\x{00AC}" => "\x{FFE2}",   # NOT SIGN   => FULLWIDTH NOT SIGN
    "\x{00A6}" => "\x{FFE4}",   # BROKEN BAR => FULLWIDTH BROKEN BAR
);



#######################################
# Full and Half
#######################################

use Jcode::CP932::H2Z;
sub h2z {
    my $self = shift;
    Jcode::CP932::H2Z::h2z( $self->{r_str}, @_ );
    $self;
}

sub z2h {
    my $self = shift;
    Jcode::CP932::H2Z::z2h( $self->{r_str}, @_ );
    $self;
}

sub h2z_ascii {
    my $str_ref = $_[0]->{r_str};
    $$str_ref =~ tr 
        [\x{0020}\x{0021}\x{0022}\x{0023}-\x{0026}\x{0027}\x{0028}-\x{005f}\x{0060}\x{0061}-\x{007e}\x{00a5}\x{00a6}]
        [\x{3000}\x{ff01}\x{201d}\x{ff03}-\x{ff06}\x{2019}\x{ff08}-\x{ff3f}\x{2018}\x{ff41}-\x{ff5e}\x{ffe5}\x{ffe4}]
    ;
    $_[0];
}
sub z2h_ascii {
    my $str_ref = $_[0]->{r_str};
    $$str_ref =~ tr
        [\x{3000}\x{ff01}-\x{ff5e}\x{ffe5}\x{ffe4}\x{201d}\x{2019}\x{2018}]
        [\x{0020}\x{0021}-\x{007e}\x{00a5}\x{00a6}\x{0022}\x{0027}\x{0060}]
    ;
    $_[0];
}

sub h2z_all {
    my $self = shift;
    $self->h2z(@_)->h2z_ascii;
}
sub z2h_all {
    my $self = shift;
    $self->z2h(@_)->z2h_ascii;
}

#######################################
# Hiragana and Katakana
#######################################

sub hira2kata {
    my $str_ref = $_[0]->{r_str};
    $$str_ref =~ tr [\x{3041}-\x{3096}]
                    [\x{30a1}-\x{30f6}] ;
    $_[0];
}
sub kata2hira {
    my $str_ref = $_[0]->{r_str};
    $$str_ref =~ tr [\x{30a1}-\x{30f6}]
                    [\x{3041}-\x{3096}] ;
    $_[0];
}



1; # End of Jcode::CP932
__END__

=encoding utf8

=head1 名前

Jcode::CP932 - CP932準拠によるJcode

=head1 概要

 use Jcode::CP932;
 # 推奨（Jcode.pmとの互換を考えて）
 jcode( $str )->utf8;

 # 古式ゆかしく
 Jcode::CP932::convert($str, $ocode, $icode, "z");
 # もしくはオブジェクト指向で！
 print Jcode::CP932->new($str)->h2z->tr($from, $to)->utf8;

=head1 説明

Jcode::CP932はCP932によるUnicodeマッピングを用いたL<Jcode>代替物です。
sjisはCP932の、eucやjisはCP51932およびCP50221のマッピングを利用しています。

特に説明のない点はL<Jcode>と同様の動作になります。

=head1 正規化

JIS系で変換したUTF-8文字とCP932系で変換したUTF-8での不整合を解消するために、エンコード変換時に正規化処理を行なうことができます。
標準では一部記号をJIS系のものからCP932系に変換しています。

=head1 追加メソッド

オリジナルのJcodeに対して、以下のメソッドを追加しています。

（これらは主にL<Unicode::Japanese>を参考にしました）

=head2 get

Jcode内部に保存しているUTF-8文字列を取得します。

utf8メソッドではUTF-8文字列をバイナリに変換しますが、getメソッドではutf8フラグが付いた文字列になります。

=head2 ひらがなカタカナ変換 (hira2kata kata2hira)

hira2kataメソッドは、文字列に含まれているひらがなを全てカタカナに変換します。

kata2hiraメソッドは、文字列に含まれているカタカナを全てひらがなに変換します。

=head2 ASCII文字列の全角半角変換

z2h_asciiメソッドは、文字列に含まれている半角ASCIIを全角ASCIIに変換します。
z2h_allメソッドは、文字列に含まれる半角のASCIIおよびカタカナを全角に変換します。

h2z_asciiメソッドは、文字列に含まれている全角ASCIIを半角ASCIIに変換します。
z2h_allメソッドは、文字列に含まれる全角のASCIIおよびカタカナを半角に変換します。



=head1 謝辞

Jcode.pmの小飼弾氏と、Encode::EUCJPMSの成瀬ゆい氏、Unicode::Japaneseの山科氷魚氏に。

また、レガシーエンコディングの件では森山将之氏にお世話になりました。

=head1 参考

L<Jcode>

L<Encode::EUCJPMS>

L<Unicode::Japanese>

=head1 著作権

Copyright 2006-2009 ASAKURA Takuji

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

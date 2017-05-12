package Encode::JP::Mobile::Vodafone;
use strict;
use base qw(Encode::Encoding);
__PACKAGE__->Define(qw(x-sjis-vodafone-raw));

use Encode::Alias;
define_alias('x-sjis-softbank-raw' => 'x-sjis-vodafone-raw');

# G! => E001, G" => E002, G# => E003 ...
# E! => E101, F! => E201, O! => E301, P! => E401, Q! => E501
my %HighCharToBit = (G => 0xE000, E => 0xE100, F => 0xE200,
                     O => 0xE300, P => 0xE400, Q => 0xE500);
my %HighBitToChar = reverse %HighCharToBit;

my $range = '\x{E001}-\x{E05A}\x{E101}-\x{E15A}\x{E201}-\x{E25A}\x{E301}-\x{E34D}\x{E401}-\x{E44C}\x{E501}-\x{E539}';
my $InRange  = "[$range]";
my $OutRange = "[^$range]";

sub decode($$;$) {
    my($self, $char, $check) = @_;
    my $str = Encode::decode("cp932", $char, Encode::FB_PERLQQ);
    $str =~ s{\x1b\x24([GEFOPQ])([\x20-\x7F]+)\x0f}{
        join '', map chr($HighCharToBit{$1} | ord($_) - 32), split //, $2;
    }ge;
    $_[1] = $str if $check;
    $str;
}

sub encode($$;$) {
    my($self, $str, $check) = @_;
    my $res = '';
    $str =~ tr/\x{301C}/\x{FF5E}/; # ad-hoc solution for  FULLWIDTH TILDE Problem
    $str =~ s{($InRange+)|($OutRange+)}{
        my $in = defined $1;
        my $m  = $in ? $1 : $2;
        $res .= $in ? _encode_vodafone($m)
            : Encode::encode("cp932", $m, $check);
        ''
    }egs;
    $_[1] = $res if $check;
    $res;
}

sub _encode_vodafone {
    my $str = shift;
    my @str = split //, $str;
    my $res = "\x1b\x24";
    my $buf = '';
    for my $str (@str) {
        my $high = ord($str) & 0xEF00;
        my $low  = ord($str) & 0x00FF;
        if ($buf ne $high) {
            $res .= "\x0f\x1b\x24" unless $buf eq '';
            $res .= $HighBitToChar{$high};
        }
        $res .= chr($low+32);
        $buf = $high;
    }
    $res . "\x0f";
}

1;

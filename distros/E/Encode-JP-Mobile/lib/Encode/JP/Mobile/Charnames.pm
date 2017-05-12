package Encode::JP::Mobile::Charnames;
use strict;
use warnings;
use bytes     ();
use File::ShareDir 'dist_file';
use Carp;
use Encode;
use Encode::JP::Mobile ':props';
use Encode::JP::Mobile::Character;

use base qw( Exporter );
our @EXPORT_OK = qw( unicode2name unicode2name_en vianame );

my $name2unicode;

{
    # re.pm clobbers $_ in 5.14.0 ~ 5.16.0
    # and charnames.pm requires re.pm
    # ref. https://github.com/mirrors/perl/commit/48895a0d
    BEGIN {
        local $_;
        require charnames;
        charnames->import(':full');
        *_def_translator = $^H{charnames}
    }
}


sub import {
    # for perl < 5.10
    if ($charnames::hint_bits) {
        $^H |= $charnames::hint_bits;
    }
    $^H{charnames} = \&_translator;
    __PACKAGE__->export_to_level(1, @_);
}

sub _translator {
    if ( $^H & $bytes::hint_bits ) {
        _bytes_translator(@_);
    }
    else {
        _unicode_translator(@_);
    }
}

sub _name2unicode () {
    return $name2unicode if $name2unicode;

    for my $carrier (qw/docomo kddi softbank/) {
        my $fname = dist_file( 'Encode-JP-Mobile', "${carrier}-table.pl" );
        my $dat = do $fname;

        for my $row (@$dat) {
            next unless exists $row->{name};
            $name2unicode->{$carrier}{$row->{name}} ||= hex $row->{unicode};
            if ( exists $row->{name_en} ) {
                $name2unicode->{$carrier}{$row->{name_en}} ||= hex $row->{unicode};
            }
        }
    }

    return $name2unicode;
}


my $re = qr/^(DoCoMo|KDDI|SoftBank) (.+)$/io;

sub _unicode_translator {
    my $name = shift;

    if ( my ( $carrier, $r_name ) = ( $name =~ $re ) ) {
        my $ret = _name2unicode->{lc($carrier)}{$r_name};
        if ( defined $ret ) {
            return pack "U*", $ret;
        }
        else {
            carp "unknown charnames: $r_name";
        }
    }
    else {
        return _def_translator($name);
    }
}

# pictograms are only in the above 0xFF area.
sub _bytes_translator {
    my $name = shift;
    return _def_translator($name);
}

sub vianame {
    my $name = shift;
    croak "missing name" unless $name;

    if ( my ( $carrier, $r_name ) = ( $name =~ $re ) ) {
        return _name2unicode->{lc($carrier)}{$r_name} || carp "unknown charnames: $r_name";
    }
    else {
        return charnames::vianame($name);
    }
}

# handling x-sjis-kddi-cp932-raw.see pod.
sub _kddi_cp932toauto {
    my $code = shift;

    my $c = pack('U', $code);
    if ($c !~ /^\p{InKDDISoftBankConflicts}$/ && $c =~ /^\p{InKDDICP932Pictograms}$/) {
        return unpack 'U*', decode('x-sjis-kddi-auto-raw', encode('x-sjis-kddi-cp932-raw', $c));
    } else {
        return $code;
    }
}

sub unicode2name {
    my $code = shift;
    croak "missing code" unless $code;

    return Encode::JP::Mobile::Character->from_unicode(_kddi_cp932toauto($code))->name;
}

sub unicode2name_en {
    my $code = shift;
    croak "missing code" unless $code;

    return Encode::JP::Mobile::Character->from_unicode(_kddi_cp932toauto($code))->name_en;
}

1;
__END__

=encoding utf-8

=head1 NAME

Encode::JP::Mobile::Charnames - define pictogram names for "\N{named}" string literal escapes

=head1 SYNOPSIS

    use Encode::JP::Mobile::Charnames;

    print "\N{DoCoMo Beer} \N{DoCoMo ファーストフード}\n";
    Encode::JP::Mobile::Charnames::unicode2name(0xE672);    # => 'ビール'
    Encode::JP::Mobile::Charnames::unicode2name_en(0xE672); # => 'Beer'
    Encode::JP::Mobile::Charnames::vianame('DoCoMo Beer');  # => 0xE672

=head1 METHODS

=over 4

=item unicode2name

    Encode::JP::Mobile::Charnames::unicode2name(0xE672);    # => 'ビール'

unicode から日本語の名前を得ます。

このメソッドは KDDI-cp932 と KDDI-Auto のどちらの Unicode が引数として渡されても名前を返します。

ただし、現在の仕様では、SoftBank と au の重複領域では SoftBank が優先されます。
シェアを考えれば KDDI の方を優先するべきですが、KDDI の方は KDDI-CP932 ではなく
KDDI-Auto を使うという代替手法があるので、このような仕様となっております。

=item unicode2name_en

    Encode::JP::Mobile::Charnames::unicode2name_en(0xE672); # => 'Beer'

Unicode から英語の名前を得ます。

キャリヤから公式に英語の絵文字名称が付与されているのは docomo だけであるため、KDDI, SoftBank については一度  DoCoMo 絵文字にマッピングして得られた文字の名前を利用しています。

=item vianame

    Encode::JP::Mobile::Charnames::vianame('DoCoMo Beer');  # => 0xE672

名前から絵文字の Unicode を得ます

=back

=head1 AUTHOR

Tokuhiro Matsuno <tokuhirom ta mfac ・ jp>

=head1 SEE ALSO

L<Encode::JP::Mobile>, L<charnames>


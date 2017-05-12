package Device::VFD::GP1022::Message;

use strict;
use warnings;

use Carp;

use Device::VFD::GP1022::Encode;

my %COMMANDS = (
    HORIZON   => 0x8100,
    VERTICAL  => 0x8200,
    BLINK     => [ 0x8300, 0x8400 ],
    DOUBLE    => [ 0x8500, 0x8600 ],
    STOP      => 0x88,
    OPEN      => { start => 0x8900, end => 0x89FF },
    CLOSE     => { start => 0x8A00, end => 0x8AFF },
    SPEED     => 0x8B,
    LEFT      => 0x8C00,
    RIGHT     => 0x8D00,
    BLINKLINE => { start => 0x8E, end => 0x8EFF },
    SPACE     => 0x8F,
    UP        => { start => 0x91, end => 0x91FF },
    DOWN      => { start => 0x92, end => 0x92FF },
    CENTER    => { start => 0x9300, end => 0x93FF },
);
$COMMANDS{FONT} = sub {
    my $stash = shift;
    my $size = shift;
    my $int = ($size eq '24x24') ? 0x9004 : 0x9003;
    i2r($int);
};
$COMMANDS{RAW} = sub {
    my $stash = shift;
    my @ret;
    for (@_) {
        push @ret, i2r($_);
    }
    @ret;
};
my %FLAGS = (
    ON  => 1,
    OFF => 0,
);

sub import {
    my $class = shift;
    my $pkg   = caller;

    no strict 'refs';
    *{"$pkg\::vfd_encode"} = \&vfd_encode;
    *{"$pkg\::STR"} = sub { goto &STR };

    for my $key (keys %COMMANDS, keys %FLAGS) {
        *{"$pkg\::$key"} = sub { goto &$key };
    }

}

sub __stub {
    my $func = shift;
    return sub {
        croak "Can't call $func() outside vfd_encode block";
    };
}

sub vfd_encode (&) {
    my $code = shift;

    my $stash = { objs => [] };

    for my $key (keys %COMMANDS) {
        no strict 'refs';
        no warnings 'redefine';
        *{$key} = sub { _commands($stash, $key, $COMMANDS{$key}, @_) };
    }
    while (my($key, $value) = each %FLAGS) {
        no strict 'refs';
        no warnings 'redefine';
        *{$key} = sub { $value };
    }

    no strict 'refs';
    no warnings 'redefine';
    local *STR = sub { _STR($stash, @_) };
    use strict;
    use warnings;

    $code->($stash);

    for my $key (keys %COMMANDS, %FLAGS) {
        no strict 'refs';
        no warnings 'redefine';
        *{$key} = __stub $key;
    }

    $stash->{objs};
}

sub _STR {
    my($stash, $str) = @_;
    push @{ $stash->{objs} }, Device::VFD::GP1022::Message::Strings->new($str);
}

sub fetch_num {
    my $int = shift;
    if ($int < 0x100) {
        $int = ($int * 256) + shift;
    }
    $int;
}

sub i2r {
    Device::VFD::GP1022::Message::Raw->i2r( shift );
}

sub _commands {
    my $stash = shift;
    my $name  = shift;
    my $conf  = shift;

    my $objs = $stash->{objs};
    if (!ref $conf) {
        push @$objs, i2r(fetch_num($conf, @_));
    } elsif(ref($conf) eq 'ARRAY') {
        my $flag = shift;
        my $data = $conf->[((!defined $flag || $flag) ? 0 : 1)];
        push @$objs, i2r(fetch_num($data, shift));
    } elsif(ref($conf) eq 'HASH') {
        my $str = shift;
        push @$objs, i2r(fetch_num($conf->{start}, @_));
        if (ref($str) eq 'CODE') {
            $str->($stash);
        } else {
            _STR($stash, $str);
        }
        push @$objs, i2r(fetch_num($conf->{end}, @_));
    } elsif(ref($conf) eq 'CODE') {
        push @$objs, $conf->($stash, @_);
    }
}

*STR   = __stub 'STR';
for my $key (keys %COMMANDS, keys %FLAGS) {
    no strict 'refs';
    *{$key} = __stub $key;
}


package Device::VFD::GP1022::Message::Strings;
use strict;
use warnings;
use overload q{""} => sub { shift->{data} };

sub is_strings { 1 };
sub is_raw { 0 };
sub new {
    my($class, $data) = @_;
    bless { data => $data }, $class;
}

package Device::VFD::GP1022::Message::Raw;
use strict;
use warnings;
use overload q{""} => sub { shift->{data} };

sub is_strings { 0 };
sub is_raw { 1 };
sub new {
    my($class, $data) = @_;
    bless { data => $data }, $class;
}
sub i2r {
    my($class, $int) = @_;
    $class->new(
        pack('C', ($int % 256)) . pack('C', int($int / 256))
    );
}

1;
__END__

=head1 NAME

Device::VFD::GP1022::Message - DSL for GP1022 VFD controller

=head1 SYNOPSIS

  use Device::VFD::GP1022;
  use Device::VFD::GP1022::Message;

  my $vfd = Device::VFD::GP1022->('/dev/ttyUSB0');
  $vfd->message( vfd_encode {
     SPEED 0;
     HORIZON;
     STR 'foo';
     BLINKLINE 'blink strings' 5;
  } );

=head1 DESCRIPTION

Device::VFD::GP1022 is

=head1 METHODS

=over 4

=item vfd_encode

make the object that can be transmitted to the vfd device. 
It describes it by DSL. 

=back

=head1 DSL

=over 4

=item STR 'string'

文字列をVFDへ表示します。

=item HORIZON

水平スクロールモードにします。

=item VERTICAL

垂直スクロールモードにします。

=item LEFT

水平スクロールモード時には右から左へ文字を流します。
垂直スクロールモード時には下から上へ文字を流します。

=item RIGHT

水平スクロールモード時には左から右へ文字を流します。
垂直スクロールモード時には上から下へ文字を流します。

=item BLINK

点滅スクロールモードにします。

=item DOUBLE

等倍フォントにします。

=item STOP 1..99

スクロールを指定秒数の間停止します。

=item OPEN 'strings'

stringsの文字列に対してカーテンオープンエフェクトを加えます。

=item CLOSE 'strings'

stringsの文字列に対してカーテンクローズエフェクトを加えます。

=item SPEED 0..4

スクロールスピードを変更します。
0が最も早く、4が最も遅くなります。

=item BLINKLINE 'strings' 1..5

stringsの文字列のみ点滅します。
2つめの引数は点滅回数です。

=item SPACE 1..15

引数で指定されたドットだけスペースを空けます。

=item UP 'strings' 0..255

stringsの文字列に対して上から下にスクロールするエフェクトを加えます。
2つめの引数はスクロールエフェクトを開始する位置です。

=item DOWN  'strings' 0..255

stringsの文字列に対して下から上にスクロールするエフェクトを加えます。
2つめの引数はスクロールエフェクトを開始する位置です。

=item CENTER  'strings'

stringsの文字列をセンタリング表示します。。

=item FONT fontsize

表示するフォントサイズを指定します。
24x24と12x24が指定できます。

  vfd_encode { FONT '24x24'; };
  vfd_encode { FONT '12x24'; };

=item RAW

VFDへの命令コードを直接記述できます。

=back

=head1 USER FONT

DSLのRAWを活用してオリジナルフォントをVFDに表示させられます。

  # for 24x24 font
  vfd_encode {
    RAW 0x9004;
    RAW ((0xFFFF) x 36);
  };

  # for 14x24 font
  vfd_encode {
    RAW 0x9003;
    RAW ((0xFFFF) x 18);
  };

このサンプルでは、全てのドットが塗りつぶされます。

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

=head1 SEE ALSO

L<Device::VFD::GP1022>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

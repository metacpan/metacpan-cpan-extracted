package Device::VFD::GP1022;

use strict;
use warnings;
our $VERSION = '0.01';

our $SERIAL;

use Carp;

if ($^O =~ /win/i && $^O !~ /darwin/) {
    $SERIAL = 'Win32::SerialPort';
} else {
    $SERIAL = 'Device::SerialPort';
}
eval "require $SERIAL";
$@ and carp "$SERIAL is not installed";

use Device::VFD::GP1022::Message;


sub new {
    my $class = shift;
    my %opts = (@_ == 1) ? ( port => $_[0] ) : @_;

    $opts{port} or carp 'port option dose not exist';
    $opts{size} ||= '264x24';

    my $self = bless {
        opts => \%opts,
    }, $class;

    eval {
        $self->{serial} = ref($opts{serial}) ? $opts{serial} : $class->setup_serial(%opts);
    };
    $@ and carp 'serial port init error';

    $self->{encode} = ref($opts{encode}) ? $opts{encode} : Device::VFD::GP1022::Encode->new;

    $self->full;
    $self;
}

sub encode { shift->{encode} }
sub serial { shift->{serial} }

sub setup_serial {
    my($class, %opts) = @_;

    my $config = $opts{port_config} || {};

    my $serial = $SERIAL->new($opts{port}) or die;
    $serial->user_msg(1) or die;
    $serial->error_msg(1) or die;
    $serial->parity('none') or die;
    $serial->databits(8) or die;
    $serial->stopbits(1) or die;
    $serial->baudrate($config->{baudrate} || 19200) or die;

    $serial->handshake('none') or die;
    $serial->read_const_time(1000) or die;
    $serial->read_char_time(10) or die;
    $serial->write_settings or die;

    $serial;
}

my $END_DATA = pack 'C', 0xEF;
sub send_message {
    my($self, $message) = @_;

    my $send = $message . $self->make_checksum($message) . $END_DATA;
    $self->{serial}->write( $send );
    my($size, $recv) = $self->{serial}->read(7);
    if ($size) {
        my @recvs = unpack 'C*', $recv;
        return $recvs[2];
    }
    return 0;
}

sub make_checksum {
    my($self, $message) = @_;

    my $sum = 0;
    for my $data (unpack 'C*', $message) {
        $sum += $data;
    }
    pack('CC', int($sum / 256), ($sum % 256));
}

my $EMPTY_DATA = pack 'C', 0xFF;
sub message {
    my($self, $mode, $str) = @_;

    unless (defined $str) {
        $str  = $mode;
        $mode = 'force';
    }

    carp "'$mode' is can't message command" unless $mode =~ /^(?:append|force|buffer)$/;

    my $objs;
    if (!ref($str)) {
        $objs = vfd_encode { STR $str };
    } else {
        $objs = $str;
    }

    my $message = '';
    for my $obj (@{ $objs }) {
        if ($obj->is_raw) {
            $message .= $obj;
        } else {
            $message .= $self->{encode}->encode($obj);
        }
    }


    use bytes;
    my @frames;
    if (bytes::length($message) > 256) {
        while (my $tmp = substr $message, 0, 256, '') {
            push @frames, $tmp;
        }
    } else {
        push @frames, $message;
    }

    my $ret = $self->$mode(scalar(@frames)) or return 0;
    croak 'send data error' if $ret eq 0xC3;
    croak 'time out error' if $ret eq 0xC3;

    my $i = 1;
    for my $msg (@frames) {
        $msg .= $EMPTY_DATA x (256 - bytes::length($msg));
        $ret =  $self->send_message( pack('C*', 0, $i++, 0) . $msg );
        croak 'send data error' if $ret eq 0xC3;
        croak 'time out error' if $ret eq 0xC3;
    }
    $ret;
}

my %COMMANDS = (
    append  => 0x03,
    force   => 0x04,
    buffer  => 0x05,
    display => [ 0x10, 0x11 ],
    scroll  => [ 0x12, 0x13 ],
    clear   => 0x14,
    default => 0x15,
    switch  => 0x17,
    rewind  => 0x18,
    full    => 0x29,
    reverse => [ 0x31, 0x30 ],
);

sub command {
    my($self, $code, $frame_num) = @_;
    $frame_num ||= 0;
    $self->send_message( pack('C*', 0, 0, $code, $frame_num) );
}

sub is_scroll {
    my $self = shift;
    ($self->command(0x1C) eq 0xC2);
}

my %TIMEOUT = (
    0.5 => 0x41,
    1.0 => 0x42,
    2.0 => 0x43,
    3.0 => 0x44,
    5.0 => 0x45,
);
sub timeout {
    my($self, $time) = @_;
    my $code = $TIMEOUT{$time} or return 0;
    $self->command($code);
}

{
    for my $key (keys %COMMANDS) {
        no strict 'refs';
        *{$key} = sub {
            my $self = shift;
            my $code = $COMMANDS{$key};
            if (ref($code) eq 'ARRAY') {
                my $flag = shift;
                $code = $code->[((!defined $flag || $flag) ? 0 : 1)];
            }
            $self->command($code, @_);
        };
    }
}


1;
__END__

=head1 NAME

Device::VFD::GP1022 - GP1022 VFD module controller

=head1 SYNOPSIS

  use Device::VFD::GP1022;

  my $vfd = Device::VFD::GP1022->('/dev/ttyUSB0');
  $vfd->message( 'messages for vfd' );

use to orignal serial module

  use Device::VFD::GP1022;
  use Device::SerialPort;

  my $serial = Device::SerialPort->new('/dev/ttyUSB0') or die;
  # more serial port configs
  my $vfd = Device::VFD::GP1022->( serial => $serial );
  $vfd->message( 'messages for vfd' );

=head1 DESCRIPTION

this module is controller for VFD module of GP1022. 
It works for Unix, Mac, and Windows. 

=head1 METHODS

=over 4

=item new

instance

=item message

文字列を引数にあたえると、その文字列をVFDに表示します。
L<Device::VFD::GP1022::Message>をuseする事で利用できるDSLを使用して、細かな表示制御を行えます。

特殊な呼び出しかたにより挙動を変更できます。

    $vfd->message( append => 'for vfd' );

表示中の文字列に続けて表示します。

    $vfd->message( 'for vfd' );
    $vfd->message( force => 'for vfd' );

表示中の文字列を捨てて、即時表示します。

    $vfd->message( buffer => 'for vfd' );

バッファーに文字列を蓄えます。別途 switch メソッドにてバッファを切り替えられます。

=item is_scroll

現在スクロール表示中なら真を返します。

=item display

  $vfd->display;
  $vfd->display(1);

表示開始する。

  $vfd->display(0);

表示停止する。

=item scroll

  $vfd->scroll;
  $vfd->scroll(1);

スクロール開始する。

  $vfd->scroll(0);

スクロール停止する。

=item switch

switch to buffer

=item rewind

表示内容を頭出しします。

=item full

画面領域全てを使ってメッセージを描画させます。

=item reverse

点滅時のバックグラウンドとフォアグラウンドを切り替えます。

  $vfd->reverse;
  $vfd->reverse(1);

切り替える。

  $vfd->reverse(0);

デフォルトに戻す。

=item clear

表示データ全てをクリアします。

=item default

全ての状態をデフォルトに戻します。

=back

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

=head1 SEE ALSO

L<Device::VFD::GP1022::Message>
L<http://akizukidenshi.com/pdf/GP1022.pdf>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

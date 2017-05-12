#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Device::MiniLED;

plan tests => 17;

sub endtoend {
    my $sign=Device::MiniLED->new(devicetype => 'sign');
    my $pix=$sign->addPix(
        clipart => 'cross16'
    ); 
    my $icon=$sign->addIcon(
        clipart => 'smile16'
    );
    $sign->addMsg( data => "Plain Text", effect => 'scroll', speed => 2);
    $sign->addMsg( data => $pix, effect => 'hold', speed => "3");
    my $check=$sign->addMsg( data => $icon, effect => 'snow', speed => 5);
    ok($check eq "3", "Third message created returned 3");
    my $result=$sign->send(device => '/dev/null', debug => 1);
    my $length=length($result);
    ok ($length == 970, "Expected 970 bytes, Got $length Bytes");
    my @checksums = qw (9f 77 b7 f7 5f 78 b8 f8 a5 79 b9 f9 db fa);
    #my @checksums = qw (9f 77 b7 f7 5f 78 b8 f8 a5 79 b9 f9 db ff);
    for (my $i =0; $i <= 13; $i++) {
        my $checksum=$checksums[$i];
        my $offset=($i+1)*69;
        my $byte=sprintf("%x",ord(substr($result,$offset,1)));
        ok( $checksum eq $byte, "Checksum number:${i} $byte == $checksum");
    } 
  
}
sub clipart {
    my $clipart=Device::MiniLED::Clipart->new(type => 'pix');
    $clipart->set(name => 'heart16');
    my $data=$clipart->data; 
    my $compare="000000000000000000000000000000000000000000000000000".
                "000000000000000001100011000000001001010010000001000".
                "010000100000100000001010000010000000001000000100000".
                "001000000010000000100000000100000100000000001000100".
                "0000000000101000000000000001000000000000000000000000";
    ok ($data eq $compare, "Clipart Data Matched Reference Data");
}

endtoend();
clipart();

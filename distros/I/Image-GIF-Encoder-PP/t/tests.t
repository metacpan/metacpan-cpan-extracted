#!/usr/bin/perl

# Copyright (c) 2021 Gavin Hayes, see LICENSE in the root of the project

use strict;
use warnings;
use FindBin;
use Image::GIF::Encoder::PP;
use Test::Simple tests => 2;
use MIME::Base64 qw(decode_base64);

sub generate_flag_gif {
    my ($outputfilename) = @_;
    my @pallete = (0x0000, 0x0010, 0x0200, 0x0210, 0x4000, 0x4010, 0x4200, 0x4210, 0x6318, 0x001F, 0x03E0, 0x03FF, 0x7C00, 0x7C1F, 0x7FE0, 0x7FFF);
    my @imdata = (
    [
     15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15
     ,15, 0, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15
     ,15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 15, 15, 15, 15, 0, 15
     ,15, 0, 15, 15, 0, 0, 15, 15, 0, 0, 0, 0, 0, 0, 0, 15
     ,15, 0, 0, 0, 15, 15, 0, 0, 15, 0, 15, 15, 0, 0, 0, 15
     ,15, 0, 0, 0, 15, 15, 0, 0, 15, 15, 0, 15, 0, 0, 0, 15
     ,15, 0, 15, 15, 0, 0, 15, 15, 0, 15, 0, 0, 15, 15, 0, 15
     ,15, 0, 15, 15, 0, 0, 15, 15, 0, 0, 15, 0, 15, 15, 0, 15
     ,15, 0, 0, 0, 15, 15, 0, 0, 15, 0, 15, 15, 0, 0, 0, 15
     ,15, 0, 0, 0, 15, 15, 0, 0, 0, 15, 0, 15, 0, 0, 0, 15
     ,15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 15, 15, 0, 15
     ,15, 0, 15, 15, 15, 15, 15, 15, 15, 15, 0, 0, 0, 0, 15, 15
     ,15, 0, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15
     ,15, 0, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15
     ,15, 0, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15
     ,15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15
    ],
    [
     15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15
     ,15, 0, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15
     ,15, 0, 0, 0, 0, 0, 15, 15, 15, 15, 0, 0, 0, 0, 15, 15
     ,15, 0, 15, 15, 0, 0, 0, 0, 0, 0, 15, 15, 0, 0, 0, 15
     ,15, 0, 0, 0, 15, 15, 0, 15, 0, 0, 15, 15, 0, 0, 0, 15
     ,15, 0, 0, 0, 15, 0, 15, 15, 0, 15, 0, 0, 15, 15, 0, 15
     ,15, 0, 15, 15, 0, 0, 15, 0, 15, 15, 0, 0, 15, 15, 0, 15
     ,15, 0, 15, 15, 0, 15, 0, 0, 15, 0, 15, 15, 0, 0, 0, 15
     ,15, 0, 0, 0, 15, 15, 0, 15, 0, 0, 15, 15, 0, 0, 0, 15
     ,15, 0, 0, 0, 15, 0, 15, 15, 0, 15, 0, 0, 15, 15, 0, 15
     ,15, 0, 0, 0, 0, 0, 15, 0, 15, 15, 0, 0, 0, 0, 0, 15
     ,15, 0, 15, 15, 15, 15, 0, 0, 0, 0, 15, 15, 15, 15, 0, 15
     ,15, 0, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15
     ,15, 0, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15
     ,15, 0, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15
     ,15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15
    ]);
    
    my $PALETTE = '';
    my $red_mask = 0x1F;
    my $green_mask = 0x3E0;
    my $blue_mask = 0x7C00;
    my $ti = -1;
    my $i = 0;
    foreach my $rgb555 (@pallete) {
        my $red = ($rgb555 & $red_mask) << 3;
    	my $green = (($rgb555 & $green_mask) >> 5) << 3;
    	my $blue = (($rgb555 & $blue_mask) >> 10) << 3;
        $PALETTE .= pack('CCC', $red, $green, $blue);
        if(($rgb555 == 0) && ($ti == -1)) {
            $ti = $i; 
        }
        $i++;
    }
    
    my $scale = 4;
    my $calcscale = $scale;
    $calcscale = 1/(-$calcscale) if($calcscale < 0);
    
    my $w = 16 * $calcscale;
    my $h = 16 * $calcscale;
    
    my $gif = Image::GIF::Encoder::PP->new($outputfilename, $w, $h, $PALETTE, 4, 0, $ti);
    $gif or die("fail to open gif");
    my $unscaled = '';
    vec($unscaled, 256-1, 8) = 0;
    for my $frame (@imdata) {
        if($scale != 1) {
            $unscaled = pack('C256', @$frame);
            if( ! Image::GIF::Encoder::PP::scale($unscaled, 16, 16, $scale, \$gif->{'frame'})) {
                die("failed to scale");
            }
        }
        else {
            $gif->{'frame'} = pack('C256', @$frame);
        }
    
        #$gif->{'frame'} = pack('C256', @$frame);
        #say "imdata";
        #say "--------------------------------------";
        #Dump($gif->{'frame'});
        #Dump($gif->{'back'});
        #say "--------------------------------------";
        $gif->add_frame(32);
        #say "--------------------------------------";
        #Dump($gif->{'frame'});
        #Dump($gif->{'back'});
    }
    undef $gif;
}

sub generate_transparent_gif {
    my ($outputfilename) = @_;
    sub MIN {
        my ($a, $b) = @_;
        return ((($a)<($b))?($a):($b));
    }
    
    sub add_frame {
        my ($gif, $delay) = @_;
        my $height = 100;
    	my $width  = 100;
    
    	for(my $i = 0; $i < $height; $i++) {
    		for(my $j = 0; $j < $width; $j++) {
                my $char = vec($gif->{'frame'}, ($i*$width) + $j, 8) ? 'Z' : ' ';
    			print $char;
    		}
    		print "\n";
    	}
    
    	print "\n";
    	$gif->add_frame($delay);
    }
    
    my $gif = Image::GIF::Encoder::PP->new($outputfilename, 100, 100, pack('CCCCCC', 0xFF, 0xFF, 0xFF, 0xDA, 0x09, 0xFF), 1, 0, 0);
    my $frameindex = 0;
    for (my $t = 0; $t < 100; $t++)
    {
    	# clear the frame
        $gif->{'frame'} = pack('x10000');
    
    	# add the giant rectange to the frame on the left
    	for (my $i = 0; $i < 100; $i++) {
            for (my $j = 0; $j < 100; $j++) {
                vec($gif->{'frame'}, ($i*100)+$j, 8) = $i > 10 && $i < 90 && $j > 10 && $j < 50;
            }
        }
    		
    	# add the varying size right bar
    	for (my $i = 50; $i > 0; $i--) {
            for (my $j = 60; $j < 65; $j++) {
                vec($gif->{'frame'}, ($i*100)+$j, 8) = $i > MIN($t, 100 - $t);
            }
        }
    		
        print sprintf("frame %03d: \n", $frameindex++);
    	add_frame($gif, 5);		
    }
    undef $gif;
}

sub run_gif_test {
    my ($test, $outfilename) = @_;

    $test->{generate}($outfilename);

    my $expectedflag = decode_base64($test->{'expected_b64'});
    my $flagfh;
    if(! open($flagfh, '<', $outfilename)) {
        warn('unable to open flag file');
        return 0;
    }
    my $newflag;
    read($flagfh, $newflag, length($expectedflag)+1);
    if((! defined $newflag) || (length($newflag) != length($expectedflag))) {
        warn('unable read flag file');
        return 0;
    }
    if($expectedflag ne $newflag) {
        warn('flags are not equal');
        return 0;
    }
    return 1;
}

 # Declare the tests
my @tests = (
{
    'generate' => \&generate_flag_gif,
    'expected_b64' => 'R0lGODlhQABAAPMAAAAAAIAAAACAAICAAAAAgIAAgACAgICAgMDAwPgAAAD4APj4AAAA+PgA+AD4
+Pj4+CH/C05FVFNDQVBFMi4wAwEAAAAh+QQJIAAAACwAAAAAQABAAAAE//DJSau9OOvNu/9gKI5k
aV5ACpxsp65tjL1yXdF2/u587/MgnOVHLAI/wptxSQyqZszo0ZOkVCc+qLSJenanyu1PCxv2yGKw
1WtWY9PZ71ievEqM6DOd/bD3i3lud3qDKYE7h35xhWVhc22Pjop8eHuCf5d1gJaInGRrXJCLknyg
jZWQh59vmaWsjaaThq+ysK+qcrGujKuiu5inhI69pLO+xsDEprjHwcjLuZ7SvNGp08XOttTNtZrP
tMK6rWDd4eDjndvY5eje2sCj4unrlPWh9N+Mo+7x5/Py7gD+QoUvm8B88OCkUeZPYRSG+hxugZhQ
4sNqw3JUjESRhRQOfjc8XtQQ8sTHDSU1jkipMgTLlkh+wRTxciZImTZjIsyp8x1PKjh/ogwqNEPN
ohmRKl3KtKlTpREAACH5BAUgAAAALAAAAABAAEAAAAT/8MlJq7046827/2AojmRpXkAKnGynrm2M
vXJd0Xb+7vwO9kCYJkgUuoq4IbL3W6Y4Tl7TCVXNosArUWukYLOoIpf7tYa35+6kLE2DLcjxmumm
w8Vpr/2Gv6P9Rm98f4NBchKCeoSKhnNPeY4+kICCSYWMloxke5mRmGaAm22IoJeRnaSPoXWqD6iu
e5qThZaviZ6zn622sbirlKW8o6a/xLDDwo3FsqmSzaLOxszH0cm3z7OVpbrR3Mnc0Na92M3iw97b
vtTm3afj1OCs7eWc6eTr9vDytfn85+rodvUL9o6dPzX3rukDRgWgu4YMl0wLqIxWlIkPJe7rs9Ai
RGkbQLBMQdixykeTJF+Fe3cIpJKTIQe2yhFDJU0SNm+KyKlzZM+a+X6G4CkUZdETRI9mSKo0V9MP
TJ9KnUq1qlWhEQAAOw==',
},
{
    'generate' => \&generate_transparent_gif,
    'expected_b64' => 'R0lGODlhZABkAPAAAP///9oJ/yH/C05FVFNDQVBFMi4wAwEAAAAh+QQJBQAAACwAAAAAZABkAAAC
/4SPqcvtD6OctK6Asd2816x54kiCAYmmH6i2LmO+shzPdlrfupfv/pr5CSm9IcCETCqXrEZxyIxK
kY6ncIqVVptGQ/ar3Aa7XrB5DON2z2xxiMw+u0/kYxw8r9vv2Xyd/+UHB4gluEY4ZWiEmOiktsgY
pQgVyTR5Vbl0+ZOp6Yh22En1+RYq+phgxXmqWgYKyfqaiooZW6rQumMri5Crs3s7y7u6u+kDTJc2
fAxsrNtMmmwa6/wLrRxca1t9g8xt4x2tF44tDbst/nd9QUuMXj6+jtvOXJw+aA+vnq8HQd7/4B/A
aKwG+pNncB6/hArfMWxI7SG7hRJdOaxoMSLGA1MCMXas+FFiyIcjGZZMeNJgyoErAbbs9zIeRZAI
ac4UWRPnTZI5ee402RPoT5RBiQ5VWRTpUZZJmS512RTq041Uq1q9ijWr1q1cu3r9CjasWAQFAAAh
+QQJBQAAACwLAAIANgBYAAAC1YSPqcuNAaGbtJ4ord4X829hAUg6YokqZ8oCa4u+MCnW9o3jZs73
+e4LCoHC4q9hTOqQyqaH6XQSo8kptWi9BrPaHrd7ZICN37GtbJap0j40OyN+89xvOtuexpv1Yz7Y
3wWoJXhFSGUYhSgFJXej2PSoFFnF2FgzSVZp+RS3eanpOQLqiYkVEqoRKlqhmop6Sgq76RrL+mpb
S9Eqa0k7y9vo2wssJxxMXId8p5zHvOfcB/0nHUg9aF2IfaidyL2I+ws+LH5MXuwNiS6pTmme7L4M
31xRAAAh+QQJBQAAACwLAAMANgBXAAAC0oSPqcuNAaGbtJ4ord4X829hAUg6YokqZ8oCa4uK8kzX
tWnnuo3v/t/7CXmNofFWPCo9yeUy6DRCo8Ip1We96rJaIqM75IJn4vFrYcY20140O1d+x9nzdN18
H+fB+25f+3cVSDUYVeh0+LT2RrbIeKbySJOoRHlkKeUomfG1KYMZprmp4TkS4kmKejq6KpnKWlH6
6tr6OGtby3irmyvXS/drF4w3rFfMd+yXDLgs2Ez4bBiNOK0Yq3oNSyFbXdl9+Z2ZTTuOW8577psO
vC7cTlxRAAAh+QQJBQAAACwLAAQANgBWAAAC0ISPqcuNAaGbtJ4ord4X829hAUg6YokqZ8oC4gvH
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
ybkpWGSJKJr16DKqieqpCrpE+UlI9soaazZbesuV67UL1iv2K0uqO8xb7HsMnCycirts+4wWDN1M
nFgAACH5BAkFAAAALAsACwA2AE8AAAK4jI+pywcPo2y0Nomj3TxDDoLeE5bVCJjqgq6uM75vK690
bd54qO9d7OMBgz8PUTQ8npLKC7PJekITvSlVajVUs1psdssFf71WcZk8NafRUHWb3XTH4Up5nX60
5/FEfZ8f5BeIosEVQFgYhkhiuMiouGh46CjpmNJIiRmpiViZCdnJSei5CToqKjjzOVbKGmqa6mJJ
+up6Cguo2nq2u9b79jsXfDe8V/x3PJjsM4uaK7vKWyt9a4tSAAAh+QQJBQAAACwLAAsANgBPAAAC
uIyPqcsHD6NstDaJo908ew5S3hOW1QiY6oKurjO+byuvdG3eeKjvXezjAYO/D7GYOSIxyk2vyRpC
Gc8pomo1YLNba3f6hYabY2X5eCamg2tfe/fGxWtzWX0mzV7zei2/f+cSaIOiAVgI0ReAmHjIqMhI
4ogIGVn5OFl4SZk5uOTpZNn5RyaqF5kyanRqytXq9QoWKzZbisl665oLuyvbS/try4k7rFvMe+yb
DLwsrKmaBM0kPUEdUQAAIfkECQUAAAAsCwALADYATwAAAriMj6nLBw+jbLQ2iaPdPHsOUl4WlsoI
mOqCrq4zvm8rr3Rt3nio713s4wGDvw+xSDpuekoGs3kaQp3SadRoZVWzMCwX8eSGs2NreXqGpptr
Zfv4JsaDc199d8fla3tZf7b19eeCMiFYCPEVgJh4yKjI+AAZOfnoiFiJeVmYybk5CBKZ8hnIRknq
ZXYqtkrWqmrJGus6C6spe0uba+uJ26v7ywuKFIz2alyLvKtcrHbsnAy9LN1sylgAACH5BAkFAAAA
LAsACwA2AE8AAAK4jI+pywcPo2y0Nomj3Tx7DlJeFpbKiJmqga6uM75vK690bd54qO9d7OMBg78P
sUg6bnpKBrN5GkKd0mnUaF08s4Ft1msFT8VQctOsRB/VRHbQ7YPv5Dh6zS7Dz6pcFr+v5xJog6IB
WAjR14X4oMjYeMjo+DgpGYlYiXlZmMm5OYjkyfUI0Am6RPn5d5Y62vr1GhY7NltWy2rpmgu7K9tL
+2sbjKupW8x77JsMvCzcTCyKHK08zVxYAAAh+QQJBQAAACwLAAsANgBPAAACt4yPqcsHD6NstDaJ
o908ew5SXhaWyoiZqoFOq4m+chDPa23DY67iPOj7bYLCCrF42SGHyqWx6Ux+oiIo9WS9Io5aWrbr
nYK33y5Xe76mqeto2/lexpHzYl14/+V5+1zf9jcTKDP40qIBdggxpvjA2PioGHk42VJZCASZqGnG
ieapBsom6kYKZyqHSqdqx4rnqgfLJ+tHC2griEuoa8h749sDrCO5Sdxp/IkcqjzKXOp8Cp0qvapY
AAAh+QQJBQAAACwLAAsANgBPAAACuIyPqcsHD6NstDaJo908ew5SXhaWyoiZqoFOq9lqb4nOc22v
eA6PvLr7gYLCDbFYOSIvvqWx6UxCo8wPVTS9nrJahLIb+HbFWvLVTEVH1U720o2EF+VC+s/Ow+f0
Nv6NCxYGCOb3EgMRKHiYePjA2Pi4GNgIEBlj2YJZOAQ52Un4ORZaNnpWmna6ltq2+tYa9zoXWzd7
V5t3u5fbt/snCforGkw6bFqMeqyazLrs2gz7LBtNO217WAAAIfkECQUAAAAsCwALADYATwAAArqM
j6nLBw+jbLQ2iaPdPHsOUl4WlsqImaqBTqvZam8ZQzM93i+qr3wPywFxn2HoZ+wIkxsks+J8XpbS
abFqJWGzqS0j6nVQw+Iruaw9o7tq1vgMJsfDc299e8fmq3tp//nHFJg0aFQ4dAhU8wC32FjzGBPZ
Mpno4yiHSadpx4nnqQfKJ+pHCmgqiEqoasiK6KoI27MIUPk2CpmZu7nb2fv5GxqMK6lbzHvsmwy8
LNxMTGkcjTytXM3cUgAAIfkECQUAAAAsCwALADYATwAAAriMj6nLBw+jbLQ2iaPdPHsOUl4WlsqI
maqBTqvZam8ZQzNdA3eI7mvvg42Cwg+RNzyCgMoNs1l5Qi/JqahqZUiziS3Xgf0ivGLy18xFZ9VW
9tQNhTflSvrRTsQH9T7+zn8DOCP4QviTI8aCmJijw7hYBnkmmUa5ZtmG+aYZxznnWQd6J5pHumfa
h/qnGsg66FoIe1iTGNBYe/tIqxuDK6uSG7kr3Mvb4js8mVy5fNmc+bwZ3Tn9WVMAACH5BAkFAAAA
LAsACwA2AE8AAAK4jI+pywcPo2y0Nomj3Tx7DlJeFpbKiJmqgU6r2WpvGUMzXQN3mOt7N/qpUEJY
sMg7IoGfJZPk3BCjlilVpLwyrNoFt5v4gh3ZMblpRojN63Eb/O7GtfNrnXqP5p37ZR/5VxQoNPhT
uHN405O2yJbD+OhYAzkpGUN5admCuamZiFPpFikaCjdqWip3qppKt+raavcqG4s3a1urd6uby7fr
2+v3KxwMOGxcLHisnEy47Nxs+CwdjZhTAAAh+QQJBQAAACwLAAsANgBPAAACuIyPqcsHD6NstDaJ
o908ew5SXhaWyoiZqoFOq9lqbxlDM10Dd5jre5f7AT9CHLEIQiF5o2Wy6dwoo5YpVQS9XrLahbV7
4oIR37FDbA6U02tze/wGx7tzbf16p+aje2d/+YcUWDQoVPhzuNPDFuTWCPcoF0k3aVeJd6mXybfp
1wn4KRhKOGpYiniqmHqz6FjD+OoaAzsr20J7a5sIszrTChkLXCucS7xrNCwZrJxMuezcbPksHY1Z
UwAAIfkECQUAAAAsCwALADYATwAAArmMj6nLBw+jbLQ2iaPdPHsOUl4WlsqImaqBTqvZam8ZQzNd
A3eY63uX+wFrwg2qiPsgQcflkOQ0jqJSJVU0vWKt2kWz682CT+Ix4mt2lNMBNNudhpvlYzrY3sVr
9Vc+1R8F6CS4RIhkWIQo1BMXNOdYB3knmUe5Z9mH+acZyDnoWQh6KJpIumj6w/hItBrTyBoJOylb
SXtpm4m7qdvJ++kbCjwqXEp8apyKuqMa69ra8urcDP2suNJTAAAh+QQJBQAAACwLAAsANgBPAAAC
uYyPqcsHD6NstDaJo908ew5SXhaWyoiZqoFOq9lqbxlDM10Dd5jre5f7AWvCTa9oQSF5oyVI6TQ2
o8kpVWS9MqDabbab4ILD3zGrbBabz581Qr2Gp9FjeZ0OtufxXX2fr+UXCHglWEhIZZgYNEfUGBPH
eOc4CfnYEkm5p/nHOeh5CLooGnV0qShkWol5ipgquWm5ivqjGss661oL2yl7S7tj24v7qxvM++k7
DHwjnEy8bNyMHKr8jFIAACH5BAkFAAAALAsACwA2AE8AAAK5jI+pywcPo2y0Nomj3Tx7DlJeFpbK
iJmqgU6r2WpvGUMzXQN3mOt7l/sBa8JNr2g5IkWjJQjlHJKiySa1Ar0yP9qLtbvIgk/fMUJsdpTT
ATTbnYab5WM62N7Fa/VXPtUfBegkuESIZFiEKKRUFzTn2Ej0KBkZEwd5h5mnucfZ5/kHGig6SFpo
eoiaqLrI+sOYSRlrOUlb2XIpu6nbyfvpGwo8KlxKfGqciryq3Mr86roDu2s7i1vbUgAAIfkECQUA
AAAsCwALADYATwAAArqMj6nLBw+jbLQ2iaPdPHsOUl4WlsqImaqBTqvZam8ZQzNdA3eY63uX+wFr
wk2vaDkiRcHlZeQckqJJKLWCumKtWka26+WCE98xWWxmodPltPrjdqzNbXedPR/f6XnwXt/X9ecX
qDUoWHh1aNgESMT36BiDF0lYiXjJmKnYaDkJ+SnZQhnqOQp6KrqIpKSaWNRqugrbiVlqmyr7KhSL
O8tbq3krnOu7+9NL/IsczLlJlew8LF2sfLzTUwAAIfkECQUAAAAsCwALADYATwAAArqMj6nLBw+j
bLQ2iaPdPHsOUl4WlsqImaqBTqvZam8ZQzNdA3eY63uX+wFrwk2vaDkiRcHlpelcoKLGETVpvTI/
2ie3K82CT+IxYmpOoNOOMnvNDsDf7vTcXjff9fnx3t8H9icY2DVoWKh1qAhFSMT3CBjpGIM3iXjJ
mHmlJFkJ+enZYhlKOQp6KrqI1Gm6WtSKWSqb6prI2kj7KhSrOetbq3sLmwu8+9PLWay8SZXsvAzd
HPVMHW1dUwAAIfkECQUAAAAsCwALADYATwAAAruMj6nLBw+jbLQ2iaPdPHsOUl4WlsqImaqBTqvZ
am8ZQzNdA3eY63uX+wFrwk2vaDkiRcHlpelcKKOnETVpvTI/2ie3K82Cq98xAmUmk9JnMTuAfrPc
7Ljc/sbX6Wl9n2/mFwg4JlhICGaYiNg1tUg0CHko+RjzR9kIVdlyaRnpOQm6qejkmImpZZqqeSra
yvkJGyo7yrikeoVLpRvFW8q6ipoLPCy8S3xs3Iu8rPzrfMv87BpMXWydHFMAACH5BAkFAAAALAsA
CwA2AE8AAAK6jI+pywcPo2y0Nomj3Tx7DlJeFpbKiJmqgU6r2WpvGUMzXQN3mOt7l/sBa8JNr2g5
IkXB5aXpXCijJygVgbpWstrnp8vggqvfcUJsdozS5zVbXX6j2fN03Xwf58H7bl/7dxVINRhV6HS4
lIg0xWfl9wgYKThJWGl4iZipuMnYWdQISYT3KRQqOapX+nNKmer4Khpjt7rTahmLOkua67qr2ov7
Czss20IbjJmsuczZ7PkMWntzq1ys21IAACH5BAkFAAAALAsACwA2AE8AAAK7jI+pywcPo2y0Nomj
3Tx7DlJeFpbKiJmqgU6r2WpvGUMzXQN3mOt7l/sBa8JNr2g5IkXB5aXpXCijJygVMb06Rlrmp8tA
gcPccfVrxpbTWzQ7IH6z1u+43F6ns/F7fZr/52cGOCg4RnhoCIa4aNWV9eioBTkpeUV5aUmFuakZ
xfnp6QQ6KrpEemqKhLqqWsT66ioEOyv7Q3tru4O7q3vD++s7Azws/EJ8bLyCvKyswvzsDCONQ1Ro
nVhTAAAh+QQJBQAAACwLAAsANgBPAAACvIyPqcsHD6NstDaJo908ew5SXhaWyoiZqoFOq9lqbxlD
M10Dd5jre5f7AWvCTa9oOSJFweWl6VwooycoFTG9OqzaAKr7/IClozFZbMaW02o027t+w93sr3xO
utvl+3e/HucXCEiX9mc4iFhodsjIpZXVFQn5eDVpWUl1qZkZtenZ6fQpGro0alqKdKqaWrTq2ir0
Khv7M2tbu3Orm3uz69s78ysc/DJsXLxyrJyssuzcDBONQ+RYPfYsXVMAACH5BAkFAAAALAsACwA2
AE8AAAK8jI+pywcPo2y0Nomj3Tx7DlJeFpbKiJmqgU6r2WpvGUMzXQN3mOt7l/sBa8JNr2g5IkXB
5aXpXCijJygVMb06rNpAtovqPj9i6ahsJqOx5zVb7fa243K4O0yvk/J4ej/+dzcHOChotxaIWKh4
iPal9XgVSTUZVel0uZSJtFnUKfT5E7ozelM6c/qSurKq0grDBRkrOUtZa3mLmau5y9nr+QsaLDpM
Wmx6jJqsusza7PoMS+QYjTNd9modUwAAIfkECQUAAAAsCwALADYATwAAAryMj6nLBw+jbLQ2iaPd
PHsOUl4WlsqImaqBTqvZam8ZQzNdA3eY63uX+wFrwk2vaDkiRcHlpelcKKMnKBUxvTqs2kC2+9Wi
us8PWTo6o81qbLrtZsO97zldDh/b76S93v43F5hXJ1hIiNc2qHjISKQWdhVJNRlV6XS5lIm0WdQp
9PkTujN6Uzpz+pK6sqrSCsMlFis5S1lreYuZq7nL2ev5CxosOkxabHqMmqy6zNrs+gz7ePaKM01W
zZNTAAAh+QQJBQAAACwLAAsANgBPAAACvIyPqcsHD6NstDaJo908ew5SXhaWyoiZqoFOq9lqbxlD
M10Dd5jre5f7AWvCTa9oOSJFweWl6VwooycoFTG9OqzaQLb71YavqO7zY5aO0mo0G7t+w91yb7xu
p8vL+Dypz4cXWDe4d0d4aKj3VsjIJfZIFkk1RjkZVYl56ZTJubnUCfqJFEo6WlSKeiqUyrr60wr7
uhNLO3tTi3s7k8u7+9IL/LsSTDysUox8DLOMQ8SWzPycFu0c4zht1lMAACH5BAkFAAAALAsACwA2
AE8AAAK8jI+pywcPo2y0Nomj3Tx7DlJeFpbKiJmqgU6r2WpvGUMzXQN3mOt7l/sBa8JNr2g5IkXB
5aXpXCijJygVMb06rNpAtvvVhq9jKqr7/KClozVb7ca243I43Tu/4+30s35P8uenN3hX2JdnmIjI
F1cW9egUuTSJVFl0KZT5s7nTefM5E/oyulKqcgrDJbZK1mr2ChkrOUtZa3mLmau5y9nr+QsaLDpM
Wmx6jJqsSuSWitO89syzDB3jWE1dUwAAIfkECQUAAAAsCwALADYATwAAAryMj6nLBw+jbLQ2iaPd
PHsOUl4WlsqImaqBTqvZam8ZQzNdA3eY63uX+wFrwk2vaDkiRcHlpelcKKMnKBUxvTqs2kC2+9WG
r2NqOYrqPj9q6ajtZsOx7zldbvfW83q8Pc3XRxIIyFeYd/i3h7ioSAR35hS5NIlUWXQplPmzudN5
8zkT+jK6UqpyCsMltkrWavaKFis5S1lreYuZq7nL2ev5CxosOkxabHqMmqz62JaK06z2zLMMHTM3
DdJTAAAh+QQJBQAAACwLAAsANgBPAAACvIyPqcsHD6NstDaJo908ew5SXhaWyoiZqoFOq9lqbxlD
M10Dd5jre5f7AWvCTa9oOSJFweWl6VwooycoFTG9OqzaQLb71YavY2o5enaius8PWzp6w91ybLxu
p+O99z1fj7fm90cyKOh3uJcY2KfIJfZIFmk2iVapdrmUppmJtOnZWfQpGio0alr6c6qaurPq2nrz
Khs7M2tb+3Krm7uy69ur8iscDFOMQyQ3bJz8towcU/fMc0zdzDYN0lMAACH5BAkFAAAALAsACwA2
AE8AAAK8jI+pywcPo2y0Nomj3Tx7DlJeFpbKiJmqgU6r2WpvGUMzXQN3mOt7l/sBa8JNr2g5IkXB
5aXpXCijJygVMb06rNpAtvvVhq9jajl6dqaXqO7z45aO4nI4HTu/4+16b77vx6fXBhhIUkgImNi3
OMgl9kgWaTaJVql2yZaJtMa5WdQJ+ikUSjr6U4p6upPKunrTCvs6E0s7+1KLe7uSy7ur0gv8CzOM
Q0QXTHwcl2wcc9fMUyy97BYNcj0UUwAAIfkECQUAAAAsCwALADYATwAAAryMj6nLBw+jbLQ2iaPd
PHsOUl4WlsqImaqBTqvZam8ZQzNdA3eY63uX+wFrwk2vaDkiRcHlpelcKKMnKBUxvTqs2kC2+9WG
r2NqOXp2ppdrJKr7/MClozldbsfW83o837v3B+jH9yY4SHJoKLj411b0KBT5M7lTeXM5k/myudKp
8gnDJTZKVmp2ipaqtsrW6vYKGSs5S1lreYuZq7nL2ev5CxosSmQXilM8d8wzjByTtwwSPfRs3Myc
DNdTAAAh+QQJBQAAACwLAAsANgBPAAACvIyPqcsHD6NstDaJo908ew5SXhaWyoiZqoFOq9lqbxlD
M10Dd5jre5f7AWvCTa9oOSJFweWl6VwooycoFTG9OqzaQLb71YavY2o5enaml2tku4jqPj9y6ahu
p+Ox9z1f7+fVFygI6BdHWEiSiEj4JvT4E7kzeVM5c/mSubKp0gnDJRZKNmpWinaqlsq26tYK9woZ
KzlLWWt5i5mrucvZ6/kLSoT3iTNcV8wTbByzlwzyPNRMvKx8LBdtlFMAACH5BAkFAAAALAsACwA2
AE8AAAK8jI+pywcPo2y0Nomj3Tx7DlJeFpbKiJmqgU6r2WpvGUMzXQN3mOt7l/sBa8JNr2g5IkXB
5aXpXCijJygVMb06rNpAtvvVhq9jajl6dqaXa2S7+Baius8PXTq64+16bL7vxwfo9TdIKAg4Z3hI
shj387gTeTM5U/lyuZKpsgnDJfZJFmo2ilaqdsqW6rYK1yr3ChkrOUtZa3mLmau5y9nrSaTXiRN8
N8zzSxzTdwzSPLQsnIxcTPdsNO2cUwAAIfkECQUAAAAsCwALADYATwAAAryMj6nLBw+jbLQ2iaPd
PHsOUl4WlsqImaqBTqvZam8ZQzNdA3eY63uX+wFrwk2vaDkiRcHlpelcKKMnKBUxvTqs2kC2+9WG
r2NqOXp2ppdrZLv4FsZ/qO7zY5eO8no8H7v3B+gn6BVYaEgoWIeYGPM3txN5MzlT+XK5kqmyCcMl
9kkWajaKVqp2ypbqtgrXKvdKFys5S1lreYuZq7nL2etJxNeJE5w3zPNL/CicjFxsdwwSPbRs3Cx9
Td1SAAAh+QQJBQAAACwLAAsANgBPAAACu4yPqcsHD6NstDaJo908ew5SXhaWyoiZqoFOq9lqbxlD
M10Dd5jre5f7AWvCTa9oOSJFweWl6VwooycoFTG9OqzaQLb71YavY2o5enaml2tku/gWxn/zHar7
/OCloz1f74fVFygISOg1eIhoSFh34zgD+SK5QqliCcMlpknGaeaJBqomykbqZgqHKqdKx2rn+ggb
KTtJW2l7iZtJ5IeJw7vny6P7GxMoDII8ZNxLPAyMp2zknEy93HKcUwAAIfkECQUAAAAsCwALADYA
TwAAAruMj6nLBw+jbLQ2iaPdPHsOUl4WlsqImaqBTqvZam8ZQzNdA3eY63uX+wFrwk2vaDkiRcHl
pelcKKMnKBUxvTqs2kC2+9WGr2NqOXp2ppdrZLv4FsZ/8139huo+P3rpqO/HB4j1N0goaOhVmKhI
BHg3A/kiuUKpYgnDJaZJxmnmiQaqJspG6mYKhyqnSsdq54oHGyk7SVtpe4mb6diHicOr58uj+xsz
KAyCPGT8SDwMDOacLL3cckxtlFMAACH5BAkFAAAALAsACwA2AE8AAAK6jI+pywcPo2y0Nomj3Tx7
DlJeFpbKiJmqgU6r2WpvGUMzXQN3mOt7l/sBa8JNr2g5IkXB5aXpXCijJygVMb06rNpAtvvVhq9j
ajl6dqaXa2S7+BbGf/Nd/XafobrPD1868gfoJ4gVWGhIiOjFJdZI9mgWiTapVsl26ZYJtynXSfdp
F4o3qlf6kod6upLKuqrSCvsKM4tDJBhLe/uXaxtT2MtTK7zLFwxyPPSLO4zcrNwC/Gw0nVRd0VMA
ACH5BAkFAAAALAsACwA2AE8AAAK5jI+pywcPo2y0Nomj3Tx7DlJeFpbKiJmqgU6r2WpvGUMzXQN3
mOt7l/sBa8JNr2g5IkXB5aXpXCijJygVMb06rNpAtvvVhq9jajl6dqaXa2S7+BbGf/Nd/Xaf5V+o
7vPjJzUSKAhIiDV4iEhEuLfiqAIJwyVGSWZphommqcbJ5ukGCicqR0pnaoeKp6rHyuf6CBspO8kY
KIlj64fLQ5sbc8gLIjwE3OjbqwuGPMxc3BLsbCSdRF3RUwAAIfkECQUAAAAsCwALADYATwAAAriM
j6nLBw+jbLQ2iaPdPHsOUl4WlsqImaqBTqvZam8ZQzNdA3eY63uX+wFrwk2vaDkiRcHlpelcKKMn
KBUxvTqs2kC2+9WGr2NqOXp2ppdrZLv4FsZ/8139dp/lX/sVqvv0ASg1MkgoaIjFJbZI1mj2iBap
NslW6XYJlym3Sddp94kXqjfKV+p3qtKnmgrTikNkuOoaOzgLG5N4y/PKWwu4CxI8lCvbK3xM3KKb
bNSc9Fwx7PwLllMAACH5BAkFAAAALAsACwA2AE8AAAK4jI+pywcPo2y0Nomj3Tx7DlJeFpbKiJmq
gU6r2WpvGUMzXQN3mOt7l/sBa8JNr2g5IkXB5aXpXCijJygVMb06rNpAtvvVhq9jajl6dqaXa2S7
+BbGf/Nd/Xaf5V/7VV+F0vX0ISg1UmhIhPgHwyXmSAZpJolGqWbJhummCccp50kHaieKR6pnyofq
pwrI2qhYyIgDKyjL4zobg+iFe0sL1gtiKxw8pLtYbJSctFwxbNyy+6z8+1hTAAAh+QQJBQAAACwL
AAsANgBPAAACuIyPqcsHD6NstDaJo908ew5SXhaWyoiZqoFOq9lqbxlDM10Dd5jre5f7AWvCTa9o
OSJFweWl6VwooycoFTG9OqzaQLb71YavY2o5enaml2tku/gWxn/zXf12n+Vf+1Vf9Qcz0vX0QSjF
JZZItmjWiPaoFsk26VYJdymXSbdp14n3qRfKN+pXCngqSHTolYqzehj4GsPaCksoy+Oqewu2C5IL
/DtEyxpM3FJ7bDTM3Kv4zBjtOA1ZUwAAIfkECQUAAAAsCwALADYATwAAAreMj6nLBw+jbLQ2iaPd
PHsOUl4WlsqImaqBTqvZam8ZQzNdA3eY63uX+wFrwk2vaDkiRcHlpelcKKMnKBUxvTqs2kC2+9WG
r2NqOXp2ppdrZLv4FsZ/8139dp/lX/tVX/UHwyU20vVEZMgySLZo1oj2qBbJNulWCXcpl0m3adeJ
96kXyjfqVwp4KoiYGIizatjKk+oak6j4CjYri0vIy+jrCAwpLElMaWyJjKmsyczp7AkNKi1aUwAA
IfkEBQUAAAAsCwALACcATwAAAjmMj6nL7Q+jnLTai7PevPsPhuJIluaJpurKtu4Lx/JM1/aN5/rO
9/4PDAqHxKLxiEwql8ym8wmNSgsAIfkEBQUAAAAsPAAyAAUAAQAAAgKMXQAh+QQFBQAAACw8ADEA
BQABAAACAoxdACH5BAUFAAAALDwAMAAFAAEAAAICjF0AIfkEBQUAAAAsPAAvAAUAAQAAAgKMXQAh
+QQFBQAAACw8AC4ABQABAAACAoxdACH5BAUFAAAALDwALQAFAAEAAAICjF0AIfkEBQUAAAAsPAAs
AAUAAQAAAgKMXQAh+QQFBQAAACw8ACsABQABAAACAoxdACH5BAUFAAAALDwAKgAFAAEAAAICjF0A
IfkEBQUAAAAsPAApAAUAAQAAAgKMXQAh+QQFBQAAACw8ACgABQABAAACAoxdACH5BAUFAAAALDwA
JwAFAAEAAAICjF0AIfkEBQUAAAAsPAAmAAUAAQAAAgKMXQAh+QQFBQAAACw8ACUABQABAAACAoxd
ACH5BAUFAAAALDwAJAAFAAEAAAICjF0AIfkEBQUAAAAsPAAjAAUAAQAAAgKMXQAh+QQFBQAAACw8
ACIABQABAAACAoxdACH5BAUFAAAALDwAIQAFAAEAAAICjF0AIfkEBQUAAAAsPAAgAAUAAQAAAgKM
XQAh+QQFBQAAACw8AB8ABQABAAACAoxdACH5BAUFAAAALDwAHgAFAAEAAAICjF0AIfkEBQUAAAAs
PAAdAAUAAQAAAgKMXQAh+QQFBQAAACw8ABwABQABAAACAoxdACH5BAUFAAAALDwAGwAFAAEAAAIC
jF0AIfkEBQUAAAAsPAAaAAUAAQAAAgKMXQAh+QQFBQAAACw8ABkABQABAAACAoxdACH5BAUFAAAA
LDwAGAAFAAEAAAICjF0AIfkEBQUAAAAsPAAXAAUAAQAAAgKMXQAh+QQFBQAAACw8ABYABQABAAAC
AoxdACH5BAUFAAAALDwAFQAFAAEAAAICjF0AIfkEBQUAAAAsPAAUAAUAAQAAAgKMXQAh+QQFBQAA
ACw8ABMABQABAAACAoxdACH5BAUFAAAALDwAEgAFAAEAAAICjF0AIfkEBQUAAAAsPAARAAUAAQAA
AgKMXQAh+QQFBQAAACw8ABAABQABAAACAoxdACH5BAUFAAAALDwADwAFAAEAAAICjF0AIfkEBQUA
AAAsPAAOAAUAAQAAAgKMXQAh+QQFBQAAACw8AA0ABQABAAACAoxdACH5BAUFAAAALDwADAAFAAEA
AAICjF0AIfkEBQUAAAAsPAALAAUAAQAAAgKMXQAh+QQFBQAAACw8AAoABQABAAACAoxdACH5BAUF
AAAALDwACQAFAAEAAAICjF0AIfkEBQUAAAAsPAAIAAUAAQAAAgKMXQAh+QQFBQAAACw8AAcABQAB
AAACAoxdACH5BAUFAAAALDwABgAFAAEAAAICjF0AIfkEBQUAAAAsPAAFAAUAAQAAAgKMXQAh+QQF
BQAAACw8AAQABQABAAACAoxdACH5BAUFAAAALDwAAwAFAAEAAAICjF0AIfkEBQUAAAAsPAACAAUA
AQAAAgKMXQA7'
}
);

# run the tests
my $i = 0;
foreach my $test (@tests) {
    ok(run_gif_test($test, "$FindBin::Bin/$i.gif"));
    $i++;
}

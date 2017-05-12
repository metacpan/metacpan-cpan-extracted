use strict;
use Test::Base;

plan tests => 30;

use_ok 'HTTP::MobileAgent';
use_ok 'HTTP::MobileAgent::Flash';

filters {
    env      => ['yaml'],
    expected => ['yaml'],
    is_flash => [qw/chomp/],
};

run {
    my $block = shift;

    local *ENV = $block->env;
    my $agent = HTTP::MobileAgent->new();

    is $block->is_flash, $agent->is_flash, $block->name . ": is_flash";
    if ($block->is_flash) {
        while (my ($key, $value) = each %{$block->expected}) {
            is $block->expected->{$key}, $agent->flash->$key, $block->name . ": $key";
        }
    }
};

__END__
=== 922SH(SoftBank)
--- is_flash
1
--- env
  HTTP_USER_AGENT : SoftBank/1.0/922SH/SHJ001[ /Serial ] Browser/NetFront/3.4 Profile/MIDP-2.0 Configuration/CLDC-1.1
--- expected
  version        : 2.0
  max_file_size  : 150
  width          : 854
  height         : 480


=== W52P(au)
--- is_flash
1
--- env
  HTTP_USER_AGENT : KDDI-MA32 UP.Browser/6.2.0.12.1.4 (GUI) MMP/2.0
  HTTP_ACCEPT                    : application/x-shockwave-flash
  HTTP_X_UP_DEVCAP_SCREENPIXELS  : 240,268
  HTTP_X_UP_DEVCAP_SCREENDEPTH   : 1
  HTTP_X_UP_DEVCAP_ISCOLOR       : 0
--- expected
  version        : 2.0
  max_file_size  : 100
  width          : 240
  height         : 400


=== W22H(au)
--- is_flash
1
--- env
  HTTP_USER_AGENT : KDDI-HI33 UP.Browser/6.2.0.7.3.129 (GUI) MMP/2.0
  HTTP_ACCEPT                    : application/x-shockwave-flash
  HTTP_X_UP_DEVCAP_SCREENPIXELS  : 240,268
  HTTP_X_UP_DEVCAP_SCREENDEPTH   : 1
  HTTP_X_UP_DEVCAP_ISCOLOR       : 0
--- expected
  version         : 1.1
  max_file_size   : 100
  width           : 240
  height          : 320


=== W52P(au)
--- is_flash
1
--- env
  HTTP_USER_AGENT : KDDI-MA32 UP.Browser/6.2.0.12.1.4 (GUI) MMP/2.0
  HTTP_ACCEPT                    : application/x-shockwave-flash
  HTTP_X_UP_DEVCAP_SCREENPIXELS  : 240,268
  HTTP_X_UP_DEVCAP_SCREENDEPTH   : 1
  HTTP_X_UP_DEVCAP_ISCOLOR       : 0
--- expected
  version        : 2.0
  max_file_size  : 100
  width          : 240
  height         : 400


=== D506I(docomo)
--- is_flash
1
--- env
  HTTP_USER_AGENT : DoCoMo/1.0/D506i/c20/TB/W16H08 
--- expected
  version         : 1.0
  width           : 240
  height          : 320
  max_file_size   : 300


=== D405i(docomo)
--- is_flash
0
--- env
  HTTP_USER_AGENT : DoCoMo/1.0/D405i/c20/TC/W20H10


=== C5001T(au)
--- is_flash
0
--- env
  HTTP_USER_AGENT : KDDI-TS21 UP.Browser/6.0.2.276 (GUI) MMP/1.1

=== NONE_MOBILE
--- is_flash
0
--- env
  HTTP_USER_AGENT : Mozilla/5.0 (Macintosh; U; PPC Mac OS;)

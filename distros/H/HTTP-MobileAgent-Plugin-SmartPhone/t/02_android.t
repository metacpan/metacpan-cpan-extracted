use strict;
use warnings;
use Test::Base;

use HTTP::MobileAgent;
use HTTP::MobileAgent::Plugin::SmartPhone;

plan tests => 1*blocks;

filters {
    input    => [qw/chomp check_agent/],
};

sub check_agent {
    local $ENV{HTTP_USER_AGENT} = shift;
    my $agent = HTTP::MobileAgent->new;
    my $result = {};
    for my $meth (qw/is_android android_version android_full_version/){
        $result->{$meth} = $agent->$meth || undef;
    }
    $result;
}

run_is_deeply;

__DATA__
=== Android2.1
--- input
Mozilla/5.0 (Linux; U; Android 2.1_Hiapk; zh-cn; GT-I5700 Build/ECLAIR) AppleWebKit/530.17 (KHTML, like Gecko) Version/4.0 Mobile Safari/530.17
--- expected yaml
is_android: 1
android_version: 2.1
android_full_version: 2.1

=== Android2.3
--- input
Mozilla/5.0 (Linux; U; Android 2.3.4-r1; zh-cn; HTC Dream Build/FRF91) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1
--- expected yaml
is_android: 1
android_version: 2.3
android_full_version: 2.3.4

=== Android3.2.1
--- input
Mozilla/5.0 (Linux; U; Android 3.2.1; ja-jp; A500 Build/HTK55D) AppleWebKit/534.13 (KHTML, like Gecko) Version/4.0 Safari/534.13
--- expected yaml
is_android: 1
android_version: 3.2
android_full_version: 3.2.1

=== Android4.0.1
--- input
Mozilla/5.0 (Linux; U; Android 4.0.1; ja-jp; Galaxy Nexus Build/ITL41D) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30
--- expected yaml
is_android: 1
android_version: 4.0
android_full_version: 4.0.1

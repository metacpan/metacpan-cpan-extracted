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
    for my $meth (qw/is_ios is_ipad is_ipod is_iphone ios_version ios_full_version/){
        $result->{$meth} = $agent->$meth || undef;
    }
    $result;
}

run_is_deeply;

__DATA__
=== iPod touch
--- input
Mozilla/5.0 (iPod; U; CPU like Mac OS X; en) AppleWebKit/420.1 (KHTML, like Gecko) Version/3.0 Mobile/3A100a Safari/419.3
--- expected yaml
is_ios: 1
is_ipad: ~
is_ipod: 1
is_iphone: ~
ios_version: 1
ios_full_version: 1

=== iPod touch 2
--- input
Mozilla/5.0 (iPod; U; CPU iPhone OS 2_1 like Mac OS X; ja-jp) AppleWebKit/525.18.1 (KHTML, like Gecko) Version/3.1.1 Mobile/5F137 Safari/525.20
--- expected yaml
is_ios: 1
is_ipad: ~
is_ipod: 1
is_iphone: ~
ios_version: 2
ios_full_version: 2_1

=== iPhone
--- input
Mozilla/5.0 (iPhone; U; CPU like Mac OS X; en) AppleWebKit/420+ (KHTML, like Gecko) Version/3.0 Mobile/1C28 Safari/419.3
--- expected yaml
is_ios: 1
is_ipad: ~
is_ipod: ~
is_iphone: 1
ios_version: 1
ios_full_version: 1

=== iPhone 3G
--- input
Mozilla/5.0 (iPhone; U; CPU iPhone OS 2_1 like Mac OS X; ja-jp) AppleWebKit/525.18.1 (KHTML, like Gecko) Version/3.1.1 Mobile/5F137 Safari/525.20
--- expected yaml
is_ios: 1
is_ipad: ~
is_ipod: ~
is_iphone: 1
ios_version: 2
ios_full_version: 2_1

=== iPad
--- input
Mozilla/5.0 (iPad; CPU OS 5_0_1 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9A405 Safari/7534.48.3
--- expected yaml
is_ios: 1
is_ipad: 1
is_ipod: ~
is_iphone: ~
ios_version: 5
ios_full_version: 5_0_1

=== hogehoge
--- input
hogehoge
--- expected yaml
is_ios: ~
is_ipad: ~
is_ipod: ~
is_iphone: ~
ios_version: ~
ios_full_version: ~


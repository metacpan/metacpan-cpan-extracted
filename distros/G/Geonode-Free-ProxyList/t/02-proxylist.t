#!perl
use strict;
use warnings;
use utf8;
use Encode;

use Geonode::Free::ProxyList;

use Test::More tests => 265;

use Test::Exception;

my $list = Geonode::Free::ProxyList->new();

#### set_filter_country ####

$list->set_filter_country('ES');
is $list->{filters}{country}, 'ES',
'can set country filter';

$list->set_filter_country();
is $list->{filters}{country}, undef,
'can reset country filter';

throws_ok { $list->set_filter_country('11'); } qr/ERROR/sxm,
'detects numbers for country code';

throws_ok { $list->set_filter_country('ESE'); } qr/ERROR/sxm,
'detects more than 2 characters for country code';

throws_ok { $list->set_filter_country('E'); } qr/ERROR/sxm,
'detects less than 2 characters for country code';

throws_ok { $list->set_filter_country('E1'); } qr/ERROR/sxm,
'detects mixed characters and numbers';

throws_ok { $list->set_filter_country('ES8'); } qr/ERROR/sxm,
'detects two characters followed by a number';

throws_ok { $list->set_filter_country(q()); } qr/ERROR/sxm,
'detects empty string for country code';

#### set_filter_country ####

for my $google ( 'true', 'false' ) {
    $list->set_filter_google( $google );
    is $list->{filters}{google}, $google,
    "can set google filter - $google";
}

$list->set_filter_google();
is $list->{filters}{google}, undef,
'can reset google filter';

throws_ok { $list->set_filter_google('T R U E'); } qr/ERROR/sxm,
'detects bad google input';

throws_ok { $list->set_filter_google(q()); } qr/ERROR/sxm,
'detects empty google input';

#### set_filter_port ####

$list->set_filter_port('3128');
is $list->{filters}{filterPort}, '3128',
'can set port filter';

$list->set_filter_port();
is $list->{filters}{filterPort}, undef,
'can reset port filter';

throws_ok { $list->set_filter_port('003128'); } qr/ERROR/sxm,
'detects numbers starting by zero';

throws_ok { $list->set_filter_port(q()); } qr/ERROR/sxm,
'detects empty port input';

throws_ok { $list->set_filter_port(0); } qr/ERROR/sxm,
'detects bad port number 0';

throws_ok { $list->set_filter_port(-3128); } qr/ERROR/sxm,
'detects bad port number - negative numbers';

#### set_filter_protocol_list ####

$list->set_filter_protocol_list( [ 'http', 'https', 'socks4', 'socks5' ] );
is_deeply $list->{filters}{protocols}, [ 'http', 'https', 'socks4', 'socks5' ],
'can set protocols filter';

$list->set_filter_protocol_list( [ 'http', 'socks4', 'http', 'socks4' ] );
is @{ $list->{filters}{protocols} }, 2,
'removes duplicates';

$list->set_filter_protocol_list( 'socks5' );
is_deeply $list->{filters}{protocols}, [ 'socks5' ],
'can use scalar for anonymity filter liset';

$list->set_filter_protocol_list();
is $list->{filters}{protocols}, undef,
'can reset protocols filter';

throws_ok { $list->set_filter_protocol_list([]); } qr/ERROR/sxm,
'detects empty protocol list';

throws_ok { $list->set_filter_protocol_list({ 'http' => 'https' }); } qr/ERROR/sxm,
'detects hash reference';

throws_ok { $list->set_filter_protocol_list([ 'http', 'socks4', 'http', 'socks6' ]); } qr/ERROR/sxm,
'detects bad protocols';

#### set_filter_anonymity_list ####

$list->set_filter_anonymity_list( [ 'elite', 'anonymous', 'transparent' ] );
is_deeply $list->{filters}{anonymityLevel}, [ 'elite', 'anonymous', 'transparent' ],
'can set anonymityLevel filter';

$list->set_filter_anonymity_list( [ 'elite', 'anonymous', 'anonymous', 'elite' ] );
is @{ $list->{filters}{anonymityLevel} }, 2,
'removes duplicates';

$list->set_filter_anonymity_list( 'elite' );
is_deeply $list->{filters}{anonymityLevel}, [ 'elite' ],
'can use scalar for anonymity filter liset';

$list->set_filter_anonymity_list();
is $list->{filters}{anonymityLevel}, undef,
'can reset anonymityLevel filter';

throws_ok { $list->set_filter_anonymity_list([]); } qr/ERROR/sxm,
'detects empty anonymityLevel list';

throws_ok { $list->set_filter_anonymity_list({ 'elite' => 'anonymous' }); } qr/ERROR/sxm,
'detects hash reference';

throws_ok { $list->set_filter_anonymity_list([ 'elite', 'anonymous', 'foobar' ]); } qr/ERROR/sxm,
'detects bad anonymityLevel';

#### set_filter_speed ####

for my $speed ( 'fast', 'medium', 'slow' ) {
    $list->set_filter_speed( $speed );
    is $list->{filters}{speed}, $speed,
    "can set speed filter - $speed";
}

$list->set_filter_speed();
is $list->{filters}{speed}, undef,
'can reset speed filter';

throws_ok { $list->set_filter_speed('foobar'); } qr/ERROR/sxm,
'detects bad speed';

#### set_filter_org ####

$list->set_filter_org('Some Org');
is $list->{filters}{filterByOrg}, 'Some Org',
"can set org filter";    

$list->set_filter_org();
is $list->{filters}{filterByOrg}, undef,
'can reset filterByOrg filter';

throws_ok { $list->set_filter_org( q() ); } qr/ERROR/sxm,
'cannot set empty Org';

#### set_filter_uptime ####

foreach my $uptime ( -1 .. 101 ) {
    if ( $uptime >= 0 && $uptime <= 100 && $uptime % 10 == 0 ) {
        $list->set_filter_uptime($uptime);
        is $list->{filters}{filterUpTime}, $uptime,
        "can set filterUpTime filter with value $uptime";
    }
    else {
        throws_ok { $list->set_filter_uptime($uptime); } qr/ERROR/sxm,
        "detects bad filterUpTime with value $uptime";
    }
}

$list->set_filter_uptime();
is $list->{filters}{filterUpTime}, undef,
'can reset filterUpTime filter';

throws_ok { $list->set_filter_uptime('90x'); } qr/ERROR/sxm,
'can detect non-numeric characters';

throws_ok { $list->set_filter_uptime(q()); } qr/ERROR/sxm,
'detects empty filterUpTime input';

#### set_filter_last_checked ####

foreach my $checked ( -1 .. 70 ) {
    my $is_ok = 
           $checked > 0 && $checked < 10
        || ( $checked >= 10 && $checked <= 60 && $checked % 10 == 0 );

    if ( $is_ok ) {
        $list->set_filter_last_checked($checked);
        is $list->{filters}{filterLastChecked}, $checked,
        "can set filterLastChecked filter with value $checked";
    }
    else {
        throws_ok { $list->set_filter_last_checked($checked); } qr/ERROR/sxm,
        "detects bad filterLastChecked with value $checked";
    }
}

$list->set_filter_last_checked();
is $list->{filters}{filterLastChecked}, undef,
'can reset filterLastChecked filter';

throws_ok { $list->set_filter_last_checked('40x'); } qr/ERROR/sxm,
'can detect non-numeric characters';

throws_ok { $list->set_filter_last_checked(q()); } qr/ERROR/sxm,
'detects empty filterLastChecked input';

#### set_filter_limit ####

$list->set_filter_limit(500);
is $list->{filters}{limit}, '500',
'can set limit filter';

$list->set_filter_limit();
is $list->{filters}{limit}, undef,
'can reset limit filter';

throws_ok { $list->set_filter_limit('00500'); } qr/ERROR/sxm,
'detects numbers starting by zero';

throws_ok { $list->set_filter_limit(q()); } qr/ERROR/sxm,
'detects empty limit input';

throws_ok { $list->set_filter_limit(0); } qr/ERROR/sxm,
'detects bad limit number 0';

throws_ok { $list->set_filter_limit(-3128); } qr/ERROR/sxm,
'detects bad negative numbers for limit';

#### _calculate_api_url ####

is $list->_calculate_api_url(), q(),
'no filters means empty api parameters';

$list->set_filter_country('ES');
is $list->_calculate_api_url(), 'country=ES',
'calculates api before adding country';

$list->set_filter_google('false');
is $list->_calculate_api_url(), 'country=ES&google=false',
'calculates api before adding google';

$list->set_filter_port('3128');
is $list->_calculate_api_url(), 'country=ES&filterPort=3128&google=false',
'calculates api before adding port';

$list->set_filter_protocol_list('http');
is $list->_calculate_api_url(), 'country=ES&filterPort=3128&google=false&protocols=http',
'calculates api before adding protocol';

$list->set_filter_protocol_list( [ 'http', 'https' ] );
is $list->_calculate_api_url(), 'country=ES&filterPort=3128&google=false&protocols=http&protocols=https',
'calculates api before adding protocols';

$list->set_filter_anonymity_list('elite');
is $list->_calculate_api_url(), 'anonymityLevel=elite&country=ES&filterPort=3128&google=false&protocols=http&protocols=https',
'calculates api before adding anonymity';

$list->set_filter_anonymity_list( [ 'transparent', 'elite' ] );
is $list->_calculate_api_url(), 'anonymityLevel=elite&anonymityLevel=transparent&country=ES&filterPort=3128&google=false&protocols=http&protocols=https',
'calculates api before adding anonymity list';

$list->set_filter_speed('fast');
is $list->_calculate_api_url(), 'anonymityLevel=elite&anonymityLevel=transparent&country=ES&filterPort=3128&google=false&protocols=http&protocols=https&speed=fast',
'calculates api before adding anonymity';

#### _create_proxy_list ####

my $data = encode( 'utf-8', <DATA>, sub {q()} );

my $proxies = $list->_create_proxy_list($data);

is @{ $proxies }, 10,
'could parse all 10 proxies';

is $data =~ s{
    [{]    \s*+ 
    "data" \s*+
    :      \s*+
    [[] \K (.*) (?=
        \s*+ [}]
        \s*+ []]
        \s*+ ,
    )}{$1,$1}sxm, 1,
'could prepare data for duplicating proxies';

is @{ $proxies }, 10,
'could remove duplicated proxies';

is grep( { ref $_ eq 'Geonode::Free::Proxy' } @{ $proxies } ), 10,
'could count 10 Geonode::Free::Proxy objects';

my $found = 0;
my $found_proxy;
foreach my $proxy ( @{ $proxies } ) {
    if ( $proxy->get_id eq '60d7aa86ce5b3bb0e9890cb4' ) {
        $found = 1;
        $found_proxy = $proxy;
        last;
    }
}

is $found, 1,
'could parse and found proxy with id = 60d7aa86ce5b3bb0e9890cb4';

is $found_proxy->get_id, '60d7aa86ce5b3bb0e9890cb4',
'proxy 60d7aa86ce5b3bb0e9890cb4 can returns its id';

is $found_proxy->get_host, '147.135.255.62',
'proxy 60d7aa86ce5b3bb0e9890cb4 can return its host';

is $found_proxy->get_port, '8123',
'proxy 60d7aa86ce5b3bb0e9890cb4 can return its port';

is_deeply [ $found_proxy->get_methods ], [ 'https' ],
'proxy 60d7aa86ce5b3bb0e9890cb4 can return its methods';

#### get_next ####

$list->{proxy_list} = $proxies;

for my $i ( 1 .. 9 ) {
    my $proxy = $list->get_next;

    is ref($proxy), 'Geonode::Free::Proxy',
    'can get a proxy from the list';

    is $list->{index}, $i,
    'can increase index';
}

$list->get_next;
is $list->{index}, 0,
'can overflow index';

__DATA__
{"data":[{"_id":"60d7aa86ce5b3bb0e9890cb4","ip":"147.135.255.62","port":"8123","anonymityLevel":"elite","asn":"AS16276","city":"Gravelines","country":"FR","created_at":"2021-06-26T22:30:30.754Z","google":false,"hostName":null,"isp":"OVH SAS","lastChecked":1624971607,"latency":143,"org":"OVH","protocols":["https"],"region":null,"responseTime":36,"speed":283,"updated_at":"2021-06-29T13:00:07.719Z","workingPercent":null,"upTime":100,"upTimeSuccessCount":61,"upTimeTryCount":61},{"_id":"60d8b5c9ce5b3bb0e9c97a6b","ip":"147.135.255.62","port":"8129","anonymityLevel":"elite","asn":"AS16276","city":"Gravelines","country":"FR","created_at":"2021-06-27T17:30:49.814Z","google":false,"isp":"OVH SAS","lastChecked":1624971612,"latency":142,"org":"OVH","protocols":["https"],"region":null,"responseTime":68,"speed":382,"updated_at":"2021-06-29T13:00:12.551Z","workingPercent":null,"upTime":100,"upTimeSuccessCount":43,"upTimeTryCount":43},{"_id":"60d94a84ce5b3bb0e9f2022a","ip":"31.25.243.40","port":"9283","anonymityLevel":"elite","asn":"AS39741","city":"Yekaterinburg","country":"RU","created_at":"2021-06-28T04:05:24.348Z","google":false,"isp":"DATAEKB","lastChecked":1624971616,"latency":188,"org":"","protocols":["socks5"],"region":null,"responseTime":40,"speed":null,"updated_at":"2021-06-29T13:00:16.641Z","workingPercent":null,"upTime":100,"upTimeSuccessCount":32,"upTimeTryCount":32},{"_id":"60d71fa9ce5b3bb0e9682ef3","ip":"103.19.129.114","port":"84","anonymityLevel":"transparent","asn":"AS132566","city":"Dewas","country":"IN","created_at":"2021-06-26T12:38:01.186Z","google":false,"hostName":null,"isp":"Skynet Internet Broadband Pvt. Ltd","lastChecked":1624971616,"latency":258,"org":"","protocols":["http"],"region":null,"responseTime":99,"speed":null,"updated_at":"2021-06-29T13:00:16.166Z","workingPercent":null,"upTime":100,"upTimeSuccessCount":71,"upTimeTryCount":71},{"_id":"60d97bc2ce5b3bb0e9ff3d1a","ip":"173.244.200.156","port":"64631","anonymityLevel":"elite","asn":"AS32780","city":"New York","country":"US","created_at":"2021-06-28T07:35:30.569Z","google":false,"isp":"Hosting Services, Inc.","lastChecked":1624971618,"latency":76.4,"org":"Hosting Services, Inc.","protocols":["socks4"],"region":null,"responseTime":51,"speed":157,"updated_at":"2021-06-29T13:00:18.742Z","workingPercent":null,"upTime":100,"upTimeSuccessCount":29,"upTimeTryCount":29},{"_id":"60d82bf8ce5b3bb0e9a80089","ip":"31.25.243.40","port":"9255","anonymityLevel":"elite","asn":"AS39741","city":"Yekaterinburg","country":"RU","created_at":"2021-06-27T07:42:48.926Z","google":false,"hostName":null,"isp":"DATAEKB","lastChecked":1624971619,"latency":188,"org":"","protocols":["socks5"],"region":null,"responseTime":87,"speed":null,"updated_at":"2021-06-29T13:00:19.853Z","workingPercent":null,"upTime":96.15384615384616,"upTimeSuccessCount":50,"upTimeTryCount":52},{"_id":"60d7af22ce5b3bb0e989d81c","ip":"31.25.243.40","port":"9237","anonymityLevel":"elite","asn":"AS39741","city":"Yekaterinburg","country":"RU","created_at":"2021-06-26T22:50:10.908Z","google":false,"hostName":null,"isp":"DATAEKB","lastChecked":1624971626,"latency":188,"org":"","protocols":["socks4"],"region":null,"responseTime":38,"speed":null,"updated_at":"2021-06-29T13:00:26.728Z","workingPercent":null,"upTime":96.72131147540983,"upTimeSuccessCount":59,"upTimeTryCount":61},{"_id":"60d8b606ce5b3bb0e9c985b8","ip":"173.244.200.154","port":"45483","anonymityLevel":"elite","asn":"AS32780","city":"New York","country":"US","created_at":"2021-06-27T17:31:50.879Z","google":false,"isp":"Hosting Services, Inc.","lastChecked":1624971630,"latency":75.7,"org":"Hosting Services, Inc.","protocols":["socks4"],"region":null,"responseTime":40,"speed":166,"updated_at":"2021-06-29T13:00:30.648Z","workingPercent":null,"upTime":100,"upTimeSuccessCount":43,"upTimeTryCount":43},{"_id":"60d94751ce5b3bb0e9effdee","ip":"31.25.243.40","port":"9456","anonymityLevel":"elite","asn":"AS39741","city":"Yekaterinburg","country":"RU","created_at":"2021-06-28T03:51:45.619Z","google":false,"isp":"DATAEKB","lastChecked":1624971630,"latency":188,"org":"","protocols":["socks5"],"region":null,"responseTime":70,"speed":null,"updated_at":"2021-06-29T13:00:30.574Z","workingPercent":null,"upTime":100,"upTimeSuccessCount":33,"upTimeTryCount":33},{"_id":"60d8baeece5b3bb0e9ca5ede","ip":"31.25.243.40","port":"9281","anonymityLevel":"elite","asn":"AS39741","city":"Yekaterinburg","country":"RU","created_at":"2021-06-27T17:52:46.167Z","google":false,"isp":"DATAEKB","lastChecked":1624971632,"latency":188,"org":"","protocols":["socks4"],"region":null,"responseTime":46,"speed":null,"updated_at":"2021-06-29T13:00:32.450Z","workingPercent":null,"upTime":95.34883720930233,"upTimeSuccessCount":41,"upTimeTryCount":43}],"total":1557,"page":1,"limit":"10"}
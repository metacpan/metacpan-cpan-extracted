use strict;
use Test::More;

eval q{ use YAML::Syck };
if ($@) {
    plan skip_all => 'YAML::Syck not installed';
}
else {
    plan tests => 29;
    $ENV{DOCOMO_FLASH_MAP} = 't/docomo.yaml';
    $ENV{EZWEB_FLASH_MAP} = 't/ezweb.yaml';
    use_ok 'HTTP::MobileAgent';
    use_ok 'HTTP::MobileAgent::Flash';
}

my @TESTS = (
    [{HTTP_USER_AGENT => 'None Mobile'}, {}],
    [{HTTP_USER_AGENT => 'DoCoMo/1.0/D405i/c20/TC/W20H10'}, {}],
    [{HTTP_USER_AGENT => 'KDDI-TS21 UP.Browser/6.0.2.276 (GUI) MMP/1.1'}, {}],
    [
        {HTTP_USER_AGENT => 'DoCoMo/2.0 P902i(c100;TB;W24H12)'},
        {version => '1.1'}
    ],
    [
        {HTTP_USER_AGENT => 'DoCoMo/2.0 N506iS(c100;TB;W24H12)'},
        {version => '1.0'}
    ],
    [
        {
            HTTP_USER_AGENT => 'KDDI-HI33 UP.Browser/6.2.0.7.3.129 (GUI) MMP/2.0',
            HTTP_ACCEPT => 'application/x-shockwave-flash',
            HTTP_X_UP_DEVCAP_SCREENPIXELS => '240,268',
            HTTP_X_UP_DEVCAP_SCREENDEPTH  => '1',
            HTTP_X_UP_DEVCAP_ISCOLOR      => 0,
        },
        {version => 1.1, max_file_size => 100, width => 240, height => 320}
    ],
    [
        {
            HTTP_USER_AGENT => 'KDDI-MA32 UP.Browser/6.2.0.12.1.4 (GUI) MMP/2.0',
            HTTP_ACCEPT => 'application/x-shockwave-flash',
            HTTP_X_UP_DEVCAP_SCREENPIXELS => '240,268',
            HTTP_X_UP_DEVCAP_SCREENDEPTH  => '1',
            HTTP_X_UP_DEVCAP_ISCOLOR      => 0,
        },
        {version => '2.0', max_file_size => 100, width => 240, height => 400}
    ],
);

for (@TESTS) {
    my ($env, $check) = @$_;
    local *ENV = $env;

    my $agent = HTTP::MobileAgent->new;
    my $flash = $agent->flash;
    isa_ok $flash, 'HTTP::MobileAgent::Flash';
    if ($agent->is_flash) {
        for my $method (keys %$check) {
            is(
                $flash->$method(),
                $check->{$method}, 
                sprintf("%s : %s = %s", $agent->model, $method, $check->{$method})
            );
        }
        my $version = $check->{version};

        ok $agent->flash->is_supported($version), sprintf("%s : is_supported = %s", $agent->model, $version);
    }
    else {
        is scalar keys %$check, 0, sprintf("%s : none flash", $agent->model);
        ok !$agent->flash->is_supported('0.0'), sprintf("%s : is_supported 0.0", $agent->model);
    }
}

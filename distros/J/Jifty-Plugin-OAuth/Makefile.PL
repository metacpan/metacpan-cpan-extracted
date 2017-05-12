use inc::Module::Install;

name           'Jifty-Plugin-OAuth';
all_from       'lib/Jifty/Plugin/OAuth.pm';

requires('Jifty' => '0.80408');
requires('Net::OAuth::Request' => '0.05');

features(
    'RSA signing' => [
        -default => 0,
        recommends('Crypt::OpenSSL::RSA'),
    ],
    'HMAC signing' => [
        -default => 1,
        recommends('Digest::HMAC_SHA1'),
    ],
);

build_requires 'Test::More';

tests('t/t/*.t');

auto_install;
WriteAll;


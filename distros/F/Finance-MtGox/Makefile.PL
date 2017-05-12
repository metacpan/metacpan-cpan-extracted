use inc::Module::Install;

name     'Finance-MtGox';
all_from 'lib/Finance/MtGox.pm';
author   q{Michael Hendricks <michael@ndrix.org>};
license  'mit';

build_requires 'Test::More';

requires 'Digest::SHA';
requires 'JSON::Any' => 1.25;
requires 'MIME::Base64';
requires 'Time::HiRes';
requires 'WWW::Mechanize' => 1.66;
requires 'URI' => 1.58;

auto_install;

WriteAll;

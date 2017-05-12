use inc::Module::Install;
include 'Module::AutoInstall';

name 'HTTP-Engine-FirePHP';
all_from 'lib/HTTP/Engine/FirePHP.pm';
perl_version '5.006';

homepage 'http://search.cpan.org/dist/HTTP-Engine-FirePHP/';
bugtracker 'http://rt.cpan.org/Public/Dist/Display.html?Name=HTTP-Engine-FirePHP';
repository 'http://github.com/hanekomu/http-engine-firephp/tree/master';

requires 'FirePHP::Dispatcher';
requires 'HTTP::Engine::Response';
requires 'HTTP::Headers';
requires 'HTTP::Headers::Fast';
requires 'UNIVERSAL::require';

test_requires 'Test::More' => '0.70';
extra_tests;

auto_install;
auto_include;
WriteAll;

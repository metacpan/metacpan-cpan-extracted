use inc::Module::Install;

name     'JSON::RPC2::AnyEvent::Client';
all_from 'lib/JSON/RPC2/AnyEvent/Client.pm';
author   'Serguei Okladnikov <oklaspec@gmail.com>';
license  'perl';

requires	'version';
requires	'JSON::XS';
requires	'JSON::RPC2::Client';
requires	'AnyEvent';
requires	'AnyEvent::Handle';


test_requires	'Test::More';
test_requires	'JSON::RPC2::AnyEvent';
test_requires	'JSON::RPC2::AnyEvent::Server';
test_requires	'JSON::RPC2::AnyEvent::Server::Handle';

recommends      'Test::CheckManifest'   => '0.9';
recommends      'Test::Perl::Critic';
recommends      'Test::Pod::Coverage'   => '1.08';
recommends      'Pod::Coverage'         => '0.18';
recommends      'Test::Pod'             => '1.22';

auto_install;

WriteAll;


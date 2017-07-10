use inc::Module::Install;

name     'JSON-Assert';
all_from 'lib/JSON/Assert.pm';
author   'NZRS Development Team <developers@nzrs.net.nz>';
repository 'https://github.com/nzrs/JSON-Assert';

perl_version '5.010_000';

requires        "Moo"                          => 0;
requires        "MooX::Types::MooseLike::Base" => 0;
requires        "JSON::Path"                   => 0;

build_requires 'Test::More';
build_requires 'Test::Builder::Tester';
test_requires 'Test::Exception';
test_requires 'Test::Deep::NoTest';

include 'Test::Exception';
include 'Sub::Uplevel';

auto_install;

WriteAll;


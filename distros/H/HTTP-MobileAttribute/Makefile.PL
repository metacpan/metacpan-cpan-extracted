use inc::Module::Install;
name 'HTTP-MobileAttribute';
all_from 'lib/HTTP/MobileAttribute.pm';

requires 'Class::Component'         => '0.17';
requires 'UNIVERSAL::require'       => 0.13;

features(
    'Plugin::CIDR' => [
        -default => 0,
        recommends('Net::CIDR::MobileJP', 0.11),
    ],
    'Plugin::Locator' => [
        -default => 0,
        recommends('Geo::Coordinates::Converter', 0.04),
        recommends('Geo::Coordinates::Converter::iArea', 0.08),
    ],
);

if ($Module::Install::AUTHOR) {
	test_requires 'Geo::Coordinates::Converter';
	test_requires 'Geo::Coordinates::Converter::iArea';
}

test_requires 'YAML';
tests 't/*.t t/Plugins/*.t t/*/*/*.t';
author_tests 'xt';
use_test_base;
WriteAll;

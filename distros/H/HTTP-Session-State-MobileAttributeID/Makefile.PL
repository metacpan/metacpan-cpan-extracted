use inc::Module::Install;
name 'HTTP-Session-State-MobileAttributeID';
all_from 'lib/HTTP/Session/State/MobileAttributeID.pm';

requires 'HTTP::Session' => 0.43;
requires 'HTTP::MobileAttribute' => 0.23;
requires 'HTML::StickyQuery::DoCoMoGUID'   => 0.01;
requires 'Net::CIDR::MobileJP' => 0.24;

readme_markdown_from 'lib/HTTP/Session/State/MobileAttributeID.pm';
tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t';
test_requires 'Test::More';
author_tests('xt');
WriteAll;

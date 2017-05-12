use inc::Module::Install;
name 'HTTP-Session-State-MobileAgentID';
all_from 'lib/HTTP/Session/State/MobileAgentID.pm';

requires 'HTTP::Session' => '0.38';
requires 'HTTP::MobileAgent' => '0.28';
requires 'Net::CIDR::MobileJP' => '0.20';

test_requires 'Test::Exception';
test_requires 'HTTP::Response';

readme_markdown_from 'lib/HTTP/Session/State/MobileAgentID.pm';
tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t';
test_requires 'Test::More';
author_tests('xt');
WriteAll;

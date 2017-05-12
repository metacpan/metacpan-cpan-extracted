use inc::Module::Install;

name 'HTML-MobileJp-Filter';
all_from 'lib/HTML/MobileJp/Filter.pm';

requires_any_moose;
requires 'Class::Trigger';
requires 'XML::LibXML';

requires 'Encode' => 2.25;
requires 'Encode::JP::Mobile' => 0.25;
requires 'Encode::JP::Mobile::Charnames';
requires 'HTML::DoCoMoCSS';
requires 'HTML::StickyQuery::DoCoMoGUID';
requires 'HTML::Entities::ConvertPictogramMobileJp';
requires 'HTTP::Headers';
requires 'YAML';
requires 'HTTP::MobileAgent';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
test_requires 'Test::Base';

use_test_base;
auto_include;

WriteAll;

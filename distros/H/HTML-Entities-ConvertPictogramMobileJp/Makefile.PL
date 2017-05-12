use inc::Module::Install;
name 'HTML-Entities-ConvertPictogramMobileJp';
all_from 'lib/HTML/Entities/ConvertPictogramMobileJp.pm';

requires 'Encode::JP::Mobile' => 0.25;
requires 'HTTP::MobileAgent' => 0.26;
requires 'Params::Validate' => 0.89;

test_requires 'Test::More' => 0.98;
test_requires 'Test::Base' => 0.60;

author_tests('xt');

WriteAll;

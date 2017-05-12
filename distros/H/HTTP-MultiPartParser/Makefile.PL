use lib '.';
use strict;
use inc::Module::Install;

name           'HTTP-MultiPartParser';
perl_version   '5.008001';
all_from       'lib/HTTP/MultiPartParser.pm';
repository     'http://github.com/chansen/p5-http-multipartparser';
readme_from    'lib/HTTP/MultiPartParser.pod';

requires       'Carp'         => '0';
requires       'Scalar::Util' => '0';
test_requires  'Test::More'   => '0.88';
test_requires  'Test::Deep'   => '0';

tests 't/*.t';

WriteAll;

use inc::Module::Install;
name 'HTTP-Request-FromLog';
all_from 'lib/HTTP/Request/FromLog.pm';

requires 'HTTP::Request';
requires 'UNIVERSAL::require';
requires 'List::MoreUtils';
requires 'Parse::AccessLogEntry';
requires 'HTTP::Headers';
requires 'Carp';

build_requires 'Test::More';
build_requires 'YAML';
build_requires 'Text::CSV_XS';

use_test_base;
auto_include;
WriteAll;

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/IO/Async/XMLStream/SAXReader.pm',
    'lib/IO/Async/XMLStream/SAXReader/DuckHandler.pm',
    't/00-compile/lib_IO_Async_XMLStream_SAXReader_DuckHandler_pm.t',
    't/00-compile/lib_IO_Async_XMLStream_SAXReader_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-piecewise-xml.t',
    't/02-piecewise-subclass-xml.t',
    't/03-piecewise-saxclass-xml.t',
    't/data-xml/KENTNL.xml'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;

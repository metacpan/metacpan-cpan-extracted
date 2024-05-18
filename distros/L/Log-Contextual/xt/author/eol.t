use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Log/Contextual.pm',
    'lib/Log/Contextual/Easy/Default.pm',
    'lib/Log/Contextual/Easy/Package.pm',
    'lib/Log/Contextual/Role/Router.pm',
    'lib/Log/Contextual/Role/Router/HasLogger.pm',
    'lib/Log/Contextual/Role/Router/SetLogger.pm',
    'lib/Log/Contextual/Role/Router/WithLogger.pm',
    'lib/Log/Contextual/Router.pm',
    'lib/Log/Contextual/SimpleLogger.pm',
    'lib/Log/Contextual/TeeLogger.pm',
    'lib/Log/Contextual/WarnLogger.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/arg.t',
    't/base.t',
    't/caller.t',
    't/default_import.t',
    't/default_logger.t',
    't/dlog.t',
    't/easy.t',
    't/eg.t',
    't/has_logger.t',
    't/inherit.t',
    't/lib/BaseLogger.pm',
    't/lib/DefaultImportLogger.pm',
    't/lib/My/Module.pm',
    't/lib/My/Module2.pm',
    't/lib/TestExporter.pm',
    't/lib/TestRouter.pm',
    't/log-with-levels.t',
    't/log.t',
    't/log4perl.conf',
    't/log4perl.t',
    't/package_logger.t',
    't/router_api.t',
    't/rt83267-begin.t',
    't/rt83267.t',
    't/simplelogger.t',
    't/warnlogger-with-levels.t',
    't/warnlogger.t',
    't/yell-loudly.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;

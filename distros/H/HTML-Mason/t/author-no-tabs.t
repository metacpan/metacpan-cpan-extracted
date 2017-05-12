
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.09

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/convert0.6.README',
    'bin/convert0.6.pl',
    'bin/convert0.8.README',
    'bin/convert0.8.pl',
    'bin/mason.pl',
    'lib/HTML/Mason.pm',
    'lib/HTML/Mason/Admin.pod',
    'lib/HTML/Mason/Apache/Request.pm',
    'lib/HTML/Mason/ApacheHandler.pm',
    'lib/HTML/Mason/CGIHandler.pm',
    'lib/HTML/Mason/Cache/BaseCache.pm',
    'lib/HTML/Mason/Compiler.pm',
    'lib/HTML/Mason/Compiler/ToObject.pm',
    'lib/HTML/Mason/Component.pm',
    'lib/HTML/Mason/Component/FileBased.pm',
    'lib/HTML/Mason/Component/Subcomponent.pm',
    'lib/HTML/Mason/ComponentSource.pm',
    'lib/HTML/Mason/Devel.pod',
    'lib/HTML/Mason/Escapes.pm',
    'lib/HTML/Mason/Exceptions.pm',
    'lib/HTML/Mason/FAQ.pod',
    'lib/HTML/Mason/FakeApache.pm',
    'lib/HTML/Mason/Handler.pm',
    'lib/HTML/Mason/Interp.pm',
    'lib/HTML/Mason/Lexer.pm',
    'lib/HTML/Mason/MethodMaker.pm',
    'lib/HTML/Mason/Params.pod',
    'lib/HTML/Mason/Parser.pm',
    'lib/HTML/Mason/Plugin.pm',
    'lib/HTML/Mason/Plugin/Context.pm',
    'lib/HTML/Mason/Request.pm',
    'lib/HTML/Mason/Resolver.pm',
    'lib/HTML/Mason/Resolver/File.pm',
    'lib/HTML/Mason/Resolver/Null.pm',
    'lib/HTML/Mason/Subclassing.pod',
    'lib/HTML/Mason/Tests.pm',
    'lib/HTML/Mason/Tools.pm',
    'lib/HTML/Mason/Utils.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-syntax.t',
    't/01a-comp-calls.t',
    't/02-sections.t',
    't/02a-filter.t',
    't/04-misc.t',
    't/05-request.t',
    't/05a-stack-corruption.t',
    't/06-compiler.t',
    't/06a-compiler_obj.t',
    't/06b-compiler-named-subs.t',
    't/06c-compiler-spaces-path.t',
    't/07-interp.t',
    't/07a-interp-mcr.t',
    't/07b-interp-static-source.t',
    't/09-component.t',
    't/09a-comp_content.t',
    't/10-cache.t',
    't/10a-cache-1.0x.t',
    't/10b-cache-chi.t',
    't/11-inherit.t',
    't/12-taint.t',
    't/13-errors.t',
    't/14-cgi.t',
    't/14a-fake_apache.t',
    't/15-subclass.t',
    't/17-print.t',
    't/18-leak.t',
    't/19-subrequest.t',
    't/20-plugins.t',
    't/21-escapes.t',
    't/22-path-security.t',
    't/23-leak2.t',
    't/24-tools.t',
    't/25-flush-in-content.t',
    't/25-log.t',
    't/author-no-tabs.t',
    't/author-pod-spell.t',
    't/lib/Apache/test.pm',
    't/lib/BadModule.pm',
    't/lib/LoadTest.pm',
    't/lib/Mason/ApacheTest.pm',
    't/release-pod-syntax.t',
    't/run_one_test',
    't/run_tests',
    't/single_test.pl',
    't/taint.comp'
);

notabs_ok($_) foreach @files;
done_testing;

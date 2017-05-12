use strict;
use warnings;

use Test::More 0.88;
use Test::Deep;
use Test::Fatal qw( exception );

use lib 't/lib';
use MockZilla;

# This evaluates at runtime, which is important.
use_ok('Dist::Zilla::Plugin::ReportVersions::Tiny');

my $rv;
is( exception {
    $rv = Dist::Zilla::Plugin::ReportVersions::Tiny->new(
        exclude     => [qw{Moose Unmatched::Module}],
        plugin_name => 'ReportVersions::Tiny',
        zilla       => MockZilla->dzil,
    );
}, undef,  "we can create an instance with multiple exclusions");

{

    MockZilla->set_prereqs({
        test    => { requires => { baz => 1, quux => 1, Moose => 5 } },
        build   => { requires => { baz => 2, foox => 1 } },
    });

    my $modules;
    is( exception { $modules = $rv->applicable_modules }, undef,
        "we can collect the applicable modules for the distribution" );

    cmp_deeply $modules, { baz => 2, foox => 1, quux => 1 },
        "we collected the first round of modules as expected";

    # Did we get the logging we expected?
    is( MockZilla->logger->call_pos(1), 'log', 'logging was called as expected');
    is( MockZilla->logger->call_args_pos(1, 2),
        'Will not report version of excluded module Moose.',
            "logging was called with the right arguments." );

    is( MockZilla->logger->call_pos(2), undef, 'logging was only called once' );
}

done_testing;

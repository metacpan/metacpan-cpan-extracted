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
        include     => ['JSON::PP 2.27103', 'Path::Class', 'Some::Thing = 1.0'],
        plugin_name => 'ReportVersions::Tiny',
        zilla       => MockZilla->dzil,
    );
}, undef, "we can create an instance with multiple inclusions" );

{
    MockZilla->set_prereqs({
        test    => { requires => { baz => 1, quux => 1 } },
        build   => { requires => { baz => 2, foox => 1 } },
    });

    my $modules;
    is( exception { $modules = $rv->applicable_modules }, undef,
        "we can collect the applicable modules for the distribution");

    cmp_deeply $modules, { baz => 2, foox => 1, quux => 1,
        'JSON::PP' => '2.27103', 'Path::Class' => 0, 'Some::Thing' => '1.0' },
        "we collected the first round of modules as expected";

    # Did we get the logging we expected?
    my @included = qw( JSON::PP Path::Class Some::Thing );
    my $count = scalar @included;
    foreach my $i ( 1 .. $count ) {
        is(MockZilla->logger->call_pos($i), 'log', 'logging was called as expected');
        is(MockZilla->logger->call_args_pos($i, 2),
            'Will also report version of included module ' . $included[$i-1] . '.',
                "logging was called with the right arguments.");
    }

    is( MockZilla->logger->call_pos($count + 1), undef, "logging was only called ${count} times" );
}

done_testing;

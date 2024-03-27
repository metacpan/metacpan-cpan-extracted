use strictures 2;
use stable 0.031 'postderef';
use experimental 'signatures';
use if "$]" >= 5.022, experimental => 're_strict';
no if "$]" >= 5.031009, feature => 'indirect';
no if "$]" >= 5.033001, feature => 'multidimensional';
no if "$]" >= 5.033006, feature => 'bareword_filehandles';

use Test::More;
use Test::Warnings;
use Test::DZil;
use Path::Tiny;
use List::Util 'first';
use Dist::Zilla::Plugin::PromptIfStale;

# look up each of these core modules in the index. Tests will start failing
# when the module finally gets added to the index, indicating we can drop our
# special handling in the plugin.


my $tzil = Builder->from_config(
    { dist_root => 't/does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ 'PromptIfStale' => { modules => [ 'Config', 'Errno' ], phase => 'build' } ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
    },
);
my $plugin = first { $_->isa('Dist::Zilla::Plugin::PromptIfStale') } $tzil->plugins->@*;

diag 'looking up some core modules in the index...';

foreach my $module (qw(
    Config
    DB
    Errno
    Pod::Functions
)) {
    is(
        $plugin->_indexed_version_via_query($module),
        undef,
        $module . ' is not indexed (but it should be!)',
    );
}

done_testing;


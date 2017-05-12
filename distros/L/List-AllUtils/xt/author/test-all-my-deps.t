use strict;
use warnings;

use Cwd qw( abs_path );
use Test::More;

BEGIN {
    plan skip_all =>
        'Must set LIST_ALLUTILS_TEST_DEPS to true in order to run these tests'
        unless $ENV{LIST_ALLUTILS_TEST_DEPS};
}

use Test::DependentModules qw( test_all_dependents );

local $ENV{PERL_TEST_DM_LOG_DIR} = abs_path('.');

my $exclude = qr/
                    ^
                    (?:
                        App-Magpie
                    )$
                /x;

my %exclude = (
    'App-Magpie'    => 1,    # requires URPM which does not install on Ubuntu
    'App-Map-Metro' => 1,    # dependency failures
    'DBD-TreeData'  => 1,    # fails tests
    'Devel-IPerl'   => 1,    # depends on ipython
    'Dist-Zilla-PluginBundle-Prereqs' => 1,    # fails tests
    'MarpaX-Grammar-GraphViz2'        => 1,    # unsatisfiable prereqs
    'Gtk3-Ex-PdfViewer'               => 1,    # requires various gtk libs
    'Net-DNS-SPF-Expander'            => 1,    # fails tests
    'Pantry'                          => 1,    # fails tests
    'Pcore'                           => 1,    # Build.PL fails
    'Silki'                           => 1,    # fails tests
    'Statistics-NiceR'                => 1,    # requires an R executable
    'Transform-Alert'                 => 1,    # fails tests
);

test_all_dependents(
    'List-AllUtils', {
        filter => sub { !$exclude{ $_[0] } }
    }
);

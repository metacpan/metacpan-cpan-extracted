use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Path::Tiny;

{
    package PodCounter;
    use Moose;
    with 'Dist::Zilla::Role::Plugin',
        'Dist::Zilla::Role::ModuleMetadata';
    # we do nothing at build time - plugin is poked after the fact
}

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ MetaConfig => ],
                '=PodCounter',
            ),
            path(qw(source lib Foo.pm)) => <<"FOO",
package Foo;
our \$VERSION = '0.001';

=pod

=head1 HELLO

This is pod content.

=cut
FOO
        },
    },
);

$tzil->chrome->logger->set_debug(1);
is(
    exception { $tzil->build },
    undef,
    'build proceeds normally',
);

my $plugin = $tzil->plugin_named('=PodCounter');
my $pod_content = "\nThis is pod content.\n\n";
# BEGIN TESTS
{
    my $mmd = $plugin->module_metadata_for_file($tzil->main_module, collect_pod => 1);
    is($mmd->pod('HELLO'), $pod_content, 'MMD object saved pod content');
}

{
    my $mmd = $plugin->module_metadata_for_file($tzil->main_module, collect_pod => 0);
    is($mmd->pod('HELLO'), $pod_content, 'MMD object collected pod because we reused our cached object');
}
# END TESTS

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;

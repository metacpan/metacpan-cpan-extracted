use strict;
use warnings;

use Test::More;

# this is just like t/04-collect_pod.t, except we request collect_pod => 0
# first and *then* collect_pod => 1, which means we need to load the file
# twice as the cached MMD object did not collect pod.

use Path::Tiny;
my $code = path('t', '04-collect_pod.t')->slurp_utf8;

my $tests = <<'TESTS';
{
    my $mmd = $plugin->module_metadata_for_file($tzil->main_module);    # collect_pod left to default to 0
    is($mmd->pod('HELLO'), undef, 'MMD object did not save pod content');
}

{
    my $mmd = $plugin->module_metadata_for_file($tzil->main_module, collect_pod => 1);
    is($mmd->pod('HELLO'), $pod_content, 'new MMD object created, which saved pod content');
}
TESTS
$code =~ s/^# BEGIN TESTS\n\K.*(# END TESTS)/$tests\n$1/ms;

eval $code;
die $@ if $@;

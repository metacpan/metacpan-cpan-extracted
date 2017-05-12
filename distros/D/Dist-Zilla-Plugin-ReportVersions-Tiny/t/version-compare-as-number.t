use strict;
use warnings;

use Test::More 0.88;
use Test::MockObject;
use Test::Warn;

my ($prereq, $dz, $log);
BEGIN {
    # Done early, hopefully before anything else might load Dist::Zilla.
    my $dz_prereq = Test::MockObject->new;
    $dz_prereq->set_bound(as_string_hash => \$prereq);

    $log = Test::MockObject->new;
    $log->set_always(log => $1);

    my $dz_logger = Test::MockObject->new;
    $dz_logger->set_always(proxy => $log);

    my $dz_chrome = Test::MockObject->new;
    $dz_chrome->set_always(logger => $dz_logger);

    $dz = Test::MockObject->new;
    $dz->fake_module('Dist::Zilla');
    $dz->set_isa('Dist::Zilla');
    $dz->set_always(prereqs => $dz_prereq);
    $dz->set_always(chrome  => $dz_chrome);
}


# This evaluates at runtime, which is important.
use_ok('Dist::Zilla::Plugin::ReportVersions::Tiny');

my $plugin = Dist::Zilla::Plugin::ReportVersions::Tiny->new(
    plugin_name => 'ReportVersions::Tiny',
    zilla       => $dz,
);

# Establish the prereq that would have failed...
$prereq = { build => { requires => { 'Test::NoPlan' => '0.0.6' } } };

# ...and get back the test code...
my $code;
warning_is { $code = $plugin->generate_test_from_prereqs() } undef,
    "No warnings during the template expansion";

# Verify that we didn't get 'any version', but rather the requested
# version; this is CPAN RT#63912
my $expect = qr{\Qpmver('Test::NoPlan','0.0.6')};
like $code, $expect, "0.0.6 was treated as a version string, not 'any version'";

done_testing;

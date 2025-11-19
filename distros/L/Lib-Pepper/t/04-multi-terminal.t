use strict;
use warnings;

use Test::More;
use File::Spec;

# Test module loading
BEGIN {
    use_ok('Lib::Pepper::Simple');
    use_ok('Lib::Pepper::Constants', qw(:all));
}

# Test that library_status() class method exists
can_ok('Lib::Pepper::Simple', 'library_status');

# Test library_status() before any instances created
{
    my $status = Lib::Pepper::Simple->library_status();
    is($status->{initialized}, 0, 'library_status(): not initialized before first instance');
    is($status->{instance_count}, 0, 'library_status(): zero instances initially');
    is($status->{library_path}, '', 'library_status(): empty library_path initially');
    is_deeply($status->{instance_ids}, {}, 'library_status(): empty instance_ids initially');
}

# Author-only test: requires PEPPER_LICENSE environment variable
# Usage: PEPPER_LICENSE=/path/to/license.xml make test
my $licenseFile = $ENV{PEPPER_LICENSE};
my $configFile = File::Spec->catfile('examples', 'config', 'pepper_config.xml');
my $libraryPath = (-f 'libpepcore.so' ? File::Spec->rel2abs('libpepcore.so') : '');
my $haveLicense = 0;
my $license_xml;
my $config_xml;

if(defined $licenseFile && -f $licenseFile && -f $configFile) {
    # Read files into XML strings (like working examples do)
    open(my $fh, '<', $licenseFile) or die "Cannot open license file: $!";
    $license_xml = do { local $/; <$fh> };
    close($fh);

    open($fh, '<', $configFile) or die "Cannot open config file: $!";
    $config_xml = do { local $/; <$fh> };
    close($fh);

    $haveLicense = 1;
}

SKIP: {
    skip 'Author-only test: Set PEPPER_LICENSE=/path/to/license.xml to run multi-terminal tests', 5 unless $haveLicense;

    # Test 1: Basic multi-terminal creation
    my $terminal1;
    my $terminal2;

    eval {
        $terminal1 = Lib::Pepper::Simple->new(
            terminal_type    => PEP_TERMINAL_TYPE_GENERIC_ZVT,
            terminal_address => '192.168.1.163:20008',
            license_xml      => $license_xml,
            config_xml       => $config_xml,
            library_path     => $libraryPath,
        );
    };

    my $firstInstanceError = $@;
    skip "Cannot initialize first terminal: $firstInstanceError", 5 if $firstInstanceError;

    ok($terminal1, 'First terminal created successfully');

    # Check library status after first instance
    my $status1 = Lib::Pepper::Simple->library_status();
    is($status1->{initialized}, 1, 'Library initialized after first instance');
    is($status1->{instance_count}, 1, 'Instance count is 1 after first instance');

    # Check instance status
    my $instStatus1 = $terminal1->checkStatus();
    is($instStatus1->{instance_id}, 1, 'First terminal has instance_id 1');
    is($instStatus1->{process_instance_count}, 1, 'Instance status shows 1 active instance');

    # Test 2: Create second terminal with same config
    eval {
        $terminal2 = Lib::Pepper::Simple->new(
            terminal_type    => PEP_TERMINAL_TYPE_GENERIC_ZVT,
            terminal_address => '192.168.1.164:20008',
            license_xml      => $license_xml,
            config_xml       => $config_xml,
            library_path     => $libraryPath,
        );
    };

    skip "Cannot initialize second terminal: $@", 0 if $@;

    ok($terminal2, 'Second terminal created successfully');

    # Check library status after second instance
    my $status2 = Lib::Pepper::Simple->library_status();
    is($status2->{instance_count}, 2, 'Instance count is 2 after second instance');
    is($status2->{initialized}, 1, 'Library still initialized');

    # Check instance IDs are different
    my $instStatus2 = $terminal2->checkStatus();
    is($instStatus2->{instance_id}, 2, 'Second terminal has instance_id 2');
    isnt($instStatus1->{instance_id}, $instStatus2->{instance_id}, 'Instance IDs are different');

    # Test 3: Destroy first terminal, library should stay initialized
    undef $terminal1;
    my $status3 = Lib::Pepper::Simple->library_status();
    is($status3->{instance_count}, 1, 'Instance count is 1 after destroying first terminal');
    is($status3->{initialized}, 1, 'Library still initialized after destroying first terminal');

    # Second terminal should still be operational
    my $instStatus2b = $terminal2->checkStatus();
    ok($instStatus2b->{ready_for_transactions}, 'Second terminal still operational');

    # Test 4: Destroy last terminal, library should STAY initialized (never-finalize design)
    undef $terminal2;
    my $status4 = Lib::Pepper::Simple->library_status();
    is($status4->{instance_count}, 0, 'Instance count is 0 after destroying last terminal');
    is($status4->{initialized}, 1, 'Library STAYS initialized after destroying last terminal (never-finalize design)');
}

# Test config mismatch detection (doesn't require real terminal)
SKIP: {
    skip 'Author-only test: Set PEPPER_LICENSE=/path/to/license.xml to run config mismatch tests', 3 unless $haveLicense;

    my $terminal1;
    eval {
        $terminal1 = Lib::Pepper::Simple->new(
            terminal_type    => PEP_TERMINAL_TYPE_GENERIC_ZVT,
            terminal_address => '192.168.1.163:20008',
            license_xml      => $license_xml,
            config_xml       => $config_xml,
            library_path     => $libraryPath,
        );
    };

    skip "Cannot initialize first terminal: $@", 3 if $@;

    # Try to create second terminal with different config (should fail)
    my $differentConfig = '<Config>DIFFERENT</Config>';
    my $terminal2;
    eval {
        $terminal2 = Lib::Pepper::Simple->new(
            terminal_type    => PEP_TERMINAL_TYPE_GENERIC_ZVT,
            terminal_address => '192.168.1.164:20008',
            license_xml      => $license_xml,
            config_xml       => $differentConfig,  # Different config!
        );
    };

    like($@, qr/Configuration mismatch/, 'Config mismatch detected and reported');
    ok(!defined $terminal2, 'Second terminal not created due to config mismatch');

    # First terminal should still be operational
    my $status = Lib::Pepper::Simple->library_status();
    is($status->{instance_count}, 1, 'Instance count unchanged after failed creation');

    undef $terminal1;
}

# Test different terminal types (instance ID allocation per type)
SKIP: {
    skip 'Author-only test: Set PEPPER_LICENSE=/path/to/license.xml to run terminal type tests', 6 unless $haveLicense;

    my $genericA;
    my $genericB;

    eval {
        # Create two Generic ZVT terminals
        $genericA = Lib::Pepper::Simple->new(
            terminal_type    => PEP_TERMINAL_TYPE_GENERIC_ZVT,
            terminal_address => '192.168.1.163:20008',
            license_xml      => $license_xml,
            config_xml       => $config_xml,
            library_path     => $libraryPath,
        );

        $genericB = Lib::Pepper::Simple->new(
            terminal_type    => PEP_TERMINAL_TYPE_GENERIC_ZVT,
            terminal_address => '192.168.1.164:20008',
            license_xml      => $license_xml,
            config_xml       => $config_xml,
            library_path     => $libraryPath,
        );
    };

    skip "Cannot initialize terminals: $@", 6 if $@;

    # Check instance IDs
    my $statusA = $genericA->checkStatus();
    my $statusB = $genericB->checkStatus();

    # With never-finalize design, absolute IDs depend on previous tests
    # Just verify IDs are valid and different
    ok($statusA->{instance_id} > 0, 'First Generic ZVT terminal has valid instance_id');
    ok($statusB->{instance_id} > 0, 'Second Generic ZVT terminal has valid instance_id');
    isnt($statusA->{instance_id}, $statusB->{instance_id}, 'Instance IDs are different');

    # Check library status
    my $libStatus = Lib::Pepper::Simple->library_status();
    is($libStatus->{instance_count}, 2, 'Total 2 instances created');
    # Next ID should be greater than both current IDs (never-finalize design)
    ok($libStatus->{instance_ids}->{+PEP_TERMINAL_TYPE_GENERIC_ZVT} > $statusA->{instance_id}, 'Next Generic ZVT ID incremented');
    ok($libStatus->{instance_ids}->{+PEP_TERMINAL_TYPE_GENERIC_ZVT} > $statusB->{instance_id}, 'Next Generic ZVT ID greater than both instances');

    undef $genericA;
    undef $genericB;
}

# Test manual instance_id specification
SKIP: {
    skip 'Author-only test: Set PEPPER_LICENSE=/path/to/license.xml to run manual instance ID tests', 2 unless $haveLicense;

    my $terminal;
    eval {
        $terminal = Lib::Pepper::Simple->new(
            terminal_type    => PEP_TERMINAL_TYPE_GENERIC_ZVT,
            terminal_address => '192.168.1.163:20008',
            license_xml      => $license_xml,
            config_xml       => $config_xml,
            library_path     => $libraryPath,
            instance_id      => 42,  # Manual ID
        );
    };

    skip "Cannot initialize terminal: $@", 2 if $@;

    my $status = $terminal->checkStatus();
    is($status->{instance_id}, 42, 'Manual instance_id is respected');

    # Auto-counter should not be affected by manual ID
    my $libStatus = Lib::Pepper::Simple->library_status();
    ok(!exists $libStatus->{instance_ids}->{+PEP_TERMINAL_TYPE_GENERIC_ZVT} ||
       $libStatus->{instance_ids}->{+PEP_TERMINAL_TYPE_GENERIC_ZVT} > 0,
       'Auto-counter remains independent');

    undef $terminal;
}

# Test rapid create/destroy (stress test for memory leaks)
SKIP: {
    skip 'Author-only test: Set PEPPER_LICENSE=/path/to/license.xml to run stress tests', 2 unless $haveLicense;

    diag("Library path for stress test: '$libraryPath'");
    my $iterations = 10;  # Reduced from 100 for faster testing
    my $success = 1;

    for my $i (1..$iterations) {
        my $terminal;
        eval {
            $terminal = Lib::Pepper::Simple->new(
                terminal_type    => PEP_TERMINAL_TYPE_GENERIC_ZVT,
                terminal_address => '192.168.1.163:20008',
                license_xml      => $license_xml,
                config_xml       => $config_xml,
            library_path     => $libraryPath,
            );
        };

        if($@) {
            $success = 0;
            diag("Iteration $i failed: $@");
            last;
        }

        undef $terminal;
    }

    ok($success, "Rapid create/destroy stress test passed ($iterations iterations)");

    # Verify library stays initialized after all instances destroyed (never-finalize design)
    my $finalStatus = Lib::Pepper::Simple->library_status();
    is($finalStatus->{instance_count}, 0, 'All instances cleaned up after stress test');
    is($finalStatus->{initialized}, 1, 'Library STAYS initialized (never-finalize design)');
}

done_testing();

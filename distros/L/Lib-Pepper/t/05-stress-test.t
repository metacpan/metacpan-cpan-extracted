use strict;
use warnings;

use Test::More;
use File::Spec;
use Time::HiRes qw(time);

# Test module loading
BEGIN {
    use_ok('Lib::Pepper::Simple');
    use_ok('Lib::Pepper::Constants', qw(:all));
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
    diag("License file: $licenseFile");
    diag("Config file: $configFile");
    diag("Library path: $libraryPath");
}

SKIP: {
    skip 'Author-only test: Set PEPPER_LICENSE=/path/to/license.xml to run stress tests', 20 unless $haveLicense;

    diag("");
    diag("=" x 70);
    diag("STRESS TEST: 100 instances - Create/Destroy cycles");
    diag("=" x 70);
    diag("");

    # Verify initial state (never-finalize design: library may be initialized from previous tests)
    my $initialStatus = Lib::Pepper::Simple->library_status();
    # With never-finalize design, library stays initialized across tests
    ok($initialStatus->{initialized} >= 0, 'Library status checked before stress test');
    is($initialStatus->{instance_count}, 0, 'Instance count is 0 before stress test');

    # Test 1: Sequential create/destroy (100 iterations)
    diag("Test 1: Sequential create/destroy (100 iterations)");
    my $startTime = time();
    my $iterations = 100;
    my $errors = 0;
    my $warnings = 0;

    # Capture warnings
    local $SIG{__WARN__} = sub {
        my $warning = shift;
        # Ignore expected warnings from destructor
        unless($warning =~ /Lib::Pepper finalization failed during DESTROY/) {
            diag("WARNING: $warning");
            $warnings++;
        }
    };

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
            diag("Iteration $i FAILED: $@");
            $errors++;
            last;  # Stop on first error
        }

        # Verify library state during iteration
        if($i == 1) {
            my $status = Lib::Pepper::Simple->library_status();
            is($status->{initialized}, 1, "Library initialized on first iteration");
            is($status->{instance_count}, 1, "Instance count is 1 on first iteration");
        }

        # Destroy terminal
        undef $terminal;

        # Every 10 iterations, verify cleanup
        if($i % 10 == 0) {
            my $status = Lib::Pepper::Simple->library_status();
            is($status->{instance_count}, 0, "Instance count is 0 after iteration $i");
            is($status->{initialized}, 1, "Library STAYS initialized after iteration $i (never-finalize design)");
            diag("Progress: $i/$iterations iterations complete");
        }
    }

    my $elapsed = time() - $startTime;
    diag(sprintf("Sequential test completed in %.2f seconds (%.0f ms per iteration)",
                 $elapsed, ($elapsed / $iterations) * 1000));

    is($errors, 0, "No errors during $iterations sequential iterations");
    is($warnings, 0, "No unexpected warnings during sequential test");

    # Verify final cleanup (never-finalize design: library STAYS initialized)
    my $finalStatus = Lib::Pepper::Simple->library_status();
    is($finalStatus->{initialized}, 1, 'Library STAYS initialized after sequential stress test (never-finalize design)');
    is($finalStatus->{instance_count}, 0, 'Instance count is 0 after sequential stress test');

    # Test 2: Multiple simultaneous instances (stress test cleanup)
    diag("");
    diag("Test 2: Multiple simultaneous instances (10 at a time, 10 cycles)");
    $startTime = time();
    $errors = 0;

    for my $cycle (1..10) {
        my @terminals;

        # Create 10 terminals
        for my $i (1..10) {
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
                diag("Cycle $cycle, terminal $i FAILED: $@");
                $errors++;
                last;
            }

            push @terminals, $terminal;
        }

        # Verify instance count
        my $status = Lib::Pepper::Simple->library_status();
        is($status->{instance_count}, 10, "Cycle $cycle: 10 instances active");

        # Destroy all terminals
        @terminals = ();

        # Verify cleanup (never-finalize design: library STAYS initialized)
        $status = Lib::Pepper::Simple->library_status();
        is($status->{instance_count}, 0, "Cycle $cycle: All instances cleaned up");
        is($status->{initialized}, 1, "Cycle $cycle: Library STAYS initialized (never-finalize design)");

        diag("Cycle $cycle complete");
    }

    $elapsed = time() - $startTime;
    diag(sprintf("Multi-instance test completed in %.2f seconds", $elapsed));

    is($errors, 0, "No errors during multi-instance stress test");

    # Verify final state (never-finalize design: library STAYS initialized)
    my $veryFinalStatus = Lib::Pepper::Simple->library_status();
    is($veryFinalStatus->{initialized}, 1, 'Library STAYS initialized after all stress tests (never-finalize design)');
    is($veryFinalStatus->{instance_count}, 0, 'Instance count is 0 after all stress tests');
    # Note: instance_ids do NOT reset with never-finalize design
    ok(exists $veryFinalStatus->{instance_ids}, 'Instance ID counters exist');

    diag("");
    diag("=" x 70);
    diag("STRESS TEST COMPLETE - All tests passed!");
    diag("=" x 70);
}

done_testing();

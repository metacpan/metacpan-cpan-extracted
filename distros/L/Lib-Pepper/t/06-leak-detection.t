use strict;
use warnings;

use Test::More;
use File::Spec;

# Load required modules first
use Lib::Pepper::Simple;
use Lib::Pepper::Constants qw(:all);

# Author-only test: requires PEPPER_LICENSE environment variable
# Usage: PEPPER_LICENSE=/path/to/license.xml perl t/06-leak-detection.t
my $licenseFile = $ENV{PEPPER_LICENSE};
my $configFile = File::Spec->catfile('examples', 'config', 'pepper_config.xml');
my $libraryPath = (-f 'libpepcore.so' ? File::Spec->rel2abs('libpepcore.so') : '');
my $license_xml;
my $config_xml;

# Read files into XML strings (like working examples do)
if(defined $licenseFile && -f $licenseFile) {
    open(my $fh, '<', $licenseFile) or die "Cannot open license file: $!";
    $license_xml = do { local $/; <$fh> };
    close($fh);
}

if(-f $configFile) {
    open(my $fh, '<', $configFile) or die "Cannot open config file: $!";
    $config_xml = do { local $/; <$fh> };
    close($fh);
}

unless(defined $licenseFile && -f $licenseFile && -f $configFile) {
    plan skip_all => 'Author-only test: Set PEPPER_LICENSE=/path/to/license.xml to run leak detection tests';
}

# Verify modules loaded
pass('Lib::Pepper::Simple loaded');
pass('Lib::Pepper::Constants loaded');

# Try to load leak detection modules
my $have_devel_leak = eval { require Devel::Leak; 1; };
my $have_devel_size = eval { require Devel::Size; 1; };

diag("");
diag("=" x 70);
diag("MEMORY LEAK DETECTION TESTS");
diag("=" x 70);
diag("");
diag("License file: $licenseFile");
diag("Config file:  $configFile");
diag("");
diag("Available tools:");
diag("  Devel::Leak: " . ($have_devel_leak ? "YES" : "NO"));
diag("  Devel::Size: " . ($have_devel_size ? "YES" : "NO"));
diag("");

# Check initial library state
my $initial_lib_status = Lib::Pepper::Simple->library_status();
diag("Initial library state:");
diag("  Initialized:    $initial_lib_status->{initialized}");
diag("  Instance count: $initial_lib_status->{instance_count}");
diag("");

# TEST 1: Devel::Leak - Perl SV leak detection
SKIP: {
    skip 'Devel::Leak not available', 3 unless $have_devel_leak;

    diag("--- Test 1: Perl SV Leak Detection (Devel::Leak) ---");

    my $handle;
    my $initial_count = Devel::Leak::NoteSV($handle);
    diag("Initial SV count: $initial_count");

    # Create and destroy 10 terminals
    # Note: Never-finalize design allows unlimited create/destroy cycles
    for my $i (1..10) {
        my $terminal = Lib::Pepper::Simple->new(
            terminal_type    => PEP_TERMINAL_TYPE_GENERIC_ZVT,
            terminal_address => '192.168.1.163:20008',
            license_xml      => $license_xml,
            config_xml       => $config_xml,
            library_path     => $libraryPath,
        );

        # Do a simple status check to exercise the object
        my $status = $terminal->checkStatus();

        # Destroy terminal
        undef $terminal;
    }

    my $final_count = Devel::Leak::CheckSV($handle);
    my $leaked_svs = $final_count - $initial_count;

    diag("Final SV count:   $final_count");
    diag("Leaked SVs:       $leaked_svs");
    diag("");

    # Allow some tolerance for Perl internals (caches, etc.)
    # Typical leak-free code might show 0-50 SVs depending on Perl version
    ok($leaked_svs < 100, "Perl SV leaks acceptable (< 100): $leaked_svs");

    if($leaked_svs > 0) {
        diag("Note: Small SV count increases can be normal due to Perl's internal caching");
    }
}

# TEST 2: Process Memory Growth Detection
SKIP: {
    skip 'Devel::Size not available', 3 unless $have_devel_size;

    diag("--- Test 2: Process Memory Growth Detection ---");

    # Get initial memory usage
    my $ps_output = `ps -o rss= -p $$`;
    my $initial_memory = $ps_output + 0;  # Convert to number
    diag("Initial memory:   $initial_memory KB");

    # Create and destroy terminals with memory sampling
    # Note: Never-finalize design allows unlimited create/destroy cycles
    my @memory_samples;
    for my $i (1..20) {
        my $terminal = Lib::Pepper::Simple->new(
            terminal_type    => PEP_TERMINAL_TYPE_GENERIC_ZVT,
            terminal_address => '192.168.1.163:20008',
            license_xml      => $license_xml,
            config_xml       => $config_xml,
            library_path     => $libraryPath,
        );

        # Exercise the object
        my $status = $terminal->checkStatus();

        # Sample memory every 5 iterations
        if($i % 5 == 0) {
            $ps_output = `ps -o rss= -p $$`;
            push @memory_samples, $ps_output + 0;
        }

        undef $terminal;
    }

    # Get final memory usage
    $ps_output = `ps -o rss= -p $$`;
    my $final_memory = $ps_output + 0;
    my $memory_growth = $final_memory - $initial_memory;

    diag("Final memory:     $final_memory KB");
    diag("Memory growth:    $memory_growth KB");
    diag("Memory samples:   " . join(", ", @memory_samples) . " KB");
    diag("");

    # Check if memory is stable (not constantly growing)
    my $growing_trend = 0;
    for my $i (1..$#memory_samples) {
        $growing_trend++ if $memory_samples[$i] > $memory_samples[$i-1];
    }

    my $samples_count = scalar(@memory_samples) - 1;
    my $growth_percentage = ($growing_trend / $samples_count) * 100;

    diag("Samples showing growth: $growing_trend / $samples_count ($growth_percentage%)");

    # Memory should not constantly grow (allow some variation due to malloc behavior)
    ok($growth_percentage < 80, "Memory not constantly growing: $growth_percentage%");

    # Total growth should be reasonable (< 5 MB for 20 iterations)
    ok($memory_growth < 5_000, "Total memory growth acceptable (< 5MB): ${memory_growth}KB");
}

# TEST 3: Library State Cleanup Verification
{
    diag("--- Test 3: Library State Cleanup Verification ---");

    # Initial state
    my $initial_status = Lib::Pepper::Simple->library_status();
    is($initial_status->{instance_count}, 0, "Initial instance count is 0");

    # Create multiple terminals
    my @terminals;
    for my $i (1..5) {
        push @terminals, Lib::Pepper::Simple->new(
            terminal_type    => PEP_TERMINAL_TYPE_GENERIC_ZVT,
            terminal_address => '192.168.1.163:20008',
            license_xml      => $license_xml,
            config_xml       => $config_xml,
            library_path     => $libraryPath,
        );
    }

    my $mid_status = Lib::Pepper::Simple->library_status();
    is($mid_status->{instance_count}, 5, "Instance count is 5 after creating 5 terminals");

    # Destroy all terminals
    @terminals = ();

    my $final_status = Lib::Pepper::Simple->library_status();
    is($final_status->{instance_count}, 0, "Instance count returns to 0 after cleanup");
    is($final_status->{initialized}, 1, "Library STAYS initialized (never-finalize design)");
    # Note: instance_ids do NOT reset with never-finalize design
    ok(exists $final_status->{instance_ids}, "Instance ID counters exist");

    diag("");
}

# TEST 4: Stress Test with Leak Monitoring
{
    diag("--- Test 4: Extended Stress Test (50 iterations) ---");

    my $errors = 0;
    my $leak_detected = 0;

    # Never-finalize design allows unlimited create/destroy cycles without keeper pattern
    for my $i (1..50) {
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
            diag("Iteration $i failed: $@");
            $errors++;
            last;
        }

        # Check instance count
        my $status = Lib::Pepper::Simple->library_status();
        if($status->{instance_count} != 1) {
            diag("Iteration $i: Wrong instance count: $status->{instance_count} (expected 1)");
            $leak_detected = 1;
        }

        undef $terminal;

        # Verify cleanup
        $status = Lib::Pepper::Simple->library_status();
        if($status->{instance_count} != 0) {
            diag("Iteration $i: Cleanup failed, count: $status->{instance_count} (expected 0)");
            $leak_detected = 1;
        }

        if($i % 10 == 0) {
            diag("Progress: $i/50 iterations complete");
        }
    }

    my $final_status = Lib::Pepper::Simple->library_status();

    is($errors, 0, "No errors during 50 iterations (never-finalize design)");
    is($leak_detected, 0, "No reference count leaks detected");
    is($final_status->{instance_count}, 0, "Final cleanup successful");

    diag("");
}

diag("=" x 70);
diag("MEMORY LEAK DETECTION COMPLETE");
diag("=" x 70);

done_testing();

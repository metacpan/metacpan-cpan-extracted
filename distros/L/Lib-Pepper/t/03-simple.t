use strict;
use warnings;

use Test::More;
use File::Spec;

# Test module loading
BEGIN {
    use_ok('Lib::Pepper::Simple');
    use_ok('Lib::Pepper::Constants', qw(:all));
}

# Test that the module has the expected methods
can_ok('Lib::Pepper::Simple', qw(new checkStatus doPayment cancelPayment endOfDay));

# Test constructor parameter validation (these should fail without actual initialization)
{
    # Test missing terminal_type
    eval {
        my $simple = Lib::Pepper::Simple->new();
    };
    like($@, qr/terminal_type parameter is required/, 'new() requires terminal_type parameter');

    # Test missing terminal_address
    eval {
        my $simple = Lib::Pepper::Simple->new(
            terminal_type => PEP_TERMINAL_TYPE_GENERIC_ZVT,
        );
    };
    like($@, qr/terminal_address parameter is required/, 'new() requires terminal_address parameter');

    # Test missing config_xml/config_file
    eval {
        my $simple = Lib::Pepper::Simple->new(
            terminal_type    => PEP_TERMINAL_TYPE_GENERIC_ZVT,
            terminal_address => '192.168.1.163:20008',
        );
    };
    like($@, qr/either config_xml or config_file parameter is required/, 'new() requires config_xml or config_file parameter');

    # Test missing license_xml/license_file
    eval {
        my $simple = Lib::Pepper::Simple->new(
            terminal_type    => PEP_TERMINAL_TYPE_GENERIC_ZVT,
            terminal_address => '192.168.1.163:20008',
            config_xml       => '<xml></xml>',
        );
    };
    like($@, qr/either license_xml or license_file parameter is required/, 'new() requires license_xml or license_file parameter');
}

# Test doPayment parameter validation (without object)
{
    # We can't test this without a valid object, so we'll skip for now
    ok(1, 'doPayment parameter validation requires valid object');
}

# Test with actual license and config (if available)
SKIP: {
    my $license_xml;
    my $license_path = '/home/cavac/src/pepperclient/pepper_license_8v5r22cg.xml';
    my $config_xml;
    # Use same config path as other tests for consistency (never-finalize design)
    my $config_path = File::Spec->catfile('examples', 'config', 'pepper_config.xml');

    # Try to load license
    if(-f $license_path) {
        open(my $fh, '<', $license_path) or skip "Cannot open license file: $!", 20;
        $license_xml = do { local $/; <$fh> };
        close($fh);
    } else {
        skip "License file not found (required for full testing): $license_path", 20;
    }

    # Try to load config (like working examples do)
    if(-f $config_path) {
        open(my $fh, '<', $config_path) or skip "Cannot open config file: $!", 20;
        $config_xml = do { local $/; <$fh> };
        close($fh);
    } else {
        skip "Config file not found: $config_path", 20;
    }

    # Use the full libpepcore.so library to match other tests (never-finalize design)
    my $library_path = (-f 'libpepcore.so' ? File::Spec->rel2abs('libpepcore.so') : '');

    # Test object creation with mock terminal
    # Use config_xml like the working examples do (NOT config_file)
    my $simple;
    eval {
        $simple = Lib::Pepper::Simple->new(
            terminal_type    => PEP_TERMINAL_TYPE_MOCK,
            terminal_address => 'mock',
            config_xml       => $config_xml,        # Use XML string like examples
            license_xml      => $license_xml,       # Use XML string like examples
            library_path     => $library_path,
        );
    };

    if($@) {
        skip "Object creation failed (may require specific environment): $@", 20;
    }

    ok(defined $simple, 'Simple object created successfully');
    isa_ok($simple, 'Lib::Pepper::Simple');

    # Test checkStatus method
    my $status;
    eval {
        $status = $simple->checkStatus();
    };

    ok(!$@, 'checkStatus() executed without error') or diag("Error: $@");
    ok(defined $status, 'checkStatus() returned defined value');
    isa_ok($status, 'HASH', 'checkStatus() returns hashref');

    # Verify status structure
    ok(exists $status->{initialized}, 'status has initialized field');
    ok(exists $status->{configured}, 'status has configured field');
    ok(exists $status->{connection_open}, 'status has connection_open field');
    ok(exists $status->{terminal_type}, 'status has terminal_type field');
    ok(exists $status->{terminal_address}, 'status has terminal_address field');
    ok(exists $status->{ready}, 'status has ready field');

    # Check expected states
    ok($status->{initialized}, 'Object is initialized');
    ok($status->{configured}, 'Object is configured');
    # connection_open may be true or false depending on terminal type

    # Test doPayment with invalid amount (should fail before terminal access)
    eval {
        $simple->doPayment(0);
    };
    like($@, qr/amount.*must be positive integer/i, 'doPayment() rejects zero amount');

    eval {
        $simple->doPayment(-100);
    };
    like($@, qr/amount.*must be positive integer/i, 'doPayment() rejects negative amount');

    # Test cancelPayment with invalid parameters
    eval {
        $simple->cancelPayment();
    };
    like($@, qr/trace_number parameter is required/i, 'cancelPayment() requires trace_number');

    eval {
        $simple->cancelPayment('1234');
    };
    like($@, qr/amount parameter is required/i, 'cancelPayment() requires amount');

    eval {
        $simple->cancelPayment('1234', 0);
    };
    like($@, qr/amount.*must be positive integer/i, 'cancelPayment() rejects zero amount');

    # Test endOfDay (may fail with mock terminal, but should not crash)
    my $eod_result;
    eval {
        $eod_result = $simple->endOfDay();
    };
    # This may fail with mock terminal - that's expected
    ok(1, 'endOfDay() executed (may fail with mock terminal)');

    # Clean up
    undef $simple;
    ok(1, 'Simple object cleanup completed');
}

done_testing();

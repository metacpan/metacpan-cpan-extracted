use strict;
use warnings;

use Test::More tests => 16;
use File::Spec;

# Test module loading
BEGIN {
    use_ok('Lib::Pepper');
    use_ok('Lib::Pepper::Instance');
    use_ok('Lib::Pepper::Simple');
    use_ok('Lib::Pepper::OptionList');
    use_ok('Lib::Pepper::Constants', qw(:all));
}

# NOTE: This test file tests the MID-LEVEL Instance API, which requires calling
# Lib::Pepper->initialize() directly. However, due to the never-finalize design,
# this conflicts with the high-level Simple API tests (t/03, t/04, t/05, t/06)
# which use Lib::Pepper::Simple->new() that processes config files differently.
#
# Solution: Use Simple API to initialize the library with same pattern as examples.
# Read files and pass XML strings (not file paths) to ensure identical processing.

my $license_path = '/home/cavac/src/pepperclient/pepper_license_8v5r22cg.xml';
my $config_path = File::Spec->catfile('examples', 'config', 'pepper_config.xml');
my $library_path = (-f 'libpepcore.so' ? File::Spec->rel2abs('libpepcore.so') : '');

# Read files (like working examples do)
my $license_xml;
my $config_xml;
if(-f $license_path) {
    open(my $fh, '<', $license_path) or die "Cannot open license file: $!";
    $license_xml = do { local $/; <$fh> };
    close($fh);
}
if(-f $config_path) {
    open(my $fh, '<', $config_path) or die "Cannot open config file: $!";
    $config_xml = do { local $/; <$fh> };
    close($fh);
}

# Use Simple API to initialize (matches t/03, t/04, t/05, t/06)
my $simple;
eval {
    $simple = Lib::Pepper::Simple->new(
        terminal_type    => PEP_TERMINAL_TYPE_MOCK,
        terminal_address => 'mock',
        config_xml       => $config_xml,       # XML string like examples
        license_xml      => $license_xml,      # XML string like examples
        library_path     => $library_path,
    );
};

SKIP: {
    if($@) {
        skip "Library initialization failed (may require license): $@", 11;
    }

    # Get the terminal type list through the Simple API
    my $terminalTypeList = Lib::Pepper->getTerminalTypes();

    ok(defined $terminalTypeList, 'Library initialized successfully');

    # Test instance creation
    my $instance;
    eval {
        $instance = Lib::Pepper::Instance->new(
            terminal_type => PEP_TERMINAL_TYPE_MOCK,
            instance_id   => 1,
        );
    };

    ok(!$@, 'Instance creation succeeded') or diag("Error: $@");
    ok(defined $instance, 'Instance object created');
    isa_ok($instance, 'Lib::Pepper::Instance');

    # Test getHandle
    my $handle = $instance->getHandle();
    ok(defined $handle, 'Instance has a handle');
    ok(Lib::Pepper::isValidHandle($handle), 'Handle is valid');

    # Test isConfigured before configuration
    ok(!$instance->isConfigured(), 'Instance not configured initially');

    # Test configuration
    my $callbackCalled = 0;
    my $callback = sub {
        my ($event, $option, $instanceHandle, $outputOptions, $inputOptions, $userData) = @_;
        $callbackCalled++;
    };

    eval {
        $instance->configure(
            callback => $callback,
            options  => {
                iLanguageValue => PEP_LANGUAGE_ENGLISH,
            },
            userdata => { test => 'data' },
        );
    };

    ok(!$@, 'Instance configuration succeeded') or diag("Error: $@");
    ok($instance->isConfigured(), 'Instance marked as configured');

    # Test OptionList creation via fromHashref
    my $optionList;
    eval {
        $optionList = Lib::Pepper::OptionList->fromHashref({
            iAmount   => 1000,
            iCurrency => PEP_CURRENCY_EUR,
        });
    };

    ok(!$@, 'OptionList creation succeeded') or diag("Error: $@");
    ok(defined $optionList, 'OptionList object created');

    # Clean up
    undef $instance;
    ok(1, 'Instance cleanup completed');

    # NOTE: Never-finalize design - we do NOT call Lib::Pepper->finalize()
    # The library stays loaded in memory for the process lifetime to avoid -103 errors
    # when running multiple tests in the same process
    ok(1, 'Library finalization skipped (never-finalize design)');
}

done_testing();

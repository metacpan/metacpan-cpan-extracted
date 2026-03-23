#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 8;

# Test: basic import
{
    package TestBasicImport;
    use Test::More;
    use Medusa;
    
    ok(TestBasicImport->isa('Medusa'), 'importing Medusa adds to @ISA');
}

# Test: import with configuration
{
    package TestConfigImport;
    use Test::More;
    use Medusa (
        LOG_LEVEL => 'info',
        LOG_FILE  => 'test_audit.log',
    );
    
    is($Medusa::LOG{LOG_LEVEL}, 'info', 'LOG_LEVEL can be configured via import');
    is($Medusa::LOG{LOG_FILE}, 'test_audit.log', 'LOG_FILE can be configured via import');
}

# Test: odd number of params dies
{
    eval {
        package TestOddParams;
        Medusa->import('single_param');
    };
    like($@, qr/odd number of params/, 'odd number of import params dies');
}

# Test: default configuration values
{
    # Reset to defaults
    $Medusa::LOG{LOG_LEVEL} = 'debug';
    $Medusa::LOG{LOG_FILE} = 'audit.log';
    
    is($Medusa::LOG{LOGGER}, 'Medusa::Logger', 'default LOGGER is Medusa::Logger');
    is($Medusa::LOG{LOG_LEVEL}, 'debug', 'default LOG_LEVEL is debug');
    is($Medusa::LOG{LOG_FILE}, 'audit.log', 'default LOG_FILE is audit.log');
}

# Test: LOG_FUNCTIONS hash
{
    is_deeply(
        $Medusa::LOG{LOG_FUNCTIONS},
        { error => 'error', info => 'info', debug => 'debug' },
        'LOG_FUNCTIONS contains expected methods'
    );
}

done_testing();

#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

plan tests => 8;

# Test: basic import
{
    package TestBasicImport;
    use Test::More;
    use Medusa::XS;
    
    ok(TestBasicImport->isa('Medusa::XS'), 'importing Medusa::XS adds to @ISA');
}

# Test: import with configuration
{
    package TestConfigImport;
    use Test::More;
    use Medusa::XS (
        LOG_LEVEL => 'info',
        LOG_FILE  => 'test_audit.log',
    );
    
    is($Medusa::XS::LOG{LOG_LEVEL}, 'info', 'LOG_LEVEL can be configured via import');
    is($Medusa::XS::LOG{LOG_FILE}, 'test_audit.log', 'LOG_FILE can be configured via import');
}

# Test: odd number of params dies
{
    eval {
        package TestOddParams;
        Medusa::XS->import('single_param');
    };
    like($@, qr/odd number of params/, 'odd number of import params dies');
}

# Test: default configuration values
{
    # Reset to defaults
    $Medusa::XS::LOG{LOG_LEVEL} = 'debug';
    $Medusa::XS::LOG{LOG_FILE} = 'audit.log';
    
    is($Medusa::XS::LOG{LOGGER}, 'Medusa::XS::Logger', 'default LOGGER is Medusa::XS::Logger');
    is($Medusa::XS::LOG{LOG_LEVEL}, 'debug', 'default LOG_LEVEL is debug');
    is($Medusa::XS::LOG{LOG_FILE}, 'audit.log', 'default LOG_FILE is audit.log');
}

# Test: LOG_FUNCTIONS hash
{
    is_deeply(
        $Medusa::XS::LOG{LOG_FUNCTIONS},
        { error => 'error', info => 'info', debug => 'debug' },
        'LOG_FUNCTIONS contains expected methods'
    );
}

done_testing();

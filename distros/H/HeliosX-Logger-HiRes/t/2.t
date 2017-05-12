
use Test::More;

my $NUMBER_OF_TESTS = 6;

# don't run these tests unless $HELIOS_INI is defined
if ( !defined($ENV{HELIOS_INI}) ) {
    plan skip_all => '$HELIOS_INI not set; tests skipped.';
} else {
    plan tests => $NUMBER_OF_TESTS;
}

# get config
use_ok('Helios::Config');
my $config_class = Helios::Config->init();
ok ( $config_class->parseConfig(), 'parsing configuration'); 
my $conf = $config_class->getConfig();
ok( defined($conf->{dsn}), 'dsn for collective database');
# if log_priority_threshold is set, remove it so the test will work
if ( defined($conf->{log_priority_threshold}) ) {
    delete $conf->{log_priority_threshold};
}


# now, we'll manually set up the logger class outside of Helios
use_ok('HeliosX::Logger::HiRes');
HeliosX::Logger::HiRes->setConfig($conf);
HeliosX::Logger::HiRes->setService('HeliosX::Logger::HiRes');
HeliosX::Logger::HiRes->setHostname($config_class->getHostname());
HeliosX::Logger::HiRes->init();

# next, we'll try to log a test message using the logger
ok( HeliosX::Logger::HiRes->logMsg(undef, 7, "Test message") );

# ok, if we got here, all the real tests passed!
# BUT, we have to clean up after ourselves
# (Who wants debug messages from a code test lying around
# in their very important log?)
my $d = HeliosX::Logger::HiRes->getDriver();
my @test_msgs = $d->search('HeliosX::Logger::HiRes::LogEntry' => { service => 'HeliosX::Logger::HiRes'} );
# if the previous tests worked, we should have at least 1 of these
# using cmp_ok will also allow us to clear previous failed tests too
cmp_ok(scalar(@test_msgs), '>=', 1, scalar(@test_msgs).' test msgs actually logged');
# ok, delete the msgs
foreach (@test_msgs) {
    $d->remove($_);
}

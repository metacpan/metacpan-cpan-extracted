use strict;
use warnings;

use Test::More 'no_plan';

use Log::Dispatch::SNMP;

# required parameters only
my %required_parameters = (
       min_level          => 'error',
       ManagementHost     => '192.168.0.1',
       EnterpriseOID      => '1.1.1.1.1.1.1.1.1.1.1',
       LocalIPAddress     => '127.0.0.1',
       SpecificTrapType   => 0,
       ApplicationTrapOID => '2.2.2.2.2.2.2.2.2.2.2',
);
my $logger = Log::Dispatch::SNMP->new(%required_parameters);

ok($logger);
isa_ok($logger, 'Log::Dispatch::SNMP');
isa_ok($logger, 'Log::Dispatch::Output');

# checking required values
is($logger->min_level, $required_parameters{min_level}, 'min_level set');
is($logger->{ManagementHost}, $required_parameters{ManagementHost}, 'ManagementHost set');
is($logger->{EnterpriseOID}, $required_parameters{EnterpriseOID}, 'EnterpriseOID set');
is($logger->{LocalIPAddress}, $required_parameters{LocalIPAddress}, 'LocalIPAddress set');
is($logger->{SpecificTrapType}, $required_parameters{SpecificTrapType}, 'SpecificTrapType set');
is($logger->{ApplicationTrapOID}, $required_parameters{ApplicationTrapOID}, 'ApplicationTrapOID set');


# checking defaults
ok($logger->name, 'logger has a name');
is($logger->max_level, 'emergency', 'max_level default set');
is($logger->{ManagementHostTrapListenPort}, 162, 'ManagementHostTrapListenPort default set');
is($logger->{LocalTrapSendPort}, 161, 'LocalTrapSendPort default set');
is($logger->{CommunityString}, 'public', 'CommunityString default set');
is($logger->{GenericTrapType}, 6, 'GenericTrapType default set');

# making sure mandatory parameters are required
foreach my $parameter (qw(min_level ManagementHost EnterpriseOID LocalIPAddress SpecificTrapType ApplicationTrapOID)) {
    my $value = $required_parameters{$parameter};
    delete $required_parameters{$parameter};
    eval {
        $logger = Log::Dispatch::SNMP->new(%required_parameters);
    };
    ok($@, "parameter '$parameter' is indeed required");

    # put the value back so we can keep testing
    $required_parameters{$parameter} = $value;
}


# making sure optional parameters can be set
my %optional_parameters = (
        name => 'my_snmp_log_object',
        max_level => 'info',
        ManagementHostTrapListenPort => 42,
        LocalTrapSendPort => 10000,
        CommunityString => 'private',
        GenericTrapType => 3,
);
$logger = Log::Dispatch::SNMP->new( %required_parameters,
                                    %optional_parameters
                                  );
is($logger->name, $optional_parameters{name}, 'name parameter overriden');
is($logger->max_level, $optional_parameters{max_level}, 'max_level parameter overriden');
is($logger->{ManagementHostTrapListenPort}, $optional_parameters{ManagementHostTrapListenPort}, 'ManagementHostTrapListenPort parameter overriden');
is($logger->{LocalTrapSendPort}, $optional_parameters{LocalTrapSendPort}, 'LocalTrapSendPort parameter overriden');
is($logger->{CommunityString}, $optional_parameters{CommunityString}, 'CommunityString parameter overriden');
is($logger->{GenericTrapType}, $optional_parameters{GenericTrapType}, 'GenericTrapType parameter overriden');


# and one for the road ;)
ok(1);

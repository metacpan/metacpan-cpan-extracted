use warnings;
use Test::More;
use strict;
use Lemonldap::NG::Portal::Main::Request;

require 't/test-lib.pm';

my $app = LLNG::Manager::Test->new( {
        ini => {
            logLevel    => 'error',
            useSafeJail => 1,
        }
    }
)->p;

my %base_req = (
    REQUEST_URI => '/',
    REMOTE_ADDR => '192.168.2.3',
    PATH_INFO   => '/'
);

# For each rule, define a series of tests structured like this:
# [ a, b, c ]
# where:
# a : a series of environment variables to be set in the $req object
# b : a hash of sessionInfo
# c : expected rule result

my @rulestotest = ( {
        rule  => "inGroup('toto')",
        tests => [
            [ {}, { hGroups => { "titi" => 1 } }, 0 ],
            [ {}, { hGroups => { "toto" => 1 } }, 1 ],
        ]
    },
    {
        rule  => "inSubnet('127.0.0.0/8')",
        tests => [ [ {}, {}, 0 ], [ { REMOTE_ADDR => '127.0.0.2' }, {}, 1 ], ]
    },
    {
        rule  => "inSubnet('127.0.0.0/8', '192.168.0.0/16')",
        tests => [
            [ {}, {}, 1 ],
            [ { REMOTE_ADDR => '127.0.0.2' }, {}, 1 ],
            [ { REMOTE_ADDR => '10.0.0.1' },  {}, 0 ],
        ]
    },
    {
        rule  => "ipInSubnet(\$ipAddr, '127.0.0.0/8', '192.168.0.0/16')",
        tests => [
            [ {}, { ipAddr => "192.168.2.3" }, 1 ],
            [ {}, { ipAddr => "127.8.7.6" },   1 ],
            [ {}, { ipAddr => "10.0.1.2" },    0 ],
        ]
    },
);

{
    no warnings;
    $Data::Dumper::Indent = 0;
    $Data::Dumper::Terse  = 1;
}

for my $rule (@rulestotest) {
    my $rule_text = $rule->{rule};
    my $sub       = $app->buildRule($rule_text);
    for my $test ( @{ $rule->{tests} } ) {
        my ( $req_param, $session_info, $output ) = @{$test};
        my $req = Lemonldap::NG::Portal::Main::Request->new(
            { %base_req, %$req_param } );
        is(
            $sub->( $req, $session_info ),
            $output,
            "Rule $rule_text on input "
              . Dumper( [ $req_param, $session_info ] )
              . " returned $output"
        );
    }
}

done_testing();

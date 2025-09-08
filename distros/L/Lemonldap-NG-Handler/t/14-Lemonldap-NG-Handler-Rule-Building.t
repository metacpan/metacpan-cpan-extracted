# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Handler-SharedConf.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

package main;
use strict;
use warnings;
require 't/test.pm';

use Test::More tests => 4;
BEGIN { use_ok('Lemonldap::NG::Handler::Main') }

# get a standard basic configuration in $args hashref
use Cwd 'abs_path';
use File::Basename;
use lib dirname( abs_path $0 );

#########################

# Insert your test code below, the Test::More module is used here so read
# its man page (perldoc Test::More) for help writing this test script.
my $h;
$h = 'Lemonldap::NG::Handler::Test';
$ENV{SERVER_NAME} = "test1.example.com";

#open STDERR, '>/dev/null';

my $conf = {
    cfgNum        => 1,
    logLevel      => 'error',
    portal        => 'http://auth.example.com/',
    globalStorage => 'Apache::Session::File',
    post          => {},
    key           => 1,
    useSafeJail   => 0,
    locationRules => {
        'test1.example.com' => {

            # Basic rules
            'default' => 'accept',
            '^/no'    => 'deny',
            'test'    => '$groups =~ /\badmin\b/',

            # Bad ordered rules
            '^/a/a' => 'deny',
            '^/a'   => 'accept',

            # Good ordered rules
            '(?#1 first)^/b/a' => 'deny',
            '(?#2 second)^/b'  => 'accept',
        },
    },
};

#########################
# Make sure that the rule building idiom (substitute/buildRule) yields
# consistent results in edge cases see #2595

sub compileRule {
    my $rule = shift;
    return $h->buildSub( $h->substitute($rule) );
}

sub runTests {
    my ($h) = @_;

    # Undef expression yields a sub that returns undef
    my $r = compileRule(undef);
    is( ref($r), "CODE", "Returned code ref" );
    is( $r->(),  undef,  "Returned undef" );

    # empty expression yields a sub that returns undef
    $r = compileRule("");
    is( ref($r), "CODE", "Returned code ref" );
    is( $r->(),  undef,  "Returned undef" );

    # empty string yields a sub that returns undef
    $r = compileRule("\"\"");
    is( ref($r), "CODE", "Returned code ref" );
    is( $r->(),  "",     "Returned empty string" );

    # 0 expression returns a sub that returns 0
    $r = compileRule("0");
    is( ref($r), "CODE", "Returned code ref" );
    is( $r->(),  0,      "Returned 0" );

    # string expression returns a sub that returns the string
    #
    $r = compileRule("\"abc def\"");
    is( ref($r), "CODE",    "Returned code ref" );
    is( $r->(),  "abc def", "Returned abc def" );

    # Access sessionInfo
    $r = compileRule('$foo');
    is( ref($r),                      "CODE", "Returned code ref" );
    is( $r->( {}, { foo => "bar" } ), "bar",  "Returned bar" );

    # Access request
    $r = compileRule('$ENV{foo}');
    is( ref($r),                                 "CODE", "Returned code ref" );
    is( $r->( { env => { foo => "bar" } }, {} ), "bar",  "Returned bar" );

    # inSubnet
    $r = compileRule("inSubnet('127.0.0.1/8')");
    is( ref($r), "CODE", "Returned code ref" );

    is( $r->( { env => { REMOTE_ADDR => "127.0.0.1" } }, {} ),
        "1", "ipInSubnet works" );
    is( $r->( { env => { REMOTE_ADDR => "192.168.0.1" } }, {} ),
        "0", "ipInSubnet works" );

    $r = compileRule("inSubnet('127.0.0.1/8', '192.168.0.0/16')");
    is( ref($r), "CODE", "Returned code ref" );

    is( $r->( { env => { REMOTE_ADDR => "192.168.0.1" } }, {} ),
        "1", "ipInSubnet works" );

    # ipInSubnet
    $r = compileRule("ipInSubnet(\$ENV{X_FORWARDED_FOR},'127.0.0.1/8')");
    is( ref($r), "CODE", "Returned code ref" );

    is( $r->( { env => { X_FORWARDED_FOR => "127.0.0.1" } }, {} ),
        "1", "ipInSubnet works" );
    is( $r->( { env => { X_FORWARDED_FOR => "192.168.0.1" } }, {} ),
        "0", "ipInSubnet works" );

    $r = compileRule(
        "ipInSubnet(\$ENV{X_FORWARDED_FOR}, '127.0.0.1/8', '192.168.0.0/16')");
    is( ref($r), "CODE", "Returned code ref" );

    is( $r->( { env => { X_FORWARDED_FOR => "192.168.0.1" } }, {} ),
        "1", "ipInSubnet works" );

    # inDomain
    $r = compileRule("inDomain('example.com') || 0");
    is( ref($r), "CODE", "Returned code ref" );

    is( $r->( { env => { HTTP_HOST => "AUTH.EXAMPLE.COM" } }, {} ),
        "1", "inDomain works for AUTH.EXAMPLE.COM" );

    is( $r->( { env => { HTTP_HOST => "auth.example.com" } }, {} ),
        "1", "inDomain works for auth.example.com" );

    is( $r->( { env => { HTTP_HOST => "example.com" } }, {} ),
        "1", "inDomain works for example.com" );

    is( $r->( { env => { HTTP_HOST => "cda.com" } }, {} ),
        "0", "inDomain works for cda.com" );

    is( $r->( { env => { HTTP_HOST => "notexample.com" } }, {} ),
        "0", "inDomain works for notexample.com" );
    is( $r->( { env => { HTTP_HOST => "exampleacom" } }, {} ),
        "0", "inDomain works for exampleacom" );

    # Complex expressions
    $r = compileRule('join(":",grep {$_ eq "a"} split(":", $list))');
    is( ref($r), "CODE", "Returned code ref" );
    is(
        $r->(
            { env  => { HTTP_HOST => "AUTH.EXAMPLE.COM" } },
            { list => "a:b:c:a:d:a" }
        ),
        "a:a:a"
    );

}

sub runUnsafeTests {
    my ($h) = @_;
    my $r;

    $r = compileRule('basic($user, $_password)');
    is( ref($r), "CODE", "Returned code ref" );
    is(
        $r->( { env => {} }, { user => "aa", _password => "bc" } ),
        "Basic YWE6YmM=",
        "Returned correct Basic header"
    );
}

eval { $h->localConfig($conf); $h->logLevelInit() };
ok( !$@, 'init' );

subtest "Safe jail off" => sub {
    plan tests => 37;
    ok( $h->configReload($conf), 'Load conf' );
    is(
        ref( $h->tsv->{jail}->jail ),
        "Lemonldap::NG::Handler::Main::Jail",
        "Safe jail is disabled"
    );

    runTests($h);
    runUnsafeTests($h);
};

subtest "Safe jail on" => sub {
    plan tests => 35;
    ok( $h->configReload( { %$conf, useSafeJail => 1 } ), 'Load conf' );
    is( ref( $h->tsv->{jail}->jail ), "Safe", "Safe jail is enabled" );

    runTests($h);
};


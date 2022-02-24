# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Handler-SharedConf.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

package main;
use strict;
use warnings;
require 't/test.pm';

use Test::More tests => 17;
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

eval { $h->localConfig($conf); $h->logLevelInit() };
ok( !$@,                     'init' );
ok( $h->configReload($conf), 'Load conf' );

#########################
# Make sure that the rule building idiom (substitute/buildRule) yields
# consistent results in edge cases see #2595

sub compileRule {
    my $rule = shift;
    return $h->buildSub( $h->substitute($rule) );
}

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

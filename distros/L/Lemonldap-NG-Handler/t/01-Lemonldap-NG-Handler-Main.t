# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Handler.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
package LemonldapNGHandlerMain;
use strict;
use warnings;

use Test::More tests => 10;
BEGIN { use_ok( 'Lemonldap::NG::Handler::Main',   qw(:all) ) }
BEGIN { use_ok( 'Lemonldap::NG::Handler::Reload', qw(:all) ) }

# get a standard basic configuration in $args hashref
use Cwd 'abs_path';
use File::Basename;
use lib dirname( abs_path $0 );

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my $h;
$h = bless {}, 'Lemonldap::NG::Handler::Main';
$ENV{SERVER_NAME} = "test1.example.com";

open STDERR, '>/dev/null';

my $conf = {
    'portal'        => 'http://auth.example.com/',
    'globalStorage' => 'Apache::Session::File',
    'post'          => {},
    'locationRules' => {
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

# includes
# - defaultValuesInit
# - portalInit
# - locationRulesInit
# - globalStorageInit
# - headerListInit
# - forgeHeadersInit
# - postUrlInit
ok(
    Lemonldap::NG::Handler::Reload->configReload(
        $conf, $Lemonldap::NG::Handler::Main::tsv
    )
);

ok( &{ $tsv->{portal} }() eq 'http://auth.example.com/', 'portal' );

ok( $h->grant('/s'),    'basic rule "accept"' );
ok( !$h->grant('/no'),  'basic rule "deny"' );
ok( $h->grant('/a/a'),  'bad ordered rule 1/2' );
ok( $h->grant('/a'),    'bad ordered rule 2/2' );
ok( !$h->grant('/b/a'), 'good ordered rule 1/2' );
ok( $h->grant('/b'),    'good ordered rule 2/2' );

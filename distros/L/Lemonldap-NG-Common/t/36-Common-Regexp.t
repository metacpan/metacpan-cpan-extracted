# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Common.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 20;
use strict;

BEGIN {
    use_ok('Lemonldap::NG::Common::Regexp');
}

#########################

# Insert your test code below, the Test::More module is used here so read
# its man page ( perldoc Test::More ) for help writing this test script.

*HOST            = *Lemonldap::NG::Common::Regexp::HOST;
*HOSTNAME        = *Lemonldap::NG::Common::Regexp::HOSTNAME;
*HTTP_URI        = *Lemonldap::NG::Common::Regexp::HTTP_URI;
*reDomainsToHost = *Lemonldap::NG::Common::Regexp::reDomainsToHost;

ok( 'test.ex.com'                   =~ HOST() );
ok( 'test.ex.com'                   =~ HOSTNAME() );
ok( 'test..ex.com'                  !~ HOST() );
ok( 'test..ex.com'                  !~ HOSTNAME() );
ok( '10.1.1.1'                      =~ HOST() );
ok( '10.1.1.1'                      !~ HOSTNAME() );
ok( 'test.ex.com'                   !~ HTTP_URI() );
ok( 'https://test.ex.com'           =~ HTTP_URI() );
ok( 'https://test.ex.com/'          =~ HTTP_URI() );
ok( 'https://test.ex.com/a'         =~ HTTP_URI() );
ok( 'https://test.ex.com/?<script>' !~ HTTP_URI() );

my $re;
ok( $re = reDomainsToHost('a.com b.org c.net') );
ok( 'test.d.fr' !~ $re );

foreach (qw(a.com b.org c.net)) {
    ok( "test.$_"  =~ $re );
    ok( "test..$_" !~ $re );
}

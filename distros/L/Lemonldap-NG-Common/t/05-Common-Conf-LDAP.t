# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Manager.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;

#########################

# Insert your test code below, the Test::More module is used here so read
# its man page ( perldoc Test::More ) for help writing this test script.

SKIP: {
    eval { require Net::LDAP; };
    skip "Net::LDAP is not installed, skipping tests", 3 if ($@);
    use_ok('Lemonldap::NG::Common::Conf');
    my $h;
    ok(
        $h = new Lemonldap::NG::Common::Conf( {
                type             => 'LDAP',
                ldapServer       => 'ldap://localhost',
                ldapConfBase     => 'ou=conf,ou=websso,dc=example,dc=com',
                ldapBindDN       => 'cn=admin,dc=example,dc=com',
                ldapBindPassword => 'secret',
            }
        ),
        "New object"
    ) or print STDERR "Error reported: " . $Lemonldap::NG::Common::Conf::msg;

    ok( ref($h) and $h->can('ldap') );
}

# Try to launch an LDAP server

use Time::HiRes qw/usleep/;

sub _ldap_cleanup {
    system 'rm -rf t/testslapd/slapd.d';
    system 'rm -rf t/testslapd/data';
    system 'rm -rf t/testslapd/slapd-test.ldif';
}

my $slapd_bin;
my $slapadd_bin;
my $slapd_schema_dir;

if ( $ENV{LLNGTESTLDAP} ) {
    $slapd_bin   = $ENV{LLNGTESTLDAP_SLAPD_BIN}   || '/usr/sbin/slapd';
    $slapadd_bin = $ENV{LLNGTESTLDAP_SLAPADD_BIN} || '/usr/sbin/slapadd';
    $slapd_schema_dir = (
        ( $ENV{LLNGTESTLDAP_SCHEMA_DIR} and -d $ENV{LLNGTESTLDAP_SCHEMA_DIR} )
        ? $ENV{LLNGTESTLDAP_SCHEMA_DIR}
        : -d '/etc/openldap/schema' ? '/etc/openldap/schema'
        :                             '/etc/ldap/schema'
    );

    eval { mkdir 't/testslapd/slapd.d' };
    eval { mkdir 't/testslapd/data' };
    system('cp t/testslapd/slapd.ldif t/testslapd/slapd-test.ldif');
    system(
"/bin/sed -i 's:__SCHEMA_DIR__:$slapd_schema_dir:' t/testslapd/slapd-test.ldif"
    );
    system( $slapadd_bin
          . ' -F t/testslapd/slapd.d -n 0 -l t/testslapd/slapd-test.ldif' );
    system( $slapadd_bin
          . ' -F t/testslapd/slapd.d -n 1 -l t/testslapd/users.ldif' );
    system( $slapd_bin
          . ' -s 256 -h "ldap://127.0.0.1:19389/" -F t/testslapd/slapd.d' );
}

sub stopLdapServer {
    if ( $ENV{LLNGTESTLDAP} ) {
        open F, 't/testslapd/slapd.pid';
        my $pid = join '', <F>;
        my $die = 0;
        close F;
        if ($pid) {
            system "kill $pid";

            # give the PID 10 seconds to stop
            my $waitloop = 0;
            while ( $waitloop < 1000 and kill 0, $pid ) {
                $waitloop++;
                usleep 10000;
            }
        }
        else {

            $die = "Could not stop slapd";
        }
        _ldap_cleanup();
        die($die) if $die;
    }
}

sub tempStopLdapServer {
    if ( $ENV{LLNGTESTLDAP} ) {
        open F, 't/testslapd/slapd.pid';
        my $pid = join '', <F>;
        close F;
        if ($pid) {
            system "kill $pid";

            # give the PID 10 seconds to stop
            my $waitloop = 0;
            while ( $waitloop < 1000 and kill 0, $pid ) {
                $waitloop++;
                usleep 10000;
            }
        }
        else {
            _ldap_cleanup();
            die("Could not stop slapd");
        }
    }
}

sub tempStartLdapServer {
    if ( $ENV{LLNGTESTLDAP} ) {
        system( $slapd_bin
              . ' -s 256 -h "ldap://127.0.0.1:19389/" -F t/testslapd/slapd.d' );
    }
}
1;

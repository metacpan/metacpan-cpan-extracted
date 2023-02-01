# Try to launch an LDAP server

use URI::Escape qw/uri_escape/;
use Time::HiRes qw/usleep/;
use Test::More;
use Net::LDAP;

use File::Copy "cp";

my $slapd_bin;
my $slapadd_bin;
my $slapd_schema_dir;
our $slapd_url = 'ldapi://' . uri_escape( $main::tmpDir . '/ldap_socket' );
our $slapd_pid;

if ( $ENV{LLNGTESTLDAP} ) {
    $slapd_bin        = $ENV{LLNGTESTLDAP_SLAPD_BIN}   || '/usr/sbin/slapd';
    $slapadd_bin      = $ENV{LLNGTESTLDAP_SLAPADD_BIN} || '/usr/sbin/slapadd';
    $slapd_schema_dir = (
        ( $ENV{LLNGTESTLDAP_SCHEMA_DIR} and -d $ENV{LLNGTESTLDAP_SCHEMA_DIR} )
        ? $ENV{LLNGTESTLDAP_SCHEMA_DIR}
        : -d '/etc/openldap/schema' ? '/etc/openldap/schema'
        :                             '/etc/ldap/schema'
    );

    eval { mkdir "$main::tmpDir/slapd.d" };
    eval { mkdir "$main::tmpDir/data" };
    cp( "t/testslapd/slapd.ldif", "$main::tmpDir/slapd-test.ldif" );
    system(
        "/bin/sed", "-i",
        "s:__SCHEMA_DIR__:$slapd_schema_dir:",
        "$main::tmpDir/slapd-test.ldif"
    );
    system(
        "/bin/sed",                       "-i",
        "s:t/testslapd/:$main::tmpDir/:", "$main::tmpDir/slapd-test.ldif"
    );
    system( $slapadd_bin, "-F", "$main::tmpDir/slapd.d", "-n", "0",
        "-l", "$main::tmpDir/slapd-test.ldif" );
    system( $slapadd_bin, "-F", "$main::tmpDir/slapd.d", "-n", "1",
        "-l", "t/testslapd/users.ldif" );
    startLdapServer();
}

sub waitForLdap {
    my $waitloop = 0;
    note "Waiting for LDAP server to be available";
    while ( $waitloop < 100 and !Net::LDAP->new($slapd_url) ) {
        $waitloop++;
        usleep 100000;
    }
    die "Timed out waiting for LDAP server to start" if $waitloop == 100;
    open F, "$main::tmpDir/slapd.pid";
    $slapd_pid = join '', <F>;
    chomp $slapd_pid;
    close F;
    die "Could not find LDAP server PID" unless $slapd_pid;
    note "LDAP server ($slapd_pid) available at $slapd_url";
}

sub stopLdapServer {
    if ( $ENV{LLNGTESTLDAP} ) {
        note "Stopping LDAP server ($slapd_pid)";
        my $pid = $slapd_pid;
        kill 15, $pid;

        # give the PID 10 seconds to stop
        my $waitloop = 0;
        while ( $waitloop < 1000 and kill 0, $pid ) {
            $waitloop++;
            usleep 10000;
        }
        if ( kill 0, $pid ) {
            note "Could not kill LDAP server normally, sending SIGKILL";
            kill 9, $pid;
        }
        else {
            note "LDAP server stopped successfully";
        }
    }
}

sub startLdapServer {
    note "Starting LDAP server";
    if ( $ENV{LLNGTESTLDAP} ) {
        system( $slapd_bin, '-s', '256', '-h', $slapd_url,
            '-F', "$main::tmpDir/slapd.d" );
    }
    waitForLdap();
}

END {
    stopLdapServer();
}
1;

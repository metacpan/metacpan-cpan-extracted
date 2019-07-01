# Try to launch an LDAP server

if ( $ENV{LLNGTESTLDAP} ) {
    my $slapd_bin   = $ENV{LLNGTESTLDAP_SLAPD_BIN}   || '/usr/sbin/slapd';
    my $slapadd_bin = $ENV{LLNGTESTLDAP_SLAPADD_BIN} || '/usr/sbin/slapadd';
    my $slapd_schema_dir =
      ( $ENV{LLNGTESTLDAP_SCHEMA_DIR}
          and -d $ENV{LLNGTESTLDAP_SCHEMA_DIR} ? $ENV{LLNGTESTLDAP_SCHEMA_DIR}
        : -d '/etc/slapd/schema' ? '/etc/slapd/schema'
        :                          '/etc/ldap/schema' );
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
        system "kill $pid";
        system 'rm -rf t/testslapd/slapd.d';
        system 'rm -rf t/testslapd/data';
        system 'rm -rf t/testslapd/slapd-test.ldif';
    }
}
1;

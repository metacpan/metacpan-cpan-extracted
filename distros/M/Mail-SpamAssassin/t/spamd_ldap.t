#!/usr/bin/perl -T
#
# NOTE: requires setup as per ldap/README.testing in advance

use lib '.'; use lib 't';
use SATest; sa_t_init("spamd_ldap");

use Test::More;
plan skip_all => "LDAP tests disabled" unless (-e 't/do_ldap' || -e 'do_ldap');
plan tests => 8;

# ---------------------------------------------------------------------------

%patterns = (

q{ Subject: There yours for FREE!}, 'subj',
q{ X-Spam-Status: Yes, score=}, 'status',
q{ X-Spam-Flag: YES}, 'flag',
q{ X-Spam-Level: **********}, 'stars',
q{ X-Spam-Foo: LDAP read}, 'ldap_config_read',
q{ TEST_ENDSNUMS}, 'endsinnums',
q{ TEST_NOREALNAME}, 'noreal',


);

tstlocalrules ("
    user_scores_dsn ldap://localhost/o=stooges?spamassassin?sub?uid=__USERNAME__
    user_scores_ldap_username cn=StoogeAdmin,o=stooges
    user_scores_ldap_password secret1
");

ok (sdrun ("-L --ldap-config", "-u curley < data/spam/001", \&patterns_run_cb));
ok_all_patterns();


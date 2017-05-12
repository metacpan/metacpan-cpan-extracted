use Test::More tests => 62;
use Debian::Copyright;
use Test::Deep;
use Test::LongString;
use Test::NoWarnings;

my $copyright = Debian::Copyright->new;
isa_ok($copyright, 'Debian::Copyright');
$copyright->read('t/data/mysql');
is($copyright->header->Format, 'http://www.debian.org/doc/packaging-manuals/copyright-format/1.0/', 'Format');
is($copyright->header->Upstream_Name, 'MySQL 5.5', 'Upstream-Name');
is($copyright->header->Upstream_Contact, 'http://bugs.mysql.com/', 'Upstream-Contact');
is($copyright->header->Source, 'http://dev.mysql.com/downloads/mysql/5.5.html', 'Source');
my $s =<<'EOS';
 The file Docs/mysql.info is removed from the upstream source
 because it is incompatible with the Debian Free Software Guidelines.
 See debian/README.source for how this repacking was done.
 .
 Originally produced by a modified version of licensecheck2dep5
 from CDBS by Clint Byrum <clint@ubuntu.com>. Hand modified to reduce 
 redundancy in the output and add appropriate license text.
 .
 Also, MySQL carries the "FOSS License Exception" specified in README
 .
 Quoting from README:
 .
 MySQL FOSS License Exception We want free and open source
 software applications under certain licenses to be able to use
 specified GPL-licensed MySQL client libraries despite the fact
 that not all such FOSS licenses are compatible with version
 2 of the GNU General Public License.  Therefore there are
 special exceptions to the terms and conditions of the GPLv2
 as applied to these client libraries, which are identified
 and described in more detail in the FOSS License Exception at
 <http://www.mysql.com/about/legal/licensing/foss-exception.html>.
 .
 The text of the Above URL is quoted below, as of Aug 17, 2011.
 .
 > FOSS License Exception
 > .
 > Updated July 1, 2010
 > .
 > What is the FOSS License Exception?  Oracle's Free and Open Source
 > Software ("FOSS") License Exception (formerly known as the FLOSS
 > License Exception) allows developers of FOSS applications to include
 > Oracle's MySQL Client Libraries (also referred to as "MySQL Drivers"
 > or "MySQL Connectors") with their FOSS applications. MySQL Client
 > Libraries are typically licensed pursuant to version 2 of the General
 > Public License ("GPL"), but this exception permits distribution of
 > certain MySQL Client Libraries with a developer's FOSS applications
 > licensed under the terms of another FOSS license listed below,
 > even though such other FOSS license may be incompatible with the GPL.
 > .
 > The following terms and conditions describe the circumstances under
 > which Oracle's FOSS License Exception applies.
 > .
 > Oracle's FOSS License Exception Terms and Conditions Definitions.
 > "Derivative Work" means a derivative work, as defined under applicable
 > copyright law, formed entirely from the Program and one or more
 > FOSS Applications.
 > .
 > "FOSS Application" means a free and open source software application
 > distributed subject to a license listed in the section below titled
 > "FOSS License List."
 > .
 > "FOSS Notice" means a notice placed by Oracle or MySQL in a copy
 > of the MySQL Client Libraries stating that such copy of the MySQL
 > Client Libraries may be distributed under Oracle's or MySQL's FOSS
 > (or FLOSS) License Exception.
 > .
 > "Independent Work" means portions of the Derivative Work that are not
 > derived from the Program and can reasonably be considered independent
 > and separate works.
 > .
 > "Program" means a copy of Oracle's MySQL Client Libraries that
 > contains a FOSS Notice.
 > . 
 > A FOSS application developer ("you" or "your") may distribute a
 > Derivative Work provided that you and the Derivative Work meet all
 > of the following conditions: You obey the GPL in all respects for
 > the Program and all portions (including modifications) of the Program
 > included in the Derivative Work (provided that this condition does not
 > apply to Independent Works); The Derivative Work does not include any
 > work licensed under the GPL other than the Program; You distribute
 > Independent Works subject to a license listed in the section below
 > titled "FOSS License List"; You distribute Independent Works in
 > object code or executable form with the complete corresponding
 > machine-readable source code on the same medium and under the same
 > FOSS license applying to the object code or executable forms; All
 > works that are aggregated with the Program or the Derivative Work
 > on a medium or volume of storage are not derivative works of the
 > Program, Derivative Work or FOSS Application, and must reasonably
 > be considered independent and separate works.  Oracle reserves all
 > rights not expressly granted in these terms and conditions. If all
 > of the above conditions are not met, then this FOSS License Exception
 > does not apply to you or your Derivative Work.
 > .
 > FOSS License List
 > . 
 > License Name    Version(s)/Copyright Date
 > Release Early    Certified Software
 > Academic Free License    2.0
 > Apache Software License  1.0/1.1/2.0
 > Apple Public Source License  2.0
 > Artistic license     From Perl 5.8.0
 > BSD license  "July 22 1999"
 > Common Development and Distribution License (CDDL)   1.0
 > Common Public License    1.0
 > Eclipse Public License   1.0
 > European Union Public License (EUPL)[1]    1.1
 > GNU Library or "Lesser" General Public License (LGPL)    2.0/2.1/3.0
 > GNU General Public License (GPL)     3.0
 > IBM Public License   1.0
 > Jabber Open Source License   1.0
 > MIT License (As listed in file MIT-License.txt)  -
 > Mozilla Public License (MPL)     1.0/1.1
 > Open Software License    2.0
 > OpenSSL license (with original SSLeay license)   "2003" ("1998")
 > PHP License  3.0/3.01
 > Python license (CNRI Python License)     -
 > Python Software Foundation License   2.1.1
 > Sleepycat License   "1999"
 > University of Illinois/NCSA Open Source License  -
 > W3C License  "2001"
 > X11 License  "2001"
 > Zlib/libpng License  -
 > Zope Public License  2.0
 > [1] When an Independent Work is licensed under a "Compatible License"
 > pursuant to the EUPL, the Compatible License rather than the EUPL is
 > the applicable license for purposes of these FOSS License Exception
 > Terms and Conditions.
 .
 The above text is subject to this copyright notice:
 © 2010, Oracle and/or its affiliates.
EOS
chomp $s;
is_string($copyright->header->Comment, "\n$s", 'Comment');

is($copyright->files->Length, 42, 'no of files');

$s = <<'EOS';
cmd-line-utils/libedit/config.h
 dbug/example1.c
 dbug/example2.c
 dbug/example3.c
 dbug/factorial.c
 dbug/main.c
 dbug/my_main.c
 dbug/remove_function_from_trace.pl
 dbug/tests.c
 dbug/tests-t.pl
 extra/yassl/src/dummy.cpp
 include/probes_mysql_nodtrace.h
 libmysqld/resource.h
 mysql-test/*
 regex/*
 sql-bench/graph-compare-results.sh
 storage/ndb/bin/*
 storage/ndb/demos/*
 support-files/binary-configure.sh
 support-files/my-huge.cnf.sh
 support-files/my-innodb-heavy-4G.cnf.sh
 support-files/my-large.cnf.sh
 support-files/my-medium.cnf.sh
 support-files/my-small.cnf.sh
 support-files/mysqld_multi.server.sh
 support-files/mysql-log-rotate.sh
 support-files/mysql.server-sys5.sh
EOS
is($copyright->files->Keys(0), $s);

$s= <<'EOS';
BUILD/*
 Docs/*
 client/*
 client/echo.c
 client/get_password.c
 cmake/*
 dbug/dbug_add_tags.pl
 extra/*
 include/*
 libmysql/*
 libmysqld/*
 libservices/*
 mysql-test/include/have_perfschema.inc
 mysql-test/include/have_perfschema.inc
 mysql-test/lib/mtr_cases.pm
 mysql-test/lib/mtr_gcov.pl
 mysql-test/lib/mtr_gprof.pl
 mysql-test/lib/mtr_io.pl
 mysql-test/lib/mtr_match.pm
 mysql-test/lib/mtr_misc.pl
 mysql-test/lib/mtr_process.pl
 mysql-test/lib/mtr_report.pm
 mysql-test/lib/mtr_results.pm
 mysql-test/lib/mtr_stress.pl
 mysql-test/lib/mtr_unique.pm
 mysql-test/lib/My/ConfigFactory.pm
 mysql-test/lib/My/Config.pm
 mysql-test/lib/My/CoreDump.pm
 mysql-test/lib/My/File/*
 mysql-test/lib/My/Find.pm
 mysql-test/lib/My/Handles.pm
 mysql-test/lib/My/Options.pm
 mysql-test/lib/My/Platform.pm
 mysql-test/lib/My/SafeProcess/Base.pm
 mysql-test/lib/My/SafeProcess.pm
 mysql-test/lib/My/SafeProcess/safe_kill_win.cc
 mysql-test/lib/My/SafeProcess/safe_process.cc
 mysql-test/lib/My/SafeProcess/safe_process.pl
 mysql-test/lib/My/SafeProcess/safe_process_win.cc
 mysql-test/lib/My/SysInfo.pm
 mysql-test/lib/My/Test.pm
 mysql-test/lib/t/*
 mysql-test/lib/v1/mtr_cases.pl
 mysql-test/lib/v1/mtr_gcov.pl
 mysql-test/lib/v1/mtr_gprof.pl
 mysql-test/lib/v1/mtr_im.pl
 mysql-test/lib/v1/mtr_io.pl
 mysql-test/lib/v1/mtr_match.pl
 mysql-test/lib/v1/mtr_misc.pl
 mysql-test/lib/v1/mtr_process.pl
 mysql-test/lib/v1/mtr_report.pl
 mysql-test/lib/v1/mtr_stress.pl
 mysql-test/lib/v1/mtr_timer.pl
 mysql-test/lib/v1/mtr_unique.pl
 mysql-test/lib/v1/My/*
 mysql-test/lib/v1/My/*
 mysql-test/lib/v1/mysql-test-run.pl
 mysql-test/mysql-stress-test.pl
 mysql-test/mysql-test-run.pl
 mysql-test/std_data/*
 mysql-test/suite/perfschema/include/*
 mysql-test/suite/perfschema_stress/include/*
 mysql-test/suite/perfschema_stress/include/*
 mysys/*
 packaging/WiX/ca/*
 plugin/audit_null/*
 plugin/auth/*
 plugin/daemon_example/*
 plugin/fulltext/*
 plugin/semisync/semisync_slave.cc
 plugin/semisync/semisync_slave.h
 scripts/*
 sql/*
 sql-common/*
 storage/*
 strings/*
 support-files/config.huge.ini.sh
 support-files/config.medium.ini.sh
 support-files/config.small.ini.sh
 support-files/MacOSX/Description.plist.sh
 support-files/MacOSX/Info.plist.sh
 support-files/MacOSX/StartupParameters.plist.sh
 support-files/MySQL-shared-compat.spec.sh
 support-files/mysql.spec.sh
 support-files/ndb-config-2-node.ini.sh
 tests/*
 unittest/*
 vio/*
EOS
is($copyright->files->Keys(1), $s);
is($copyright->files->Keys(2), 'storage/innobase/*');
is($copyright->files->Keys(3), 'cmd-line-utils/readline/*');
is($copyright->files->Keys(4), 'cmd-line-utils/libedit/*');

$s = <<'EOS';
cmd-line-utils/libedit/filecomplete.c
 cmd-line-utils/libedit/filecomplete.h
 cmd-line-utils/libedit/np/fgetln.c
 cmd-line-utils/libedit/read.h
 cmd-line-utils/libedit/readline.c
 cmd-line-utils/libedit/readline/*
EOS
is($copyright->files->Keys(5), $s);

$s= <<'EOS';
client/completion_hash.h
 scripts/mysqlaccess.sh
 scripts/mysql_fix_extensions.sh
 scripts/mysql_setpermission.sh
 sql-bench/*
 storage/myisam/ftbench/ft-test-run.sh
 storage/myisam/mi_test_all.sh
 storage/ndb/test/run-test/atrt-analyze-result.sh
 storage/ndb/test/run-test/atrt-clear-result.sh
 storage/ndb/test/run-test/atrt-gather-result.sh
 storage/ndb/test/run-test/atrt-setup.sh
 storage/ndb/test/run-test/make-config.sh
 storage/ndb/test/run-test/make-html-reports.sh
 storage/ndb/test/run-test/make-index.sh
 storage/ndb/test/run-test/ndb-autotest.sh
 strings/strxmov.c
 strings/strxnmov.c
 support-files/MacOSX/postflight.sh
 support-files/MacOSX/preflight.sh
EOS
is($copyright->files->Keys(6), $s);

$s= <<'EOS';
storage/archive/azio.c
 storage/archive/azlib.h
 zlib/*
EOS
is($copyright->files->Keys(7), $s);

$s= <<'EOS';
sql-bench/innotest1.sh
 sql-bench/innotest1a.sh
 sql-bench/innotest1b.sh
 sql-bench/innotest2.sh
 sql-bench/innotest2a.sh
 sql-bench/innotest2b.sh
EOS
is($copyright->files->Keys(8), $s);

$s= <<'EOS';
storage/innobase/btr/btr0sea.c
 storage/innobase/include/log0log.h
 storage/innobase/include/os0sync.h
 storage/innobase/log/log0log.c
 storage/innobase/row/row0sel.c
EOS
is($copyright->files->Keys(9), $s);

$s= <<'EOS';
storage/innobase/btr/btr0cur.c
 storage/innobase/buf/buf0buf.c
 storage/innobase/include/sync0rw.h
 storage/innobase/include/sync0sync.h
 storage/innobase/sync/*
EOS
is($copyright->files->Keys(10), $s);

$s= <<'EOS';
storage/myisam/rt_index.h
 storage/myisam/rt_key.c
 storage/myisam/rt_mbr.c
 storage/myisam/rt_mbr.h
 storage/myisam/sp_defs.h
EOS
is($copyright->files->Keys(11), $s);

$s= <<'EOS';
storage/innobase/include/ut0bh.h
 storage/innobase/trx/trx0rseg.c
 storage/innobase/ut/ut0bh.c
 storage/innobase/ut/ut0ut.c
EOS
is($copyright->files->Keys(12), $s);

$s= <<'EOS';
plugin/semisync/semisync.cc
 plugin/semisync/semisync.h
 plugin/semisync/semisync_slave_plugin.cc
EOS
is($copyright->files->Keys(13), $s);

$s= <<'EOS';
strings/ctype-bin.c
 strings/ctype-eucjpms.c
 strings/ctype-ujis.c
EOS
is($copyright->files->Keys(14), $s);

$s= <<'EOS';
scripts/mysqld_safe.sh
 support-files/mysql-multi.server.sh
 support-files/mysql.server.sh
EOS
is($copyright->files->Keys(15), $s);

$s= <<'EOS';
sql/sql_yacc.cc
 sql/sql_yacc.h
EOS
is($copyright->files->Keys(16), $s);

$s= <<'EOS';
storage/innobase/include/pars0grm.h
 storage/innobase/pars/pars0grm.c
EOS
is($copyright->files->Keys(17), $s);

$s= <<'EOS';
storage/innobase/include/srv0srv.h
 storage/innobase/srv/srv0start.c
EOS
is($copyright->files->Keys(18), $s);

$s= <<'EOS';
plugin/semisync/semisync_master.cc
 plugin/semisync/semisync_master_plugin.cc
EOS
is($copyright->files->Keys(19), $s);

$s= <<'EOS';
storage/innobase/include/os0file.h
 storage/innobase/os/os0file.c
EOS
is($copyright->files->Keys(20), $s);
is_string($copyright->files->Keys(21), "include/t_ctype.h\n strings/t_ctype.h\n");
is_string($copyright->files->Keys(22), "cmd-line-utils/libedit/np/strlcat.c\n cmd-line-utils/libedit/np/strlcpy.c\n");
is_string($copyright->files->Keys(23), "sql/nt_servc.cc\n sql/nt_servc.h\n");
is_string($copyright->files->Keys(24), "dbug/dbug.c\n dbug/dbug_long.h\n");
is($copyright->files->Keys(25), 'cmd-line-utils/libedit/np/vis.c');
is($copyright->files->Keys(26), 'scripts/dheadgen.pl');
is($copyright->files->Keys(27), 'storage/ndb/test/src/getarg.c');
is($copyright->files->Keys(28), 'storage/ndb/test/include/getarg.h');
is($copyright->files->Keys(29), 'storage/innobase/handler/ha_innodb.cc');
is($copyright->files->Keys(30), 'plugin/semisync/semisync_master.h');
is($copyright->files->Keys(31), 'storage/innobase/srv/srv0srv.c');
is($copyright->files->Keys(32), 'storage/innobase/ut/ut0rbt.c');
is($copyright->files->Keys(33), 'strings/ctype-win1250ch.c');
is($copyright->files->Keys(34), 'strings/ctype-tis620.c');
is($copyright->files->Keys(35), 'storage/innobase/handler/ha_innodb.h');
is($copyright->files->Keys(36), 'strings/dtoa.c');
is($copyright->files->Keys(37), 'scripts/mysqldumpslow.sh');
is($copyright->files->Keys(38), 'libmysqld/lib_sql.cc');
is($copyright->files->Keys(39), 'tests/mail_to_db.pl');
is($copyright->files->Keys(40), 'dbug/dbug_analyze.c');
is($copyright->files->Values(40)->Files, 'dbug/dbug_analyze.c');
is($copyright->files->Values(40)->Copyright, '1987 June Binayak Banerjee');
is_string($copyright->files->Values(40)->License, "public-domain\n This program may be freely distributed under the same terms and\n conditions as Fred Fish's Dbug package.");
is($copyright->files->Keys(41), 'regex/regexp.c');
is($copyright->licenses->Length, 4, 'no of licenses');
is($copyright->licenses->Keys(0), 'GPL-2', 'GPL-2');
is($copyright->licenses->Keys(1), 'GPL-2+', 'GPL-2+');
is($copyright->licenses->Keys(2), 'LGPL', 'LGPL');
is($copyright->licenses->Keys(3), 'BSD (3 clause)', 'BSD (3 clause)');
like_string($copyright->licenses->Values(0), qr/GNU\s+General\s+Public\s+License\s+version\s+2/xms, 'GPL-2');
like_string($copyright->licenses->Values(1), qr/GNU\s+General\s+Public\s+License\s+version\s+2/xms, 'GPL-2+');
like_string($copyright->licenses->Values(2), qr/GNU\s+Library\s+General\s+Public\s+License\s+version\s+2/xms, 'LGPL');
like_string($copyright->licenses->Values(3), qr/THIS\s+SOFTWARE\s+IS\s+PROVIDED\s+BY\s+THE\s+REGENTS\s+AND\s+CONTRIBUTORS/xms, 'BSD');

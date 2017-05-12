use Test;
BEGIN { $| = 1; plan(tests  => 2); chdir 't' if -d 't'; }
use blib;

use Mail::Procmailrc;

my $rcfile;
my @rcfile;
my $pmrc;

$rcfile =<<'_RCFILE_';
LOGFILE=$PMDIR/log.mailblock.net

VERBOSE=yes

FORMAIL=/usr/local/bin/formail

RM=/bin/rm

:0
## bounced bounce?
* !^TO_MAILER-DAEMON@mailblock.net
{ }

:0E
/dev/null

:0
## test conditions
* !^TO_.*@mailblock\.net
{ }

:0E
## else do this
{ BOUNCEPID=`echo $$` }

:0B
* foo
{ HASFOO=`grep 'foo' ${BOUNCEPID}` }

VERBOSE=no
_RCFILE_

ok( $pmrc = new Mail::Procmailrc( { 'data' => $rcfile } ) );
ok( $pmrc->dump(), $rcfile );

use Test;
BEGIN { $| = 1; plan(tests => 4); chdir 't' if -d 't'; }
use blib;

use Mail::Procmailrc;

my $rcfile;
my @rcfile;
my $pmrc;

#########################################################
## test string constructor
#########################################################
$rcfile =<<'_RCFILE_';
LOGABSTRACT=yes
PMDIR=$HOME/.procmail

:0B:
## block indecent emails
* 1^0 people talking dirty
* 1^0 dirty persian poetry
* 1^0 dirty pictures
* 1^0 xxx
{ IS_DIRTY=yes }
_RCFILE_

ok( $pmrc = new Mail::Procmailrc( { 'data' => $rcfile } ) );
ok( $pmrc->dump(), $rcfile );

## from procmailex(5)
$rcfile =<<'_RCFILE_';
:0
* ^Subject: send file [0-9a-z]
* !^X-Loop: yourname@your.main.mail.address
* !^Subject:.*Re:
* !^FROM_DAEMON
* !^Subject: send file .*[/.]\.
{
  MAILDIR=$HOME/fileserver
  
  :0 fhw
  * ^Subject: send file \/[^ ]*
  | formail -rA "X-Loop: yourname@your.main.mail.address"
  
  FILE="$MATCH"
  
  :0 ah
  | cat - ./$FILE 2>&1 | $SENDMAIL -oi -t
}
_RCFILE_

ok( $pmrc->parse( $rcfile ) );
ok( $pmrc->dump(), $rcfile );

exit;

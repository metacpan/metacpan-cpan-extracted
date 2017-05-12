use Test;
BEGIN { $| = 1; plan(tests  => 10); chdir 't' if -d 't'; }
use blib;

use Mail::Procmailrc;

my $rcfile;
my @rcfile;
my $pmrc;

$rcfile =<<'_RCFILE_';
LOGFILE=$PMDIR/log.mailblock.net

VERBOSE=no

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
{
  :0
  { BOUNCEPID=`echo $$` }
  
  :0 c:
  bouncetemp.${BOUNCEPID}
  
  :0
  { SPAMFROM=`${FORMAIL} -r -xTo: | sed 's/^ *//'` }
  
  :0
  { RECIPIENT=`${FORMAIL} -xTo: | sed 's/^ *//'` }
  
  :0
  { RHOST=`${FORMAIL} -xTo: | awk -F @ '{print $2 }'` }
  
  :0
  { SPAMERROR=scott@wiersdorf.org }
  
  :0
  { SPAMDATE=`date` }
  
  :0: bouncetemp.${BOUNCEPID}.lock
  | (${FORMAIL} -rt \
    -I"From: MAILER-DAEMON@$RHOST (Mail Delivery Subsystem)" \
    -I"Subject: Returned mail: User unknown" \
    -I"Auto-Submitted: auto-generated (failure)" \
    -I"Bcc: ${SPAMERROR}" \
    -I"X-Loop: MAILER-DAEMON@${RHOST}";\
     echo "The original message was received at ${SPAMDATE}";\
     echo "from ${SPAMFROM}";\
     echo " ";\
     echo "   ----- The following addresses had permanent fatal errors -----";\
     echo "<${RECIPIENT}>";\
     echo " ";\
     echo "   ----- Transcript of session follows -----";\
     echo "... while talking to ${RHOST}.:";\
     echo ">>> RCPT To:<${RECIPIENT}>";\
     echo "<<< 550 5.1.1 <${RECIPIENT}>... User unknown";\
     echo "550 ${RECIPIENT}... User unknown";\
     echo " ";\
     echo "   ----- Original messages follows ----";\
     echo " ";\
     cat bouncetemp.${BOUNCEPID};\
     ${RM} -f bouncetemp.${BOUNCEPID}) \
     | ${SENDMAIL} -oi -t -fMAILER-DAEMON@${RHOST}
}

VERBOSE=no
_RCFILE_

ok( $pmrc = new Mail::Procmailrc( { 'data' => $rcfile } ) );
ok( $pmrc->dump(), $rcfile );

$rcfile =<<'_RCFILE_';
:0
# Prepare the IP address you are checking.
* RUNCHECK ?? yes
{
  CHECKIP="000.000.000.000"
  
  :0
  * ()\/Received: from.*
  {
    CHECK=${MATCH}
    :0
    *$  CHECK ?? Received: from.*\[.*\].*by.*${THISISP}
    *$! CHECK ?? Received: from.*${THISISP}.*\[.*\]
    *$  CHECK ?? Received:.*\[\/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+
    { CHECKIP=${MATCH} }
  }
}
_RCFILE_

ok( $pmrc->parse( $rcfile ) );
ok( $pmrc->dump(), $rcfile );

$rcfile =<<'_RCFILE_';
:0H
#* 1^0 $ ^content-type:${ws}(multipart/(mixed|application|signed|encrypted))|(application/)
* 4^0 $ ^content-disposition:${ws}attachment;${ws}.*name${ws}=${ws}${dq}?.*\.${ext}(\..*)?${dq}?${ws}$
{
  :0:
  * $ $=^0
  * -1^0 B ?? $ ^content-type:${ws}text/plain
  * -1^0 B ?? $ ^content-type:${ws}text/html
  *  1^0 B ?? $ ^content-transfer-encoding:${ws}base64
  /var/log/quarantine
}
_RCFILE_

ok( $pmrc->parse( $rcfile ) );
ok( $pmrc->dump(), $rcfile );
ok( ${$pmrc->rc}[0]->action->stringify, <<'_ACTION_' );
{
  :0:
  * $ $=^0
  * -1^0 B ?? $ ^content-type:${ws}text/plain
  * -1^0 B ?? $ ^content-type:${ws}text/html
  *  1^0 B ?? $ ^content-transfer-encoding:${ws}base64
  /var/log/quarantine
}
_ACTION_

## try with some stuff after the action line
$rcfile =<<'_RCFILE_';
:0H
#* 1^0 $ ^content-type:${ws}(multipart/(mixed|application|signed|encrypted))|(application/)
* 4^0 $ ^content-disposition:${ws}attachment;${ws}.*name${ws}=${ws}${dq}?.*\.${ext}(\..*)?${dq}?${ws}$
{
  :0:
  * $ $=^0
  * -1^0 B ?? $ ^content-type:${ws}text/plain
  * -1^0 B ?? $ ^content-type:${ws}text/html
  *  1^0 B ?? $ ^content-transfer-encoding:${ws}base64
  /var/log/quarantine
}

## this is a joke
_RCFILE_

ok( $pmrc->parse( $rcfile ) );
ok( $pmrc->dump(), $rcfile );
ok( ${$pmrc->rc}[0]->action->stringify, <<'_ACTION_' );
{
  :0:
  * $ $=^0
  * -1^0 B ?? $ ^content-type:${ws}text/plain
  * -1^0 B ?? $ ^content-type:${ws}text/html
  *  1^0 B ?? $ ^content-transfer-encoding:${ws}base64
  /var/log/quarantine
}
_ACTION_

exit;

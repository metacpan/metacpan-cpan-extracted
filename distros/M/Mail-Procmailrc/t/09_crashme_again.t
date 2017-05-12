use Test;
BEGIN { $| = 1; plan(tests  => 15); chdir 't' if -d 't'; }
use blib;

use Mail::Procmailrc;

my $rcfile;
my @rcfile;
my $pmrc;

## multi-line variable test
$rcfile =<<'_RCFILE_';
ext='(a(d[ep]|r[cj]|s[dmxp]|u|vi)|b(a[st]|mp|z[0-9]?)|c(an|hm|il|lass|md|om|(p[lp]|\+\+)?|rt|sv)|\
      d(at|e?b|ll|o[ct])|e(ml|ps?|xe)|g(if|z?)|h(lp|t(a|ml?)|(pp|\+\+)?)|i(n[cfis]|sp)|\
      j(ava|pe?g|se?|sp|tmpl)|kbf|l(ha|nk|og|yx)|m(d[abew]|p(e?g|[32])|s[cipt])|ocx|\
      p(a(tch|s)|c[dsx]|df|h(p[0-9]?|tml?)|if|[lm?]|n[gm]|[po][st]|p?s)|r(a[mr]|eg|pm|tf)|\
      s(c[rt]|h([bs]|tml?)|lp|ql|ys)?|t(ar|ex|gz|iff?|xt)|u(pd|rl|x)|vb[es]?|\
      w(av|m[szd]|p(d|[0-9]?)|s[cfh])|x(al|[pb]m|l[stw])|z(ip|oo))'
_RCFILE_
ok( $pmrc = new Mail::Procmailrc );
ok( $pmrc->parse( $rcfile ) );
ok( $pmrc->dump(), $rcfile );
ok( $pmrc->flush( ".newprocmailrc2-$$" ) );

undef $pmrc;
ok( $pmrc = new Mail::Procmailrc( ".newprocmailrc2-$$" ) );
ok( $pmrc->dump, $rcfile );
unlink ".newprocmailrc2-$$";

## real-life rcfile
$rcfile =<<'_RCFILE_';
COMSAT=no
VERBOSE=off
LOGABSTRACT=yes
LOGFILE=/var/log/procmail.log

## portions borrowed from John Conover
## http://www.johncon.com/john/archive/quarantine.outlook.attachments.txt
##
## Procmail Script to Quarantine Malicious Microsoft Outlook(r)
## Attachments
LOGFILE=/var/log/quarantine.log
ext='(a(d[ep]|r[cj]|s[dmxp]|u|vi)|b(a[st]|mp|z[0-9]?)|c(an|hm|il|lass|md|om|(p[lp]|\+\+)?|rt|sv)|\
      d(at|e?b|ll|o[ct])|e(ml|ps?|xe)|g(if|z?)|h(lp|t(a|ml?)|(pp|\+\+)?)|i(n[cfis]|sp)|\
      j(ava|pe?g|se?|sp|tmpl)|kbf|l(ha|nk|og|yx)|m(d[abew]|p(e?g|[32])|s[cipt])|ocx|\
      p(a(tch|s)|c[dsx]|df|h(p[0-9]?|tml?)|if|[lm?]|n[gm]|[po][st]|p?s)|r(a[mr]|eg|pm|tf)|\
      s(c[rt]|h([bs]|tml?)|lp|ql|ys)?|t(ar|ex|gz|iff?|xt)|u(pd|rl|x)|vb[es]?|\
      w(av|m[szd]|p(d|[0-9]?)|s[cfh])|x(al|[pb]m|l[stw])|z(ip|oo))'
ws = '[	 ]*($[	 ]+)*'
dq = '"'

## generic exe attachment
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

#:0E
#* -3^0
#* 4^0 B ?? $ name${ws}=${ws}${dq}?.*\.${ext}(\..*)?${dq}?${ws}$
#* 4^0 B ?? $ begin${ws}[0-9]+${ws}.*\.${ext}(\..*)?${ws}$
#* 4^0 B ?? $ ^content-type:${ws}application/
#* 2^0 B ?? $ ^content-transfer-encoding:${ws}base64
#* 1^0 B ?? \<(!doctype|[sp]?h(tml|ead)|title|body)
#* 2^0 B ?? \<(app|bgsound|div|embed|form|i?l(ayer|ink)|img|i?frame(set)?|meta|object|s(cript|tyle))
#* 2^0 B ?? =3d
#/var/log/quarantine

LOGFILE=/var/log/worm.log
## These are from elsewhere:
##
## sircam virus
:0
* > 100000
* B ?? (in order to have your advice|que me des tu punto de vista)
/dev/null

## sexyfun.net
:0
* ^From: .*hahaha@sexyfun.net
/dev/null

## klez worm signature
:0
* > 100000
* B ?? 135AAItEjhyJRI8ci0SOGIlEjxiLRI4UiUSPFItEjhCJRI8Qi0SODIlEjwyLRI4IiUSPCItE
/dev/null

## badtrans worm
:0
*  -1500^0
*    800^0  ^From: .*<_.*>
*    400^0  B ?? ^Content-Type: audio/x-wav
*    400^0  B ?? name=.*\.(doc|mp3|zip|wav)\.(scr|pif)
/dev/null

LOGFILE=/var/log/procmail.log

## clean environment (this gets passed on to users)

## begin spamassassin vinstall (do not remove these comments)
TMPLOGFILE=$LOGFILE
TMPLOGABSTRACT=$LOGABSTRACT
TMPVERBOSE=$VERBOSE

LOGFILE=/dev/null
LOGABSTRACT=yes
VERBOSE=no

:0fw
|/usr/local/bin/spamassassin

LOGFILE=$TMPLOGFILE
LOGABSTRACT=$TMPLOGABSTRACT
VERBOSE=$TMPVERBOSE
## end spamassassin vinstall (do not remove these comments)
_RCFILE_

open TMP, ">.procmailrc-$$"
  or do {
      die "Could not write procmailrc file: $!\n";
  };
print TMP $rcfile;
close TMP;

my $newrc;
open TMP, ".procmailrc-$$"
  or do {
      die "Could not read procmailrc file: $!\n";
  };
{
    local $/;
    $newrc = <TMP>;
}
close TMP;

## compare to make sure write worked
ok( $newrc, $rcfile );

ok( $pmrc = new Mail::Procmailrc );
ok( $pmrc->parse( $rcfile ) );
ok( $pmrc->dump(), $rcfile );
ok( $pmrc->flush( ".newprocmailrc-$$" ) );

undef $pmrc;
ok( $pmrc = new Mail::Procmailrc( ".newprocmailrc-$$" ) );
ok( $pmrc->dump, $rcfile );

##
## this is bad syntax and causes an infinite loop in the Recipe::init()
##
undef $pmrc;
$rcfile =<<'_BROKEN_';
:0
#some_action
_BROKEN_

$pmrc = new Mail::Procmailrc;
ok( $pmrc->parse( $rcfile ) );  ## infinite loop begins here
ok( $pmrc->dump(), $rcfile );

END { unlink (".procmailrc-$$", ".newprocmailrc-$$", ".newprocmailrc2-$$") }

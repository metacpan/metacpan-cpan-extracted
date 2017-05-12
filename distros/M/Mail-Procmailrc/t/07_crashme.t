use Test;
BEGIN { $| = 1; plan(tests  => 18); chdir 't' if -d 't'; }
use blib;

use Mail::Procmailrc;

my $rcfile;
my @rcfile;
my $pmrc;

$rcfile =<<'_RCFILE_';
RUNCHECK=no

:0
* DULCHECK ?? yes
{ RUNCHECK=yes }

:0
* DORKSLCHECK ?? yes
{ RUNCHECK=yes }

:0
* ORBLCHECK ?? yes
{ RUNCHECK=yes }

:0
* ORBZINCHECK ?? yes
{ RUNCHECK=yes }

:0
* ORBZOUTCHECK ?? yes
{ RUNCHECK=yes }

:0
* ORDBCHECK ?? yes
{ RUNCHECK=yes }

:0
* OSDIALCHECK ?? yes
{ RUNCHECK=yes }

:0
* OSSPAMCHECK ?? yes
{ RUNCHECK=yes }

:0
* RBLCHECK ?? yes
{ RUNCHECK=yes }

:0
* RSSCHECK ?? yes
{ RUNCHECK=yes }

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
  
  :0
  * CHECKIP ?? 000.000.000.000
  * ^Received: from(.*$)+\/Received: from.*$
  {
    CHECK=${MATCH}
    :0
    *$  CHECK ?? Received: from.*\[.*\].*by.*${THISISP}
    *$! CHECK ?? Received: from.*${THISISP}.*\[.*\]
    *$  CHECK ?? Received:.*\[\/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+
    { CHECKIP=${MATCH} }
  }
  
  :0
  * CHECKIP ?? 000.000.000.000
  * ^Received: from(.*$)+Received: from(.*$)+\/Received: from.*$
  {
    CHECK=${MATCH}
    :0
    *$  CHECK ?? Received: from.*\[.*\].*by.*${THISISP}
    *$! CHECK ?? Received: from.*${THISISP}.*\[.*\]
    *$  CHECK ?? Received:.*\[\/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+
    { CHECKIP=${MATCH} }
  }
  
  :0
  * $!CHECKIP ?? 000.000.000.000
  *   CHECKIP ?? ()\/[0-9]+
  {
    QUAD1=${MATCH}
    
    :0
    *  CHECKIP ?? [0-9]+\.\/[0-9]+
    {
      QUAD2=${MATCH}
      
      :0
      *  CHECKIP ?? [0-9]+\.[0-9]+\.\/[0-9]+
      {
        QUAD3=${MATCH}
        
        :0
        *  CHECKIP ?? [0-9]+\.[0-9]+\.[0-9]+\.\/[0-9]+
        {
          REVERSED="${MATCH}.${QUAD3}.${QUAD2}.${QUAD1}"
          
          :0
          # Dorkslayers Check
          * DORKSLCHECK ?? yes
          {
            REVCHECKIP=`${NSLOOKUP} ${REVERSED}.orbs.dorkslayers.com`
            
            :0
            * $ REVCHECKIP ?? 127\.0\.0\.2
            {
              :0 f
              | ${FORMAIL} -A"X-SBRule: IP ${CHECKIP} is in Dorkslayers"
              
              :0
              { BLOCKTAG=yes }
              
              :0
              * BLOCKREPLY ?? NOTIFY
              { BLOCKTHIS=yes }
            }
          }
          
          :0
          # MAPS DUL Check
          * DULCHECK ?? yes
          {
            REVCHECKIP=`${NSLOOKUP} ${REVERSED}.dialups.mail-abuse.org`
            
            :0
            * $ REVCHECKIP ?? 127\.0\.0\.3
            {
              :0 f
              | ${FORMAIL} -A"X-SBRule: IP ${CHECKIP} is in DUL"
              
              :0
              { BLOCKTAG=yes }
              
              :0
              * BLOCKREPLY ?? NOTIFY
              { BLOCKTHIS=yes }
            }
          }
          
          :0
          # ORBL Check
          * ORBLCHECK ?? yes
          {
            REVCHECKIP=`${NSLOOKUP} ${REVERSED}.relays.orbl.org`
            
            :0
            * $ REVCHECKIP ?? 127\.0\.0\.2
            {
              :0 f
              | ${FORMAIL} -A"X-SBRule: IP ${CHECKIP} is in ORBL"
              
              :0
              { BLOCKTAG=yes }
              
              :0
              * BLOCKREPLY ?? NOTIFY
              { BLOCKTHIS=yes }
            }
          }
        }
      }
    }
  }
}
_RCFILE_

ok( $pmrc = new Mail::Procmailrc( { 'data' => $rcfile } ) );
ok( $pmrc->dump(), $rcfile );

$rcfile =<<'_RCFILE_';
:0
# SPAMHAUS.ORG BLACKLIST
* SPAMHAUSORGCHECK ?? yes
{
  :0 BH
  * !--.*forwarded message --
  * !^forwarded message:
  * !^-----BEGIN PGP SIGNED MESSAGE-----
  * -1000^0
  * -1000^0   ^Subject: Re:
  *  -200^1   ^[:;#>]
  *  1100^1    1affiliateprograms\.com([^\.]|$)
  *  1100^1    1marketing\.net([^\.]|$)
  *  1100^1    1tips\.net([^\.]|$)
  *  1100^1    4uservers\.com([^\.]|$)
  *  1100^1    abestvalue\.com([^\.]|$)
  *  1100^1    abulkemailsource\.com([^\.]|$)
  *  1100^1    accessonesoftware\.com([^\.]|$)
  *  1100^1    americaint\.com([^\.]|$)
  *  1100^1    amtech2010\.com([^\.]|$)
  *  1100^1    apex-pi\.com([^\.]|$)
  *  1100^1    atf\.net([^\.]|$)
  *  1100^1    bizzbang\.com([^\.]|$)
  *  1100^1    bradreaenterprises\.com([^\.]|$)
  *  1100^1    bulkbarn\.com([^\.]|$)
  *  1100^1    bulkemail\.ca([^\.]|$)
  *  1100^1    bulkemail\.cc([^\.]|$)
  *  1100^1    bulkemail\.nu([^\.]|$)
  *  1100^1    bulk-email-center\.com([^\.]|$)
  *  1100^1    bulkemailgroup\.com([^\.]|$)
  *  1100^1    bulkemailpeople\.com([^\.]|$)
  *  1100^1    bulkemailsoftware\.net([^\.]|$)
  *  1100^1    bulkemailsoftwarecenter\.com([^\.]|$)
  *  1100^1    bulkemailstore\.com([^\.]|$)
  *  1100^1    bulk-email-store\.com ([^\.]|$)
  *  1100^1    bulkers\.net([^\.]|$)
  *  1100^1    bulkhost\.net([^\.]|$)
  *  1100^1    bulkisp\.com([^\.]|$)
  *  1100^1    bulk-isp\.com([^\.]|$)
  *  1100^1    bulkisp\.net([^\.]|$)
  *  1100^1    bulk-isp\.net([^\.]|$)
  *  1100^1    bulkisp\.nu([^\.]|$)
  *  1100^1    bulkispcorp\.com([^\.]|$)
  *  1100^1    bulkispcorp\.net([^\.]|$)
  *  1100^1    bulklist\.com([^\.]|$)
  *  1100^1    bulkmailstore\.com([^\.]|$)
  *  1100^1    bulkmarketing\.net([^\.]|$)
  *  1100^1    bulletproofwebhosting\.net([^\.]|$)
  *  1100^1    cequal2000\.com([^\.]|$)
  *  1100^1    cyberlink1\.com([^\.]|$)
  *  1100^1    cyber-webcom\.com([^\.]|$)
  *  1100^1    datalogical\.com([^\.]|$)
  *  1100^1    data-miners\.net([^\.]|$)
  *  1100^1    desktopserver\.com([^\.]|$)
  *  1100^1    desktop-server\.com([^\.]|$)
  *  1100^1    desktopserver2000\.com([^\.]|$)
  *  1100^1    desktopserver98\.com([^\.]|$)
  *  1100^1    e-announce\.com([^\.]|$)
  *  1100^1    earthonline\.com([^\.]|$)
  *  1100^1    e-mailblaster\.com([^\.]|$)
  *  1100^1    e-maildata\.com([^\.]|$)
  *  1100^1    emaildigger\.com([^\.]|$)
  *  1100^1    email-marketers\.net([^\.]|$)
  *  1100^1    emailmarketingsystems\.com([^\.]|$)
  *  1100^1    e-mailplatinum\.com([^\.]|$)
  *  1100^1    emailsgalore\.com([^\.]|$)
  *  1100^1    e-mailsoftware\.com([^\.]|$)
  *  1100^1    emailsoftwaresolutions\.com([^\.]|$)
  *  1100^1    expressmail-server\.com([^\.]|$)
  *  1100^1    extractorpro\.com([^\.]|$)
  *  1100^1    extractor-pro98\.com([^\.]|$)
  *  1100^1    firstlinesoft\.com([^\.]|$)
  *  1100^1    getyoursoftware\.com([^\.]|$)
  *  1100^1    globaldirectmarketing\.net([^\.]|$)
  *  1100^1    homeuniverse\.com([^\.]|$)
  *  1100^1    hot-new\.com([^\.]|$)
  *  1100^1    intellitec\.net([^\.]|$)
  *  1100^1    intouch2001\.com([^\.]|$)
  *  1100^1    itsfreakinfree\.com([^\.]|$)
  *  1100^1    jbpublications\.com([^\.]|$)
  *  1100^1    jemwebs\.com([^\.]|$)
  *  1100^1    june\.net-psychic\.com([^\.]|$)
  *  1100^1    kingcard\.com([^\.]|$)
  *  1100^1    listguy\.com([^\.]|$)
  *  1100^1    listsorcerer\.com([^\.]|$)
  *  1100^1    list-sorcerer\.com([^\.]|$)
  *  1100^1    madwebextractor\.com([^\.]|$)
  *  1100^1    market-2-sales\.com([^\.]|$)
  *  1100^1    marketing-2000\.net([^\.]|$)
  *  1100^1    marketingmasters\.com([^\.]|$)
  *  1100^1    massmailer\.com([^\.]|$)
  *  1100^1    mass-marketers\.net([^\.]|$)
  *  1100^1    mlmhelp\.com([^\.]|$)
  *  1100^1    natlpark\.net([^\.]|$)
  *  1100^1    netachievers\.com([^\.]|$)
  *  1100^1    netbillions\.com([^\.]|$)
  *  1100^1    nikola\.net([^\.]|$)
  *  1100^1    nitro-net\.com([^\.]|$)
  *  1100^1    prospect-2000\.com([^\.]|$)
  *  1100^1    prospectmailer2000\.com([^\.]|$)
  *  1100^1    realcybersex\.com([^\.]|$)
  *  1100^1    rlyeh\.com([^\.]|$)
  *  1100^1    site-secrets\.com([^\.]|$)
  *  1100^1    softwareshop\.net([^\.]|$)
  *  1100^1    theinternetbiz\.com([^\.]|$)
  *  1100^1    usa-marketers\.com([^\.]|$)
  *  1100^1    usaplaza\.com([^\.]|$)
  *  1100^1    w3-lightspeed\.com([^\.]|$)
  *  1100^1    webmasterszone\.net([^\.]|$)
  *  1100^1    webmole\.com([^\.]|$)
  *  1100^1    web-promotions\.com([^\.]|$)
  *  1100^1    webyellowpages\.com([^\.]|$)
  *  1100^1    windows100\.com([^\.]|$)
  *  1100^1    yug\.com([^\.]|$)
  {
    :0 f
    | ${FORMAIL} -A"X-SBRule: spamhaus.org domain"
    
    :0
    { BLOCKTAG=yes }
    
    :0
    * BLOCKREPLY ?? NOTIFY
    { BLOCKTHIS=yes }
  }
  
  :0
  # IP addresses (6/2/2001)
  * ^(From.|Reply-To:|Message-ID:|Received:).*[^0-9a-z](65\.162\.95\.23|\
	    64\.78\.43\.63|\
	    64\.70\.227\.137|\
	    64\.70\.160\.89|\
	    64\.70\.144\.37|\
	    64\.225\.137\.227|\
	    63\.74\.120\.199|\
	    63\.74\.120\.141|\
	    63\.73\.122\.152|\
	    63\.219\.100\.5|\
	    63\.144\.246\.95|\
	    63\.119\.69\.105|\
	    63\.107\.146\.61|\
	    63\.107\.146\.21|\
	    63\.107\.146\.20|\
	    63\.107\.146\.18|\
	    63\.107\.146\.17|\
	    63\.107\.146\.13|\
	    216\.65\.111\.4|\
	    216\.4\.57\.174|\
	    216\.36\.202\.96|\
	    216\.32\.198\.21|\
	    216\.156\.235\.208|\
	    216\.141\.121\.22|\
	    216\.117\.154\.227|\
	    216\.117\.150\.151|\
	    216\.117\.144\.116|\
	    216\.117\.138\.40|\
	    213\.165\.154\.51|\
	    213\.11\.173\.50|\
	    212\.152\.178\.146|\
	    211\.99\.199\.5|\
	    209\.54\.65\.94|\
	    209\.238\.140\.116|\
	    209\.237\.190\.254|\
	    209\.237\.187\.208|\
	    209\.237\.172\.222|\
	    209\.237\.169\.56|\
	    209\.237\.151\.178|\
	    209\.235\.102\.9|\
	    209\.235\.100\.17|\
	    209\.211\.253\.89|\
	    209\.211\.253\.88|\
	    209\.211\.253\.84|\
	    209\.211\.253\.74|\
	    209\.211\.253\.73|\
	    209\.211\.253\.71|\
	    209\.211\.253\.70|\
	    209\.211\.253\.69|\
	    209\.211\.253\.68|\
	    209\.211\.253\.248|\
	    209\.211\.253\.139|\
	    209\.211\.253\.126|\
	    209\.208\.253\.34|\
	    209\.20\.201\.68|\
	    209\.2\.137\.153|\
	    209\.125\.208\.28|\
	    208\.46\.184\.34|\
	    208\.46\.184\.31|\
	    208\.46\.184\.30|\
	    208\.46\.184\.29|\
	    208\.46\.184\.28|\
	    208\.46\.184\.26|\
	    208\.46\.184\.25|\
	    208\.46\.184\.10|\
	    208\.234\.5\.242|\
	    208\.234\.4\.123|\
	    208\.234\.29\.141|\
	    208\.234\.15\.37|\
	    208\.234\.13\.9|\
	    208\.221\.168\.112|\
	    208\.161\.191\.51|\
	    208\.161\.191\.24|\
	    208\.161\.191\.22|\
	    208\.158\.124\.105|\
	    208\.130\.198\.238|\
	    208\.130\.197\.236|\
	    207\.23\.186\.230|\
	    207\.198\.74\.82|\
	    207\.180\.29\.196|\
	    206\.61\.177\.145|\
	    206\.61\.177\.144|\
	    206\.61\.177\.142|\
	    206\.61\.177\.141|\
	    206\.61\.177\.137|\
	    206\.61\.177\.130|\
	    206\.169\.213\.230|\
	    206\.114\.159\.230|\
	    205\.238\.206\.132|\
	    204\.83\.230\.164|\
	    204\.213\.85\.162|\
	    202\.157\.130\.109|\
	    199\.93\.70\.42|\
	    198\.30\.222\.8|\
	    151\.196\.152\.53)
  {
    :0 f
    | ${FORMAIL} -A"X-SBRule: spamhaus.org IP"
    
    :0
    { BLOCKTAG=yes }
    
    :0
    * BLOCKREPLY ?? NOTIFY
    { BLOCKTHIS=yes }
  }
}
_RCFILE_

ok( $pmrc->parse( $rcfile ) );
ok( $pmrc->dump(), $rcfile );

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
|/usr/local/bin/spamassassin -P

LOGFILE=$TMPLOGFILE
LOGABSTRACT=$TMPLOGABSTRACT
VERBOSE=$TMPVERBOSE
## end spamassassin vinstall (do not remove these comments)
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

ok( $pmrc->parse( $rcfile ) );
ok( $pmrc->dump(), $rcfile );

## this subset of the above tests a bug found 20 Nov 2002 where the
## parser sucked the whole file
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

NL="
"
LOGFILE=/var/log/worm.log
## These are from elsewhere:
##
## sircam virus
:0
* > 100000
* B ?? (in order to have your advice|que me des tu punto de vista)
/dev/null
_RCFILE_

ok( $pmrc->parse( $rcfile ) );
ok( $pmrc->dump(), $rcfile );
ok( ${$pmrc->recipes}[0]->dump, <<'_RECIPE_' );
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
_RECIPE_

ok( ${$pmrc->recipes}[1]->dump, <<'_RECIPE_' );
:0
* > 100000
* B ?? (in order to have your advice|que me des tu punto de vista)
/dev/null
_RECIPE_

ok( $pmrc->rc->[2]->stringify, '#:0E' );
ok( $pmrc->rc->[3]->stringify, '#* -3^0' );
ok( $pmrc->rc->[11]->stringify, '#/var/log/quarantine' );
ok( $pmrc->rc->[13]->lval, "NL" );
ok( $pmrc->rc->[13]->rval, qq("\n") );
ok( $pmrc->rc->[14]->stringify, 'LOGFILE=/var/log/worm.log' );
ok( ${$pmrc->variables}[0]->stringify, qq(NL="\n") );
ok( ${$pmrc->variables}[1]->stringify, 'LOGFILE=/var/log/worm.log' );

#use Data::Dumper;
#print STDERR Dumper($pmrc);
exit;

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..42\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
do './recurse2txt';     # get my Dumper

use Mail::SMTP::Honeypot;
*_EHLO	=	\&Mail::SMTP::Honeypot::_EHLO;
*_HELO	=	\&Mail::SMTP::Honeypot::_HELO;
*_MAIL	=	\&Mail::SMTP::Honeypot::_MAIL;
*_RCPT	=	\&Mail::SMTP::Honeypot::_RCPT;
*_RSET	=	\&Mail::SMTP::Honeypot::_RSET;
*_VRFY	=	\&Mail::SMTP::Honeypot::_VRFY;
*_HELP	=	\&Mail::SMTP::Honeypot::_HELP;
*_NOOP	=	\&Mail::SMTP::Honeypot::_NOOP;
*_QUIT	=	\&Mail::SMTP::Honeypot::_QUIT;
*soft_reset =	\&Mail::SMTP::Honeypot::soft_reset;
*notimp	=	\&Mail::SMTP::Honeypot::notimp;
*clear_bufs =	\&Mail::SMTP::Honeypot::clear_bufs;
*parseSMTP =	\&Mail::SMTP::Honeypot::parseSMTP;
*get_unique =	\&Mail::SMTP::Honeypot::get_unique;
*uniquemsgid =	\&Mail::SMTP::Honeypot::uniquemsgid;

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

sub next_sec {
  my ($then) = @_;
  $then = time unless $then;
  my $now;
# wait for epoch
  do { select(undef,undef,undef,0.1); $now = time }
        while ( $then >= $now );
  $now;
}

sub gotexp {
  my($got,$exp) = @_;
  if ($exp =~ /\D/) {
    print "got: $got\nexp: $exp\nnot "
        unless $got eq $exp;
  } else {
    print "got: $got, exp: $exp\nnot "
        unless $got == $exp;
  }
  &ok;
}

################################################################
################################################################

my $flag;

{ local $^W = 0; # no warnings;
  *Mail::SMTP::Honeypot::write_rearm = sub {$flag = 1};
}

my $conf = {
	hostname	=> 'test.host.com'
};

Mail::SMTP::Honeypot::check_config($conf);
my $tp = Mail::SMTP::Honeypot::_trace();
my $bare	= {
		sock	=> 'dummy sock',
		proto	=> 'SMTP',
		lastc	=> 'CONN',
#		name	=> 'dns.name.net',
#		ipaddr	=> '5.4.3.2',
};

my $fileno = 1;
my $CRLF = "\r\n";
my $domain = 'elsewhere.com';
my $name = 'real.name.net';
my $raddr = '5.4.3.2';
my $exp;

sub init {
  %$exp = %{${$tp}->{$fileno}} = %{$bare};
  $flag = 0;
  return ${$tp}->{$fileno};
}

###############	clean_bufs
## test 2	clean_bufs
my $tptr = &init;
# add trash to hash
@{$tptr}{qw(add trash to hash)} = qw(adding some trash crap);
$tptr = clear_bufs($fileno);
$exp->{domain} = undef;
gotexp(Dumper($tptr),Dumper($exp));

## test 3	clean_bufs with domain present
@{$exp}{qw(domain lastc)} = ($domain,'HELO');
@{$tptr}{qw(add trash to hash domain)} = (qw(adding some trash crap), $domain);
$tptr = clear_bufs($fileno);
gotexp(Dumper($tptr),Dumper($exp));

## test 4	clean_bufs with ESMTP
@{$exp}{qw(proto lastc)} = qw(ESMTP EHLO);
@{$tptr}{qw(add trash to hash proto)} = qw(adding some trash crap ESMTP);
$tptr = clear_bufs($fileno);
gotexp(Dumper($tptr),Dumper($exp));  

############### COMMANDS
## test 5	EHLO
$tptr = &init;
@{$exp}{qw(domain lastc proto wargs)} = ($domain, qw(EHLO ESMTP),
'250-'. $conf->{hostname} .' ready for '. $domain .' ('. $name .'['. $raddr .'])'. $CRLF .
'250 HELP'. $CRLF);

  @{$tptr}{qw(name ipaddr)} = ($name,$raddr);
  @{$exp}{qw(name ipaddr)} = ($name,$raddr);

_EHLO($fileno,$domain,$tptr);
gotexp(Dumper($tptr),Dumper($exp));  

## test 6	EHLO, no domain
$tptr = &init;
$domain = '';
@{$exp}{qw(domain lastc proto wargs)} = (qw(nobody EHLO ESMTP),
'250-'. $conf->{hostname} .' ready for nobody ('. $name .'['. $raddr .'])'. $CRLF .
'250 HELP'. $CRLF);

  @{$tptr}{qw(name ipaddr)} = ($name,$raddr);
  @{$exp}{qw(name ipaddr)} = ($name,$raddr); 

_EHLO($fileno,$domain,$tptr);
gotexp(Dumper($tptr),Dumper($exp));  


## test 7	HELO
$tptr = &init;
$domain = 'another.domain.com';
@{$exp}{qw(domain lastc proto wargs)} = ($domain, qw(HELO SMTP),
'250 '. $conf->{hostname} .' ready for '. $domain .' ('. $name .'['. $raddr .'])'. $CRLF);

  @{$tptr}{qw(name ipaddr)} = ($name,$raddr);
  @{$exp}{qw(name ipaddr)} = ($name,$raddr); 

_HELO($fileno,$domain,$tptr);
gotexp(Dumper($tptr),Dumper($exp));  

## test 8	HELO, no domain
$tptr = &init;
$domain = '';
@{$exp}{qw(domain lastc proto wargs)} = (qw(nobody HELO SMTP),
'250 '. $conf->{hostname} .' ready for nobody ('. $name .'['. $raddr .'])'. $CRLF);

  @{$tptr}{qw(name ipaddr)} = ($name,$raddr);
  @{$exp}{qw(name ipaddr)} = ($name,$raddr); 

_HELO($fileno,$domain,$tptr);
gotexp(Dumper($tptr),Dumper($exp));  

next_sec();
## test 9	MAIL, fail -- no user domain
# in the interest of sandbox programs being happy
local $$;

$$ = 1234;		# presets for uniquemsgid
get_unique(567);
my $msgid = uniquemsgid();
$tptr = &init;
$domain = 'fred';
$exp->{wargs} = q|553 5.5.4 Domain name required for address "|. $domain .q|"|. $CRLF;
_MAIL($fileno,'from:'.$domain,$tptr);
gotexp(Dumper($tptr),Dumper($exp));

## test 10	MAIL
$$ = 1234;		# presets for uniquemsgid
get_unique(567);
$tptr = &init;
$domain = 'fred@somewhere.com';
@{$exp}{qw(lastc wargs from msgid)} = ('MAIL','250 2.1.0 OK'. $CRLF,$domain,$msgid);
_MAIL($fileno,'from:'.$domain,$tptr);
gotexp(Dumper($tptr),Dumper($exp));

## test 11	RCPT, fail -- no user domain
$tptr = &init;
$domain = 'fred';
$exp->{wargs} = q|553 5.5.4 Domain name required for address "|. $domain .q|"|. $CRLF;
_RCPT($fileno,'to:'.$domain,$tptr);
gotexp(Dumper($tptr),Dumper($exp));

## test 12	RSET	clear test 14
%$exp = %{$bare};
${$tp}->{$fileno}->{ipaddr} = '1.2.3.4';
@{$exp}{qw(domain wargs ipaddr name)} = (undef,'250 2.0.0 OK'. $CRLF,'1.2.3.4','');
_RSET($fileno,'any garbage at all',$tptr);
gotexp(Dumper(${$tp}->{$fileno}),Dumper($exp));

## test 13	RCPT, fail USER UNKNOWN
# since the test for !$dest has been removed from _RCPT and migrated to the
# smtpvmta.filter, fake it here and test the mechanism

$tptr = &init;
$exp->{wargs} = '553 5.5.4 Domain name required for address "'. $domain .'"'. $CRLF;
_RCPT($fileno,'to:'.$domain,$tptr);
gotexp(Dumper($tptr),Dumper($exp));

## test 14	VRFY, fail user unknown
$tptr = &init;
$exp->{wargs} = '553 5.5.4 Domain name required for address "'. $domain .'"'. $CRLF;
_VRFY($fileno,$domain,$tptr);
gotexp(Dumper($tptr),Dumper($exp));

## test 15	VRFY, bad domain address
$tptr = &init;
$domain = 'harry';
$exp->{wargs} = '553 5.5.4 Domain name required for address "'. $domain .'"'. $CRLF;
_VRFY($fileno,$domain,$tptr);
gotexp(Dumper($tptr),Dumper($exp));

## test 16	VRFY
$tptr = &init;
$domain = 'old@address.com';
$exp->{lastc} = 'VRFY';
$exp->{wargs} = '250 2.1.5 OK'. $CRLF;
_VRFY($fileno,$domain,$tptr);
gotexp(Dumper($tptr),Dumper($exp));

## test 17	HELP
@{$tptr}{qw(add some garbage to hash)} = qw(added lots of stuff here);
%{$exp} = (%{$tptr},'wargs',
'214-2.0.0     Commands supported are'. $CRLF .
'214-2.0.0    HELO EHLO MAIL RCPT DATA'. $CRLF .
'214 2.0.0    RSET VRFY HELP NOOP QUIT'. $CRLF); 
_HELP($fileno,'any old stuff',$tptr);
gotexp(Dumper($tptr),Dumper($exp));

## test 18	NOOP
$exp->{wargs} = '250 2.0.0 OK'. $CRLF;
_NOOP($fileno,'any old stuff',$tptr);
gotexp(Dumper($tptr),Dumper($exp));

## test 19	QUIT
$exp->{wargs} = '221 2.0.0 '. $conf->{hostname} .' closing connection'. $CRLF;
_QUIT($fileno,'any old stuff',$tptr);
gotexp(Dumper($tptr),Dumper($exp));

## test 20	notimp
$exp->{wargs} = '502 5.5.1 Command not implemented'. $CRLF;
notimp($fileno,'any old stuff',$tptr);
gotexp(Dumper($tptr),Dumper($exp));

#################################################################
############## test SMTP parser
#################################################################

my $count = 1;
## test 21	line too long
$tptr = &init;
@{$tptr}{qw(rargs roff)} = ('Zap', 3);
@{$exp}{qw(cmdcnt rargs roff wargs)} = ($count++,'Zap',3,'500 5.5.1 Command unrecognized "Zap"'. $CRLF);
parseSMTP($fileno);
gotexp(Dumper($tptr),Dumper($exp));

## test 22	short command
@{$tptr}{qw(rargs roff)} = ('HELO', 513);
@{$exp}{qw(cmdcnt rargs roff wargs)} = ($count++,'HELO',513,'500 5.5.4 Command line too long'. $CRLF);
parseSMTP($fileno);
gotexp(Dumper($tptr),Dumper($exp));

## test 23	long command
@{$tptr}{qw(rargs roff)} = ('Sunny', 3);
@{$exp}{qw(cmdcnt rargs roff wargs)} = ($count++,'Sunny',3,'500 5.5.1 Command unrecognized "Sunny"'. $CRLF);
parseSMTP($fileno);
gotexp(Dumper($tptr),Dumper($exp));

## test 24	non-existent command, empty
@{$tptr}{qw(rargs roff)} = ('', 3);
@{$exp}{qw(cmdcnt rargs roff wargs)} = ($count++,'',3,'500 5.5.1 Command unrecognized ""'. $CRLF);
parseSMTP($fileno);
gotexp(Dumper($tptr),Dumper($exp));

## test 25	non-existent command 4 chars
@{$tptr}{qw(rargs roff)} = ('Nada', 4);
@{$exp}{qw(cmdcnt rargs roff wargs)} = ($count++,'Nada',4,'500 5.5.1 Command unrecognized "Nada"'. $CRLF);
parseSMTP($fileno);
gotexp(Dumper($tptr),Dumper($exp));

## test 26	RCPT	fail, need MAIL
@{$tptr}{qw(rargs)} = ('RcPt');
@{$exp}{qw(cmdcnt rargs wargs)} = ($count++,'RcPt','503 5.0.0 Need MAIL before RCPT'. $CRLF);
parseSMTP($fileno);                                                                           
gotexp(Dumper($tptr),Dumper($exp));

## test 27	DATA	fail, need MAIL
@{$tptr}{qw(rargs)} = ('DaTa');
@{$exp}{qw(cmdcnt rargs wargs)} = ($count++,'DaTa','503 5.0.0 Need MAIL command'. $CRLF);
parseSMTP($fileno);
gotexp(Dumper($tptr),Dumper($exp));

## test 28	feed optional HELO
@{$tptr}{qw(rargs roff domain)} = ('hELo', 4, 'nobody');
@{$exp}{qw(cmdcnt rargs roff wargs domain lastc)} = ($count++,'hELo',4,
	'250 '. $conf->{hostname} .' ready for nobody ('. $name .'['. $raddr .'])'. $CRLF, 'nobody','HELO');

  @{$tptr}{qw(name ipaddr)} = ($name,$raddr);
  @{$exp}{qw(name ipaddr)} = ($name,$raddr);

parseSMTP($fileno);
gotexp(Dumper($tptr),Dumper($exp));

## test 29	RCPT	fail, need MAIL
@{$tptr}{qw(rargs)} = ('RcPt');
@{$exp}{qw(cmdcnt rargs wargs)} = ($count++,'RcPt','503 5.0.0 Need MAIL before RCPT'. $CRLF);
parseSMTP($fileno);                                                                           
gotexp(Dumper($tptr),Dumper($exp));

## test 30	DATA	fail, need MAIL
@{$tptr}{qw(rargs)} = ('DaTa');
@{$exp}{qw(cmdcnt rargs wargs)} = ($count++,'DaTa','503 5.0.0 Need MAIL command'. $CRLF);
parseSMTP($fileno);                                                                           
gotexp(Dumper($tptr),Dumper($exp));

## test 31	MAIL
$$ = 1234;                      # presets for uniquemsgid
get_unique(567);
$domain = 'from@me.com';
@{$tptr}{qw(rargs)} = ('mAiL from:'.$domain );
@{$exp}{qw(cmdcnt lastc from rargs wargs msgid)} = ($count++,'MAIL',$domain,'mAiL from:'.$domain,'250 2.1.0 OK'. $CRLF, $msgid);
parseSMTP($fileno);                                       
gotexp(Dumper($tptr),Dumper($exp));                                      

## test 32	MAIL	again
@{$exp}{qw(cmdcnt wargs)} = ($count++,'503 5.5.0 Sender already specified'. $CRLF);
parseSMTP($fileno);
gotexp(Dumper($tptr),Dumper($exp));                                      

## test 33	DATA	fail need RCPT
@{$tptr}{qw(rargs)} = ('DaTa');
@{$exp}{qw(cmdcnt rargs wargs)} = ($count++,'DaTa','503 5.0.0 Need RCPT before DATA'. $CRLF);
parseSMTP($fileno);                                                                           
gotexp(Dumper($tptr),Dumper($exp));

## test 34	HELP
$tptr->{rargs} = 'help and other stuff';
@{$exp}{qw(cmdcnt rargs wargs)} = ($count++,'help and other stuff',
'214-2.0.0     Commands supported are'. $CRLF .
'214-2.0.0    HELO EHLO MAIL RCPT DATA'. $CRLF .
'214 2.0.0    RSET VRFY HELP NOOP QUIT'. $CRLF); 
parseSMTP($fileno);
gotexp(Dumper($tptr),Dumper($exp));

## test 35	NOOP
$tptr->{rargs} = 'noop and other stuff';
@{$exp}{qw(cmdcnt rargs wargs)} = ($count++,'noop and other stuff','250 2.0.0 OK'. $CRLF);
parseSMTP($fileno);
gotexp(Dumper($tptr),Dumper($exp));

## test 36 - 39	notimp
$exp->{wargs} = '502 5.5.1 Command not implemented'. $CRLF;
foreach (qw(send saml expn turn)) {
  $exp->{rargs} = $tptr->{rargs} = $_;
  $exp->{cmdcnt} = $count++;
  parseSMTP($fileno);
  gotexp(Dumper($tptr),Dumper($exp));
}

## test 40	DATA
my $now = &next_sec();
$$ = 1234;			# presets for uniquemsgid
get_unique(567);
@{$tptr}{qw(lastc rargs)} = ('RCPT', 'DATA');
@{$exp}{qw(cmdcnt rargs wargs lastc alarm next)} 
	= ($count++,'DATA','','RCPT',$now,sub {});
parseSMTP($fileno);
gotexp(Dumper($tptr),Dumper($exp));

## test 41	soft_reset	# clear above tests
$tptr->{wargs} = 'just a plain string';
%$exp = %{$bare};
@{$exp}{qw(domain wargs ipaddr name)} = ('nobody','just a plain string',$raddr,$name);
soft_reset($fileno);
gotexp(Dumper(${$tp}->{$fileno}),Dumper($exp));

## test 42	QUIT
$count = 1;
$tptr = &init;
$tptr->{rargs} = 'QuIT';
$tptr->{roff} = 4;
@{$exp}{qw(cmdcnt rargs wargs roff)} = ($count++,'QuIT','221 2.0.0 '. $conf->{hostname} .' closing connection'. $CRLF, 4);
parseSMTP($fileno);
gotexp(Dumper($tptr),Dumper($exp));

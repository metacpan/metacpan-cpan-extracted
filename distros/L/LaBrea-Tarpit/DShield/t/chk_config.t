# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as erl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..24\n"; }
END {print "not ok 1\n" unless $loaded;}
use LaBrea::Tarpit::DShield qw(
	chk_config
	move2_Q
);
$loaded = 1;
print "ok 1\n";

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

=pod

Need to test this:

  my $config = {
    'DShield'   => 'tmp/DShield.cache', # path/to/file
    'UserID'    => '0',                 # DShield UserID
    'To'        => 'test@dshield.org',  # or report@dshield.org
    'From'      => 'john.doe@foo.com',
    'Reply-To'  => 'john.doe@foo.com',  # optional
  # optional
    'Obfuscate' => 'complete or partial',
  # either one or more working SMTP server's
    'smtp'      => 'iceman.dshield.org,mail.euclidian.com',
  # or a sendmail compatible mail transport command
    'sendmail'  => '/usr/lib/sendmail -t -oi',
  };

  order is:

	UserID
	DShield
	To
	From
	Reply-To
	smtp
	sendmail
	Obfuscate

=cut

my $config = {};

### NOTE ###
# Test for UserID moved to 'move2_Q', tests 2,3,4,5,6
###

## check various UserID combinations
## 2 absent
print "missing UserID not found\nnot "
	unless ($_ = move2_Q($config)) eq 'missing DShield UserID';
&ok;

## 3 undefined
$config->{UserID} = undef;
print "undef UserID not found\nnot "
        unless ($_ = move2_Q($config)) eq 'missing DShield UserID';
&ok;

## 4 non-numeric
$config->{UserID} = 'crap';
print "non-numeric UserID not found\nnot "
        unless ($_ = move2_Q($config)) eq 'missing DShield UserID';
&ok;

## 5 -- 0 OK
$config->{UserID} = 0;
print "zero UserID not accepted\nnot "
	unless move2_Q($config) eq 'missing DShield queue directory';
&ok;

## 6 other mumeric
$config->{UserID} = '12345';
print "zero UserID not accepted\nnot "
	unless move2_Q($config) eq 'missing DShield queue directory';
&ok;

# missing DShield file checked above, twice... but....

## 7 should not insert leading './'
$config->{DShield} = 'tmp/crap';
chk_config($config);
print "inserted extra './' in DShield filename\nnot "
	unless $config->{DShield} eq 'tmp/crap';
&ok;

## 8 insert './' where needed
$config->{DShield} = 'tmp';
chk_config($config);
print "failed to insert './' in DShield filename\nnot "
	unless $config->{DShield} eq './tmp';
&ok;

## 9 check one insertion of './' only
$_ = chk_config($config);
print "inserted extra './' in DShield filename\nnot "
	unless $config->{DShield} eq './tmp';
&ok;

## 10 response above should find missing To:
print "failed to detect missing To:\nnot "
	unless $_ =~ /missing or invalid To:/;
&ok;

## 11 corrupt mail format
$config->{To} = 'a@b';
print "failed to detect corrupt To:\nnot "
	unless chk_config($config) =~ /missing or invalid To:/;
&ok;

## 12 To is OK
$config->{To} = 'a@b.c';
print "refused good To:\nnot "
	unless ($_ = chk_config($config)) =~ /missing or invalid From:/;
&ok;

## 13 corrupt mail format
$config->{From} = 'a@b';
print "failed to detect corrupt From:\nnot "
	unless chk_config($config) =~ /missing or invalid From:/;
&ok;

## 14 From is OK
$config->{From} = 'a@b.f';
print "refused good From:\nnot "
	unless ($_ = chk_config($config)) =~ /missing mail agent/;
&ok;

## 15 Reply-To should eq From
print "did not preset absent Reply-To\nnot "
	unless $config->{'Reply-To'} eq 'a@b.f';
&ok;

## 16 missing Reply-To
$config->{'Reply-To'} = undef;
print "accepted undefined Reply-To\nnot "
	unless chk_config($config) =~ /invalid Reply-To/;
&ok;

## 17 corrupt mail format
$config->{'Reply-To'} = 'a@b';
print "failed to detect corrupt Reply-To:\nnot "
	unless chk_config($config) =~ /invalid Reply-To/;
&ok;

## 18 From is OK
$config->{'Reply-To'} = 'a@b.r';
print "refused good Reply-To:\nnot "
	unless ($_ = chk_config($config)) =~ /missing mail agent/;
&ok;

## 19 mail agents found
$config->{smtp} = '_SomeRandomString_123453211_';
print "failed to recognize SMTP mail agent\nnot "
	if chk_config($config);
&ok;

delete $config->{smtp};
## 20
$config->{sendmail} = '_SomeRandomString_123453211_';
print "accepted bogus sendmail agent\nnot "
	unless chk_config($config) =~ /sendmail agent missing/;
&ok;

$config->{smtp} = '_SomeRandomString_123453211_';
delete $config->{sendmail};

## 21 obfuscate
$config->{Obfuscate} = '0';	# false
print "failed Obfuscate false test\nnot "
	if chk_config($config);
&ok;

## 22 obfuscate, invalid keyword
$config->{Obfuscate} = 'crap';
print "accepted bad Obfuscate keyword\nnot "
	unless chk_config($config) =~ /unknown/;
&ok;

## 23
$config->{Obfuscate} = 'PaRtIaL';
print "failed to accept 'partial' keyword\nnot "
	if ($_ = chk_config($config));
&ok;

## 24
$config->{Obfuscate} = 'cOmPlEtE';
print "failed to accept 'complete' keyword\nnot "
	if ($_ = chk_config($config));
&ok;

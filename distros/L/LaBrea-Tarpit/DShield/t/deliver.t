# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as erl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..10\n"; }
END {print "not ok 1\n" unless $loaded;}
use lib qw(blib/arch blib/lib ../ ../blib/lib ../blib/arch);
use LaBrea::Tarpit::DShield qw(
	move2_Q
	deliver2_DShield
);
$loaded = 1;
print "ok 1\n";

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

sub next_sec {
  my ($then) = @_;
  my $now;
# wait for epoch
  do { select(undef,undef,undef,0.1); $now = time }
        while ( $then >= $now );
  $now;
}

local $SIG{ALRM} = sub { die "test timeout"; };

umask 027;
if (-d 'tmp') {         # clean up previous test runs
  opendir(T,'tmp');
  @_ = grep(!/^\./, readdir(T));
  closedir T;
  foreach(@_) {
    unlink "tmp/$_";
  }
} else {
  mkdir 'tmp', 0750 unless (-e 'tmp' && -d 'tmp');
}

my $smtp_response = 'dshield.smtp.response';
my $sendmail_response = 'dshield.sendmail.response';

sub compare_files {
  my ($cf,$q) = @_;     # comparison file, q file
  local(*F);
  open (F,$cf);
  $cf = '';
  while (<F>) {
    $cf .= $_; 
  }
  tweak_version_string(\$cf);
  close F;
  open (F,$q);
  $q = '';
  while (<F>) {
    $q .= $_;  
  }
  tweak_version_string(\$q);
  return ($q eq $cf) ? ''   
        : "queue file:\n$q\nne expected:\n$cf\nnot ";
}
 
sub tweak_version_string {
  my ($tp) = @_;
  $$tp =~ s/VERSION/$LaBrea::Tarpit::DShield::VERSION/;
  $$tp =~ s/LaBrea_Tarpit_DShield\s+[\S]+/LaBrea_Tarpit_DShield current:version:string/;
}
sub create_cache {
  my ($in,$out) = @_;
  local (*IN,*OUT);
  open (IN,$in);
  select IN;
  $| = 1;
  open (OUT,'>'.$out);
  select OUT;
  $| = 1;
  select STDOUT;
  while (<IN>) {
    print OUT $_;
  }
  close IN;
  close OUT;
}

  my $config = {
    'DShield'   => 'tmp/DShield.cache', # path/to/file
    'UserID'    => '12321',                 # DShield UserID
    'To'        => 'test@dshield.org',  # or report@dshield.org
    'From'      => 'john.doe@foo.com',
    'Reply-To'  => 'mary.doe@foo.com',  # optional
  # optional
    'Obfuscate' => 'complete or partial',
  # either one or more working SMTP server's
    'smtp'      => 'iceman.dshield.org,mail.euclidian.com',
  # or a sendmail compatible mail transport command
    'sendmail'  => '/usr/lib/sendmail -t -oi',
  };


my $ds = $config->{DShield};
my $in = './dshield.cache';

&create_cache($in,$ds);

$ds =~ m|(.*/)|;
my $dir = $1;

## 2 trap chk_config errors
delete $config->{sendmail};
print "did not trap chk_config errors\nnot "
        unless deliver2_DShield($config) =~ /unknown/;
&ok;

delete $config->{Obfuscate};

## 3 should fall through to end, no queue files
$_ = deliver2_DShield($config);
print "unknown error $_"
	if $_;
&ok;

## 4 create qf1

my $now = &next_sec(time);

my $dbfsmtp = $dir . 'dF' . $now .'.'. $$ .'.'. 0 . '.smtp';
my $dbfsendmail = $dir . 'dF' . $now .'.'. $$ .'.'. 0 . '.sendmail';

$_ = move2_Q($config,1);
print "failed: $_\nnot "
	if $_;
&ok;

## 5 create smtp response
$_ = deliver2_DShield($config,2);
print "$_\nnot "
	if $_;
&ok;

## 6 check smtp data
print compare_files($smtp_response,$dbfsmtp);
&ok;

delete $config->{smtp};

# set the cache file to executable for dummy sendmail
chmod 0755, $ds;
$config->{sendmail} = $ds;


## 7 create the sendmail response
$_ = deliver2_DShield($config,2);
print "$_\nnot "
	if $_;
&ok;

## 8 check smtp data
print compare_files($sendmail_response,$dbfsendmail);
&ok;

## 9 this should unlink all qFiles
$_ = deliver2_DShield($config,1);
print "$_\nnot "
	if $_;
&ok;

## 10 verify that they are gone
local *D;
opendir(D, $dir);
@_ = grep(/qF/, readdir(D));
closedir D;
print "failed to delete sent files in queue\nnot "
	if @_;
&ok;


# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as erl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..18\n"; }
END {print "not ok 1\n" unless $loaded;}
use Fcntl qw(:DEFAULT :flock);
use LaBrea::Tarpit::DShield qw(
	move2_Q
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

my $result1 = './dshield.result1';
my $result2 = './dshield.result2';
my $result3 = './dshield.result3';

sub compare_result {
  my ($cf,$cfg) = @_;
  my $qf = $cfg->{DShield} . '.q.tmp';
  compare_files($cf,$qf);
}

sub compare_files {
  my ($cf,$q) = @_;	# comparison file, q file
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


## 
## 2 trap chk_config errors
delete $config->{sendmail};
print "did not trap chk_config errors\nnot "
	unless move2_Q($config,2) =~ /unknown/;
&ok;

delete $config->{Obfuscate};

## 3 nothing to do
$_ = move2_Q($config,2);
print qq|unknown error:\n$_\nnot |
	if $_;
&ok;

my $ds = $config->{DShield};
my $in = './dshield.cache';

## 4 attempt to read directory only
$config->{DShield} = './tmp';	# directory
print "accepted directory as read file\nnot "
	unless move2_Q($config,2) =~ /plain file/;
&ok;

## 5 file locking
&create_cache($in,$ds);
$config->{DShield} = $ds;
local (*L,*TEST);
sysopen L, $ds . '.flock', O_RDWR|O_CREAT|O_TRUNC;
flock(L,LOCK_EX);

if (open(TEST,'-|')) {
  print (<TEST>);
} else {
  eval {
    alarm 2;
    move2_Q($config,2);
  };
  alarm 0;
  print "faulty lock\nnot "
	unless $@ =~ /test timeout/;
  &ok;
  exit;
}
close L;  
close TEST;
++$test;

## 6 creat real output
$_ = move2_Q($config,2);
print "failed: $_\nnot "
	if $_;
&ok;

## 7 check output against expected
print compare_result($result1,$config);
&ok;

## 8 obfuscate leading quad
$config->{Obfuscate} = 'partial';
$_ = move2_Q($config,2);
print "failed: $_\nnot "
	if $_;
&ok;

## 9 check output against expected
print compare_result($result2,$config);
&ok;

## 10 obfuscate complete
$config->{Obfuscate} = 'complete';
$_ = move2_Q($config,2);
print "failed: $_\nnot "
	if $_;
&ok;

## 11 check output against expected
print compare_result($result3,$config);
&ok;

my $now = &next_sec(time);

## 12 create qF file
$_ = move2_Q($config,1);
print "failed: $_\nnot "
	if $_;
&ok;

$config->{DShield} =~ m|(.*/)|;
my $dir = $1;

## 13 check that it is there
my $qf = 'qF' . $now . '.' . $$ .'.'. 0;
print "failed to create queue file\nnot "
	unless -e $dir . $qf;
&ok;

## 14 check the contents
print compare_files($result3,$dir . $qf);
&ok;

## 15 check for original delete and Q creation

my $qf1 = $qf;

$now = &next_sec(time);

## 15 create qF file, and delete dshield file
$_ = move2_Q($config);
print "failed: $_\nnot "
	if $_;
&ok;

## 16 check that it is there
$qf = 'qF' . $now . '.' . $$ .'.'. 0;
print "failed to create queue file\nnot "
	unless -e $dir . $qf;
&ok;

## 17 check the contents
print compare_files($result3,$dir . $qf);
&ok;

## 18 check that previous queue file exists
print "first queue file destroyed\nnot "
	unless -e $dir . $qf1;
&ok;

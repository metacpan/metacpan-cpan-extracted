# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..98\n"; }
END {print "not ok 1\n" unless $loaded;}

#use strict;
#use diagnostics;
use Cwd;
use Net::DNS::Codes qw(:all);
use Net::DNS::ToolKit qw(
	put16
	newhead
	gethead
	get1char
);
use Net::DNS::ToolKit::Debug qw(
	print_head
	print_buf
);
use Net::DNS::ToolKit::RR;

use IPTables::IPv4::DBTarpit::Tools;

use Socket;
use CTest;

$IPTOOLS	= 'IPTables::IPv4::DBTarpit::Tools';
$TCTEST		= 'Mail::SpamCannibal::DNSBLserver::CTest';
$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

umask 007;
foreach my $dir (qw(tmp tmp.dbhome tmp.bogus)) {
  if (-d $dir) {         # clean up previous test runs
    opendir(T,$dir);
    @_ = grep(!/^\./, readdir(T));
    closedir T;
    foreach(@_) {
      unlink "$dir/$_";
    }
    rmdir $dir or die "COULD NOT REMOVE $dir DIRECTORY\n";
  }
  unlink $dir if -e $dir;	# remove files of this name as well
}

sub ok {
  my($todo) = @_;
  $todo = ($todo) ? ' # TODO '. $todo : '';
  print "ok ${test}$todo\n";
  ++$test;
}

my $localdir = cwd();

mkdir './tmp.dbhome',0755;
my $dbhome = $localdir.'/tmp.dbhome';

sub NOREAD {1};

# $istcp is a count of buffers to read
# $tcpmode is what to send to the "munge" routine
#
sub dialog {
  my ($buff,$len,$noread,$istcp,$tcpmode) = @_;
  socketpair(my $child, my $parent,AF_UNIX,SOCK_DGRAM,PF_UNSPEC);
  local $SIG{ALRM} = sub {die "$0: timed out, read or write blocked\n"};
  my $pid;
  if($pid = fork) {	# is parent
    alarm 3;
    close $child;
  } else {	# child
    alarm 2;
    close $parent;
    my $fd = fileno($child);
    if ($istcp) {
      $tcpmode = 1 unless $tcpmode;	# normal mode unless specified
    } else {
      $istcp = $tcpmode = 0;
    }
    my $rv = eval{&{"${TCTEST}::t_munge"}($fd,$buff,$len,$tcpmode)};
    close $child;
    alarm 0;
    $rv = -1 if ! defined $rv || $rv < 0;
    exit $rv;
  }
  my $resp;
  my $size = 1000;
  my $rv;
  my @allresp;
  do {
    if ($istcp) {
      $size = 2;
      $rv = sysread($parent,$resp,$size) unless $noread;
      die "$0: bad invalid response size $resp\n"
	unless $noread || $rv == 2;
      $size = unpack("n",$resp) unless $noread;
    }
    $rv = sysread($parent,$resp,$size) unless $noread;
    push @allresp, $resp;
    $istcp--;
  } while ($istcp > 0);
  close $parent;
  waitpid($pid,0);	# reap child
  alarm 0;
  return($rv,@allresp);
}

my $extra;

# input array @_ used in child process after } else {
sub getmaintxt {
  $extra = '';
  if (open(FROMCHILD, "-|")) {
    while (my $record = <FROMCHILD>) { 
      $extra .= $record;
    }
  } else {
# program name is always argv[0]
    unless (open STDERR, '>&STDOUT') {
      print "can't dup STDERR to /dev/null: $!";
      exit;
    }
    &{"${TCTEST}::t_main"}('CTest',@_);
    exit;
  }
  close FROMCHILD;
}

sub expect {
  my $x = shift;
  my @exp;
  foreach(split(/\n/,$x)) {
    if ($_ =~ /0x\w+\s+(\d+) /) {
      push @exp,$1;
    }
  }  
  return @exp;
}
 
sub chk_exp {
  my($bp,$exp) = @_;
  my $todo = '';
  my @expect = expect($$exp);
  foreach(0..length($$bp) -1) {
    $char = get1char($bp,$_);
    next if $char == $expect[$_];
    print "buffer mismatch $_, got: $char, exp: $expect[$_]\nnot ";
    $todo = 'fix test for marginal dn_comp resolver implementations';
    last;
  }
  &ok($todo);
}

## test 2	check short buffer
my $buffer = '';
my $len = put16(\$buffer,0,0);	# short buffer
# set isudp = 1 for these tests
$buffer="the quick brown fox\n";
my($rv,$response) = dialog($buffer,$len,NOREAD);
print "$@\nnot "
	if $@;
&ok();

## test 3	check exit value is -1
# see description of $? for function syswrite in perlman
print "expected exit value of -1\nnot "
	unless $? >> 8 == 255;
&ok();

## test 4	check QR = 1
$len = newhead(\$buffer,
	12345,		# id
	QR,		# Q response on
	1,0,0,0,	# one question
);
($rv,$response) = dialog($buffer,$len,NOREAD);
print "$@\nnot "
	if $@;
&ok();

## test 5	check exit value is -1
# see description of $? for function syswrite in perlman
print "expected exit value of -1\nnot "
	unless $? >> 8 == 255;
&ok();

####
## test 6	check QUERY only
$len = newhead(\$buffer,
	12345,
	BITS_IQUERY,	# opcode
	1,0,0,0,	# one question
);
($rv,$response) = dialog($buffer,$len);
print "$@\nnot "
	if $@;
&ok();

## test 7	check exit value positive
# see description of $? for function syswrite in perlman
$_ = $? >> 8;
print "expected exit value of 12, got: $_\nnot "
	if $_ < 0;
&ok();

## test 8	check return length
print "got $rv, exp: $len\nnot "
	unless $rv == $len;
&ok();

#print_head(\$response);
#print_buf(\$response,0,$len);

## test 9	check response code
my ($offset,
	$id,$qr,$opcode,$aa,$tc,$rd,$ra,$mbz,$ad,$cd,$rcode,
	$qdcount,$ancount,$nscount,$arcount)
	= gethead(\$response);
print "got: ",RcodeTxt->{$rcode},", exp: NOTIMP\nnot "
	unless $rcode == NOTIMP();
&ok();

####
## test 10	lie about number of questions, exp FORMERR
$len = newhead(\$buffer,
	12345,
	BITS_QUERY,	# opcode
	2,0,0,0,	# two questions
);
($rv,$response) = dialog($buffer,$len);
print "$@\nnot "
	if $@;
&ok();

## test 11	check exit value positive
# see description of $? for function syswrite in perlman
$_ = $? >> 8;
print "expected exit value of 12, got: $_\nnot "
	if $_ < 0;
&ok();



## test 12	check return length
print "got $rv, exp: $len\nnot "
	unless $rv == $len;
&ok();

#print_head(\$response);
#print_buf(\$response,0,$len);

## test 13	check response code
($offset,
	$id,$qr,$opcode,$aa,$tc,$rd,$ra,$mbz,$ad,$cd,$rcode,
	$qdcount,$ancount,$nscount,$arcount)
	= gethead(\$response);
print "got: ",RcodeTxt->{$rcode},", exp: FORMERR\nnot "
	unless $rcode == FORMERR();
&ok();

####
## test 14	fail to send real question
$len = newhead(\$buffer,
	12345,
	BITS_QUERY,	# opcode
	1,0,0,0,	# one question
);
($rv,$response) = dialog($buffer,$len);
print "$@\nnot "
	if $@;
&ok();

## test 15	check exit value positive
# see description of $? for function syswrite in perlman
$_ = $? >> 8;
print "expected exit value of 12, got: $_\nnot "
	if $_ < 0;
&ok();



## test 16	check return length
print "got $rv, exp: $len\nnot "
	unless $rv == $len;
&ok();

#print_head(\$response);
#print_buf(\$response,0,$len);

## test 17	check response code
($offset,
	$id,$qr,$opcode,$aa,$tc,$rd,$ra,$mbz,$ad,$cd,$rcode,
	$qdcount,$ancount,$nscount,$arcount)
	= gethead(\$response);
print "got: ",RcodeTxt->{$rcode},", exp: FORMERR\nnot "
	unless $rcode == FORMERR();
&ok();

####
## test 18	 check for short question
my ($get,$put) = new Net::DNS::ToolKit::RR(C_IN);
$len = $put->Question(\$buffer,$len,'foo.bar.com',T_A,C_IN);
$len--;		# lie about length;

($rv,$response) = dialog($buffer,$len);
print "$@\nnot "
	if $@;
&ok();

## test 19	check exit value positive
# see description of $? for function syswrite in perlman
$_ = $? >> 8;
print "expected exit value of 28, got: $_\nnot "
	if $_ < 0;
&ok();

## test 20	check return length
print "got $rv, exp: $len\nnot "
	unless $rv == $len;
&ok();

#print_head(\$response);
#print_buf(\$response,0,$len);

## test 21	check for short question
($offset,
	$id,$qr,$opcode,$aa,$tc,$rd,$ra,$mbz,$ad,$cd,$rcode,
	$qdcount,$ancount,$nscount,$arcount)
	= gethead(\$response);
print "got: ",RcodeTxt->{$rcode},", exp: FORMERR\nnot "
	unless $rcode == FORMERR();
&ok();

####
## test 22	check for bad class != C_IN
$len = newhead(\$buffer,
	12345,
	BITS_QUERY,	# opcode
	1,0,0,0,	# one question
);
$len = $put->Question(\$buffer,$len,'foo.bar.com',T_A,C_HS);
($rv,$response) = dialog($buffer,$len);
print "$@\nnot "
	if $@;
&ok();

## test 23	check exit value positive
# see description of $? for function syswrite in perlman
$_ = $? >> 8;
print "expected exit value of 29, got: $_\nnot "
	if $_ < 0;
&ok();


## test 24	check return length
print "got $rv, exp: $len\nnot "
	unless $rv == $len;
&ok();

#print_head(\$response);
#print_buf(\$response,0,$len);

## test 25	check response code
($offset,
	$id,$qr,$opcode,$aa,$tc,$rd,$ra,$mbz,$ad,$cd,$rcode,
	$qdcount,$ancount,$nscount,$arcount)
	= gethead(\$response);
print "got: ",RcodeTxt->{$rcode},", exp: REFUSED\nnot "
	unless $rcode == REFUSED();
&ok();

####
## test 26	set zone name
my $zonename = 'foo.bar.com';
print "failed to set zone name\nnot "
	unless  &{"${TCTEST}::t_cmdline"}('z',$zonename);
&ok();

## test 27	question name shorter than zone name
$len = newhead(\$buffer,
	12345,
	BITS_QUERY,	# opcode
	1,0,0,0,	# one question
);
$len = $put->Question(\$buffer,$len,'bar.com',T_A,C_IN);
($rv,$response) = dialog($buffer,$len);
print "$@\nnot "
	if $@;
&ok();

## test 28	check exit value positive
# see description of $? for function syswrite in perlman
$_ = $? >> 8;
print "expected exit value of 25, got: $_\nnot "
	if $_ < 0;
&ok();


## test 29	check return length
print "got $rv, exp: $len\nnot "
	unless $rv == $len;
&ok();

#print_head(\$response);
#print_buf(\$response,0,$len);

## test 30	check response code
($offset,
	$id,$qr,$opcode,$aa,$tc,$rd,$ra,$mbz,$ad,$cd,$rcode,
	$qdcount,$ancount,$nscount,$arcount)
	= gethead(\$response);
print "got: ",RcodeTxt->{$rcode},", exp: NXDOMAIN\nnot "
	unless $rcode == NXDOMAIN();
&ok();

## test 31	question name does not end in zone name
$len = newhead(\$buffer,
	12345,
	BITS_QUERY,	# opcode
	1,0,0,0,	# one question
);
$len = $put->Question(\$buffer,$len,'foo.bar.net',T_A,C_IN);
($rv,$response) = dialog($buffer,$len);
print "$@\nnot "
	if $@;
&ok();

#### lets dispense with the extra checks, they clearly work or failures would already have occured
## test 32	check response code
($offset,
	$id,$qr,$opcode,$aa,$tc,$rd,$ra,$mbz,$ad,$cd,$rcode,
	$qdcount,$ancount,$nscount,$arcount)
	= gethead(\$response);
print "got: ",RcodeTxt->{$rcode},", exp: NXDOMAIN\nnot "
	unless $rcode == NXDOMAIN();
&ok();

## test 33	question name does not end in '.'zone name
$len = newhead(\$buffer,
	12345,
	BITS_QUERY,	# opcode
	1,0,0,0,	# one question
);
$len = $put->Question(\$buffer,$len,'xfoo.bar.com',T_A,C_IN);
($rv,$response) = dialog($buffer,$len);
print "$@\nnot "
	if $@;
&ok();

## test 34	check response code
($offset,
	$id,$qr,$opcode,$aa,$tc,$rd,$ra,$mbz,$ad,$cd,$rcode,
	$qdcount,$ancount,$nscount,$arcount)
	= gethead(\$response);
print "got: ",RcodeTxt->{$rcode},", exp: NXDOMAIN\nnot "
	unless $rcode == NXDOMAIN();
&ok();

######################################################################
# at this point, all failure modes are checked, test normal responses
######################################################################
#
# load new zone, NS, and MX info
$zonename	= 'bar.com';
my $localip	= '192.168.99.100';
my $ns1		= 'ns1.xyz.com';
my $ns2		= 'ns2.bar.com';
my $ns1IP	= '12.34.56.78';
my $ns2IP	= '76.54.32.10';
my $mx1		= 'bar.com';
my $mx2		= 'mx.bar.com';
my $mx1p	= 50;
my $mx2p	= 10;
my $mx1IP	= '1.2.3.4';
my $mx2IP	= '101.202.103.44';

## test 35
print "failed to set ns1 name\nnot "
	unless  &{"${TCTEST}::t_cmdline"}('n',$ns1);
&ok();

## test 36
print "failed to set ns1 IP\nnot "
	unless  &{"${TCTEST}::t_cmdline"}('a',$ns1IP);
&ok();

## test 37
print "failed to set ns2 name\nnot "
	unless  &{"${TCTEST}::t_cmdline"}('n',$ns2);
&ok();

## test 38
print "failed to set ns2 IP\nnot "
	unless  &{"${TCTEST}::t_cmdline"}('a',$ns2IP);
&ok();

## test 39
print "failed to set mx1 name\nnot "
	unless  &{"${TCTEST}::t_cmdline"}('n',$mx1);
&ok();

## test 40
print "failed to set mx1 priority\nnot "
	unless  &{"${TCTEST}::t_cmdline"}('m',$mx1p);
&ok();

## test 41
print "failed to set mx1 IP\nnot "
	unless  &{"${TCTEST}::t_cmdline"}('a',$mx1IP);
&ok();

## test 42
print "failed to set mx2 name\nnot "
	unless  &{"${TCTEST}::t_cmdline"}('n',$mx2);
&ok();

## test 43
print "failed to set mx2 IP\nnot "
	unless  &{"${TCTEST}::t_cmdline"}('a',$mx2IP);
&ok();

## test 44
print "failed to set mx2 priority\nnot "
	unless  &{"${TCTEST}::t_cmdline"}('m',$mx2p);
&ok();

## test 45	set zone_name
print "failed to set local name\nnot "
	unless  &{"${TCTEST}::t_cmdline"}('z',$zonename);
&ok();

## test 46	set local_name = zone_name
print "failed to set local name\nnot "
	unless  &{"${TCTEST}::t_cmdline"}('L',$zonename);
&ok();

## test 47	set local ip address
print "failed to set local IPaddr\nnot "
	unless &{"${TCTEST}::t_cmdline"}('I',$localip);
&ok();

## test 48	set contact name
print "failed to set contact name\nnot "
	unless &{"${TCTEST}::t_cmdline"}('c','human.'.$zonename);
&ok();

## test 49	set response IP addrs
my $zero = '127.0.0.0';
my $stdR = '127.0.0.2';
my $stdB = '127.0.0.3';
print "failed to set standard response codes\nnot "
	unless &{"${TCTEST}::t_set_resp"}($zero,$stdR,$stdB);
&ok();

## test 50	set the serial number for this response
my $ipt = $IPTOOLS->new(
	dbfile	=> 'tarpit',
	dbhome	=> $dbhome,
	txtfile	=> 'rblcontrib',
);
print "failed to set serial number in database\nnot "
	if $ipt->put('tarpit',inet_aton($zero),123454321);
&ok();

#############################################################
###  WARNING db handle held open until end of file
#############################################################

## test 51	set up the database
my $dbprimary = 'tarpit';
my $dbsecondary = 'rblcontrib';
print "failed to init databases\nnot "
	if &{"${TCTEST}::t_init"}($dbhome,$dbprimary,$dbsecondary);
&ok();

############ setup complete

## test 52	check domain SOA
$len = newhead(\$buffer,
	12345,
	BITS_QUERY,	# opcode
	1,0,0,0,	# one question
);
$len = $put->Question(\$buffer,$len,'bar.com',T_SOA,C_IN);
($rv,$response) = dialog($buffer,$len);

#print_head(\$response);
#print_buf(\$buffer);
#print_buf(\$response);

my $exptext = q|
  0     :  0011_0000  0x30   48  0  
  1     :  0011_1001  0x39   57  9  
  2     :  1000_0100  0x84  132    
  3     :  0000_0000  0x00    0    
  4     :  0000_0000  0x00    0    
  5     :  0000_0001  0x01    1    
  6     :  0000_0000  0x00    0    
  7     :  0000_0001  0x01    1    
  8     :  0000_0000  0x00    0    
  9     :  0000_0010  0x02    2    
  10    :  0000_0000  0x00    0    
  11    :  0000_0010  0x02    2    
  12    :  0000_0011  0x03    3    
  13    :  0110_0010  0x62   98  b  
  14    :  0110_0001  0x61   97  a  
  15    :  0111_0010  0x72  114  r  
  16    :  0000_0011  0x03    3    
  17    :  0110_0011  0x63   99  c  
  18    :  0110_1111  0x6F  111  o  
  19    :  0110_1101  0x6D  109  m  
  20    :  0000_0000  0x00    0    
  21    :  0000_0000  0x00    0    
  22    :  0000_0110  0x06    6    
  23    :  0000_0000  0x00    0    
  24    :  0000_0001  0x01    1    
  25    :  1100_0000  0xC0  192    
  26    :  0000_1100  0x0C   12    
  27    :  0000_0000  0x00    0    
  28    :  0000_0110  0x06    6    
  29    :  0000_0000  0x00    0    
  30    :  0000_0001  0x01    1    
  31    :  0000_0000  0x00    0    
  32    :  0000_0000  0x00    0    
  33    :  0000_0000  0x00    0    
  34    :  0000_0000  0x00    0    
  35    :  0000_0000  0x00    0    
  36    :  0001_1110  0x1E   30    
  37    :  1100_0000  0xC0  192    
  38    :  0000_1100  0x0C   12    
  39    :  0000_0101  0x05    5    
  40    :  0110_1000  0x68  104  h  
  41    :  0111_0101  0x75  117  u  
  42    :  0110_1101  0x6D  109  m  
  43    :  0110_0001  0x61   97  a  
  44    :  0110_1110  0x6E  110  n  
  45    :  1100_0000  0xC0  192    
  46    :  0000_1100  0x0C   12    
  47    :  0000_0111  0x07    7    
  48    :  0101_1011  0x5B   91  [  
  49    :  1100_0011  0xC3  195    
  50    :  0111_0001  0x71  113  q  
  51    :  0000_0000  0x00    0    
  52    :  0000_0000  0x00    0    
  53    :  1010_1000  0xA8  168    
  54    :  1100_0000  0xC0  192    
  55    :  0000_0000  0x00    0    
  56    :  0000_0000  0x00    0    
  57    :  0000_1110  0x0E   14    
  58    :  0001_0000  0x10   16    
  59    :  0000_0000  0x00    0    
  60    :  0000_0001  0x01    1    
  61    :  0101_0001  0x51   81  Q  
  62    :  1000_0000  0x80  128    
  63    :  0000_0000  0x00    0    
  64    :  0000_0000  0x00    0    
  65    :  0010_1010  0x2A   42  *  
  66    :  0011_0000  0x30   48  0  
  67    :  1100_0000  0xC0  192    
  68    :  0000_1100  0x0C   12    
  69    :  0000_0000  0x00    0    
  70    :  0000_0010  0x02    2    
  71    :  0000_0000  0x00    0    
  72    :  0000_0001  0x01    1    
  73    :  0000_0000  0x00    0    
  74    :  0000_0000  0x00    0    
  75    :  0010_1010  0x2A   42  *  
  76    :  0011_0000  0x30   48  0  
  77    :  0000_0000  0x00    0    
  78    :  0000_1010  0x0A   10    
  79    :  0000_0011  0x03    3    
  80    :  0110_1110  0x6E  110  n  
  81    :  0111_0011  0x73  115  s  
  82    :  0011_0001  0x31   49  1  
  83    :  0000_0011  0x03    3    
  84    :  0111_1000  0x78  120  x  
  85    :  0111_1001  0x79  121  y  
  86    :  0111_1010  0x7A  122  z  
  87    :  1100_0000  0xC0  192    
  88    :  0001_0000  0x10   16    
  89    :  1100_0000  0xC0  192    
  90    :  0000_1100  0x0C   12    
  91    :  0000_0000  0x00    0    
  92    :  0000_0010  0x02    2    
  93    :  0000_0000  0x00    0    
  94    :  0000_0001  0x01    1    
  95    :  0000_0000  0x00    0    
  96    :  0000_0000  0x00    0    
  97    :  0010_1010  0x2A   42  *  
  98    :  0011_0000  0x30   48  0  
  99    :  0000_0000  0x00    0    
  100   :  0000_0110  0x06    6    
  101   :  0000_0011  0x03    3    
  102   :  0110_1110  0x6E  110  n  
  103   :  0111_0011  0x73  115  s  
  104   :  0011_0010  0x32   50  2  
  105   :  1100_0000  0xC0  192    
  106   :  0000_1100  0x0C   12    
  107   :  1100_0000  0xC0  192    
  108   :  0100_1111  0x4F   79  O  
  109   :  0000_0000  0x00    0    
  110   :  0000_0001  0x01    1    
  111   :  0000_0000  0x00    0    
  112   :  0000_0001  0x01    1    
  113   :  0000_0000  0x00    0    
  114   :  0000_0000  0x00    0    
  115   :  0010_1010  0x2A   42  *  
  116   :  0011_0000  0x30   48  0  
  117   :  0000_0000  0x00    0    
  118   :  0000_0100  0x04    4    
  119   :  0000_1100  0x0C   12    
  120   :  0010_0010  0x22   34  "  
  121   :  0011_1000  0x38   56  8  
  122   :  0100_1110  0x4E   78  N  
  123   :  1100_0000  0xC0  192    
  124   :  0110_0101  0x65  101  e  
  125   :  0000_0000  0x00    0    
  126   :  0000_0001  0x01    1    
  127   :  0000_0000  0x00    0    
  128   :  0000_0001  0x01    1    
  129   :  0000_0000  0x00    0    
  130   :  0000_0000  0x00    0    
  131   :  0010_1010  0x2A   42  *  
  132   :  0011_0000  0x30   48  0  
  133   :  0000_0000  0x00    0    
  134   :  0000_0100  0x04    4    
  135   :  0100_1100  0x4C   76  L  
  136   :  0011_0110  0x36   54  6  
  137   :  0010_0000  0x20   32     
  138   :  0000_1010  0x0A   10    
|;
chk_exp(\$response,\$exptext);

## test 53	check domain A
$len = newhead(\$buffer,
	12345,
	BITS_QUERY,	# opcode
	1,0,0,0,	# one question
);
$len = $put->Question(\$buffer,$len,'bar.com',T_A,C_IN);
($rv,$response) = dialog($buffer,$len);

#print_head(\$response);
#print_buf(\$buffer);
#print_buf(\$response);

$exptext = q|
  0     :  0011_0000  0x30   48  0  
  1     :  0011_1001  0x39   57  9  
  2     :  1000_0100  0x84  132    
  3     :  0000_0000  0x00    0    
  4     :  0000_0000  0x00    0    
  5     :  0000_0001  0x01    1    
  6     :  0000_0000  0x00    0    
  7     :  0000_0001  0x01    1    
  8     :  0000_0000  0x00    0    
  9     :  0000_0010  0x02    2    
  10    :  0000_0000  0x00    0    
  11    :  0000_0010  0x02    2    
  12    :  0000_0011  0x03    3    
  13    :  0110_0010  0x62   98  b  
  14    :  0110_0001  0x61   97  a  
  15    :  0111_0010  0x72  114  r  
  16    :  0000_0011  0x03    3    
  17    :  0110_0011  0x63   99  c  
  18    :  0110_1111  0x6F  111  o  
  19    :  0110_1101  0x6D  109  m  
  20    :  0000_0000  0x00    0    
  21    :  0000_0000  0x00    0    
  22    :  0000_0001  0x01    1    
  23    :  0000_0000  0x00    0    
  24    :  0000_0001  0x01    1    
  25    :  1100_0000  0xC0  192    
  26    :  0000_1100  0x0C   12    
  27    :  0000_0000  0x00    0    
  28    :  0000_0001  0x01    1    
  29    :  0000_0000  0x00    0    
  30    :  0000_0001  0x01    1    
  31    :  0000_0000  0x00    0    
  32    :  0000_0000  0x00    0    
  33    :  0010_1010  0x2A   42  *  
  34    :  0011_0000  0x30   48  0  
  35    :  0000_0000  0x00    0    
  36    :  0000_0100  0x04    4    
  37    :  1100_0000  0xC0  192    
  38    :  1010_1000  0xA8  168    
  39    :  0110_0011  0x63   99  c  
  40    :  0110_0100  0x64  100  d  
  41    :  1100_0000  0xC0  192    
  42    :  0000_1100  0x0C   12    
  43    :  0000_0000  0x00    0    
  44    :  0000_0010  0x02    2    
  45    :  0000_0000  0x00    0    
  46    :  0000_0001  0x01    1    
  47    :  0000_0000  0x00    0    
  48    :  0000_0000  0x00    0    
  49    :  0010_1010  0x2A   42  *  
  50    :  0011_0000  0x30   48  0  
  51    :  0000_0000  0x00    0    
  52    :  0000_1010  0x0A   10    
  53    :  0000_0011  0x03    3    
  54    :  0110_1110  0x6E  110  n  
  55    :  0111_0011  0x73  115  s  
  56    :  0011_0001  0x31   49  1  
  57    :  0000_0011  0x03    3    
  58    :  0111_1000  0x78  120  x  
  59    :  0111_1001  0x79  121  y  
  60    :  0111_1010  0x7A  122  z  
  61    :  1100_0000  0xC0  192    
  62    :  0001_0000  0x10   16    
  63    :  1100_0000  0xC0  192    
  64    :  0000_1100  0x0C   12    
  65    :  0000_0000  0x00    0    
  66    :  0000_0010  0x02    2    
  67    :  0000_0000  0x00    0    
  68    :  0000_0001  0x01    1    
  69    :  0000_0000  0x00    0    
  70    :  0000_0000  0x00    0    
  71    :  0010_1010  0x2A   42  *  
  72    :  0011_0000  0x30   48  0  
  73    :  0000_0000  0x00    0    
  74    :  0000_0110  0x06    6    
  75    :  0000_0011  0x03    3    
  76    :  0110_1110  0x6E  110  n  
  77    :  0111_0011  0x73  115  s  
  78    :  0011_0010  0x32   50  2  
  79    :  1100_0000  0xC0  192    
  80    :  0000_1100  0x0C   12    
  81    :  1100_0000  0xC0  192    
  82    :  0011_0101  0x35   53  5  
  83    :  0000_0000  0x00    0    
  84    :  0000_0001  0x01    1    
  85    :  0000_0000  0x00    0    
  86    :  0000_0001  0x01    1    
  87    :  0000_0000  0x00    0    
  88    :  0000_0000  0x00    0    
  89    :  0010_1010  0x2A   42  *  
  90    :  0011_0000  0x30   48  0  
  91    :  0000_0000  0x00    0    
  92    :  0000_0100  0x04    4    
  93    :  0000_1100  0x0C   12    
  94    :  0010_0010  0x22   34  "  
  95    :  0011_1000  0x38   56  8  
  96    :  0100_1110  0x4E   78  N  
  97    :  1100_0000  0xC0  192    
  98    :  0100_1011  0x4B   75  K  
  99    :  0000_0000  0x00    0    
  100   :  0000_0001  0x01    1    
  101   :  0000_0000  0x00    0    
  102   :  0000_0001  0x01    1    
  103   :  0000_0000  0x00    0    
  104   :  0000_0000  0x00    0    
  105   :  0010_1010  0x2A   42  *  
  106   :  0011_0000  0x30   48  0  
  107   :  0000_0000  0x00    0    
  108   :  0000_0100  0x04    4    
  109   :  0100_1100  0x4C   76  L  
  110   :  0011_0110  0x36   54  6  
  111   :  0010_0000  0x20   32     
  112   :  0000_1010  0x0A   10    
|;
chk_exp(\$response,\$exptext);    

## test 54	set up additional nameserver pointing to local ip, zonename
print "failed to set ns3 name to zonename\nnot "
	unless  &{"${TCTEST}::t_cmdline"}('n',$zonename);
&ok();

## test 55
print "failed to set ns3 IP to localip\nnot "
	unless  &{"${TCTEST}::t_cmdline"}('a',$localip);
&ok();

## test 56	check domain A with domain added as ns server
$len = newhead(\$buffer,
	12345,
	BITS_QUERY,	# opcode
	1,0,0,0,	# one question
);
$len = $put->Question(\$buffer,$len,'bar.com',T_A,C_IN);
($rv,$response) = dialog($buffer,$len);

#print_head(\$response);
#print_buf(\$buffer);
#print_buf(\$response);

$exptext = q|
  0     :  0011_0000  0x30   48  0  
  1     :  0011_1001  0x39   57  9  
  2     :  1000_0100  0x84  132    
  3     :  0000_0000  0x00    0    
  4     :  0000_0000  0x00    0    
  5     :  0000_0001  0x01    1    
  6     :  0000_0000  0x00    0    
  7     :  0000_0001  0x01    1    
  8     :  0000_0000  0x00    0    
  9     :  0000_0011  0x03    3    
  10    :  0000_0000  0x00    0    
  11    :  0000_0010  0x02    2    
  12    :  0000_0011  0x03    3    
  13    :  0110_0010  0x62   98  b  
  14    :  0110_0001  0x61   97  a  
  15    :  0111_0010  0x72  114  r  
  16    :  0000_0011  0x03    3    
  17    :  0110_0011  0x63   99  c  
  18    :  0110_1111  0x6F  111  o  
  19    :  0110_1101  0x6D  109  m  
  20    :  0000_0000  0x00    0    
  21    :  0000_0000  0x00    0    
  22    :  0000_0001  0x01    1    
  23    :  0000_0000  0x00    0    
  24    :  0000_0001  0x01    1    
  25    :  1100_0000  0xC0  192    
  26    :  0000_1100  0x0C   12    
  27    :  0000_0000  0x00    0    
  28    :  0000_0001  0x01    1    
  29    :  0000_0000  0x00    0    
  30    :  0000_0001  0x01    1    
  31    :  0000_0000  0x00    0    
  32    :  0000_0000  0x00    0    
  33    :  0010_1010  0x2A   42  *  
  34    :  0011_0000  0x30   48  0  
  35    :  0000_0000  0x00    0    
  36    :  0000_0100  0x04    4    
  37    :  1100_0000  0xC0  192    
  38    :  1010_1000  0xA8  168    
  39    :  0110_0011  0x63   99  c  
  40    :  0110_0100  0x64  100  d  
  41    :  1100_0000  0xC0  192    
  42    :  0000_1100  0x0C   12    
  43    :  0000_0000  0x00    0    
  44    :  0000_0010  0x02    2    
  45    :  0000_0000  0x00    0    
  46    :  0000_0001  0x01    1    
  47    :  0000_0000  0x00    0    
  48    :  0000_0000  0x00    0    
  49    :  0010_1010  0x2A   42  *  
  50    :  0011_0000  0x30   48  0  
  51    :  0000_0000  0x00    0    
  52    :  0000_1010  0x0A   10    
  53    :  0000_0011  0x03    3    
  54    :  0110_1110  0x6E  110  n  
  55    :  0111_0011  0x73  115  s  
  56    :  0011_0001  0x31   49  1  
  57    :  0000_0011  0x03    3    
  58    :  0111_1000  0x78  120  x  
  59    :  0111_1001  0x79  121  y  
  60    :  0111_1010  0x7A  122  z  
  61    :  1100_0000  0xC0  192    
  62    :  0001_0000  0x10   16    
  63    :  1100_0000  0xC0  192    
  64    :  0000_1100  0x0C   12    
  65    :  0000_0000  0x00    0    
  66    :  0000_0010  0x02    2    
  67    :  0000_0000  0x00    0    
  68    :  0000_0001  0x01    1    
  69    :  0000_0000  0x00    0    
  70    :  0000_0000  0x00    0    
  71    :  0010_1010  0x2A   42  *  
  72    :  0011_0000  0x30   48  0  
  73    :  0000_0000  0x00    0    
  74    :  0000_0110  0x06    6    
  75    :  0000_0011  0x03    3    
  76    :  0110_1110  0x6E  110  n  
  77    :  0111_0011  0x73  115  s  
  78    :  0011_0010  0x32   50  2  
  79    :  1100_0000  0xC0  192    
  80    :  0000_1100  0x0C   12    
  81    :  1100_0000  0xC0  192    
  82    :  0000_1100  0x0C   12    
  83    :  0000_0000  0x00    0    
  84    :  0000_0010  0x02    2    
  85    :  0000_0000  0x00    0    
  86    :  0000_0001  0x01    1    
  87    :  0000_0000  0x00    0    
  88    :  0000_0000  0x00    0    
  89    :  0010_1010  0x2A   42  *  
  90    :  0011_0000  0x30   48  0  
  91    :  0000_0000  0x00    0    
  92    :  0000_0010  0x02    2    
  93    :  1100_0000  0xC0  192    
  94    :  0000_1100  0x0C   12    
  95    :  1100_0000  0xC0  192    
  96    :  0011_0101  0x35   53  5  
  97    :  0000_0000  0x00    0    
  98    :  0000_0001  0x01    1    
  99    :  0000_0000  0x00    0    
  100   :  0000_0001  0x01    1    
  101   :  0000_0000  0x00    0    
  102   :  0000_0000  0x00    0    
  103   :  0010_1010  0x2A   42  *  
  104   :  0011_0000  0x30   48  0  
  105   :  0000_0000  0x00    0    
  106   :  0000_0100  0x04    4    
  107   :  0000_1100  0x0C   12    
  108   :  0010_0010  0x22   34  "  
  109   :  0011_1000  0x38   56  8  
  110   :  0100_1110  0x4E   78  N  
  111   :  1100_0000  0xC0  192    
  112   :  0100_1011  0x4B   75  K  
  113   :  0000_0000  0x00    0    
  114   :  0000_0001  0x01    1    
  115   :  0000_0000  0x00    0    
  116   :  0000_0001  0x01    1    
  117   :  0000_0000  0x00    0    
  118   :  0000_0000  0x00    0    
  119   :  0010_1010  0x2A   42  *  
  120   :  0011_0000  0x30   48  0  
  121   :  0000_0000  0x00    0    
  122   :  0000_0100  0x04    4    
  123   :  0100_1100  0x4C   76  L  
  124   :  0011_0110  0x36   54  6  
  125   :  0010_0000  0x20   32     
  126   :  0000_1010  0x0A   10    
|;
chk_exp(\$response,\$exptext);

## test 57      set local_name = something new
print "failed to set local name\nnot "
        unless  &{"${TCTEST}::t_cmdline"}('L','localhost.'.$zonename);
&ok();

## test 58	check domain A with local name != zone name
$len = newhead(\$buffer,
	12345,
	BITS_QUERY,	# opcode
	1,0,0,0,	# one question
);
$len = $put->Question(\$buffer,$len,'bar.com',T_A,C_IN);
($rv,$response) = dialog($buffer,$len);

#print_head(\$response);
#print_buf(\$buffer);
#print_buf(\$response);

$exptext = q|
  0     :  0011_0000  0x30   48  0  
  1     :  0011_1001  0x39   57  9  
  2     :  1000_0100  0x84  132    
  3     :  0000_0000  0x00    0    
  4     :  0000_0000  0x00    0    
  5     :  0000_0001  0x01    1    
  6     :  0000_0000  0x00    0    
  7     :  0000_0000  0x00    0    
  8     :  0000_0000  0x00    0    
  9     :  0000_0001  0x01    1    
  10    :  0000_0000  0x00    0    
  11    :  0000_0000  0x00    0    
  12    :  0000_0011  0x03    3    
  13    :  0110_0010  0x62   98  b  
  14    :  0110_0001  0x61   97  a  
  15    :  0111_0010  0x72  114  r  
  16    :  0000_0011  0x03    3    
  17    :  0110_0011  0x63   99  c  
  18    :  0110_1111  0x6F  111  o  
  19    :  0110_1101  0x6D  109  m  
  20    :  0000_0000  0x00    0    
  21    :  0000_0000  0x00    0    
  22    :  0000_0001  0x01    1    
  23    :  0000_0000  0x00    0    
  24    :  0000_0001  0x01    1    
  25    :  1100_0000  0xC0  192    
  26    :  0000_1100  0x0C   12    
  27    :  0000_0000  0x00    0    
  28    :  0000_0110  0x06    6    
  29    :  0000_0000  0x00    0    
  30    :  0000_0001  0x01    1    
  31    :  0000_0000  0x00    0    
  32    :  0000_0000  0x00    0    
  33    :  0000_0000  0x00    0    
  34    :  0000_0000  0x00    0    
  35    :  0000_0000  0x00    0    
  36    :  0010_1000  0x28   40  (  
  37    :  0000_1001  0x09    9    
  38    :  0110_1100  0x6C  108  l  
  39    :  0110_1111  0x6F  111  o  
  40    :  0110_0011  0x63   99  c  
  41    :  0110_0001  0x61   97  a  
  42    :  0110_1100  0x6C  108  l  
  43    :  0110_1000  0x68  104  h  
  44    :  0110_1111  0x6F  111  o  
  45    :  0111_0011  0x73  115  s  
  46    :  0111_0100  0x74  116  t  
  47    :  1100_0000  0xC0  192    
  48    :  0000_1100  0x0C   12    
  49    :  0000_0101  0x05    5    
  50    :  0110_1000  0x68  104  h  
  51    :  0111_0101  0x75  117  u  
  52    :  0110_1101  0x6D  109  m  
  53    :  0110_0001  0x61   97  a  
  54    :  0110_1110  0x6E  110  n  
  55    :  1100_0000  0xC0  192    
  56    :  0000_1100  0x0C   12    
  57    :  0000_0111  0x07    7    
  58    :  0101_1011  0x5B   91  [  
  59    :  1100_0011  0xC3  195    
  60    :  0111_0001  0x71  113  q  
  61    :  0000_0000  0x00    0    
  62    :  0000_0000  0x00    0    
  63    :  1010_1000  0xA8  168    
  64    :  1100_0000  0xC0  192    
  65    :  0000_0000  0x00    0    
  66    :  0000_0000  0x00    0    
  67    :  0000_1110  0x0E   14    
  68    :  0001_0000  0x10   16    
  69    :  0000_0000  0x00    0    
  70    :  0000_0001  0x01    1    
  71    :  0101_0001  0x51   81  Q  
  72    :  1000_0000  0x80  128    
  73    :  0000_0000  0x00    0    
  74    :  0000_0000  0x00    0    
  75    :  0010_1010  0x2A   42  *  
  76    :  0011_0000  0x30   48  0  
|;
chk_exp(\$response,\$exptext);

## test 59	check domain NS records
$len = newhead(\$buffer,
	12345,
	BITS_QUERY,	# opcode
	1,0,0,0,	# one question
);
$len = $put->Question(\$buffer,$len,'bar.com',T_NS,C_IN);
($rv,$response) = dialog($buffer,$len);

#print_head(\$response);
#print_buf(\$buffer);
#print_buf(\$response);

$exptext = q|
  0     :  0011_0000  0x30   48  0  
  1     :  0011_1001  0x39   57  9  
  2     :  1000_0100  0x84  132    
  3     :  0000_0000  0x00    0    
  4     :  0000_0000  0x00    0    
  5     :  0000_0001  0x01    1    
  6     :  0000_0000  0x00    0    
  7     :  0000_0011  0x03    3    
  8     :  0000_0000  0x00    0    
  9     :  0000_0000  0x00    0    
  10    :  0000_0000  0x00    0    
  11    :  0000_0011  0x03    3    
  12    :  0000_0011  0x03    3    
  13    :  0110_0010  0x62   98  b  
  14    :  0110_0001  0x61   97  a  
  15    :  0111_0010  0x72  114  r  
  16    :  0000_0011  0x03    3    
  17    :  0110_0011  0x63   99  c  
  18    :  0110_1111  0x6F  111  o  
  19    :  0110_1101  0x6D  109  m  
  20    :  0000_0000  0x00    0    
  21    :  0000_0000  0x00    0    
  22    :  0000_0010  0x02    2    
  23    :  0000_0000  0x00    0    
  24    :  0000_0001  0x01    1    
  25    :  1100_0000  0xC0  192    
  26    :  0000_1100  0x0C   12    
  27    :  0000_0000  0x00    0    
  28    :  0000_0010  0x02    2    
  29    :  0000_0000  0x00    0    
  30    :  0000_0001  0x01    1    
  31    :  0000_0000  0x00    0    
  32    :  0000_0000  0x00    0    
  33    :  0010_1010  0x2A   42  *  
  34    :  0011_0000  0x30   48  0  
  35    :  0000_0000  0x00    0    
  36    :  0000_1010  0x0A   10    
  37    :  0000_0011  0x03    3    
  38    :  0110_1110  0x6E  110  n  
  39    :  0111_0011  0x73  115  s  
  40    :  0011_0001  0x31   49  1  
  41    :  0000_0011  0x03    3    
  42    :  0111_1000  0x78  120  x  
  43    :  0111_1001  0x79  121  y  
  44    :  0111_1010  0x7A  122  z  
  45    :  1100_0000  0xC0  192    
  46    :  0001_0000  0x10   16    
  47    :  1100_0000  0xC0  192    
  48    :  0000_1100  0x0C   12    
  49    :  0000_0000  0x00    0    
  50    :  0000_0010  0x02    2    
  51    :  0000_0000  0x00    0    
  52    :  0000_0001  0x01    1    
  53    :  0000_0000  0x00    0    
  54    :  0000_0000  0x00    0    
  55    :  0010_1010  0x2A   42  *  
  56    :  0011_0000  0x30   48  0  
  57    :  0000_0000  0x00    0    
  58    :  0000_0110  0x06    6    
  59    :  0000_0011  0x03    3    
  60    :  0110_1110  0x6E  110  n  
  61    :  0111_0011  0x73  115  s  
  62    :  0011_0010  0x32   50  2  
  63    :  1100_0000  0xC0  192    
  64    :  0000_1100  0x0C   12    
  65    :  1100_0000  0xC0  192    
  66    :  0000_1100  0x0C   12    
  67    :  0000_0000  0x00    0    
  68    :  0000_0010  0x02    2    
  69    :  0000_0000  0x00    0    
  70    :  0000_0001  0x01    1    
  71    :  0000_0000  0x00    0    
  72    :  0000_0000  0x00    0    
  73    :  0010_1010  0x2A   42  *  
  74    :  0011_0000  0x30   48  0  
  75    :  0000_0000  0x00    0    
  76    :  0000_0010  0x02    2    
  77    :  1100_0000  0xC0  192    
  78    :  0000_1100  0x0C   12    
  79    :  1100_0000  0xC0  192    
  80    :  0010_0101  0x25   37  %  
  81    :  0000_0000  0x00    0    
  82    :  0000_0001  0x01    1    
  83    :  0000_0000  0x00    0    
  84    :  0000_0001  0x01    1    
  85    :  0000_0000  0x00    0    
  86    :  0000_0000  0x00    0    
  87    :  0010_1010  0x2A   42  *  
  88    :  0011_0000  0x30   48  0  
  89    :  0000_0000  0x00    0    
  90    :  0000_0100  0x04    4    
  91    :  0000_1100  0x0C   12    
  92    :  0010_0010  0x22   34  "  
  93    :  0011_1000  0x38   56  8  
  94    :  0100_1110  0x4E   78  N  
  95    :  1100_0000  0xC0  192    
  96    :  0011_1011  0x3B   59  ;  
  97    :  0000_0000  0x00    0    
  98    :  0000_0001  0x01    1    
  99    :  0000_0000  0x00    0    
  100   :  0000_0001  0x01    1    
  101   :  0000_0000  0x00    0    
  102   :  0000_0000  0x00    0    
  103   :  0010_1010  0x2A   42  *  
  104   :  0011_0000  0x30   48  0  
  105   :  0000_0000  0x00    0    
  106   :  0000_0100  0x04    4    
  107   :  0100_1100  0x4C   76  L  
  108   :  0011_0110  0x36   54  6  
  109   :  0010_0000  0x20   32     
  110   :  0000_1010  0x0A   10    
  111   :  1100_0000  0xC0  192    
  112   :  0000_1100  0x0C   12    
  113   :  0000_0000  0x00    0    
  114   :  0000_0001  0x01    1    
  115   :  0000_0000  0x00    0    
  116   :  0000_0001  0x01    1    
  117   :  0000_0000  0x00    0    
  118   :  0000_0000  0x00    0    
  119   :  0010_1010  0x2A   42  *  
  120   :  0011_0000  0x30   48  0  
  121   :  0000_0000  0x00    0    
  122   :  0000_0100  0x04    4    
  123   :  1100_0000  0xC0  192    
  124   :  1010_1000  0xA8  168    
  125   :  0110_0011  0x63   99  c  
  126   :  0110_0100  0x64  100  d  
|;
chk_exp(\$response,\$exptext);

## test 60	check domain MX records
$len = newhead(\$buffer,
	12345,
	BITS_QUERY,	# opcode
	1,0,0,0,	# one question
);
$len = $put->Question(\$buffer,$len,'bar.com',T_MX,C_IN);
($rv,$response) = dialog($buffer,$len);

#print_head(\$response);
#print_buf(\$buffer);
#print_buf(\$response);

$exptext = q|
  0     :  0011_0000  0x30   48  0  
  1     :  0011_1001  0x39   57  9  
  2     :  1000_0100  0x84  132    
  3     :  0000_0000  0x00    0    
  4     :  0000_0000  0x00    0    
  5     :  0000_0001  0x01    1    
  6     :  0000_0000  0x00    0    
  7     :  0000_0010  0x02    2    
  8     :  0000_0000  0x00    0    
  9     :  0000_0011  0x03    3    
  10    :  0000_0000  0x00    0    
  11    :  0000_0101  0x05    5    
  12    :  0000_0011  0x03    3    
  13    :  0110_0010  0x62   98  b  
  14    :  0110_0001  0x61   97  a  
  15    :  0111_0010  0x72  114  r  
  16    :  0000_0011  0x03    3    
  17    :  0110_0011  0x63   99  c  
  18    :  0110_1111  0x6F  111  o  
  19    :  0110_1101  0x6D  109  m  
  20    :  0000_0000  0x00    0    
  21    :  0000_0000  0x00    0    
  22    :  0000_1111  0x0F   15    
  23    :  0000_0000  0x00    0    
  24    :  0000_0001  0x01    1    
  25    :  1100_0000  0xC0  192    
  26    :  0000_1100  0x0C   12    
  27    :  0000_0000  0x00    0    
  28    :  0000_1111  0x0F   15    
  29    :  0000_0000  0x00    0    
  30    :  0000_0001  0x01    1    
  31    :  0000_0000  0x00    0    
  32    :  0000_0000  0x00    0    
  33    :  0010_1010  0x2A   42  *  
  34    :  0011_0000  0x30   48  0  
  35    :  0000_0000  0x00    0    
  36    :  0000_0100  0x04    4    
  37    :  0000_0000  0x00    0    
  38    :  0011_0010  0x32   50  2  
  39    :  1100_0000  0xC0  192    
  40    :  0000_1100  0x0C   12    
  41    :  1100_0000  0xC0  192    
  42    :  0000_1100  0x0C   12    
  43    :  0000_0000  0x00    0    
  44    :  0000_1111  0x0F   15    
  45    :  0000_0000  0x00    0    
  46    :  0000_0001  0x01    1    
  47    :  0000_0000  0x00    0    
  48    :  0000_0000  0x00    0    
  49    :  0010_1010  0x2A   42  *  
  50    :  0011_0000  0x30   48  0  
  51    :  0000_0000  0x00    0    
  52    :  0000_0111  0x07    7    
  53    :  0000_0000  0x00    0    
  54    :  0000_1010  0x0A   10    
  55    :  0000_0010  0x02    2    
  56    :  0110_1101  0x6D  109  m  
  57    :  0111_1000  0x78  120  x  
  58    :  1100_0000  0xC0  192    
  59    :  0000_1100  0x0C   12    
  60    :  1100_0000  0xC0  192    
  61    :  0000_1100  0x0C   12    
  62    :  0000_0000  0x00    0    
  63    :  0000_0010  0x02    2    
  64    :  0000_0000  0x00    0    
  65    :  0000_0001  0x01    1    
  66    :  0000_0000  0x00    0    
  67    :  0000_0000  0x00    0    
  68    :  0010_1010  0x2A   42  *  
  69    :  0011_0000  0x30   48  0  
  70    :  0000_0000  0x00    0    
  71    :  0000_1010  0x0A   10    
  72    :  0000_0011  0x03    3    
  73    :  0110_1110  0x6E  110  n  
  74    :  0111_0011  0x73  115  s  
  75    :  0011_0001  0x31   49  1  
  76    :  0000_0011  0x03    3    
  77    :  0111_1000  0x78  120  x  
  78    :  0111_1001  0x79  121  y  
  79    :  0111_1010  0x7A  122  z  
  80    :  1100_0000  0xC0  192    
  81    :  0001_0000  0x10   16    
  82    :  1100_0000  0xC0  192    
  83    :  0000_1100  0x0C   12    
  84    :  0000_0000  0x00    0    
  85    :  0000_0010  0x02    2    
  86    :  0000_0000  0x00    0    
  87    :  0000_0001  0x01    1    
  88    :  0000_0000  0x00    0    
  89    :  0000_0000  0x00    0    
  90    :  0010_1010  0x2A   42  *  
  91    :  0011_0000  0x30   48  0  
  92    :  0000_0000  0x00    0    
  93    :  0000_0110  0x06    6    
  94    :  0000_0011  0x03    3    
  95    :  0110_1110  0x6E  110  n  
  96    :  0111_0011  0x73  115  s  
  97    :  0011_0010  0x32   50  2  
  98    :  1100_0000  0xC0  192    
  99    :  0000_1100  0x0C   12    
  100   :  1100_0000  0xC0  192    
  101   :  0000_1100  0x0C   12    
  102   :  0000_0000  0x00    0    
  103   :  0000_0010  0x02    2    
  104   :  0000_0000  0x00    0    
  105   :  0000_0001  0x01    1    
  106   :  0000_0000  0x00    0    
  107   :  0000_0000  0x00    0    
  108   :  0010_1010  0x2A   42  *  
  109   :  0011_0000  0x30   48  0  
  110   :  0000_0000  0x00    0    
  111   :  0000_0010  0x02    2    
  112   :  1100_0000  0xC0  192    
  113   :  0000_1100  0x0C   12    
  114   :  1100_0000  0xC0  192    
  115   :  0100_1000  0x48   72  H  
  116   :  0000_0000  0x00    0    
  117   :  0000_0001  0x01    1    
  118   :  0000_0000  0x00    0    
  119   :  0000_0001  0x01    1    
  120   :  0000_0000  0x00    0    
  121   :  0000_0000  0x00    0    
  122   :  0010_1010  0x2A   42  *  
  123   :  0011_0000  0x30   48  0  
  124   :  0000_0000  0x00    0    
  125   :  0000_0100  0x04    4    
  126   :  0000_1100  0x0C   12    
  127   :  0010_0010  0x22   34  "  
  128   :  0011_1000  0x38   56  8  
  129   :  0100_1110  0x4E   78  N  
  130   :  1100_0000  0xC0  192    
  131   :  0101_1110  0x5E   94  ^  
  132   :  0000_0000  0x00    0    
  133   :  0000_0001  0x01    1    
  134   :  0000_0000  0x00    0    
  135   :  0000_0001  0x01    1    
  136   :  0000_0000  0x00    0    
  137   :  0000_0000  0x00    0    
  138   :  0010_1010  0x2A   42  *  
  139   :  0011_0000  0x30   48  0  
  140   :  0000_0000  0x00    0    
  141   :  0000_0100  0x04    4    
  142   :  0100_1100  0x4C   76  L  
  143   :  0011_0110  0x36   54  6  
  144   :  0010_0000  0x20   32     
  145   :  0000_1010  0x0A   10    
  146   :  1100_0000  0xC0  192    
  147   :  0000_1100  0x0C   12    
  148   :  0000_0000  0x00    0    
  149   :  0000_0001  0x01    1    
  150   :  0000_0000  0x00    0    
  151   :  0000_0001  0x01    1    
  152   :  0000_0000  0x00    0    
  153   :  0000_0000  0x00    0    
  154   :  0010_1010  0x2A   42  *  
  155   :  0011_0000  0x30   48  0  
  156   :  0000_0000  0x00    0    
  157   :  0000_0100  0x04    4    
  158   :  0000_0001  0x01    1    
  159   :  0000_0010  0x02    2    
  160   :  0000_0011  0x03    3    
  161   :  0000_0100  0x04    4    
  162   :  1100_0000  0xC0  192    
  163   :  0011_0111  0x37   55  7  
  164   :  0000_0000  0x00    0    
  165   :  0000_0001  0x01    1    
  166   :  0000_0000  0x00    0    
  167   :  0000_0001  0x01    1    
  168   :  0000_0000  0x00    0    
  169   :  0000_0000  0x00    0    
  170   :  0010_1010  0x2A   42  *  
  171   :  0011_0000  0x30   48  0  
  172   :  0000_0000  0x00    0    
  173   :  0000_0100  0x04    4    
  174   :  0110_0101  0x65  101  e  
  175   :  1100_1010  0xCA  202    
  176   :  0110_0111  0x67  103  g  
  177   :  0010_1100  0x2C   44  ,  
  178   :  1100_0000  0xC0  192    
  179   :  0000_1100  0x0C   12    
  180   :  0000_0000  0x00    0    
  181   :  0000_0001  0x01    1    
  182   :  0000_0000  0x00    0    
  183   :  0000_0001  0x01    1    
  184   :  0000_0000  0x00    0    
  185   :  0000_0000  0x00    0    
  186   :  0010_1010  0x2A   42  *  
  187   :  0011_0000  0x30   48  0  
  188   :  0000_0000  0x00    0    
  189   :  0000_0100  0x04    4    
  190   :  1100_0000  0xC0  192    
  191   :  1010_1000  0xA8  168    
  192   :  0110_0011  0x63   99  c  
  193   :  0110_0100  0x64  100  d  
|;
chk_exp(\$response,\$exptext);

## test 61	check domain ANY records
$len = newhead(\$buffer,
	12345,
	BITS_QUERY,	# opcode
	1,0,0,0,	# one question
);
$len = $put->Question(\$buffer,$len,'bar.com',T_ANY,C_IN);
($rv,$response) = dialog($buffer,$len);

#print_head(\$response);
#print_buf(\$buffer);
#print_buf(\$response);

$exptext = q|
  0     :  0011_0000  0x30   48  0  
  1     :  0011_1001  0x39   57  9  
  2     :  1000_0100  0x84  132    
  3     :  0000_0000  0x00    0    
  4     :  0000_0000  0x00    0    
  5     :  0000_0001  0x01    1    
  6     :  0000_0000  0x00    0    
  7     :  0000_0110  0x06    6    
  8     :  0000_0000  0x00    0    
  9     :  0000_0000  0x00    0    
  10    :  0000_0000  0x00    0    
  11    :  0000_0101  0x05    5    
  12    :  0000_0011  0x03    3    
  13    :  0110_0010  0x62   98  b  
  14    :  0110_0001  0x61   97  a  
  15    :  0111_0010  0x72  114  r  
  16    :  0000_0011  0x03    3    
  17    :  0110_0011  0x63   99  c  
  18    :  0110_1111  0x6F  111  o  
  19    :  0110_1101  0x6D  109  m  
  20    :  0000_0000  0x00    0    
  21    :  0000_0000  0x00    0    
  22    :  1111_1111  0xFF  255    
  23    :  0000_0000  0x00    0    
  24    :  0000_0001  0x01    1    
  25    :  1100_0000  0xC0  192    
  26    :  0000_1100  0x0C   12    
  27    :  0000_0000  0x00    0    
  28    :  0000_0110  0x06    6    
  29    :  0000_0000  0x00    0    
  30    :  0000_0001  0x01    1    
  31    :  0000_0000  0x00    0    
  32    :  0000_0000  0x00    0    
  33    :  0000_0000  0x00    0    
  34    :  0000_0000  0x00    0    
  35    :  0000_0000  0x00    0    
  36    :  0010_1000  0x28   40  (  
  37    :  0000_1001  0x09    9    
  38    :  0110_1100  0x6C  108  l  
  39    :  0110_1111  0x6F  111  o  
  40    :  0110_0011  0x63   99  c  
  41    :  0110_0001  0x61   97  a  
  42    :  0110_1100  0x6C  108  l  
  43    :  0110_1000  0x68  104  h  
  44    :  0110_1111  0x6F  111  o  
  45    :  0111_0011  0x73  115  s  
  46    :  0111_0100  0x74  116  t  
  47    :  1100_0000  0xC0  192    
  48    :  0000_1100  0x0C   12    
  49    :  0000_0101  0x05    5    
  50    :  0110_1000  0x68  104  h  
  51    :  0111_0101  0x75  117  u  
  52    :  0110_1101  0x6D  109  m  
  53    :  0110_0001  0x61   97  a  
  54    :  0110_1110  0x6E  110  n  
  55    :  1100_0000  0xC0  192    
  56    :  0000_1100  0x0C   12    
  57    :  0000_0111  0x07    7    
  58    :  0101_1011  0x5B   91  [  
  59    :  1100_0011  0xC3  195    
  60    :  0111_0001  0x71  113  q  
  61    :  0000_0000  0x00    0    
  62    :  0000_0000  0x00    0    
  63    :  1010_1000  0xA8  168    
  64    :  1100_0000  0xC0  192    
  65    :  0000_0000  0x00    0    
  66    :  0000_0000  0x00    0    
  67    :  0000_1110  0x0E   14    
  68    :  0001_0000  0x10   16    
  69    :  0000_0000  0x00    0    
  70    :  0000_0001  0x01    1    
  71    :  0101_0001  0x51   81  Q  
  72    :  1000_0000  0x80  128    
  73    :  0000_0000  0x00    0    
  74    :  0000_0000  0x00    0    
  75    :  0010_1010  0x2A   42  *  
  76    :  0011_0000  0x30   48  0  
  77    :  1100_0000  0xC0  192    
  78    :  0000_1100  0x0C   12    
  79    :  0000_0000  0x00    0    
  80    :  0000_0010  0x02    2    
  81    :  0000_0000  0x00    0    
  82    :  0000_0001  0x01    1    
  83    :  0000_0000  0x00    0    
  84    :  0000_0000  0x00    0    
  85    :  0010_1010  0x2A   42  *  
  86    :  0011_0000  0x30   48  0  
  87    :  0000_0000  0x00    0    
  88    :  0000_1010  0x0A   10    
  89    :  0000_0011  0x03    3    
  90    :  0110_1110  0x6E  110  n  
  91    :  0111_0011  0x73  115  s  
  92    :  0011_0001  0x31   49  1  
  93    :  0000_0011  0x03    3    
  94    :  0111_1000  0x78  120  x  
  95    :  0111_1001  0x79  121  y  
  96    :  0111_1010  0x7A  122  z  
  97    :  1100_0000  0xC0  192    
  98    :  0001_0000  0x10   16    
  99    :  1100_0000  0xC0  192    
  100   :  0000_1100  0x0C   12    
  101   :  0000_0000  0x00    0    
  102   :  0000_0010  0x02    2    
  103   :  0000_0000  0x00    0    
  104   :  0000_0001  0x01    1    
  105   :  0000_0000  0x00    0    
  106   :  0000_0000  0x00    0    
  107   :  0010_1010  0x2A   42  *  
  108   :  0011_0000  0x30   48  0  
  109   :  0000_0000  0x00    0    
  110   :  0000_0110  0x06    6    
  111   :  0000_0011  0x03    3    
  112   :  0110_1110  0x6E  110  n  
  113   :  0111_0011  0x73  115  s  
  114   :  0011_0010  0x32   50  2  
  115   :  1100_0000  0xC0  192    
  116   :  0000_1100  0x0C   12    
  117   :  1100_0000  0xC0  192    
  118   :  0000_1100  0x0C   12    
  119   :  0000_0000  0x00    0    
  120   :  0000_0010  0x02    2    
  121   :  0000_0000  0x00    0    
  122   :  0000_0001  0x01    1    
  123   :  0000_0000  0x00    0    
  124   :  0000_0000  0x00    0    
  125   :  0010_1010  0x2A   42  *  
  126   :  0011_0000  0x30   48  0  
  127   :  0000_0000  0x00    0    
  128   :  0000_0010  0x02    2    
  129   :  1100_0000  0xC0  192    
  130   :  0000_1100  0x0C   12    
  131   :  1100_0000  0xC0  192    
  132   :  0000_1100  0x0C   12    
  133   :  0000_0000  0x00    0    
  134   :  0000_1111  0x0F   15    
  135   :  0000_0000  0x00    0    
  136   :  0000_0001  0x01    1    
  137   :  0000_0000  0x00    0    
  138   :  0000_0000  0x00    0    
  139   :  0010_1010  0x2A   42  *  
  140   :  0011_0000  0x30   48  0  
  141   :  0000_0000  0x00    0    
  142   :  0000_0100  0x04    4    
  143   :  0000_0000  0x00    0    
  144   :  0011_0010  0x32   50  2  
  145   :  1100_0000  0xC0  192    
  146   :  0000_1100  0x0C   12    
  147   :  1100_0000  0xC0  192    
  148   :  0000_1100  0x0C   12    
  149   :  0000_0000  0x00    0    
  150   :  0000_1111  0x0F   15    
  151   :  0000_0000  0x00    0    
  152   :  0000_0001  0x01    1    
  153   :  0000_0000  0x00    0    
  154   :  0000_0000  0x00    0    
  155   :  0010_1010  0x2A   42  *  
  156   :  0011_0000  0x30   48  0  
  157   :  0000_0000  0x00    0    
  158   :  0000_0111  0x07    7    
  159   :  0000_0000  0x00    0    
  160   :  0000_1010  0x0A   10    
  161   :  0000_0010  0x02    2    
  162   :  0110_1101  0x6D  109  m  
  163   :  0111_1000  0x78  120  x  
  164   :  1100_0000  0xC0  192    
  165   :  0000_1100  0x0C   12    
  166   :  1100_0000  0xC0  192    
  167   :  0101_1001  0x59   89  Y  
  168   :  0000_0000  0x00    0    
  169   :  0000_0001  0x01    1    
  170   :  0000_0000  0x00    0    
  171   :  0000_0001  0x01    1    
  172   :  0000_0000  0x00    0    
  173   :  0000_0000  0x00    0    
  174   :  0010_1010  0x2A   42  *  
  175   :  0011_0000  0x30   48  0  
  176   :  0000_0000  0x00    0    
  177   :  0000_0100  0x04    4    
  178   :  0000_1100  0x0C   12    
  179   :  0010_0010  0x22   34  "  
  180   :  0011_1000  0x38   56  8  
  181   :  0100_1110  0x4E   78  N  
  182   :  1100_0000  0xC0  192    
  183   :  0110_1111  0x6F  111  o  
  184   :  0000_0000  0x00    0    
  185   :  0000_0001  0x01    1    
  186   :  0000_0000  0x00    0    
  187   :  0000_0001  0x01    1    
  188   :  0000_0000  0x00    0    
  189   :  0000_0000  0x00    0    
  190   :  0010_1010  0x2A   42  *  
  191   :  0011_0000  0x30   48  0  
  192   :  0000_0000  0x00    0    
  193   :  0000_0100  0x04    4    
  194   :  0100_1100  0x4C   76  L  
  195   :  0011_0110  0x36   54  6  
  196   :  0010_0000  0x20   32     
  197   :  0000_1010  0x0A   10    
  198   :  1100_0000  0xC0  192    
  199   :  0000_1100  0x0C   12    
  200   :  0000_0000  0x00    0    
  201   :  0000_0001  0x01    1    
  202   :  0000_0000  0x00    0    
  203   :  0000_0001  0x01    1    
  204   :  0000_0000  0x00    0    
  205   :  0000_0000  0x00    0    
  206   :  0010_1010  0x2A   42  *  
  207   :  0011_0000  0x30   48  0  
  208   :  0000_0000  0x00    0    
  209   :  0000_0100  0x04    4    
  210   :  0000_0001  0x01    1    
  211   :  0000_0010  0x02    2    
  212   :  0000_0011  0x03    3    
  213   :  0000_0100  0x04    4    
  214   :  1100_0000  0xC0  192    
  215   :  1010_0001  0xA1  161    
  216   :  0000_0000  0x00    0    
  217   :  0000_0001  0x01    1    
  218   :  0000_0000  0x00    0    
  219   :  0000_0001  0x01    1    
  220   :  0000_0000  0x00    0    
  221   :  0000_0000  0x00    0    
  222   :  0010_1010  0x2A   42  *  
  223   :  0011_0000  0x30   48  0  
  224   :  0000_0000  0x00    0    
  225   :  0000_0100  0x04    4    
  226   :  0110_0101  0x65  101  e  
  227   :  1100_1010  0xCA  202    
  228   :  0110_0111  0x67  103  g  
  229   :  0010_1100  0x2C   44  ,  
  230   :  1100_0000  0xC0  192    
  231   :  0000_1100  0x0C   12    
  232   :  0000_0000  0x00    0    
  233   :  0000_0001  0x01    1    
  234   :  0000_0000  0x00    0    
  235   :  0000_0001  0x01    1    
  236   :  0000_0000  0x00    0    
  237   :  0000_0000  0x00    0    
  238   :  0010_1010  0x2A   42  *  
  239   :  0011_0000  0x30   48  0  
  240   :  0000_0000  0x00    0    
  241   :  0000_0100  0x04    4    
  242   :  1100_0000  0xC0  192    
  243   :  1010_1000  0xA8  168    
  244   :  0110_0011  0x63   99  c  
  245   :  0110_0100  0x64  100  d  
|;
chk_exp(\$response,\$exptext);    

## test 62      set local_name = something new
print "failed to set local name\nnot "
        unless  &{"${TCTEST}::t_cmdline"}('L',$zonename);
&ok();

## test 63	check domain ANY records with zone = local
$len = newhead(\$buffer,
	12345,
	BITS_QUERY,	# opcode
	1,0,0,0,	# one question
);
$len = $put->Question(\$buffer,$len,'bar.com',T_ANY,C_IN);
($rv,$response) = dialog($buffer,$len);

#print_head(\$response);
#print_buf(\$buffer);
#print_buf(\$response);

$exptext = q|
  0     :  0011_0000  0x30   48  0  
  1     :  0011_1001  0x39   57  9  
  2     :  1000_0100  0x84  132    
  3     :  0000_0000  0x00    0    
  4     :  0000_0000  0x00    0    
  5     :  0000_0001  0x01    1    
  6     :  0000_0000  0x00    0    
  7     :  0000_0111  0x07    7    
  8     :  0000_0000  0x00    0    
  9     :  0000_0000  0x00    0    
  10    :  0000_0000  0x00    0    
  11    :  0000_0011  0x03    3    
  12    :  0000_0011  0x03    3    
  13    :  0110_0010  0x62   98  b  
  14    :  0110_0001  0x61   97  a  
  15    :  0111_0010  0x72  114  r  
  16    :  0000_0011  0x03    3    
  17    :  0110_0011  0x63   99  c  
  18    :  0110_1111  0x6F  111  o  
  19    :  0110_1101  0x6D  109  m  
  20    :  0000_0000  0x00    0    
  21    :  0000_0000  0x00    0    
  22    :  1111_1111  0xFF  255    
  23    :  0000_0000  0x00    0    
  24    :  0000_0001  0x01    1    
  25    :  1100_0000  0xC0  192    
  26    :  0000_1100  0x0C   12    
  27    :  0000_0000  0x00    0    
  28    :  0000_0001  0x01    1    
  29    :  0000_0000  0x00    0    
  30    :  0000_0001  0x01    1    
  31    :  0000_0000  0x00    0    
  32    :  0000_0000  0x00    0    
  33    :  0010_1010  0x2A   42  *  
  34    :  0011_0000  0x30   48  0  
  35    :  0000_0000  0x00    0    
  36    :  0000_0100  0x04    4    
  37    :  1100_0000  0xC0  192    
  38    :  1010_1000  0xA8  168    
  39    :  0110_0011  0x63   99  c  
  40    :  0110_0100  0x64  100  d  
  41    :  1100_0000  0xC0  192    
  42    :  0000_1100  0x0C   12    
  43    :  0000_0000  0x00    0    
  44    :  0000_0110  0x06    6    
  45    :  0000_0000  0x00    0    
  46    :  0000_0001  0x01    1    
  47    :  0000_0000  0x00    0    
  48    :  0000_0000  0x00    0    
  49    :  0000_0000  0x00    0    
  50    :  0000_0000  0x00    0    
  51    :  0000_0000  0x00    0    
  52    :  0001_1110  0x1E   30    
  53    :  1100_0000  0xC0  192    
  54    :  0000_1100  0x0C   12    
  55    :  0000_0101  0x05    5    
  56    :  0110_1000  0x68  104  h  
  57    :  0111_0101  0x75  117  u  
  58    :  0110_1101  0x6D  109  m  
  59    :  0110_0001  0x61   97  a  
  60    :  0110_1110  0x6E  110  n  
  61    :  1100_0000  0xC0  192    
  62    :  0000_1100  0x0C   12    
  63    :  0000_0111  0x07    7    
  64    :  0101_1011  0x5B   91  [  
  65    :  1100_0011  0xC3  195    
  66    :  0111_0001  0x71  113  q  
  67    :  0000_0000  0x00    0    
  68    :  0000_0000  0x00    0    
  69    :  1010_1000  0xA8  168    
  70    :  1100_0000  0xC0  192    
  71    :  0000_0000  0x00    0    
  72    :  0000_0000  0x00    0    
  73    :  0000_1110  0x0E   14    
  74    :  0001_0000  0x10   16    
  75    :  0000_0000  0x00    0    
  76    :  0000_0001  0x01    1    
  77    :  0101_0001  0x51   81  Q  
  78    :  1000_0000  0x80  128    
  79    :  0000_0000  0x00    0    
  80    :  0000_0000  0x00    0    
  81    :  0010_1010  0x2A   42  *  
  82    :  0011_0000  0x30   48  0  
  83    :  1100_0000  0xC0  192    
  84    :  0000_1100  0x0C   12    
  85    :  0000_0000  0x00    0    
  86    :  0000_0010  0x02    2    
  87    :  0000_0000  0x00    0    
  88    :  0000_0001  0x01    1    
  89    :  0000_0000  0x00    0    
  90    :  0000_0000  0x00    0    
  91    :  0010_1010  0x2A   42  *  
  92    :  0011_0000  0x30   48  0  
  93    :  0000_0000  0x00    0    
  94    :  0000_1010  0x0A   10    
  95    :  0000_0011  0x03    3    
  96    :  0110_1110  0x6E  110  n  
  97    :  0111_0011  0x73  115  s  
  98    :  0011_0001  0x31   49  1  
  99    :  0000_0011  0x03    3    
  100   :  0111_1000  0x78  120  x  
  101   :  0111_1001  0x79  121  y  
  102   :  0111_1010  0x7A  122  z  
  103   :  1100_0000  0xC0  192    
  104   :  0001_0000  0x10   16    
  105   :  1100_0000  0xC0  192    
  106   :  0000_1100  0x0C   12    
  107   :  0000_0000  0x00    0    
  108   :  0000_0010  0x02    2    
  109   :  0000_0000  0x00    0    
  110   :  0000_0001  0x01    1    
  111   :  0000_0000  0x00    0    
  112   :  0000_0000  0x00    0    
  113   :  0010_1010  0x2A   42  *  
  114   :  0011_0000  0x30   48  0  
  115   :  0000_0000  0x00    0    
  116   :  0000_0110  0x06    6    
  117   :  0000_0011  0x03    3    
  118   :  0110_1110  0x6E  110  n  
  119   :  0111_0011  0x73  115  s  
  120   :  0011_0010  0x32   50  2  
  121   :  1100_0000  0xC0  192    
  122   :  0000_1100  0x0C   12    
  123   :  1100_0000  0xC0  192    
  124   :  0000_1100  0x0C   12    
  125   :  0000_0000  0x00    0    
  126   :  0000_0010  0x02    2    
  127   :  0000_0000  0x00    0    
  128   :  0000_0001  0x01    1    
  129   :  0000_0000  0x00    0    
  130   :  0000_0000  0x00    0    
  131   :  0010_1010  0x2A   42  *  
  132   :  0011_0000  0x30   48  0  
  133   :  0000_0000  0x00    0    
  134   :  0000_0010  0x02    2    
  135   :  1100_0000  0xC0  192    
  136   :  0000_1100  0x0C   12    
  137   :  1100_0000  0xC0  192    
  138   :  0000_1100  0x0C   12    
  139   :  0000_0000  0x00    0    
  140   :  0000_1111  0x0F   15    
  141   :  0000_0000  0x00    0    
  142   :  0000_0001  0x01    1    
  143   :  0000_0000  0x00    0    
  144   :  0000_0000  0x00    0    
  145   :  0010_1010  0x2A   42  *  
  146   :  0011_0000  0x30   48  0  
  147   :  0000_0000  0x00    0    
  148   :  0000_0100  0x04    4    
  149   :  0000_0000  0x00    0    
  150   :  0011_0010  0x32   50  2  
  151   :  1100_0000  0xC0  192    
  152   :  0000_1100  0x0C   12    
  153   :  1100_0000  0xC0  192    
  154   :  0000_1100  0x0C   12    
  155   :  0000_0000  0x00    0    
  156   :  0000_1111  0x0F   15    
  157   :  0000_0000  0x00    0    
  158   :  0000_0001  0x01    1    
  159   :  0000_0000  0x00    0    
  160   :  0000_0000  0x00    0    
  161   :  0010_1010  0x2A   42  *  
  162   :  0011_0000  0x30   48  0  
  163   :  0000_0000  0x00    0    
  164   :  0000_0111  0x07    7    
  165   :  0000_0000  0x00    0    
  166   :  0000_1010  0x0A   10    
  167   :  0000_0010  0x02    2    
  168   :  0110_1101  0x6D  109  m  
  169   :  0111_1000  0x78  120  x  
  170   :  1100_0000  0xC0  192    
  171   :  0000_1100  0x0C   12    
  172   :  1100_0000  0xC0  192    
  173   :  0101_1111  0x5F   95  _  
  174   :  0000_0000  0x00    0    
  175   :  0000_0001  0x01    1    
  176   :  0000_0000  0x00    0    
  177   :  0000_0001  0x01    1    
  178   :  0000_0000  0x00    0    
  179   :  0000_0000  0x00    0    
  180   :  0010_1010  0x2A   42  *  
  181   :  0011_0000  0x30   48  0  
  182   :  0000_0000  0x00    0    
  183   :  0000_0100  0x04    4    
  184   :  0000_1100  0x0C   12    
  185   :  0010_0010  0x22   34  "  
  186   :  0011_1000  0x38   56  8  
  187   :  0100_1110  0x4E   78  N  
  188   :  1100_0000  0xC0  192    
  189   :  0111_0101  0x75  117  u  
  190   :  0000_0000  0x00    0    
  191   :  0000_0001  0x01    1    
  192   :  0000_0000  0x00    0    
  193   :  0000_0001  0x01    1    
  194   :  0000_0000  0x00    0    
  195   :  0000_0000  0x00    0    
  196   :  0010_1010  0x2A   42  *  
  197   :  0011_0000  0x30   48  0  
  198   :  0000_0000  0x00    0    
  199   :  0000_0100  0x04    4    
  200   :  0100_1100  0x4C   76  L  
  201   :  0011_0110  0x36   54  6  
  202   :  0010_0000  0x20   32     
  203   :  0000_1010  0x0A   10    
  204   :  1100_0000  0xC0  192    
  205   :  1010_0111  0xA7  167    
  206   :  0000_0000  0x00    0    
  207   :  0000_0001  0x01    1    
  208   :  0000_0000  0x00    0    
  209   :  0000_0001  0x01    1    
  210   :  0000_0000  0x00    0    
  211   :  0000_0000  0x00    0    
  212   :  0010_1010  0x2A   42  *  
  213   :  0011_0000  0x30   48  0  
  214   :  0000_0000  0x00    0    
  215   :  0000_0100  0x04    4    
  216   :  0110_0101  0x65  101  e  
  217   :  1100_1010  0xCA  202    
  218   :  0110_0111  0x67  103  g  
  219   :  0010_1100  0x2C   44  ,  
|;
chk_exp(\$response,\$exptext);

## test 64	check attempted AXFR using udp
$len = newhead(\$buffer,
	12345,
	BITS_QUERY,	# opcode
	1,0,0,0,	# one question
);
$len = $put->Question(\$buffer,$len,'bar.com',T_AXFR,C_IN);
($rv,$response) = dialog($buffer,$len);

#print_head(\$response);
#print_buf(\$buffer);
#print_buf(\$response);

$exptext = q|
  0     :  0011_0000  0x30   48  0  
  1     :  0011_1001  0x39   57  9  
  2     :  1000_0110  0x86  134    
  3     :  0000_0001  0x01    1    
  4     :  0000_0000  0x00    0    
  5     :  0000_0001  0x01    1    
  6     :  0000_0000  0x00    0    
  7     :  0000_0000  0x00    0    
  8     :  0000_0000  0x00    0    
  9     :  0000_0000  0x00    0    
  10    :  0000_0000  0x00    0    
  11    :  0000_0000  0x00    0    
  12    :  0000_0011  0x03    3    
  13    :  0110_0010  0x62   98  b  
  14    :  0110_0001  0x61   97  a  
  15    :  0111_0010  0x72  114  r  
  16    :  0000_0011  0x03    3    
  17    :  0110_0011  0x63   99  c  
  18    :  0110_1111  0x6F  111  o  
  19    :  0110_1101  0x6D  109  m  
  20    :  0000_0000  0x00    0    
  21    :  0000_0000  0x00    0    
  22    :  1111_1100  0xFC  252    
  23    :  0000_0000  0x00    0    
  24    :  0000_0001  0x01    1    
|;
chk_exp(\$response,\$exptext);

## test 65      set AXFR block to 1
print "failed to set local name\nnot "
        unless  &{"${TCTEST}::t_cmdline"}('b',1);
&ok();

## test 66	check attempted AXFR while blocked, should be refused
$len = newhead(\$buffer,
	12345,
	BITS_QUERY,	# opcode
	1,0,0,0,	# one question
);
$len = $put->Question(\$buffer,$len,'bar.com',T_AXFR,C_IN);
($rv,$response) = dialog($buffer,$len);

#print_head(\$response);
#print_buf(\$buffer);
#print_buf(\$response);

$exptext = q|
  0     :  0011_0000  0x30   48  0  
  1     :  0011_1001  0x39   57  9  
  2     :  1000_0100  0x84  132    
  3     :  0000_0101  0x05    5    
  4     :  0000_0000  0x00    0    
  5     :  0000_0001  0x01    1    
  6     :  0000_0000  0x00    0    
  7     :  0000_0000  0x00    0    
  8     :  0000_0000  0x00    0    
  9     :  0000_0000  0x00    0    
  10    :  0000_0000  0x00    0    
  11    :  0000_0000  0x00    0    
  12    :  0000_0011  0x03    3    
  13    :  0110_0010  0x62   98  b  
  14    :  0110_0001  0x61   97  a  
  15    :  0111_0010  0x72  114  r  
  16    :  0000_0011  0x03    3    
  17    :  0110_0011  0x63   99  c  
  18    :  0110_1111  0x6F  111  o  
  19    :  0110_1101  0x6D  109  m  
  20    :  0000_0000  0x00    0    
  21    :  0000_0000  0x00    0    
  22    :  1111_1100  0xFC  252    
  23    :  0000_0000  0x00    0    
  24    :  0000_0001  0x01    1    
|;
chk_exp(\$response,\$exptext);

## test 67      set AXFR block to 0
print "failed to set local name\nnot "
        unless  &{"${TCTEST}::t_cmdline"}('b',0);
&ok();

## test 68      set local_name = something new
print "failed to set local name\nnot "
        unless  &{"${TCTEST}::t_cmdline"}('L','localhost.'.$zonename);
&ok();

## test 69	check unsupported TYPE for auth only return
$len = newhead(\$buffer,
	12345,
	BITS_QUERY,	# opcode
	1,0,0,0,	# one question
);
$len = $put->Question(\$buffer,$len,'bar.com',T_NULL,C_IN);
($rv,$response) = dialog($buffer,$len);

#print_head(\$response);
#print_buf(\$buffer);
#print_buf(\$response);

$exptext = q|
  0     :  0011_0000  0x30   48  0  
  1     :  0011_1001  0x39   57  9  
  2     :  1000_0100  0x84  132    
  3     :  0000_0100  0x04    4    
  4     :  0000_0000  0x00    0    
  5     :  0000_0001  0x01    1    
  6     :  0000_0000  0x00    0    
  7     :  0000_0000  0x00    0    
  8     :  0000_0000  0x00    0    
  9     :  0000_0000  0x00    0    
  10    :  0000_0000  0x00    0    
  11    :  0000_0000  0x00    0    
  12    :  0000_0011  0x03    3    
  13    :  0110_0010  0x62   98  b  
  14    :  0110_0001  0x61   97  a  
  15    :  0111_0010  0x72  114  r  
  16    :  0000_0011  0x03    3    
  17    :  0110_0011  0x63   99  c  
  18    :  0110_1111  0x6F  111  o  
  19    :  0110_1101  0x6D  109  m  
  20    :  0000_0000  0x00    0    
  21    :  0000_0000  0x00    0    
  22    :  0000_1010  0x0A   10    
  23    :  0000_0000  0x00    0    
  24    :  0000_0001  0x01    1    
  25    :  1100_0000  0xC0  192    
  26    :  0000_1100  0x0C   12    
  27    :  0000_0000  0x00    0    
  28    :  0000_0110  0x06    6    
  29    :  0000_0000  0x00    0    
  30    :  0000_0001  0x01    1    
  31    :  0000_0000  0x00    0    
  32    :  0000_0000  0x00    0    
  33    :  0000_0000  0x00    0    
  34    :  0000_0000  0x00    0    
  35    :  0000_0000  0x00    0    
  36    :  0010_1000  0x28   40  (  
  37    :  0000_1001  0x09    9    
  38    :  0110_1100  0x6C  108  l  
  39    :  0110_1111  0x6F  111  o  
  40    :  0110_0011  0x63   99  c  
  41    :  0110_0001  0x61   97  a  
  42    :  0110_1100  0x6C  108  l  
  43    :  0110_1000  0x68  104  h  
  44    :  0110_1111  0x6F  111  o  
  45    :  0111_0011  0x73  115  s  
  46    :  0111_0100  0x74  116  t  
  47    :  1100_0000  0xC0  192    
  48    :  0000_1100  0x0C   12    
  49    :  0000_0101  0x05    5    
  50    :  0110_1000  0x68  104  h  
  51    :  0111_0101  0x75  117  u  
  52    :  0110_1101  0x6D  109  m  
  53    :  0110_0001  0x61   97  a  
  54    :  0110_1110  0x6E  110  n  
  55    :  1100_0000  0xC0  192    
  56    :  0000_1100  0x0C   12    
  57    :  0000_0111  0x07    7    
  58    :  0101_1011  0x5B   91  [  
  59    :  1100_0011  0xC3  195    
  60    :  0111_0001  0x71  113  q  
  61    :  0000_0000  0x00    0    
  62    :  0000_0000  0x00    0    
  63    :  1010_1000  0xA8  168    
  64    :  1100_0000  0xC0  192    
  65    :  0000_0000  0x00    0    
  66    :  0000_0000  0x00    0    
  67    :  0000_1110  0x0E   14    
  68    :  0001_0000  0x10   16    
  69    :  0000_0000  0x00    0    
  70    :  0000_0001  0x01    1    
  71    :  0101_0001  0x51   81  Q  
  72    :  1000_0000  0x80  128    
  73    :  0000_0000  0x00    0    
  74    :  0000_0000  0x00    0    
  75    :  0010_1010  0x2A   42  *  
  76    :  0011_0000  0x30   48  0  
|;
chk_exp(\$response,\$exptext);

########################################################
# checks complete for zone = question except for AXFR
########################################################

## test 70	check A record, known host
$len = newhead(\$buffer,
	12345,
	BITS_QUERY,	# opcode
	1,0,0,0,	# one question
);
$len = $put->Question(\$buffer,$len,'mx.bar.com',T_A,C_IN);
($rv,$response) = dialog($buffer,$len);

#print_head(\$response);
#print_buf(\$buffer);
#print_buf(\$response);

$exptext = q|
  0     :  0011_0000  0x30   48  0  
  1     :  0011_1001  0x39   57  9  
  2     :  1000_0100  0x84  132    
  3     :  0000_0000  0x00    0    
  4     :  0000_0000  0x00    0    
  5     :  0000_0001  0x01    1    
  6     :  0000_0000  0x00    0    
  7     :  0000_0001  0x01    1    
  8     :  0000_0000  0x00    0    
  9     :  0000_0011  0x03    3    
  10    :  0000_0000  0x00    0    
  11    :  0000_0011  0x03    3    
  12    :  0000_0010  0x02    2    
  13    :  0110_1101  0x6D  109  m  
  14    :  0111_1000  0x78  120  x  
  15    :  0000_0011  0x03    3    
  16    :  0110_0010  0x62   98  b  
  17    :  0110_0001  0x61   97  a  
  18    :  0111_0010  0x72  114  r  
  19    :  0000_0011  0x03    3    
  20    :  0110_0011  0x63   99  c  
  21    :  0110_1111  0x6F  111  o  
  22    :  0110_1101  0x6D  109  m  
  23    :  0000_0000  0x00    0    
  24    :  0000_0000  0x00    0    
  25    :  0000_0001  0x01    1    
  26    :  0000_0000  0x00    0    
  27    :  0000_0001  0x01    1    
  28    :  1100_0000  0xC0  192    
  29    :  0000_1100  0x0C   12    
  30    :  0000_0000  0x00    0    
  31    :  0000_0001  0x01    1    
  32    :  0000_0000  0x00    0    
  33    :  0000_0001  0x01    1    
  34    :  0000_0000  0x00    0    
  35    :  0000_0000  0x00    0    
  36    :  0010_1010  0x2A   42  *  
  37    :  0011_0000  0x30   48  0  
  38    :  0000_0000  0x00    0    
  39    :  0000_0100  0x04    4    
  40    :  0110_0101  0x65  101  e  
  41    :  1100_1010  0xCA  202    
  42    :  0110_0111  0x67  103  g  
  43    :  0010_1100  0x2C   44  ,  
  44    :  1100_0000  0xC0  192    
  45    :  0000_1111  0x0F   15    
  46    :  0000_0000  0x00    0    
  47    :  0000_0010  0x02    2    
  48    :  0000_0000  0x00    0    
  49    :  0000_0001  0x01    1    
  50    :  0000_0000  0x00    0    
  51    :  0000_0000  0x00    0    
  52    :  0010_1010  0x2A   42  *  
  53    :  0011_0000  0x30   48  0  
  54    :  0000_0000  0x00    0    
  55    :  0000_1010  0x0A   10    
  56    :  0000_0011  0x03    3    
  57    :  0110_1110  0x6E  110  n  
  58    :  0111_0011  0x73  115  s  
  59    :  0011_0001  0x31   49  1  
  60    :  0000_0011  0x03    3    
  61    :  0111_1000  0x78  120  x  
  62    :  0111_1001  0x79  121  y  
  63    :  0111_1010  0x7A  122  z  
  64    :  1100_0000  0xC0  192    
  65    :  0001_0011  0x13   19    
  66    :  1100_0000  0xC0  192    
  67    :  0000_1111  0x0F   15    
  68    :  0000_0000  0x00    0    
  69    :  0000_0010  0x02    2    
  70    :  0000_0000  0x00    0    
  71    :  0000_0001  0x01    1    
  72    :  0000_0000  0x00    0    
  73    :  0000_0000  0x00    0    
  74    :  0010_1010  0x2A   42  *  
  75    :  0011_0000  0x30   48  0  
  76    :  0000_0000  0x00    0    
  77    :  0000_0110  0x06    6    
  78    :  0000_0011  0x03    3    
  79    :  0110_1110  0x6E  110  n  
  80    :  0111_0011  0x73  115  s  
  81    :  0011_0010  0x32   50  2  
  82    :  1100_0000  0xC0  192    
  83    :  0000_1111  0x0F   15    
  84    :  1100_0000  0xC0  192    
  85    :  0000_1111  0x0F   15    
  86    :  0000_0000  0x00    0    
  87    :  0000_0010  0x02    2    
  88    :  0000_0000  0x00    0    
  89    :  0000_0001  0x01    1    
  90    :  0000_0000  0x00    0    
  91    :  0000_0000  0x00    0    
  92    :  0010_1010  0x2A   42  *  
  93    :  0011_0000  0x30   48  0  
  94    :  0000_0000  0x00    0    
  95    :  0000_0010  0x02    2    
  96    :  1100_0000  0xC0  192    
  97    :  0000_1111  0x0F   15    
  98    :  1100_0000  0xC0  192    
  99    :  0011_1000  0x38   56  8  
  100   :  0000_0000  0x00    0    
  101   :  0000_0001  0x01    1    
  102   :  0000_0000  0x00    0    
  103   :  0000_0001  0x01    1    
  104   :  0000_0000  0x00    0    
  105   :  0000_0000  0x00    0    
  106   :  0010_1010  0x2A   42  *  
  107   :  0011_0000  0x30   48  0  
  108   :  0000_0000  0x00    0    
  109   :  0000_0100  0x04    4    
  110   :  0000_1100  0x0C   12    
  111   :  0010_0010  0x22   34  "  
  112   :  0011_1000  0x38   56  8  
  113   :  0100_1110  0x4E   78  N  
  114   :  1100_0000  0xC0  192    
  115   :  0100_1110  0x4E   78  N  
  116   :  0000_0000  0x00    0    
  117   :  0000_0001  0x01    1    
  118   :  0000_0000  0x00    0    
  119   :  0000_0001  0x01    1    
  120   :  0000_0000  0x00    0    
  121   :  0000_0000  0x00    0    
  122   :  0010_1010  0x2A   42  *  
  123   :  0011_0000  0x30   48  0  
  124   :  0000_0000  0x00    0    
  125   :  0000_0100  0x04    4    
  126   :  0100_1100  0x4C   76  L  
  127   :  0011_0110  0x36   54  6  
  128   :  0010_0000  0x20   32     
  129   :  0000_1010  0x0A   10    
  130   :  1100_0000  0xC0  192    
  131   :  0000_1111  0x0F   15    
  132   :  0000_0000  0x00    0    
  133   :  0000_0001  0x01    1    
  134   :  0000_0000  0x00    0    
  135   :  0000_0001  0x01    1    
  136   :  0000_0000  0x00    0    
  137   :  0000_0000  0x00    0    
  138   :  0010_1010  0x2A   42  *  
  139   :  0011_0000  0x30   48  0  
  140   :  0000_0000  0x00    0    
  141   :  0000_0100  0x04    4    
  142   :  1100_0000  0xC0  192    
  143   :  1010_1000  0xA8  168    
  144   :  0110_0011  0x63   99  c  
  145   :  0110_0100  0x64  100  d  
|;
chk_exp(\$response,\$exptext);    

## test 71	check A record, unknown host
$len = newhead(\$buffer,
	12345,
	BITS_QUERY,	# opcode
	1,0,0,0,	# one question
);
$len = $put->Question(\$buffer,$len,'unknown.bar.com',T_A,C_IN);
($rv,$response) = dialog($buffer,$len);

#print_head(\$response);
#print_buf(\$buffer);
#print_buf(\$response);

$exptext = q|
  0     :  0011_0000  0x30   48  0  
  1     :  0011_1001  0x39   57  9  
  2     :  1000_0100  0x84  132    
  3     :  0000_0000  0x00    0    
  4     :  0000_0000  0x00    0    
  5     :  0000_0001  0x01    1    
  6     :  0000_0000  0x00    0    
  7     :  0000_0000  0x00    0    
  8     :  0000_0000  0x00    0    
  9     :  0000_0001  0x01    1    
  10    :  0000_0000  0x00    0    
  11    :  0000_0000  0x00    0    
  12    :  0000_0111  0x07    7    
  13    :  0111_0101  0x75  117  u  
  14    :  0110_1110  0x6E  110  n  
  15    :  0110_1011  0x6B  107  k  
  16    :  0110_1110  0x6E  110  n  
  17    :  0110_1111  0x6F  111  o  
  18    :  0111_0111  0x77  119  w  
  19    :  0110_1110  0x6E  110  n  
  20    :  0000_0011  0x03    3    
  21    :  0110_0010  0x62   98  b  
  22    :  0110_0001  0x61   97  a  
  23    :  0111_0010  0x72  114  r  
  24    :  0000_0011  0x03    3    
  25    :  0110_0011  0x63   99  c  
  26    :  0110_1111  0x6F  111  o  
  27    :  0110_1101  0x6D  109  m  
  28    :  0000_0000  0x00    0    
  29    :  0000_0000  0x00    0    
  30    :  0000_0001  0x01    1    
  31    :  0000_0000  0x00    0    
  32    :  0000_0001  0x01    1    
  33    :  1100_0000  0xC0  192    
  34    :  0001_0100  0x14   20    
  35    :  0000_0000  0x00    0    
  36    :  0000_0110  0x06    6    
  37    :  0000_0000  0x00    0    
  38    :  0000_0001  0x01    1    
  39    :  0000_0000  0x00    0    
  40    :  0000_0000  0x00    0    
  41    :  0000_0000  0x00    0    
  42    :  0000_0000  0x00    0   
  43    :  0000_0000  0x00    0    
  44    :  0010_1000  0x28   40  (  
  45    :  0000_1001  0x09    9    
  46    :  0110_1100  0x6C  108  l  
  47    :  0110_1111  0x6F  111  o  
  48    :  0110_0011  0x63   99  c  
  49    :  0110_0001  0x61   97  a  
  50    :  0110_1100  0x6C  108  l  
  51    :  0110_1000  0x68  104  h  
  52    :  0110_1111  0x6F  111  o  
  53    :  0111_0011  0x73  115  s  
  54    :  0111_0100  0x74  116  t  
  55    :  1100_0000  0xC0  192    
  56    :  0001_0100  0x14   20    
  57    :  0000_0101  0x05    5    
  58    :  0110_1000  0x68  104  h  
  59    :  0111_0101  0x75  117  u  
  60    :  0110_1101  0x6D  109  m  
  61    :  0110_0001  0x61   97  a  
  62    :  0110_1110  0x6E  110  n  
  63    :  1100_0000  0xC0  192    
  64    :  0001_0100  0x14   20    
  65    :  0000_0111  0x07    7    
  66    :  0101_1011  0x5B   91  [  
  67    :  1100_0011  0xC3  195    
  68    :  0111_0001  0x71  113  q  
  69    :  0000_0000  0x00    0    
  70    :  0000_0000  0x00    0    
  71    :  1010_1000  0xA8  168    
  72    :  1100_0000  0xC0  192    
  73    :  0000_0000  0x00    0    
  74    :  0000_0000  0x00    0    
  75    :  0000_1110  0x0E   14    
  76    :  0001_0000  0x10   16    
  77    :  0000_0000  0x00    0    
  78    :  0000_0001  0x01    1    
  79    :  0101_0001  0x51   81  Q  
  80    :  1000_0000  0x80  128    
  81    :  0000_0000  0x00    0    
  82    :  0000_0000  0x00    0    
  83    :  0010_1010  0x2A   42  *  
  84    :  0011_0000  0x30   48  0  
|;
chk_exp(\$response,\$exptext);    

## test 72	check NOT A record, known host
$len = newhead(\$buffer,
	12345,
	BITS_QUERY,	# opcode
	1,0,0,0,	# one question
);
$len = $put->Question(\$buffer,$len,'mx.bar.com',T_NS,C_IN);
($rv,$response) = dialog($buffer,$len);

#print_head(\$response);
#print_buf(\$buffer);
#print_buf(\$response);

$exptext = q|
  0     :  0011_0000  0x30   48  0  
  1     :  0011_1001  0x39   57  9  
  2     :  1000_0100  0x84  132    
  3     :  0000_0000  0x00    0    
  4     :  0000_0000  0x00    0    
  5     :  0000_0001  0x01    1    
  6     :  0000_0000  0x00    0    
  7     :  0000_0000  0x00    0    
  8     :  0000_0000  0x00    0    
  9     :  0000_0001  0x01    1    
  10    :  0000_0000  0x00    0    
  11    :  0000_0000  0x00    0    
  12    :  0000_0010  0x02    2    
  13    :  0110_1101  0x6D  109  m  
  14    :  0111_1000  0x78  120  x  
  15    :  0000_0011  0x03    3    
  16    :  0110_0010  0x62   98  b  
  17    :  0110_0001  0x61   97  a  
  18    :  0111_0010  0x72  114  r  
  19    :  0000_0011  0x03    3    
  20    :  0110_0011  0x63   99  c  
  21    :  0110_1111  0x6F  111  o  
  22    :  0110_1101  0x6D  109  m  
  23    :  0000_0000  0x00    0    
  24    :  0000_0000  0x00    0    
  25    :  0000_0010  0x02    2    
  26    :  0000_0000  0x00    0    
  27    :  0000_0001  0x01    1    
  28    :  1100_0000  0xC0  192    
  29    :  0000_1111  0x0F   15    
  30    :  0000_0000  0x00    0    
  31    :  0000_0110  0x06    6    
  32    :  0000_0000  0x00    0    
  33    :  0000_0001  0x01    1    
  34    :  0000_0000  0x00    0    
  35    :  0000_0000  0x00    0    
  36    :  0000_0000  0x00    0    
  37    :  0000_0000  0x00    0    
  38    :  0000_0000  0x00    0    
  39    :  0010_1000  0x28   40  (  
  40    :  0000_1001  0x09    9    
  41    :  0110_1100  0x6C  108  l  
  42    :  0110_1111  0x6F  111  o  
  43    :  0110_0011  0x63   99  c  
  44    :  0110_0001  0x61   97  a  
  45    :  0110_1100  0x6C  108  l  
  46    :  0110_1000  0x68  104  h  
  47    :  0110_1111  0x6F  111  o  
  48    :  0111_0011  0x73  115  s  
  49    :  0111_0100  0x74  116  t  
  50    :  1100_0000  0xC0  192    
  51    :  0000_1111  0x0F   15    
  52    :  0000_0101  0x05    5    
  53    :  0110_1000  0x68  104  h  
  54    :  0111_0101  0x75  117  u  
  55    :  0110_1101  0x6D  109  m  
  56    :  0110_0001  0x61   97  a  
  57    :  0110_1110  0x6E  110  n  
  58    :  1100_0000  0xC0  192    
  59    :  0000_1111  0x0F   15    
  60    :  0000_0111  0x07    7    
  61    :  0101_1011  0x5B   91  [  
  62    :  1100_0011  0xC3  195    
  63    :  0111_0001  0x71  113  q  
  64    :  0000_0000  0x00    0    
  65    :  0000_0000  0x00    0    
  66    :  1010_1000  0xA8  168    
  67    :  1100_0000  0xC0  192    
  68    :  0000_0000  0x00    0    
  69    :  0000_0000  0x00    0    
  70    :  0000_1110  0x0E   14    
  71    :  0001_0000  0x10   16    
  72    :  0000_0000  0x00    0    
  73    :  0000_0001  0x01    1    
  74    :  0101_0001  0x51   81  Q  
  75    :  1000_0000  0x80  128    
  76    :  0000_0000  0x00    0    
  77    :  0000_0000  0x00    0    
  78    :  0010_1010  0x2A   42  *  
  79    :  0011_0000  0x30   48  0  
|;
chk_exp(\$response,\$exptext);    

## test 73	set default error response
print "failed to set contact name\nnot "
	unless &{"${TCTEST}::t_cmdline"}('e','Error: your mail server has been BLACKHOLED. See http://blackhole.spamcannibal.com');
&ok();

## test 74	check unknown numeric A record
$len = newhead(\$buffer,
	12345,
	BITS_QUERY,	# opcode
	1,0,0,0,	# one question
);
$len = $put->Question(\$buffer,$len,'1.2.3.4.bar.com',T_A,C_IN);
($rv,$response) = dialog($buffer,$len);

#print_head(\$response);
#print_buf(\$buffer);
#print_buf(\$response);

$exptext = q|
  0     :  0011_0000  0x30   48  0  
  1     :  0011_1001  0x39   57  9  
  2     :  1000_0100  0x84  132    
  3     :  0000_0000  0x00    0    
  4     :  0000_0000  0x00    0    
  5     :  0000_0001  0x01    1    
  6     :  0000_0000  0x00    0    
  7     :  0000_0000  0x00    0    
  8     :  0000_0000  0x00    0    
  9     :  0000_0001  0x01    1    
  10    :  0000_0000  0x00    0    
  11    :  0000_0000  0x00    0    
  12    :  0000_0001  0x01    1    
  13    :  0011_0001  0x31   49  1  
  14    :  0000_0001  0x01    1    
  15    :  0011_0010  0x32   50  2  
  16    :  0000_0001  0x01    1    
  17    :  0011_0011  0x33   51  3  
  18    :  0000_0001  0x01    1    
  19    :  0011_0100  0x34   52  4  
  20    :  0000_0011  0x03    3    
  21    :  0110_0010  0x62   98  b  
  22    :  0110_0001  0x61   97  a  
  23    :  0111_0010  0x72  114  r  
  24    :  0000_0011  0x03    3    
  25    :  0110_0011  0x63   99  c  
  26    :  0110_1111  0x6F  111  o  
  27    :  0110_1101  0x6D  109  m  
  28    :  0000_0000  0x00    0    
  29    :  0000_0000  0x00    0    
  30    :  0000_0010  0x02    1    
  31    :  0000_0000  0x00    0    
  32    :  0000_0001  0x01    1    
  33    :  1100_0000  0xC0  192    
  34    :  0001_0100  0x14   20    
  35    :  0000_0000  0x00    0    
  36    :  0000_0110  0x06    6    
  37    :  0000_0000  0x00    0    
  38    :  0000_0001  0x01    1    
  39    :  0000_0000  0x00    0    
  40    :  0000_0000  0x00    0    
  41    :  0000_0000  0x00    0    
  42    :  0000_0000  0x00    0    
  43    :  0000_0000  0x00    0    
  44    :  0010_1000  0x28   40  (  
  45    :  0000_1001  0x09    9    
  46    :  0110_1100  0x6C  108  l  
  47    :  0110_1111  0x6F  111  o  
  48    :  0110_0011  0x63   99  c  
  49    :  0110_0001  0x61   97  a  
  50    :  0110_1100  0x6C  108  l  
  51    :  0110_1000  0x68  104  h  
  52    :  0110_1111  0x6F  111  o  
  53    :  0111_0011  0x73  115  s  
  54    :  0111_0100  0x74  116  t  
  55    :  1100_0000  0xC0  192    
  56    :  0001_0100  0x14   20    
  57    :  0000_0101  0x05    5    
  58    :  0110_1000  0x68  104  h  
  59    :  0111_0101  0x75  117  u  
  60    :  0110_1101  0x6D  109  m  
  61    :  0110_0001  0x61   97  a  
  62    :  0110_1110  0x6E  110  n  
  63    :  1100_0000  0xC0  192    
  64    :  0001_0100  0x14   20    
  65    :  0000_0111  0x07    7    
  66    :  0101_1011  0x5B   91  [  
  67    :  1100_0011  0xC3  195    
  68    :  0111_0001  0x71  113  q  
  69    :  0000_0000  0x00    0    
  70    :  0000_0000  0x00    0    
  71    :  1010_1000  0xA8  168    
  72    :  1100_0000  0xC0  192    
  73    :  0000_0000  0x00    0    
  74    :  0000_0000  0x00    0    
  75    :  0000_1110  0x0E   14    
  76    :  0001_0000  0x10   16    
  77    :  0000_0000  0x00    0    
  78    :  0000_0001  0x01    1    
  79    :  0101_0001  0x51   81  Q  
  80    :  1000_0000  0x80  128    
  81    :  0000_0000  0x00    0    
  82    :  0000_0000  0x00    0    
  83    :  0010_1010  0x2A   42  *  
  84    :  0011_0000  0x30   48  0  
|;
chk_exp(\$response,\$exptext);    

## test 75	insert known IP in database
print "failed to set known IP 4.3.2.1 in database\nnot "
	if $ipt->put('tarpit',inet_aton("4.3.2.1"),123451234);
&ok();

## test 76	check known numeric A record
$len = newhead(\$buffer,
	12345,
	BITS_QUERY,	# opcode
	1,0,0,0,	# one question
);
$len = $put->Question(\$buffer,$len,'1.2.3.4.bar.com',T_A,C_IN);
($rv,$response) = dialog($buffer,$len);

#print_head(\$response);
#print_buf(\$buffer);
#print_buf(\$response);

$exptext = q|
  0     :  0011_0000  0x30   48  0  
  1     :  0011_1001  0x39   57  9  
  2     :  1000_0100  0x84  132    
  3     :  0000_0000  0x00    0    
  4     :  0000_0000  0x00    0    
  5     :  0000_0001  0x01    1    
  6     :  0000_0000  0x00    0    
  7     :  0000_0001  0x01    1    
  8     :  0000_0000  0x00    0    
  9     :  0000_0011  0x03    3    
  10    :  0000_0000  0x00    0    
  11    :  0000_0011  0x03    3    
  12    :  0000_0001  0x01    1    
  13    :  0011_0001  0x31   49  1  
  14    :  0000_0001  0x01    1    
  15    :  0011_0010  0x32   50  2  
  16    :  0000_0001  0x01    1    
  17    :  0011_0011  0x33   51  3  
  18    :  0000_0001  0x01    1    
  19    :  0011_0100  0x34   52  4  
  20    :  0000_0011  0x03    3    
  21    :  0110_0010  0x62   98  b  
  22    :  0110_0001  0x61   97  a  
  23    :  0111_0010  0x72  114  r  
  24    :  0000_0011  0x03    3    
  25    :  0110_0011  0x63   99  c  
  26    :  0110_1111  0x6F  111  o  
  27    :  0110_1101  0x6D  109  m  
  28    :  0000_0000  0x00    0    
  29    :  0000_0000  0x00    0    
  30    :  0000_0001  0x01    1    
  31    :  0000_0000  0x00    0    
  32    :  0000_0001  0x01    1    
  33    :  1100_0000  0xC0  192    
  34    :  0000_1100  0x0C   12    
  35    :  0000_0000  0x00    0    
  36    :  0000_0001  0x01    1    
  37    :  0000_0000  0x00    0    
  38    :  0000_0001  0x01    1    
  39    :  0000_0000  0x00    0    
  40    :  0000_0000  0x00    0    
  41    :  0010_1010  0x2A   42  *  
  42    :  0011_0000  0x30   48  0  
  43    :  0000_0000  0x00    0    
  44    :  0000_0100  0x04    4    
  45    :  0111_1111  0x7F  127    
  46    :  0000_0000  0x00    0    
  47    :  0000_0000  0x00    0    
  48    :  0000_0003  0x03    3    
  49    :  1100_0000  0xC0  192    
  50    :  0001_0100  0x14   20    
  51    :  0000_0000  0x00    0    
  52    :  0000_0010  0x02    2    
  53    :  0000_0000  0x00    0    
  54    :  0000_0001  0x01    1    
  55    :  0000_0000  0x00    0    
  56    :  0000_0000  0x00    0    
  57    :  0010_1010  0x2A   42  *  
  58    :  0011_0000  0x30   48  0  
  59    :  0000_0000  0x00    0    
  60    :  0000_1010  0x0A   10    
  61    :  0000_0011  0x03    3    
  62    :  0110_1110  0x6E  110  n  
  63    :  0111_0011  0x73  115  s  
  64    :  0011_0001  0x31   49  1  
  65    :  0000_0011  0x03    3    
  66    :  0111_1000  0x78  120  x  
  67    :  0111_1001  0x79  121  y  
  68    :  0111_1010  0x7A  122  z  
  69    :  1100_0000  0xC0  192    
  70    :  0001_1000  0x18   24    
  71    :  1100_0000  0xC0  192    
  72    :  0001_0100  0x14   20    
  73    :  0000_0000  0x00    0    
  74    :  0000_0010  0x02    2    
  75    :  0000_0000  0x00    0    
  76    :  0000_0001  0x01    1    
  77    :  0000_0000  0x00    0    
  78    :  0000_0000  0x00    0    
  79    :  0010_1010  0x2A   42  *  
  80    :  0011_0000  0x30   48  0  
  81    :  0000_0000  0x00    0    
  82    :  0000_0110  0x06    6    
  83    :  0000_0011  0x03    3    
  84    :  0110_1110  0x6E  110  n  
  85    :  0111_0011  0x73  115  s  
  86    :  0011_0010  0x32   50  2  
  87    :  1100_0000  0xC0  192    
  88    :  0001_0100  0x14   20    
  89    :  1100_0000  0xC0  192    
  90    :  0001_0100  0x14   20    
  91    :  0000_0000  0x00    0    
  92    :  0000_0010  0x02    2    
  93    :  0000_0000  0x00    0    
  94    :  0000_0001  0x01    1    
  95    :  0000_0000  0x00    0    
  96    :  0000_0000  0x00    0    
  97    :  0010_1010  0x2A   42  *  
  98    :  0011_0000  0x30   48  0  
  99    :  0000_0000  0x00    0    
  100   :  0000_0010  0x02    2    
  101   :  1100_0000  0xC0  192    
  102   :  0001_0100  0x14   20    
  103   :  1100_0000  0xC0  192    
  104   :  0011_1101  0x3D   61  =  
  105   :  0000_0000  0x00    0    
  106   :  0000_0001  0x01    1    
  107   :  0000_0000  0x00    0    
  108   :  0000_0001  0x01    1    
  109   :  0000_0000  0x00    0    
  110   :  0000_0000  0x00    0    
  111   :  0010_1010  0x2A   42  *  
  112   :  0011_0000  0x30   48  0  
  113   :  0000_0000  0x00    0    
  114   :  0000_0100  0x04    4    
  115   :  0000_1100  0x0C   12    
  116   :  0010_0010  0x22   34  "  
  117   :  0011_1000  0x38   56  8  
  118   :  0100_1110  0x4E   78  N  
  119   :  1100_0000  0xC0  192    
  120   :  0101_0011  0x53   83  S  
  121   :  0000_0000  0x00    0    
  122   :  0000_0001  0x01    1    
  123   :  0000_0000  0x00    0    
  124   :  0000_0001  0x01    1    
  125   :  0000_0000  0x00    0    
  126   :  0000_0000  0x00    0    
  127   :  0010_1010  0x2A   42  *  
  128   :  0011_0000  0x30   48  0  
  129   :  0000_0000  0x00    0    
  130   :  0000_0100  0x04    4    
  131   :  0100_1100  0x4C   76  L  
  132   :  0011_0110  0x36   54  6  
  133   :  0010_0000  0x20   32     
  134   :  0000_1010  0x0A   10    
  135   :  1100_0000  0xC0  192    
  136   :  0001_0100  0x14   20    
  137   :  0000_0000  0x00    0    
  138   :  0000_0001  0x01    1    
  139   :  0000_0000  0x00    0    
  140   :  0000_0001  0x01    1    
  141   :  0000_0000  0x00    0    
  142   :  0000_0000  0x00    0    
  143   :  0010_1010  0x2A   42  *  
  144   :  0011_0000  0x30   48  0  
  145   :  0000_0000  0x00    0    
  146   :  0000_0100  0x04    4    
  147   :  1100_0000  0xC0  192    
  148   :  1010_1000  0xA8  168    
  149   :  0110_0011  0x63   99  c  
  150   :  0110_0100  0x64  100  d  
|;
chk_exp(\$response,\$exptext);    

## test 77	check known numeric TXT record
$len = newhead(\$buffer,
	12345,
	BITS_QUERY,	# opcode
	1,0,0,0,	# one question
);
$len = $put->Question(\$buffer,$len,'1.2.3.4.bar.com',T_TXT,C_IN);
($rv,$response) = dialog($buffer,$len);

#print_head(\$response);
#print_buf(\$buffer);
#print_buf(\$response);

$exptext = q|
  0     :  0011_0000  0x30   48  0  
  1     :  0011_1001  0x39   57  9  
  2     :  1000_0100  0x84  132    
  3     :  0000_0000  0x00    0    
  4     :  0000_0000  0x00    0    
  5     :  0000_0001  0x01    1    
  6     :  0000_0000  0x00    0    
  7     :  0000_0001  0x01    1    
  8     :  0000_0000  0x00    0    
  9     :  0000_0011  0x03    3    
  10    :  0000_0000  0x00    0    
  11    :  0000_0011  0x03    3    
  12    :  0000_0001  0x01    1    
  13    :  0011_0001  0x31   49  1  
  14    :  0000_0001  0x01    1    
  15    :  0011_0010  0x32   50  2  
  16    :  0000_0001  0x01    1    
  17    :  0011_0011  0x33   51  3  
  18    :  0000_0001  0x01    1    
  19    :  0011_0100  0x34   52  4  
  20    :  0000_0011  0x03    3    
  21    :  0110_0010  0x62   98  b  
  22    :  0110_0001  0x61   97  a  
  23    :  0111_0010  0x72  114  r  
  24    :  0000_0011  0x03    3    
  25    :  0110_0011  0x63   99  c  
  26    :  0110_1111  0x6F  111  o  
  27    :  0110_1101  0x6D  109  m  
  28    :  0000_0000  0x00    0    
  29    :  0000_0000  0x00    0    
  30    :  0001_0000  0x10   16    
  31    :  0000_0000  0x00    0    
  32    :  0000_0001  0x01    1    
  33    :  1100_0000  0xC0  192    
  34    :  0000_1100  0x0C   12    
  35    :  0000_0000  0x00    0    
  36    :  0001_0000  0x10   16    
  37    :  0000_0000  0x00    0    
  38    :  0000_0001  0x01    1    
  39    :  0000_0000  0x00    0    
  40    :  0000_0000  0x00    0    
  41    :  0010_1010  0x2A   42  *  
  42    :  0011_0000  0x30   48  0  
  43    :  0000_0000  0x00    0    
  44    :  0101_0011  0x53   83  S  
  45    :  0101_0010  0x52   82  R  
  46    :  0100_0101  0x45   69  E  
  47    :  0111_0010  0x72  114  r  
  48    :  0111_0010  0x72  114  r  
  49    :  0110_1111  0x6F  111  o  
  50    :  0111_0010  0x72  114  r  
  51    :  0011_1010  0x3A   58  :  
  52    :  0010_0000  0x20   32     
  53    :  0111_1001  0x79  121  y  
  54    :  0110_1111  0x6F  111  o  
  55    :  0111_0101  0x75  117  u  
  56    :  0111_0010  0x72  114  r  
  57    :  0010_0000  0x20   32     
  58    :  0110_1101  0x6D  109  m  
  59    :  0110_0001  0x61   97  a  
  60    :  0110_1001  0x69  105  i  
  61    :  0110_1100  0x6C  108  l  
  62    :  0010_0000  0x20   32     
  63    :  0111_0011  0x73  115  s  
  64    :  0110_0101  0x65  101  e  
  65    :  0111_0010  0x72  114  r  
  66    :  0111_0110  0x76  118  v  
  67    :  0110_0101  0x65  101  e  
  68    :  0111_0010  0x72  114  r  
  69    :  0010_0000  0x20   32     
  70    :  0110_1000  0x68  104  h  
  71    :  0110_0001  0x61   97  a  
  72    :  0111_0011  0x73  115  s  
  73    :  0010_0000  0x20   32     
  74    :  0110_0010  0x62   98  b  
  75    :  0110_0101  0x65  101  e  
  76    :  0110_0101  0x65  101  e  
  77    :  0110_1110  0x6E  110  n  
  78    :  0010_0000  0x20   32     
  79    :  0100_0010  0x42   66  B  
  80    :  0100_1100  0x4C   76  L  
  81    :  0100_0001  0x41   65  A  
  82    :  0100_0011  0x43   67  C  
  83    :  0100_1011  0x4B   75  K  
  84    :  0100_1000  0x48   72  H  
  85    :  0100_1111  0x4F   79  O  
  86    :  0100_1100  0x4C   76  L  
  87    :  0100_0101  0x45   69  E  
  88    :  0100_0100  0x44   68  D  
  89    :  0010_1110  0x2E   46  .  
  90    :  0010_0000  0x20   32     
  91    :  0101_0011  0x53   83  S  
  92    :  0110_0101  0x65  101  e  
  93    :  0110_0101  0x65  101  e  
  94    :  0010_0000  0x20   32     
  95    :  0110_1000  0x68  104  h  
  96    :  0111_0100  0x74  116  t  
  97    :  0111_0100  0x74  116  t  
  98    :  0111_0000  0x70  112  p  
  99    :  0011_1010  0x3A   58  :  
  100   :  0010_1111  0x2F   47  /  
  101   :  0010_1111  0x2F   47  /  
  102   :  0110_0010  0x62   98  b  
  103   :  0110_1100  0x6C  108  l  
  104   :  0110_0001  0x61   97  a  
  105   :  0110_0011  0x63   99  c  
  106   :  0110_1011  0x6B  107  k  
  107   :  0110_1000  0x68  104  h  
  108   :  0110_1111  0x6F  111  o  
  109   :  0110_1100  0x6C  108  l  
  110   :  0110_0101  0x65  101  e  
  111   :  0010_1110  0x2E   46  .  
  112   :  0111_0011  0x73  115  s  
  113   :  0111_0000  0x70  112  p  
  114   :  0110_0001  0x61   97  a  
  115   :  0110_1101  0x6D  109  m  
  116   :  0110_0011  0x63   99  c  
  117   :  0110_0001  0x61   97  a  
  118   :  0110_1110  0x6E  110  n  
  119   :  0110_1110  0x6E  110  n  
  120   :  0110_1001  0x69  105  i  
  121   :  0110_0010  0x62   98  b  
  122   :  0110_0001  0x61   97  a  
  123   :  0110_1100  0x6C  108  l  
  124   :  0010_1110  0x2E   46  .  
  125   :  0110_0011  0x63   99  c  
  126   :  0110_1111  0x6F  111  o  
  127   :  0110_1101  0x6D  109  m  
  128   :  1100_0000  0xC0  192    
  129   :  0001_0100  0x14   20    
  130   :  0000_0000  0x00    0    
  131   :  0000_0010  0x02    2    
  132   :  0000_0000  0x00    0    
  133   :  0000_0001  0x01    1    
  134   :  0000_0000  0x00    0    
  135   :  0000_0000  0x00    0    
  136   :  0010_1010  0x2A   42  *  
  137   :  0011_0000  0x30   48  0  
  138   :  0000_0000  0x00    0    
  139   :  0000_1010  0x0A   10    
  140   :  0000_0011  0x03    3    
  141   :  0110_1110  0x6E  110  n  
  142   :  0111_0011  0x73  115  s  
  143   :  0011_0001  0x31   49  1  
  144   :  0000_0011  0x03    3    
  145   :  0111_1000  0x78  120  x  
  146   :  0111_1001  0x79  121  y  
  147   :  0111_1010  0x7A  122  z  
  148   :  1100_0000  0xC0  192    
  149   :  0001_1000  0x18   24    
  150   :  1100_0000  0xC0  192    
  151   :  0001_0100  0x14   20    
  152   :  0000_0000  0x00    0    
  153   :  0000_0010  0x02    2    
  154   :  0000_0000  0x00    0    
  155   :  0000_0001  0x01    1    
  156   :  0000_0000  0x00    0    
  157   :  0000_0000  0x00    0    
  158   :  0010_1010  0x2A   42  *  
  159   :  0011_0000  0x30   48  0  
  160   :  0000_0000  0x00    0    
  161   :  0000_0110  0x06    6    
  162   :  0000_0011  0x03    3    
  163   :  0110_1110  0x6E  110  n  
  164   :  0111_0011  0x73  115  s  
  165   :  0011_0010  0x32   50  2  
  166   :  1100_0000  0xC0  192    
  167   :  0001_0100  0x14   20    
  168   :  1100_0000  0xC0  192    
  169   :  0001_0100  0x14   20    
  170   :  0000_0000  0x00    0    
  171   :  0000_0010  0x02    2    
  172   :  0000_0000  0x00    0    
  173   :  0000_0001  0x01    1    
  174   :  0000_0000  0x00    0    
  175   :  0000_0000  0x00    0    
  176   :  0010_1010  0x2A   42  *  
  177   :  0011_0000  0x30   48  0  
  178   :  0000_0000  0x00    0    
  179   :  0000_0010  0x02    2    
  180   :  1100_0000  0xC0  192    
  181   :  0001_0100  0x14   20    
  182   :  1100_0000  0xC0  192    
  183   :  1000_1100  0x8C  140    
  184   :  0000_0000  0x00    0    
  185   :  0000_0001  0x01    1    
  186   :  0000_0000  0x00    0    
  187   :  0000_0001  0x01    1    
  188   :  0000_0000  0x00    0    
  189   :  0000_0000  0x00    0    
  190   :  0010_1010  0x2A   42  *  
  191   :  0011_0000  0x30   48  0  
  192   :  0000_0000  0x00    0    
  193   :  0000_0100  0x04    4    
  194   :  0000_1100  0x0C   12    
  195   :  0010_0010  0x22   34  "  
  196   :  0011_1000  0x38   56  8  
  197   :  0100_1110  0x4E   78  N  
  198   :  1100_0000  0xC0  192    
  199   :  1010_0010  0xA2  162    
  200   :  0000_0000  0x00    0    
  201   :  0000_0001  0x01    1    
  202   :  0000_0000  0x00    0    
  203   :  0000_0001  0x01    1    
  204   :  0000_0000  0x00    0    
  205   :  0000_0000  0x00    0    
  206   :  0010_1010  0x2A   42  *  
  207   :  0011_0000  0x30   48  0  
  208   :  0000_0000  0x00    0    
  209   :  0000_0100  0x04    4    
  210   :  0100_1100  0x4C   76  L  
  211   :  0011_0110  0x36   54  6  
  212   :  0010_0000  0x20   32     
  213   :  0000_1010  0x0A   10    
  214   :  1100_0000  0xC0  192    
  215   :  0001_0100  0x14   20    
  216   :  0000_0000  0x00    0    
  217   :  0000_0001  0x01    1    
  218   :  0000_0000  0x00    0    
  219   :  0000_0001  0x01    1    
  220   :  0000_0000  0x00    0    
  221   :  0000_0000  0x00    0    
  222   :  0010_1010  0x2A   42  *  
  223   :  0011_0000  0x30   48  0  
  224   :  0000_0000  0x00    0    
  225   :  0000_0100  0x04    4    
  226   :  1100_0000  0xC0  192    
  227   :  1010_1000  0xA8  168    
  228   :  0110_0011  0x63   99  c  
  229   :  0110_0100  0x64  100  d  
|;
chk_exp(\$response,\$exptext);    

## test 78	check known numeric ANY records
$len = newhead(\$buffer,
	12345,
	BITS_QUERY,	# opcode
	1,0,0,0,	# one question
);
$len = $put->Question(\$buffer,$len,'1.2.3.4.bar.com',T_ANY,C_IN);
($rv,$response) = dialog($buffer,$len);

#print_head(\$response);
#print_buf(\$buffer);
#print_buf(\$response);

$exptext = q|
  0     :  0011_0000  0x30   48  0  
  1     :  0011_1001  0x39   57  9  
  2     :  1000_0100  0x84  132    
  3     :  0000_0000  0x00    0    
  4     :  0000_0000  0x00    0    
  5     :  0000_0001  0x01    1    
  6     :  0000_0000  0x00    0    
  7     :  0000_0010  0x02    2    
  8     :  0000_0000  0x00    0    
  9     :  0000_0011  0x03    3    
  10    :  0000_0000  0x00    0    
  11    :  0000_0011  0x03    3    
  12    :  0000_0001  0x01    1    
  13    :  0011_0001  0x31   49  1  
  14    :  0000_0001  0x01    1    
  15    :  0011_0010  0x32   50  2  
  16    :  0000_0001  0x01    1    
  17    :  0011_0011  0x33   51  3  
  18    :  0000_0001  0x01    1    
  19    :  0011_0100  0x34   52  4  
  20    :  0000_0011  0x03    3    
  21    :  0110_0010  0x62   98  b  
  22    :  0110_0001  0x61   97  a  
  23    :  0111_0010  0x72  114  r  
  24    :  0000_0011  0x03    3    
  25    :  0110_0011  0x63   99  c  
  26    :  0110_1111  0x6F  111  o  
  27    :  0110_1101  0x6D  109  m  
  28    :  0000_0000  0x00    0    
  29    :  0000_0000  0x00    0    
  30    :  1111_1111  0xFF  255    
  31    :  0000_0000  0x00    0    
  32    :  0000_0001  0x01    1    
  33    :  1100_0000  0xC0  192    
  34    :  0000_1100  0x0C   12    
  35    :  0000_0000  0x00    0    
  36    :  0000_0001  0x01    1    
  37    :  0000_0000  0x00    0    
  38    :  0000_0001  0x01    1    
  39    :  0000_0000  0x00    0    
  40    :  0000_0000  0x00    0    
  41    :  0010_1010  0x2A   42  *  
  42    :  0011_0000  0x30   48  0  
  43    :  0000_0000  0x00    0    
  44    :  0000_0100  0x04    4    
  45    :  0111_1111  0x7F  127    
  46    :  0000_0000  0x00    0    
  47    :  0000_0000  0x00    0    
  48    :  0000_0003  0x03    3    
  49    :  1100_0000  0xC0  192    
  50    :  0000_1100  0x0C   12    
  51    :  0000_0000  0x00    0    
  52    :  0001_0000  0x10   16    
  53    :  0000_0000  0x00    0    
  54    :  0000_0001  0x01    1    
  55    :  0000_0000  0x00    0    
  56    :  0000_0000  0x00    0    
  57    :  0010_1010  0x2A   42  *  
  58    :  0011_0000  0x30   48  0  
  59    :  0000_0000  0x00    0    
  60    :  0101_0011  0x53   83  S  
  61    :  0101_0010  0x52   82  R  
  62    :  0100_0101  0x45   69  E  
  63    :  0111_0010  0x72  114  r  
  64    :  0111_0010  0x72  114  r  
  65    :  0110_1111  0x6F  111  o  
  66    :  0111_0010  0x72  114  r  
  67    :  0011_1010  0x3A   58  :  
  68    :  0010_0000  0x20   32     
  69    :  0111_1001  0x79  121  y  
  70    :  0110_1111  0x6F  111  o  
  71    :  0111_0101  0x75  117  u  
  72    :  0111_0010  0x72  114  r  
  73    :  0010_0000  0x20   32     
  74    :  0110_1101  0x6D  109  m  
  75    :  0110_0001  0x61   97  a  
  76    :  0110_1001  0x69  105  i  
  77    :  0110_1100  0x6C  108  l  
  78    :  0010_0000  0x20   32     
  79    :  0111_0011  0x73  115  s  
  80    :  0110_0101  0x65  101  e  
  81    :  0111_0010  0x72  114  r  
  82    :  0111_0110  0x76  118  v  
  83    :  0110_0101  0x65  101  e  
  84    :  0111_0010  0x72  114  r  
  85    :  0010_0000  0x20   32     
  86    :  0110_1000  0x68  104  h  
  87    :  0110_0001  0x61   97  a  
  88    :  0111_0011  0x73  115  s  
  89    :  0010_0000  0x20   32     
  90    :  0110_0010  0x62   98  b  
  91    :  0110_0101  0x65  101  e  
  92    :  0110_0101  0x65  101  e  
  93    :  0110_1110  0x6E  110  n  
  94    :  0010_0000  0x20   32     
  95    :  0100_0010  0x42   66  B  
  96    :  0100_1100  0x4C   76  L  
  97    :  0100_0001  0x41   65  A  
  98    :  0100_0011  0x43   67  C  
  99    :  0100_1011  0x4B   75  K  
  100   :  0100_1000  0x48   72  H  
  101   :  0100_1111  0x4F   79  O  
  102   :  0100_1100  0x4C   76  L  
  103   :  0100_0101  0x45   69  E  
  104   :  0100_0100  0x44   68  D  
  105   :  0010_1110  0x2E   46  .  
  106   :  0010_0000  0x20   32     
  107   :  0101_0011  0x53   83  S  
  108   :  0110_0101  0x65  101  e  
  109   :  0110_0101  0x65  101  e  
  110   :  0010_0000  0x20   32     
  111   :  0110_1000  0x68  104  h  
  112   :  0111_0100  0x74  116  t  
  113   :  0111_0100  0x74  116  t  
  114   :  0111_0000  0x70  112  p  
  115   :  0011_1010  0x3A   58  :  
  116   :  0010_1111  0x2F   47  /  
  117   :  0010_1111  0x2F   47  /  
  118   :  0110_0010  0x62   98  b  
  119   :  0110_1100  0x6C  108  l  
  120   :  0110_0001  0x61   97  a  
  121   :  0110_0011  0x63   99  c  
  122   :  0110_1011  0x6B  107  k  
  123   :  0110_1000  0x68  104  h  
  124   :  0110_1111  0x6F  111  o  
  125   :  0110_1100  0x6C  108  l  
  126   :  0110_0101  0x65  101  e  
  127   :  0010_1110  0x2E   46  .  
  128   :  0111_0011  0x73  115  s  
  129   :  0111_0000  0x70  112  p  
  130   :  0110_0001  0x61   97  a  
  131   :  0110_1101  0x6D  109  m  
  132   :  0110_0011  0x63   99  c  
  133   :  0110_0001  0x61   97  a  
  134   :  0110_1110  0x6E  110  n  
  135   :  0110_1110  0x6E  110  n  
  136   :  0110_1001  0x69  105  i  
  137   :  0110_0010  0x62   98  b  
  138   :  0110_0001  0x61   97  a  
  139   :  0110_1100  0x6C  108  l  
  140   :  0010_1110  0x2E   46  .  
  141   :  0110_0011  0x63   99  c  
  142   :  0110_1111  0x6F  111  o  
  143   :  0110_1101  0x6D  109  m  
  144   :  1100_0000  0xC0  192    
  145   :  0001_0100  0x14   20    
  146   :  0000_0000  0x00    0    
  147   :  0000_0010  0x02    2    
  148   :  0000_0000  0x00    0    
  149   :  0000_0001  0x01    1    
  150   :  0000_0000  0x00    0    
  151   :  0000_0000  0x00    0    
  152   :  0010_1010  0x2A   42  *  
  153   :  0011_0000  0x30   48  0  
  154   :  0000_0000  0x00    0    
  155   :  0000_1010  0x0A   10    
  156   :  0000_0011  0x03    3    
  157   :  0110_1110  0x6E  110  n  
  158   :  0111_0011  0x73  115  s  
  159   :  0011_0001  0x31   49  1  
  160   :  0000_0011  0x03    3    
  161   :  0111_1000  0x78  120  x  
  162   :  0111_1001  0x79  121  y  
  163   :  0111_1010  0x7A  122  z  
  164   :  1100_0000  0xC0  192    
  165   :  0001_1000  0x18   24    
  166   :  1100_0000  0xC0  192    
  167   :  0001_0100  0x14   20    
  168   :  0000_0000  0x00    0    
  169   :  0000_0010  0x02    2    
  170   :  0000_0000  0x00    0    
  171   :  0000_0001  0x01    1    
  172   :  0000_0000  0x00    0    
  173   :  0000_0000  0x00    0    
  174   :  0010_1010  0x2A   42  *  
  175   :  0011_0000  0x30   48  0  
  176   :  0000_0000  0x00    0    
  177   :  0000_0110  0x06    6    
  178   :  0000_0011  0x03    3    
  179   :  0110_1110  0x6E  110  n  
  180   :  0111_0011  0x73  115  s  
  181   :  0011_0010  0x32   50  2  
  182   :  1100_0000  0xC0  192    
  183   :  0001_0100  0x14   20    
  184   :  1100_0000  0xC0  192    
  185   :  0001_0100  0x14   20    
  186   :  0000_0000  0x00    0    
  187   :  0000_0010  0x02    2    
  188   :  0000_0000  0x00    0    
  189   :  0000_0001  0x01    1    
  190   :  0000_0000  0x00    0    
  191   :  0000_0000  0x00    0    
  192   :  0010_1010  0x2A   42  *  
  193   :  0011_0000  0x30   48  0  
  194   :  0000_0000  0x00    0    
  195   :  0000_0010  0x02    2    
  196   :  1100_0000  0xC0  192    
  197   :  0001_0100  0x14   20    
  198   :  1100_0000  0xC0  192    
  199   :  1001_1100  0x9C  156    
  200   :  0000_0000  0x00    0    
  201   :  0000_0001  0x01    1    
  202   :  0000_0000  0x00    0    
  203   :  0000_0001  0x01    1    
  204   :  0000_0000  0x00    0    
  205   :  0000_0000  0x00    0    
  206   :  0010_1010  0x2A   42  *  
  207   :  0011_0000  0x30   48  0  
  208   :  0000_0000  0x00    0    
  209   :  0000_0100  0x04    4    
  210   :  0000_1100  0x0C   12    
  211   :  0010_0010  0x22   34  "  
  212   :  0011_1000  0x38   56  8  
  213   :  0100_1110  0x4E   78  N  
  214   :  1100_0000  0xC0  192    
  215   :  1011_0010  0xB2  178    
  216   :  0000_0000  0x00    0    
  217   :  0000_0001  0x01    1    
  218   :  0000_0000  0x00    0    
  219   :  0000_0001  0x01    1    
  220   :  0000_0000  0x00    0    
  221   :  0000_0000  0x00    0    
  222   :  0010_1010  0x2A   42  *  
  223   :  0011_0000  0x30   48  0  
  224   :  0000_0000  0x00    0    
  225   :  0000_0100  0x04    4    
  226   :  0100_1100  0x4C   76  L  
  227   :  0011_0110  0x36   54  6  
  228   :  0010_0000  0x20   32     
  229   :  0000_1010  0x0A   10    
  230   :  1100_0000  0xC0  192    
  231   :  0001_0100  0x14   20    
  232   :  0000_0000  0x00    0    
  233   :  0000_0001  0x01    1    
  234   :  0000_0000  0x00    0    
  235   :  0000_0001  0x01    1    
  236   :  0000_0000  0x00    0    
  237   :  0000_0000  0x00    0    
  238   :  0010_1010  0x2A   42  *  
  239   :  0011_0000  0x30   48  0  
  240   :  0000_0000  0x00    0    
  241   :  0000_0100  0x04    4    
  242   :  1100_0000  0xC0  192    
  243   :  1010_1000  0xA8  168    
  244   :  0110_0011  0x63   99  c  
  245   :  0110_0100  0x64  100  d  
|;
chk_exp(\$response,\$exptext);    

## test 79	check invalid numeric record
$len = newhead(\$buffer,
	12345,
	BITS_QUERY,	# opcode
	1,0,0,0,	# one question
);
$len = $put->Question(\$buffer,$len,'1.2.3.bar.com',T_ANY,C_IN);
($rv,$response) = dialog($buffer,$len);

#print_head(\$response);
#print_buf(\$buffer);
#print_buf(\$response);

$exptext = q|
  0     :  0011_0000  0x30   48  0  
  1     :  0011_1001  0x39   57  9  
  2     :  1000_0100  0x84  132    
  3     :  0000_0000  0x00    0    
  4     :  0000_0000  0x00    0    
  5     :  0000_0001  0x01    1    
  6     :  0000_0000  0x00    0    
  7     :  0000_0000  0x00    0    
  8     :  0000_0000  0x00    0    
  9     :  0000_0001  0x01    1    
  10    :  0000_0000  0x00    0    
  11    :  0000_0000  0x00    0    
  12    :  0000_0001  0x01    1    
  13    :  0011_0001  0x31   49  1  
  14    :  0000_0001  0x01    1    
  15    :  0011_0010  0x32   50  2  
  16    :  0000_0001  0x01    1    
  17    :  0011_0011  0x33   51  3  
  18    :  0000_0011  0x03    3    
  19    :  0110_0010  0x62   98  b  
  20    :  0110_0001  0x61   97  a  
  21    :  0111_0010  0x72  114  r  
  22    :  0000_0011  0x03    3    
  23    :  0110_0011  0x63   99  c  
  24    :  0110_1111  0x6F  111  o  
  25    :  0110_1101  0x6D  109  m  
  26    :  0000_0000  0x00    0    
  27    :  0000_0000  0x00    0    
  28    :  1111_1111  0xFF  255    
  29    :  0000_0000  0x00    0    
  30    :  0000_0001  0x01    1    
  31    :  1100_0000  0xC0  192    
  32    :  0001_0010  0x12   18    
  33    :  0000_0000  0x00    0    
  34    :  0000_0110  0x06    6    
  35    :  0000_0000  0x00    0    
  36    :  0000_0001  0x01    1    
  37    :  0000_0000  0x00    0    
  38    :  0000_0000  0x00    0    
  39    :  0000_0000  0x00    0    
  40    :  0000_0000  0x00    0    
  41    :  0000_0000  0x00    0    
  42    :  0010_1000  0x28   40  (  
  43    :  0000_1001  0x09    9    
  44    :  0110_1100  0x6C  108  l  
  45    :  0110_1111  0x6F  111  o  
  46    :  0110_0011  0x63   99  c  
  47    :  0110_0001  0x61   97  a  
  48    :  0110_1100  0x6C  108  l  
  49    :  0110_1000  0x68  104  h  
  50    :  0110_1111  0x6F  111  o  
  51    :  0111_0011  0x73  115  s  
  52    :  0111_0100  0x74  116  t  
  53    :  1100_0000  0xC0  192    
  54    :  0001_0010  0x12   18    
  55    :  0000_0101  0x05    5    
  56    :  0110_1000  0x68  104  h  
  57    :  0111_0101  0x75  117  u  
  58    :  0110_1101  0x6D  109  m  
  59    :  0110_0001  0x61   97  a  
  60    :  0110_1110  0x6E  110  n  
  61    :  1100_0000  0xC0  192    
  62    :  0001_0010  0x12   18    
  63    :  0000_0111  0x07    7    
  64    :  0101_1011  0x5B   91  [  
  65    :  1100_0011  0xC3  195    
  66    :  0111_0001  0x71  113  q  
  67    :  0000_0000  0x00    0    
  68    :  0000_0000  0x00    0    
  69    :  1010_1000  0xA8  168    
  70    :  1100_0000  0xC0  192    
  71    :  0000_0000  0x00    0    
  72    :  0000_0000  0x00    0    
  73    :  0000_1110  0x0E   14    
  74    :  0001_0000  0x10   16    
  75    :  0000_0000  0x00    0    
  76    :  0000_0001  0x01    1    
  77    :  0101_0001  0x51   81  Q  
  78    :  1000_0000  0x80  128    
  79    :  0000_0000  0x00    0    
  80    :  0000_0000  0x00    0    
  81    :  0010_1010  0x2A   42  *  
  82    :  0011_0000  0x30   48  0  
|;
chk_exp(\$response,\$exptext);    

## test 80	insert alternate text record
print "failed to set known IP 4.3.2.1 in database\nnot "
	if $ipt->put('rblcontrib',inet_aton("4.3.2.1"),inet_aton('127.0.0.2')."\0Alternate Error: from another RBL\0");
&ok();

## test 81	check ANY records with dbtext present
# enable promiscious reporting
&{"${TCTEST}::t_cmdline"}('P',1);
$len = newhead(\$buffer,
	12345,
	BITS_QUERY,	# opcode
	1,0,0,0,	# one question
);
$len = $put->Question(\$buffer,$len,'1.2.3.4.bar.com',T_ANY,C_IN);
($rv,$response) = dialog($buffer,$len);

#print_head(\$response);
#print_buf(\$buffer);
#print_buf(\$response);

$exptext = q|
  0     :  0011_0000  0x30   48  0  
  1     :  0011_1001  0x39   57  9  
  2     :  1000_0100  0x84  132    
  3     :  0000_0000  0x00    0    
  4     :  0000_0000  0x00    0    
  5     :  0000_0001  0x01    1    
  6     :  0000_0000  0x00    0    
  7     :  0000_0010  0x02    2    
  8     :  0000_0000  0x00    0    
  9     :  0000_0011  0x03    3    
  10    :  0000_0000  0x00    0    
  11    :  0000_0011  0x03    3    
  12    :  0000_0001  0x01    1    
  13    :  0011_0001  0x31   49  1  
  14    :  0000_0001  0x01    1    
  15    :  0011_0010  0x32   50  2  
  16    :  0000_0001  0x01    1    
  17    :  0011_0011  0x33   51  3  
  18    :  0000_0001  0x01    1    
  19    :  0011_0100  0x34   52  4  
  20    :  0000_0011  0x03    3    
  21    :  0110_0010  0x62   98  b  
  22    :  0110_0001  0x61   97  a  
  23    :  0111_0010  0x72  114  r  
  24    :  0000_0011  0x03    3    
  25    :  0110_0011  0x63   99  c  
  26    :  0110_1111  0x6F  111  o  
  27    :  0110_1101  0x6D  109  m  
  28    :  0000_0000  0x00    0    
  29    :  0000_0000  0x00    0    
  30    :  1111_1111  0xFF  255    
  31    :  0000_0000  0x00    0    
  32    :  0000_0001  0x01    1    
  33    :  1100_0000  0xC0  192    
  34    :  0000_1100  0x0C   12    
  35    :  0000_0000  0x00    0    
  36    :  0000_0001  0x01    1    
  37    :  0000_0000  0x00    0    
  38    :  0000_0001  0x01    1    
  39    :  0000_0000  0x00    0    
  40    :  0000_0000  0x00    0    
  41    :  0010_1010  0x2A   42  *  
  42    :  0011_0000  0x30   48  0  
  43    :  0000_0000  0x00    0    
  44    :  0000_0100  0x04    4    
  45    :  0111_1111  0x7F  127    
  46    :  0000_0000  0x00    0    
  47    :  0000_0000  0x00    0    
  48    :  0000_0010  0x02    2    
  49    :  1100_0000  0xC0  192    
  50    :  0000_1100  0x0C   12    
  51    :  0000_0000  0x00    0    
  52    :  0001_0000  0x10   16    
  53    :  0000_0000  0x00    0    
  54    :  0000_0001  0x01    1    
  55    :  0000_0000  0x00    0    
  56    :  0000_0000  0x00    0    
  57    :  0010_1010  0x2A   42  *  
  58    :  0011_0000  0x30   48  0  
  59    :  0000_0000  0x00    0    
  60    :  0010_0010  0x22   34  "  
  61    :  0010_0001  0x21   33  !  
  62    :  0100_0001  0x41   65  A  
  63    :  0110_1100  0x6C  108  l  
  64    :  0111_0100  0x74  116  t  
  65    :  0110_0101  0x65  101  e  
  66    :  0111_0010  0x72  114  r  
  67    :  0110_1110  0x6E  110  n  
  68    :  0110_0001  0x61   97  a  
  69    :  0111_0100  0x74  116  t  
  70    :  0110_0101  0x65  101  e  
  71    :  0010_0000  0x20   32     
  72    :  0100_0101  0x45   69  E  
  73    :  0111_0010  0x72  114  r  
  74    :  0111_0010  0x72  114  r  
  75    :  0110_1111  0x6F  111  o  
  76    :  0111_0010  0x72  114  r  
  77    :  0011_1010  0x3A   58  :  
  78    :  0010_0000  0x20   32     
  79    :  0110_0110  0x66  102  f  
  80    :  0111_0010  0x72  114  r  
  81    :  0110_1111  0x6F  111  o  
  82    :  0110_1101  0x6D  109  m  
  83    :  0010_0000  0x20   32     
  84    :  0110_0001  0x61   97  a  
  85    :  0110_1110  0x6E  110  n  
  86    :  0110_1111  0x6F  111  o  
  87    :  0111_0100  0x74  116  t  
  88    :  0110_1000  0x68  104  h  
  89    :  0110_0101  0x65  101  e  
  90    :  0111_0010  0x72  114  r  
  91    :  0010_0000  0x20   32     
  92    :  0101_0010  0x52   82  R  
  93    :  0100_0010  0x42   66  B  
  94    :  0100_1100  0x4C   76  L  
  95    :  1100_0000  0xC0  192    
  96    :  0001_0100  0x14   20    
  97    :  0000_0000  0x00    0    
  98    :  0000_0010  0x02    2    
  99    :  0000_0000  0x00    0    
  100   :  0000_0001  0x01    1    
  101   :  0000_0000  0x00    0    
  102   :  0000_0000  0x00    0    
  103   :  0010_1010  0x2A   42  *  
  104   :  0011_0000  0x30   48  0  
  105   :  0000_0000  0x00    0    
  106   :  0000_1010  0x0A   10    
  107   :  0000_0011  0x03    3    
  108   :  0110_1110  0x6E  110  n  
  109   :  0111_0011  0x73  115  s  
  110   :  0011_0001  0x31   49  1  
  111   :  0000_0011  0x03    3    
  112   :  0111_1000  0x78  120  x  
  113   :  0111_1001  0x79  121  y  
  114   :  0111_1010  0x7A  122  z  
  115   :  1100_0000  0xC0  192    
  116   :  0001_1000  0x18   24    
  117   :  1100_0000  0xC0  192    
  118   :  0001_0100  0x14   20    
  119   :  0000_0000  0x00    0    
  120   :  0000_0010  0x02    2    
  121   :  0000_0000  0x00    0    
  122   :  0000_0001  0x01    1    
  123   :  0000_0000  0x00    0    
  124   :  0000_0000  0x00    0    
  125   :  0010_1010  0x2A   42  *  
  126   :  0011_0000  0x30   48  0  
  127   :  0000_0000  0x00    0    
  128   :  0000_0110  0x06    6    
  129   :  0000_0011  0x03    3    
  130   :  0110_1110  0x6E  110  n  
  131   :  0111_0011  0x73  115  s  
  132   :  0011_0010  0x32   50  2  
  133   :  1100_0000  0xC0  192    
  134   :  0001_0100  0x14   20    
  135   :  1100_0000  0xC0  192    
  136   :  0001_0100  0x14   20    
  137   :  0000_0000  0x00    0    
  138   :  0000_0010  0x02    2    
  139   :  0000_0000  0x00    0    
  140   :  0000_0001  0x01    1    
  141   :  0000_0000  0x00    0    
  142   :  0000_0000  0x00    0    
  143   :  0010_1010  0x2A   42  *  
  144   :  0011_0000  0x30   48  0  
  145   :  0000_0000  0x00    0    
  146   :  0000_0010  0x02    2    
  147   :  1100_0000  0xC0  192    
  148   :  0001_0100  0x14   20    
  149   :  1100_0000  0xC0  192    
  150   :  0110_1011  0x6B  107  k  
  151   :  0000_0000  0x00    0    
  152   :  0000_0001  0x01    1    
  153   :  0000_0000  0x00    0    
  154   :  0000_0001  0x01    1    
  155   :  0000_0000  0x00    0    
  156   :  0000_0000  0x00    0    
  157   :  0010_1010  0x2A   42  *  
  158   :  0011_0000  0x30   48  0  
  159   :  0000_0000  0x00    0    
  160   :  0000_0100  0x04    4    
  161   :  0000_1100  0x0C   12    
  162   :  0010_0010  0x22   34  "  
  163   :  0011_1000  0x38   56  8  
  164   :  0100_1110  0x4E   78  N  
  165   :  1100_0000  0xC0  192    
  166   :  1000_0001  0x81  129    
  167   :  0000_0000  0x00    0    
  168   :  0000_0001  0x01    1    
  169   :  0000_0000  0x00    0    
  170   :  0000_0001  0x01    1    
  171   :  0000_0000  0x00    0    
  172   :  0000_0000  0x00    0    
  173   :  0010_1010  0x2A   42  *  
  174   :  0011_0000  0x30   48  0  
  175   :  0000_0000  0x00    0    
  176   :  0000_0100  0x04    4    
  177   :  0100_1100  0x4C   76  L  
  178   :  0011_0110  0x36   54  6  
  179   :  0010_0000  0x20   32     
  180   :  0000_1010  0x0A   10    
  181   :  1100_0000  0xC0  192    
  182   :  0001_0100  0x14   20    
  183   :  0000_0000  0x00    0    
  184   :  0000_0001  0x01    1    
  185   :  0000_0000  0x00    0    
  186   :  0000_0001  0x01    1    
  187   :  0000_0000  0x00    0    
  188   :  0000_0000  0x00    0    
  189   :  0010_1010  0x2A   42  *  
  190   :  0011_0000  0x30   48  0  
  191   :  0000_0000  0x00    0    
  192   :  0000_0100  0x04    4    
  193   :  1100_0000  0xC0  192    
  194   :  1010_1000  0xA8  168    
  195   :  0110_0011  0x63   99  c  
  196   :  0110_0100  0x64  100  d  
|;
chk_exp(\$response,\$exptext);    

##################################################################
## Everything checked except zone transfer and TCP mode stuff
##################################################################

## test 82,	repeat 76 but with 127.0.0.2 response
##		check known numeric A record using tcp mode
$len = newhead(\$buffer,
	12345,
	BITS_QUERY,	# opcode
	1,0,0,0,	# one question
);
$len = $put->Question(\$buffer,$len,'1.2.3.4.bar.com',T_A,C_IN);
($rv,$response) = dialog($buffer,$len,0,1);	# read, +tcp

#print_head(\$response);
#print_buf(\$buffer);
#print_buf(\$response);

$exptext = q|
  0     :  0011_0000  0x30   48  0  
  1     :  0011_1001  0x39   57  9  
  2     :  1000_0100  0x84  132    
  3     :  0000_0000  0x00    0    
  4     :  0000_0000  0x00    0    
  5     :  0000_0001  0x01    1    
  6     :  0000_0000  0x00    0    
  7     :  0000_0001  0x01    1    
  8     :  0000_0000  0x00    0    
  9     :  0000_0011  0x03    3    
  10    :  0000_0000  0x00    0    
  11    :  0000_0011  0x03    3    
  12    :  0000_0001  0x01    1    
  13    :  0011_0001  0x31   49  1  
  14    :  0000_0001  0x01    1    
  15    :  0011_0010  0x32   50  2  
  16    :  0000_0001  0x01    1    
  17    :  0011_0011  0x33   51  3  
  18    :  0000_0001  0x01    1    
  19    :  0011_0100  0x34   52  4  
  20    :  0000_0011  0x03    3    
  21    :  0110_0010  0x62   98  b  
  22    :  0110_0001  0x61   97  a  
  23    :  0111_0010  0x72  114  r  
  24    :  0000_0011  0x03    3    
  25    :  0110_0011  0x63   99  c  
  26    :  0110_1111  0x6F  111  o  
  27    :  0110_1101  0x6D  109  m  
  28    :  0000_0000  0x00    0    
  29    :  0000_0000  0x00    0    
  30    :  0000_0001  0x01    1    
  31    :  0000_0000  0x00    0    
  32    :  0000_0001  0x01    1    
  33    :  1100_0000  0xC0  192    
  34    :  0000_1100  0x0C   12    
  35    :  0000_0000  0x00    0    
  36    :  0000_0001  0x01    1    
  37    :  0000_0000  0x00    0    
  38    :  0000_0001  0x01    1    
  39    :  0000_0000  0x00    0    
  40    :  0000_0000  0x00    0    
  41    :  0010_1010  0x2A   42  *  
  42    :  0011_0000  0x30   48  0  
  43    :  0000_0000  0x00    0    
  44    :  0000_0100  0x04    4    
  45    :  0111_1111  0x7F  127    
  46    :  0000_0000  0x00    0    
  47    :  0000_0000  0x00    0    
  48    :  0000_0001  0x01    2    
  49    :  1100_0000  0xC0  192    
  50    :  0001_0100  0x14   20    
  51    :  0000_0000  0x00    0    
  52    :  0000_0010  0x02    2    
  53    :  0000_0000  0x00    0    
  54    :  0000_0001  0x01    1    
  55    :  0000_0000  0x00    0    
  56    :  0000_0000  0x00    0    
  57    :  0010_1010  0x2A   42  *  
  58    :  0011_0000  0x30   48  0  
  59    :  0000_0000  0x00    0    
  60    :  0000_1010  0x0A   10    
  61    :  0000_0011  0x03    3    
  62    :  0110_1110  0x6E  110  n  
  63    :  0111_0011  0x73  115  s  
  64    :  0011_0001  0x31   49  1  
  65    :  0000_0011  0x03    3    
  66    :  0111_1000  0x78  120  x  
  67    :  0111_1001  0x79  121  y  
  68    :  0111_1010  0x7A  122  z  
  69    :  1100_0000  0xC0  192    
  70    :  0001_1000  0x18   24    
  71    :  1100_0000  0xC0  192    
  72    :  0001_0100  0x14   20    
  73    :  0000_0000  0x00    0    
  74    :  0000_0010  0x02    2    
  75    :  0000_0000  0x00    0    
  76    :  0000_0001  0x01    1    
  77    :  0000_0000  0x00    0    
  78    :  0000_0000  0x00    0    
  79    :  0010_1010  0x2A   42  *  
  80    :  0011_0000  0x30   48  0  
  81    :  0000_0000  0x00    0    
  82    :  0000_0110  0x06    6    
  83    :  0000_0011  0x03    3    
  84    :  0110_1110  0x6E  110  n  
  85    :  0111_0011  0x73  115  s  
  86    :  0011_0010  0x32   50  2  
  87    :  1100_0000  0xC0  192    
  88    :  0001_0100  0x14   20    
  89    :  1100_0000  0xC0  192    
  90    :  0001_0100  0x14   20    
  91    :  0000_0000  0x00    0    
  92    :  0000_0010  0x02    2    
  93    :  0000_0000  0x00    0    
  94    :  0000_0001  0x01    1    
  95    :  0000_0000  0x00    0    
  96    :  0000_0000  0x00    0    
  97    :  0010_1010  0x2A   42  *  
  98    :  0011_0000  0x30   48  0  
  99    :  0000_0000  0x00    0    
  100   :  0000_0010  0x02    2    
  101   :  1100_0000  0xC0  192    
  102   :  0001_0100  0x14   20    
  103   :  1100_0000  0xC0  192    
  104   :  0011_1101  0x3D   61  =  
  105   :  0000_0000  0x00    0    
  106   :  0000_0001  0x01    1    
  107   :  0000_0000  0x00    0    
  108   :  0000_0001  0x01    1    
  109   :  0000_0000  0x00    0    
  110   :  0000_0000  0x00    0    
  111   :  0010_1010  0x2A   42  *  
  112   :  0011_0000  0x30   48  0  
  113   :  0000_0000  0x00    0    
  114   :  0000_0100  0x04    4    
  115   :  0000_1100  0x0C   12    
  116   :  0010_0010  0x22   34  "  
  117   :  0011_1000  0x38   56  8  
  118   :  0100_1110  0x4E   78  N  
  119   :  1100_0000  0xC0  192    
  120   :  0101_0011  0x53   83  S  
  121   :  0000_0000  0x00    0    
  122   :  0000_0001  0x01    1    
  123   :  0000_0000  0x00    0    
  124   :  0000_0001  0x01    1    
  125   :  0000_0000  0x00    0    
  126   :  0000_0000  0x00    0    
  127   :  0010_1010  0x2A   42  *  
  128   :  0011_0000  0x30   48  0  
  129   :  0000_0000  0x00    0    
  130   :  0000_0100  0x04    4    
  131   :  0100_1100  0x4C   76  L  
  132   :  0011_0110  0x36   54  6  
  133   :  0010_0000  0x20   32     
  134   :  0000_1010  0x0A   10    
  135   :  1100_0000  0xC0  192    
  136   :  0001_0100  0x14   20    
  137   :  0000_0000  0x00    0    
  138   :  0000_0001  0x01    1    
  139   :  0000_0000  0x00    0    
  140   :  0000_0001  0x01    1    
  141   :  0000_0000  0x00    0    
  142   :  0000_0000  0x00    0    
  143   :  0010_1010  0x2A   42  *  
  144   :  0011_0000  0x30   48  0  
  145   :  0000_0000  0x00    0    
  146   :  0000_0100  0x04    4    
  147   :  1100_0000  0xC0  192    
  148   :  1010_1000  0xA8  168    
  149   :  0110_0011  0x63   99  c  
  150   :  0110_0100  0x64  100  d  
|;
chk_exp(\$response,\$exptext);    

################################################################
# begin zone transfer testing
################################################################

## NOTES: on $istcp and $tcpmode
# Setting $istcp true forces TCP mode in the ns.c
# $istcp is used as a counter by "dialog", above, to
# determine how many buffers to collect before returning.
# Get it wrong and the routine will fail
#
# $tcpmode tells ns.c how to process the requests (TCP or UDP)
# and specifically how to process AXFR requests so we can test
# all of the program branches.
#
# tcpmode  = 0	use UDP
# tcpmode  = 1	use TCP, AXFR in one message if possible
# tcpmode  = 2	use TCP, AXFR in two messages. The first message contains
#		all overhead records, SOA, NS, MX and local host stuff
#		The second message contains all numeric A & TXT records
#		or as many as will fit.
# tcpmode >= 3	The first record is the same as tcpmode 2. Each additional
#		record contains an A + TXT record pair for a particular
#		numeric record, with the last record containing only the SOA

## test 83	insert another known IP in database
print "failed to set known IP 86.87.88.89 in database\nnot "
	if $ipt->put('tarpit',inet_aton("86.87.88.89"),123455555);
&ok();

## test 84-87
##		check known numeric A record using tcp mode
$len = newhead(\$buffer,
	12345,
	BITS_QUERY,	# opcode
	1,0,0,0,	# one question
);
$len = $put->Question(\$buffer,$len,'bar.com',T_AXFR,C_IN);
#print_buf(\$buffer);
my $istcp = 4;		# expect 4 packets
my $tcpmode = 3;
($rv,my @response) = dialog($buffer,$len,0,$istcp,$tcpmode);	# read, +tcp

#print_buf(\$response[0]); print "\n";
# test 84
$exptext = q|
  0     :  0011_0000  0x30   48  0  
  1     :  0011_1001  0x39   57  9  
  2     :  1000_0100  0x84  132    
  3     :  0000_0000  0x00    0    
  4     :  0000_0000  0x00    0    
  5     :  0000_0001  0x01    1    
  6     :  0000_0000  0x00    0    
  7     :  0000_1010  0x0A   10    
  8     :  0000_0000  0x00    0    
  9     :  0000_0000  0x00    0    
  10    :  0000_0000  0x00    0    
  11    :  0000_0000  0x00    0    
  12    :  0000_0011  0x03    3    
  13    :  0110_0010  0x62   98  b  
  14    :  0110_0001  0x61   97  a  
  15    :  0111_0010  0x72  114  r  
  16    :  0000_0011  0x03    3    
  17    :  0110_0011  0x63   99  c  
  18    :  0110_1111  0x6F  111  o  
  19    :  0110_1101  0x6D  109  m  
  20    :  0000_0000  0x00    0    
  21    :  0000_0000  0x00    0    
  22    :  1111_1100  0xFC  252    
  23    :  0000_0000  0x00    0    
  24    :  0000_0001  0x01    1    
  25    :  1100_0000  0xC0  192    
  26    :  0000_1100  0x0C   12    
  27    :  0000_0000  0x00    0    
  28    :  0000_0110  0x06    6    
  29    :  0000_0000  0x00    0    
  30    :  0000_0001  0x01    1    
  31    :  0000_0000  0x00    0    
  32    :  0000_0000  0x00    0    
  33    :  0000_0000  0x00    0    
  34    :  0000_0000  0x00    0    
  35    :  0000_0000  0x00    0    
  36    :  0010_1000  0x28   40  (  
  37    :  0000_1001  0x09    9    
  38    :  0110_1100  0x6C  108  l  
  39    :  0110_1111  0x6F  111  o  
  40    :  0110_0011  0x63   99  c  
  41    :  0110_0001  0x61   97  a  
  42    :  0110_1100  0x6C  108  l  
  43    :  0110_1000  0x68  104  h  
  44    :  0110_1111  0x6F  111  o  
  45    :  0111_0011  0x73  115  s  
  46    :  0111_0100  0x74  116  t  
  47    :  1100_0000  0xC0  192    
  48    :  0000_1100  0x0C   12    
  49    :  0000_0101  0x05    5    
  50    :  0110_1000  0x68  104  h  
  51    :  0111_0101  0x75  117  u  
  52    :  0110_1101  0x6D  109  m  
  53    :  0110_0001  0x61   97  a  
  54    :  0110_1110  0x6E  110  n  
  55    :  1100_0000  0xC0  192    
  56    :  0000_1100  0x0C   12    
  57    :  0000_0111  0x07    7    
  58    :  0101_1011  0x5B   91  [  
  59    :  1100_0011  0xC3  195    
  60    :  0111_0001  0x71  113  q  
  61    :  0000_0000  0x00    0    
  62    :  0000_0000  0x00    0    
  63    :  1010_1000  0xA8  168    
  64    :  1100_0000  0xC0  192    
  65    :  0000_0000  0x00    0    
  66    :  0000_0000  0x00    0    
  67    :  0000_1110  0x0E   14    
  68    :  0001_0000  0x10   16    
  69    :  0000_0000  0x00    0    
  70    :  0000_0001  0x01    1    
  71    :  0101_0001  0x51   81  Q  
  72    :  1000_0000  0x80  128    
  73    :  0000_0000  0x00    0    
  74    :  0000_0000  0x00    0    
  75    :  0010_1010  0x2A   42  *  
  76    :  0011_0000  0x30   48  0  
  77    :  1100_0000  0xC0  192    
  78    :  0000_1100  0x0C   12    
  79    :  0000_0000  0x00    0    
  80    :  0000_0010  0x02    2    
  81    :  0000_0000  0x00    0    
  82    :  0000_0001  0x01    1    
  83    :  0000_0000  0x00    0    
  84    :  0000_0000  0x00    0    
  85    :  0010_1010  0x2A   42  *  
  86    :  0011_0000  0x30   48  0  
  87    :  0000_0000  0x00    0    
  88    :  0000_1010  0x0A   10    
  89    :  0000_0011  0x03    3    
  90    :  0110_1110  0x6E  110  n  
  91    :  0111_0011  0x73  115  s  
  92    :  0011_0001  0x31   49  1  
  93    :  0000_0011  0x03    3    
  94    :  0111_1000  0x78  120  x  
  95    :  0111_1001  0x79  121  y  
  96    :  0111_1010  0x7A  122  z  
  97    :  1100_0000  0xC0  192    
  98    :  0001_0000  0x10   16    
  99    :  1100_0000  0xC0  192    
  100   :  0000_1100  0x0C   12    
  101   :  0000_0000  0x00    0    
  102   :  0000_0010  0x02    2    
  103   :  0000_0000  0x00    0    
  104   :  0000_0001  0x01    1    
  105   :  0000_0000  0x00    0    
  106   :  0000_0000  0x00    0    
  107   :  0010_1010  0x2A   42  *  
  108   :  0011_0000  0x30   48  0  
  109   :  0000_0000  0x00    0    
  110   :  0000_0110  0x06    6    
  111   :  0000_0011  0x03    3    
  112   :  0110_1110  0x6E  110  n  
  113   :  0111_0011  0x73  115  s  
  114   :  0011_0010  0x32   50  2  
  115   :  1100_0000  0xC0  192    
  116   :  0000_1100  0x0C   12    
  117   :  1100_0000  0xC0  192    
  118   :  0000_1100  0x0C   12    
  119   :  0000_0000  0x00    0    
  120   :  0000_0010  0x02    2    
  121   :  0000_0000  0x00    0    
  122   :  0000_0001  0x01    1    
  123   :  0000_0000  0x00    0    
  124   :  0000_0000  0x00    0    
  125   :  0010_1010  0x2A   42  *  
  126   :  0011_0000  0x30   48  0  
  127   :  0000_0000  0x00    0    
  128   :  0000_0010  0x02    2    
  129   :  1100_0000  0xC0  192    
  130   :  0000_1100  0x0C   12    
  131   :  1100_0000  0xC0  192    
  132   :  0000_1100  0x0C   12    
  133   :  0000_0000  0x00    0    
  134   :  0000_1111  0x0F   15    
  135   :  0000_0000  0x00    0    
  136   :  0000_0001  0x01    1    
  137   :  0000_0000  0x00    0    
  138   :  0000_0000  0x00    0    
  139   :  0010_1010  0x2A   42  *  
  140   :  0011_0000  0x30   48  0  
  141   :  0000_0000  0x00    0    
  142   :  0000_0100  0x04    4    
  143   :  0000_0000  0x00    0    
  144   :  0011_0010  0x32   50  2  
  145   :  1100_0000  0xC0  192    
  146   :  0000_1100  0x0C   12    
  147   :  1100_0000  0xC0  192    
  148   :  0000_1100  0x0C   12    
  149   :  0000_0000  0x00    0    
  150   :  0000_1111  0x0F   15    
  151   :  0000_0000  0x00    0    
  152   :  0000_0001  0x01    1    
  153   :  0000_0000  0x00    0    
  154   :  0000_0000  0x00    0    
  155   :  0010_1010  0x2A   42  *  
  156   :  0011_0000  0x30   48  0  
  157   :  0000_0000  0x00    0    
  158   :  0000_0111  0x07    7    
  159   :  0000_0000  0x00    0    
  160   :  0000_1010  0x0A   10    
  161   :  0000_0010  0x02    2    
  162   :  0110_1101  0x6D  109  m  
  163   :  0111_1000  0x78  120  x  
  164   :  1100_0000  0xC0  192    
  165   :  0000_1100  0x0C   12    
  166   :  1100_0000  0xC0  192    
  167   :  0110_1111  0x6F  111  o  
  168   :  0000_0000  0x00    0    
  169   :  0000_0001  0x01    1    
  170   :  0000_0000  0x00    0    
  171   :  0000_0001  0x01    1    
  172   :  0000_0000  0x00    0    
  173   :  0000_0000  0x00    0    
  174   :  0010_1010  0x2A   42  *  
  175   :  0011_0000  0x30   48  0  
  176   :  0000_0000  0x00    0    
  177   :  0000_0100  0x04    4    
  178   :  0100_1100  0x4C   76  L  
  179   :  0011_0110  0x36   54  6  
  180   :  0010_0000  0x20   32     
  181   :  0000_1010  0x0A   10    
  182   :  1100_0000  0xC0  192    
  183   :  0000_1100  0x0C   12    
  184   :  0000_0000  0x00    0    
  185   :  0000_0001  0x01    1    
  186   :  0000_0000  0x00    0    
  187   :  0000_0001  0x01    1    
  188   :  0000_0000  0x00    0    
  189   :  0000_0000  0x00    0    
  190   :  0010_1010  0x2A   42  *  
  191   :  0011_0000  0x30   48  0  
  192   :  0000_0000  0x00    0    
  193   :  0000_0100  0x04    4    
  194   :  0000_0001  0x01    1    
  195   :  0000_0010  0x02    2    
  196   :  0000_0011  0x03    3    
  197   :  0000_0100  0x04    4    
  198   :  1100_0000  0xC0  192    
  199   :  1010_0001  0xA1  161    
  200   :  0000_0000  0x00    0    
  201   :  0000_0001  0x01    1    
  202   :  0000_0000  0x00    0    
  203   :  0000_0001  0x01    1    
  204   :  0000_0000  0x00    0    
  205   :  0000_0000  0x00    0    
  206   :  0010_1010  0x2A   42  *  
  207   :  0011_0000  0x30   48  0  
  208   :  0000_0000  0x00    0    
  209   :  0000_0100  0x04    4    
  210   :  0110_0101  0x65  101  e  
  211   :  1100_1010  0xCA  202    
  212   :  0110_0111  0x67  103  g  
  213   :  0010_1100  0x2C   44  ,  
  214   :  1100_0000  0xC0  192    
  215   :  0000_1100  0x0C   12    
  216   :  0000_0000  0x00    0    
  217   :  0000_0001  0x01    1    
  218   :  0000_0000  0x00    0    
  219   :  0000_0001  0x01    1    
  220   :  0000_0000  0x00    0    
  221   :  0000_0000  0x00    0    
  222   :  0010_1010  0x2A   42  *  
  223   :  0011_0000  0x30   48  0  
  224   :  0000_0000  0x00    0    
  225   :  0000_0100  0x04    4    
  226   :  1100_0000  0xC0  192    
  227   :  1010_1000  0xA8  168    
  228   :  0110_0011  0x63   99  c  
  229   :  0110_0100  0x64  100  d  
|;
chk_exp(\$response[0],\$exptext);    

#print_buf(\$response[1]); print "\n";
# test 85
$exptext = q|
  0     :  0011_0000  0x30   48  0  
  1     :  0011_1001  0x39   57  9  
  2     :  1000_0100  0x84  132    
  3     :  0000_0000  0x00    0    
  4     :  0000_0000  0x00    0    
  5     :  0000_0000  0x00    0    
  6     :  0000_0000  0x00    0    
  7     :  0000_0010  0x02    2    
  8     :  0000_0000  0x00    0    
  9     :  0000_0000  0x00    0    
  10    :  0000_0000  0x00    0    
  11    :  0000_0000  0x00    0    
  12    :  0000_0001  0x01    1    
  13    :  0011_0001  0x31   49  1  
  14    :  0000_0001  0x01    1    
  15    :  0011_0010  0x32   50  2  
  16    :  0000_0001  0x01    1    
  17    :  0011_0011  0x33   51  3  
  18    :  0000_0001  0x01    1    
  19    :  0011_0100  0x34   52  4  
  20    :  0000_0011  0x03    3    
  21    :  0110_0010  0x62   98  b  
  22    :  0110_0001  0x61   97  a  
  23    :  0111_0010  0x72  114  r  
  24    :  0000_0011  0x03    3    
  25    :  0110_0011  0x63   99  c  
  26    :  0110_1111  0x6F  111  o  
  27    :  0110_1101  0x6D  109  m  
  28    :  0000_0000  0x00    0    
  29    :  0000_0000  0x00    0    
  30    :  0000_0001  0x01    1    
  31    :  0000_0000  0x00    0    
  32    :  0000_0001  0x01    1    
  33    :  0000_0000  0x00    0    
  34    :  0000_0000  0x00    0    
  35    :  0010_1010  0x2A   42  *  
  36    :  0011_0000  0x30   48  0  
  37    :  0000_0000  0x00    0    
  38    :  0000_0100  0x04    4    
  39    :  0111_1111  0x7F  127    
  40    :  0000_0000  0x00    0    
  41    :  0000_0000  0x00    0    
  42    :  0000_0010  0x02    2    
  43    :  1100_0000  0xC0  192    
  44    :  0000_1100  0x0C   12    
  45    :  0000_0000  0x00    0    
  46    :  0001_0000  0x10   16    
  47    :  0000_0000  0x00    0    
  48    :  0000_0001  0x01    1    
  49    :  0000_0000  0x00    0    
  50    :  0000_0000  0x00    0    
  51    :  0010_1010  0x2A   42  *  
  52    :  0011_0000  0x30   48  0  
  53    :  0000_0000  0x00    0    
  54    :  0010_0010  0x22   34  "  
  55    :  0010_0001  0x21   33  !  
  56    :  0100_0001  0x41   65  A  
  57    :  0110_1100  0x6C  108  l  
  58    :  0111_0100  0x74  116  t  
  59    :  0110_0101  0x65  101  e  
  60    :  0111_0010  0x72  114  r  
  61    :  0110_1110  0x6E  110  n  
  62    :  0110_0001  0x61   97  a  
  63    :  0111_0100  0x74  116  t  
  64    :  0110_0101  0x65  101  e  
  65    :  0010_0000  0x20   32     
  66    :  0100_0101  0x45   69  E  
  67    :  0111_0010  0x72  114  r  
  68    :  0111_0010  0x72  114  r  
  69    :  0110_1111  0x6F  111  o  
  70    :  0111_0010  0x72  114  r  
  71    :  0011_1010  0x3A   58  :  
  72    :  0010_0000  0x20   32     
  73    :  0110_0110  0x66  102  f  
  74    :  0111_0010  0x72  114  r  
  75    :  0110_1111  0x6F  111  o  
  76    :  0110_1101  0x6D  109  m  
  77    :  0010_0000  0x20   32     
  78    :  0110_0001  0x61   97  a  
  79    :  0110_1110  0x6E  110  n  
  80    :  0110_1111  0x6F  111  o  
  81    :  0111_0100  0x74  116  t  
  82    :  0110_1000  0x68  104  h  
  83    :  0110_0101  0x65  101  e  
  84    :  0111_0010  0x72  114  r  
  85    :  0010_0000  0x20   32     
  86    :  0101_0010  0x52   82  R  
  87    :  0100_0010  0x42   66  B  
  88    :  0100_1100  0x4C   76  L  
|;
chk_exp(\$response[1],\$exptext); 

#print_buf(\$response[2]); print "\n";
# test 86
$exptext = q|
  0     :  0011_0000  0x30   48  0  
  1     :  0011_1001  0x39   57  9  
  2     :  1000_0100  0x84  132    
  3     :  0000_0000  0x00    0    
  4     :  0000_0000  0x00    0    
  5     :  0000_0000  0x00    0    
  6     :  0000_0000  0x00    0    
  7     :  0000_0010  0x02    2    
  8     :  0000_0000  0x00    0    
  9     :  0000_0000  0x00    0    
  10    :  0000_0000  0x00    0    
  11    :  0000_0000  0x00    0    
  12    :  0000_0010  0x02    2    
  13    :  0011_1000  0x38   56  8  
  14    :  0011_1001  0x39   57  9  
  15    :  0000_0010  0x02    2    
  16    :  0011_1000  0x38   56  8  
  17    :  0011_1000  0x38   56  8  
  18    :  0000_0010  0x02    2    
  19    :  0011_1000  0x38   56  8  
  20    :  0011_0111  0x37   55  7  
  21    :  0000_0010  0x02    2    
  22    :  0011_1000  0x38   56  8  
  23    :  0011_0110  0x36   54  6  
  24    :  0000_0011  0x03    3    
  25    :  0110_0010  0x62   98  b  
  26    :  0110_0001  0x61   97  a  
  27    :  0111_0010  0x72  114  r  
  28    :  0000_0011  0x03    3    
  29    :  0110_0011  0x63   99  c  
  30    :  0110_1111  0x6F  111  o  
  31    :  0110_1101  0x6D  109  m  
  32    :  0000_0000  0x00    0    
  33    :  0000_0000  0x00    0    
  34    :  0000_0001  0x01    1    
  35    :  0000_0000  0x00    0    
  36    :  0000_0001  0x01    1    
  37    :  0000_0000  0x00    0    
  38    :  0000_0000  0x00    0    
  39    :  0010_1010  0x2A   42  *  
  40    :  0011_0000  0x30   48  0  
  41    :  0000_0000  0x00    0    
  42    :  0000_0100  0x04    4    
  43    :  0111_1111  0x7F  127    
  44    :  0000_0000  0x00    0    
  45    :  0000_0000  0x00    0    
  46    :  0000_0003  0x03    3    
  47    :  1100_0000  0xC0  192    
  48    :  0000_1100  0x0C   12    
  49    :  0000_0000  0x00    0    
  50    :  0001_0000  0x10   16    
  51    :  0000_0000  0x00    0    
  52    :  0000_0001  0x01    1    
  53    :  0000_0000  0x00    0    
  54    :  0000_0000  0x00    0    
  55    :  0010_1010  0x2A   42  *  
  56    :  0011_0000  0x30   48  0  
  57    :  0000_0000  0x00    0    
  58    :  0101_0011  0x53   83  S  
  59    :  0101_0010  0x52   82  R  
  60    :  0100_0101  0x45   69  E  
  61    :  0111_0010  0x72  114  r  
  62    :  0111_0010  0x72  114  r  
  63    :  0110_1111  0x6F  111  o  
  64    :  0111_0010  0x72  114  r  
  65    :  0011_1010  0x3A   58  :  
  66    :  0010_0000  0x20   32     
  67    :  0111_1001  0x79  121  y  
  68    :  0110_1111  0x6F  111  o  
  69    :  0111_0101  0x75  117  u  
  70    :  0111_0010  0x72  114  r  
  71    :  0010_0000  0x20   32     
  72    :  0110_1101  0x6D  109  m  
  73    :  0110_0001  0x61   97  a  
  74    :  0110_1001  0x69  105  i  
  75    :  0110_1100  0x6C  108  l  
  76    :  0010_0000  0x20   32     
  77    :  0111_0011  0x73  115  s  
  78    :  0110_0101  0x65  101  e  
  79    :  0111_0010  0x72  114  r  
  80    :  0111_0110  0x76  118  v  
  81    :  0110_0101  0x65  101  e  
  82    :  0111_0010  0x72  114  r  
  83    :  0010_0000  0x20   32     
  84    :  0110_1000  0x68  104  h  
  85    :  0110_0001  0x61   97  a  
  86    :  0111_0011  0x73  115  s  
  87    :  0010_0000  0x20   32     
  88    :  0110_0010  0x62   98  b  
  89    :  0110_0101  0x65  101  e  
  90    :  0110_0101  0x65  101  e  
  91    :  0110_1110  0x6E  110  n  
  92    :  0010_0000  0x20   32     
  93    :  0100_0010  0x42   66  B  
  94    :  0100_1100  0x4C   76  L  
  95    :  0100_0001  0x41   65  A  
  96    :  0100_0011  0x43   67  C  
  97    :  0100_1011  0x4B   75  K  
  98    :  0100_1000  0x48   72  H  
  99    :  0100_1111  0x4F   79  O  
  100   :  0100_1100  0x4C   76  L  
  101   :  0100_0101  0x45   69  E  
  102   :  0100_0100  0x44   68  D  
  103   :  0010_1110  0x2E   46  .  
  104   :  0010_0000  0x20   32     
  105   :  0101_0011  0x53   83  S  
  106   :  0110_0101  0x65  101  e  
  107   :  0110_0101  0x65  101  e  
  108   :  0010_0000  0x20   32     
  109   :  0110_1000  0x68  104  h  
  110   :  0111_0100  0x74  116  t  
  111   :  0111_0100  0x74  116  t  
  112   :  0111_0000  0x70  112  p  
  113   :  0011_1010  0x3A   58  :  
  114   :  0010_1111  0x2F   47  /  
  115   :  0010_1111  0x2F   47  /  
  116   :  0110_0010  0x62   98  b  
  117   :  0110_1100  0x6C  108  l  
  118   :  0110_0001  0x61   97  a  
  119   :  0110_0011  0x63   99  c  
  120   :  0110_1011  0x6B  107  k  
  121   :  0110_1000  0x68  104  h  
  122   :  0110_1111  0x6F  111  o  
  123   :  0110_1100  0x6C  108  l  
  124   :  0110_0101  0x65  101  e  
  125   :  0010_1110  0x2E   46  .  
  126   :  0111_0011  0x73  115  s  
  127   :  0111_0000  0x70  112  p  
  128   :  0110_0001  0x61   97  a  
  129   :  0110_1101  0x6D  109  m  
  130   :  0110_0011  0x63   99  c  
  131   :  0110_0001  0x61   97  a  
  132   :  0110_1110  0x6E  110  n  
  133   :  0110_1110  0x6E  110  n  
  134   :  0110_1001  0x69  105  i  
  135   :  0110_0010  0x62   98  b  
  136   :  0110_0001  0x61   97  a  
  137   :  0110_1100  0x6C  108  l  
  138   :  0010_1110  0x2E   46  .  
  139   :  0110_0011  0x63   99  c  
  140   :  0110_1111  0x6F  111  o  
  141   :  0110_1101  0x6D  109  m  
|;
chk_exp(\$response[2],\$exptext);   

#print_buf(\$response[3]); print "\n";
# test 87
$exptext = q|
  0     :  0011_0000  0x30   48  0  
  1     :  0011_1001  0x39   57  9  
  2     :  1000_0100  0x84  132    
  3     :  0000_0000  0x00    0    
  4     :  0000_0000  0x00    0    
  5     :  0000_0000  0x00    0    
  6     :  0000_0000  0x00    0    
  7     :  0000_0001  0x01    1    
  8     :  0000_0000  0x00    0    
  9     :  0000_0000  0x00    0    
  10    :  0000_0000  0x00    0    
  11    :  0000_0000  0x00    0    
  12    :  0000_0011  0x03    3    
  13    :  0110_0010  0x62   98  b  
  14    :  0110_0001  0x61   97  a  
  15    :  0111_0010  0x72  114  r  
  16    :  0000_0011  0x03    3    
  17    :  0110_0011  0x63   99  c  
  18    :  0110_1111  0x6F  111  o  
  19    :  0110_1101  0x6D  109  m  
  20    :  0000_0000  0x00    0    
  21    :  0000_0000  0x00    0    
  22    :  0000_0110  0x06    6    
  23    :  0000_0000  0x00    0    
  24    :  0000_0001  0x01    1    
  25    :  0000_0000  0x00    0    
  26    :  0000_0000  0x00    0    
  27    :  0000_0000  0x00    0    
  28    :  0000_0000  0x00    0    
  29    :  0000_0000  0x00    0    
  30    :  0010_1000  0x28   40  (  
  31    :  0000_1001  0x09    9    
  32    :  0110_1100  0x6C  108  l  
  33    :  0110_1111  0x6F  111  o  
  34    :  0110_0011  0x63   99  c  
  35    :  0110_0001  0x61   97  a  
  36    :  0110_1100  0x6C  108  l  
  37    :  0110_1000  0x68  104  h  
  38    :  0110_1111  0x6F  111  o  
  39    :  0111_0011  0x73  115  s  
  40    :  0111_0100  0x74  116  t  
  41    :  1100_0000  0xC0  192    
  42    :  0000_1100  0x0C   12    
  43    :  0000_0101  0x05    5    
  44    :  0110_1000  0x68  104  h  
  45    :  0111_0101  0x75  117  u  
  46    :  0110_1101  0x6D  109  m  
  47    :  0110_0001  0x61   97  a  
  48    :  0110_1110  0x6E  110  n  
  49    :  1100_0000  0xC0  192    
  50    :  0000_1100  0x0C   12    
  51    :  0000_0111  0x07    7    
  52    :  0101_1011  0x5B   91  [  
  53    :  1100_0011  0xC3  195    
  54    :  0111_0001  0x71  113  q  
  55    :  0000_0000  0x00    0    
  56    :  0000_0000  0x00    0    
  57    :  1010_1000  0xA8  168    
  58    :  1100_0000  0xC0  192    
  59    :  0000_0000  0x00    0    
  60    :  0000_0000  0x00    0    
  61    :  0000_1110  0x0E   14    
  62    :  0001_0000  0x10   16    
  63    :  0000_0000  0x00    0    
  64    :  0000_0001  0x01    1    
  65    :  0101_0001  0x51   81  Q  
  66    :  1000_0000  0x80  128    
  67    :  0000_0000  0x00    0    
  68    :  0000_0000  0x00    0    
  69    :  0010_1010  0x2A   42  *  
  70    :  0011_0000  0x30   48  0  
|;
chk_exp(\$response[3],\$exptext);   

## test 88-89	# test with one split, 2 packets for AXFR
##		check known numeric A record using tcp mode
$len = newhead(\$buffer,
	12345,
	BITS_QUERY,	# opcode
	1,0,0,0,	# one question
);
$len = $put->Question(\$buffer,$len,'bar.com',T_AXFR,C_IN);
#print_buf(\$buffer);
$istcp = 2;		# expect 2 packets
$tcpmode = 2;
($rv,@response) = dialog($buffer,$len,0,$istcp,$tcpmode);	# read, +tcp

#print_buf(\$response[0]); print "\n";
# test 88
# should be the same as packet[0] above
$exptext = q|
  0     :  0011_0000  0x30   48  0  
  1     :  0011_1001  0x39   57  9  
  2     :  1000_0100  0x84  132    
  3     :  0000_0000  0x00    0    
  4     :  0000_0000  0x00    0    
  5     :  0000_0001  0x01    1    
  6     :  0000_0000  0x00    0    
  7     :  0000_1010  0x0A   10    
  8     :  0000_0000  0x00    0    
  9     :  0000_0000  0x00    0    
  10    :  0000_0000  0x00    0    
  11    :  0000_0000  0x00    0    
  12    :  0000_0011  0x03    3    
  13    :  0110_0010  0x62   98  b  
  14    :  0110_0001  0x61   97  a  
  15    :  0111_0010  0x72  114  r  
  16    :  0000_0011  0x03    3    
  17    :  0110_0011  0x63   99  c  
  18    :  0110_1111  0x6F  111  o  
  19    :  0110_1101  0x6D  109  m  
  20    :  0000_0000  0x00    0    
  21    :  0000_0000  0x00    0    
  22    :  1111_1100  0xFC  252    
  23    :  0000_0000  0x00    0    
  24    :  0000_0001  0x01    1    
  25    :  1100_0000  0xC0  192    
  26    :  0000_1100  0x0C   12    
  27    :  0000_0000  0x00    0    
  28    :  0000_0110  0x06    6    
  29    :  0000_0000  0x00    0    
  30    :  0000_0001  0x01    1    
  31    :  0000_0000  0x00    0    
  32    :  0000_0000  0x00    0    
  33    :  0000_0000  0x00    0    
  34    :  0000_0000  0x00    0    
  35    :  0000_0000  0x00    0    
  36    :  0010_1000  0x28   40  (  
  37    :  0000_1001  0x09    9    
  38    :  0110_1100  0x6C  108  l  
  39    :  0110_1111  0x6F  111  o  
  40    :  0110_0011  0x63   99  c  
  41    :  0110_0001  0x61   97  a  
  42    :  0110_1100  0x6C  108  l  
  43    :  0110_1000  0x68  104  h  
  44    :  0110_1111  0x6F  111  o  
  45    :  0111_0011  0x73  115  s  
  46    :  0111_0100  0x74  116  t  
  47    :  1100_0000  0xC0  192    
  48    :  0000_1100  0x0C   12    
  49    :  0000_0101  0x05    5    
  50    :  0110_1000  0x68  104  h  
  51    :  0111_0101  0x75  117  u  
  52    :  0110_1101  0x6D  109  m  
  53    :  0110_0001  0x61   97  a  
  54    :  0110_1110  0x6E  110  n  
  55    :  1100_0000  0xC0  192    
  56    :  0000_1100  0x0C   12    
  57    :  0000_0111  0x07    7    
  58    :  0101_1011  0x5B   91  [  
  59    :  1100_0011  0xC3  195    
  60    :  0111_0001  0x71  113  q  
  61    :  0000_0000  0x00    0    
  62    :  0000_0000  0x00    0    
  63    :  1010_1000  0xA8  168    
  64    :  1100_0000  0xC0  192    
  65    :  0000_0000  0x00    0    
  66    :  0000_0000  0x00    0    
  67    :  0000_1110  0x0E   14    
  68    :  0001_0000  0x10   16    
  69    :  0000_0000  0x00    0    
  70    :  0000_0001  0x01    1    
  71    :  0101_0001  0x51   81  Q  
  72    :  1000_0000  0x80  128    
  73    :  0000_0000  0x00    0    
  74    :  0000_0000  0x00    0    
  75    :  0010_1010  0x2A   42  *  
  76    :  0011_0000  0x30   48  0  
  77    :  1100_0000  0xC0  192    
  78    :  0000_1100  0x0C   12    
  79    :  0000_0000  0x00    0    
  80    :  0000_0010  0x02    2    
  81    :  0000_0000  0x00    0    
  82    :  0000_0001  0x01    1    
  83    :  0000_0000  0x00    0    
  84    :  0000_0000  0x00    0    
  85    :  0010_1010  0x2A   42  *  
  86    :  0011_0000  0x30   48  0  
  87    :  0000_0000  0x00    0    
  88    :  0000_1010  0x0A   10    
  89    :  0000_0011  0x03    3    
  90    :  0110_1110  0x6E  110  n  
  91    :  0111_0011  0x73  115  s  
  92    :  0011_0001  0x31   49  1  
  93    :  0000_0011  0x03    3    
  94    :  0111_1000  0x78  120  x  
  95    :  0111_1001  0x79  121  y  
  96    :  0111_1010  0x7A  122  z  
  97    :  1100_0000  0xC0  192    
  98    :  0001_0000  0x10   16    
  99    :  1100_0000  0xC0  192    
  100   :  0000_1100  0x0C   12    
  101   :  0000_0000  0x00    0    
  102   :  0000_0010  0x02    2    
  103   :  0000_0000  0x00    0    
  104   :  0000_0001  0x01    1    
  105   :  0000_0000  0x00    0    
  106   :  0000_0000  0x00    0    
  107   :  0010_1010  0x2A   42  *  
  108   :  0011_0000  0x30   48  0  
  109   :  0000_0000  0x00    0    
  110   :  0000_0110  0x06    6    
  111   :  0000_0011  0x03    3    
  112   :  0110_1110  0x6E  110  n  
  113   :  0111_0011  0x73  115  s  
  114   :  0011_0010  0x32   50  2  
  115   :  1100_0000  0xC0  192    
  116   :  0000_1100  0x0C   12    
  117   :  1100_0000  0xC0  192    
  118   :  0000_1100  0x0C   12    
  119   :  0000_0000  0x00    0    
  120   :  0000_0010  0x02    2    
  121   :  0000_0000  0x00    0    
  122   :  0000_0001  0x01    1    
  123   :  0000_0000  0x00    0    
  124   :  0000_0000  0x00    0    
  125   :  0010_1010  0x2A   42  *  
  126   :  0011_0000  0x30   48  0  
  127   :  0000_0000  0x00    0    
  128   :  0000_0010  0x02    2    
  129   :  1100_0000  0xC0  192    
  130   :  0000_1100  0x0C   12    
  131   :  1100_0000  0xC0  192    
  132   :  0000_1100  0x0C   12    
  133   :  0000_0000  0x00    0    
  134   :  0000_1111  0x0F   15    
  135   :  0000_0000  0x00    0    
  136   :  0000_0001  0x01    1    
  137   :  0000_0000  0x00    0    
  138   :  0000_0000  0x00    0    
  139   :  0010_1010  0x2A   42  *  
  140   :  0011_0000  0x30   48  0  
  141   :  0000_0000  0x00    0    
  142   :  0000_0100  0x04    4    
  143   :  0000_0000  0x00    0    
  144   :  0011_0010  0x32   50  2  
  145   :  1100_0000  0xC0  192    
  146   :  0000_1100  0x0C   12    
  147   :  1100_0000  0xC0  192    
  148   :  0000_1100  0x0C   12    
  149   :  0000_0000  0x00    0    
  150   :  0000_1111  0x0F   15    
  151   :  0000_0000  0x00    0    
  152   :  0000_0001  0x01    1    
  153   :  0000_0000  0x00    0    
  154   :  0000_0000  0x00    0    
  155   :  0010_1010  0x2A   42  *  
  156   :  0011_0000  0x30   48  0  
  157   :  0000_0000  0x00    0    
  158   :  0000_0111  0x07    7    
  159   :  0000_0000  0x00    0    
  160   :  0000_1010  0x0A   10    
  161   :  0000_0010  0x02    2    
  162   :  0110_1101  0x6D  109  m  
  163   :  0111_1000  0x78  120  x  
  164   :  1100_0000  0xC0  192    
  165   :  0000_1100  0x0C   12    
  166   :  1100_0000  0xC0  192    
  167   :  0110_1111  0x6F  111  o  
  168   :  0000_0000  0x00    0    
  169   :  0000_0001  0x01    1    
  170   :  0000_0000  0x00    0    
  171   :  0000_0001  0x01    1    
  172   :  0000_0000  0x00    0    
  173   :  0000_0000  0x00    0    
  174   :  0010_1010  0x2A   42  *  
  175   :  0011_0000  0x30   48  0  
  176   :  0000_0000  0x00    0    
  177   :  0000_0100  0x04    4    
  178   :  0100_1100  0x4C   76  L  
  179   :  0011_0110  0x36   54  6  
  180   :  0010_0000  0x20   32     
  181   :  0000_1010  0x0A   10    
  182   :  1100_0000  0xC0  192    
  183   :  0000_1100  0x0C   12    
  184   :  0000_0000  0x00    0    
  185   :  0000_0001  0x01    1    
  186   :  0000_0000  0x00    0    
  187   :  0000_0001  0x01    1    
  188   :  0000_0000  0x00    0    
  189   :  0000_0000  0x00    0    
  190   :  0010_1010  0x2A   42  *  
  191   :  0011_0000  0x30   48  0  
  192   :  0000_0000  0x00    0    
  193   :  0000_0100  0x04    4    
  194   :  0000_0001  0x01    1    
  195   :  0000_0010  0x02    2    
  196   :  0000_0011  0x03    3    
  197   :  0000_0100  0x04    4    
  198   :  1100_0000  0xC0  192    
  199   :  1010_0001  0xA1  161    
  200   :  0000_0000  0x00    0    
  201   :  0000_0001  0x01    1    
  202   :  0000_0000  0x00    0    
  203   :  0000_0001  0x01    1    
  204   :  0000_0000  0x00    0    
  205   :  0000_0000  0x00    0    
  206   :  0010_1010  0x2A   42  *  
  207   :  0011_0000  0x30   48  0  
  208   :  0000_0000  0x00    0    
  209   :  0000_0100  0x04    4    
  210   :  0110_0101  0x65  101  e  
  211   :  1100_1010  0xCA  202    
  212   :  0110_0111  0x67  103  g  
  213   :  0010_1100  0x2C   44  ,  
  214   :  1100_0000  0xC0  192    
  215   :  0000_1100  0x0C   12    
  216   :  0000_0000  0x00    0    
  217   :  0000_0001  0x01    1    
  218   :  0000_0000  0x00    0    
  219   :  0000_0001  0x01    1    
  220   :  0000_0000  0x00    0    
  221   :  0000_0000  0x00    0    
  222   :  0010_1010  0x2A   42  *  
  223   :  0011_0000  0x30   48  0  
  224   :  0000_0000  0x00    0    
  225   :  0000_0100  0x04    4    
  226   :  1100_0000  0xC0  192    
  227   :  1010_1000  0xA8  168    
  228   :  0110_0011  0x63   99  c  
  229   :  0110_0100  0x64  100  d  
|;
chk_exp(\$response[0],\$exptext); 

#print_buf(\$response[1]); print "\n";
# test 89
$exptext = q|
  0     :  0011_0000  0x30   48  0  
  1     :  0011_1001  0x39   57  9  
  2     :  1000_0100  0x84  132    
  3     :  0000_0000  0x00    0    
  4     :  0000_0000  0x00    0    
  5     :  0000_0000  0x00    0    
  6     :  0000_0000  0x00    0    
  7     :  0000_0101  0x05    5    
  8     :  0000_0000  0x00    0    
  9     :  0000_0000  0x00    0    
  10    :  0000_0000  0x00    0    
  11    :  0000_0000  0x00    0    
  12    :  0000_0001  0x01    1    
  13    :  0011_0001  0x31   49  1  
  14    :  0000_0001  0x01    1    
  15    :  0011_0010  0x32   50  2  
  16    :  0000_0001  0x01    1    
  17    :  0011_0011  0x33   51  3  
  18    :  0000_0001  0x01    1    
  19    :  0011_0100  0x34   52  4  
  20    :  0000_0011  0x03    3    
  21    :  0110_0010  0x62   98  b  
  22    :  0110_0001  0x61   97  a  
  23    :  0111_0010  0x72  114  r  
  24    :  0000_0011  0x03    3    
  25    :  0110_0011  0x63   99  c  
  26    :  0110_1111  0x6F  111  o  
  27    :  0110_1101  0x6D  109  m  
  28    :  0000_0000  0x00    0    
  29    :  0000_0000  0x00    0    
  30    :  0000_0001  0x01    1    
  31    :  0000_0000  0x00    0    
  32    :  0000_0001  0x01    1    
  33    :  0000_0000  0x00    0    
  34    :  0000_0000  0x00    0    
  35    :  0010_1010  0x2A   42  *  
  36    :  0011_0000  0x30   48  0  
  37    :  0000_0000  0x00    0    
  38    :  0000_0100  0x04    4    
  39    :  0111_1111  0x7F  127    
  40    :  0000_0000  0x00    0    
  41    :  0000_0000  0x00    0    
  42    :  0000_0010  0x02    2    
  43    :  1100_0000  0xC0  192    
  44    :  0000_1100  0x0C   12    
  45    :  0000_0000  0x00    0    
  46    :  0001_0000  0x10   16    
  47    :  0000_0000  0x00    0    
  48    :  0000_0001  0x01    1    
  49    :  0000_0000  0x00    0    
  50    :  0000_0000  0x00    0    
  51    :  0010_1010  0x2A   42  *  
  52    :  0011_0000  0x30   48  0  
  53    :  0000_0000  0x00    0    
  54    :  0010_0010  0x22   34  "  
  55    :  0010_0001  0x21   33  !  
  56    :  0100_0001  0x41   65  A  
  57    :  0110_1100  0x6C  108  l  
  58    :  0111_0100  0x74  116  t  
  59    :  0110_0101  0x65  101  e  
  60    :  0111_0010  0x72  114  r  
  61    :  0110_1110  0x6E  110  n  
  62    :  0110_0001  0x61   97  a  
  63    :  0111_0100  0x74  116  t  
  64    :  0110_0101  0x65  101  e  
  65    :  0010_0000  0x20   32     
  66    :  0100_0101  0x45   69  E  
  67    :  0111_0010  0x72  114  r  
  68    :  0111_0010  0x72  114  r  
  69    :  0110_1111  0x6F  111  o  
  70    :  0111_0010  0x72  114  r  
  71    :  0011_1010  0x3A   58  :  
  72    :  0010_0000  0x20   32     
  73    :  0110_0110  0x66  102  f  
  74    :  0111_0010  0x72  114  r  
  75    :  0110_1111  0x6F  111  o  
  76    :  0110_1101  0x6D  109  m  
  77    :  0010_0000  0x20   32     
  78    :  0110_0001  0x61   97  a  
  79    :  0110_1110  0x6E  110  n  
  80    :  0110_1111  0x6F  111  o  
  81    :  0111_0100  0x74  116  t  
  82    :  0110_1000  0x68  104  h  
  83    :  0110_0101  0x65  101  e  
  84    :  0111_0010  0x72  114  r  
  85    :  0010_0000  0x20   32     
  86    :  0101_0010  0x52   82  R  
  87    :  0100_0010  0x42   66  B  
  88    :  0100_1100  0x4C   76  L  
  89    :  0000_0010  0x02    2    
  90    :  0011_1000  0x38   56  8  
  91    :  0011_1001  0x39   57  9  
  92    :  0000_0010  0x02    2    
  93    :  0011_1000  0x38   56  8  
  94    :  0011_1000  0x38   56  8  
  95    :  0000_0010  0x02    2    
  96    :  0011_1000  0x38   56  8  
  97    :  0011_0111  0x37   55  7  
  98    :  0000_0010  0x02    2    
  99    :  0011_1000  0x38   56  8  
  100   :  0011_0110  0x36   54  6  
  101   :  1100_0000  0xC0  192    
  102   :  0001_0100  0x14   20    
  103   :  0000_0000  0x00    0    
  104   :  0000_0001  0x01    1    
  105   :  0000_0000  0x00    0    
  106   :  0000_0001  0x01    1    
  107   :  0000_0000  0x00    0    
  108   :  0000_0000  0x00    0    
  109   :  0010_1010  0x2A   42  *  
  110   :  0011_0000  0x30   48  0  
  111   :  0000_0000  0x00    0    
  112   :  0000_0100  0x04    4    
  113   :  0111_1111  0x7F  127    
  114   :  0000_0000  0x00    0    
  115   :  0000_0000  0x00    0    
  116   :  0000_0003  0x03    3    
  117   :  1100_0000  0xC0  192    
  118   :  0101_1001  0x59   89  Y  
  119   :  0000_0000  0x00    0    
  120   :  0001_0000  0x10   16    
  121   :  0000_0000  0x00    0    
  122   :  0000_0001  0x01    1    
  123   :  0000_0000  0x00    0    
  124   :  0000_0000  0x00    0    
  125   :  0010_1010  0x2A   42  *  
  126   :  0011_0000  0x30   48  0  
  127   :  0000_0000  0x00    0    
  128   :  0101_0011  0x53   83  S  
  129   :  0101_0010  0x52   82  R  
  130   :  0100_0101  0x45   69  E  
  131   :  0111_0010  0x72  114  r  
  132   :  0111_0010  0x72  114  r  
  133   :  0110_1111  0x6F  111  o  
  134   :  0111_0010  0x72  114  r  
  135   :  0011_1010  0x3A   58  :  
  136   :  0010_0000  0x20   32     
  137   :  0111_1001  0x79  121  y  
  138   :  0110_1111  0x6F  111  o  
  139   :  0111_0101  0x75  117  u  
  140   :  0111_0010  0x72  114  r  
  141   :  0010_0000  0x20   32     
  142   :  0110_1101  0x6D  109  m  
  143   :  0110_0001  0x61   97  a  
  144   :  0110_1001  0x69  105  i  
  145   :  0110_1100  0x6C  108  l  
  146   :  0010_0000  0x20   32     
  147   :  0111_0011  0x73  115  s  
  148   :  0110_0101  0x65  101  e  
  149   :  0111_0010  0x72  114  r  
  150   :  0111_0110  0x76  118  v  
  151   :  0110_0101  0x65  101  e  
  152   :  0111_0010  0x72  114  r  
  153   :  0010_0000  0x20   32     
  154   :  0110_1000  0x68  104  h  
  155   :  0110_0001  0x61   97  a  
  156   :  0111_0011  0x73  115  s  
  157   :  0010_0000  0x20   32     
  158   :  0110_0010  0x62   98  b  
  159   :  0110_0101  0x65  101  e  
  160   :  0110_0101  0x65  101  e  
  161   :  0110_1110  0x6E  110  n  
  162   :  0010_0000  0x20   32     
  163   :  0100_0010  0x42   66  B  
  164   :  0100_1100  0x4C   76  L  
  165   :  0100_0001  0x41   65  A  
  166   :  0100_0011  0x43   67  C  
  167   :  0100_1011  0x4B   75  K  
  168   :  0100_1000  0x48   72  H  
  169   :  0100_1111  0x4F   79  O  
  170   :  0100_1100  0x4C   76  L  
  171   :  0100_0101  0x45   69  E  
  172   :  0100_0100  0x44   68  D  
  173   :  0010_1110  0x2E   46  .  
  174   :  0010_0000  0x20   32     
  175   :  0101_0011  0x53   83  S  
  176   :  0110_0101  0x65  101  e  
  177   :  0110_0101  0x65  101  e  
  178   :  0010_0000  0x20   32     
  179   :  0110_1000  0x68  104  h  
  180   :  0111_0100  0x74  116  t  
  181   :  0111_0100  0x74  116  t  
  182   :  0111_0000  0x70  112  p  
  183   :  0011_1010  0x3A   58  :  
  184   :  0010_1111  0x2F   47  /  
  185   :  0010_1111  0x2F   47  /  
  186   :  0110_0010  0x62   98  b  
  187   :  0110_1100  0x6C  108  l  
  188   :  0110_0001  0x61   97  a  
  189   :  0110_0011  0x63   99  c  
  190   :  0110_1011  0x6B  107  k  
  191   :  0110_1000  0x68  104  h  
  192   :  0110_1111  0x6F  111  o  
  193   :  0110_1100  0x6C  108  l  
  194   :  0110_0101  0x65  101  e  
  195   :  0010_1110  0x2E   46  .  
  196   :  0111_0011  0x73  115  s  
  197   :  0111_0000  0x70  112  p  
  198   :  0110_0001  0x61   97  a  
  199   :  0110_1101  0x6D  109  m  
  200   :  0110_0011  0x63   99  c  
  201   :  0110_0001  0x61   97  a  
  202   :  0110_1110  0x6E  110  n  
  203   :  0110_1110  0x6E  110  n  
  204   :  0110_1001  0x69  105  i  
  205   :  0110_0010  0x62   98  b  
  206   :  0110_0001  0x61   97  a  
  207   :  0110_1100  0x6C  108  l  
  208   :  0010_1110  0x2E   46  .  
  209   :  0110_0011  0x63   99  c  
  210   :  0110_1111  0x6F  111  o  
  211   :  0110_1101  0x6D  109  m  
  212   :  1100_0000  0xC0  192    
  213   :  0001_0100  0x14   20    
  214   :  0000_0000  0x00    0    
  215   :  0000_0110  0x06    6    
  216   :  0000_0000  0x00    0    
  217   :  0000_0001  0x01    1    
  218   :  0000_0000  0x00    0    
  219   :  0000_0000  0x00    0    
  220   :  0000_0000  0x00    0    
  221   :  0000_0000  0x00    0    
  222   :  0000_0000  0x00    0    
  223   :  0010_1000  0x28   40  (  
  224   :  0000_1001  0x09    9    
  225   :  0110_1100  0x6C  108  l  
  226   :  0110_1111  0x6F  111  o  
  227   :  0110_0011  0x63   99  c  
  228   :  0110_0001  0x61   97  a  
  229   :  0110_1100  0x6C  108  l  
  230   :  0110_1000  0x68  104  h  
  231   :  0110_1111  0x6F  111  o  
  232   :  0111_0011  0x73  115  s  
  233   :  0111_0100  0x74  116  t  
  234   :  1100_0000  0xC0  192    
  235   :  0001_0100  0x14   20    
  236   :  0000_0101  0x05    5    
  237   :  0110_1000  0x68  104  h  
  238   :  0111_0101  0x75  117  u  
  239   :  0110_1101  0x6D  109  m  
  240   :  0110_0001  0x61   97  a  
  241   :  0110_1110  0x6E  110  n  
  242   :  1100_0000  0xC0  192    
  243   :  0001_0100  0x14   20    
  244   :  0000_0111  0x07    7    
  245   :  0101_1011  0x5B   91  [  
  246   :  1100_0011  0xC3  195    
  247   :  0111_0001  0x71  113  q  
  248   :  0000_0000  0x00    0    
  249   :  0000_0000  0x00    0    
  250   :  1010_1000  0xA8  168    
  251   :  1100_0000  0xC0  192    
  252   :  0000_0000  0x00    0    
  253   :  0000_0000  0x00    0    
  254   :  0000_1110  0x0E   14    
  255   :  0001_0000  0x10   16    
  256   :  0000_0000  0x00    0    
  257   :  0000_0001  0x01    1    
  258   :  0101_0001  0x51   81  Q  
  259   :  1000_0000  0x80  128    
  260   :  0000_0000  0x00    0    
  261   :  0000_0000  0x00    0    
  262   :  0010_1010  0x2A   42  *  
  263   :  0011_0000  0x30   48  0  
|;
chk_exp(\$response[1],\$exptext);   

## test 90	# test with single packet for AXFR, normal mode
##		check known numeric A record using tcp mode
$len = newhead(\$buffer,
	12345,
	BITS_QUERY,	# opcode
	1,0,0,0,	# one question
);
$len = $put->Question(\$buffer,$len,'bar.com',T_AXFR,C_IN);
#print_buf(\$buffer);
$istcp = 1;		# expect 1 packet
$tcpmode = 1;
($rv,@response) = dialog($buffer,$len,0,$istcp,$tcpmode);	# read, +tcp

#print_buf(\$response[0]); print "\n";

$exptext = q|
  0     :  0011_0000  0x30   48  0  
  1     :  0011_1001  0x39   57  9  
  2     :  1000_0100  0x84  132    
  3     :  0000_0000  0x00    0    
  4     :  0000_0000  0x00    0    
  5     :  0000_0001  0x01    1    
  6     :  0000_0000  0x00    0    
  7     :  0000_1111  0x0F   15    
  8     :  0000_0000  0x00    0    
  9     :  0000_0000  0x00    0    
  10    :  0000_0000  0x00    0    
  11    :  0000_0000  0x00    0    
  12    :  0000_0011  0x03    3    
  13    :  0110_0010  0x62   98  b  
  14    :  0110_0001  0x61   97  a  
  15    :  0111_0010  0x72  114  r  
  16    :  0000_0011  0x03    3    
  17    :  0110_0011  0x63   99  c  
  18    :  0110_1111  0x6F  111  o  
  19    :  0110_1101  0x6D  109  m  
  20    :  0000_0000  0x00    0    
  21    :  0000_0000  0x00    0    
  22    :  1111_1100  0xFC  252    
  23    :  0000_0000  0x00    0    
  24    :  0000_0001  0x01    1    
  25    :  1100_0000  0xC0  192    
  26    :  0000_1100  0x0C   12    
  27    :  0000_0000  0x00    0    
  28    :  0000_0110  0x06    6    
  29    :  0000_0000  0x00    0    
  30    :  0000_0001  0x01    1    
  31    :  0000_0000  0x00    0    
  32    :  0000_0000  0x00    0    
  33    :  0000_0000  0x00    0    
  34    :  0000_0000  0x00    0    
  35    :  0000_0000  0x00    0    
  36    :  0010_1000  0x28   40  (  
  37    :  0000_1001  0x09    9    
  38    :  0110_1100  0x6C  108  l  
  39    :  0110_1111  0x6F  111  o  
  40    :  0110_0011  0x63   99  c  
  41    :  0110_0001  0x61   97  a  
  42    :  0110_1100  0x6C  108  l  
  43    :  0110_1000  0x68  104  h  
  44    :  0110_1111  0x6F  111  o  
  45    :  0111_0011  0x73  115  s  
  46    :  0111_0100  0x74  116  t  
  47    :  1100_0000  0xC0  192    
  48    :  0000_1100  0x0C   12    
  49    :  0000_0101  0x05    5    
  50    :  0110_1000  0x68  104  h  
  51    :  0111_0101  0x75  117  u  
  52    :  0110_1101  0x6D  109  m  
  53    :  0110_0001  0x61   97  a  
  54    :  0110_1110  0x6E  110  n  
  55    :  1100_0000  0xC0  192    
  56    :  0000_1100  0x0C   12    
  57    :  0000_0111  0x07    7    
  58    :  0101_1011  0x5B   91  [  
  59    :  1100_0011  0xC3  195    
  60    :  0111_0001  0x71  113  q  
  61    :  0000_0000  0x00    0    
  62    :  0000_0000  0x00    0    
  63    :  1010_1000  0xA8  168    
  64    :  1100_0000  0xC0  192    
  65    :  0000_0000  0x00    0    
  66    :  0000_0000  0x00    0    
  67    :  0000_1110  0x0E   14    
  68    :  0001_0000  0x10   16    
  69    :  0000_0000  0x00    0    
  70    :  0000_0001  0x01    1    
  71    :  0101_0001  0x51   81  Q  
  72    :  1000_0000  0x80  128    
  73    :  0000_0000  0x00    0    
  74    :  0000_0000  0x00    0    
  75    :  0010_1010  0x2A   42  *  
  76    :  0011_0000  0x30   48  0  
  77    :  1100_0000  0xC0  192    
  78    :  0000_1100  0x0C   12    
  79    :  0000_0000  0x00    0    
  80    :  0000_0010  0x02    2    
  81    :  0000_0000  0x00    0    
  82    :  0000_0001  0x01    1    
  83    :  0000_0000  0x00    0    
  84    :  0000_0000  0x00    0    
  85    :  0010_1010  0x2A   42  *  
  86    :  0011_0000  0x30   48  0  
  87    :  0000_0000  0x00    0    
  88    :  0000_1010  0x0A   10    
  89    :  0000_0011  0x03    3    
  90    :  0110_1110  0x6E  110  n  
  91    :  0111_0011  0x73  115  s  
  92    :  0011_0001  0x31   49  1  
  93    :  0000_0011  0x03    3    
  94    :  0111_1000  0x78  120  x  
  95    :  0111_1001  0x79  121  y  
  96    :  0111_1010  0x7A  122  z  
  97    :  1100_0000  0xC0  192    
  98    :  0001_0000  0x10   16    
  99    :  1100_0000  0xC0  192    
  100   :  0000_1100  0x0C   12    
  101   :  0000_0000  0x00    0    
  102   :  0000_0010  0x02    2    
  103   :  0000_0000  0x00    0    
  104   :  0000_0001  0x01    1    
  105   :  0000_0000  0x00    0    
  106   :  0000_0000  0x00    0    
  107   :  0010_1010  0x2A   42  *  
  108   :  0011_0000  0x30   48  0  
  109   :  0000_0000  0x00    0    
  110   :  0000_0110  0x06    6    
  111   :  0000_0011  0x03    3    
  112   :  0110_1110  0x6E  110  n  
  113   :  0111_0011  0x73  115  s  
  114   :  0011_0010  0x32   50  2  
  115   :  1100_0000  0xC0  192    
  116   :  0000_1100  0x0C   12    
  117   :  1100_0000  0xC0  192    
  118   :  0000_1100  0x0C   12    
  119   :  0000_0000  0x00    0    
  120   :  0000_0010  0x02    2    
  121   :  0000_0000  0x00    0    
  122   :  0000_0001  0x01    1    
  123   :  0000_0000  0x00    0    
  124   :  0000_0000  0x00    0    
  125   :  0010_1010  0x2A   42  *  
  126   :  0011_0000  0x30   48  0  
  127   :  0000_0000  0x00    0    
  128   :  0000_0010  0x02    2    
  129   :  1100_0000  0xC0  192    
  130   :  0000_1100  0x0C   12    
  131   :  1100_0000  0xC0  192    
  132   :  0000_1100  0x0C   12    
  133   :  0000_0000  0x00    0    
  134   :  0000_1111  0x0F   15    
  135   :  0000_0000  0x00    0    
  136   :  0000_0001  0x01    1    
  137   :  0000_0000  0x00    0    
  138   :  0000_0000  0x00    0    
  139   :  0010_1010  0x2A   42  *  
  140   :  0011_0000  0x30   48  0  
  141   :  0000_0000  0x00    0    
  142   :  0000_0100  0x04    4    
  143   :  0000_0000  0x00    0    
  144   :  0011_0010  0x32   50  2  
  145   :  1100_0000  0xC0  192    
  146   :  0000_1100  0x0C   12    
  147   :  1100_0000  0xC0  192    
  148   :  0000_1100  0x0C   12    
  149   :  0000_0000  0x00    0    
  150   :  0000_1111  0x0F   15    
  151   :  0000_0000  0x00    0    
  152   :  0000_0001  0x01    1    
  153   :  0000_0000  0x00    0    
  154   :  0000_0000  0x00    0    
  155   :  0010_1010  0x2A   42  *  
  156   :  0011_0000  0x30   48  0  
  157   :  0000_0000  0x00    0    
  158   :  0000_0111  0x07    7    
  159   :  0000_0000  0x00    0    
  160   :  0000_1010  0x0A   10    
  161   :  0000_0010  0x02    2    
  162   :  0110_1101  0x6D  109  m  
  163   :  0111_1000  0x78  120  x  
  164   :  1100_0000  0xC0  192    
  165   :  0000_1100  0x0C   12    
  166   :  1100_0000  0xC0  192    
  167   :  0110_1111  0x6F  111  o  
  168   :  0000_0000  0x00    0    
  169   :  0000_0001  0x01    1    
  170   :  0000_0000  0x00    0    
  171   :  0000_0001  0x01    1    
  172   :  0000_0000  0x00    0    
  173   :  0000_0000  0x00    0    
  174   :  0010_1010  0x2A   42  *  
  175   :  0011_0000  0x30   48  0  
  176   :  0000_0000  0x00    0    
  177   :  0000_0100  0x04    4    
  178   :  0100_1100  0x4C   76  L  
  179   :  0011_0110  0x36   54  6  
  180   :  0010_0000  0x20   32     
  181   :  0000_1010  0x0A   10    
  182   :  1100_0000  0xC0  192    
  183   :  0000_1100  0x0C   12    
  184   :  0000_0000  0x00    0    
  185   :  0000_0001  0x01    1    
  186   :  0000_0000  0x00    0    
  187   :  0000_0001  0x01    1    
  188   :  0000_0000  0x00    0    
  189   :  0000_0000  0x00    0    
  190   :  0010_1010  0x2A   42  *  
  191   :  0011_0000  0x30   48  0  
  192   :  0000_0000  0x00    0    
  193   :  0000_0100  0x04    4    
  194   :  0000_0001  0x01    1    
  195   :  0000_0010  0x02    2    
  196   :  0000_0011  0x03    3    
  197   :  0000_0100  0x04    4    
  198   :  1100_0000  0xC0  192    
  199   :  1010_0001  0xA1  161    
  200   :  0000_0000  0x00    0    
  201   :  0000_0001  0x01    1    
  202   :  0000_0000  0x00    0    
  203   :  0000_0001  0x01    1    
  204   :  0000_0000  0x00    0    
  205   :  0000_0000  0x00    0    
  206   :  0010_1010  0x2A   42  *  
  207   :  0011_0000  0x30   48  0  
  208   :  0000_0000  0x00    0    
  209   :  0000_0100  0x04    4    
  210   :  0110_0101  0x65  101  e  
  211   :  1100_1010  0xCA  202    
  212   :  0110_0111  0x67  103  g  
  213   :  0010_1100  0x2C   44  ,  
  214   :  1100_0000  0xC0  192    
  215   :  0000_1100  0x0C   12    
  216   :  0000_0000  0x00    0    
  217   :  0000_0001  0x01    1    
  218   :  0000_0000  0x00    0    
  219   :  0000_0001  0x01    1    
  220   :  0000_0000  0x00    0    
  221   :  0000_0000  0x00    0    
  222   :  0010_1010  0x2A   42  *  
  223   :  0011_0000  0x30   48  0  
  224   :  0000_0000  0x00    0    
  225   :  0000_0100  0x04    4    
  226   :  1100_0000  0xC0  192    
  227   :  1010_1000  0xA8  168    
  228   :  0110_0011  0x63   99  c  
  229   :  0110_0100  0x64  100  d  
  230   :  0000_0001  0x01    1    
  231   :  0011_0001  0x31   49  1  
  232   :  0000_0001  0x01    1    
  233   :  0011_0010  0x32   50  2  
  234   :  0000_0001  0x01    1    
  235   :  0011_0011  0x33   51  3  
  236   :  0000_0001  0x01    1    
  237   :  0011_0100  0x34   52  4  
  238   :  1100_0000  0xC0  192    
  239   :  0000_1100  0x0C   12    
  240   :  0000_0000  0x00    0    
  241   :  0000_0001  0x01    1    
  242   :  0000_0000  0x00    0    
  243   :  0000_0001  0x01    1    
  244   :  0000_0000  0x00    0    
  245   :  0000_0000  0x00    0    
  246   :  0010_1010  0x2A   42  *  
  247   :  0011_0000  0x30   48  0  
  248   :  0000_0000  0x00    0    
  249   :  0000_0100  0x04    4    
  250   :  0111_1111  0x7F  127    
  251   :  0000_0000  0x00    0    
  252   :  0000_0000  0x00    0    
  253   :  0000_0010  0x02    2    
  254   :  1100_0000  0xC0  192    
  255   :  1110_0110  0xE6  230    
  256   :  0000_0000  0x00    0    
  257   :  0001_0000  0x10   16    
  258   :  0000_0000  0x00    0    
  259   :  0000_0001  0x01    1    
  260   :  0000_0000  0x00    0    
  261   :  0000_0000  0x00    0    
  262   :  0010_1010  0x2A   42  *  
  263   :  0011_0000  0x30   48  0  
  264   :  0000_0000  0x00    0    
  265   :  0010_0010  0x22   34  "  
  266   :  0010_0001  0x21   33  !  
  267   :  0100_0001  0x41   65  A  
  268   :  0110_1100  0x6C  108  l  
  269   :  0111_0100  0x74  116  t  
  270   :  0110_0101  0x65  101  e  
  271   :  0111_0010  0x72  114  r  
  272   :  0110_1110  0x6E  110  n  
  273   :  0110_0001  0x61   97  a  
  274   :  0111_0100  0x74  116  t  
  275   :  0110_0101  0x65  101  e  
  276   :  0010_0000  0x20   32     
  277   :  0100_0101  0x45   69  E  
  278   :  0111_0010  0x72  114  r  
  279   :  0111_0010  0x72  114  r  
  280   :  0110_1111  0x6F  111  o  
  281   :  0111_0010  0x72  114  r  
  282   :  0011_1010  0x3A   58  :  
  283   :  0010_0000  0x20   32     
  284   :  0110_0110  0x66  102  f  
  285   :  0111_0010  0x72  114  r  
  286   :  0110_1111  0x6F  111  o  
  287   :  0110_1101  0x6D  109  m  
  288   :  0010_0000  0x20   32     
  289   :  0110_0001  0x61   97  a  
  290   :  0110_1110  0x6E  110  n  
  291   :  0110_1111  0x6F  111  o  
  292   :  0111_0100  0x74  116  t  
  293   :  0110_1000  0x68  104  h  
  294   :  0110_0101  0x65  101  e  
  295   :  0111_0010  0x72  114  r  
  296   :  0010_0000  0x20   32     
  297   :  0101_0010  0x52   82  R  
  298   :  0100_0010  0x42   66  B  
  299   :  0100_1100  0x4C   76  L  
  300   :  0000_0010  0x02    2    
  301   :  0011_1000  0x38   56  8  
  302   :  0011_1001  0x39   57  9  
  303   :  0000_0010  0x02    2    
  304   :  0011_1000  0x38   56  8  
  305   :  0011_1000  0x38   56  8  
  306   :  0000_0010  0x02    2    
  307   :  0011_1000  0x38   56  8  
  308   :  0011_0111  0x37   55  7  
  309   :  0000_0010  0x02    2    
  310   :  0011_1000  0x38   56  8  
  311   :  0011_0110  0x36   54  6  
  312   :  1100_0000  0xC0  192    
  313   :  0000_1100  0x0C   12    
  314   :  0000_0000  0x00    0    
  315   :  0000_0001  0x01    1    
  316   :  0000_0000  0x00    0    
  317   :  0000_0001  0x01    1    
  318   :  0000_0000  0x00    0    
  319   :  0000_0000  0x00    0    
  320   :  0010_1010  0x2A   42  *  
  321   :  0011_0000  0x30   48  0  
  322   :  0000_0000  0x00    0    
  323   :  0000_0100  0x04    4    
  324   :  0111_1111  0x7F  127    
  325   :  0000_0000  0x00    0    
  326   :  0000_0000  0x00    0    
  327   :  0000_0003  0x03    3    
  328   :  1100_0001  0xC1  193    
  329   :  0010_1100  0x2C   44  ,  
  330   :  0000_0000  0x00    0    
  331   :  0001_0000  0x10   16    
  332   :  0000_0000  0x00    0    
  333   :  0000_0001  0x01    1    
  334   :  0000_0000  0x00    0    
  335   :  0000_0000  0x00    0    
  336   :  0010_1010  0x2A   42  *  
  337   :  0011_0000  0x30   48  0  
  338   :  0000_0000  0x00    0    
  339   :  0101_0011  0x53   83  S  
  340   :  0101_0010  0x52   82  R  
  341   :  0100_0101  0x45   69  E  
  342   :  0111_0010  0x72  114  r  
  343   :  0111_0010  0x72  114  r  
  344   :  0110_1111  0x6F  111  o  
  345   :  0111_0010  0x72  114  r  
  346   :  0011_1010  0x3A   58  :  
  347   :  0010_0000  0x20   32     
  348   :  0111_1001  0x79  121  y  
  349   :  0110_1111  0x6F  111  o  
  350   :  0111_0101  0x75  117  u  
  351   :  0111_0010  0x72  114  r  
  352   :  0010_0000  0x20   32     
  353   :  0110_1101  0x6D  109  m  
  354   :  0110_0001  0x61   97  a  
  355   :  0110_1001  0x69  105  i  
  356   :  0110_1100  0x6C  108  l  
  357   :  0010_0000  0x20   32     
  358   :  0111_0011  0x73  115  s  
  359   :  0110_0101  0x65  101  e  
  360   :  0111_0010  0x72  114  r  
  361   :  0111_0110  0x76  118  v  
  362   :  0110_0101  0x65  101  e  
  363   :  0111_0010  0x72  114  r  
  364   :  0010_0000  0x20   32     
  365   :  0110_1000  0x68  104  h  
  366   :  0110_0001  0x61   97  a  
  367   :  0111_0011  0x73  115  s  
  368   :  0010_0000  0x20   32     
  369   :  0110_0010  0x62   98  b  
  370   :  0110_0101  0x65  101  e  
  371   :  0110_0101  0x65  101  e  
  372   :  0110_1110  0x6E  110  n  
  373   :  0010_0000  0x20   32     
  374   :  0100_0010  0x42   66  B  
  375   :  0100_1100  0x4C   76  L  
  376   :  0100_0001  0x41   65  A  
  377   :  0100_0011  0x43   67  C  
  378   :  0100_1011  0x4B   75  K  
  379   :  0100_1000  0x48   72  H  
  380   :  0100_1111  0x4F   79  O  
  381   :  0100_1100  0x4C   76  L  
  382   :  0100_0101  0x45   69  E  
  383   :  0100_0100  0x44   68  D  
  384   :  0010_1110  0x2E   46  .  
  385   :  0010_0000  0x20   32     
  386   :  0101_0011  0x53   83  S  
  387   :  0110_0101  0x65  101  e  
  388   :  0110_0101  0x65  101  e  
  389   :  0010_0000  0x20   32     
  390   :  0110_1000  0x68  104  h  
  391   :  0111_0100  0x74  116  t  
  392   :  0111_0100  0x74  116  t  
  393   :  0111_0000  0x70  112  p  
  394   :  0011_1010  0x3A   58  :  
  395   :  0010_1111  0x2F   47  /  
  396   :  0010_1111  0x2F   47  /  
  397   :  0110_0010  0x62   98  b  
  398   :  0110_1100  0x6C  108  l  
  399   :  0110_0001  0x61   97  a  
  400   :  0110_0011  0x63   99  c  
  401   :  0110_1011  0x6B  107  k  
  402   :  0110_1000  0x68  104  h  
  403   :  0110_1111  0x6F  111  o  
  404   :  0110_1100  0x6C  108  l  
  405   :  0110_0101  0x65  101  e  
  406   :  0010_1110  0x2E   46  .  
  407   :  0111_0011  0x73  115  s  
  408   :  0111_0000  0x70  112  p  
  409   :  0110_0001  0x61   97  a  
  410   :  0110_1101  0x6D  109  m  
  411   :  0110_0011  0x63   99  c  
  412   :  0110_0001  0x61   97  a  
  413   :  0110_1110  0x6E  110  n  
  414   :  0110_1110  0x6E  110  n  
  415   :  0110_1001  0x69  105  i  
  416   :  0110_0010  0x62   98  b  
  417   :  0110_0001  0x61   97  a  
  418   :  0110_1100  0x6C  108  l  
  419   :  0010_1110  0x2E   46  .  
  420   :  0110_0011  0x63   99  c  
  421   :  0110_1111  0x6F  111  o  
  422   :  0110_1101  0x6D  109  m  
  423   :  1100_0000  0xC0  192    
  424   :  0000_1100  0x0C   12    
  425   :  0000_0000  0x00    0    
  426   :  0000_0110  0x06    6    
  427   :  0000_0000  0x00    0    
  428   :  0000_0001  0x01    1    
  429   :  0000_0000  0x00    0    
  430   :  0000_0000  0x00    0    
  431   :  0000_0000  0x00    0    
  432   :  0000_0000  0x00    0    
  433   :  0000_0000  0x00    0    
  434   :  0001_1000  0x18   24    
  435   :  1100_0000  0xC0  192    
  436   :  0010_0101  0x25   37  %  
  437   :  1100_0000  0xC0  192    
  438   :  0011_0001  0x31   49  1  
  439   :  0000_0111  0x07    7    
  440   :  0101_1011  0x5B   91  [  
  441   :  1100_0011  0xC3  195    
  442   :  0111_0001  0x71  113  q  
  443   :  0000_0000  0x00    0    
  444   :  0000_0000  0x00    0    
  445   :  1010_1000  0xA8  168    
  446   :  1100_0000  0xC0  192    
  447   :  0000_0000  0x00    0    
  448   :  0000_0000  0x00    0    
  449   :  0000_1110  0x0E   14    
  450   :  0001_0000  0x10   16    
  451   :  0000_0000  0x00    0    
  452   :  0000_0001  0x01    1    
  453   :  0101_0001  0x51   81  Q  
  454   :  1000_0000  0x80  128    
  455   :  0000_0000  0x00    0    
  456   :  0000_0000  0x00    0    
  457   :  0010_1010  0x2A   42  *  
  458   :  0011_0000  0x30   48  0  
|;
chk_exp(\$response[0],\$exptext);

## test 91      set AXFR block to 1
print "failed to set local name\nnot "
        unless  &{"${TCTEST}::t_cmdline"}('b',1);
&ok();

## test 92	check attempted IXFR while blocked, should be refused
$len = newhead(\$buffer,
	12345,
	BITS_QUERY,	# opcode
	1,0,0,0,	# one question
);
$len = $put->Question(\$buffer,$len,'bar.com',T_IXFR,C_IN);
($rv,$response) = dialog($buffer,$len);

#print_head(\$response);
#print_buf(\$buffer);
#print_buf(\$response);

$exptext = q|
  0     :  0011_0000  0x30   48  0  
  1     :  0011_1001  0x39   57  9  
  2     :  1000_0100  0x84  132    
  3     :  0000_0101  0x05    5    
  4     :  0000_0000  0x00    0    
  5     :  0000_0001  0x01    1    
  6     :  0000_0000  0x00    0    
  7     :  0000_0000  0x00    0    
  8     :  0000_0000  0x00    0    
  9     :  0000_0000  0x00    0    
  10    :  0000_0000  0x00    0    
  11    :  0000_0000  0x00    0    
  12    :  0000_0011  0x03    3    
  13    :  0110_0010  0x62   98  b  
  14    :  0110_0001  0x61   97  a  
  15    :  0111_0010  0x72  114  r  
  16    :  0000_0011  0x03    3    
  17    :  0110_0011  0x63   99  c  
  18    :  0110_1111  0x6F  111  o  
  19    :  0110_1101  0x6D  109  m  
  20    :  0000_0000  0x00    0    
  21    :  0000_0000  0x00    0    
  22    :  1111_1011  0xFB  251    
  23    :  0000_0000  0x00    0    
  24    :  0000_0001  0x01    1    
|;
chk_exp(\$response,\$exptext);

## test 93      set AXFR block to 0
print "failed to set local name\nnot "
        unless  &{"${TCTEST}::t_cmdline"}('b',0);
&ok();

# serial is 123454321 from test 50

## test 94	check IXFR no transfer, should get SOA
$len = newhead(\$buffer,
	12345,
	BITS_QUERY,	# opcode
	1,0,1,0,	# one question, one authority record
);
($len,my @dnptrs) = $put->Question(\$buffer,$len,'bar.com',T_IXFR,C_IN);
($len,@dnptrs) = $put->SOA(\$buffer,$len,\@dnptrs,'bar.com',1234,
	'unused.bar.com','notused.bar.com',123454321,1,2,3,4);
#print_buf(\$buffer);

($rv,$response) = dialog($buffer,$len);

#print_head(\$response);
#print_buf(\$buffer);
#print_buf(\$response);

$exptext = q|
  0     :  0011_0000  0x30   48  0  
  1     :  0011_1001  0x39   57  9  
  2     :  1000_0100  0x84  132    
  3     :  0000_0000  0x00    0    
  4     :  0000_0000  0x00    0    
  5     :  0000_0001  0x01    1    
  6     :  0000_0000  0x00    0    
  7     :  0000_0001  0x01    1    
  8     :  0000_0000  0x00    0    
  9     :  0000_0000  0x00    0    
  10    :  0000_0000  0x00    0    
  11    :  0000_0000  0x00    0    
  12    :  0000_0011  0x03    3    
  13    :  0110_0010  0x62   98  b  
  14    :  0110_0001  0x61   97  a  
  15    :  0111_0010  0x72  114  r  
  16    :  0000_0011  0x03    3    
  17    :  0110_0011  0x63   99  c  
  18    :  0110_1111  0x6F  111  o  
  19    :  0110_1101  0x6D  109  m  
  20    :  0000_0000  0x00    0    
  21    :  0000_0000  0x00    0    
  22    :  1111_1011  0xFB  251    
  23    :  0000_0000  0x00    0    
  24    :  0000_0001  0x01    1    
  25    :  1100_0000  0xC0  192    
  26    :  0000_1100  0x0C   12    
  27    :  0000_0000  0x00    0    
  28    :  0000_0110  0x06    6    
  29    :  0000_0000  0x00    0    
  30    :  0000_0001  0x01    1    
  31    :  0000_0000  0x00    0    
  32    :  0000_0000  0x00    0    
  33    :  0000_0000  0x00    0    
  34    :  0000_0000  0x00    0    
  35    :  0000_0000  0x00    0    
  36    :  0010_1000  0x28   40  (  
  37    :  0000_1001  0x09    9    
  38    :  0110_1100  0x6C  108  l  
  39    :  0110_1111  0x6F  111  o  
  40    :  0110_0011  0x63   99  c  
  41    :  0110_0001  0x61   97  a  
  42    :  0110_1100  0x6C  108  l  
  43    :  0110_1000  0x68  104  h  
  44    :  0110_1111  0x6F  111  o  
  45    :  0111_0011  0x73  115  s  
  46    :  0111_0100  0x74  116  t  
  47    :  1100_0000  0xC0  192    
  48    :  0000_1100  0x0C   12    
  49    :  0000_0101  0x05    5    
  50    :  0110_1000  0x68  104  h  
  51    :  0111_0101  0x75  117  u  
  52    :  0110_1101  0x6D  109  m  
  53    :  0110_0001  0x61   97  a  
  54    :  0110_1110  0x6E  110  n  
  55    :  1100_0000  0xC0  192    
  56    :  0000_1100  0x0C   12    
  57    :  0000_0111  0x07    7    
  58    :  0101_1011  0x5B   91  [  
  59    :  1100_0011  0xC3  195    
  60    :  0111_0001  0x71  113  q  
  61    :  0000_0000  0x00    0    
  62    :  0000_0000  0x00    0    
  63    :  1010_1000  0xA8  168    
  64    :  1100_0000  0xC0  192    
  65    :  0000_0000  0x00    0    
  66    :  0000_0000  0x00    0    
  67    :  0000_1110  0x0E   14    
  68    :  0001_0000  0x10   16    
  69    :  0000_0000  0x00    0    
  70    :  0000_0001  0x01    1    
  71    :  0101_0001  0x51   81  Q  
  72    :  1000_0000  0x80  128    
  73    :  0000_0000  0x00    0    
  74    :  0000_0000  0x00    0    
  75    :  0010_1010  0x2A   42  *  
  76    :  0011_0000  0x30   48  0  
|;
chk_exp(\$response,\$exptext);

## test 95	check IXFR no transfer, should get SOA, serial > server serial
$len = newhead(\$buffer,
	12345,
	BITS_QUERY,	# opcode
	1,0,1,0,	# one question, one authority record
);
($len,@dnptrs) = $put->Question(\$buffer,$len,'bar.com',T_IXFR,C_IN);
($len,@dnptrs) = $put->SOA(\$buffer,$len,\@dnptrs,'bar.com',1234,
	'unused.bar.com','notused.bar.com',123454322,1,2,3,4);
#print_buf(\$buffer);

($rv,$response) = dialog($buffer,$len);

#print_head(\$response);
#print_buf(\$buffer);
#print_buf(\$response);

chk_exp(\$response,\$exptext);  

## test 96	check IXFR no transfer, should get TC & FORMERR, but UDP

$len = newhead(\$buffer,
	12345,
	BITS_QUERY,	# opcode
	1,0,1,0,	# one question, one authority record
);
($len,@dnptrs) = $put->Question(\$buffer,$len,'bar.com',T_IXFR,C_IN);
($len,@dnptrs) = $put->SOA(\$buffer,$len,\@dnptrs,'bar.com',1234,
	'unused.bar.com','notused.bar.com',123454320,1,2,3,4);
#print_buf(\$buffer);

($rv,$response) = dialog($buffer,$len);

#print_head(\$response);
#print_buf(\$buffer);
#print_buf(\$response);

$exptext = q|
  0     :  0011_0000  0x30   48  0  
  1     :  0011_1001  0x39   57  9  
  2     :  1000_0110  0x86  134    
  3     :  0000_0001  0x01    1    
  4     :  0000_0000  0x00    0    
  5     :  0000_0001  0x01    1    
  6     :  0000_0000  0x00    0    
  7     :  0000_0000  0x00    0    
  8     :  0000_0000  0x00    0    
  9     :  0000_0000  0x00    0    
  10    :  0000_0000  0x00    0    
  11    :  0000_0000  0x00    0    
  12    :  0000_0011  0x03    3    
  13    :  0110_0010  0x62   98  b  
  14    :  0110_0001  0x61   97  a  
  15    :  0111_0010  0x72  114  r  
  16    :  0000_0011  0x03    3    
  17    :  0110_0011  0x63   99  c  
  18    :  0110_1111  0x6F  111  o  
  19    :  0110_1101  0x6D  109  m  
  20    :  0000_0000  0x00    0    
  21    :  0000_0000  0x00    0    
  22    :  1111_1011  0xFB  251    
  23    :  0000_0000  0x00    0    
  24    :  0000_0001  0x01    1    
|;
chk_exp(\$response,\$exptext);  

## test 97	# test with single packet for IXFR, normal mode
##		check known numeric A record using tcp mode
$len = newhead(\$buffer,
	12345,
	BITS_QUERY,	# opcode
	1,0,1,0,	# one question
);
($len,@dnptrs) = $put->Question(\$buffer,$len,'bar.com',T_IXFR,C_IN);
($len,@dnptrs) = $put->SOA(\$buffer,$len,\@dnptrs,'bar.com',1234,
	'unused.bar.com','notused.bar.com',123454320,1,2,3,4);
#print_buf(\$buffer);
$istcp = 1;		# expect 1 packet
$tcpmode = 1;
($rv,@response) = dialog($buffer,$len,0,$istcp,$tcpmode);	# read, +tcp

#print_buf(\$response[0]); print "\n";

$exptext = q|
  0     :  0011_0000  0x30   48  0  
  1     :  0011_1001  0x39   57  9  
  2     :  1000_0100  0x84  132    
  3     :  0000_0000  0x00    0    
  4     :  0000_0000  0x00    0    
  5     :  0000_0001  0x01    1    
  6     :  0000_0000  0x00    0    
  7     :  0000_1111  0x0F   15    
  8     :  0000_0000  0x00    0    
  9     :  0000_0000  0x00    0    
  10    :  0000_0000  0x00    0    
  11    :  0000_0000  0x00    0    
  12    :  0000_0011  0x03    3    
  13    :  0110_0010  0x62   98  b  
  14    :  0110_0001  0x61   97  a  
  15    :  0111_0010  0x72  114  r  
  16    :  0000_0011  0x03    3    
  17    :  0110_0011  0x63   99  c  
  18    :  0110_1111  0x6F  111  o  
  19    :  0110_1101  0x6D  109  m  
  20    :  0000_0000  0x00    0    
  21    :  0000_0000  0x00    0    
  22    :  1111_1011  0xFB  251    
  23    :  0000_0000  0x00    0    
  24    :  0000_0001  0x01    1    
  25    :  1100_0000  0xC0  192    
  26    :  0000_1100  0x0C   12    
  27    :  0000_0000  0x00    0    
  28    :  0000_0110  0x06    6    
  29    :  0000_0000  0x00    0    
  30    :  0000_0001  0x01    1    
  31    :  0000_0000  0x00    0    
  32    :  0000_0000  0x00    0    
  33    :  0000_0000  0x00    0    
  34    :  0000_0000  0x00    0    
  35    :  0000_0000  0x00    0    
  36    :  0010_1000  0x28   40  (  
  37    :  0000_1001  0x09    9    
  38    :  0110_1100  0x6C  108  l  
  39    :  0110_1111  0x6F  111  o  
  40    :  0110_0011  0x63   99  c  
  41    :  0110_0001  0x61   97  a  
  42    :  0110_1100  0x6C  108  l  
  43    :  0110_1000  0x68  104  h  
  44    :  0110_1111  0x6F  111  o  
  45    :  0111_0011  0x73  115  s  
  46    :  0111_0100  0x74  116  t  
  47    :  1100_0000  0xC0  192    
  48    :  0000_1100  0x0C   12    
  49    :  0000_0101  0x05    5    
  50    :  0110_1000  0x68  104  h  
  51    :  0111_0101  0x75  117  u  
  52    :  0110_1101  0x6D  109  m  
  53    :  0110_0001  0x61   97  a  
  54    :  0110_1110  0x6E  110  n  
  55    :  1100_0000  0xC0  192    
  56    :  0000_1100  0x0C   12    
  57    :  0000_0111  0x07    7    
  58    :  0101_1011  0x5B   91  [  
  59    :  1100_0011  0xC3  195    
  60    :  0111_0001  0x71  113  q  
  61    :  0000_0000  0x00    0    
  62    :  0000_0000  0x00    0    
  63    :  1010_1000  0xA8  168    
  64    :  1100_0000  0xC0  192    
  65    :  0000_0000  0x00    0    
  66    :  0000_0000  0x00    0    
  67    :  0000_1110  0x0E   14    
  68    :  0001_0000  0x10   16    
  69    :  0000_0000  0x00    0    
  70    :  0000_0001  0x01    1    
  71    :  0101_0001  0x51   81  Q  
  72    :  1000_0000  0x80  128    
  73    :  0000_0000  0x00    0    
  74    :  0000_0000  0x00    0    
  75    :  0010_1010  0x2A   42  *  
  76    :  0011_0000  0x30   48  0  
  77    :  1100_0000  0xC0  192    
  78    :  0000_1100  0x0C   12    
  79    :  0000_0000  0x00    0    
  80    :  0000_0010  0x02    2    
  81    :  0000_0000  0x00    0    
  82    :  0000_0001  0x01    1    
  83    :  0000_0000  0x00    0    
  84    :  0000_0000  0x00    0    
  85    :  0010_1010  0x2A   42  *  
  86    :  0011_0000  0x30   48  0  
  87    :  0000_0000  0x00    0    
  88    :  0000_1010  0x0A   10    
  89    :  0000_0011  0x03    3    
  90    :  0110_1110  0x6E  110  n  
  91    :  0111_0011  0x73  115  s  
  92    :  0011_0001  0x31   49  1  
  93    :  0000_0011  0x03    3    
  94    :  0111_1000  0x78  120  x  
  95    :  0111_1001  0x79  121  y  
  96    :  0111_1010  0x7A  122  z  
  97    :  1100_0000  0xC0  192    
  98    :  0001_0000  0x10   16    
  99    :  1100_0000  0xC0  192    
  100   :  0000_1100  0x0C   12    
  101   :  0000_0000  0x00    0    
  102   :  0000_0010  0x02    2    
  103   :  0000_0000  0x00    0    
  104   :  0000_0001  0x01    1    
  105   :  0000_0000  0x00    0    
  106   :  0000_0000  0x00    0    
  107   :  0010_1010  0x2A   42  *  
  108   :  0011_0000  0x30   48  0  
  109   :  0000_0000  0x00    0    
  110   :  0000_0110  0x06    6    
  111   :  0000_0011  0x03    3    
  112   :  0110_1110  0x6E  110  n  
  113   :  0111_0011  0x73  115  s  
  114   :  0011_0010  0x32   50  2  
  115   :  1100_0000  0xC0  192    
  116   :  0000_1100  0x0C   12    
  117   :  1100_0000  0xC0  192    
  118   :  0000_1100  0x0C   12    
  119   :  0000_0000  0x00    0    
  120   :  0000_0010  0x02    2    
  121   :  0000_0000  0x00    0    
  122   :  0000_0001  0x01    1    
  123   :  0000_0000  0x00    0    
  124   :  0000_0000  0x00    0    
  125   :  0010_1010  0x2A   42  *  
  126   :  0011_0000  0x30   48  0  
  127   :  0000_0000  0x00    0    
  128   :  0000_0010  0x02    2    
  129   :  1100_0000  0xC0  192    
  130   :  0000_1100  0x0C   12    
  131   :  1100_0000  0xC0  192    
  132   :  0000_1100  0x0C   12    
  133   :  0000_0000  0x00    0    
  134   :  0000_1111  0x0F   15    
  135   :  0000_0000  0x00    0    
  136   :  0000_0001  0x01    1    
  137   :  0000_0000  0x00    0    
  138   :  0000_0000  0x00    0    
  139   :  0010_1010  0x2A   42  *  
  140   :  0011_0000  0x30   48  0  
  141   :  0000_0000  0x00    0    
  142   :  0000_0100  0x04    4    
  143   :  0000_0000  0x00    0    
  144   :  0011_0010  0x32   50  2  
  145   :  1100_0000  0xC0  192    
  146   :  0000_1100  0x0C   12    
  147   :  1100_0000  0xC0  192    
  148   :  0000_1100  0x0C   12    
  149   :  0000_0000  0x00    0    
  150   :  0000_1111  0x0F   15    
  151   :  0000_0000  0x00    0    
  152   :  0000_0001  0x01    1    
  153   :  0000_0000  0x00    0    
  154   :  0000_0000  0x00    0    
  155   :  0010_1010  0x2A   42  *  
  156   :  0011_0000  0x30   48  0  
  157   :  0000_0000  0x00    0    
  158   :  0000_0111  0x07    7    
  159   :  0000_0000  0x00    0    
  160   :  0000_1010  0x0A   10    
  161   :  0000_0010  0x02    2    
  162   :  0110_1101  0x6D  109  m  
  163   :  0111_1000  0x78  120  x  
  164   :  1100_0000  0xC0  192    
  165   :  0000_1100  0x0C   12    
  166   :  1100_0000  0xC0  192    
  167   :  0110_1111  0x6F  111  o  
  168   :  0000_0000  0x00    0    
  169   :  0000_0001  0x01    1    
  170   :  0000_0000  0x00    0    
  171   :  0000_0001  0x01    1    
  172   :  0000_0000  0x00    0    
  173   :  0000_0000  0x00    0    
  174   :  0010_1010  0x2A   42  *  
  175   :  0011_0000  0x30   48  0  
  176   :  0000_0000  0x00    0    
  177   :  0000_0100  0x04    4    
  178   :  0100_1100  0x4C   76  L  
  179   :  0011_0110  0x36   54  6  
  180   :  0010_0000  0x20   32     
  181   :  0000_1010  0x0A   10    
  182   :  1100_0000  0xC0  192    
  183   :  0000_1100  0x0C   12    
  184   :  0000_0000  0x00    0    
  185   :  0000_0001  0x01    1    
  186   :  0000_0000  0x00    0    
  187   :  0000_0001  0x01    1    
  188   :  0000_0000  0x00    0    
  189   :  0000_0000  0x00    0    
  190   :  0010_1010  0x2A   42  *  
  191   :  0011_0000  0x30   48  0  
  192   :  0000_0000  0x00    0    
  193   :  0000_0100  0x04    4    
  194   :  0000_0001  0x01    1    
  195   :  0000_0010  0x02    2    
  196   :  0000_0011  0x03    3    
  197   :  0000_0100  0x04    4    
  198   :  1100_0000  0xC0  192    
  199   :  1010_0001  0xA1  161    
  200   :  0000_0000  0x00    0    
  201   :  0000_0001  0x01    1    
  202   :  0000_0000  0x00    0    
  203   :  0000_0001  0x01    1    
  204   :  0000_0000  0x00    0    
  205   :  0000_0000  0x00    0    
  206   :  0010_1010  0x2A   42  *  
  207   :  0011_0000  0x30   48  0  
  208   :  0000_0000  0x00    0    
  209   :  0000_0100  0x04    4    
  210   :  0110_0101  0x65  101  e  
  211   :  1100_1010  0xCA  202    
  212   :  0110_0111  0x67  103  g  
  213   :  0010_1100  0x2C   44  ,  
  214   :  1100_0000  0xC0  192    
  215   :  0000_1100  0x0C   12    
  216   :  0000_0000  0x00    0    
  217   :  0000_0001  0x01    1    
  218   :  0000_0000  0x00    0    
  219   :  0000_0001  0x01    1    
  220   :  0000_0000  0x00    0    
  221   :  0000_0000  0x00    0    
  222   :  0010_1010  0x2A   42  *  
  223   :  0011_0000  0x30   48  0  
  224   :  0000_0000  0x00    0    
  225   :  0000_0100  0x04    4    
  226   :  1100_0000  0xC0  192    
  227   :  1010_1000  0xA8  168    
  228   :  0110_0011  0x63   99  c  
  229   :  0110_0100  0x64  100  d  
  230   :  0000_0001  0x01    1    
  231   :  0011_0001  0x31   49  1  
  232   :  0000_0001  0x01    1    
  233   :  0011_0010  0x32   50  2  
  234   :  0000_0001  0x01    1    
  235   :  0011_0011  0x33   51  3  
  236   :  0000_0001  0x01    1    
  237   :  0011_0100  0x34   52  4  
  238   :  1100_0000  0xC0  192    
  239   :  0000_1100  0x0C   12    
  240   :  0000_0000  0x00    0    
  241   :  0000_0001  0x01    1    
  242   :  0000_0000  0x00    0    
  243   :  0000_0001  0x01    1    
  244   :  0000_0000  0x00    0    
  245   :  0000_0000  0x00    0    
  246   :  0010_1010  0x2A   42  *  
  247   :  0011_0000  0x30   48  0  
  248   :  0000_0000  0x00    0    
  249   :  0000_0100  0x04    4    
  250   :  0111_1111  0x7F  127    
  251   :  0000_0000  0x00    0    
  252   :  0000_0000  0x00    0    
  253   :  0000_0010  0x02    2    
  254   :  1100_0000  0xC0  192    
  255   :  1110_0110  0xE6  230    
  256   :  0000_0000  0x00    0    
  257   :  0001_0000  0x10   16    
  258   :  0000_0000  0x00    0    
  259   :  0000_0001  0x01    1    
  260   :  0000_0000  0x00    0    
  261   :  0000_0000  0x00    0    
  262   :  0010_1010  0x2A   42  *  
  263   :  0011_0000  0x30   48  0  
  264   :  0000_0000  0x00    0    
  265   :  0010_0010  0x22   34  "  
  266   :  0010_0001  0x21   33  !  
  267   :  0100_0001  0x41   65  A  
  268   :  0110_1100  0x6C  108  l  
  269   :  0111_0100  0x74  116  t  
  270   :  0110_0101  0x65  101  e  
  271   :  0111_0010  0x72  114  r  
  272   :  0110_1110  0x6E  110  n  
  273   :  0110_0001  0x61   97  a  
  274   :  0111_0100  0x74  116  t  
  275   :  0110_0101  0x65  101  e  
  276   :  0010_0000  0x20   32     
  277   :  0100_0101  0x45   69  E  
  278   :  0111_0010  0x72  114  r  
  279   :  0111_0010  0x72  114  r  
  280   :  0110_1111  0x6F  111  o  
  281   :  0111_0010  0x72  114  r  
  282   :  0011_1010  0x3A   58  :  
  283   :  0010_0000  0x20   32     
  284   :  0110_0110  0x66  102  f  
  285   :  0111_0010  0x72  114  r  
  286   :  0110_1111  0x6F  111  o  
  287   :  0110_1101  0x6D  109  m  
  288   :  0010_0000  0x20   32     
  289   :  0110_0001  0x61   97  a  
  290   :  0110_1110  0x6E  110  n  
  291   :  0110_1111  0x6F  111  o  
  292   :  0111_0100  0x74  116  t  
  293   :  0110_1000  0x68  104  h  
  294   :  0110_0101  0x65  101  e  
  295   :  0111_0010  0x72  114  r  
  296   :  0010_0000  0x20   32     
  297   :  0101_0010  0x52   82  R  
  298   :  0100_0010  0x42   66  B  
  299   :  0100_1100  0x4C   76  L  
  300   :  0000_0010  0x02    2    
  301   :  0011_1000  0x38   56  8  
  302   :  0011_1001  0x39   57  9  
  303   :  0000_0010  0x02    2    
  304   :  0011_1000  0x38   56  8  
  305   :  0011_1000  0x38   56  8  
  306   :  0000_0010  0x02    2    
  307   :  0011_1000  0x38   56  8  
  308   :  0011_0111  0x37   55  7  
  309   :  0000_0010  0x02    2    
  310   :  0011_1000  0x38   56  8  
  311   :  0011_0110  0x36   54  6  
  312   :  1100_0000  0xC0  192    
  313   :  0000_1100  0x0C   12    
  314   :  0000_0000  0x00    0    
  315   :  0000_0001  0x01    1    
  316   :  0000_0000  0x00    0    
  317   :  0000_0001  0x01    1    
  318   :  0000_0000  0x00    0    
  319   :  0000_0000  0x00    0    
  320   :  0010_1010  0x2A   42  *  
  321   :  0011_0000  0x30   48  0  
  322   :  0000_0000  0x00    0    
  323   :  0000_0100  0x04    4    
  324   :  0111_1111  0x7F  127    
  325   :  0000_0000  0x00    0    
  326   :  0000_0000  0x00    0    
  327   :  0000_0003  0x03    3    
  328   :  1100_0001  0xC1  193    
  329   :  0010_1100  0x2C   44  ,  
  330   :  0000_0000  0x00    0    
  331   :  0001_0000  0x10   16    
  332   :  0000_0000  0x00    0    
  333   :  0000_0001  0x01    1    
  334   :  0000_0000  0x00    0    
  335   :  0000_0000  0x00    0    
  336   :  0010_1010  0x2A   42  *  
  337   :  0011_0000  0x30   48  0  
  338   :  0000_0000  0x00    0    
  339   :  0101_0011  0x53   83  S  
  340   :  0101_0010  0x52   82  R  
  341   :  0100_0101  0x45   69  E  
  342   :  0111_0010  0x72  114  r  
  343   :  0111_0010  0x72  114  r  
  344   :  0110_1111  0x6F  111  o  
  345   :  0111_0010  0x72  114  r  
  346   :  0011_1010  0x3A   58  :  
  347   :  0010_0000  0x20   32     
  348   :  0111_1001  0x79  121  y  
  349   :  0110_1111  0x6F  111  o  
  350   :  0111_0101  0x75  117  u  
  351   :  0111_0010  0x72  114  r  
  352   :  0010_0000  0x20   32     
  353   :  0110_1101  0x6D  109  m  
  354   :  0110_0001  0x61   97  a  
  355   :  0110_1001  0x69  105  i  
  356   :  0110_1100  0x6C  108  l  
  357   :  0010_0000  0x20   32     
  358   :  0111_0011  0x73  115  s  
  359   :  0110_0101  0x65  101  e  
  360   :  0111_0010  0x72  114  r  
  361   :  0111_0110  0x76  118  v  
  362   :  0110_0101  0x65  101  e  
  363   :  0111_0010  0x72  114  r  
  364   :  0010_0000  0x20   32     
  365   :  0110_1000  0x68  104  h  
  366   :  0110_0001  0x61   97  a  
  367   :  0111_0011  0x73  115  s  
  368   :  0010_0000  0x20   32     
  369   :  0110_0010  0x62   98  b  
  370   :  0110_0101  0x65  101  e  
  371   :  0110_0101  0x65  101  e  
  372   :  0110_1110  0x6E  110  n  
  373   :  0010_0000  0x20   32     
  374   :  0100_0010  0x42   66  B  
  375   :  0100_1100  0x4C   76  L  
  376   :  0100_0001  0x41   65  A  
  377   :  0100_0011  0x43   67  C  
  378   :  0100_1011  0x4B   75  K  
  379   :  0100_1000  0x48   72  H  
  380   :  0100_1111  0x4F   79  O  
  381   :  0100_1100  0x4C   76  L  
  382   :  0100_0101  0x45   69  E  
  383   :  0100_0100  0x44   68  D  
  384   :  0010_1110  0x2E   46  .  
  385   :  0010_0000  0x20   32     
  386   :  0101_0011  0x53   83  S  
  387   :  0110_0101  0x65  101  e  
  388   :  0110_0101  0x65  101  e  
  389   :  0010_0000  0x20   32     
  390   :  0110_1000  0x68  104  h  
  391   :  0111_0100  0x74  116  t  
  392   :  0111_0100  0x74  116  t  
  393   :  0111_0000  0x70  112  p  
  394   :  0011_1010  0x3A   58  :  
  395   :  0010_1111  0x2F   47  /  
  396   :  0010_1111  0x2F   47  /  
  397   :  0110_0010  0x62   98  b  
  398   :  0110_1100  0x6C  108  l  
  399   :  0110_0001  0x61   97  a  
  400   :  0110_0011  0x63   99  c  
  401   :  0110_1011  0x6B  107  k  
  402   :  0110_1000  0x68  104  h  
  403   :  0110_1111  0x6F  111  o  
  404   :  0110_1100  0x6C  108  l  
  405   :  0110_0101  0x65  101  e  
  406   :  0010_1110  0x2E   46  .  
  407   :  0111_0011  0x73  115  s  
  408   :  0111_0000  0x70  112  p  
  409   :  0110_0001  0x61   97  a  
  410   :  0110_1101  0x6D  109  m  
  411   :  0110_0011  0x63   99  c  
  412   :  0110_0001  0x61   97  a  
  413   :  0110_1110  0x6E  110  n  
  414   :  0110_1110  0x6E  110  n  
  415   :  0110_1001  0x69  105  i  
  416   :  0110_0010  0x62   98  b  
  417   :  0110_0001  0x61   97  a  
  418   :  0110_1100  0x6C  108  l  
  419   :  0010_1110  0x2E   46  .  
  420   :  0110_0011  0x63   99  c  
  421   :  0110_1111  0x6F  111  o  
  422   :  0110_1101  0x6D  109  m  
  423   :  1100_0000  0xC0  192    
  424   :  0000_1100  0x0C   12    
  425   :  0000_0000  0x00    0    
  426   :  0000_0110  0x06    6    
  427   :  0000_0000  0x00    0    
  428   :  0000_0001  0x01    1    
  429   :  0000_0000  0x00    0    
  430   :  0000_0000  0x00    0    
  431   :  0000_0000  0x00    0    
  432   :  0000_0000  0x00    0    
  433   :  0000_0000  0x00    0    
  434   :  0001_1000  0x18   24    
  435   :  1100_0000  0xC0  192    
  436   :  0010_0101  0x25   37  %  
  437   :  1100_0000  0xC0  192    
  438   :  0011_0001  0x31   49  1  
  439   :  0000_0111  0x07    7    
  440   :  0101_1011  0x5B   91  [  
  441   :  1100_0011  0xC3  195    
  442   :  0111_0001  0x71  113  q  
  443   :  0000_0000  0x00    0    
  444   :  0000_0000  0x00    0    
  445   :  1010_1000  0xA8  168    
  446   :  1100_0000  0xC0  192    
  447   :  0000_0000  0x00    0    
  448   :  0000_0000  0x00    0    
  449   :  0000_1110  0x0E   14    
  450   :  0001_0000  0x10   16    
  451   :  0000_0000  0x00    0    
  452   :  0000_0001  0x01    1    
  453   :  0101_0001  0x51   81  Q  
  454   :  1000_0000  0x80  128    
  455   :  0000_0000  0x00    0    
  456   :  0000_0000  0x00    0    
  457   :  0010_1010  0x2A   42  *  
  458   :  0011_0000  0x30   48  0  
|;
chk_exp(\$response[0],\$exptext);

## test 98	check for append of ip address to TXT record
&{"${TCTEST}::t_set_qflag"}(1);	# set question mark flag
## repeat test 97	check known numeric A record using tcp mode
$len = newhead(\$buffer,
	12345,
	BITS_QUERY,	# opcode
	1,0,1,0,	# one question
);
($len,@dnptrs) = $put->Question(\$buffer,$len,'bar.com',T_IXFR,C_IN);
($len,@dnptrs) = $put->SOA(\$buffer,$len,\@dnptrs,'bar.com',1234,
	'unused.bar.com','notused.bar.com',123454320,1,2,3,4);
#print_buf(\$buffer);
$istcp = 1;		# expect 1 packet
$tcpmode = 1;
($rv,@response) = dialog($buffer,$len,0,$istcp,$tcpmode);	# read, +tcp

#print_buf(\$response[0]); print "\n";

$exptext = q|
  0	:  0011_0000  0x30   48  0  
  1	:  0011_1001  0x39   57  9  
  2	:  1000_0100  0x84  132    
  3	:  0000_0000  0x00    0    
  4	:  0000_0000  0x00    0    
  5	:  0000_0001  0x01    1    
  6	:  0000_0000  0x00    0    
  7	:  0000_1111  0x0F   15    
  8	:  0000_0000  0x00    0    
  9	:  0000_0000  0x00    0    
  10	:  0000_0000  0x00    0    
  11	:  0000_0000  0x00    0    
  12	:  0000_0011  0x03    3    
  13	:  0110_0010  0x62   98  b  
  14	:  0110_0001  0x61   97  a  
  15	:  0111_0010  0x72  114  r  
  16	:  0000_0011  0x03    3    
  17	:  0110_0011  0x63   99  c  
  18	:  0110_1111  0x6F  111  o  
  19	:  0110_1101  0x6D  109  m  
  20	:  0000_0000  0x00    0    
  21	:  0000_0000  0x00    0    
  22	:  1111_1011  0xFB  251    
  23	:  0000_0000  0x00    0    
  24	:  0000_0001  0x01    1    
  25	:  1100_0000  0xC0  192    
  26	:  0000_1100  0x0C   12    
  27	:  0000_0000  0x00    0    
  28	:  0000_0110  0x06    6    
  29	:  0000_0000  0x00    0    
  30	:  0000_0001  0x01    1    
  31	:  0000_0000  0x00    0    
  32	:  0000_0000  0x00    0    
  33	:  0000_0000  0x00    0    
  34	:  0000_0000  0x00    0    
  35	:  0000_0000  0x00    0    
  36	:  0010_1000  0x28   40  (  
  37	:  0000_1001  0x09    9    
  38	:  0110_1100  0x6C  108  l  
  39	:  0110_1111  0x6F  111  o  
  40	:  0110_0011  0x63   99  c  
  41	:  0110_0001  0x61   97  a  
  42	:  0110_1100  0x6C  108  l  
  43	:  0110_1000  0x68  104  h  
  44	:  0110_1111  0x6F  111  o  
  45	:  0111_0011  0x73  115  s  
  46	:  0111_0100  0x74  116  t  
  47	:  1100_0000  0xC0  192    
  48	:  0000_1100  0x0C   12    
  49	:  0000_0101  0x05    5    
  50	:  0110_1000  0x68  104  h  
  51	:  0111_0101  0x75  117  u  
  52	:  0110_1101  0x6D  109  m  
  53	:  0110_0001  0x61   97  a  
  54	:  0110_1110  0x6E  110  n  
  55	:  1100_0000  0xC0  192    
  56	:  0000_1100  0x0C   12    
  57	:  0000_0111  0x07    7    
  58	:  0101_1011  0x5B   91  [  
  59	:  1100_0011  0xC3  195    
  60	:  0111_0001  0x71  113  q  
  61	:  0000_0000  0x00    0    
  62	:  0000_0000  0x00    0    
  63	:  1010_1000  0xA8  168    
  64	:  1100_0000  0xC0  192    
  65	:  0000_0000  0x00    0    
  66	:  0000_0000  0x00    0    
  67	:  0000_1110  0x0E   14    
  68	:  0001_0000  0x10   16    
  69	:  0000_0000  0x00    0    
  70	:  0000_0001  0x01    1    
  71	:  0101_0001  0x51   81  Q  
  72	:  1000_0000  0x80  128    
  73	:  0000_0000  0x00    0    
  74	:  0000_0000  0x00    0    
  75	:  0010_1010  0x2A   42  *  
  76	:  0011_0000  0x30   48  0  
  77	:  1100_0000  0xC0  192    
  78	:  0000_1100  0x0C   12    
  79	:  0000_0000  0x00    0    
  80	:  0000_0010  0x02    2    
  81	:  0000_0000  0x00    0    
  82	:  0000_0001  0x01    1    
  83	:  0000_0000  0x00    0    
  84	:  0000_0000  0x00    0    
  85	:  0010_1010  0x2A   42  *  
  86	:  0011_0000  0x30   48  0  
  87	:  0000_0000  0x00    0    
  88	:  0000_1010  0x0A   10    
  89	:  0000_0011  0x03    3    
  90	:  0110_1110  0x6E  110  n  
  91	:  0111_0011  0x73  115  s  
  92	:  0011_0001  0x31   49  1  
  93	:  0000_0011  0x03    3    
  94	:  0111_1000  0x78  120  x  
  95	:  0111_1001  0x79  121  y  
  96	:  0111_1010  0x7A  122  z  
  97	:  1100_0000  0xC0  192    
  98	:  0001_0000  0x10   16    
  99	:  1100_0000  0xC0  192    
  100	:  0000_1100  0x0C   12    
  101	:  0000_0000  0x00    0    
  102	:  0000_0010  0x02    2    
  103	:  0000_0000  0x00    0    
  104	:  0000_0001  0x01    1    
  105	:  0000_0000  0x00    0    
  106	:  0000_0000  0x00    0    
  107	:  0010_1010  0x2A   42  *  
  108	:  0011_0000  0x30   48  0  
  109	:  0000_0000  0x00    0    
  110	:  0000_0110  0x06    6    
  111	:  0000_0011  0x03    3    
  112	:  0110_1110  0x6E  110  n  
  113	:  0111_0011  0x73  115  s  
  114	:  0011_0010  0x32   50  2  
  115	:  1100_0000  0xC0  192    
  116	:  0000_1100  0x0C   12    
  117	:  1100_0000  0xC0  192    
  118	:  0000_1100  0x0C   12    
  119	:  0000_0000  0x00    0    
  120	:  0000_0010  0x02    2    
  121	:  0000_0000  0x00    0    
  122	:  0000_0001  0x01    1    
  123	:  0000_0000  0x00    0    
  124	:  0000_0000  0x00    0    
  125	:  0010_1010  0x2A   42  *  
  126	:  0011_0000  0x30   48  0  
  127	:  0000_0000  0x00    0    
  128	:  0000_0010  0x02    2    
  129	:  1100_0000  0xC0  192    
  130	:  0000_1100  0x0C   12    
  131	:  1100_0000  0xC0  192    
  132	:  0000_1100  0x0C   12    
  133	:  0000_0000  0x00    0    
  134	:  0000_1111  0x0F   15    
  135	:  0000_0000  0x00    0    
  136	:  0000_0001  0x01    1    
  137	:  0000_0000  0x00    0    
  138	:  0000_0000  0x00    0    
  139	:  0010_1010  0x2A   42  *  
  140	:  0011_0000  0x30   48  0  
  141	:  0000_0000  0x00    0    
  142	:  0000_0100  0x04    4    
  143	:  0000_0000  0x00    0    
  144	:  0011_0010  0x32   50  2  
  145	:  1100_0000  0xC0  192    
  146	:  0000_1100  0x0C   12    
  147	:  1100_0000  0xC0  192    
  148	:  0000_1100  0x0C   12    
  149	:  0000_0000  0x00    0    
  150	:  0000_1111  0x0F   15    
  151	:  0000_0000  0x00    0    
  152	:  0000_0001  0x01    1    
  153	:  0000_0000  0x00    0    
  154	:  0000_0000  0x00    0    
  155	:  0010_1010  0x2A   42  *  
  156	:  0011_0000  0x30   48  0  
  157	:  0000_0000  0x00    0    
  158	:  0000_0111  0x07    7    
  159	:  0000_0000  0x00    0    
  160	:  0000_1010  0x0A   10    
  161	:  0000_0010  0x02    2    
  162	:  0110_1101  0x6D  109  m  
  163	:  0111_1000  0x78  120  x  
  164	:  1100_0000  0xC0  192    
  165	:  0000_1100  0x0C   12    
  166	:  1100_0000  0xC0  192    
  167	:  0110_1111  0x6F  111  o  
  168	:  0000_0000  0x00    0    
  169	:  0000_0001  0x01    1    
  170	:  0000_0000  0x00    0    
  171	:  0000_0001  0x01    1    
  172	:  0000_0000  0x00    0    
  173	:  0000_0000  0x00    0    
  174	:  0010_1010  0x2A   42  *  
  175	:  0011_0000  0x30   48  0  
  176	:  0000_0000  0x00    0    
  177	:  0000_0100  0x04    4    
  178	:  0100_1100  0x4C   76  L  
  179	:  0011_0110  0x36   54  6  
  180	:  0010_0000  0x20   32     
  181	:  0000_1010  0x0A   10    
  182	:  1100_0000  0xC0  192    
  183	:  0000_1100  0x0C   12    
  184	:  0000_0000  0x00    0    
  185	:  0000_0001  0x01    1    
  186	:  0000_0000  0x00    0    
  187	:  0000_0001  0x01    1    
  188	:  0000_0000  0x00    0    
  189	:  0000_0000  0x00    0    
  190	:  0010_1010  0x2A   42  *  
  191	:  0011_0000  0x30   48  0  
  192	:  0000_0000  0x00    0    
  193	:  0000_0100  0x04    4    
  194	:  0000_0001  0x01    1    
  195	:  0000_0010  0x02    2    
  196	:  0000_0011  0x03    3    
  197	:  0000_0100  0x04    4    
  198	:  1100_0000  0xC0  192    
  199	:  1010_0001  0xA1  161    
  200	:  0000_0000  0x00    0    
  201	:  0000_0001  0x01    1    
  202	:  0000_0000  0x00    0    
  203	:  0000_0001  0x01    1    
  204	:  0000_0000  0x00    0    
  205	:  0000_0000  0x00    0    
  206	:  0010_1010  0x2A   42  *  
  207	:  0011_0000  0x30   48  0  
  208	:  0000_0000  0x00    0    
  209	:  0000_0100  0x04    4    
  210	:  0110_0101  0x65  101  e  
  211	:  1100_1010  0xCA  202    
  212	:  0110_0111  0x67  103  g  
  213	:  0010_1100  0x2C   44  ,  
  214	:  1100_0000  0xC0  192    
  215	:  0000_1100  0x0C   12    
  216	:  0000_0000  0x00    0    
  217	:  0000_0001  0x01    1    
  218	:  0000_0000  0x00    0    
  219	:  0000_0001  0x01    1    
  220	:  0000_0000  0x00    0    
  221	:  0000_0000  0x00    0    
  222	:  0010_1010  0x2A   42  *  
  223	:  0011_0000  0x30   48  0  
  224	:  0000_0000  0x00    0    
  225	:  0000_0100  0x04    4    
  226	:  1100_0000  0xC0  192    
  227	:  1010_1000  0xA8  168    
  228	:  0110_0011  0x63   99  c  
  229	:  0110_0100  0x64  100  d  
  230	:  0000_0001  0x01    1    
  231	:  0011_0001  0x31   49  1  
  232	:  0000_0001  0x01    1    
  233	:  0011_0010  0x32   50  2  
  234	:  0000_0001  0x01    1    
  235	:  0011_0011  0x33   51  3  
  236	:  0000_0001  0x01    1    
  237	:  0011_0100  0x34   52  4  
  238	:  1100_0000  0xC0  192    
  239	:  0000_1100  0x0C   12    
  240	:  0000_0000  0x00    0    
  241	:  0000_0001  0x01    1    
  242	:  0000_0000  0x00    0    
  243	:  0000_0001  0x01    1    
  244	:  0000_0000  0x00    0    
  245	:  0000_0000  0x00    0    
  246	:  0010_1010  0x2A   42  *  
  247	:  0011_0000  0x30   48  0  
  248	:  0000_0000  0x00    0    
  249	:  0000_0100  0x04    4    
  250	:  0111_1111  0x7F  127    
  251	:  0000_0000  0x00    0    
  252	:  0000_0000  0x00    0    
  253	:  0000_0010  0x02    2    
  254	:  1100_0000  0xC0  192    
  255	:  1110_0110  0xE6  230    
  256	:  0000_0000  0x00    0    
  257	:  0001_0000  0x10   16    
  258	:  0000_0000  0x00    0    
  259	:  0000_0001  0x01    1    
  260	:  0000_0000  0x00    0    
  261	:  0000_0000  0x00    0    
  262	:  0010_1010  0x2A   42  *  
  263	:  0011_0000  0x30   48  0  
  264	:  0000_0000  0x00    0    
  265	:  0010_0010  0x22   34  "  
  266	:  0010_0001  0x21   33  !  
  267	:  0100_0001  0x41   65  A  
  268	:  0110_1100  0x6C  108  l  
  269	:  0111_0100  0x74  116  t  
  270	:  0110_0101  0x65  101  e  
  271	:  0111_0010  0x72  114  r  
  272	:  0110_1110  0x6E  110  n  
  273	:  0110_0001  0x61   97  a  
  274	:  0111_0100  0x74  116  t  
  275	:  0110_0101  0x65  101  e  
  276	:  0010_0000  0x20   32     
  277	:  0100_0101  0x45   69  E  
  278	:  0111_0010  0x72  114  r  
  279	:  0111_0010  0x72  114  r  
  280	:  0110_1111  0x6F  111  o  
  281	:  0111_0010  0x72  114  r  
  282	:  0011_1010  0x3A   58  :  
  283	:  0010_0000  0x20   32     
  284	:  0110_0110  0x66  102  f  
  285	:  0111_0010  0x72  114  r  
  286	:  0110_1111  0x6F  111  o  
  287	:  0110_1101  0x6D  109  m  
  288	:  0010_0000  0x20   32     
  289	:  0110_0001  0x61   97  a  
  290	:  0110_1110  0x6E  110  n  
  291	:  0110_1111  0x6F  111  o  
  292	:  0111_0100  0x74  116  t  
  293	:  0110_1000  0x68  104  h  
  294	:  0110_0101  0x65  101  e  
  295	:  0111_0010  0x72  114  r  
  296	:  0010_0000  0x20   32     
  297	:  0101_0010  0x52   82  R  
  298	:  0100_0010  0x42   66  B  
  299	:  0100_1100  0x4C   76  L  
  300	:  0000_0010  0x02    2    
  301	:  0011_1000  0x38   56  8  
  302	:  0011_1001  0x39   57  9  
  303	:  0000_0010  0x02    2    
  304	:  0011_1000  0x38   56  8  
  305	:  0011_1000  0x38   56  8  
  306	:  0000_0010  0x02    2    
  307	:  0011_1000  0x38   56  8  
  308	:  0011_0111  0x37   55  7  
  309	:  0000_0010  0x02    2    
  310	:  0011_1000  0x38   56  8  
  311	:  0011_0110  0x36   54  6  
  312	:  1100_0000  0xC0  192    
  313	:  0000_1100  0x0C   12    
  314	:  0000_0000  0x00    0    
  315	:  0000_0001  0x01    1    
  316	:  0000_0000  0x00    0    
  317	:  0000_0001  0x01    1    
  318	:  0000_0000  0x00    0    
  319	:  0000_0000  0x00    0    
  320	:  0010_1010  0x2A   42  *  
  321	:  0011_0000  0x30   48  0  
  322	:  0000_0000  0x00    0    
  323	:  0000_0100  0x04    4    
  324	:  0111_1111  0x7F  127    
  325	:  0000_0000  0x00    0    
  326	:  0000_0000  0x00    0    
  327	:  0000_0011  0x03    3    
  328	:  1100_0001  0xC1  193    
  329	:  0010_1100  0x2C   44  ,  
  330	:  0000_0000  0x00    0    
  331	:  0001_0000  0x10   16    
  332	:  0000_0000  0x00    0    
  333	:  0000_0001  0x01    1    
  334	:  0000_0000  0x00    0    
  335	:  0000_0000  0x00    0    
  336	:  0010_1010  0x2A   42  *  
  337	:  0011_0000  0x30   48  0  
  338	:  0000_0000  0x00    0    
  339	:  0101_1110  0x5E   94  ^  
  340	:  0101_1101  0x5D   93  ]  
  341	:  0100_0101  0x45   69  E  
  342	:  0111_0010  0x72  114  r  
  343	:  0111_0010  0x72  114  r  
  344	:  0110_1111  0x6F  111  o  
  345	:  0111_0010  0x72  114  r  
  346	:  0011_1010  0x3A   58  :  
  347	:  0010_0000  0x20   32     
  348	:  0111_1001  0x79  121  y  
  349	:  0110_1111  0x6F  111  o  
  350	:  0111_0101  0x75  117  u  
  351	:  0111_0010  0x72  114  r  
  352	:  0010_0000  0x20   32     
  353	:  0110_1101  0x6D  109  m  
  354	:  0110_0001  0x61   97  a  
  355	:  0110_1001  0x69  105  i  
  356	:  0110_1100  0x6C  108  l  
  357	:  0010_0000  0x20   32     
  358	:  0111_0011  0x73  115  s  
  359	:  0110_0101  0x65  101  e  
  360	:  0111_0010  0x72  114  r  
  361	:  0111_0110  0x76  118  v  
  362	:  0110_0101  0x65  101  e  
  363	:  0111_0010  0x72  114  r  
  364	:  0010_0000  0x20   32     
  365	:  0110_1000  0x68  104  h  
  366	:  0110_0001  0x61   97  a  
  367	:  0111_0011  0x73  115  s  
  368	:  0010_0000  0x20   32     
  369	:  0110_0010  0x62   98  b  
  370	:  0110_0101  0x65  101  e  
  371	:  0110_0101  0x65  101  e  
  372	:  0110_1110  0x6E  110  n  
  373	:  0010_0000  0x20   32     
  374	:  0100_0010  0x42   66  B  
  375	:  0100_1100  0x4C   76  L  
  376	:  0100_0001  0x41   65  A  
  377	:  0100_0011  0x43   67  C  
  378	:  0100_1011  0x4B   75  K  
  379	:  0100_1000  0x48   72  H  
  380	:  0100_1111  0x4F   79  O  
  381	:  0100_1100  0x4C   76  L  
  382	:  0100_0101  0x45   69  E  
  383	:  0100_0100  0x44   68  D  
  384	:  0010_1110  0x2E   46  .  
  385	:  0010_0000  0x20   32     
  386	:  0101_0011  0x53   83  S  
  387	:  0110_0101  0x65  101  e  
  388	:  0110_0101  0x65  101  e  
  389	:  0010_0000  0x20   32     
  390	:  0110_1000  0x68  104  h  
  391	:  0111_0100  0x74  116  t  
  392	:  0111_0100  0x74  116  t  
  393	:  0111_0000  0x70  112  p  
  394	:  0011_1010  0x3A   58  :  
  395	:  0010_1111  0x2F   47  /  
  396	:  0010_1111  0x2F   47  /  
  397	:  0110_0010  0x62   98  b  
  398	:  0110_1100  0x6C  108  l  
  399	:  0110_0001  0x61   97  a  
  400	:  0110_0011  0x63   99  c  
  401	:  0110_1011  0x6B  107  k  
  402	:  0110_1000  0x68  104  h  
  403	:  0110_1111  0x6F  111  o  
  404	:  0110_1100  0x6C  108  l  
  405	:  0110_0101  0x65  101  e  
  406	:  0010_1110  0x2E   46  .  
  407	:  0111_0011  0x73  115  s  
  408	:  0111_0000  0x70  112  p  
  409	:  0110_0001  0x61   97  a  
  410	:  0110_1101  0x6D  109  m  
  411	:  0110_0011  0x63   99  c  
  412	:  0110_0001  0x61   97  a  
  413	:  0110_1110  0x6E  110  n  
  414	:  0110_1110  0x6E  110  n  
  415	:  0110_1001  0x69  105  i  
  416	:  0110_0010  0x62   98  b  
  417	:  0110_0001  0x61   97  a  
  418	:  0110_1100  0x6C  108  l  
  419	:  0010_1110  0x2E   46  .  
  420	:  0110_0011  0x63   99  c  
  421	:  0110_1111  0x6F  111  o  
  422	:  0110_1101  0x6D  109  m  
  423	:  0011_1000  0x38   56  8  
  424	:  0011_0110  0x36   54  6  
  425	:  0010_1110  0x2E   46  .  
  426	:  0011_1000  0x38   56  8  
  427	:  0011_0111  0x37   55  7  
  428	:  0010_1110  0x2E   46  .  
  429	:  0011_1000  0x38   56  8  
  430	:  0011_1000  0x38   56  8  
  431	:  0010_1110  0x2E   46  .  
  432	:  0011_1000  0x38   56  8  
  433	:  0011_1001  0x39   57  9  
  434	:  1100_0000  0xC0  192    
  435	:  0000_1100  0x0C   12    
  436	:  0000_0000  0x00    0    
  437	:  0000_0110  0x06    6    
  438	:  0000_0000  0x00    0    
  439	:  0000_0001  0x01    1    
  440	:  0000_0000  0x00    0    
  441	:  0000_0000  0x00    0    
  442	:  0000_0000  0x00    0    
  443	:  0000_0000  0x00    0    
  444	:  0000_0000  0x00    0    
  445	:  0001_1000  0x18   24    
  446	:  1100_0000  0xC0  192    
  447	:  0010_0101  0x25   37  %  
  448	:  1100_0000  0xC0  192    
  449	:  0011_0001  0x31   49  1  
  450	:  0000_0111  0x07    7    
  451	:  0101_1011  0x5B   91  [  
  452	:  1100_0011  0xC3  195    
  453	:  0111_0001  0x71  113  q  
  454	:  0000_0000  0x00    0    
  455	:  0000_0000  0x00    0    
  456	:  1010_1000  0xA8  168    
  457	:  1100_0000  0xC0  192    
  458	:  0000_0000  0x00    0    
  459	:  0000_0000  0x00    0    
  460	:  0000_1110  0x0E   14    
  461	:  0001_0000  0x10   16    
  462	:  0000_0000  0x00    0    
  463	:  0000_0001  0x01    1    
  464	:  0101_0001  0x51   81  Q  
  465	:  1000_0000  0x80  128    
  466	:  0000_0000  0x00    0    
  467	:  0000_0000  0x00    0    
  468	:  0010_1010  0x2A   42  *  
  469	:  0011_0000  0x30   48  0  
|;
chk_exp(\$response[0],\$exptext);

$ipt->closedb;
&{"${TCTEST}::t_close"}();

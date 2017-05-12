#!/usr/bin/perl -w

use lib '.','./t','./blib/lib','../blib/lib';
# can run from here or distribution base

# Before installation is performed this script should be runnable with
# `perl test1.t time' which pauses `time' seconds (1..5) between pages

######################### We start with some black magic to print on failure.

use Test::More;
eval "use DefaultPort;";
if ($@) {
    plan skip_all => 'No serial port selected for use with testing';
}
else {
    plan tests => 171;
}

use POSIX qw(uname);
# can't drain ports without modems on them under POSIX in Solaris 2.6
my ($sysname, $nodename, $release, $version, $machine) = POSIX::uname();
my $SKIPDRAIN=0;
if ($sysname eq "SunOS" && $machine =~ /^sun/) {
        $SKIPDRAIN=1;
}

use AltPort qw( :PARAM 0.10 );		# check inheritance & export

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use strict;

## verifies the (0, 1) list returned by binary functions
sub test_bin_list {
    return undef unless (@_ == 2);
    return undef unless (0 == shift);
    return undef unless (1 == shift);
    return 1;
}

sub is_ok {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return ok(shift);
}

sub is_zero {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return ok(shift == 0);
}

sub is_bad {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return ok(!shift);
}

# assume a "vanilla" port on "/dev/ttyS0"

my $file = "/dev/ttyS0";
if ($SerialJunk::Makefile_Test_Port) {
    $file = $SerialJunk::Makefile_Test_Port;
}
if (exists $ENV{Makefile_Test_Port}) {
    $file = $ENV{Makefile_Test_Port};
}

my $naptime = 0;	# pause between output pages
if (@ARGV) {
    $naptime = shift @ARGV;
    unless ($naptime =~ /^[0-5]$/) {
	die "Usage: perl test?.t [ page_delay (0..5) ] [ /dev/ttySx ]";
    }
}
if (@ARGV) {
    $file = shift @ARGV;
}

my $cfgfile = "$file"."_test.cfg";
$cfgfile =~ s/.*\///;

my $fault = 0;
my $ob;
my $pass;
my $fail;
my $in;
my $in2;
my @opts;
my $out;
my $err;
my $blk;
my $e;
my $tick;
my $tock;
my %required_param;

my $s="testing is a wonderful thing - this is a 60 byte long string";
#      123456789012345678901234567890123456789012345678901234567890
my $line = $s.$s.$s;		# about 185 MS at 9600 baud

is_ok(0x0 == nocarp);				# 2
my @necessary_param = AltPort->set_test_mode_active(1);

unlink $cfgfile;
foreach $e (@necessary_param) { $required_param{$e} = 0; }

## 2 - 5 SerialPort Global variable ($Babble);

ok(scalar(AltPort->debug) == 0);		# 3: start out false
ok(scalar(AltPort->debug(1)));	# 4: set it

# 5: yes_true subroutine, no need to SHOUT if it works

ok ( AltPort->debug("T"));
ok (!AltPort->debug("F"));

{
    no strict 'subs';
    ok ( AltPort->debug(T));
    ok (!AltPort->debug(F));
    ok ( AltPort->debug(Y));
    ok (!AltPort->debug(N));
    ok ( AltPort->debug(ON));
    ok (!AltPort->debug(OFF));
    ok ( AltPort->debug(TRUE));
    ok (!AltPort->debug(FALSE));
    ok ( AltPort->debug(Yes));
    ok (!AltPort->debug(No));
    ok ( AltPort->debug("yes"));
    ok (!AltPort->debug("f"));
}

@opts = AltPort->debug;		# 6: binary_opt array
is_ok(test_bin_list(@opts));

# 7: Constructor

unless (is_ok ($ob = AltPort->new ($file))) {
    printf "could not open port $file\n";
    exit 1;
    # next test would die at runtime without $ob
}

#### 8 - 64: Check Port Capabilities 

## 8 - 21: Binary Capabilities

is_ok($ob->can_baud);				# 8
is_ok($ob->can_databits);			# 9
is_ok($ob->can_stopbits);			# 10
is_ok($ob->can_dtrdsr);				# 11
is_ok($ob->can_handshake);			# 12
is_ok($ob->can_parity_check);			# 13
is_ok($ob->can_parity_config);			# 14
is_ok($ob->can_parity_enable);			# 15
is_zero($ob->can_rlsd);				# 16
is_ok($ob->can_rtscts);				# 17
is_ok($ob->can_xonxoff);			# 18
is_zero($ob->can_interval_timeout);		# 19
is_ok($ob->can_total_timeout);			# 20
is_ok($ob->can_xon_char);			# 21
if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

is_zero($ob->can_spec_char);			# 22
is_zero($ob->can_16bitmode);			# 23
is_ok($ob->is_rs232);				# 24
is_zero($ob->is_modem);				# 25

#### 26 - xx: Set Basic Port Parameters 

## 26 - 31: Baud (Valid/Invalid/Current)

@opts=$ob->baudrate;		# list of allowed values
is_ok(1 == grep(/^9600$/, @opts));		# 26
is_zero(scalar grep(/^9601/, @opts));		# 27

is_ok($in = $ob->baudrate);			# 28
is_ok(1 == grep(/^$in$/, @opts));		# 29

is_bad(scalar $ob->baudrate(9601));		# 30
is_ok($in == $ob->baudrate(9600));		# 31
    # leaves 9600 pending

## 32 - xx: Parity (Valid/Invalid/Current)

@opts=$ob->parity;		# list of allowed values
is_ok(1 == grep(/none/, @opts));		# 32
is_zero(scalar grep(/any/, @opts));		# 33

is_ok($in = $ob->parity);			# 34
is_ok(1 == grep(/^$in$/, @opts));		# 35

is_bad(scalar $ob->parity("any"));		# 36
is_ok($in eq $ob->parity("none"));		# 37
    # leaves "none" pending

## 38 - 43: Databits (Valid/Invalid/Current)

@opts=$ob->databits;		# list of allowed values
is_ok(1 == grep(/8/, @opts));			# 38
is_zero(scalar grep(/4/, @opts));		# 39

is_ok($in = $ob->databits);			# 40
is_ok(1 == grep(/^$in$/, @opts));		# 41

is_bad(scalar $ob->databits(3));		# 42
is_ok($in == $ob->databits(8));			# 43
    # leaves 8 pending

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

## 44 - 49: Stopbits (Valid/Invalid/Current)

@opts=$ob->stopbits;		# list of allowed values
is_ok(1 == grep(/2/, @opts));			# 44
is_zero(scalar grep(/1.5/, @opts));		# 45

is_ok($in = $ob->stopbits);			# 46
is_ok(1 == grep(/^$in$/, @opts));		# 47

is_bad(scalar $ob->stopbits(3));		# 48
is_ok($in == $ob->stopbits(1));			# 49
    # leaves 1 pending

## 50 - 55: Handshake (Valid/Invalid/Current)

@opts=$ob->handshake;		# list of allowed values
is_ok(1 == grep(/none/, @opts));		# 50
is_zero(scalar grep(/moo/, @opts));		# 51

is_ok($in = $ob->handshake);			# 52
is_ok(1 == grep(/^$in$/, @opts));		# 53

is_bad(scalar $ob->handshake("moo"));		# 54
is_ok($in = $ob->handshake("rts"));		# 55
    # leaves "rts" pending for status

## 56 - 61: Buffer Size

($in, $out) = $ob->buffer_max(512);
is_bad(defined $in);				# 56
($in, $out) = $ob->buffer_max;
is_ok(defined $in);				# 57

if (($in > 0) and ($in < 4096))		{ $in2 = $in; } 
else					{ $in2 = 4096; }

if (($out > 0) and ($out < 4096))	{ $err = $out; } 
else					{ $err = 4096; }

is_ok(scalar $ob->buffers($in2, $err));		# 58

@opts = $ob->buffers(4096, 4096, 4096);
is_bad(defined $opts[0]);			# 59
($in, $out)= $ob->buffers;
is_ok($in2 == $in);				# 60
is_ok($out == $err);				# 61

## 62 - 64: Other Parameters (Defaults)

is_ok("AltPort" eq $ob->alias("AltPort"));	# 62
is_zero(scalar $ob->parity_enable(0));		# 63
is_ok($ob->write_settings);			# 64
is_ok($ob->binary);				# 65

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

## 66 - 67: Read Timeout Initialization

is_zero($ob->read_const_time);			# 66
is_zero($ob->read_char_time);			# 67

## 68 - 74: No Handshake, Polled Write

is_ok("none" eq $ob->handshake("none"));	# 68

$tick=$ob->get_tick_count;
$pass=$ob->write($line);
if ($SKIPDRAIN) {
        is_zero(0);                             # 69
        select(undef,undef,undef,0.185);
} else {
        is_ok(1 == $ob->write_drain);           # 69
}
$tock=$ob->get_tick_count;

is_ok($pass == 180);				# 70
$err=$tock - $tick;
is_bad (($err < 160) or ($err > 220));		# 71
print "<185> elapsed time=$err\n";

is_ok(scalar $ob->purge_tx);			# 72
is_ok(scalar $ob->purge_rx);			# 73
is_ok(scalar $ob->purge_all);			# 74

## 75 - 80: Optional Messages

@opts = $ob->user_msg;
is_ok(test_bin_list(@opts));			# 75
is_zero(scalar $ob->user_msg);			# 76
is_ok(1 == $ob->user_msg(1));			# 77

@opts = $ob->error_msg;
is_ok(test_bin_list(@opts));			# 78
is_zero(scalar $ob->error_msg);			# 79
is_ok(1 == $ob->error_msg(1));			# 80

## 81: Save Configuration

is_ok(scalar $ob->save($cfgfile));		# 81
undef $ob;

sleep 1;

## 82 - 116: Reopen as (mostly 5.003 Compatible) Tie

    # constructor = TIEHANDLE method		# 82
unless (is_ok ($ob = tie(*PORT,'AltPort', $cfgfile))) {
    printf "could not reopen port from $cfgfile\n";
    exit 1;
    # next test would die at runtime without $ob
}

    # tie to PRINT method
$tick=$ob->get_tick_count;
$pass=print PORT $line;
if ($SKIPDRAIN) {
        is_zero(0);                             # 83
        select(undef,undef,undef,0.185);
} else {
        is_ok(1 == $ob->write_drain);           # 83
}
$tock=$ob->get_tick_count;

is_ok($pass == 1);				# 84

$err=$tock - $tick;
is_bad (($err < 160) or ($err > 235));		# 85
print "<185> elapsed time=$err\n";

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

    # tie to PRINTF method
$tick=$ob->get_tick_count;
if ( $] < 5.004 ) {
    $out=sprintf "123456789_%s_987654321", $line;
    $pass=print PORT $out;
}
else {
    $pass=printf PORT "123456789_%s_987654321", $line;
}
if ($SKIPDRAIN) {
        is_zero(0);                             # 86
        select(undef,undef,undef,0.205);
} else {
        is_ok(1 == $ob->write_drain);           # 86
}
$tock=$ob->get_tick_count;

is_ok($pass == 1);				# 87
$err=$tock - $tick;
is_bad (($err < 170) or ($err > 255));		# 88
print "<205> elapsed time=$err\n";

is_ok (300 == $ob->read_const_time(300));	# 89
is_ok (20 == $ob->read_char_time(20));		# 90
$tick=$ob->get_tick_count;
$in2 = $ob->input;
$tock=$ob->get_tick_count;

is_ok (20 == $ob->read_char_time);		# 91
unless (is_ok ($in2 eq "")) {			# 92
    die "\n92: Looks like you have a modem on the serial port!\n".
        "Please turn it off, or remove it and restart the tests.\n";
    # many tests following here will fail if there is modem attached
}

$err=$tock - $tick;
is_bad ($err > 50);				# 93
print "<0> elapsed time=$err\n";

is_ok (0 == $ob->read_char_time(0));		# 94
$tick=$ob->get_tick_count;
$in2= getc PORT;
$tock=$ob->get_tick_count;

is_bad (defined $in2);				# 95
$err=$tock - $tick;
is_bad (($err < 275) or ($err > 365));		# 96
print "<300> elapsed time=$err\n";

is_ok (0 == $ob->read_const_time(0));		# 97
$tick=$ob->get_tick_count;
$in2= getc PORT;
$tock=$ob->get_tick_count;

is_bad (defined $in2);				# 98
$err=$tock - $tick;
is_bad ($err > 50);				# 99
print "<0> elapsed time=$err\n";

## 99 - 103: Bad Port (new + quiet)

$file = "/dev/badport";
my $ob2;
is_bad ($ob2 = AltPort->new ($file));		# 100
is_bad (defined $ob2);				# 101
is_bad ($ob2 = AltPort->new ($file, 1));	# 102
is_bad ($ob2 = AltPort->new ($file, 0));	# 103

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

is_bad (defined $ob2);				# 104

## 104 - 119: Output bits and pulses

SKIP: {
    skip "Can't IOCTL", 14 unless $ob->can_ioctl;

    is_ok ($ob->dtr_active(0));			# 105
    $tick=$ob->get_tick_count;
    is_ok ($ob->pulse_dtr_on(100));		# 106
    $tock=$ob->get_tick_count;
    $err=$tock - $tick;
    if (!is_bad (($err < 180) or ($err > 265))) {# 107
      if ($err > 265) {
        warn "\n107: DTR toggle took too long.  Is this a Solaris serial port?\n\tPlease read the 'SOLARIS TROUBLE' section in the README\n\tto correct this problem.\n";
      }
    }
    print "<200> elapsed time=$err\n";
    
    is_ok ($ob->dtr_active(1));			# 108
    $tick=$ob->get_tick_count;
    is_ok ($ob->pulse_dtr_off(200));		# 109
    $tock=$ob->get_tick_count;
    $err=$tock - $tick;
    if (!is_bad (($err < 370) or ($err > 485))) {# 110
      if ($err > 485) {
        warn "\n110: DTR toggle took too long.  Is this a Solaris serial port?\n\tPlease read the 'SOLARIS TROUBLE' section in the README\n\tto correct this problem.\n";
      }
    }
    print "<400> elapsed time=$err\n";
    
    SKIP: {
        skip "Can't RTS", 7 unless $ob->can_rts();
	
        is_ok ($ob->rts_active(0));		# 111
        $tick=$ob->get_tick_count;
        is_ok ($ob->pulse_rts_on(150));		# 112
        $tock=$ob->get_tick_count;
        $err=$tock - $tick;
        is_bad (($err < 275) or ($err > 365));	# 113
        print "<300> elapsed time=$err\n";
    
        is_ok ($ob->rts_active(1));		# 114
        $tick=$ob->get_tick_count;
        is_ok ($ob->pulse_rts_on(50));		# 115
        $tock=$ob->get_tick_count;
        $err=$tock - $tick;
        is_bad (($err < 80) or ($err > 145));	# 116
        print "<100> elapsed time=$err\n";
    
        is_ok ($ob->rts_active(0));		# 117
    }
    is_ok ($ob->dtr_active(0));			# 118
}

$tick=$ob->get_tick_count;
is_ok ($ob->pulse_break_on(250));		# 119
$tock=$ob->get_tick_count;
$err=$tock - $tick;
is_bad (($err < 235) or ($err > 900));		# 120
print "<500> elapsed time=$err\n";

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

## 121 - 135: Record and Field Separators

my $r = "I am the very model of an output record separator";	## =49
#        1234567890123456789012345678901234567890123456789
my $f = "The fields are alive with the sound of music";		## =44
my $ff = "$f, with fields they have sung for a thousand years";	## =93
my $rr = "$r, not animal or vegetable or mineral or any other";	## =98

is_ok($ob->output_record_separator eq "");	# 121
is_ok($ob->output_field_separator eq "");	# 122
$, = "";
$\ = "";

    # tie to PRINT method
$tick=$ob->get_tick_count;
$pass=print PORT $s, $s, $s;
if ($SKIPDRAIN) {
        is_zero(0);                             # 123
        select(undef,undef,undef,0.185);
} else {
        is_ok(1 == $ob->write_drain);           # 123
}
$tock=$ob->get_tick_count;

is_ok($pass == 1);				# 124

$err=$tock - $tick;
is_bad (($err < 160) or ($err > 210));		# 125
print "<185> elapsed time=$err\n";

is_ok($ob->output_field_separator($f) eq "");	# 126
$tick=$ob->get_tick_count;
$pass=print PORT $s, $s, $s;
if ($SKIPDRAIN) {
        is_zero(0);                             # 127
        select(undef,undef,undef,0.275);
} else {
        is_ok(1 == $ob->write_drain);           # 127
}
$tock=$ob->get_tick_count;

is_ok($pass == 1);				# 128

$err=$tock - $tick;
is_bad (($err < 260) or ($err > 310));		# 129
print "<275> elapsed time=$err\n";

is_ok($ob->output_record_separator($r) eq "");	# 130
$tick=$ob->get_tick_count;
$pass=print PORT $s, $s, $s;
if ($SKIPDRAIN) {
        is_zero(0);                             # 131
        select(undef,undef,undef,0.325);
} else {
        is_ok(1 == $ob->write_drain);           # 131
}
$tock=$ob->get_tick_count;

is_ok($pass == 1);				# 132

$err=$tock - $tick;
is_bad (($err < 310) or ($err > 360));		# 133
print "<325> elapsed time=$err\n";

is_ok($ob->output_record_separator eq $r);	# 134
is_ok($ob->output_field_separator eq $f);	# 135
$, = $ff;
$\ = $rr;

$tick=$ob->get_tick_count;
$pass=print PORT $s, $s, $s;
if ($SKIPDRAIN) {
        is_zero(0);                             # 136
        select(undef,undef,undef,0.325);
} else {
        is_ok(1 == $ob->write_drain);           # 136
}
$tock=$ob->get_tick_count;

$, = "";
$\ = "";
is_ok($pass == 1);				# 137

$err=$tock - $tick;
is_bad (($err < 310) or ($err > 360));		# 138
print "<325> elapsed time=$err\n";

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

$, = $ff;
$\ = $rr;
is_ok($ob->output_field_separator("") eq $f);	# 139
$tick=$ob->get_tick_count;
$pass=print PORT $s, $s, $s;
if ($SKIPDRAIN) {
        is_zero(0);                             # 140
        select(undef,undef,undef,0.425);
} else {
        is_ok(1 == $ob->write_drain);           # 140
}
$tock=$ob->get_tick_count;

$, = "";
$\ = "";
is_ok($pass == 1);				# 141

$err=$tock - $tick;
is_bad (($err < 410) or ($err > 460));		# 142
print "<425> elapsed time=$err\n";

$, = $ff;
$\ = $rr;
is_ok($ob->output_record_separator("") eq $r);	# 143
$tick=$ob->get_tick_count;
$pass=print PORT $s, $s, $s;
if ($SKIPDRAIN) {
        is_zero(0);                             # 144
        select(undef,undef,undef,0.475);
} else {
        is_ok(1 == $ob->write_drain);           # 144
}
$tock=$ob->get_tick_count;

$, = "";
$\ = "";
is_ok($pass == 1);				# 145

$err=$tock - $tick;
is_bad (($err < 460) or ($err > 510));		# 146
print "<475> elapsed time=$err\n";

is_ok($ob->output_field_separator($f) eq "");	# 147
is_ok($ob->output_record_separator($r) eq "");	# 148

    # tie to PRINTF method
$tick=$ob->get_tick_count;
if ( $] < 5.004 ) {
    $out=sprintf "123456789_%s_987654321", $line;
    $pass=print PORT $out;
}
else {
    $pass=printf PORT "123456789_%s_987654321", $line;
}
if ($SKIPDRAIN) {
        is_zero(0);                             # 149
        select(undef,undef,undef,0.260);
} else {
        is_ok(1 == $ob->write_drain);           # 149
}
$tock=$ob->get_tick_count;

is_ok($pass == 1);				# 150

$err=$tock - $tick;
is_bad (($err < 240) or ($err > 295));		# 151
print "<260> elapsed time=$err\n";

is_ok($ob->output_field_separator("") eq $f);	# 152
is_ok($ob->output_record_separator("") eq $r);	# 153

    # destructor = CLOSE method
if ( $] < 5.005 ) {
    is_ok($ob->close);				# 154
}
else {
    is_ok(close PORT);				# 154
}

    # destructor = DESTROY method
undef $ob;					# Don't forget this one!!
untie *PORT;

no strict 'subs';
is_ok(0xffffffff == LONGsize);			# 155
is_ok(0xffff == SHORTsize);			# 156
is_ok(0x1 == nocarp);				# 157
is_ok(0x0 == yes_true("F"));			# 158
is_ok(0x1 == yes_true("T"));			# 159

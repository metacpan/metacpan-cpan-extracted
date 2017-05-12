# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Linux-RTC-Ioctl.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use strict;
use warnings;
use Fcntl qw(SEEK_SET);

use Test::More tests => 27;

BEGIN { use_ok('Linux::RTC::Ioctl', qw(:all)) };


my $fail = 0;
foreach my $constname (qw(
	RTC_AF RTC_AIE_OFF RTC_AIE_ON RTC_ALM_READ RTC_ALM_SET RTC_EPOCH_READ
	RTC_EPOCH_SET RTC_IRQF RTC_IRQP_READ RTC_IRQP_SET RTC_MAX_FREQ RTC_PF
	RTC_PIE_OFF RTC_PIE_ON RTC_PLL_GET RTC_PLL_SET RTC_RD_TIME RTC_SET_TIME
	RTC_UF RTC_UIE_OFF RTC_UIE_ON RTC_VL_CLR RTC_VL_READ RTC_WIE_OFF
	RTC_WIE_ON RTC_WKALM_RD RTC_WKALM_SET RTC_RECORD_SIZE)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined Linux::RTC::Ioctl macro $constname/) {
    print "# pass: $@";
  } else {
    print "# fail: $@";
    $fail = 1;
  }

}

ok( $fail == 0 , 'Constants' );
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Test opening and writing

my $rtc = Linux::RTC::Ioctl->new('/dev/null');

ok($rtc->nodename eq '/dev/null', 'Device file name');

ok(fileno $rtc->device >= 0, 'Open file handle');

eval { $rtc->wait_for_timer };
ok($@ =~ m/^Unexpected end of file from real time clock device/, 'EOF from RTC device');

open my $DEV_NULL, '<:unix:raw:bytes', '/dev/null';

$rtc = Linux::RTC::Ioctl->new($DEV_NULL);
close($DEV_NULL);
eval { $rtc->wait_for_timer };
ok($@ =~ m'Invalid device file handle.', 'Invalid handle');

open my $DEV_FILE, '+>:unix:raw:bytes', "/tmp/rtc.$$";
syswrite $DEV_FILE, pack 'L!', (28 << 8 | RTC_IRQF | RTC_PF | RTC_AF | RTC_UF);
sysseek $DEV_FILE, 0, SEEK_SET;

$rtc = Linux::RTC::Ioctl->new($DEV_FILE);

if (-e "/proc/$$/fd/0")
{
    if (exists &CORE::readlink)
    {
	ok("/tmp/rtc.$$" eq $rtc->nodename, 'Device file name');
    }
    else
    {
	ok("/proc/$$/fd/" . fileno($DEV_FILE) eq $rtc->nodename, 'Device file name');
    }
}
else
{
    ok(1, '"proc" fs not available');
}

SKIP:
{
    skip 'Periodic frequency not available on the platform.', 1
	unless defined \&Linux::RTC::Ioctl::periodic_frequency;

    ok(!defined $rtc->periodic_frequency && !defined $rtc->periodic_frequency(20), 'Periodic frequency ioctl can report errors.');
}

SKIP:
{
    skip 'Periodic interrupt not available on the platform', 1
	unless defined \&Linux::RTC::Ioctl::periodic_interrupt;

    ok(!defined $rtc->periodic_interrupt(0) && !defined $rtc->periodic_interrupt(!0), 'Periodic interrupt ioctl can report errors.');
}

SKIP:
{
    skip 'Update interrupt not available on the platform.', 1
	unless defined \&Linux::RTC::Ioctl::update_interrupt;

    ok(!defined $rtc->update_interrupt(0) && !defined $rtc->update_interrupt(!0), 'Update interrupt ioctl can report errors.');
}

SKIP:
{
    skip 'Alarm interrupt not available on the platform.', 1
	unless defined \&Linux::RTC::Ioctl::alarm_interrupt;

    ok(!defined $rtc->alarm_interrupt(0) && !defined $rtc->alarm_interrupt(!0), 'Alarm interrupt ioctl can report errors.');
}

SKIP:
{
    skip 'RTC read ioctl not available on the platform.', 1
	unless defined \&Linux::RTC::Ioctl::read_time;

    ok(!defined $rtc->read_time, 'RTC read ioctl can report errors.');
}

SKIP:
{
    skip 'RTC set ioctl not available on the platform.', 1
	unless defined \&Linux::RTC::Ioctl::set_time;

    ok(!defined $rtc->set_time, 'RTC set ioctl can report errors.');
}

SKIP:
{
    skip 'RTC alarm read ioctl not available on the platform.', 1
	unless defined \&Linux::RTC::Ioctl::read_alarm;

    ok(!defined $rtc->read_alarm, 'RTC alarm read ioctl can report errors.');
}

SKIP:
{
    skip 'RTC alarm set ioctl not available on the platform.', 1
	unless defined \&Linux::RTC::Ioctl::set_alarm;

    ok(!defined $rtc->set_alarm, 'RTC alarm set ioctl can report errors.');
}

SKIP:
{
    skip 'Read Voltage Low indicator not available on the platform', 1
	unless defined  \&Linux::RTC::Ioctl::read_voltage_low_indicator;

    ok(!defined $rtc->read_voltage_low_indicator, 'RTC read voltage low indicator can report errors.');
}

SKIP:
{
    skip 'Clear Voltage Low indicator not available on the platform', 2
	unless defined \&Linux::RTC::Ioctl::clear_voltage_low_indicator;

    ok(!defined $rtc->clear_voltage_low_indicator, 'RTC clear voltage low indicator can report errors.');
}

my ($timer_flags, $timer_count) = $rtc->wait_for_timer;

ok($timer_flags & RTC_PF && $timer_flags & RTC_UF && $timer_flags & RTC_AF && $timer_flags & RTC_IRQF, 'Timer flags');
ok($timer_count == 28, 'Timer count');

# test the example reading code from the documentation
sysseek $DEV_FILE, 0, SEEK_SET;

#
    my $rtc_record = pack 'L!', 0;
    my $record_size = length $rtc_record;   # length also given as the package constant RTC_RECORD_SIZE
    my $size = sysread $rtc->device, $rtc_record, $record_size;	# blocks until next timer event occurs

    defined $size or die("Access to real time clock device failed: $!");
    $size == $record_size or die("Unexpected end of file reading RTC device.");

    $rtc_record = unpack 'L!', $rtc_record;

    # Event flags and the interrupt count are now available
    $timer_flags = $rtc_record & 0xFF;
    $timer_count = $rtc_record >> 8;
#

ok($timer_flags & RTC_PF && $timer_flags & RTC_UF && $timer_flags & RTC_AF && $timer_flags & RTC_IRQF, 'Example timer flags');
ok($timer_count == 28, 'Example timer count');

# Simple test for $rtc->rtctime

my $null_rtc = Linux::RTC::Ioctl->new("/dev/null");

is_deeply([ $null_rtc->rtctime ], [ -1, -1, -1, -1, -1, -1, -1, -1, -1 ], '$null_rtc->rtctime');

($$null_rtc{sec}, $$null_rtc{min}, $$null_rtc{hour}, $$null_rtc{mday}, $$null_rtc{mon}, $$null_rtc{year}, $$null_rtc{wday}, $$null_rtc{yday}, $$null_rtc{isdst}) = 
     (10, 22, 8, 28, 11, 2016, 0, 0, -3);

is($null_rtc->{sec}, 10, '$null_rtc object members populated.');

is_deeply([ $null_rtc->rtctime ], [ 10, 22, 8, 28, 11, 2016, 0, 0, -3 ], '$rtc->rtctime reads all members');

$null_rtc->rtctime(11, 23, 7, 29, 12, 2015, 1, 1, 8);

is_deeply([ $null_rtc->rtctime ], [11, 23, 7, 29, 12, 2015, 1, 1, 8], '$rtc->rtctime(...) sets all members');

$null_rtc->rtctime(9, 21, 9, 27, 10, 2014);

is_deeply([ $null_rtc->rtctime ], [9, 21, 9, 27, 10, 2014, 1, 1, 8], '$rtc->rtctime(...) sets used members');

# Open non-existent file
my $undef_rtc = Linux::RTC::Ioctl->new('/adfsfdaGUID_433423_34FFA_4314_08');
ok (! defined $undef_rtc, 'Non-existent device file returns undef object.');

END
{
    $null_rtc = undef if defined($null_rtc);
    $rtc = undef if defined($rtc);
    close($DEV_FILE) if defined($DEV_FILE);
    unlink "/tmp/rtc.$$"
}

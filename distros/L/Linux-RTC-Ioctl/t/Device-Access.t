use strict;
use warnings;
use Cwd;
use Fcntl qw(SEEK_SET);
use POSIX;
use Test::More tests => 26;

BEGIN { use_ok('Linux::RTC::Ioctl', qw(:all)) };

my $DEVICE_FILE='/dev/rtc';

$DEVICE_FILE = Cwd::realpath $DEVICE_FILE;  # read symlink

my $rtc = undef;
my $restoreRTCTime = 0;

SKIP:
{
    skip "Read access to $DEVICE_FILE needed.", 25
	unless (-r $DEVICE_FILE);

    my $rtc = Linux::RTC::Ioctl->new($DEVICE_FILE) // die "Failed to open RTC device $DEVICE_FILE";

    ok($rtc->nodename eq $DEVICE_FILE, 'Device file name');

    SKIP:
    {
	skip 'RTC periodic frequncy not available on the platform', 5
	    unless defined(\&Linux::RTC::Ioctl::periodic_frequency) && defined(\&Linux::RTC::Ioctl::periodic_interrupt);

	eval { $rtc->periodic_frequency(32) // die "Access to RTC device ${\$rtc->nodename} failed: $!"; };
	ok( length($@) == 0, 'Set periodic frequency.') || diag($@);
	ok( $rtc->periodic_frequency == 32, 'Get periodic frequency.');

	eval { $rtc->periodic_interrupt(!0) // die "Access to RTC device ${\$rtc->nodename} failed: $!"; };
	ok( length $@ == 0, 'Set periodic interrupts.') || diag($@);

	my $start_time = time;
	my $flag_ok = !0;

	# Should be about 1 sec
	for (1..32)
	{
	    my ($flags, $counter) = $rtc->wait_for_timer;

	    $flag_ok &&= ($flags & RTC_PF);
	}

	ok($flag_ok && (time - $start_time >= 1), 'Periodic interrupt read.');

	eval { $rtc->periodic_interrupt(0) // die "Access to RTC device ${\$rtc->nodename} failed: $!"; };
	ok( length $@ == 0, 'Reset periodic interrupts.') || diag($@);
    }

    SKIP:
    {
	skip 'RTC update interrupts not available on the platform.', 3 unless defined(&Linux::RTC::Ioctl::update_interrupt);
	eval { $rtc->update_interrupt(!0) // die "Access to RTC device ${\$rtc->nodename} failed: $!"; };
	ok( length $@ == 0, 'Set update interrupts.') || diag($@);

	my $start_time = time;
	my $flag_ok = !0;

	for (1..3)
	{
	    my ($flags, $count) = $rtc->wait_for_timer;
	    $flag_ok &&= $flags & RTC_UF;
	}

	ok( $flag_ok && time - $start_time >= 2, 'Update interrupt read.');

	eval { $rtc->update_interrupt(0) // die "Access to RTC device ${\$rtc->nodename} failed: $!"; };
	ok( length $@ == 0, 'Reset update interrupts.') || diag($@);
    }

    SKIP:
    {
	skip 'Reading RTC date and time not available on the platform', 1
	    unless defined(&Linux::RTC::Ioctl::read_time);

	$rtc->read_time // die "Access to RTC device ${\$rtc->nodename} failed: $!";
	my $time1 = POSIX::mktime($rtc->{sec}, $rtc->{min}, $rtc->{hour}, $rtc->{mday}, $rtc->{mon}, $rtc->{year});

	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = $rtc->read_time;
	my $time2 = POSIX::mktime($sec, $min, $hour, $mday, $mon, $year);

	note("RTC time: " . POSIX::ctime($time2));
	note("RTC time: " . POSIX::ctime($time1));

	my $time_zone_diff1 = time - $time1;
	ok(-14*60*60 - 1 <= $time_zone_diff1 && $time_zone_diff1 <= 14*60*60 + 1, 'RTC time zone is within +/- 14h from the local time zone');

	my $time_zone_diff2 = time -$time2;
	ok(-14*60*60 - 1 <= $time_zone_diff2 && $time_zone_diff2 <= 14*60*60 + 1, 'RTC time zone is within +/- 14h from the local time zone');

	my $time_diff = $time2 - $time1;

	ok($time_diff < 1, 'Reading RTC time');
    }

    SKIP:
    {
	skip 'RTC alarm not available on the platform.', 5
	    unless defined(&Linux::RTC::Ioctl::alarm_interrupt) && defined(&Linux::RTC::Ioctl::set_alarm) && defined(&Linux::RTC::Ioctl::read_alarm);

	eval { $rtc->alarm_interrupt(!0 // die "Access to RTC device ${\$rtc->nodename} failed: $!"); };
	ok( length $@ == 0, 'Set alarm interrupts.') || diag($@);

	eval { $rtc->alarm_interrupt(0 // die "Access to RTC device ${\$rtc->nodename} failed: $!"); };
	ok( length $@ == 0, 'Reset alarm interrupts.') || diag($@);

	skip 'Reading RTC date and time not available on the platform', 3
	    unless defined(&Linux::RTC::Ioctl::read_time);

	$rtc->close;
	$rtc = Linux::RTC::Ioctl->new($DEVICE_FILE);

	$rtc->read_time // die "Access to RTC device ${\$rtc->nodename} failed: $!";
	my $rtc_time = POSIX::mktime($$rtc{sec}, $rtc->{min}, $rtc->{hour}, $$rtc{mday}, $$rtc{mon}, $$rtc{year});
	my $rtc_daytime = POSIX::mktime($$rtc{sec}, $$rtc{min}, $$rtc{hour}, 0, 0, 0);

	$rtc->set_alarm(localtime($rtc_time + 2)) // die "Access to RTC device ${\$rtc->nodename} failed: $!";
	$rtc->read_alarm // die "Access to RTC device ${\$rtc->nodename} failed: $!";
	my $alarm_time = POSIX::mktime($$rtc{sec}, $$rtc{min}, $$rtc{hour}, $$rtc{mday}, $$rtc{mon}, $$rtc{year});
	my $alarm_daytime = POSIX::mktime($$rtc{sec}, $$rtc{min}, $$rtc{hour}, 0, 0, 0);

	if ($alarm_time - $rtc_time == 2)
	{
	    pass('Alarm full date and time set 2 sec after RTC time.');
	}
	else
	{
	    if ($alarm_daytime - $rtc_daytime == 2)
	    {
		pass('Alarm daytime set 2 sec after RTC time.');
	    }
	    else
	    {
		fail('Alarm time set 2 sec after RTC time.');
	    }
	}

	$rtc->alarm_interrupt(!0) // die "Access to RTC device ${\$rtc->nodename} failed: $!";
	my($flags, $count) = $rtc->wait_for_timer;
	my $interrupt_time = POSIX::mktime($rtc->read_time);
	my $interrupt_daytime = POSIX::mktime($$rtc{sec}, $$rtc{min}, $$rtc{hour}, 0, 0, 0);

	ok($alarm_time == $interrupt_time || $alarm_daytime == $interrupt_daytime, 'Alarm event read.');
	ok($flags & RTC_AF && $count >= 1, 'Alarm event reported.');

	$rtc->alarm_interrupt(0) // die "Access to RTC device ${\$rtc->nodename} failed: $!";
    }

    SKIP:
    {
	skip 'RTC wake-up alarm not available on the platform.', 3
	    unless defined(&Linux::RTC::Ioctl::set_wakeup_alarm) && defined(&Linux::RTC::Ioctl::read_wakeup_alarm);

	skip 'Reading RTC date and time not available on the platform', 3
	    unless defined(&Linux::RTC::Ioctl::read_time);

	$rtc->close;
	$rtc = Linux::RTC::Ioctl->new($DEVICE_FILE);

	$rtc->read_time // die "Access to RTC device ${\$rtc->nodename} failed: $!";
	my $rtc_time = POSIX::mktime($$rtc{sec}, $rtc->{min}, $rtc->{hour}, $$rtc{mday}, $$rtc{mon}, $$rtc{year});

	$rtc->set_wakeup_alarm(1, 0, localtime($rtc_time + 2)) // die "Access to RTC device ${\$rtc->nodename} failed: $!";
	$rtc->read_wakeup_alarm // die "Access to RTC device ${\$rtc->nodename} failed: $!";
	my $alarm_time = POSIX::mktime($$rtc{sec}, $$rtc{min}, $$rtc{hour}, $$rtc{mday}, $$rtc{mon}, $$rtc{year});

	if ($rtc->{enabled} && ($alarm_time - $rtc_time == 2))
	{
	    pass('Wake-up alarm date and time set 2 sec after RTC time.');
	}
	else
	{
	    fail('Wake-up alarm date and time set 2 sec after RTC time.');
	}

	my($flags, $count) = $rtc->wait_for_timer;
	$rtc->read_time;
	my $interrupt_time = POSIX::mktime($$rtc{sec}, $$rtc{min}, $$rtc{hour}, $$rtc{mday}, $$rtc{mon}, $$rtc{year});

	cmp_ok($alarm_time, '==', $interrupt_time, 'Wake-up alarm event read.');

	ok($flags & RTC_AF && $count >= 1, 'Wake-up alarm event reported.');
    }

    SKIP:
    {
	skip 'Setting RTC time not available on the platform.', 3
	    unless defined(&Linux::RTC::Ioctl::set_time);

	skip 'Current process needs access for setting RTC time.', 3
	    unless -w $rtc->device;

	$rtc->read_time;
	my $present_time = POSIX::mktime $rtc->rtctime;

	# add 1 year, 28 days, 5 days, 8 hours, 43min and 18sec to the current RTC time
	my $future_time = $present_time + 360*24*3600 + 28*24*3600 + 5*24*3600 + 8*3600 + 43*60 + 18;

	# This will really modify your computer time
	if (defined $rtc->set_time(localtime $future_time))
	{
	    $restoreRTCTime = !0;
	    pass('RTC time write access.');

	    is(POSIX::mktime(($rtc->read_time)[0..5]), POSIX::mktime((localtime $future_time)[0..5]), 'Set RTC time');

	    $rtc->set_time; # restore present date and time
	    is(POSIX::mktime($rtc->read_time), $present_time, 'Restore RTC time');
	    $restoreRTCTime = 0;
	}
	else
	{
	    if ($! == POSIX::EACCES)
	    {
		skip "Access to $DEVICE_FILE required for setting time.", 3
	    }

	    diag("Ioctl error: $!");
	    fail('RTC time write access.');
	}
    }

    SKIP:
    {
	skip 'Read voltage low indicator not available on the platform', 1
	    unless defined \&Linux::RTC::Ioctl::read_voltage_low_indicator;

	my $voltage_low = $rtc->read_voltage_low_indicator;

	if (defined $voltage_low)
	{
	    diag("Voltage low indicator: $voltage_low.");
	    pass('Read voltage low indicator.');
	}
	else
	{
	    skip "Read voltage low indicator not implemented: $!", 1;
	}
    }

    SKIP:
    {
	skip 'Clear voltage low indicator not available on the platform', 1
	    unless defined \&Linux::RTC::Ioctl::clear_voltage_low_indicator;

	if (defined $rtc->clear_voltage_low_indicator)
	{
	    pass('Clear voltage low indicator.');
	}
	else
	{
	    skip "Clear voltage low indicator not implemented: $!", 1
	}
    }
}

END
{
    if (defined $rtc)
    {
	$rtc->alarm_interrupt(0)
	    if (defined(&Linux::RTC::Ioctl::alarm_interrupt));


	$rtc->alarm_interrupt(0)
	    if (defined(&Linux::RTC::Ioctl::update_interrupt));


	$rtc->alarm_interrupt(0)
	    if (defined(&Linux::RTC::Ioctl::periodic_interrupt));

	$rtc->set_time
	    if ($restoreRTCTime);

	$rtc->set_wakeup_alarm(0, 0, 0, 0, 0, 0, 0, 0)
	    if (defined(&Linux::RTC::Ioctl::set_wakeup_alarm));

	$rtc->close;
    }
}

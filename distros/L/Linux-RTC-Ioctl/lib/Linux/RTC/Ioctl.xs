# include <sys/ioctl.h>
# include <linux/rtc.h>

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#if defined(read) || defined(ioctl)
# warning "POSIX read/ioctl re-defined"
# include "src/IoctlNative.h"
#else
# define linux_rtc_native_read read
# define linux_rtc_native_ioctl ioctl
#endif

#include "const-c.inc"

static const char
    invalidHandleMsg[] = "Invalid device file handle.",
    missingDeviceFileMsg[] = "No device file given.",
    rtcRecordSizeMsg[] = "Unexpected end of file from real time clock device %s.",
    unsignedParamMsg[] = "Unsigned number parameter expected.",
    numericParamMsg[] = "Numeric parameter expected.",
    hashAccessFailedMsg[] = "Failed to access $rtc object hash keys.",
    objectFieldsMissingMsg[] = "Member field \"%s\" is missing or is non-numeric in RTC object.";

MODULE = Linux::RTC::Ioctl		PACKAGE = Linux::RTC::Ioctl		

INCLUDE: const-xs.inc

void
wait_for_timer(HV *rtc)
    PROTOTYPE: \%
    PPCODE:
	int fd = -1;
	char const *node = "";
	unsigned long record = 0;
	ssize_t read_size = -1;
	SV **device = hv_fetch(rtc, "device", 6, 0);

	{
	    SV **nodename = hv_fetch(rtc, "nodename", 8, 0);

	    if (nodename && (node = SvPV_nolen(*nodename), SvPOK(*nodename)))
		;
	    else
		node = "";
	}

	if (device)
	{
	    IO *file_io = sv_2io(*device);

	    if (file_io)
	    {
		PerlIO *device_perlio = IoIFP(file_io);

		if (device_perlio)
		{
		    fd = PerlIO_fileno(device_perlio);

		    if (fd < 0)
			croak(invalidHandleMsg);
		}
		else
		    croak(invalidHandleMsg);
	    }
	    else
		croak(invalidHandleMsg);
	}
	else
	    croak(missingDeviceFileMsg);

	read_size = linux_rtc_native_read(fd, &record, sizeof record);

	if (read_size == sizeof record)
	{
	    EXTEND(SP, 2);
	    PUSHs(sv_2mortal(newSVuv(record & ((1 << CHAR_BIT) - 1))));
	    PUSHs(sv_2mortal(newSVuv(record >> CHAR_BIT)));
	    XSRETURN(2);
	}
	else
	    if (read_size >= 0)
		croak(rtcRecordSizeMsg, node);
	    else
	    {
	        // return undef after a read error, check $!
	        XPUSHs(&PL_sv_undef);
	        XSRETURN(1);
	    }

#if defined(RTC_IRQP_SET) && defined(RTC_IRQP_READ)

void
periodic_frequency(HV *rtc, ...)
    PROTOTYPE: \%;$
    PPCODE:
	int fd = -1;
	SV **device = hv_fetch(rtc, "device", 6, 0);;

	if (device)
	{
	    IO *file_io = sv_2io(*device);

	    if (file_io)
	    {
		PerlIO *device_perlio = IoIFP(file_io);

		if (device_perlio)
		{
		    fd = PerlIO_fileno(device_perlio);

		    if (fd < 0)
			croak(invalidHandleMsg);
		}
		else
		    croak(invalidHandleMsg);
	    }
	    else
		croak(invalidHandleMsg);
	}
	else
	    croak(missingDeviceFileMsg);

	if (items > 1)
	{
	    IV freq = SvIV(ST(1));

	    if (SvIOK(ST(1)) && freq > 0)
	    {
		dXSTARG;
		unsigned long frequency = freq;
		int result = ioctl(fd, RTC_IRQP_SET, frequency);

		if (result < 0)
		    XPUSHs(&PL_sv_undef);
		else
		    XPUSHu(result);

		XSRETURN(1);
	    }
	    else
		croak(unsignedParamMsg);
	}
	else
	{
	    dXSTARG;
	    unsigned long frequency;
	    int result = ioctl(fd, RTC_IRQP_READ, &frequency);

	    if (result < 0)
		XPUSHs(&PL_sv_undef);
	    else
		XPUSHu(frequency);

	    XSRETURN(1);
	}

#endif

#if defined(RTC_PIE_ON) && defined(RTC_PIE_OFF)

void
periodic_interrupt(HV *rtc, bool fEnable)
    PROTOTYPE: \%$
    PPCODE:
	int fd = -1;
	SV **device = hv_fetch(rtc, "device", 6, 0);;

	if (device)
	{
	    IO *file_io = sv_2io(*device);

	    if (file_io)
	    {
		PerlIO *device_perlio = IoIFP(file_io);

		if (device_perlio)
		{
		    fd = PerlIO_fileno(device_perlio);

		    if (fd < 0)
			croak(invalidHandleMsg);
		}
		else
		    croak(invalidHandleMsg);
	    }
	    else
		croak(invalidHandleMsg);
	}
	else
	    croak(missingDeviceFileMsg);

	{
	    dXSTARG;
	    int result = ioctl(fd, fEnable ? RTC_PIE_ON : RTC_PIE_OFF, 0);

	    if (result < 0)
		XPUSHs(&PL_sv_undef);
	    else
		XPUSHu(result);

	    XSRETURN(1);
	}

#endif

#if defined(RTC_UIE_ON) && defined(RTC_UIE_OFF)

void
update_interrupt(HV *rtc, bool fEnable)
    PROTOTYPE: \%$
    PPCODE:
	int fd = -1;
	SV **device = hv_fetch(rtc, "device", 6, 0);;

	if (device)
	{
	    IO *file_io = sv_2io(*device);

	    if (file_io)
	    {
		PerlIO *device_perlio = IoIFP(file_io);

		if (device_perlio)
		{
		    fd = PerlIO_fileno(device_perlio);

		    if (fd < 0)
			croak(invalidHandleMsg);
		}
		else
		    croak(invalidHandleMsg);
	    }
	    else
		croak(invalidHandleMsg);
	}
	else
	    croak(missingDeviceFileMsg);

	{
	    dXSTARG;
	    int result = ioctl(fd, fEnable ? RTC_UIE_ON : RTC_UIE_OFF, 0);

	    if (result < 0)
		XPUSHs(&PL_sv_undef);
	    else
		XPUSHu(result);

	    XSRETURN(1);
	}

#endif

#if defined(RTC_AIE_ON) && defined(RTC_AIE_OFF)

void
alarm_interrupt(HV *rtc, bool fEnable)
    PROTOTYPE: \%$
    PPCODE:
	int fd = -1;
	SV **device = hv_fetch(rtc, "device", 6, 0);;

	if (device)
	{
	    IO *file_io = sv_2io(*device);

	    if (file_io)
	    {
		PerlIO *device_perlio = IoIFP(file_io);

		if (device_perlio)
		{
		    fd = PerlIO_fileno(device_perlio);

		    if (fd < 0)
			croak(invalidHandleMsg);
		}
		else
		    croak(invalidHandleMsg);
	    }
	    else
		croak(invalidHandleMsg);
	}
	else
	    croak(missingDeviceFileMsg);

	{
	    dXSTARG;
	    int result = ioctl(fd, fEnable ? RTC_AIE_ON : RTC_AIE_OFF, 0);

	    if (result < 0)
		XPUSHs(&PL_sv_undef);
	    else
		XPUSHu(result);

	    XSRETURN(1);
	}

#endif

#if defined(RTC_RD_TIME)

void
read_time(HV *rtc)
    PROTOTYPE: \%
    PPCODE:
	struct rtc_time tm = { 0, 0, 0,  0, 0, 0,  -1, -1, -1 };
	int fd = -1;
	SV **device = hv_fetch(rtc, "device", 6, 0);
	int result;

	if (device)
	{
	    IO *file_io = sv_2io(*device);

	    if (file_io)
	    {
		PerlIO *device_perlio = IoIFP(file_io);

		if (device_perlio)
		{
		    fd = PerlIO_fileno(device_perlio);

		    if (fd < 0)
			croak(invalidHandleMsg);
		}
		else
		    croak(invalidHandleMsg);
	    }
	    else
		croak(invalidHandleMsg);
	}
	else
	    croak(missingDeviceFileMsg);

	result = ioctl(fd, RTC_RD_TIME, &tm);

	if (result < 0)
	{
	    XPUSHs(&PL_sv_undef);
	    XSRETURN(1);
	}
	else
	    if (G_ARRAY == GIMME_V)
	    {
		/* called in list context, push time members on stack and do not store them. */
		EXTEND(SP, 9);
		mPUSHi(tm.tm_sec);
		mPUSHi(tm.tm_min);
		mPUSHi(tm.tm_hour);

		mPUSHi(tm.tm_mday);
		mPUSHi(tm.tm_mon);
		mPUSHi(tm.tm_year);

		mPUSHi(tm.tm_wday);
		mPUSHi(tm.tm_yday);
		mPUSHi(tm.tm_isdst);
		XSRETURN(9);
	    }
	    else
	    {
		dXSTARG;
		/* called in void (or scalar) context, save members in the perl object. */
		SV **val = hv_fetch(rtc, "sec", 3, !0);

		if (*val)
		    sv_setiv(*val, (IV)(tm.tm_sec));
		else
		    croak(hashAccessFailedMsg);

		val = hv_fetch(rtc, "min", 3, !0);
		if (*val)
		    sv_setiv(*val, (IV)(tm.tm_min));
		else
		    croak(hashAccessFailedMsg);

		val = hv_fetch(rtc, "hour", 4, !0);
		if (*val)
		    sv_setiv(*val, (IV)(tm.tm_hour));
		else
		    croak(hashAccessFailedMsg);

		val = hv_fetch(rtc, "mday", 4, !0);
		if (*val)
		    sv_setiv(*val, (IV)(tm.tm_mday));
		else
		    croak(hashAccessFailedMsg);

		val = hv_fetch(rtc, "mon", 3, !0);
		if (*val)
		    sv_setiv(*val, (IV)(tm.tm_mon));
		else
		    croak(hashAccessFailedMsg);

		val = hv_fetch(rtc, "year", 4, !0);
		if (*val)
		    sv_setiv(*val, (IV)(tm.tm_year));
		else
		    croak(hashAccessFailedMsg);

		val = hv_fetch(rtc, "wday", 4, !0);
		if (*val)
		    sv_setiv(*val, (IV)(tm.tm_wday));
		else
		    croak(hashAccessFailedMsg);

		val = hv_fetch(rtc, "yday", 4, !0);
		if (*val)
		    sv_setiv(*val, (IV)(tm.tm_yday));
		else
		    croak(hashAccessFailedMsg);

		val = hv_fetch(rtc, "isdst", 5, !0);
		if (*val)
		    sv_setiv(*val, (IV)(tm.tm_isdst));
		else
		    croak(hashAccessFailedMsg);

		XPUSHu(result);
		XSRETURN(1);
	    }

#endif

#if defined(RTC_SET_TIME)

void
set_time(HV *rtc, ...)
    PROTOTYPE: \*%;$$$$$$$$$
    PPCODE:
	int args_count = items;
	struct rtc_time tm = { 0, 0, 0,  0, 0, 0,  -1, -1, -1 };
	int fd = -1;
	SV **device = hv_fetch(rtc, "device", 6, 0);;

	if (device)
	{
	    IO *file_io = sv_2io(*device);

	    if (file_io)
	    {
		PerlIO *device_perlio = IoIFP(file_io);

		if (device_perlio)
		{
		    fd = PerlIO_fileno(device_perlio);

		    if (fd < 0)
			croak(invalidHandleMsg);
		}
		else
		    croak(invalidHandleMsg);
	    }
	    else
		croak(invalidHandleMsg);
	}
	else
	    croak(missingDeviceFileMsg);

	if (args_count > 10)
	    args_count = 10;

	switch (args_count)
	{
	case 10:
	    if (tm.tm_isdst = SvIV(ST(9)), SvIOK(ST(9)))
		;
	    else
		croak(numericParamMsg);
	    // fall-through
	case 9:
	    if (tm.tm_yday = SvIV(ST(8)), SvIOK(ST(8)))
		;
	    else
		croak(numericParamMsg);
	    // fall-through
	case 8:
	    if (tm.tm_wday = SvIV(ST(7)), SvIOK(ST(7)))
		;
	    else
		croak(numericParamMsg);
	    // fall-through
	case 7:
	    if (tm.tm_year = SvIV(ST(6)), SvIOK(ST(6)))
		;
	    else
		croak(numericParamMsg);
	    // fall-through
	case 6:
	    if (tm.tm_mon = SvIV(ST(5)), SvIOK(ST(5)))
		;
	    else
		croak(numericParamMsg);
	case 5:
	    if (tm.tm_mday = SvIV(ST(4)), SvIOK(ST(4)))
		;
	    else
		croak(numericParamMsg);
	    // fall-through
	case 4:
	    if (tm.tm_hour = SvIV(ST(3)), SvIOK(ST(3)))
		;
	    else
		croak(numericParamMsg);
	    // fall-through
	case 3:
	    if (tm.tm_min = SvIV(ST(2)), SvIOK(ST(2)))
		;
	    else
		croak(numericParamMsg);
	    // fall-through
	case 2:
	    if (tm.tm_sec = SvIV(ST(1)), SvIOK(ST(1)))
		;
	    else
		croak(numericParamMsg);
	    break;
	case 1:
	    {
		SV **val = hv_fetch(rtc, "isdst", 5, 0);

		if (*val && (tm.tm_isdst = SvIV(*val), SvIOK(*val)))
		    ;
		else
		    croak(objectFieldsMissingMsg, "isdst");

		val = hv_fetch(rtc, "yday", 4, 0);
		if (*val && (tm.tm_yday = SvIV(*val), SvIOK(*val)))
		    ;
		else
		    croak(objectFieldsMissingMsg, "yday");

		val = hv_fetch(rtc, "wday", 4, 0);
		if (*val && (tm.tm_wday = SvIV(*val), SvIOK(*val)))
		    ;
		else
		    croak(objectFieldsMissingMsg, "wday");

		val = hv_fetch(rtc, "year", 4, 0);
		if (*val && (tm.tm_year = SvIV(*val), SvIOK(*val)))
		    ;
		else
		    croak(objectFieldsMissingMsg, "year");

		val = hv_fetch(rtc, "mon", 3, 0);
		if (*val && (tm.tm_mon = SvIV(*val), SvIOK(*val)))
		    ;
		else
		    croak(objectFieldsMissingMsg, "mon");

		val = hv_fetch(rtc, "mday", 4, 0);
		if (*val && (tm.tm_mday = SvIV(*val), SvIOK(*val)))
		    ;
		else
		    croak(objectFieldsMissingMsg, "mday");

		val = hv_fetch(rtc, "hour", 4, 0);
		if (*val && (tm.tm_hour = SvIV(*val), SvIOK(*val)))
		    ;
		else
		    croak(objectFieldsMissingMsg, "hour");

		val = hv_fetch(rtc, "min", 3, 0);
		if (*val && (tm.tm_min = SvIV(*val), SvIOK(*val)))
		    ;
		else
		    croak(objectFieldsMissingMsg, "min");

		val = hv_fetch(rtc, "sec", 3, 0);
		if (*val && (tm.tm_sec = SvIV(*val), SvIOK(*val)))
		    ;
		else
		    croak(objectFieldsMissingMsg, "sec");

		break;
	    }
	}

	{
	    dXSTARG;
	    int result = ioctl(fd, RTC_SET_TIME, &tm);

	    if (result < 0)
		XPUSHs(&PL_sv_undef);
	    else
		XPUSHu(result);

	    XSRETURN(1);
	}

#endif

#if defined(RTC_ALM_READ)

void
read_alarm(HV *rtc)
    PROTOTYPE: \%
    PPCODE:
	struct rtc_time tm = { 0, 0, 0,  0, 0, 0,  -1, -1, -1 };
	int fd = -1;
	SV **device = hv_fetch(rtc, "device", 6, 0);;
	int result;

	if (device)
	{
	    IO *file_io = sv_2io(*device);

	    if (file_io)
	    {
		PerlIO *device_perlio = IoIFP(file_io);

		if (device_perlio)
		{
		    fd = PerlIO_fileno(device_perlio);

		    if (fd < 0)
			croak(invalidHandleMsg);
		}
		else
		    croak(invalidHandleMsg);
	    }
	    else
		croak(invalidHandleMsg);
	}
	else
	    croak(missingDeviceFileMsg);

	result = ioctl(fd, RTC_ALM_READ, &tm);

	if (result < 0)
	{
	    XPUSHs(&PL_sv_undef);
	    XSRETURN(1);
	}
	else
	    if (G_ARRAY == GIMME_V)
	    {
		/* called in list context, push time members on stack and do not store them. */
		EXTEND(SP, 9);
		mPUSHi(tm.tm_sec);
		mPUSHi(tm.tm_min);
		mPUSHi(tm.tm_hour);

		mPUSHi(tm.tm_mday);
		mPUSHi(tm.tm_mon);
		mPUSHi(tm.tm_year);

		mPUSHi(tm.tm_wday);
		mPUSHi(tm.tm_yday);
		mPUSHi(tm.tm_isdst);
		XSRETURN(9);
	    }
	    else
	    {
		dXSTARG;

		/* called in void (or scalar) context, save members in the perl object. */
		SV **val = hv_fetch(rtc, "sec", 3, !0);

		if (*val)
		    sv_setiv(*val, (IV)(tm.tm_sec));
		else
		    croak(hashAccessFailedMsg);

		val = hv_fetch(rtc, "min", 3, !0);
		if (*val)
		    sv_setiv(*val, (IV)(tm.tm_min));
		else
		    croak(hashAccessFailedMsg);

		val = hv_fetch(rtc, "hour", 4, !0);
		if (*val)
		    sv_setiv(*val, (IV)(tm.tm_hour));
		else
		    croak(hashAccessFailedMsg);

		val = hv_fetch(rtc, "mday", 4, !0);
		if (*val)
		    sv_setiv(*val, (IV)(tm.tm_mday));
		else
		    croak(hashAccessFailedMsg);

		val = hv_fetch(rtc, "mon", 3, !0);
		if (*val)
		    sv_setiv(*val, (IV)(tm.tm_mon));
		else
		    croak(hashAccessFailedMsg);

		val = hv_fetch(rtc, "year", 4, !0);
		if (*val)
		    sv_setiv(*val, (IV)(tm.tm_year));
		else
		    croak(hashAccessFailedMsg);

		val = hv_fetch(rtc, "wday", 4, !0);
		if (*val)
		    sv_setiv(*val, (IV)(tm.tm_wday));
		else
		    croak(hashAccessFailedMsg);

		val = hv_fetch(rtc, "yday", 4, !0);
		if (*val)
		    sv_setiv(*val, (IV)(tm.tm_yday));
		else
		    croak(hashAccessFailedMsg);

		val = hv_fetch(rtc, "isdst", 5, !0);
		if (*val)
		    sv_setiv(*val, (IV)(tm.tm_isdst));
		else
		    croak(hashAccessFailedMsg);

		XPUSHu(result);
		XSRETURN(1);
	    }

#endif


#if defined(RTC_ALM_SET)

void
set_alarm(HV *rtc, ...)
    PROTOTYPE: \*%;$$$$$$$$$
    PPCODE:
	int args_count = items;
	struct rtc_time tm = { 0, 0, 0,  0, 0, 0,  -1, -1, -1 };
	int fd = -1;
	SV **device = hv_fetch(rtc, "device", 6, 0);;

	if (device)
	{
	    IO *file_io = sv_2io(*device);

	    if (file_io)
	    {
		PerlIO *device_perlio = IoIFP(file_io);

		if (device_perlio)
		{
		    fd = PerlIO_fileno(device_perlio);

		    if (fd < 0)
			croak(invalidHandleMsg);
		}
		else
		    croak(invalidHandleMsg);
	    }
	    else
		croak(invalidHandleMsg);
	}
	else
	    croak(missingDeviceFileMsg);

	if (args_count > 10)
	    args_count = 10;

	switch (args_count)
	{
	case 10:
	    if (tm.tm_isdst = SvIV(ST(9)), SvIOK(ST(9)))
		;
	    else
		croak(numericParamMsg);
	    // fall-through
	case 9:
	    if (tm.tm_yday = SvIV(ST(8)), SvIOK(ST(8)))
		;
	    else
		croak(numericParamMsg);
	    // fall-through
	case 8:
	    if (tm.tm_wday = SvIV(ST(7)), SvIOK(ST(7)))
		;
	    else
		croak(numericParamMsg);
	    // fall-through
	case 7:
	    if (tm.tm_year = SvIV(ST(6)), SvIOK(ST(6)))
		;
	    else
		croak(numericParamMsg);
	    // fall-through
	case 6:
	    if (tm.tm_mon = SvIV(ST(5)), SvIOK(ST(5)))
		;
	    else
		croak(numericParamMsg);
	case 5:
	    if (tm.tm_mday = SvIV(ST(4)), SvIOK(ST(4)))
		;
	    else
		croak(numericParamMsg);
	    // fall-through
	case 4:
	    if (tm.tm_hour = SvIV(ST(3)), SvIOK(ST(3)))
		;
	    else
		croak(numericParamMsg);
	    // fall-through
	case 3:
	    if (tm.tm_min = SvIV(ST(2)), SvIOK(ST(2)))
		;
	    else
		croak(numericParamMsg);
	    // fall-through
	case 2:
	    if (tm.tm_sec = SvIV(ST(1)), SvIOK(ST(1)))
		;
	    else
		croak(numericParamMsg);
	    break;
	case 1:
	    {
		SV **val = hv_fetch(rtc, "isdst", 5, 0);

		if (*val && (tm.tm_isdst = SvIV(*val), SvIOK(*val)))
		    ;
		else
		    croak(objectFieldsMissingMsg, "isdst");

		val = hv_fetch(rtc, "yday", 4, 0);
		if (*val && (tm.tm_yday = SvIV(*val), SvIOK(*val)))
		    ;
		else
		    croak(objectFieldsMissingMsg, "yday");

		val = hv_fetch(rtc, "wday", 4, 0);
		if (*val && (tm.tm_wday = SvIV(*val), SvIOK(*val)))
		    ;
		else
		    croak(objectFieldsMissingMsg, "wday");

		val = hv_fetch(rtc, "year", 4, 0);
		if (*val && (tm.tm_year = SvIV(*val), SvIOK(*val)))
		    ;
		else
		    croak(objectFieldsMissingMsg, "year");

		val = hv_fetch(rtc, "mon", 3, 0);
		if (*val && (tm.tm_mon = SvIV(*val), SvIOK(*val)))
		    ;
		else
		    croak(objectFieldsMissingMsg, "mon");

		val = hv_fetch(rtc, "mday", 4, 0);
		if (*val && (tm.tm_mday = SvIV(*val), SvIOK(*val)))
		    ;
		else
		    croak(objectFieldsMissingMsg, "mday");

		val = hv_fetch(rtc, "hour", 4, 0);
		if (*val && (tm.tm_hour = SvIV(*val), SvIOK(*val)))
		    ;
		else
		    croak(objectFieldsMissingMsg, "hour");

		val = hv_fetch(rtc, "min", 3, 0);
		if (*val && (tm.tm_min = SvIV(*val), SvIOK(*val)))
		    ;
		else
		    croak(objectFieldsMissingMsg, "min");

		val = hv_fetch(rtc, "sec", 3, 0);
		if (*val && (tm.tm_sec = SvIV(*val), SvIOK(*val)))
		    ;
		else
		    croak(objectFieldsMissingMsg, "sec");

		break;
	    }
	}

	{
	    dXSTARG;
	    int result = ioctl(fd, RTC_ALM_SET, &tm);

	    if (result < 0)
		XPUSHs(&PL_sv_undef);
	    else
		XPUSHu(result);

	    XSRETURN(1);
	}

#endif

#if defined(RTC_WKALM_RD)

void
read_wakeup_alarm(HV *rtc)
    PROTOTYPE: \%
    PPCODE:
	struct rtc_wkalrm tm = { 0, 0, { 0, 0, 0,  0, 0, 0,  -1, -1, -1 } };
	int fd = -1;
	SV **device = hv_fetch(rtc, "device", 6, 0);;
	int result;

	if (device)
	{
	    IO *file_io = sv_2io(*device);

	    if (file_io)
	    {
		PerlIO *device_perlio = IoIFP(file_io);

		if (device_perlio)
		{
		    fd = PerlIO_fileno(device_perlio);

		    if (fd < 0)
			croak(invalidHandleMsg);
		}
		else
		    croak(invalidHandleMsg);
	    }
	    else
		croak(invalidHandleMsg);
	}
	else
	    croak(missingDeviceFileMsg);

	result = ioctl(fd, RTC_WKALM_RD, &tm);

	if (result < 0)
	{
	    XPUSHs(&PL_sv_undef);
	    XSRETURN(1);
	}
	else
	    if (G_ARRAY == GIMME_V)
	    {
		/* called in list context, push time members on stack and do not store them. */
		EXTEND(SP, 11);
		mPUSHi(tm.enabled);
		mPUSHi(tm.pending);

		mPUSHi(tm.time.tm_sec);
		mPUSHi(tm.time.tm_min);
		mPUSHi(tm.time.tm_hour);

		mPUSHi(tm.time.tm_mday);
		mPUSHi(tm.time.tm_mon);
		mPUSHi(tm.time.tm_year);

		mPUSHi(tm.time.tm_wday);
		mPUSHi(tm.time.tm_yday);
		mPUSHi(tm.time.tm_isdst);
		XSRETURN(9);
	    }
	    else
	    {
		dXSTARG;

		/* called in void (or scalar) context, save members in the perl object. */
		SV **val = hv_fetch(rtc, "enabled", 7, !0);

		if (*val)
		    sv_setiv(*val, (IV)(tm.enabled));
		else
		    croak(hashAccessFailedMsg);

		val = hv_fetch(rtc, "pending", 7, !0);
		if (*val)
		    sv_setiv(*val, (IV)(tm.pending));
		else
		    croak(hashAccessFailedMsg);

		val = hv_fetch(rtc, "sec", 3, !0);
		if (*val)
		    sv_setiv(*val, (IV)(tm.time.tm_sec));
		else
		    croak(hashAccessFailedMsg);

		val = hv_fetch(rtc, "min", 3, !0);
		if (*val)
		    sv_setiv(*val, (IV)(tm.time.tm_min));
		else
		    croak(hashAccessFailedMsg);

		val = hv_fetch(rtc, "hour", 4, !0);
		if (*val)
		    sv_setiv(*val, (IV)(tm.time.tm_hour));
		else
		    croak(hashAccessFailedMsg);

		val = hv_fetch(rtc, "mday", 4, !0);
		if (*val)
		    sv_setiv(*val, (IV)(tm.time.tm_mday));
		else
		    croak(hashAccessFailedMsg);

		val = hv_fetch(rtc, "mon", 3, !0);
		if (*val)
		    sv_setiv(*val, (IV)(tm.time.tm_mon));
		else
		    croak(hashAccessFailedMsg);

		val = hv_fetch(rtc, "year", 4, !0);
		if (*val)
		    sv_setiv(*val, (IV)(tm.time.tm_year));
		else
		    croak(hashAccessFailedMsg);

		val = hv_fetch(rtc, "wday", 4, !0);
		if (*val)
		    sv_setiv(*val, (IV)(tm.time.tm_wday));
		else
		    croak(hashAccessFailedMsg);

		val = hv_fetch(rtc, "yday", 4, !0);
		if (*val)
		    sv_setiv(*val, (IV)(tm.time.tm_yday));
		else
		    croak(hashAccessFailedMsg);

		val = hv_fetch(rtc, "isdst", 5, !0);
		if (*val)
		    sv_setiv(*val, (IV)(tm.time.tm_isdst));
		else
		    croak(hashAccessFailedMsg);

		XPUSHu(result);
		XSRETURN(1);
	    }

#endif


#if defined(RTC_WKALM_SET)

void
set_wakeup_alarm(HV *rtc, ...)
    PROTOTYPE: \*%;$$$$$$$$$
    PPCODE:
	int args_count = items;
	struct rtc_wkalrm tm = { 0, 0, { 0, 0, 0,  0, 0, 0,  -1, -1, -1 } };
	int fd = -1;
	SV **device = hv_fetch(rtc, "device", 6, 0);;

	if (device)
	{
	    IO *file_io = sv_2io(*device);

	    if (file_io)
	    {
		PerlIO *device_perlio = IoIFP(file_io);

		if (device_perlio)
		{
		    fd = PerlIO_fileno(device_perlio);

		    if (fd < 0)
			croak(invalidHandleMsg);
		}
		else
		    croak(invalidHandleMsg);
	    }
	    else
		croak(invalidHandleMsg);
	}
	else
	    croak(missingDeviceFileMsg);

	if (args_count > 10)
	    args_count = 10;

	switch (args_count)
	{
	case 12:
	    if (tm.time.tm_isdst = SvIV(ST(11)), SvIOK(ST(11)))
		;
	    else
		croak(numericParamMsg);
	    // fall-through
	case 11:
	    if (tm.time.tm_yday = SvIV(ST(10)), SvIOK(ST(10)))
		;
	    else
		croak(numericParamMsg);
	    // fall-through
	case 10:
	    if (tm.time.tm_wday = SvIV(ST(9)), SvIOK(ST(9)))
		;
	    else
		croak(numericParamMsg);
	    // fall-through
	case 9:
	    if (tm.time.tm_year = SvIV(ST(8)), SvIOK(ST(8)))
		;
	    else
		croak(numericParamMsg);
	    // fall-through
	case 8:
	    if (tm.time.tm_mon = SvIV(ST(7)), SvIOK(ST(7)))
		;
	    else
		croak(numericParamMsg);
	case 7:
	    if (tm.time.tm_mday = SvIV(ST(6)), SvIOK(ST(6)))
		;
	    else
		croak(numericParamMsg);
	    // fall-through
	case 6:
	    if (tm.time.tm_hour = SvIV(ST(5)), SvIOK(ST(5)))
		;
	    else
		croak(numericParamMsg);
	    // fall-through
	case 5:
	    if (tm.time.tm_min = SvIV(ST(4)), SvIOK(ST(4)))
		;
	    else
		croak(numericParamMsg);
	    // fall-through
	case 4:
	    if (tm.time.tm_sec = SvIV(ST(3)), SvIOK(ST(3)))
		;
	    else
		croak(numericParamMsg);
	    // fall-through
	case 3:
	    if (tm.pending = SvIV(ST(2)), SvIOK(ST(2)))
		;
	    else
		croak(numericParamMsg);
	    // fall-through
	case 2:
	    if (tm.enabled = SvIV(ST(1)), SvIOK(ST(1)))
		;
	    else
		croak(numericParamMsg);
	    break;
	case 1:
	    {
		SV **val = hv_fetch(rtc, "isdst", 5, 0);

		if (*val && (tm.time.tm_isdst = SvIV(*val), SvIOK(*val)))
		    ;
		else
		    croak(objectFieldsMissingMsg, "isdst");

		val = hv_fetch(rtc, "yday", 4, 0);
		if (*val && (tm.time.tm_yday = SvIV(*val), SvIOK(*val)))
		    ;
		else
		    croak(objectFieldsMissingMsg, "yday");

		val = hv_fetch(rtc, "wday", 4, 0);
		if (*val && (tm.time.tm_wday = SvIV(*val), SvIOK(*val)))
		    ;
		else
		    croak(objectFieldsMissingMsg, "wday");

		val = hv_fetch(rtc, "year", 4, 0);
		if (*val && (tm.time.tm_year = SvIV(*val), SvIOK(*val)))
		    ;
		else
		    croak(objectFieldsMissingMsg, "year");

		val = hv_fetch(rtc, "mon", 3, 0);
		if (*val && (tm.time.tm_mon = SvIV(*val), SvIOK(*val)))
		    ;
		else
		    croak(objectFieldsMissingMsg, "mon");

		val = hv_fetch(rtc, "mday", 4, 0);
		if (*val && (tm.time.tm_mday = SvIV(*val), SvIOK(*val)))
		    ;
		else
		    croak(objectFieldsMissingMsg, "mday");

		val = hv_fetch(rtc, "hour", 4, 0);
		if (*val && (tm.time.tm_hour = SvIV(*val), SvIOK(*val)))
		    ;
		else
		    croak(objectFieldsMissingMsg, "hour");

		val = hv_fetch(rtc, "min", 3, 0);
		if (*val && (tm.time.tm_min = SvIV(*val), SvIOK(*val)))
		    ;
		else
		    croak(objectFieldsMissingMsg, "min");

		val = hv_fetch(rtc, "sec", 3, 0);
		if (*val && (tm.time.tm_sec = SvIV(*val), SvIOK(*val)))
		    ;
		else
		    croak(objectFieldsMissingMsg, "sec");

		val = hv_fetch(rtc, "pending", 7, 0);
		if (*val && (tm.pending = SvIV(*val), SvIOK(*val)))
		    ;
		else
		    croak(objectFieldsMissingMsg, "pending");

		val = hv_fetch(rtc, "enabled", 7, 0);
		if (*val && (tm.enabled = SvIV(*val), SvIOK(*val)))
		    ;
		else
		    croak(objectFieldsMissingMsg, "enabled");

		break;
	    }

	    break;
	}

	{
	    dXSTARG;
	    int result = ioctl(fd, RTC_WKALM_SET, &tm);

	    if (result < 0)
		XPUSHs(&PL_sv_undef);
	    else
		XPUSHu(result);

	    XSRETURN(1);
	}

#endif

#if defined(RTC_VL_READ)

void
read_voltage_low_indicator(HV *rtc)
    PROTOTYPE: \%
    PPCODE:
	int result, voltage_low_indicator;
	int fd = -1;
	SV **device = hv_fetch(rtc, "device", 6, 0);;

	if (device)
	{
	    IO *file_io = sv_2io(*device);

	    if (file_io)
	    {
		PerlIO *device_perlio = IoIFP(file_io);

		if (device_perlio)
		{
		    fd = PerlIO_fileno(device_perlio);

		    if (fd < 0)
			croak(invalidHandleMsg);
		}
		else
		    croak(invalidHandleMsg);
	    }
	    else
		croak(invalidHandleMsg);
	}
	else
	    croak(missingDeviceFileMsg);

	result = ioctl(fd, RTC_VL_READ, &voltage_low_indicator);

	if (result < 0)
	    XSRETURN_UNDEF;
	else
	{
	    dXSTARG;
	    XPUSHi(voltage_low_indicator);
	    XSRETURN(1);
	}

#endif

#if defined(RTC_VL_CLR)

void
clear_voltage_low_indicator(HV *rtc)
    PROTOTYPE: \%
    PPCODE:
	int fd = -1;
	SV **device = hv_fetch(rtc, "device", 6, 0);;

	if (device)
	{
	    IO *file_io = sv_2io(*device);

	    if (file_io)
	    {
		PerlIO *device_perlio = IoIFP(file_io);

		if (device_perlio)
		{
		    fd = PerlIO_fileno(device_perlio);

		    if (fd < 0)
			croak(invalidHandleMsg);
		}
		else
		    croak(invalidHandleMsg);
	    }
	    else
		croak(invalidHandleMsg);
	}
	else
	    croak(missingDeviceFileMsg);

	{
	    dXSTARG;
	    int result = ioctl(fd, RTC_VL_CLR, 0);

	    if (result < 0)
		XPUSHs(&PL_sv_undef);
	    else
		XPUSHu(result);

	    XSRETURN(1);
	}

#endif

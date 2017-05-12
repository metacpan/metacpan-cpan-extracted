#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <fcntl.h>
#include <sys/soundcard.h>

#define BUFFSIZE 1024

int seqfd = -1;
int OSS_initialized = 0;

SEQ_DEFINEBUF(BUFFSIZE);

#ifndef OSSLIB 
void seqbuf_dump () {

    if (_seqbufptr) { 

        if (write(seqfd, _seqbuf, _seqbufptr) == -1)
            croak("write /dev/music");
    }
    _seqbufptr = 0;
} 
#endif

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(char *name, int arg)
{
    errno = 0;
    switch (*name) {
    case 'A':
        break;
    case 'B':
        break;
    case 'C':
        break;
    case 'D':
        break;
    case 'E':
        if (strEQ(name, "EV_CHN_COMMON"))
#ifdef EV_CHN_COMMON
            return EV_CHN_COMMON;
#else
            goto not_there;
#endif
        if (strEQ(name, "EV_CHN_VOICE"))
#ifdef EV_CHN_VOICE
            return EV_CHN_VOICE;
#else
            goto not_there;
#endif
        if (strEQ(name, "EV_SEQ_LOCAL"))
#ifdef EV_SEQ_LOCAL
            return EV_SEQ_LOCAL;
#else
            goto not_there;
#endif
        if (strEQ(name, "EV_SYSEX"))
#ifdef EV_SYSEX
            return EV_SYSEX;
#else
            goto not_there;
#endif
        if (strEQ(name, "EV_SYSTEM"))
#ifdef EV_SYSTEM
            return EV_SYSTEM;
#else
            goto not_there;
#endif
        if (strEQ(name, "EV_TIMING"))
#ifdef EV_TIMING
            return EV_TIMING;
#else
            goto not_there;
#endif
        break;
    case 'F':
        break;
    case 'G':
        break;
    case 'H':
        break;
    case 'I':
        break;
    case 'J':
        break;
    case 'K':
        break;
    case 'L':
        break;
    case 'M':
        if (strEQ(name, "MIDI_CHN_PRESSURE"))
#ifdef MIDI_CHN_PRESSURE
            return MIDI_CHN_PRESSURE;
#else
            goto not_there;
#endif
        if (strEQ(name, "MIDI_CTL_CHANGE"))
#ifdef MIDI_CTL_CHANGE
            return MIDI_CTL_CHANGE;
#else
            goto not_there;
#endif
        if (strEQ(name, "MIDI_KEY_PRESSURE"))
#ifdef MIDI_KEY_PRESSURE
            return MIDI_KEY_PRESSURE;
#else
            goto not_there;
#endif
        if (strEQ(name, "MIDI_NOTEOFF"))
#ifdef MIDI_NOTEOFF
            return MIDI_NOTEOFF;
#else
            goto not_there;
#endif
        if (strEQ(name, "MIDI_NOTEON"))
#ifdef MIDI_NOTEON
            return MIDI_NOTEON;
#else
            goto not_there;
#endif
        if (strEQ(name, "MIDI_PGM_CHANGE"))
#ifdef MIDI_PGM_CHANGE
            return MIDI_PGM_CHANGE;
#else
            goto not_there;
#endif
        if (strEQ(name, "MIDI_PITCH_BEND"))
#ifdef MIDI_PITCH_BEND
            return MIDI_PITCH_BEND;
#else
            goto not_there;
#endif
        break;
    case 'N':
        break;
    case 'O':
        break;
    case 'P':
        break;
    case 'Q':
        break;
    case 'R':
        break;
    case 'S':
        break;
    case 'T':
        if (strEQ(name, "TMR_CLOCK"))
#ifdef TMR_CLOCK
            return TMR_CLOCK;
#else
            goto not_there;
#endif
        if (strEQ(name, "TMR_CONTINUE"))
#ifdef TMR_CONTINUE
            return TMR_CONTINUE;
#else
            goto not_there;
#endif
        if (strEQ(name, "TMR_ECHO"))
#ifdef TMR_ECHO
            return TMR_ECHO;
#else
            goto not_there;
#endif
        if (strEQ(name, "TMR_EXTERNAL"))
#ifdef TMR_EXTERNAL
            return TMR_EXTERNAL;
#else
            goto not_there;
#endif
        if (strEQ(name, "TMR_INTERNAL"))
#ifdef TMR_INTERNAL
            return TMR_INTERNAL;
#else
            goto not_there;
#endif
        if (strEQ(name, "TMR_MODE_CLS"))
#ifdef TMR_MODE_CLS
            return TMR_MODE_CLS;
#else
            goto not_there;
#endif
        if (strEQ(name, "TMR_MODE_FSK"))
#ifdef TMR_MODE_FSK
            return TMR_MODE_FSK;
#else
            goto not_there;
#endif
        if (strEQ(name, "TMR_MODE_MIDI"))
#ifdef TMR_MODE_MIDI
            return TMR_MODE_MIDI;
#else
            goto not_there;
#endif
        if (strEQ(name, "TMR_MODE_SMPTE"))
#ifdef TMR_MODE_SMPTE
            return TMR_MODE_SMPTE;
#else
            goto not_there;
#endif
        if (strEQ(name, "TMR_SPP"))
#ifdef TMR_SPP
            return TMR_SPP;
#else
            goto not_there;
#endif
        if (strEQ(name, "TMR_START"))
#ifdef TMR_START
            return TMR_START;
#else
            goto not_there;
#endif
        if (strEQ(name, "TMR_STOP"))
#ifdef TMR_STOP
            return TMR_STOP;
#else
            goto not_there;
#endif
        if (strEQ(name, "TMR_TEMPO"))
#ifdef TMR_TEMPO
            return TMR_TEMPO;
#else
            goto not_there;
#endif
        if (strEQ(name, "TMR_TIMESIG"))
#ifdef TMR_TIMESIG
            return TMR_TIMESIG;
#else
            goto not_there;
#endif
        if (strEQ(name, "TMR_WAIT_ABS"))
#ifdef TMR_WAIT_ABS
            return TMR_WAIT_ABS;
#else
            goto not_there;
#endif
        if (strEQ(name, "TMR_WAIT_REL"))
#ifdef TMR_WAIT_REL
            return TMR_WAIT_REL;
#else
            goto not_there;
#endif
        break;
    case 'U':
        break;
    case 'V':
        break;
    case 'W':
        break;
    case 'X':
        break;
    case 'Y':
        break;
    case 'Z':
        break;
    case '_':
        break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

MODULE = MIDI::Music		PACKAGE = MIDI::Music		

PROTOTYPES: ENABLE

double
constant(name,arg)
	char *		name
	int		arg


############################################################################
######################## opening/closing device ############################

void
init(mm, ...)
	SV * mm
	PREINIT:
	int    error, dev_no, ndevices, stidx, tmp, wanted, arrlen, arridx;
	int    mode = O_RDWR;
	char * key;
	SV   * gminstr_ref;
	SV   * gmdrum_ref;
	SV   * timesig_ref;
	HV   * towhich = (HV*)SvRV(mm);
	CODE:
	{
	    if ((items % 2) == 0)
	        croak("Odd number of elements in hash list");

	    for (stidx = 1; stidx < items; stidx += 2) {

	        key = SvPVX(ST(stidx));

	        if (strEQ(key, "mode")) {
	            mode = SvIV(ST(stidx + 1));
	        } else if (strEQ(key, "device")) {
	            hv_store(towhich, "_device", 7, newSVsv(ST(stidx + 1)), 0);

	        /********************************
	         * Recording-related parameters */
	        } else if (strEQ(key, "readbuf")) {
	            hv_store(towhich, "_readbuf", 8, newSVsv(ST(stidx + 1)), 0);
##	        } else if (strEQ(key, "actsense")) {
##	            hv_store(towhich, "_actsense", 9, newSVsv(ST(stidx + 1)), 0);
	        } else if (strEQ(key, "realtime")) {
	            hv_store(towhich, "_realtime", 9, newSVsv(ST(stidx + 1)), 0);
##	        } else if (strEQ(key, "timing")) {
##	            hv_store(towhich, "_timing", 7, newSVsv(ST(stidx + 1)), 0);

	        /********************************
	         *  Playback-related parameters */
##	        } else if (strEQ(key, "extbuf")) { 
##	            hv_store(towhich, "_extbuf", 7, newSVsv(ST(stidx + 1)), 0);
	        } else if (strEQ(key, "gmdrum")) {
	            hv_store(towhich, "_gmdrum", 7, newSVsv(ST(stidx + 1)), 0);
	        } else if (strEQ(key, "gminstr")) {
	            hv_store(towhich, "_gminstr", 8, newSVsv(ST(stidx + 1)), 0);
	        } else if (strEQ(key, "tempo")) {
	            hv_store(towhich, "_tempo", 6, newSVsv(ST(stidx + 1)), 0);
	        } else if (strEQ(key, "timebase")) {
	            hv_store(towhich, "_timebase", 9, newSVsv(ST(stidx + 1)), 0);
	        } else if (strEQ(key, "timesig")) {
	            hv_store(towhich, "_timesig", 8, newSVsv(ST(stidx + 1)), 0);
	        }
	    }

	    /*************************************************
	     * open the device, initialize OSSlib if present */ 
	    if ((seqfd = open("/dev/music", mode, 0)) == -1) {

	        hv_store(towhich, "_errstr", 7,
	                 newSVpvf("%s::init(): failed to open device '/dev/music'",
	                          HvNAME(SvSTASH(towhich))), 0);

	        XSRETURN_NO;
	    }
#ifdef OSSLIB
	    if (!OSS_initialized) {
	        if ((error = OSS_init(seqfd, BUFFSIZE)) != 0) {

	            hv_store(towhich, "_errstr", 7,
	                     newSVpvf("%s::init(): failed to initialize OSSlib, error %d",
	                              HvNAME(SvSTASH(towhich)), error), 0);
	            XSRETURN_NO;
	        }
	        OSS_initialized = 1;
	    }
#endif
	    if (ioctl(seqfd, SNDCTL_SEQ_NRSYNTHS, &ndevices) == -1) {
	        hv_store(towhich, "_errstr", 7,
	                 newSVpvf("%s::init(): device unavailable",
	                          HvNAME(SvSTASH(towhich))), 0);
	        XSRETURN_NO;
	    }

	    if (SvIV(*hv_fetch(towhich, "_device", 7, 0)) >= ndevices) {
	        hv_store(towhich, "_errstr", 7,
	                 newSVpvf("%s::init(): device doesn't exist",
	                          HvNAME(SvSTASH(towhich))), 0);
	        XSRETURN_NO;
	    }

	    /*********************************
	     * Set initial timing parameters */
	    tmp = wanted = SvIV(*hv_fetch(towhich, "_timebase", 9, 0));

	    if (ioctl(seqfd, SNDCTL_TMR_TIMEBASE, &tmp) == -1) {
	        hv_store(towhich, "_errstr", 7,
	                 newSVpvf("%s::init(): failed to set timebase",
	                          HvNAME(SvSTASH(towhich))), 0);
	        XSRETURN_NO;
	    }
	    if (tmp != wanted) {
	        hv_store(towhich, "_errstr", 7,
	                 newSVpvf("%s::init(): failed setting timebase to %d",
	                          HvNAME(SvSTASH(towhich)), wanted), 0);
	        XSRETURN_NO;
	    }

	    tmp = wanted = SvIV(*hv_fetch(towhich, "_tempo", 6, 0));
            if (ioctl(seqfd, SNDCTL_TMR_TEMPO, &tmp) == -1) {
                hv_store(towhich, "_errstr", 7,
                         newSVpvf("%s::init(): failed to set initial tempo",
                                  HvNAME(SvSTASH(towhich))), 0);
                XSRETURN_NO;
            }
	    if (tmp != wanted) {
	        hv_store(towhich, "_errstr", 7,
	                 newSVpvf("%s::init(): failed setting tempo to %d",
	                          HvNAME(SvSTASH(towhich)), wanted), 0);
	        XSRETURN_NO;
	    }

	    /* time signature is a little complicated */
	    timesig_ref = *hv_fetch(towhich, "_timesig", 8, 0);
	    wanted  = SvIV(*av_fetch( (AV*)SvRV(timesig_ref), 0, 0 )) << 24;
	    wanted |= SvIV(*av_fetch( (AV*)SvRV(timesig_ref), 1, 0 )) << 16;
	    wanted |= SvIV(*av_fetch( (AV*)SvRV(timesig_ref), 2, 0 )) << 8;
	    wanted |= SvIV(*av_fetch( (AV*)SvRV(timesig_ref), 3, 0 ));

            tmp = wanted;

	    if (ioctl(seqfd, SNDCTL_TMR_METRONOME, &tmp) == -1) {
#
#	        The above seems to be meaningless -- it is always the case.
#
#	        hv_store(towhich, "_errstr", 7,
#                         newSVpvf("%s::init(): failed to set initial time signature",
#                                  HvNAME(SvSTASH(towhich))), 0);
#	        XSRETURN_NO;
	    }
	    if (tmp != wanted) {
	        hv_store(towhich, "_errstr", 7,
	                 newSVpvf("%s::init(): failed setting time signature to [ %d, %d, %d, %d ]",
	                          HvNAME(SvSTASH(towhich)),
	                          SvIV(*av_fetch( (AV*)SvRV(timesig_ref), 0, 0 )),
	                          SvIV(*av_fetch( (AV*)SvRV(timesig_ref), 1, 0 )),
	                          SvIV(*av_fetch( (AV*)SvRV(timesig_ref), 2, 0 )),
	                          SvIV(*av_fetch( (AV*)SvRV(timesig_ref), 3, 0 ))), 0);
	        XSRETURN_NO;
	    }

	    dev_no = SvIV(*hv_fetch(towhich, "_device", 7, 0));

	    /**********************************
	     * instrument caching for playback*/
	    if ((mode == O_RDWR) || (mode == O_WRONLY)) {
	        gminstr_ref = *hv_fetch(towhich, "_gminstr", 8, 0);
	        gmdrum_ref  = *hv_fetch(towhich, "_gmdrum", 7, 0);

	        arrlen = av_len((AV*)SvRV(gminstr_ref));
	        if (arrlen != -1) {
	
	            for (arridx = 0; arridx <= arrlen; arridx++) {
	                SEQ_LOAD_GMINSTR(dev_no,
	                  SvIV(*av_fetch( (AV*)SvRV(gminstr_ref), arridx, 0 )));
	            }
	        }

	        arrlen = av_len((AV*)SvRV(gmdrum_ref));
	        if (arrlen != -1) {
	            for (arridx = 0; arridx <= arrlen; arridx++) {
	                SEQ_LOAD_GMDRUM(dev_no,
	                  SvIV(*av_fetch( (AV*)SvRV(gmdrum_ref), arridx, 0 )));
	            }
	        }
	    }

	    /*****************************
	     * recording-related options */
	    if ((mode == O_RDWR) || (mode == O_RDONLY)) {

##	        if (SvIV(*hv_fetch(towhich, "_actsense", 9, 0))) {
###ifdef SNDCTL_SEQ_ACTSENSE_ENABLE
##	            if (ioctl(seqfd, SNDCTL_SEQ_ACTSENSE_ENABLE, 0) == -1) {
##	                hv_store(towhich, "_errstr", 7,
##	                         newSVpvf("%s::init(): /dev/music ACTSENSE_ENABLE failed",
##	                                  HvNAME(SvSTASH(towhich))), 0);
##	                XSRETURN_NO;
##	            }
###else
##	            hv_store(towhich, "_errstr", 7,
##	                     newSVpvf("%s::init(): 'actsense' option not available",
##	                              HvNAME(SvSTASH(towhich))), 0);
##	            XSRETURN_NO;
###endif
##	        }
##
##	        if (SvIV(*hv_fetch(towhich, "_timing", 7, 0))) {
###ifdef SNDCTL_SEQ_TIMING_ENABLE
##	            if (ioctl(seqfd, SNDCTL_SEQ_TIMING_ENABLE, 0) == -1) {
##	                hv_store(towhich, "_errstr", 7,
##	                         newSVpvf("%s::init(): /dev/music TIMING_ENABLE failed",
##	                                  HvNAME(SvSTASH(towhich))), 0);
##	                XSRETURN_NO;
##	            }
###else
##	            hv_store(towhich, "_errstr", 7,
##	                     newSVpvf("%s::init(): 'timing' option not available",
##	                              HvNAME(SvSTASH(towhich))), 0);
##	            XSRETURN_NO;
###endif
##	        }

	        if (SvIV(*hv_fetch(towhich, "_realtime", 9, 0))) {
#ifdef SNDCTL_SEQ_RT_ENABLE
	            if (ioctl(seqfd, SNDCTL_SEQ_RT_ENABLE, 0) == -1) {
	                hv_store(towhich, "_errstr", 7,
	                         newSVpvf("%s::init(): /dev/music RT_ENABLE failed",
	                                  HvNAME(SvSTASH(towhich))), 0);
	                XSRETURN_NO;
	            }
#else
	            hv_store(towhich, "_errstr", 7,
	                     newSVpvf("%s::init(): 'realtime' option not available",
	                              HvNAME(SvSTASH(towhich))), 0);
	            XSRETURN_NO;
#endif
	        }
	        SEQ_START_TIMER();
	    }
	    hv_store(towhich, "_initialized", 12, newSViv(1), 0);
	    XSRETURN_YES;
	}

void
close(mm)
	SV * mm
	PREINIT:
	HV * towhich = (HV *)SvRV(mm);
	CODE:
	{
	    close(seqfd);
	    hv_store(towhich, "_initialized", 12, newSViv(0), 0);
	}

############################################################################
######################### reading from the device ##########################

void
_readblock(mm)
	SV * mm
	PREINIT:
	HV * towhich = (HV *)SvRV(mm);
	int  readbuf = SvIV(*hv_fetch(towhich, "_readbuf", 8, 0));
	int l;
	unsigned char midichars[readbuf];
	CODE:
	{
	    if ((l = read(seqfd, midichars, readbuf)) == -1) {

	        hv_store(towhich, "_errstr", 7,
	                 newSVpvf("%s::_readblock(): failed read on /dev/music",
	                          HvNAME(SvSTASH(towhich))), 0);
	        XSRETURN_UNDEF;

	    } else {

	        ST(0) = sv_newmortal();
	        sv_setpvn(ST(0), midichars, l);

	    }
	}

##########################
## Play an event structure

void
playevents(mm, event_struct)
	SV * mm
	SV * event_struct
	PREINIT:
	HV * towhich = (HV *)SvRV(mm);
	AV * events  = (AV*)SvRV(event_struct);
	AV * event;
	/*
	 * here I break things up the declarations
	 * in order to describe the data I'm dealing with
	 */
	int evs_index;
	char * event_type;
	int usecs_per_qn, bpm; /* tempo messages */
	int timesig;
	int chan, note, vel;   /* note messages */
	int controller, value; /* control messages */
	int patch;             /* 0 to 127 */
	int wheel;             /* -8192 to 8192 */
	int sysex_len;
	char * sysex_data;
	int dtime = 0, time = 0, last = time;
        int dev   = SvIV(*hv_fetch(towhich, "_device", 7, 0));
	CODE:
	{
	    SEQ_START_TIMER(); /* doesn't hurt. */
	    for (evs_index = 0; evs_index <= av_len(events); evs_index++) {

	        event = (AV*)SvRV(*av_fetch(events, evs_index, 0));

	        if (av_len(event) < 1) {
	            hv_store(towhich, "_errstr", 7,
	                     newSVpvf("%s::playevents(): %d elements in event (ought to have at least 2)",
	                              HvNAME(SvSTASH(towhich)), (av_len(event) + 1)), 0);
	             XSRETURN_NO;
	        }

	        event_type = SvPVX(*av_fetch(event, 0, 0));
	        dtime      = SvIV(*av_fetch(event, 1, 0));

	        if (dtime) {
	            last = time;
	            time = time + dtime;
	            SEQ_WAIT_TIME(time);
	        }

	        if (strEQ(event_type, "note_off")) {

	            if (av_len(event) != 4) {
	                hv_store(towhich, "_errstr", 7,
	                         newSVpvf("%s::playevents(): %d elements in note_off event",
	                                  HvNAME(SvSTASH(towhich)), (av_len(event) + 1)), 0);
	                 XSRETURN_NO;
	            }

	            chan = SvIV(*av_fetch(event, 2, 0));
	            note = SvIV(*av_fetch(event, 3, 0));
	            vel  = SvIV(*av_fetch(event, 4, 0));

	            SEQ_STOP_NOTE(dev, chan, note, vel);

	        } else if (strEQ(event_type, "note_on")) {

	            if (av_len(event) != 4) {
	                hv_store(towhich, "_errstr", 7,
                                 newSVpvf("%s::playevents(): %d elements in note_on event",
                                          HvNAME(SvSTASH(towhich)), (av_len(event) + 1)), 0);
	                XSRETURN_NO;
	            }

	            chan = SvIV(*av_fetch(event, 2, 0));
	            note = SvIV(*av_fetch(event, 3, 0));
	            vel  = SvIV(*av_fetch(event, 4, 0));

	            SEQ_START_NOTE(dev, chan, note, vel);

	        } else if (strEQ(event_type, "key_after_touch")) {

	            if (av_len(event) != 4) {
	                hv_store(towhich, "_errstr", 7,
                                 newSVpvf("%s::playevents(): %d elements in key_after_touch event",
                                          HvNAME(SvSTASH(towhich)), (av_len(event) + 1)), 0);
	                XSRETURN_NO;
	            }

	            chan = SvIV(*av_fetch(event, 2, 0));
	            note = SvIV(*av_fetch(event, 3, 0));
	            vel  = SvIV(*av_fetch(event, 4, 0));

	            SEQ_KEY_PRESSURE(dev, chan, note, vel);

	        } else if (strEQ(event_type, "control_change")) {

	            if (av_len(event) != 4) {
	                hv_store(towhich, "_errstr", 7,
                                 newSVpvf("%s::playevents(): %d elements in control_change event",
                                          HvNAME(SvSTASH(towhich)), (av_len(event) + 1)), 0);
	                XSRETURN_NO;
	            }

	            chan       = SvIV(*av_fetch(event, 2, 0));
	            controller = SvIV(*av_fetch(event, 3, 0));
	            value      = SvIV(*av_fetch(event, 4, 0));

	            SEQ_CONTROL(dev, chan, controller, value);

	        } else if (strEQ(event_type, "patch_change")) {

	            if (av_len(event) != 3) {
	                hv_store(towhich, "_errstr", 7,
                                 newSVpvf("%s::playevents(): %d elements in patch_change event",
                                          HvNAME(SvSTASH(towhich)), (av_len(event) + 1)), 0);
	                XSRETURN_NO;
	            }

	            chan  = SvIV(*av_fetch(event, 2, 0));
	            patch = SvIV(*av_fetch(event, 3, 0));

	            SEQ_PGM_CHANGE(dev, chan, patch);

	        } else if (strEQ(event_type, "channel_after_touch")) {

	            if (av_len(event) != 3) {
	                hv_store(towhich, "_errstr", 7,
                                 newSVpvf("%s::playevents(): %d elements in channel_after_touch event",
                                          HvNAME(SvSTASH(towhich)), (av_len(event) + 1)), 0);
	                XSRETURN_NO;
	            }

	            chan = SvIV(*av_fetch(event, 2, 0));
	            vel  = SvIV(*av_fetch(event, 3, 0));

	            SEQ_CHN_PRESSURE(dev, chan, vel);

	        } else if (strEQ(event_type, "pitch_wheel_change")) {

	            if (av_len(event) != 3) {
	                hv_store(towhich, "_errstr", 7,
                                 newSVpvf("%s::playevents(): %d elements in pitch_wheel_change event",
                                          HvNAME(SvSTASH(towhich)), (av_len(event) + 1)), 0);
	                XSRETURN_NO;
	            }

	            chan  = SvIV(*av_fetch(event, 2, 0));
	            wheel = SvIV(*av_fetch(event, 3, 0)) + 8192;

	            SEQ_BENDER(dev, chan, wheel);


	        /*****************************************************
	         *
	         * Not doing anything with text events at present...
	         * Might include a feature to map filehandles to these
	         *   events in a future version.
	         */
	        } else if (strEQ(event_type, "text_event")) {
	        } else if (strEQ(event_type, "copyright_text_event")) {
	        } else if (strEQ(event_type, "track_name")) {
	        } else if (strEQ(event_type, "instrument_name")) {
	        } else if (strEQ(event_type, "lyric")) {
	        } else if (strEQ(event_type, "marker")) {
	        } else if (strEQ(event_type, "cue_point")) {
	        } else if (strEQ(event_type, "text_event_08")) {
	        } else if (strEQ(event_type, "text_event_09")) {
	        } else if (strEQ(event_type, "text_event_0a")) {
	        } else if (strEQ(event_type, "text_event_0b")) {
	        } else if (strEQ(event_type, "text_event_0c")) {
	        } else if (strEQ(event_type, "text_event_0d")) {
	        } else if (strEQ(event_type, "text_event_0e")) {
	        } else if (strEQ(event_type, "text_event_0f")) {
	        } else if (strEQ(event_type, "end_track")) {
	        } else if (strEQ(event_type, "set_tempo")) {

	            if (av_len(event) != 2) {
	                hv_store(towhich, "_errstr", 7,
                                 newSVpvf("%s::playevents(): %d elements in set_tempo event",
                                          HvNAME(SvSTASH(towhich)), (av_len(event) + 1)), 0);
	                XSRETURN_NO;
	            }

	            usecs_per_qn = SvIV(*av_fetch(event, 2, 0));
	            /* bpm = (60000000 + (usecs_per_qn / 2)) / usecs_per_qn; */
	            bpm = 60000000 / usecs_per_qn;

	            SEQ_SET_TEMPO(bpm);

	        } else if (strEQ(event_type, "smpte_offset")) {
	        } else if (strEQ(event_type, "time_signature")) {

	            if (av_len(event) != 5) {
	                hv_store(towhich, "_errstr", 7,
                                 newSVpvf("%s::playevents(): %d elements in time_signature event",
                                          HvNAME(SvSTASH(towhich)), (av_len(event) + 1)), 0);
	                XSRETURN_NO;
	            }

	            timesig  = SvIV(*av_fetch(event, 2, 0)) << 24;
	            timesig |= SvIV(*av_fetch(event, 3, 0)) << 16;
	            timesig |= SvIV(*av_fetch(event, 4, 0)) << 8;
	            timesig |= SvIV(*av_fetch(event, 5, 0));

	            SEQ_TIME_SIGNATURE(timesig);

	        } else if (strEQ(event_type, "key_signature")) {
	        } else if (strEQ(event_type, "sequencer_specific")) { /* do nothing for now... */
	        } else if (strEQ(event_type, "raw_meta_event")) { /* do nothing for now... */
	        } else if (strEQ(event_type, "sysex_f0")) {

	            sysex_data = SvPVX(*av_fetch(event, 2, 0));
	            sysex_len  = SvCUR(*av_fetch(event, 2, 0));
	            SEQ_SYSEX(dev, sysex_data, sysex_len);

	        } else if (strEQ(event_type, "sysex_f7")) {

	            sysex_data = SvPVX(*av_fetch(event, 2, 0));
	            sysex_len  = SvCUR(*av_fetch(event, 2, 0));
	            SEQ_SYSEX(dev, sysex_data, sysex_len);

	        } else if (strEQ(event_type, "song_position")) {
	        } else if (strEQ(event_type, "song_select")) {
	        } else if (strEQ(event_type, "tune_request")) {
	        } else if (strEQ(event_type, "raw_data")) { /* do nothing for now... */
	        }
	    }
	    XSRETURN_YES;
	}

void
dumpbuf(mm)
	SV * mm
	CODE:
	SEQ_DUMPBUF();

// VERSION = "1.000"
//
// Standard C code loaded outside XS space. Contains useful routines used by ts TS parsing functions
//
// The callbacks in this file are automatically installed and always called. The user settings determine whether
// they want to use a callback or not; if so, then their Perl subroutine is called with the appropriate parameters.
//
//
//
//
#include <unistd.h>
#include <limits.h>
#include "ts_parse.h"


#define DEBUG_TS

#ifdef DEBUG_TS
#define debug_prt(msg)	\
	printf("[DVBT-TS] %s\n", msg)
#else
#define debug_prt(msg)
#endif

#define VALID_READER(tsr)	\
	RETVAL = ERR_NONE ; \
	if (!tsr || (tsr->MAGIC != MAGIC_READER) )\
	{ \
		SET_ERROR(RETVAL, ERR_INVALID_TSREADER) ;\
	}

#define SET_CALLBACK(NAME)	\
	if (settings->NAME##_callback) \
		tsreader->NAME##_hook = parse_##NAME##_hook


//========================================================================================================
// Settings
//========================================================================================================

// common settings from Perl - amalgamation of all settings required for the following functions
struct TS_settings {
	int 		debug;
	unsigned	num_pkts ;
	int			origin ;
	int			skip_pkts ;

	unsigned	null_error_packets ;
	unsigned	save_cut ;

	SV	*perl_data ;

	SV	*pid_callback ;
	SV	*error_callback ;
	SV	*payload_callback ;
	SV	*ts_callback ;
	SV	*pes_callback ;
	SV	*pes_data_callback ;
	SV	*progress_callback ;
	SV	*mpeg2_callback ;
	SV	*mpeg2_rgb_callback ;
	SV	*audio_callback ;

};

//---------------------------------------------------------------------------------------------------------
static void clear_settings(struct TS_settings *settings)
{
	settings->debug = 0 ;
	settings->num_pkts = 0 ;
	settings->origin = SEEK_SET ;
	settings->skip_pkts = 0 ;

	settings->null_error_packets = 0 ;
	settings->save_cut = 0 ;

	settings->pid_callback = NULL ;
	settings->error_callback = NULL  ;
	settings->payload_callback = NULL  ;
	settings->ts_callback = NULL  ;
	settings->pes_callback = NULL  ;
	settings->pes_data_callback = NULL  ;
	settings->progress_callback = NULL  ;
	settings->mpeg2_callback = NULL  ;
	settings->mpeg2_rgb_callback = NULL  ;
	settings->audio_callback = NULL  ;

	settings->perl_data = NULL  ;
}


//========================================================================================================
// PARSE
//========================================================================================================

// data passed into hooks
struct TS_parse_data {
	// general
	struct TS_settings	*settings ;
	struct TS_reader	*tsreader ;

	// only used for repair - otherwise ignored
	unsigned null_error_packets ;
	int ofile;
};


//---------------------------------------------------------------------------------------------------------
static void _add_pidinfo(HV * info_href, struct TS_pidinfo *pidinfo)
{
HV * pidinfo_href =  newHV();
char string[256] ;

	HVS_I(pidinfo_href, pidinfo, pid) ;
	HVS_INT(pidinfo_href, err_flag, pidinfo->err_flag ? 1 : 0) ;
	HVS_INT(pidinfo_href, pes_start, pidinfo->pes_start ? 1 : 0) ;
	HVS_I(pidinfo_href, pidinfo, afc) ;
	HVS_I(pidinfo_href, pidinfo, pid_error) ;
	HVS_I(pidinfo_href, pidinfo, pktnum) ;

	HVS(info_href, pidinfo, newRV((SV *)pidinfo_href)) ;

}

//---------------------------------------------------------------------------------------------------------
static HV *  _store_ts(HV * href, char *key, int64_t ts)
{
HV * ts_href =  newHV();
unsigned secs, usecs ;

// 2^33 = 8589934592
char ts_str[12] ;

	if (ts >= 0)
	{
		secs = (unsigned)(ts / 90000) ;
		usecs = (unsigned)((ts % 90000) * 1000 / 90) ;

		HVS_INT(ts_href, secs, (int)secs) ;
		HVS_INT(ts_href, usecs, (int)usecs) ;

		sprintf(ts_str, "%"PRId64, ts) ;
		HVS_STR(ts_href, ts, ts_str) ;

		hv_store(href, key, strlen(key), newRV((SV *)ts_href), 0) ;
	}

	return ts_href ;
}

//---------------------------------------------------------------------------------------------------------
// Similar to _store_ts but assumes ts is relative (i.e. a duration/time) and works out the hours, mins, secs
static void _store_time(HV * href, char *key, int64_t ts)
{
HV * ts_href ;
unsigned hh, mm, ss ;

	if (ts >= 0)
	{
		// do the usual secs, usecs
		ts_href = _store_ts(href, key, ts) ;

		// now add HH:MM:SS
		ss = (unsigned)(ts / 90000) ;

		hh = (unsigned)(ss / (60*60)) ;
		ss -= hh * 60*60 ;
		mm = (unsigned)(ss / (60)) ;
		ss -= mm * 60 ;

		HVS_INT(ts_href, hh, (int)hh) ;
		HVS_INT(ts_href, mm, (int)mm) ;
		HVS_INT(ts_href, ss, (int)ss) ;
	}
}

//---------------------------------------------------------------------------------------------------------
static void _add_pesinfo(HV * info_href, struct TS_pesinfo *pesinfo)
{
HV * pesinfo_href =  newHV();
char *string ;

	_store_ts(pesinfo_href, "pts", pesinfo->pts) ;
	_store_ts(pesinfo_href, "dts", pesinfo->dts) ;

	_store_ts(pesinfo_href, "start_pts", pesinfo->start_pts) ;
	_store_ts(pesinfo_href, "start_dts", pesinfo->start_dts) ;

	_store_ts(pesinfo_href, "end_pts", pesinfo->end_pts) ;
	_store_ts(pesinfo_href, "end_dts", pesinfo->end_dts) ;

	_store_ts(pesinfo_href, "rel_pts", pesinfo->pts - pesinfo->start_pts) ;
	_store_ts(pesinfo_href, "rel_dts", pesinfo->dts - pesinfo->start_dts) ;

	HVS_I(pesinfo_href, pesinfo, pes_error) ;
	HVS_I(pesinfo_href, pesinfo, psi_error) ;
	HVS_I(pesinfo_href, pesinfo, ts_error) ;

	string = "PES" ;
	if (pesinfo->pes_psi == T_PSI)
	{
		string = "PSI" ;
	}
	HVS_STR(pesinfo_href, pes_psi, string) ;

	HVS(info_href, pesinfo, newRV((SV *)pesinfo_href)) ;
}


//---------------------------------------------------------------------------------------------------------
// HOOKS
//---------------------------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------------------------
static unsigned parse_pid_hook(unsigned pid,  void *user_data)
{
unsigned rc = 1 ;

	dSP ;
struct TS_parse_data *hook_data = (struct TS_parse_data *)user_data ;
SV * tsreader ;

	ENTER;
	SAVETMPS;

	if (hook_data->settings->pid_callback)
	{
		PUSHMARK(SP);

		tsreader = sv_newmortal();
		sv_setref_pv(tsreader, "TSReaderPtr", (void *)hook_data->tsreader );
		XPUSHs( tsreader );

		XPUSHs(sv_2mortal(newSViv(pid)));
		XPUSHs(hook_data->settings->perl_data);
		PUTBACK;

		rc = call_sv(hook_data->settings->pid_callback, G_SCALAR);

		SPAGAIN;
		PUTBACK;
	}

	FREETMPS;
	LEAVE;

	return rc ;
}



//---------------------------------------------------------------------------------------------------------
static void parse_error_hook(enum DVB_error error_code, struct TS_pidinfo *pidinfo, void *user_data)
{
	dSP ;
struct TS_parse_data *hook_data = (struct TS_parse_data *)user_data ;
HV * info_href = (HV*)NULL;
HV * error_href = (HV*)NULL;
char *error_str ;
SV * tsreader ;

	ENTER;
	SAVETMPS;

	if (hook_data->settings->error_callback)
	{
		info_href = newHV();
		_add_pidinfo(info_href, pidinfo) ;

		error_href = newHV();
		HVS_INT(error_href, code, (int)error_code) ;
		error_str = dvb_error_str(error_code) ;
		HVS_STR(error_href, str, error_str) ;
		HVS(info_href, error, newRV((SV *)error_href)) ;

		PUSHMARK(SP);

		tsreader = sv_newmortal();
		sv_setref_pv(tsreader, "TSReaderPtr", (void *)hook_data->tsreader );
		XPUSHs( tsreader );

		XPUSHs(sv_2mortal( newRV((SV *)info_href) ));
		XPUSHs(hook_data->settings->perl_data);
		PUTBACK;

		call_sv(hook_data->settings->error_callback, G_DISCARD);

		SPAGAIN;
	}

	FREETMPS;
	LEAVE;

}


//---------------------------------------------------------------------------------------------------------
static void parse_progress_hook(enum TS_progress_state state, unsigned progress, unsigned total, void *user_data)
{
	dSP ;
struct TS_parse_data *hook_data = (struct TS_parse_data *)user_data ;
char *state_str ;
SV * tsreader ;

	ENTER;
	SAVETMPS;

	if (hook_data->settings->progress_callback)
	{
		switch (state)
		{
			case PROGRESS_START 	: state_str = "START"; break ;
			case PROGRESS_RUNNING 	: state_str = "RUNNING"; break ;
			case PROGRESS_END 		: state_str = "END"; break ;
			case PROGRESS_STOPPED 	: state_str = "STOPPED"; break ;
			default				 	: state_str = "UNKNOWN"; break ;
		}

		PUSHMARK(SP);

		tsreader = sv_newmortal();
		sv_setref_pv(tsreader, "TSReaderPtr", (void *)hook_data->tsreader );
		XPUSHs( tsreader );

		XPUSHs(sv_2mortal( newSVpv( (char *)state_str, strlen(state_str) ) ));
		XPUSHs(sv_2mortal( newSViv(progress) ));
		XPUSHs(sv_2mortal( newSViv(total) ));
		XPUSHs(hook_data->settings->perl_data);
		PUTBACK;

		call_sv(hook_data->settings->progress_callback, G_DISCARD);

		SPAGAIN;
	}

	FREETMPS;
	LEAVE;

}


//---------------------------------------------------------------------------------------------------------
static void parse_ts_hook(struct TS_pidinfo *pidinfo, uint8_t *packet, unsigned packet_len, void *user_data)
{
	dSP ;
struct TS_parse_data *hook_data = (struct TS_parse_data *)user_data ;
HV * info_href = (HV*)NULL;
SV * tsreader ;

	ENTER;
	SAVETMPS;

	if (hook_data->settings->ts_callback)
	{
		info_href = newHV();
		_add_pidinfo(info_href, pidinfo) ;

		PUSHMARK(SP);

		tsreader = sv_newmortal();
		sv_setref_pv(tsreader, "TSReaderPtr", (void *)hook_data->tsreader );
		XPUSHs( tsreader );

		XPUSHs(sv_2mortal( newRV((SV *)info_href) ));
		XPUSHs(sv_2mortal(newSVpv( (char *)packet, packet_len)));
		XPUSHs(hook_data->settings->perl_data);
		PUTBACK;

		call_sv(hook_data->settings->ts_callback, G_DISCARD);

		SPAGAIN;
	}

	FREETMPS;
	LEAVE;

}

//---------------------------------------------------------------------------------------------------------
static void parse_payload_hook(struct TS_pidinfo *pidinfo, uint8_t *payload, unsigned payload_len, void *user_data)
{
	dSP ;
struct TS_parse_data *hook_data = (struct TS_parse_data *)user_data ;
HV * info_href = (HV*)NULL;
SV * tsreader ;

	ENTER;
	SAVETMPS;

	if (hook_data->settings->payload_callback)
	{
		info_href = newHV();
		_add_pidinfo(info_href, pidinfo) ;

		PUSHMARK(SP);

		tsreader = sv_newmortal();
		sv_setref_pv(tsreader, "TSReaderPtr", (void *)hook_data->tsreader );
		XPUSHs( tsreader );

		XPUSHs(sv_2mortal( newRV((SV *)info_href) ));
		XPUSHs(sv_2mortal(newSVpv( (char *)payload, payload_len)));
		XPUSHs(hook_data->settings->perl_data);
		PUTBACK;

		call_sv(hook_data->settings->payload_callback, G_DISCARD);

		SPAGAIN;
	}

	FREETMPS;
	LEAVE;

}


//---------------------------------------------------------------------------------------------------------
static void parse_pes_hook(struct TS_pidinfo *pidinfo, struct TS_pesinfo *pesinfo, uint8_t *pesdata, unsigned pesdata_len, void *user_data)
{
	dSP ;
struct TS_parse_data *hook_data = (struct TS_parse_data *)user_data ;
HV * info_href = (HV*)NULL;
SV * tsreader ;

	ENTER;
	SAVETMPS;

	if (hook_data->settings->pes_callback)
	{
		info_href = newHV();
		_add_pidinfo(info_href, pidinfo) ;
		_add_pesinfo(info_href, pesinfo) ;

		PUSHMARK(SP);

		tsreader = sv_newmortal();
		sv_setref_pv(tsreader, "TSReaderPtr", (void *)hook_data->tsreader );
		XPUSHs( tsreader );

		XPUSHs(sv_2mortal( newRV((SV *)info_href) ));
		XPUSHs(sv_2mortal(newSVpv( (char *)pesdata, pesdata_len)));
		XPUSHs(hook_data->settings->perl_data);
		PUTBACK;

		call_sv(hook_data->settings->pes_callback, G_DISCARD);

		SPAGAIN;
	}

	FREETMPS;
	LEAVE;

}

//---------------------------------------------------------------------------------------------------------
static void parse_pes_data_hook(struct TS_pidinfo *pidinfo, struct TS_pesinfo *pesinfo, uint8_t *pesdata, unsigned pesdata_len, void *user_data)
{
	dSP ;
struct TS_parse_data *hook_data = (struct TS_parse_data *)user_data ;
HV * info_href = (HV*)NULL;
SV * tsreader ;

	ENTER;
	SAVETMPS;

	if (hook_data->settings->pes_data_callback)
	{
		info_href = newHV();
		_add_pidinfo(info_href, pidinfo) ;
		_add_pesinfo(info_href, pesinfo) ;

		PUSHMARK(SP);

		tsreader = sv_newmortal();
		sv_setref_pv(tsreader, "TSReaderPtr", (void *)hook_data->tsreader );
		XPUSHs( tsreader );

		XPUSHs(sv_2mortal( newRV((SV *)info_href) ));
		XPUSHs(sv_2mortal(newSVpv( (char *)pesdata, pesdata_len)));
		XPUSHs(hook_data->settings->perl_data);
		PUTBACK;

		call_sv(hook_data->settings->pes_data_callback, G_DISCARD);

		SPAGAIN;
	}

	FREETMPS;
	LEAVE;

}


//---------------------------------------------------------------------------------------------------------
static void parse_mpeg2_hook(struct TS_pidinfo *pidinfo, struct TS_frame_info *frameinfo, const mpeg2_info_t *info, void *user_data)
{
	dSP ;
struct TS_parse_data *hook_data = (struct TS_parse_data *)user_data ;
HV * info_href = (HV*)NULL;
SV * tsreader ;

	ENTER;
	SAVETMPS;

	if (hook_data->settings->mpeg2_callback)
	{
	int datalen = info->sequence->width * info->sequence->height ;

		info_href = newHV();
		HVS_I(info_href, frameinfo, framenum) ;
		HVS_I(info_href, frameinfo, gop_pkt) ;
		_add_pidinfo(info_href, &frameinfo->pidinfo) ;
		_add_pesinfo(info_href, &frameinfo->pesinfo) ;

		PUSHMARK(SP);

		tsreader = sv_newmortal();
		sv_setref_pv(tsreader, "TSReaderPtr", (void *)hook_data->tsreader );
		XPUSHs( tsreader );

		XPUSHs(sv_2mortal( newRV((SV *)info_href) ));
		XPUSHs(sv_2mortal(newSViv( info->sequence->width )));
		XPUSHs(sv_2mortal(newSViv( info->sequence->height )));
		XPUSHs(sv_2mortal(newSVpv( (char *)info->display_fbuf->buf[0], datalen)));
		XPUSHs(hook_data->settings->perl_data);
		PUTBACK;

		call_sv(hook_data->settings->mpeg2_callback, G_DISCARD);

		SPAGAIN;
	}

	FREETMPS;
	LEAVE;
}

//---------------------------------------------------------------------------------------------------------
static void parse_mpeg2_rgb_hook(struct TS_pidinfo *pidinfo, struct TS_frame_info *frameinfo, const mpeg2_info_t *info, void *user_data)
{
	dSP ;
struct TS_parse_data *hook_data = (struct TS_parse_data *)user_data ;
HV * info_href = (HV*)NULL;
SV * tsreader ;

	ENTER;
	SAVETMPS;

	if (hook_data->settings->mpeg2_rgb_callback)
	{
	// 3 bytes (rgb) per pixel
	int datalen = info->sequence->width * info->sequence->height * 3 ;

		info_href = newHV();
		HVS_I(info_href, frameinfo, framenum) ;
		HVS_I(info_href, frameinfo, gop_pkt) ;
		_add_pidinfo(info_href, &frameinfo->pidinfo) ;
		_add_pesinfo(info_href, &frameinfo->pesinfo) ;

		PUSHMARK(SP);

		tsreader = sv_newmortal();
		sv_setref_pv(tsreader, "TSReaderPtr", (void *)hook_data->tsreader );
		XPUSHs( tsreader );

		XPUSHs(sv_2mortal( newRV((SV *)info_href) ));
		XPUSHs(sv_2mortal(newSViv( info->sequence->width )));
		XPUSHs(sv_2mortal(newSViv( info->sequence->height )));
		XPUSHs(sv_2mortal(newSVpv( (char *)info->display_fbuf->buf[0], datalen)));
		XPUSHs(hook_data->settings->perl_data);
		PUTBACK;

		call_sv(hook_data->settings->mpeg2_rgb_callback, G_DISCARD);

		SPAGAIN;
	}

	FREETMPS;
	LEAVE;
}

//---------------------------------------------------------------------------------------------------------
static void parse_audio_hook(struct TS_pidinfo *pidinfo, struct TS_pesinfo *pesinfo, const mpeg2_audio_t *info, void *user_data)
{
	dSP ;
struct TS_parse_data *hook_data = (struct TS_parse_data *)user_data ;
HV * info_href = (HV*)NULL;
SV * tsreader ;

	ENTER;
	SAVETMPS;

	if (hook_data->settings->audio_callback)
	{
		info_href = newHV();
		HVS_I(info_href, info, sample_rate) ;
		HVS_I(info_href, info, channels) ;
		HVS_I(info_href, info, samples_per_frame) ;
		HVS_I(info_href, info, samples) ;
		HVS_I(info_href, info, audio_framenum) ;
		HVS_I(info_href, info, framesize) ;
		_add_pidinfo(info_href, pidinfo) ;
		_add_pesinfo(info_href, pesinfo) ;

		PUSHMARK(SP);

		tsreader = sv_newmortal();
		sv_setref_pv(tsreader, "TSReaderPtr", (void *)hook_data->tsreader );
		XPUSHs( tsreader );

		XPUSHs(sv_2mortal( newRV((SV *)info_href) ));
		XPUSHs(sv_2mortal(newSVpv( (char *)info->audio, info->samples)));
		XPUSHs(hook_data->settings->perl_data);
		PUTBACK;

		call_sv(hook_data->settings->audio_callback, G_DISCARD);

		SPAGAIN;
	}

	FREETMPS;
	LEAVE;
}



//---------------------------------------------------------------------------------------------------------
// PARSING
//---------------------------------------------------------------------------------------------------------


//---------------------------------------------------------------------------------------------------------
struct TS_reader *tsparse_start(char *filename, struct TS_settings *settings)
{
int file;
struct TS_parse_data *hook_data ;
struct TS_reader *tsreader ;

	dvb_error_clear() ;

	hook_data = (struct TS_parse_data *)malloc(sizeof(struct TS_parse_data)) ;
	memset(hook_data, 0, sizeof(*hook_data)) ;

	hook_data->settings = settings ;
	hook_data->tsreader = NULL ;

	tsreader = tsreader_new(filename) ;
    if (!tsreader)
    {
		//fprintf(stderr,"ERROR %s: %s\n",filename,dvb_error_str(dvb_error_code));
    	return(NULL);
    }
	hook_data->tsreader = tsreader ;
    tsreader_setpos(tsreader, settings->skip_pkts, settings->origin, settings->num_pkts) ;

	tsreader->debug = settings->debug ;

//	if (settings->pid_callback)
//		tsreader->pid_hook = parse_pid_hook ;
	SET_CALLBACK(error) ;
	SET_CALLBACK(payload) ;
	SET_CALLBACK(ts) ;
	SET_CALLBACK(pes) ;
	SET_CALLBACK(pes_data) ;
	SET_CALLBACK(progress) ;
	SET_CALLBACK(audio) ;
	SET_CALLBACK(mpeg2) ;
	SET_CALLBACK(mpeg2_rgb) ;

//	tsreader->error_hook = parse_error_hook ;
//	tsreader->payload_hook = parse_payload_hook ;
//	tsreader->ts_hook = parse_ts_hook ;
//	tsreader->pes_hook = parse_pes_hook ;
//	tsreader->pes_data_hook = parse_pes_data_hook ;
//	tsreader->progress_hook = parse_progress_hook ;
//	tsreader->audio_hook = parse_audio_hook ;
//
//	if (settings->mpeg2_callback)
//	{
//		tsreader->mpeg2_hook = parse_mpeg2_hook ;
//	}
//	else if (settings->mpeg2_rgb_callback)
//	{
//		tsreader->mpeg2_rgb_hook = parse_mpeg2_rgb_hook ;
//	}

	tsreader->user_data = hook_data ;

	return tsreader ;
}

//---------------------------------------------------------------------------------------------------------
int tsparse_run(TSReader *tsreader)
{
int rc ;

	// parse data
    ts_parse(tsreader) ;

	return(dvb_error_code) ;
}

//---------------------------------------------------------------------------------------------------------
int tsparse_end(TSReader *tsreader)
{
	if (tsreader->user_data)
	{
		free(tsreader->user_data) ;
	}

	// free
	tsreader_free(tsreader) ;

	return(dvb_error_code) ;
}




//---------------------------------------------------------------------------------------------------------
// Self-contained
int tsparse(char *filename, struct TS_settings *settings)
{
struct TS_reader *tsreader ;

	// start
	tsreader = tsparse_start(filename, settings) ;
    if (!tsreader)
    {
    	return(dvb_error_code);
    }

	// parse data
    tsparse_run(tsreader) ;

    if (dvb_error_code)
    {
    	debug_prt(dvb_error_str(dvb_error_code)) ;
    }

	// end
    tsparse_end(tsreader) ;

    if (dvb_error_code)
    {
    	debug_prt(dvb_error_str(dvb_error_code)) ;
    }

    return(dvb_error_code) ;
}


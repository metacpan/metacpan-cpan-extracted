/*
 * Audio volume statistics
 *
 */
#include <math.h>

#include "ad_audio.h"
#include "ad_debug.h"

extern int get_framesize() ;
extern int get_framenum() ;

//===========================================================================================================================
// CONSTANTS
//===========================================================================================================================

// Audio default Perl settings
#define AUDIO_max_advert			(4*60*FPS)
#define AUDIO_min_advert			(2*60*FPS)
#define AUDIO_min_program			(5*60*FPS)
#define AUDIO_start_pad				(2*60*FPS)
#define AUDIO_end_pad				(2*60*FPS)
#define AUDIO_min_frames 	 		2
#define AUDIO_frame_window 	 		(4*60*FPS)
#define AUDIO_max_gap 		 		(10*FPS)
#define AUDIO_reduce_end			0
#define AUDIO_reduce_min_gap	 	0

//===========================================================================================================================
// MACROS
//===========================================================================================================================

// print debug if debug setting is high enough
#define audio_dbg_prt(LVL, ARGS)	\
		if (settings->debug >= LVL)	printf ARGS

//===========================================================================================================================
// FUNCTIONS
//===========================================================================================================================


//---------------------------------------------------------------------------------------------------------------------------
// Initialise the results
void audio_init_results(struct Ad_audio_results *results)
{
}

//---------------------------------------------------------------------------------------------------------------------------
// Initialise the totals
void audio_init_totals(struct Ad_audio_totals *totals)
{

}

//---------------------------------------------------------------------------------------------------------------------------
// Initialise the user data
void audio_init_settings(struct Ad_audio_settings *settings)
{
	settings->debug = 0 ;
	settings->scale = 1 ;
	settings->silence_threshold = -80 ;

	settings->silence_window = 100 ;

	// set_perl_settings(settings, mx_ad, mn_ad, mn_pr, s_pd, e_pd, mn_fr, fr_wn, mx_gp, r_en, r_mn_gp)
	set_perl_settings(settings,
		AUDIO_max_advert,
		AUDIO_min_advert,
		AUDIO_min_program,
		AUDIO_start_pad,
		AUDIO_end_pad,
		AUDIO_min_frames,
		AUDIO_frame_window,
		AUDIO_max_gap,
		AUDIO_reduce_end,
		AUDIO_reduce_min_gap
	) ;
}

//---------------------------------------------------------------------------------------------------------------------------
// Initialise the state data
void audio_init_state(struct Ad_audio_state *state)
{
}

//---------------------------------------------------------------------------------------------------------------------------
// Initialise the detector
void audio_detector_init(struct Ad_audio_settings *settings, struct Ad_audio_state *state)
{
	audio_init_settings(settings) ;
	audio_init_state(state) ;
}

//---------------------------------------------------------------------------------------------------------------------------
// Free up data created by the detector
void audio_detector_free(struct Ad_audio_state *state)
{

}

//---------------------------------------------------------------------------------------------------------------------------
// Run the detector
void audio_detector_run(struct TS_reader *tsreader, struct TS_pidinfo *pidinfo, struct TS_pesinfo *pesinfo, const mpeg2_audio_t *info,
		struct Ad_audio_settings *settings, struct Ad_audio_state *state, struct Ad_audio_results *results, struct Ad_audio_totals *totals)
{
unsigned i, volume, max_vol, val ;
short *buffer ;
double dB ;

	audio_init_results(results) ;

audio_dbg_prt(1, ("audio frame=%d [samples=%d, s/f=%d, chan=%d]\n",
		info->audio_framenum, info->samples, info->samples_per_frame, info->channels)) ;

audio_dbg_prt(1, ("# Audio : framesize=%d, framenum=%d, sample_rate=%d\n",
			 get_framesize(),
			 get_framenum(),
			 get_samplerate()
			 )) ;

	// Frame volume = SUM( ABS(sound samples per frame) ) / number of samples per frame
	volume = 0;
	max_vol = 0;
	buffer = info->audio ;
	for (i = 0; i < info->samples; i++)
	{
		val = (*buffer>0 ? *buffer : -*buffer) ;
		volume += val ;
		if (max_vol < val) max_vol = val ;

		audio_dbg_prt(2, (" * [%3d] val=%u sum(vol)=%u max=%u (buff=%i)\n", i, val, volume, max_vol, (int)*buffer)) ;

		buffer++;
	}
	volume = volume/info->samples;


	// set return info
	results->audio_framenum = info->audio_framenum ;
	results->pts = info->pts ;
	results->volume = volume ;
	results->max_volume = max_vol ;

	results->sample_rate = info->sample_rate	;
	results->channels = info->channels ;
	results->samples_per_frame = info->samples_per_frame ;
	results->samples = info->samples ;
	results->framesize = info->framesize ;

	// Calc volume in dB
	dB = (double)MIN_DB ;
	if (volume)
	{
		dB = 20.0 * log10( (double)volume / (double)MAX_VOL) ;
		if (dB < MIN_DB) dB = MIN_DB ;
	}
	results->volume_dB = (int)(settings->scale * dB - 0.5) ; // dB will always be -ve

	// check for silence
	results->silent_frame = 0 ;
	if (dB <= (double)settings->silence_threshold)
	{
		results->silent_frame = 1 ;
	}

	audio_dbg_prt(2, (" *audio* dB %f  vold_dB %d volume %d silent %d (scale %d, thresh %d)\n",
		dB, results->volume_dB, volume, results->silent_frame,
		settings->scale, settings->silence_threshold)) ;



// DEBUG
	if (settings->debug >= 2)
	{
	uint64_t rel_dts ;
	unsigned dts_frame ;
	unsigned dts_secs ;

	rel_dts = info->pts - pesinfo->start_dts ;
	dts_frame = (unsigned)(rel_dts * 25 / 90000) ;
	dts_secs = (unsigned)(rel_dts / 90000) ;

	fprintf(stderr, "# PTS audio frame %5d : dB %d : pts=%"PRId64" [%"PRId64" .. %"PRId64" ] frm=%u sec=%u\n",
			info->audio_framenum,
			results->volume_dB,
			info->pts,
			pesinfo->start_dts, pesinfo->end_dts,
			dts_frame, dts_secs
			) ;
	}
// DEBUG

}


#ifdef AUDIO_STANDALONE
//---------------------------------------------------------------------------------------------------------------------------
audio_hook_t *audio_hook(struct TS_pidinfo *pidinfo, struct TS_pesinfo *pesinfo, const mpeg2_audio_t *info, void *hook_data)
{
struct Ad_user_data *user_data = (struct Ad_user_data *)hook_data ;
unsigned i, volume, max_vol, val ;
short *buffer ;

if (_debug) fprintf(stderr, "audio frame=%d [samples=%d, s/f=%d, chan=%d]\n",
		info->audio_framenum, info->samples, info->samples_per_frame, info->channels) ;

if (_debug)
{
	 fprintf(stderr, "# framesize=%d, framenum=%d, sample_rate=%d\n",
			 get_framesize(),
			 get_framenum(),
			 get_samplerate()
			 ) ;
}

	// Frame volume = SUM( ABS(sound samples per frame) ) / number of samples per frame
	volume = 0;
	max_vol = 0;
	buffer = info->audio ;
	for (i = 0; i < info->samples; i++)
	{
		val = (*buffer>0 ? *buffer : -*buffer) ;
		volume += val ;
		if (max_vol < val) max_vol = val ;

if (_debug >= 2) fprintf(stderr, " * [%3d] val=%u sum(vol)=%u max=%u (buff=%i)\n", i, val, volume, max_vol, (int)*buffer) ;

		buffer++;
	}
	volume = volume/info->samples;


	// set return info
	hook_return.audio_framenum = info->audio_framenum ;
	hook_return.pts = info->pts ;
	hook_return.volume = volume ;
	hook_return.max_volume = max_vol ;

	hook_return.sample_rate = info->sample_rate	;
	hook_return.channels = info->channels ;
	hook_return.samples_per_frame = info->samples_per_frame ;
	hook_return.samples = info->samples ;
	hook_return.framesize = info->framesize ;


//	fprintf(stderr, "Audio frame %06d : vol %d  max %d : pkt %u [ %u ..  %u]\n",
//			info->audio_framenum,
//			volume,
//			max_vol,
//			pidinfo->pktnum,
//			pesinfo->start_pkt, pesinfo->end_pkt);



// DEBUG
	{
	uint64_t rel_dts ;
	unsigned dts_frame ;
	unsigned dts_secs ;

	rel_dts = info->pts - pesinfo->start_dts ;
	dts_frame = (unsigned)(rel_dts * 25 / 90000) ;
	dts_secs = (unsigned)(rel_dts / 90000) ;

	fprintf(stderr, "# PTS audio frame %5d : pts=%"PRId64" [%"PRId64" .. %"PRId64" ] frm=%u sec=%u\n",
			info->audio_framenum,
			info->pts,
			pesinfo->start_dts, pesinfo->end_dts,
			dts_frame, dts_secs
			) ;
	}
// DEBUG


	return (&hook_return) ;
}


//============================================================================================
enum DVB_error run_audio_check(struct Ad_user_data *user_data,
		char *filename, unsigned num_pkts, unsigned skip)
{
struct TS_reader *tsreader ;

	tsreader = tsreader_new(filename) ;
    if (!tsreader)
    {
		fprintf(stderr,"ERROR %s: %s\n",filename,dvb_error_str(dvb_error_code));
		return(ERR_FILE);
    }

    tsreader->num_pkts = num_pkts ;
    tsreader->skip = skip ;
    tsreader->debug = 0 ;
    tsreader->user_data = user_data ;
    user_data->tsreader = tsreader ;

	tsreader->pid_hook = pid_hook ;
	tsreader->audio_hook = audio_hook ;


    // process file
    tsreader_setpos(tsreader, 0, SEEK_SET, num_pkts) ;
    ts_parse(tsreader) ;

    // end
    tsreader_free(tsreader) ;

    return (ERR_NONE) ;
}
#endif

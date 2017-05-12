// VERSION = "1.003"
//
// Standard C code loaded outside XS space. Contains useful routines used by advert detection functions
#include "ts_advert.h"
#include "ts_cut.h"
#include "ts_split.h"

//---------------------------------------------------------------------------------------------------------
// MACROS
//---------------------------------------------------------------------------------------------------------

#define _USER_SETTING(HREF, NAME, VAR)	HVF_IV(HREF, NAME, user_data->VAR)

#define USER_SETTING(NAME)			_USER_SETTING(settings_href, NAME, NAME)
#define USER_FRAME_SETTING(NAME)	_USER_SETTING(frame_settings_href, NAME, frame_settings.NAME)
#define USER_LOGO_SETTING(NAME)		_USER_SETTING(logo_settings_href, NAME, logo_settings.NAME)
#define USER_AUDIO_SETTING(NAME)	_USER_SETTING(audio_settings_href, NAME, audio_settings.NAME)

#define USER_PERL_SETTING(NAME)			_USER_SETTING(settings_href, NAME, perl_set.NAME)
#define USER_FRAME_PERL_SETTING(NAME)	_USER_SETTING(frame_settings_href, NAME, frame_settings.perl_set.NAME)
#define USER_LOGO_PERL_SETTING(NAME)	_USER_SETTING(logo_settings_href, NAME, logo_settings.perl_set.NAME)
#define USER_AUDIO_PERL_SETTING(NAME)	_USER_SETTING(audio_settings_href, NAME, audio_settings.perl_set.NAME)


//---------------------------------------------------------------------------------------------------------
// HOOKS
//---------------------------------------------------------------------------------------------------------


//---------------------------------------------------------------------------------------------------------
static void advert_progress_hook(enum TS_progress_state state, unsigned progress, unsigned total, void *user_data)
{
	dSP ;
struct Ad_user_data  *hook_data = (struct Ad_user_data *)user_data ;
char *state_str ;
char ad_state_str[256] ;

	ENTER;
	SAVETMPS;

	if (hook_data->progress_callback && total)
	{
		switch (state)
		{
			case PROGRESS_START 	: state_str = "START"; break ;
			case PROGRESS_RUNNING 	: state_str = "RUNNING"; break ;
			case PROGRESS_END 		: state_str = "END"; break ;
			case PROGRESS_STOPPED 	: state_str = "STOPPED"; break ;
			default				 	: state_str = "UNKNOWN"; break ;
		}

		if (hook_data->process_state == ADVERT_PREPROCESS)
		{
			sprintf(ad_state_str, "PREPROCESS %s", state_str) ;
		}
		else
		{
			sprintf(ad_state_str, "PROCESS %s", state_str) ;
		}

		PUSHMARK(SP);
		XPUSHs(sv_2mortal( newSVpv( (char *)ad_state_str, strlen(ad_state_str) ) ));
		XPUSHs(sv_2mortal( newSViv(progress) ));
		XPUSHs(sv_2mortal( newSViv(total) ));
		XPUSHs((SV *)hook_data->extra_data);
		PUTBACK;

		call_sv(hook_data->progress_callback, G_DISCARD);

		SPAGAIN;
	}

	FREETMPS;
	LEAVE;

}


//========================================================================================================
// FUNCTIONS
//========================================================================================================

//---------------------------------------------------------------------------------------------------------
// Copy any user settings from the Perl HASH into the user_data
//
static void advert_set_settings(struct Ad_user_data *user_data, HV *settings_href)
{
SV **val;
HV *frame_settings_href = NULL ;
HV *logo_settings_href = NULL ;
HV *audio_settings_href = NULL ;

	if (settings_href)
	{
		val = HVF(settings_href, frame) ;
		if (val)
			frame_settings_href = (HV *) SvRV (*val);

		val = HVF(settings_href, logo) ;
		if (val)
			logo_settings_href = (HV *) SvRV (*val);

		val = HVF(settings_href, audio) ;
		if (val)
			audio_settings_href = (HV *) SvRV (*val);


		//-- user settings --
		HVF_SVV(settings_href, progress_callback, user_data->progress_callback) ;
		HVF_SVV(settings_href, user_data, user_data->extra_data) ;

		_USER_SETTING(settings_href, dbg-adv, debug) ;
		_USER_SETTING(settings_href, dbg-ts, ts_debug) ;
		USER_SETTING(pid) ;
		USER_SETTING(audio_pid) ;
		USER_SETTING(detection_method) ;

		USER_PERL_SETTING(max_advert) ;
		USER_PERL_SETTING(min_advert) ;
		USER_PERL_SETTING(min_program) ;
		USER_PERL_SETTING(start_pad) ;
		USER_PERL_SETTING(end_pad) ;
		USER_PERL_SETTING(min_frames) ;
		USER_PERL_SETTING(frame_window) ;
		USER_PERL_SETTING(max_gap) ;
		USER_PERL_SETTING(reduce_end) ;
		USER_PERL_SETTING(reduce_min_gap) ;

		//-- frame settings --
		_USER_SETTING(settings_href, dbg-frame, frame_settings.debug) ;
		if (frame_settings_href)
		{
			USER_FRAME_SETTING(max_black) ;
			USER_FRAME_SETTING(window_percent) ;
			USER_FRAME_SETTING(max_brightness) ;
			USER_FRAME_SETTING(test_brightness) ;
			USER_FRAME_SETTING(brightness_jump) ;
			USER_FRAME_SETTING(schange_cutlevel) ;
			USER_FRAME_SETTING(schange_jump) ;
			USER_FRAME_SETTING(noise_level) ;
			USER_FRAME_SETTING(remove_logo) ;

			USER_FRAME_PERL_SETTING(max_advert) ;
			USER_FRAME_PERL_SETTING(min_advert) ;
			USER_FRAME_PERL_SETTING(min_program) ;
			USER_FRAME_PERL_SETTING(start_pad) ;
			USER_FRAME_PERL_SETTING(end_pad) ;
			USER_FRAME_PERL_SETTING(min_frames) ;
			USER_FRAME_PERL_SETTING(frame_window) ;
			USER_FRAME_PERL_SETTING(max_gap) ;
			USER_FRAME_PERL_SETTING(reduce_end) ;
			USER_FRAME_PERL_SETTING(reduce_min_gap) ;
		}

		//-- logo settings --
		_USER_SETTING(settings_href, dbg-logo, logo_settings.debug) ;
		if (logo_settings_href)
		{
			USER_LOGO_SETTING(window_percent) ;
			USER_LOGO_SETTING(logo_window) ;
			USER_LOGO_SETTING(logo_edge_radius) ;
			USER_LOGO_SETTING(logo_edge_step) ;
			USER_LOGO_SETTING(logo_edge_threshold) ;
			USER_LOGO_SETTING(logo_checking_period) ;
			USER_LOGO_SETTING(logo_skip_frames) ;
			USER_LOGO_SETTING(logo_num_checks) ;
			USER_LOGO_SETTING(logo_ok_percent) ;
			USER_LOGO_SETTING(logo_max_percentage_of_screen) ;
			USER_LOGO_SETTING(logo_ave_points) ;

			USER_LOGO_SETTING(logo_fall_threshold) ;
			USER_LOGO_SETTING(logo_rise_threshold) ;
			USER_LOGO_PERL_SETTING(max_advert) ;
			USER_LOGO_PERL_SETTING(min_advert) ;
			USER_LOGO_PERL_SETTING(min_program) ;
			USER_LOGO_PERL_SETTING(start_pad) ;
			USER_LOGO_PERL_SETTING(end_pad) ;
			USER_LOGO_PERL_SETTING(min_frames) ;
			USER_LOGO_PERL_SETTING(frame_window) ;
			USER_LOGO_PERL_SETTING(max_gap) ;
			USER_LOGO_PERL_SETTING(reduce_end) ;
			USER_LOGO_PERL_SETTING(reduce_min_gap) ;
		}

		//-- audio settings --
		_USER_SETTING(settings_href, dbg-audio, audio_settings.debug) ;
		if (audio_settings_href)
		{
			USER_AUDIO_SETTING(scale) ;
			USER_AUDIO_SETTING(silence_threshold) ;

			USER_AUDIO_SETTING(silence_window) ;
			USER_AUDIO_PERL_SETTING(max_advert) ;
			USER_AUDIO_PERL_SETTING(min_advert) ;
			USER_AUDIO_PERL_SETTING(min_program) ;
			USER_AUDIO_PERL_SETTING(start_pad) ;
			USER_AUDIO_PERL_SETTING(end_pad) ;
			USER_AUDIO_PERL_SETTING(min_frames) ;
			USER_AUDIO_PERL_SETTING(frame_window) ;
			USER_AUDIO_PERL_SETTING(max_gap) ;
			USER_AUDIO_PERL_SETTING(reduce_end) ;
			USER_AUDIO_PERL_SETTING(reduce_min_gap) ;
		}
	}
}





//---------------------------------------------------------------------------------------------------------
// Copy all settings from the user_data struct into the Perl HASH
//
static void advert_get_settings(struct Ad_user_data *user_data, HV *settings)
{
HV * rh;

	//== Common ===============

	//-- Used by C routines ---
	HVS_INT_SETTING(settings, pid, user_data->pid, ) ;
	HVS_INT_SETTING(settings, audio_pid, user_data->audio_pid, ) ;
	HVS_INT_SETTING(settings, detection_method, user_data->detection_method, ) ;
	HVS_INT_SETTING(settings, num_frames, user_data->last_framenum+1, ) ;

	//-- Used only by Perl modules --
	HVS_INT_SETTING(settings, max_advert, 		user_data->perl_set.max_advert, ) ;
	HVS_INT_SETTING(settings, min_advert, 		user_data->perl_set.min_advert, ) ;
	HVS_INT_SETTING(settings, min_program, 		user_data->perl_set.min_program, ) ;
	HVS_INT_SETTING(settings, start_pad, 		user_data->perl_set.start_pad, ) ;
	HVS_INT_SETTING(settings, end_pad,	 		user_data->perl_set.end_pad, ) ;
	HVS_INT_SETTING(settings, min_frames, 		user_data->perl_set.min_frames, ) ;
	HVS_INT_SETTING(settings, frame_window,		user_data->perl_set.frame_window, ) ;
	HVS_INT_SETTING(settings, max_gap,			user_data->perl_set.max_gap, ) ;
	HVS_INT_SETTING(settings, reduce_end,		user_data->perl_set.reduce_end, ) ;
	HVS_INT_SETTING(settings, reduce_min_gap,	user_data->perl_set.reduce_min_gap, ) ;
//	HVS_INT_SETTING(settings, increase_start,	0, ) ;
//	HVS_INT_SETTING(settings, increase_min_gap,	(60*FPS), ) ;


	//== Frame ===============

	//-- Used by C routines ---
	rh = (HV *)sv_2mortal((SV *)newHV());
	HVS_INT_SETTING(rh, max_black, user_data->frame_settings.max_black, frame.) ;
	HVS_INT_SETTING(rh, window_percent, user_data->frame_settings.window_percent, frame.) ;
	HVS_INT_SETTING(rh, max_brightness, user_data->frame_settings.max_brightness, frame.) ;
	HVS_INT_SETTING(rh, test_brightness, user_data->frame_settings.test_brightness, frame.) ;
	HVS_INT_SETTING(rh, brightness_jump, user_data->frame_settings.brightness_jump, frame.) ;
	HVS_INT_SETTING(rh, schange_cutlevel, user_data->frame_settings.schange_cutlevel, frame.) ;
	HVS_INT_SETTING(rh, schange_jump, user_data->frame_settings.schange_jump, frame.) ;
	HVS_INT_SETTING(rh, noise_level, user_data->frame_settings.noise_level, frame.) ;
	HVS_INT_SETTING(rh, remove_logo, user_data->frame_settings.remove_logo, frame.) ;

	//-- Used only by Perl modules --
	HVS_INT_SETTING(rh, max_advert, 		user_data->frame_settings.perl_set.max_advert, frame.) ;
	HVS_INT_SETTING(rh, min_advert, 		user_data->frame_settings.perl_set.min_advert, frame.) ;
	HVS_INT_SETTING(rh, min_program, 		user_data->frame_settings.perl_set.min_program, frame.) ;
	HVS_INT_SETTING(rh, start_pad, 			user_data->frame_settings.perl_set.start_pad, frame.) ;
	HVS_INT_SETTING(rh, end_pad,	 		user_data->frame_settings.perl_set.end_pad, frame.) ;
	HVS_INT_SETTING(rh, min_frames, 		user_data->frame_settings.perl_set.min_frames, frame.) ;
	HVS_INT_SETTING(rh, frame_window,		user_data->frame_settings.perl_set.frame_window, frame.) ;
	HVS_INT_SETTING(rh, max_gap,			user_data->frame_settings.perl_set.max_gap, frame.) ;
	HVS_INT_SETTING(rh, reduce_end,			user_data->frame_settings.perl_set.reduce_end, frame.) ;
	HVS_INT_SETTING(rh, reduce_min_gap,		user_data->frame_settings.perl_set.reduce_min_gap, frame.) ;

	HVS(settings, frame, newRV((SV *)rh)) ;


	//== Logo ===============

	//-- Used by C routines ---
	rh = (HV *)sv_2mortal((SV *)newHV());
	HVS_INT_SETTING(rh, window_percent, user_data->logo_settings.window_percent, logo.) ;
	HVS_INT_SETTING(rh, logo_window, user_data->logo_settings.logo_window, logo.) ;
	HVS_INT_SETTING(rh, logo_edge_radius, user_data->logo_settings.logo_edge_radius, logo.) ;
	HVS_INT_SETTING(rh, logo_edge_step, user_data->logo_settings.logo_edge_step, logo.) ;
	HVS_INT_SETTING(rh, logo_edge_threshold, user_data->logo_settings.logo_edge_threshold, logo.) ;
	HVS_INT_SETTING(rh, logo_checking_period, user_data->logo_settings.logo_checking_period, logo.) ;
	HVS_INT_SETTING(rh, logo_skip_frames, user_data->logo_settings.logo_skip_frames, logo.) ;
	HVS_INT_SETTING(rh, logo_num_checks, user_data->logo_settings.logo_num_checks, logo.) ;
	HVS_INT_SETTING(rh, logo_ok_percent, user_data->logo_settings.logo_ok_percent, logo.) ;
	HVS_INT_SETTING(rh, logo_max_percentage_of_screen, user_data->logo_settings.logo_max_percentage_of_screen, logo.) ;
	HVS_INT_SETTING(rh, logo_ave_points, user_data->logo_settings.logo_ave_points, logo.) ;

	//-- Used only by Perl modules --
	HVS_INT_SETTING(rh, max_advert, 		user_data->logo_settings.perl_set.max_advert, logo.) ;
	HVS_INT_SETTING(rh, min_advert, 		user_data->logo_settings.perl_set.min_advert, logo.) ;
	HVS_INT_SETTING(rh, min_program, 		user_data->logo_settings.perl_set.min_program, logo.) ;
	HVS_INT_SETTING(rh, start_pad, 			user_data->logo_settings.perl_set.start_pad, logo.) ;
	HVS_INT_SETTING(rh, end_pad,	 		user_data->logo_settings.perl_set.end_pad, logo.) ;
	HVS_INT_SETTING(rh, min_frames, 		user_data->logo_settings.perl_set.min_frames, logo.) ;
	HVS_INT_SETTING(rh, frame_window,		user_data->logo_settings.perl_set.frame_window, logo.) ;
	HVS_INT_SETTING(rh, max_gap,			user_data->logo_settings.perl_set.max_gap, logo.) ;
	HVS_INT_SETTING(rh, reduce_end,			user_data->logo_settings.perl_set.reduce_end, logo.) ;
	HVS_INT_SETTING(rh, reduce_min_gap,		user_data->logo_settings.perl_set.reduce_min_gap, logo.) ;

	HVS_INT_SETTING(rh, logo_rise_threshold,	user_data->logo_settings.logo_rise_threshold, logo.) ;
	HVS_INT_SETTING(rh, logo_fall_threshold,	user_data->logo_settings.logo_fall_threshold, logo.) ;

	HVS(settings, logo, newRV((SV *)rh)) ;


	//== Audio ===============

	//-- Used by C routines ---
	rh = (HV *)sv_2mortal((SV *)newHV());
	HVS_INT_SETTING(rh, scale, user_data->audio_settings.scale, audio.) ;
	HVS_INT_SETTING(rh, silence_threshold, user_data->audio_settings.silence_threshold, audio.) ;

	//-- Used only by Perl modules --
	HVS_INT_SETTING(rh, max_advert, 		user_data->audio_settings.perl_set.max_advert, audio.) ;
	HVS_INT_SETTING(rh, min_advert, 		user_data->audio_settings.perl_set.min_advert, audio.) ;
	HVS_INT_SETTING(rh, min_program, 		user_data->audio_settings.perl_set.min_program, audio.) ;
	HVS_INT_SETTING(rh, start_pad, 			user_data->audio_settings.perl_set.start_pad, audio.) ;
	HVS_INT_SETTING(rh, end_pad,	 		user_data->audio_settings.perl_set.end_pad, audio.) ;
	HVS_INT_SETTING(rh, min_frames, 		user_data->audio_settings.perl_set.min_frames, audio.) ;
	HVS_INT_SETTING(rh, frame_window,		user_data->audio_settings.perl_set.frame_window, audio.) ;
	HVS_INT_SETTING(rh, max_gap,			user_data->audio_settings.perl_set.max_gap, audio.) ;
	HVS_INT_SETTING(rh, reduce_end,			user_data->audio_settings.perl_set.reduce_end, audio.) ;
	HVS_INT_SETTING(rh, reduce_min_gap,		user_data->audio_settings.perl_set.reduce_min_gap, audio.) ;

	HVS_INT_SETTING(rh, silence_window,		user_data->audio_settings.silence_window, audio.) ;

	HVS(settings, audio, newRV((SV *)rh)) ;


	//== Save Totals ===============

	//-- Used only by Perl modules --
	HVS_INT_SETTING(settings, total_logo_frames, user_data->logo_totals.num_logo_frames, ) ;
	HVS_INT_SETTING(settings, total_black_frames, user_data->frame_totals.num_black_frames, ) ;
	HVS_INT_SETTING(settings, total_scene_frames, user_data->frame_totals.num_scene_frames, ) ;
	HVS_INT_SETTING(settings, total_size_frames, user_data->frame_totals.num_size_frames, ) ;



}

//---------------------------------------------------------------------------------------------------------
static HV *advert_result(struct Ad_user_data * user_data, unsigned index)
{
HV * rh;

	HVS_RESULT_START ;

	rh = (HV *)sv_2mortal((SV *)newHV());

	HVS_INT_RESULT(rh, frame, user_data->results_array[index].video_framenum) ;
	HVS_INT_RESULT(rh, frame_end, user_data->results_array[index].video_framenum) ;

	HVS_INT_RESULT(rh, start_pkt, user_data->results_array[index].start_pkt) ;
	HVS_INT_RESULT(rh, end_pkt, user_data->results_array[index].end_pkt) ;
	HVS_INT_RESULT(rh, gop_pkt, user_data->results_array[index].gop_pkt) ;

	/*
	unsigned	black_frame ;
	unsigned	scene_frame ;

	unsigned 	screen_width ;
	unsigned 	screen_height ;
	unsigned 	brightness ;
	unsigned 	uniform ;
	unsigned	dimCount;
	int			sceneChangePercent;
	*/
	HVS_FRAME_RESULT(rh, black_frame, index) ;
	HVS_FRAME_RESULT(rh, scene_frame, index) ;
	HVS_FRAME_RESULT(rh, size_change, index) ;
	HVS_FRAME_RESULT(rh, screen_width, index) ;
	HVS_FRAME_RESULT(rh, screen_height, index) ;
	HVS_FRAME_RESULT(rh, brightness, index) ;
	HVS_FRAME_RESULT(rh, uniform, index) ;
	HVS_FRAME_RESULT(rh, dimCount, index) ;
	HVS_FRAME_RESULT(rh, sceneChangePercent, index) ;

	/*
	unsigned	logo_frame ;	// boolean

	unsigned 	match_percent ;
	unsigned 	ave_percent ;
	*/
	HVS_LOGO_RESULT(rh, logo_frame, index) ;
	HVS_LOGO_RESULT(rh, match_percent, index) ;
	HVS_LOGO_RESULT(rh, ave_percent, index) ;

	/*
	unsigned		audio_framenum ;
	int64_t			pts ;
	unsigned		volume ;
	unsigned		max_volume ;

	unsigned 		sample_rate	;
	unsigned 		channels ;
	unsigned 		samples_per_frame ;
	unsigned 		samples ;
	unsigned 		framesize ;
	*/
	HVS_AUDIO_RESULT(rh, audio_framenum, index) ;
	/*HVS_AUDIO_RESULT(rh, pts, index) ;*/
	_store_ts(rh, "pts", user_data->results_array[index].audio_results.pts) ;
	HVS_AUDIO_RESULT(rh, volume, index) ;
	HVS_AUDIO_RESULT(rh, max_volume, index) ;
	HVS_AUDIO_RESULT(rh, sample_rate, index) ;
	HVS_AUDIO_RESULT(rh, channels, index) ;
	HVS_AUDIO_RESULT(rh, samples_per_frame, index) ;
	HVS_AUDIO_RESULT(rh, samples, index) ;
	HVS_AUDIO_RESULT(rh, framesize, index) ;
	HVS_AUDIO_RESULT(rh, silent_frame, index) ;
	HVS_AUDIO_RESULT(rh, volume_dB, index) ;

	HVS_RESULT_END ;

	return rh ;
}

//---------------------------------------------------------------------------------------------------------
static void execute_advert_detection(struct Ad_user_data * user_data, char *filename, HV *settings_href, HV *results, HV *settings)
{
SV **val;
HV * rh;
unsigned i ;
unsigned video_framenum ;
char key[256] ;

	// Set settings
	advert_set_settings(user_data, settings_href) ;

	if (user_data->debug) fprintf(stderr, "[XS] Pre-processing...\n") ;

	if (user_data->debug) dbg_print_settings(user_data) ;

	// Run detection - pre-process
	user_data->process_state = ADVERT_PREPROCESS ;
	run_preprocess(user_data, filename, advert_progress_hook) ;

	if (user_data->debug) fprintf(stderr, "[XS] dvb_err=%s [%03d]\n", dvb_error_str(dvb_error_code), dvb_error_code) ;

	if (user_data->debug) fprintf(stderr, "[XS] Detecting...\n") ;

    // Run detection - main
	user_data->process_state = ADVERT_PROCESS ;
    run_detect(user_data, filename, advert_progress_hook) ;

    if (user_data->debug) fprintf(stderr, "[XS] dvb_err=%s [%03d]\n", dvb_error_str(dvb_error_code), dvb_error_code) ;

	if (user_data->debug) fprintf(stderr, "[XS] Detect done\n") ;

    // == Pass results back to Perl ==

    // copy settings
    advert_get_settings(user_data, settings) ;

#ifdef PERLXS_DEBUG
	printf("frame,frame_end,start_pkt,end_pkt,gop_pkt,black_frame,scene_frame,size_change,screen_width,screen_height,") ;
	printf("brightness,uniform,dimCount,sceneChangePercent,") ;
	printf("logo_frame,match_percent,ave_percent,") ;
	printf("audio_framenum,volume,max_volume,sample_rate,channels,samples_per_frame,samples,") ;
	printf("framesize,silent_frame,volume_dB") ;
	printf("\n") ;
#endif

//    // get frame data
//	for (i=0; i < user_data->results_list_size; i++)
//	{
//		rh = advert_result(user_data, user_data->results_list[i].idx) ;
//		av_push(frames, newRV((SV *)rh));
//	}

//    // Free up structures
//    free_user_data(user_data) ;

}





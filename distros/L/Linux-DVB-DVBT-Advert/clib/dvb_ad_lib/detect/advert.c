/*
 * Common routines for advert detection
 *
 */
#include <math.h>
#include "ts_advert.h"

#include "detect/ad_logo.h"
#include "detect/ad_frame.h"
#include "detect/ad_audio.h"


// print debug if debug setting is high enough
#define advert_dbg_prt(LVL, ARGS)	\
		if (user_data->debug >= LVL)	printf ARGS

//===========================================================================================================================

#define _PRT(REG, REGION, NAME)	printf("%s.%s = %d\n", #REGION, #NAME, user_data->REG.NAME)
#define _PRT_FRAME(NAME)		_PRT(frame_settings, frame, NAME)
#define _PRT_LOGO(NAME)			_PRT(logo_settings, logo, NAME)
#define _PRT_AUDIO(NAME)		_PRT(audio_settings, audio, NAME)

void dbg_print_settings(struct Ad_user_data *user_data)
{
	printf("User Settings\n");
	printf("=============\n");

	_PRT_FRAME(max_black) ;
	_PRT_FRAME(window_percent) ;
	_PRT_FRAME(max_brightness) ;
	_PRT_FRAME(test_brightness) ;
	_PRT_FRAME(brightness_jump) ;
	_PRT_FRAME(schange_cutlevel) ;
	_PRT_FRAME(schange_jump) ;
	_PRT_FRAME(noise_level) ;
	_PRT_FRAME(remove_logo) ;


	_PRT_LOGO(window_percent) ;
	_PRT_LOGO(logo_window) ;
	_PRT_LOGO(logo_edge_radius) ;
	_PRT_LOGO(logo_edge_step) ;
	_PRT_LOGO(logo_edge_threshold) ;
	_PRT_LOGO(logo_checking_period) ;
	_PRT_LOGO(logo_skip_frames) ;
	_PRT_LOGO(logo_num_checks) ;
	_PRT_LOGO(logo_ok_percent) ;
	_PRT_LOGO(logo_max_percentage_of_screen) ;
	_PRT_LOGO(logo_ave_points) ;

	_PRT_AUDIO(scale) ;
	_PRT_AUDIO(silence_threshold) ;

}

//===========================================================================================================================
// PTS / Frame number utils
//
#define MAX_VIDEO_FRAME_JUMP	FPS

//---------------------------------------------------------------------------------------------------------------------------
static unsigned pts_framenum(uint64_t pts)
{
	return (unsigned)(pts / VIDEO_PTS_DELTA) ;
}

//---------------------------------------------------------------------------------------------------------------------------
static int video_pts_framenum(uint64_t pts, unsigned first_video_framenum)
{
	int framenum = -1 ;
	unsigned pts_frame = pts_framenum(pts) ;
	if (pts_frame >= first_video_framenum)
	{
		framenum = (int)(pts_frame - first_video_framenum) ;
	}
	return framenum ;
}

//===========================================================================================================================
// Results array utils
//

// Set to 30 minutes (+margin)
#define RESULTS_BLOCKSIZE		(32 * 60 * FPS)

//---------------------------------------------------------------------------------------------------------------------------
// Return the results array entry for this frame. Allocates more memory as appropriate
struct Ad_results *result_entry(struct Ad_user_data *user_data, unsigned framenum)
{
	// If framenum > array size, expand
	if (framenum >= user_data->results_array_size)
	{
		user_data->results_array_size += RESULTS_BLOCKSIZE ;

		user_data->results_array = (struct Ad_results *)realloc(user_data->results_array, user_data->results_array_size * sizeof(struct Ad_results)) ;
		memset(&user_data->results_array[user_data->results_array_size - RESULTS_BLOCKSIZE], 0, RESULTS_BLOCKSIZE * sizeof(struct Ad_results)) ;
	}

	return &user_data->results_array[framenum] ;
}

//---------------------------------------------------------------------------------------------------------------------------
// Free the results array
void free_results(struct Ad_user_data *user_data)
{
	if (user_data->results_array)
	{
		user_data->results_array_size = 0 ;
		free(user_data->results_array) ;
		user_data->results_array = NULL ;
	}
}

//---------------------------------------------------------------------------------------------------------------------------
// Free the results list
void free_results_list(struct Ad_user_data *user_data)
{
	if (user_data->results_list)
	{
		free(user_data->results_list) ;
	}
}

//---------------------------------------------------------------------------------------------------------------------------
// Return the results array
struct Ad_results *results_list(struct Ad_user_data *user_data)
{
	return user_data->results_array ;
}

//---------------------------------------------------------------------------------------------------------------------------
// DEBUG - show results
void dump_frame_results(unsigned framenum, struct Ad_frame_results *frame_results)
{
	fprintf(stderr, "  Frame %06d : frame results [%p] {\n", framenum, frame_results) ;
	fprintf(stderr, "    black_frame : %d,\n", frame_results->black_frame) ;
	fprintf(stderr, "    scene_frame : %d,\n", frame_results->scene_frame) ;
	fprintf(stderr, "    brightness : %d,\n", frame_results->brightness) ;
	fprintf(stderr, "    uniform : %d,\n", frame_results->uniform) ;
	fprintf(stderr, "    dimCount : %d,\n", frame_results->dimCount) ;
	fprintf(stderr, "    sceneChangePercent : %d,\n", frame_results->sceneChangePercent) ;
	fprintf(stderr, "  }\n") ;
}

//---------------------------------------------------------------------------------------------------------------------------
// DEBUG - show results
void dump_logo_results(unsigned framenum, struct Ad_logo_results *logo_results)
{
	fprintf(stderr, "  Frame %06d : logo results [%p] {\n", framenum, logo_results) ;

	fprintf(stderr, "    logo_frame : %d,\n", logo_results->logo_frame) ;
	fprintf(stderr, "    match_percent : %d,\n", logo_results->match_percent) ;
	fprintf(stderr, "    ave_percent : %d,\n", logo_results->ave_percent) ;
	fprintf(stderr, "  }\n") ;
}

//---------------------------------------------------------------------------------------------------------------------------
// DEBUG - show results
void dump_audio_results(unsigned framenum, struct Ad_audio_results *audio_results)
{
	fprintf(stderr, "  Frame %06d : audio results [%p] PTS %"PRId64" {\n", framenum, audio_results, audio_results->pts) ;

	fprintf(stderr, "    silent_frame : %d,\n", audio_results->silent_frame) ;
	fprintf(stderr, "    volume : %d,\n", audio_results->volume) ;
	fprintf(stderr, "    volume dB : %d,\n", audio_results->volume_dB) ;
	fprintf(stderr, "  }\n") ;
}

//---------------------------------------------------------------------------------------------------------------------------
// DEBUG - show results
void dump_results_list(struct Ad_user_data *user_data)
{
	fprintf(stderr, "\n===============================================\n") ;
	fprintf(stderr, "RESULTS ARRAY\n") ;
	if (user_data->results_array)
	{
	unsigned i ;

		for (i=0; i <= user_data->last_framenum; i++)
		{
			if (user_data->results_array[i].valid_frame)
			{
			fprintf(stderr, "%06d :: Frame %06d: <Valid=%d> Black=%d Scene=%d Logo=%d PTS=%"PRId64" {\n",
					user_data->results_array[i].framenum,
					i,
					user_data->results_array[i].valid_frame,
					user_data->results_array[i].frame_results.black_frame,
					user_data->results_array[i].frame_results.scene_frame,
					user_data->results_array[i].logo_results.logo_frame,
					user_data->results_array[i].pts
					) ;
dump_frame_results(i, &user_data->results_array[i].frame_results) ;
dump_logo_results(i, &user_data->results_array[i].logo_results) ;
dump_audio_results(i, &user_data->results_array[i].audio_results) ;

			fprintf(stderr, "}\n") ;
			}
		}
	}
	else
	{
		fprintf(stderr, "  <EMPTY>\n") ;
	}
	fprintf(stderr, "\n===============================================\n") ;
}


//---------------------------------------------------------------------------------------------------------------------------
// Post process results
void post_process_results(struct Ad_user_data *user_data)
{
unsigned i, video_framenum ;

	user_data->results_list = (struct Ad_results_list_entry *)malloc(user_data->results_array_size * sizeof(struct Ad_results_list_entry)) ;
	memset(user_data->results_list, 0, user_data->results_array_size * sizeof(struct Ad_results_list_entry)) ;

    // set frame numbers
	// Create the monotonic list
	user_data->results_list_size = 0 ;
	for (i=0; i < user_data->results_array_size; i++)
	{
		// only output if we have some results for this frame entry (create monotonically increasing frame count)
		if (user_data->results_array[i].valid_frame)
		{
			// set real frame number
			user_data->results_array[i].video_framenum = user_data->results_list_size ;

			// set the monotonic list to point to this entry
			user_data->results_list[user_data->results_list_size].results = &user_data->results_array[i] ;
			user_data->results_list[user_data->results_list_size++].idx = i ;
		}
	}

}

//===========================================================================================================================
// TS parse utils
//

//#define DEBUG_PIDHOOK

//---------------------------------------------------------------------------------------------------------------------------
// Only process the one pid when it's been set
unsigned pid_hook(unsigned pid, void *hook_data)
{
struct Ad_user_data *user_data = (struct Ad_user_data *)hook_data ;

	//
	// * if audio detecting AND both set, pass through if pid matches either value
	// * if not audio detecting AND video set, pass through if pid matches video value
	//
	unsigned pid_match = 0 ;

	// if either pid is set, check this pid against it
	unsigned audio_match = pid == user_data->audio_pid ;
	unsigned video_match = pid == user_data->pid ;

	if ( user_data->detection_method & METHOD_AUDIO )
	{
		// detecting audio
		if ( (user_data->audio_pid < 0) || (user_data->pid < 0))
		{
			// not both set yet, so wait
			pid_match = 1 ;
		}
		else
		{
			// see if pid matches video or audio pid
			pid_match = video_match || audio_match ;
		}
	}
	else
	{
		// not detecting audio
		if (user_data->pid < 0)
		{
			// video both set yet, so wait
			pid_match = 1 ;
		}
		else
		{
			// see if pid matches video pid
			pid_match = video_match ;
		}
	}

	return pid_match ;



}

//---------------------------------------------------------------------------------------------------------------------------
// Initialise the user data
void init_user_data(struct Ad_user_data *user_data)
{

	user_data->tsreader = NULL ;

	user_data->debug = 0 ;
	user_data->ts_debug = 0 ;
	user_data->start_pkt = 0 ;
	user_data->num_frames = 0 ;

	user_data->detection_method = METHOD_DEFAULT ;

	user_data->last_framenum = 0 ;

	user_data->stop_processing = 0 ;
	user_data->multi_process = 0 ;

	user_data->process_state = ADVERT_PREPROCESS ;

	user_data->pid = -1 ;
	user_data->audio_pid = -1 ;

	// PTS
	user_data->first_audio_pts = UNSET_TS ;
	user_data->first_video_pts = UNSET_TS ;


	//////////////////////////////
	// Perl
	user_data->progress_callback = NULL ;
	user_data->extra_data = NULL ;

	//////////////////////////////
	// Detectors
	frame_detector_init(&user_data->frame_settings, &user_data->frame_state) ;
	logo_detector_init(&user_data->logo_settings, &user_data->logo_state) ;
	audio_detector_init(&user_data->audio_settings, &user_data->audio_state) ;

	// perl settings
	set_default_perl_settings(user_data) ;


	//////////////////////////////
	// Results
	user_data->results_array_size = 0 ;
	user_data->results_array = NULL ;
	user_data->results_list_size = 0 ;
	user_data->results_list = NULL ;

	frame_init_totals(&user_data->frame_totals) ;
	logo_init_totals(&user_data->logo_totals) ;
	audio_init_totals(&user_data->audio_totals) ;

}


//---------------------------------------------------------------------------------------------------------------------------
// Free up detector's data, then clear locally created data (results etc)
void free_user_data(struct Ad_user_data *user_data)
{
	// free detectors
	frame_detector_free(&user_data->frame_state) ;
	logo_detector_free(&user_data->logo_state) ;
	audio_detector_free(&user_data->audio_state) ;

	// free results
	free_results(user_data) ;

	// free local data
	free_results_list(user_data) ;

}

//---------------------------------------------------------------------------------------------------------------------------
void mpeg2_preprocess_hook(struct TS_pidinfo *pidinfo, struct TS_frame_info *frameinfo, const mpeg2_info_t *info, void *hook_data)
{
struct Ad_user_data *user_data = (struct Ad_user_data *)hook_data ;
unsigned framenum = frameinfo->framenum ;
unsigned handled = 0 ;

advert_dbg_prt(2, ("mpeg2_preprocess_hook() : PID = %d : Detect = 0x%02x\n", pidinfo->pid, user_data->detection_method)) ;

	// set pid
	if (user_data->pid < 0)
	{
		user_data->pid = pidinfo->pid ;
		advert_dbg_prt(1, ("Locked down TS parsing just to video PID = %d\n", pidinfo->pid)) ;
	}

	// Update last frame number - only tracks up to the point at which we stop pre-processing
	user_data->last_framenum = framenum ;

	// Pass to individual pre-processors
	if (user_data->detection_method & METHOD_LOGO)
	{
		logo_detector_preprocess(user_data->tsreader, pidinfo, frameinfo, info,
				&user_data->logo_settings,
				&user_data->logo_state) ;
		++handled ;
	}

	if (!handled)
	{
		user_data->stop_processing = 1 ;
	}

	// For debug - stop after specified number of frames
	if (user_data->num_frames && (framenum >= user_data->num_frames))
	{
		user_data->stop_processing = 1 ;
	}

advert_dbg_prt(2, ("mpeg2_preprocess_hook() - END : stop = %d\n", user_data->stop_processing)) ;

	// stop if required
	if (user_data->stop_processing)
	{
		// stop now
		tsreader_stop(user_data->tsreader) ;
		return ;
	}
}

//---------------------------------------------------------------------------------------------------------------------------
void mpeg2_detect_hook(struct TS_pidinfo *pidinfo, struct TS_frame_info *frameinfo, const mpeg2_info_t *info, void *hook_data)
{
struct Ad_user_data *user_data = (struct Ad_user_data *)hook_data ;
unsigned framenum = frameinfo->framenum ;
unsigned handled = 0 ;
struct Ad_results *results ;

advert_dbg_prt(2, ("mpeg2_detect_hook() : PID = %d : Detect = 0x%02x\n", pidinfo->pid, user_data->detection_method)) ;

	// set pid
	if (user_data->pid < 0)
	{
		user_data->pid = pidinfo->pid ;
		advert_dbg_prt(1, ("Locked down TS parsing just to video PID = %d\n", pidinfo->pid)) ;
	}

	// Update last frame number
	if (user_data->last_framenum < framenum) user_data->last_framenum = framenum ;

	// keep track of PTS
	unsigned pts_frame = pts_framenum(frameinfo->pesinfo.dts) ;
	if (user_data->first_video_pts == UNSET_TS)
	{
		user_data->first_video_pts = frameinfo->pesinfo.dts ;
		user_data->first_video_pts_framenum = pts_frame ;
		user_data->prev_video_framenum = (unsigned)video_pts_framenum(frameinfo->pesinfo.dts, user_data->first_video_pts_framenum) ;
		user_data->prev_video_pts = frameinfo->pesinfo.dts ;
	}

	// Fix any jumps
	int64_t fixed_pts = frameinfo->pesinfo.dts ;
	unsigned video_framenum = (unsigned)video_pts_framenum(frameinfo->pesinfo.dts, user_data->first_video_pts_framenum) ;
	if ((video_framenum > user_data->prev_video_framenum + MAX_VIDEO_FRAME_JUMP) || (frameinfo->pesinfo.dts < user_data->prev_video_pts))
	{
		advert_dbg_prt(2, (" !! video fixed framenum: from %u to %u [pts %"PRId64" prev pts %"PRId64"]\n",
				video_framenum, user_data->prev_video_framenum+1,
				frameinfo->pesinfo.dts, user_data->prev_video_pts)) ;

		// fix any major PTS jumps
		video_framenum = user_data->prev_video_framenum+1 ;
		fixed_pts = user_data->prev_video_pts+VIDEO_PTS_DELTA ;
	}
	user_data->prev_video_framenum = video_framenum ;
	user_data->prev_video_pts = fixed_pts ;

	advert_dbg_prt(1, ("mpeg2 :frame %06d : PTS %"PRId64" : FIXED PTS %"PRId64" : pts frame=%u first=%u : curr frame=%u\n",
			framenum, frameinfo->pesinfo.dts, fixed_pts, pts_frame, user_data->first_video_pts_framenum, video_framenum)) ;


	// Results
	results = result_entry(user_data, video_framenum) ;
	results->start_pkt = frameinfo->pesinfo.start_pkt ;
	results->end_pkt = frameinfo->pesinfo.end_pkt ;
	results->gop_pkt = frameinfo->gop_pkt ;
	results->pts = frameinfo->pesinfo.dts ;
	results->fixed_pts = fixed_pts ;
	results->framenum = framenum ;
	results->valid_frame = 1 ;

	// Pass to individual processors
	if (user_data->detection_method & METHOD_BLACK)
	{
		advert_dbg_prt(2, ("mpeg2_detect_hook() : BLACK\n")) ;

		// detect
		frame_detector_run(user_data->tsreader, pidinfo, frameinfo, info,
				&user_data->frame_settings,
				&user_data->frame_state,
				&results->frame_results,
				&user_data->frame_totals);
		++handled ;
	}

	if (user_data->detection_method & METHOD_LOGO)
	{
		advert_dbg_prt(2, ("mpeg2_detect_hook() : LOGO : logo_found = %d\n", user_data->logo_state.logo_found)) ;

		if (user_data->logo_state.logo_found)
		{
			logo_detector_run(user_data->tsreader, pidinfo, frameinfo, info,
					&user_data->logo_settings,
					&user_data->logo_state,
					&results->logo_results,
					&user_data->logo_totals);
		}
		++handled ;
	}

	// For debug - stop after specified number of frames
	if (user_data->num_frames && (framenum >= user_data->num_frames))
	{
		user_data->stop_processing = 1 ;
	}

advert_dbg_prt(2, ("mpeg2_detect_hook() - END : stop = %d\n", user_data->stop_processing)) ;

}

//---------------------------------------------------------------------------------------------------------------------------
void audio_detect_hook(struct TS_pidinfo *pidinfo, struct TS_pesinfo *pesinfo, const mpeg2_audio_t *info, void *hook_data)
{
struct Ad_user_data *user_data = (struct Ad_user_data *)hook_data ;
unsigned handled = 0 ;
struct Ad_audio_results	audio_results ;

	advert_dbg_prt(1, ("audio_detect_hook() : PID = %d : Detect = 0x%02x\n", pidinfo->pid, user_data->detection_method)) ;

	// set pid
	if (user_data->audio_pid < 0)
	{
		user_data->audio_pid = pidinfo->pid ;
		advert_dbg_prt(1, ("Locked down TS parsing just to audio PID = %d\n", pidinfo->pid)) ;
	}

	// Pass to individual processors
	if (user_data->detection_method & METHOD_AUDIO)
	{
		advert_dbg_prt(1, ("audio_detect_hook() : AUDIO\n")) ;

		audio_detector_run(user_data->tsreader, pidinfo, pesinfo, info,
				&user_data->audio_settings,
				&user_data->audio_state,
				&audio_results,
				&user_data->audio_totals) ;

		++handled ;

		// Track PTS
		if (info->audio_framenum == 0)
		{
			user_data->first_audio_pts = audio_results.pts ;
			user_data->prev_audio_framenum = 0 ;
		}

		advert_dbg_prt(1, ("audio pts=%"PRIu64" (pes pts %"PRId64") first=%"PRIu64" (video=%"PRIu64")\n",
				audio_results.pts,
				pesinfo->dts,
				user_data->first_audio_pts,
				user_data->first_video_pts)) ;

		// Only report audio once we've got some video
		if (user_data->first_video_pts != UNSET_TS)
		{
			// convert audio PTS into a video frame number
			int pts_framenum = video_pts_framenum(audio_results.pts, user_data->first_video_pts_framenum) ;

			if (pts_framenum >= 0)
			{
			struct Ad_results *results ;
			unsigned fnum ;

				// check for jumps
				if (pts_framenum > user_data->prev_audio_framenum + MAX_VIDEO_FRAME_JUMP)
				{
					advert_dbg_prt(2, (" !! audio fixed framenum: from %u to %u\n",pts_framenum, user_data->prev_audio_framenum+1)) ;

					// fix any major PTS jumps
					pts_framenum = user_data->prev_audio_framenum+1 ;
				}

				// fill in any gaps
				for (fnum=user_data->prev_audio_framenum+1; fnum < pts_framenum; ++fnum)
				{
					struct Ad_results *prev_results ;

					// copy last good values
					results = result_entry(user_data, fnum) ;
					prev_results = result_entry(user_data, user_data->prev_audio_framenum) ;	// NB: Must do this here each time because previous call can relocate the array

					results = result_entry(user_data, fnum) ;

					advert_dbg_prt(1, (" ++ audio copying frame %u [PTS %"PRId64"] to %u\n",
							user_data->prev_audio_framenum, prev_results->audio_results.pts, fnum)) ;

					memcpy(&results->audio_results, &prev_results->audio_results, sizeof(struct Ad_audio_results) ) ;
				}

				// update prev
				user_data->prev_audio_framenum = pts_framenum ;

				// Results
				results = result_entry(user_data, pts_framenum) ;

				// save results
				memcpy(&results->audio_results, &audio_results, sizeof(struct Ad_audio_results) ) ;

				advert_dbg_prt(1, ("Audio frame %06d : vol %d  vol dB %d : pkt %u [ %u ..  %u] PTS %"PRId64" (Adjusted  PTS %"PRId64")\n",
						pts_framenum,
						audio_results.volume,
						audio_results.volume_dB,
						pidinfo->pktnum,
						pesinfo->start_pkt, pesinfo->end_pkt,
						audio_results.pts,
						(int64_t)pts_framenum*(int64_t)VIDEO_PTS_DELTA));

			}
		}

	}

advert_dbg_prt(2, ("audio_detect_hook() - END : stop = %d\n", user_data->stop_processing)) ;

}




//============================================================================================
enum DVB_error run_preprocess(struct Ad_user_data *user_data,
		char *filename, tsparse_progress_hook progress_hook)
{
struct TS_reader *tsreader ;

	tsreader = tsreader_new(filename) ;
    if (!tsreader)
    {
		fprintf(stderr,"ERROR %s: %s\n",filename,dvb_error_str(dvb_error_code));
		return(ERR_FILE);
    }

    tsreader->num_pkts = 0 ;
    tsreader->skip = 0 ;
    tsreader->debug = user_data->ts_debug ;
    tsreader->user_data = user_data ;
    user_data->tsreader = tsreader ;

	tsreader->pid_hook = pid_hook ;
	tsreader->mpeg2_hook = mpeg2_preprocess_hook ;
	if (progress_hook)
	{
		tsreader->progress_hook = progress_hook ;
	}

	user_data->stop_processing = 0 ;
	user_data->multi_process = 1 ;

    // process file
    tsreader_setpos(tsreader, user_data->start_pkt, SEEK_SET, 0) ;
    ts_parse(tsreader) ;

    // end
    tsreader_free(tsreader) ;

    // Found logo?
	if (user_data->logo_state.logo_found)
	{
		frame_set_logo_area(&user_data->frame_settings,
				1 /* remove_logo */,
				user_data->logo_state.logo_screen->logo_y1,		// top left
				user_data->logo_state.logo_screen->logo_x1,
				user_data->logo_state.logo_screen->logo_y2,		// bottom right
				user_data->logo_state.logo_screen->logo_x2);
	}


    return (ERR_NONE) ;
}

//============================================================================================
enum DVB_error run_detect(struct Ad_user_data *user_data,
		char *filename, tsparse_progress_hook progress_hook)
{
struct TS_reader *tsreader ;

	tsreader = tsreader_new(filename) ;
    if (!tsreader)
    {
		fprintf(stderr,"ERROR %s: %s\n",filename,dvb_error_str(dvb_error_code));
		return(ERR_FILE);
    }
    tsreader->num_pkts = 0LLU ;
    tsreader->skip = 0LLU ;
    tsreader->debug = user_data->ts_debug ;
    tsreader->user_data = user_data ;
    user_data->tsreader = tsreader ;

    advert_dbg_prt(1, ("Total Num packets=%u\n", tsreader->tsstate->total_pkts)) ;

	tsreader->pid_hook = pid_hook ;
	tsreader->mpeg2_hook = mpeg2_detect_hook ;

	if (user_data->detection_method == 0)
	{
		user_data->detection_method = METHOD_MIN ;
	}

	if (user_data->detection_method & METHOD_AUDIO)
	{
		tsreader->audio_hook = audio_detect_hook ;
	}

	if (progress_hook)
	{
		tsreader->progress_hook = progress_hook ;
	}

	user_data->stop_processing = 0 ;
	user_data->multi_process = 1 ;

    // process file
    tsreader_setpos(tsreader, user_data->start_pkt, SEEK_SET, 0) ;
    ts_parse(tsreader) ;

    advert_dbg_prt(1, ("Last frame=%u\n", user_data->last_framenum)) ;

    // end
    tsreader_free(tsreader) ;

    advert_dbg_prt(1, ("run_detect: last frame=%d, results size=%d\n",
    		user_data->last_framenum,
    		user_data->results_array_size));

    // Do any post-run cleanup/processing
    post_process_results(user_data) ;

    if (user_data->debug >= 10)
    	dump_results_list(user_data) ;

    return (ERR_NONE) ;
}

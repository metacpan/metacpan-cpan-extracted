/*
 * Frame statistics (blank, scene change) etc.
 *
 */


#include "ad_frame.h"
#include "ts_advert.h"


//===========================================================================================================================
// CONSTANTS
//===========================================================================================================================

// Audio default Perl settings
#define FRAME_max_advert			(3*60*FPS)
#define FRAME_min_advert			(3*60*FPS)
#define FRAME_min_program			(5*60*FPS)
#define FRAME_start_pad				(2*60*FPS)
#define FRAME_end_pad				(2*60*FPS)
#define FRAME_min_frames 	 		2
#define FRAME_frame_window 	 		(4*60*FPS)
#define FRAME_max_gap 		 		(10*FPS)
#define FRAME_reduce_end			0
#define FRAME_reduce_min_gap	 	0

//#define DEBUG_STATE

//===========================================================================================================================
// MACROS
//===========================================================================================================================


// print debug if debug setting is high enough
#define frame_dbg_prt(LVL, ARGS)	\
		if (frame_settings->debug >= LVL)	printf ARGS


//===========================================================================================================================
// FUNCTIONS
//===========================================================================================================================



//---------------------------------------------------------------------------------------------------------------------------
#ifdef DEBUG_STATE
static void dump_histo(char *msg, unsigned *histo)
{
unsigned i;

	fprintf(stderr, "%s\n", msg) ;
	for (i=0; i < HISTOGRAM_BINS; )
	{
	unsigned j ;

		fprintf(stderr, "%4d: ", i) ;
		for (j=0; j<32; j++, i++)
		{
			fprintf(stderr, "%04x ", histo[i]) ;
		}
		fprintf(stderr, "\n") ;
	}
	fprintf(stderr, "\n") ;
}
#endif

//===========================================================================================================================
// Stats utils
//


//---------------------------------------------------------------------------------------------------------------------------
// Blank out buffer area
static void _remove_logo(int width, int height,
		int chroma_width, int chroma_height,
		uint8_t ** buf,
		struct Ad_frame_settings *frame_settings)
{
uint8_t *frame = buf[0] ;
uint8_t *Cr = buf[1] ;
uint8_t *Cb = buf[2] ;
uint8_t *pp_Cr, *pp_Cb, *pp ;
unsigned x, y ;

unsigned chroma_x1 = frame_settings->logo_x1 / 2 ;
unsigned chroma_y1 = frame_settings->logo_y1 / 2 ;
unsigned chroma_x2 = frame_settings->logo_x2 / 2 ;
unsigned chroma_y2 = frame_settings->logo_y2 / 2 ;


	// Chroma
	for(y = chroma_y1; (y <= chroma_y2); y++)
	{
	unsigned offset = (y * chroma_width) + chroma_x1 ;
	uint8_t blank_Cr=0 ;
	uint8_t blank_Cb=0 ;

		if (chroma_x1 > 0)
		{
			blank_Cr = Cr[offset-1];
			blank_Cb = Cb[offset-1];
		}

		pp_Cr = &Cr[offset] ;
		pp_Cb = &Cb[offset] ;

		for (x=chroma_x1; (x <= chroma_x2); x++)
		{
			*pp_Cr++ = blank_Cr ;
			*pp_Cb++ = blank_Cb ;
		}
	}

	// Frame
	for(y = frame_settings->logo_y1; (y <= frame_settings->logo_y2); y++)
	{
	unsigned offset = (y * width) + frame_settings->logo_x1 ;
	uint8_t blank = 0 ;

		if (frame_settings->logo_x1 > 0)
		{
			blank = frame[offset-1];
		}

		pp = &frame[offset] ;

		for (x=frame_settings->logo_x1; (x <= frame_settings->logo_x2); x++)
		{
			*pp++ = blank ;
		}
	}

}

//---------------------------------------------------------------------------------------------------------------------------
static unsigned _chroma_diff(
		int chroma_width, int chroma_height,
		uint8_t * const * buf, int framenum,
		struct Ad_frame_settings *frame_settings,
		struct Ad_frame_state *frame_state
		)
{
uint8_t *Cr = buf[1] ;
uint8_t *Cb = buf[2] ;
uint8_t *pp_Cr, *pp_Cb ;
unsigned x, y ;
unsigned max_diff = 0 ;

unsigned start_row ;
unsigned sample_height ;
unsigned start_col ;
unsigned sample_width ;
unsigned num_pixels ;
unsigned step ;


	// Chroma
	start_row = chroma_height * (100 - frame_settings->window_percent) / 200 ;
	sample_height = chroma_height * frame_settings->window_percent / 100 ;
	start_col = chroma_width * (100 - frame_settings->window_percent) / 200 ;
	sample_width = chroma_width * frame_settings->window_percent / 100 ;
	num_pixels = sample_height * sample_width ;
	step = 2;

	if (chroma_width > 800) step = 4;
	if (chroma_width < 400) step = 1;

	for(y = 0; (y < sample_height); y+=step)
	{
	unsigned offset = (start_row+y) * chroma_width + start_col ;

		pp_Cr = &Cr[offset] ;
		pp_Cb = &Cb[offset] ;

		for (x=0; (x < sample_width); x+=step)
		{
		unsigned diff = abs(*pp_Cr - *pp_Cb) ;

			if (diff > max_diff)
			{
				max_diff = diff;
			}
			pp_Cr += step;
			pp_Cb += step ;
		}
	}

	return max_diff ;
}

//---------------------------------------------------------------------------------------------------------------------------
static void _frame_state(
		int width, int height,
		uint8_t * const * buf, int framenum,
		struct Ad_frame_settings *frame_settings,
		struct Ad_frame_state *frame_state
		)
{
uint8_t *frame = buf[0] ;
unsigned x, y ;


unsigned	start_row = height * (100 - frame_settings->window_percent) / 200 ;
unsigned	sample_height = height * frame_settings->window_percent / 100 ;
unsigned	start_col = width * (100 - frame_settings->window_percent) / 200 ;
unsigned	sample_width = width * frame_settings->window_percent / 100 ;
unsigned	num_pixels = height * sample_width ;

int i ;
int uniform ;
int pixels = 0 ;
long similar = 0;
int		hasBright = 0;
int		dimCount = 0;
int		sceneChangePercent;

unsigned 	delta, hereBright ;
unsigned	brightCountminX = 0;
unsigned	brightCountminY = 0;
unsigned	brightCountmaxX = 0;
unsigned	brightCountmaxY = 0;

unsigned	minY = start_row;
unsigned	maxY = height - start_row;
unsigned	minX = start_col;
unsigned	maxX = width - start_col;
unsigned	brightCount = 0;
unsigned	step = 4;


frame_dbg_prt(4, ("_frame_state(w %d x h %d) %d%%\n", width, height, frame_settings->window_percent)) ;

	frame_state->max_bright = 0 ;

	if (width > 800) step = 8;
	if (width < 400) step = 2;

	memcpy(frame_state->lastHistogram, frame_state->histogram, sizeof(frame_state->histogram));

	// compare current frame with last frame here
	memset(frame_state->histogram, 0, sizeof(frame_state->histogram));

	delta = 0;

	//			minX						maxX
	//
	//	minY	+---------------------------+
	//			|							|
	//			|	+-------------------+	|
	//			|	|					|	|
	//			|	+-------------------+	|
	//			|							|
	//	maxY	+---------------------------+
	//

	brightCountminX = 0;
	brightCountminY = 0;
	brightCountmaxX = 0;
	brightCountmaxY = 0;
	while (1)
	{
		y = start_row + delta;
//fprintf(stderr, "1: Y=%d\n  X: ", y) ;
		for (x = start_col + delta; x <= width - start_col - delta; x += step) {
//fprintf(stderr, "%d,", x) ;
//			if (haslogo[y * width + x])
//				continue;
			hereBright = frame[y * width + x];
			frame_state->histogram[hereBright]++;

			if (hereBright > frame_state->max_bright) frame_state->max_bright = hereBright ;

			// update brightness count for minY
			if (hereBright > frame_settings->test_brightness)
				brightCountminY++;
		}
//fprintf(stderr, "\n") ;

		// keep moving minY down until brightness registers
		if (brightCountminY < 5) {
			minY = y;
		}


		y = height - start_row - delta;
//		fprintf(stderr, "2: Y=%d\n  X: ", y) ;
		for (x = start_col + delta; x <= width - start_col - delta; x += step) {
//			fprintf(stderr, "%d,", x) ;
//			if (haslogo[y * width + x])
//				continue;
			hereBright = frame[y * width + x];
			frame_state->histogram[hereBright]++;

			if (hereBright > frame_state->max_bright) frame_state->max_bright = hereBright ;

			// update brightness count for maxY
			if (hereBright > frame_settings->test_brightness)
				brightCountmaxY++;
		}
//		fprintf(stderr, "\n") ;

		// keep moving maxY up until brightness registers
		if (brightCountmaxY < 5) {
			maxY = y;
		}

		x = start_col + delta;
//		fprintf(stderr, "3: X=%d\n  Y: ", x) ;
		for (y = start_row + delta; y <= height - start_row - delta; y += step) {
//			fprintf(stderr, "%d,", y) ;
//			if (haslogo[y * width + x])
//				continue;
			hereBright = frame[y * width + x];
			frame_state->histogram[hereBright]++;

			if (hereBright > frame_state->max_bright) frame_state->max_bright = hereBright ;

			// update brightness count for minX
			if (hereBright > frame_settings->test_brightness)
				brightCountminX++;
		}
//		fprintf(stderr, "\n") ;

		// keep moving minX right until brightness registers
		if (brightCountminX < 5) {
			minX = x;
		}
//		fprintf(stderr, "brightCountmaxX=%d\n", brightCountmaxX) ;

		x = width - start_col - delta;

		// don't bother with brightness update if maxX brightness registers
		if (brightCountmaxX < 5) {
//			fprintf(stderr, "4: X=%d\n  Y: ", x) ;
			for (y = start_row + delta; y <= height - start_row - delta; y += step) {
//				if (haslogo[y * width + x])
//					continue;
				hereBright = frame[y * width + x];
				frame_state->histogram[hereBright]++;

				if (hereBright > frame_state->max_bright) frame_state->max_bright = hereBright ;

				// update brightness count for maxX
				if (hereBright > frame_settings->test_brightness)
					brightCountmaxX++;
			}
//			fprintf(stderr, "\n") ;

			// keep moving maxX left until brightness registers
			if (brightCountmaxX < 5) {
				maxX = x;
			}
		}

		delta += step;

		if (delta > width / 2 || delta > height / 2)
		{
			// ****** STOP ******
			break;
		}
	}

}

//---------------------------------------------------------------------------------------------------------------------------
void calc_frame_state(
		struct TS_frame_info *frameinfo,
		int width, int height,
		int chroma_width, int chroma_height,
		uint8_t * const * buf, int framenum,
		struct Ad_frame_settings *frame_settings,
		struct Ad_frame_state *frame_state,
		struct Ad_frame_results *results,
		struct Ad_frame_totals *totals
		)
{
int 		i ;
unsigned 	pixels = 0 ;
long		similar = 0;


	// remove logo area if required
	if (frame_settings->remove_logo && frame_settings->logo_set)
	{
		_remove_logo(width, height,
				chroma_width, chroma_height,
				(uint8_t **)buf,
				frame_settings) ;
	}

	// Chroma
	frame_state->max_diff = _chroma_diff(chroma_width, chroma_height, buf, framenum, frame_settings, frame_state) ;

	// Frame stats
	_frame_state(width, height, buf, framenum, frame_settings, frame_state) ;

	frame_state->last_brightness = frame_state->brightness;
	frame_state->brightness = 0;

	frame_state->hasBright = 0;
	frame_state->dimCount = 0;

#ifdef DEBUG_STATE
dump_histo("Last Histograme", frame_state->lastHistogram) ;
dump_histo("Current Histograme", frame_state->histogram) ;
#endif

	// pixels = SUM( num_pixels[pixel_val] )
	// brightness = SUM( pixel_val * num_pixels[pixel_val] ) / SUM( num_pixels[pixel_val] )
	//
	//
	for (i = 255; i > frame_settings->max_brightness; i--)
	{
		pixels += frame_state->histogram[i];
		frame_state->brightness += frame_state->histogram[i] * i;

		// ** > max **
		if (frame_state->histogram[i])
			frame_state->hasBright++;

		if (frame_state->histogram[i] < frame_state->lastHistogram[i])
			similar += frame_state->histogram[i];
		else
			similar += frame_state->lastHistogram[i];
	}

	for (i = frame_settings->max_brightness; i > frame_settings->test_brightness; i--)
	{
		pixels += frame_state->histogram[i];
		frame_state->brightness += frame_state->histogram[i] * i;

		// ** max .. test **
		frame_state->dimCount += frame_state->histogram[i];

		if (frame_state->histogram[i] < frame_state->lastHistogram[i])
			similar += frame_state->histogram[i];
		else
			similar += frame_state->lastHistogram[i];
	}

	for (i = frame_settings->test_brightness; i >= 0; i--)
	{
		pixels += frame_state->histogram[i];
		frame_state->brightness += frame_state->histogram[i] * i;

		if (frame_state->histogram[i] < frame_state->lastHistogram[i])
			similar += frame_state->histogram[i];
		else
			similar += frame_state->lastHistogram[i];
	}
	frame_state->brightness /= pixels;

	frame_state->dimCount = frame_state->dimCount * 100 / pixels ;

	//---------------
	frame_state->sceneChangePercent = 100 - (unsigned)(100.0 * similar / pixels);
	if (frame_state->sceneChangePercent < 0) frame_state->sceneChangePercent=0 ;
	if (frame_state->sceneChangePercent > 100) frame_state->sceneChangePercent=100 ;

	//------------------
	// uniform = SUM( (pixel_val  - brightness) * num_pixels[pixel_val] ) 			255 >= pixel_val > brightness + noise
	// uniform = SUM( (brightness - pixel_val)  * num_pixels[pixel_val] ) 			brightness - noise >= pixel_val >= 0
	//
#ifdef DEBUG_STATE
fprintf(stderr, "uniform calc: bright=%d, noise=%d, pixels=%d\n",
		frame_state->brightness, frame_settings->noise_level, pixels) ;
#endif

	frame_state->uniform = 0;
	for (i = 255; i > frame_state->brightness + frame_settings->noise_level; i--) {
		frame_state->uniform +=  frame_state->histogram[i] * (i - frame_state->brightness);
	}
#ifdef DEBUG_STATE
fprintf(stderr, " + uniform calc A: uniform=%d\n", frame_state->uniform) ;
#endif
	for (i = frame_state->brightness - frame_settings->noise_level; i >= 0; i--) {
		frame_state->uniform +=  frame_state->histogram[i] * (frame_state->brightness - i);
	}
#ifdef DEBUG_STATE
fprintf(stderr, " + uniform calc B: uniform=%d\n", frame_state->uniform) ;
#endif
//	frame_state->uniform = ((double)frame_state->uniform) * 730/pixels;
	frame_state->uniform = (unsigned)(((double)frame_state->uniform) * 100/pixels);
#ifdef DEBUG_STATE
fprintf(stderr, " + uniform calc C: uniform=%d\n", frame_state->uniform) ;
#endif

	if (frame_state->min_uniform > frame_state->uniform) frame_state->min_uniform = frame_state->uniform ;
	if (frame_state->max_uniform < frame_state->uniform) frame_state->max_uniform = frame_state->uniform ;

	//---------------
	if (abs(frame_state->brightness - frame_state->last_brightness) > frame_settings->brightness_jump)
	{
		results->black_frame = 1 ;

		frame_dbg_prt(1, ("Black Frame %6i [ %u ..  %u] - Black frame because large brightness change from %i to %i with uniform %i (chroma %u)\n",
				framenum, frameinfo->pesinfo.start_pkt, frameinfo->pesinfo.end_pkt, frame_state->last_brightness, frame_state->brightness, frame_state->uniform, frame_state->max_diff));
	}

	if (frame_state->max_bright <= frame_settings->max_black)
	{
		results->black_frame = 1 ;

		frame_dbg_prt(1, ("Black Frame %6i [ %u ..  %u] - Black frame because max bright %d < threshold (chroma %d)\n",
				framenum, frameinfo->pesinfo.start_pkt, frameinfo->pesinfo.end_pkt, frame_state->max_bright, frame_state->max_diff));
	}

	if (frame_state->sceneChangePercent > frame_settings->schange_cutlevel)
	{
		results->scene_frame = 1 ;

		frame_dbg_prt(1, ("Scene Frame %6i [ %u ..  %u] - Black frame because large scene change of %i, uniform %i\n",
				framenum, frameinfo->pesinfo.start_pkt, frameinfo->pesinfo.end_pkt, frame_state->sceneChangePercent, frame_state->uniform));
	}
	if ((int)frame_state->sceneChangePercent - (int)frame_state->prev_sceneChangePercent > (int)frame_settings->schange_jump)
	{
		results->scene_frame = 1 ;

		frame_dbg_prt(1, ("Scene Frame %6i [ %u ..  %u] - Black frame because large scene change of %i to %i, uniform %i\n",
				framenum, frameinfo->pesinfo.start_pkt, frameinfo->pesinfo.end_pkt, frame_state->prev_sceneChangePercent, frame_state->sceneChangePercent, frame_state->uniform));
	}

	frame_dbg_prt(1, ("# frame %5d : has %d, dim %d, brightness %d, similar %ld (pixels %d), scene change %d%%, uniform %d [%d .. %d]\n", framenum,
			frame_state->hasBright, frame_state->dimCount, frame_state->brightness,
			similar, pixels, frame_state->sceneChangePercent, frame_state->uniform,
			frame_state->min_uniform, frame_state->max_uniform)) ;

	results->screen_width = width ;
	results->screen_height = height ;
	results->brightness = frame_state->brightness ;
	results->uniform = frame_state->uniform ;
	results->dimCount = frame_state->dimCount ;
	results->sceneChangePercent = frame_state->sceneChangePercent ;

	// check for screen size change
	results->size_change = 0 ;
	if (frame_state->prev_screen_height && frame_state->prev_screen_width)
	{
		if (results->screen_width != frame_state->prev_screen_width) results->size_change = 1 ;
		if (results->screen_height != frame_state->prev_screen_height) results->size_change = 1 ;
	}

	//---------------
	frame_state->prev_sceneChangePercent = frame_state->sceneChangePercent ;
	frame_state->prev_screen_width = results->screen_width ;
	frame_state->prev_screen_height = results->screen_height ;

	// Totals
	if (results->black_frame) ++totals->num_black_frames ;
	if (results->scene_frame) ++totals->num_scene_frames ;
	if (results->size_change) ++totals->num_size_frames ;

}




//---------------------------------------------------------------------------------------------------------------------------
// Initialise logo area
void frame_set_logo_area(struct Ad_frame_settings *settings,
		unsigned	logo_set,
		unsigned	logo_y1,		// top left
		unsigned	logo_x1,
		unsigned	logo_y2,		// bottom right
		unsigned	logo_x2)
{
	settings->logo_set = logo_set ;
	if (logo_set)
	{
		settings->logo_x1 = logo_x1 ;
		settings->logo_y1 = logo_y1 ;
		settings->logo_x2 = logo_x2 ;
		settings->logo_y2 = logo_y1 ;
	}
	else
	{
		settings->logo_x1 = 0 ;
		settings->logo_y1 = 0 ;
		settings->logo_x2 = 0 ;
		settings->logo_y2 = 0 ;
	}
}


//---------------------------------------------------------------------------------------------------------------------------
// Initialise the user data
void frame_init_settings(struct Ad_frame_settings *settings)
{
	settings->debug = 0 ;

	settings->max_brightness = 60;				// frame not black if any pixels checked are greater than this (scale 0 to 255)
	settings->test_brightness = 40;				// frame not pure black if any pixels are greater than this, will check average

	settings->brightness_jump = 200;
	settings->schange_cutlevel = 85;
	settings->schange_jump = 30;

	settings->noise_level=5;

	settings->window_percent = WINDOW_PERCENT;

	// maximum pixel value considered as a black frame
	settings->max_black = MAX_BLACK ;

	// no logo removal
	settings->remove_logo = 0 ;
	frame_set_logo_area(settings, 0, 0,0, 0,0) ;

	// Perl settings
	// set_perl_settings(settings, mx_ad, mn_ad, mn_pr, s_pd, e_pd, mn_fr, fr_wn, mx_gp, r_en, r_mn_gp)
	set_perl_settings(settings,
		FRAME_max_advert,
		FRAME_min_advert,
		FRAME_min_program,
		FRAME_start_pad,
		FRAME_end_pad,
		FRAME_min_frames,
		FRAME_frame_window,
		FRAME_max_gap,
		FRAME_reduce_end,
		FRAME_reduce_min_gap
	) ;

}

//---------------------------------------------------------------------------------------------------------------------------
// Initialise the state data
void frame_init_state(struct Ad_frame_state *state)
{
	state->brightness = 0 ;
	state->last_brightness = 0 ;
	state->prevsimilar = 0 ;
	state->prev_sceneChangePercent = 0 ;
	memset(state->histogram, 0, HISTOGRAM_BINS*sizeof(unsigned)) ;
	memset(state->lastHistogram, 0, HISTOGRAM_BINS*sizeof(unsigned)) ;

	state->min_uniform = 100000 ;
	state->max_uniform = 0 ;

	state->prev_screen_height = 0 ;
	state->prev_screen_width = 0 ;
}

//---------------------------------------------------------------------------------------------------------------------------
// Initialise the results
void frame_init_results(struct Ad_frame_results *results)
{
	results->black_frame = 0 ;
	results->scene_frame = 0 ;
	results->size_change = 0 ;
	results->screen_width = 0 ;
	results->screen_height = 0 ;
	results->brightness = 0 ;
	results->uniform = 0 ;
	results->dimCount = 0 ;
	results->sceneChangePercent = 0 ;
}

//---------------------------------------------------------------------------------------------------------------------------
// Initialise the totals
void frame_init_totals(struct Ad_frame_totals *totals)
{
	totals->num_black_frames = 0 ;
	totals->num_scene_frames = 0 ;
	totals->num_size_frames = 0 ;
}


//---------------------------------------------------------------------------------------------------------------------------
// Initialise the detector
void frame_detector_init(struct Ad_frame_settings *settings, struct Ad_frame_state *state)
{
	frame_init_settings(settings) ;
	frame_init_state(state) ;
}

//---------------------------------------------------------------------------------------------------------------------------
// Free up data created by the detector
void frame_detector_free(struct Ad_frame_state *state)
{

}


//---------------------------------------------------------------------------------------------------------------------------
// Run the detector
void frame_detector_run(struct TS_reader *tsreader, struct TS_pidinfo *pidinfo, struct TS_frame_info *frameinfo, const mpeg2_info_t *info,
		struct Ad_frame_settings *settings, struct Ad_frame_state *state, struct Ad_frame_results *results, struct Ad_frame_totals *totals)
{
unsigned framenum = frameinfo->framenum ;

	// clear down results
	frame_init_results(results) ;

	// get frame statistics
	calc_frame_state(
			frameinfo,
			info->sequence->width, info->sequence->height,
			info->sequence->chroma_width, info->sequence->chroma_height,
			info->display_fbuf->buf, framenum,
			settings,
			state,
			results,
			totals) ;
}


#ifdef FRAME_STANDALONE

//---------------------------------------------------------------------------------------------------------------------------
// TS parsing

// For stand-alone running

//---------------------------------------------------------------------------------------------------------------------------
void mpeg2_stats_hook(struct TS_pidinfo *pidinfo, struct TS_frame_info *frameinfo, const mpeg2_info_t *info, void *hook_data)
{
struct Ad_user_data *user_data = (struct Ad_user_data *)hook_data ;

//	// init
//	if (framenum == 0)
//	{
//		user_data->frame_state.brightness = 0 ;
//		user_data->frame_state.last_brightness = 0 ;
//		user_data->frame_state.prevsimilar = 0 ;
//		user_data->frame_state.prev_sceneChangePercent = 0 ;
//	}

	// set pid
	if (user_data->pid < 0)
	{
		user_data->pid = pidinfo->pid ;
		if (user_data->debug) fprintf(stderr, "Locked down TS parsing just to video PID = %d\n", pidinfo->pid) ;
	}

if (user_data->debug >= 4) fprintf(stderr, "mpeg2_stats_hook(frame=%06d)\n", framenum);

	// Update last frame number
	user_data->last_framenum = framenum ;

	// get frame statistics
	calc_frame_state(
			frameinfo,
			info->sequence->width, info->sequence->height,
			info->sequence->chroma_width, info->sequence->chroma_height,
			info->display_fbuf->buf, framenum,
			&user_data->frame_settings,
			&user_data->frame_state,
			&user_data->frame_results) ;

	{
	uint64_t rel_pts, rel_dts ;
	unsigned pts_frame, dts_frame ;
	unsigned pts_secs, dts_secs ;

	rel_pts = frameinfo->pesinfo.end_pts - frameinfo->pesinfo.start_pts ;
	pts_frame = (unsigned)(rel_pts * 25 / 90000) ;
	pts_secs = (unsigned)(rel_pts / 90000) ;

	rel_dts = frameinfo->pesinfo.dts - frameinfo->pesinfo.start_dts ;
	dts_frame = (unsigned)(rel_dts * 25 / 90000) ;
	dts_secs = (unsigned)(rel_dts / 90000) ;

	fprintf(stderr, "# PTS video frame %5d : pts=%"PRIu64" [%"PRIu64" .. %"PRIu64" ] frm=%u sec=%u\n",
			framenum,
			frameinfo->pesinfo.dts,
			frameinfo->pesinfo.start_dts, frameinfo->pesinfo.end_dts,
			dts_frame, dts_secs
			) ;
	}
}


//============================================================================================
enum DVB_error run_stats_check(struct Ad_user_data *user_data,
		char *filename, unsigned num_pkts, unsigned skip)
{
struct TS_reader *tsreader ;

	tsreader = tsreader_new(filename) ;
    if (!tsreader)
    {
		fprintf(stderr,"ERROR %s: %s\n",filename,dvb_error_str(dvb_error_code));
		return(ERR_FILE);
    }

    fprintf(stderr, "Total Num packets=%u\n", tsreader->tsstate->total_pkts) ;

    tsreader->num_pkts = num_pkts ;
    tsreader->skip = skip ;
    tsreader->debug = 0 ;
    tsreader->user_data = user_data ;
    user_data->tsreader = tsreader ;

	tsreader->pid_hook = pid_hook ;
	tsreader->mpeg2_hook = mpeg2_stats_hook ;

    // process file
    tsreader_setpos(tsreader, 0, SEEK_SET, num_pkts) ;
    ts_parse(tsreader) ;

	fprintf(stderr, "Last frame=%u\n", user_data->last_framenum) ;

    // end
    tsreader_free(tsreader) ;

    return (ERR_NONE) ;
}
#endif

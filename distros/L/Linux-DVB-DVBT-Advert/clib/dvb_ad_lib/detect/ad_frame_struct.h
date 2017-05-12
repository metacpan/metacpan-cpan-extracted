/*
 * Frame statistics (blank, scene change) etc.
 *
 */

#ifndef AD_FRAME_STRUCT_H_
#define AD_FRAME_STRUCT_H_

#include "ad_perl_struct.h"

// black frame detect
#define MAX_BLACK		0x30
#define WINDOW_PERCENT	95

// Settings defaults
#define HISTOGRAM_BINS		256


//-----------------------------------------------------------------------------------------------------------------------------------------
// This structure contains all of the settings for this detector
//
struct Ad_frame_settings {
	//-- settings --
	unsigned debug ;

	// maximum pixel value considered as a black frame
	unsigned max_black ;

	// percentage of picture to analyse
	unsigned window_percent ;

	unsigned max_brightness;				// frame not black if any pixels checked are greater than this (scale 0 to 255)
	unsigned test_brightness;				// frame not pure black if any pixels are greater than this, will check average

	unsigned brightness_jump;
	unsigned schange_cutlevel;
	unsigned schange_jump;

	unsigned noise_level;

	// Used for logo removal before attempting to detect frame info
	unsigned	remove_logo ;

	unsigned	logo_set ;
	unsigned	logo_y1 ;		// top left
	unsigned	logo_x1 ;
	unsigned	logo_y2 ;		// bottom right
	unsigned	logo_x2 ;

	struct Ad_perl_settings perl_set ;

} ;

//-----------------------------------------------------------------------------------------------------------------------------------------
// Frame stats

struct Ad_frame_state {
	unsigned 	brightness ;
	unsigned 	histogram[HISTOGRAM_BINS] ;
	unsigned 	max_diff ;
	unsigned 	max_bright ;
	unsigned 	uniform ;
	unsigned	hasBright;
	unsigned	dimCount;
	int			sceneChangePercent;

	unsigned 	last_brightness ;
	long 		prevsimilar ;
	unsigned 	lastHistogram[256] ;
	unsigned 	prev_sceneChangePercent ;

	unsigned 	min_uniform ;
	unsigned 	max_uniform ;

	unsigned	prev_screen_height ;
	unsigned	prev_screen_width ;

};


//-----------------------------------------------------------------------------------------------------------------------------------------
// Frame results

struct Ad_frame_results {
	unsigned	black_frame ;
	unsigned	scene_frame ;
	unsigned	size_change ;

	unsigned	screen_width ;
	unsigned	screen_height ;
	unsigned 	brightness ;
	unsigned 	uniform ;
	unsigned	dimCount;
	int			sceneChangePercent;
};

// Totals
struct Ad_frame_totals {
	unsigned	num_black_frames ;
	unsigned	num_scene_frames ;
	unsigned	num_size_frames ;
};


#endif

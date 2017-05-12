/*
 * Logo detect
 *
 */

#ifndef AD_LOGO_STRUCT_H_
#define AD_LOGO_STRUCT_H_

#include "ad_perl_struct.h"


#define MAX_LOGO_AVE		512

// edge detect values
#define LOGO_NONE_EDGE		0x00
#define LOGO_VERT_EDGE		0x01
#define LOGO_HORIZ_EDGE		0x02
#define LOGO_BOTH_EDGE		(LOGO_VERT_EDGE|LOGO_HORIZ_EDGE)


//-----------------------------------------------------------------------------------------------------------------------------------------
// This structure contains all of the settings for this detector
//
struct Ad_logo_settings {
	//-- settings --
	unsigned debug ;

	// percentage of picture to analyse
	unsigned window_percent ;


	// rolling "window" of time used for logo detection. Specified as a number of frames
	unsigned logo_window ;

	unsigned logo_edge_radius ;
	unsigned logo_edge_step ;
	unsigned logo_edge_threshold ;

	// max time to check for logo (in frames)
	unsigned logo_checking_period ;
	unsigned logo_skip_frames ;
	unsigned logo_num_checks ;
	unsigned logo_ok_percent ;
	unsigned logo_max_percentage_of_screen ;
	unsigned logo_ave_points ;

	// Perl settings
	struct Ad_perl_settings perl_set ;
	unsigned logo_rise_threshold;
	unsigned logo_fall_threshold;


} ;

//-----------------------------------------------------------------------------------------------------------------------------------------
// Logo detection
//

// logo frame buffer element
struct Ad_logo_buff {
	uint8_t		horiz ;
	uint8_t		vert ;
};

// TS parse data
//

// contains all the detection information that is frame size specific
struct Ad_screen_info {
	unsigned	width ;
	unsigned	height ;

	//-- local copy of settings
	struct Ad_logo_settings		settings ;

	//-- logo --
	unsigned dbl_check_count ;

	// checking window
	unsigned start_row ;
	unsigned sample_height ;
	unsigned start_col ;
	unsigned sample_width ;

	// Frame buffers storing rolling window of N frames
	unsigned	frames_totalled ;	// number of frames summed
	unsigned	frames_stored ;		// number of frames stored (when full this will be = circular buffer length)
	int			frame_index ;		// current frame buffer index in the circular buffer. Tracks the newest frame.
	unsigned	num_frames ;		// circular buffer length
	unsigned	buff_size ;
	uint8_t		**frame_buffer ;
	struct Ad_logo_buff *totals ;
	struct Ad_logo_buff *edge_detect ;

	// Rolling average
	unsigned	logo_ave_buff[MAX_LOGO_AVE] ;
	unsigned	logo_ave_total ;
	unsigned	logo_ave_num ;
	unsigned	logo_ave_index ;

	// Final logo mask
	unsigned	logo_found ;

	unsigned	logo_edges ;
	unsigned	logo_y1 ;		// top left
	unsigned	logo_x1 ;
	unsigned	logo_y2 ;		// bottom right
	unsigned	logo_x2 ;

	unsigned	logo_width ;	// pre-calc to speed things up
	unsigned	logo_height ;
	unsigned	logo_area ;

	struct Ad_logo_buff *logo ;

};

//-----------------------------------------------------------------------------------------------------------------------------------------
// Keep track of logo state
//-- logo state --
struct Ad_logo_state {

	//-- logo detection --
	unsigned logo_found ;	// set when logo found
	struct Ad_screen_info	*logo_screen ;	// when logo found, pointer set to the appropriate screen_info

	//-- Per frame size --
	unsigned screen_info_count ;
	struct Ad_screen_info	*screen_info ;	// array of screen_info's

} ;

//-----------------------------------------------------------------------------------------------------------------------------------------
// Logo results

struct Ad_logo_results {
	unsigned	logo_frame ;	// boolean

	unsigned 	match_percent ;
	unsigned 	ave_percent ;
};

// Totals
struct Ad_logo_totals {
	unsigned	num_logo_frames ;
};




#endif

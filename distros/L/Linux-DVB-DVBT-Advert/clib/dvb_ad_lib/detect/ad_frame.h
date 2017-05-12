/*
 * Frame statistics (blank, scene change) etc.
 *
 */

#ifndef AD_FRAME_H_
#define AD_FRAME_H_

#include "ts_parse.h"
#include "detect/ad_frame_struct.h"


//---------------------------------------------------------------------------------------------------------------------------
// Initialise logo area
void frame_set_logo_area(struct Ad_frame_settings *settings,
		unsigned	remove_logo,
		unsigned	logo_y1,		// top left
		unsigned	logo_x1,
		unsigned	logo_y2,		// bottom right
		unsigned	logo_x2) ;


//---------------------------------------------------------------------------------------------------------------------------
// Initialise the results
void frame_init_results(struct Ad_frame_results *results) ;

//---------------------------------------------------------------------------------------------------------------------------
// Initialise the totals
void frame_init_totals(struct Ad_frame_totals *totals) ;

//---------------------------------------------------------------------------------------------------------------------------
// Initialise the detector
void frame_detector_init(struct Ad_frame_settings *settings, struct Ad_frame_state *state) ;

//---------------------------------------------------------------------------------------------------------------------------
// Free up data created by the detector
void frame_detector_free(struct Ad_frame_state *state) ;


//---------------------------------------------------------------------------------------------------------------------------
// Run the detector
void frame_detector_run(struct TS_reader *tsreader, struct TS_pidinfo *pidinfo, struct TS_frame_info *frameinfo, const mpeg2_info_t *info,
		struct Ad_frame_settings *settings, struct Ad_frame_state *state, struct Ad_frame_results *results, struct Ad_frame_totals *totals) ;


#ifdef FRAME_STANDALONE
#include "ts_advert.h"

//---------------------------------------------------------------------------------------------------------------------------
// TS parsing

void mpeg2_stats_hook(struct TS_pidinfo *pidinfo, struct TS_frame_info *frameinfo, const mpeg2_info_t *info, void *hook_data) ;

enum DVB_error run_stats_check(struct Ad_user_data *user_data,
		char *filename, unsigned num_pkts, unsigned skip) ;
#endif

#endif

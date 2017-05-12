/*
 * Logo detect
 *
 */

#ifndef AD_LOGO_H_
#define AD_LOGO_H_

#include "ts_advert.h"
#include "detect/ad_logo_struct.h"


//---------------------------------------------------------------------------------------------------------------------------
// Logo data

//---------------------------------------------------------------------------------------------------------------------------
// Edge detect on an image buffer
uint8_t *image_edge_detect(uint8_t *image, unsigned height, unsigned width) ;

//---------------------------------------------------------------------------------------------------------------------------
// Initialise the results
void logo_init_results(struct Ad_logo_results *results) ;

//---------------------------------------------------------------------------------------------------------------------------
// Initialise the totals
void logo_init_totals(struct Ad_logo_totals *totals) ;

//---------------------------------------------------------------------------------------------------------------------------
// Initialise the detector
void logo_detector_init(struct Ad_logo_settings *settings, struct Ad_logo_state *state) ;

//---------------------------------------------------------------------------------------------------------------------------
// Free up data created by the detector
void logo_detector_free(struct Ad_logo_state *state) ;

//---------------------------------------------------------------------------------------------------------------------------
// Run the detector (preprocess data)
void logo_detector_preprocess(struct TS_reader *tsreader, struct TS_pidinfo *pidinfo, struct TS_frame_info *frameinfo, const mpeg2_info_t *info,
		struct Ad_logo_settings *settings, struct Ad_logo_state *state) ;

//---------------------------------------------------------------------------------------------------------------------------
// Run the detector
void logo_detector_run(struct TS_reader *tsreader, struct TS_pidinfo *pidinfo, struct TS_frame_info *frameinfo, const mpeg2_info_t *info,
		struct Ad_logo_settings *settings, struct Ad_logo_state *state, struct Ad_logo_results *results, struct Ad_logo_totals *totals) ;


#ifdef LOGO_STANDALONE
//---------------------------------------------------------------------------------------------------------------------------
// TS parsing


//---------------------------------------------------------------------------------------------------------------------------
void mpeg2_logofind_hook(struct TS_pidinfo *pidinfo, struct TS_pesinfo *pesinfo, struct TS_frame_info *frameinfo, const mpeg2_info_t *info, void *hook_data);
void mpeg2_logocheck_hook(struct TS_pidinfo *pidinfo, struct TS_pesinfo *pesinfo, struct TS_frame_info *frameinfo, const mpeg2_info_t *info, void *hook_data);

//============================================================================================
enum DVB_error run_logo_find(struct Ad_user_data *user_data,
		char *filename, unsigned num_pkts, unsigned skip);

enum DVB_error run_logo_check(struct Ad_user_data *user_data,
		char *filename, unsigned num_pkts, unsigned skip);
#endif

#endif

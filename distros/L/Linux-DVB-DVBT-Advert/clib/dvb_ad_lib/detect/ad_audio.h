/*
 * Logo detect
 *
 */

#ifndef AD_AUDIO_H_
#define AD_AUDIO_H_

#include "ts_parse.h"
#include "detect/ad_audio_struct.h"

//---------------------------------------------------------------------------------------------------------------------------
// Initialise the results
void audio_init_results(struct Ad_audio_results *results) ;

//---------------------------------------------------------------------------------------------------------------------------
// Initialise the totals
void audio_init_totals(struct Ad_audio_totals *totals) ;

//---------------------------------------------------------------------------------------------------------------------------
// Initialise the detector
void audio_detector_init(struct Ad_audio_settings *settings, struct Ad_audio_state *state) ;

//---------------------------------------------------------------------------------------------------------------------------
// Free up data created by the detector
void audio_detector_free(struct Ad_audio_state *state) ;

//---------------------------------------------------------------------------------------------------------------------------
// Run the detector
void audio_detector_run(struct TS_reader *tsreader, struct TS_pidinfo *pidinfo, struct TS_pesinfo *pesinfo, const mpeg2_audio_t *info,
		struct Ad_audio_settings *settings, struct Ad_audio_state *state, struct Ad_audio_results *results, struct Ad_audio_totals *totals) ;

#ifdef AUDIO_STANDALONE
#include "ts_advert.h"
//---------------------------------------------------------------------------------------------------------------------------
audio_hook_t *audio_hook(struct TS_pidinfo *pidinfo, struct TS_pesinfo *pesinfo, const mpeg2_audio_t *info, void *hook_data) ;

//============================================================================================
enum DVB_error run_audio_check(struct Ad_user_data *user_data,
		char *filename, unsigned num_pkts, unsigned skip);
#endif

#endif

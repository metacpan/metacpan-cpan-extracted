/*
 * Logo detect
 *
 */

#ifndef AD_AUDIO_STRUCT_H_
#define AD_AUDIO_STRUCT_H_

#include "ad_perl_struct.h"

// 16-bit results
#define MAX_VOL		0xffff

// 16-bit equates to this range
#define MIN_DB		-96

//---------------------------------------------------------------------------------------------------------------------------
// This structure contains all of the settings for this detector
//
struct Ad_audio_settings {
	//-- settings --
	unsigned debug ;

	// scale the results (e.g. set to 10 to get 1dp)
	unsigned scale ;

	// threshold below which audio is treated as silence (set in dB e.g. -26 for threshold = -26dB)
	int		silence_threshold ;

	struct Ad_perl_settings perl_set ;
	unsigned silence_window ;

} ;

//---------------------------------------------------------------------------------------------------------------------------
// Audio state
struct Ad_audio_state {

} ;

//---------------------------------------------------------------------------------------------------------------------------
// Audio results
struct Ad_audio_results {

	unsigned		audio_framenum ;
	int64_t			pts ;
	unsigned		volume ;
	unsigned		max_volume ;

	unsigned 		sample_rate	;
	unsigned 		channels ;
	unsigned 		samples_per_frame ;
	unsigned 		samples ;
	unsigned 		framesize ;

	int				volume_dB ;
	unsigned		silent_frame ;

} ;

// Totals
struct Ad_audio_totals {
	unsigned	num_silent_frames ;
};



#endif

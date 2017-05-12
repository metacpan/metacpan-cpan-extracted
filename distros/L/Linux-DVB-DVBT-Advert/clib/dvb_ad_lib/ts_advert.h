/*
 * ts_advert.h
 *
 *  Created on: 29 Apr 2010
 *      Author: sdprice1
 */

#ifndef TS_ADVERT_H_
#define TS_ADVERT_H_

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>


#include "list.h"
#include "dvb_error.h"
#include "ts_parse.h"


// Forward definitions
struct Ad_user_data ;


// register detectors
#include "detect/ad_logo_struct.h"
#include "detect/ad_frame_struct.h"
#include "detect/ad_audio_struct.h"
#include "detect/ad_perl_struct.h"

/*=============================================================================================*/
// CONSTANTS
/*=============================================================================================*/

enum Detection_method {
	METHOD_BLACK	= 0x0001,
	METHOD_LOGO		= 0x0002,
	METHOD_AUDIO	= 0x0004,
	METHOD_BANNER	= 0x0008
}  ;

#define METHOD_MIN		METHOD_BLACK
#define METHOD_ALL		(METHOD_BLACK + METHOD_LOGO + METHOD_AUDIO + METHOD_BANNER)
#define METHOD_DEFAULT	(METHOD_BLACK + METHOD_LOGO + METHOD_AUDIO)


/*=============================================================================================*/
// MACROS
/*=============================================================================================*/


/*=============================================================================================*/
// STRUCTURES
/*=============================================================================================*/


//----------------------------------------------------------------------------------------------
// Results array entry (all results, some entries may not be valid)
struct Ad_results {

	unsigned				start_pkt ;
	unsigned				end_pkt ;
	unsigned				gop_pkt ;

	int64_t					pts ;
	int64_t					fixed_pts ;
	unsigned				framenum ;
	unsigned				valid_frame ;		// set when video info has been written

	// set to the correct framenum at the end when we know what's valid
	unsigned				video_framenum ;

	//====================================================
	// Detector results
	struct Ad_frame_results	frame_results ;
	struct Ad_logo_results	logo_results ;
	struct Ad_audio_results	audio_results ;
};

// Results array list entry. List is created
// in post-process stage and is really is indexed by framenum
struct Ad_results_list_entry {

	// Pointer to actual results entry
	struct Ad_results	*results ;

	// Link to Ad_results - this is the index into results_array (used by the function that converts C struct to HV)
	int					idx ;

	// Generic pointer to data - Perl uses this for a HASH
	void 				*extra ;
};

enum Ad_state {
	ADVERT_PREPROCESS,
	ADVERT_PROCESS
};

// This structure contains all of the advert detection information & is passed to all callbacks
//
typedef struct Ad_user_data {
	//-- user settings --
	unsigned debug ;
	unsigned ts_debug ;

	// for debug
	unsigned start_pkt ;
	unsigned num_frames ;

	// Pid to use
	int	pid ;		// video
	int audio_pid ;	// Audio (if required)

	// how to detect
	unsigned detection_method ;

	enum Ad_state	process_state ;

	//-- Settings for detection methods --
	struct Ad_frame_settings	frame_settings ;
	struct Ad_logo_settings		logo_settings ;
	struct Ad_audio_settings	audio_settings ;

	// Perl settings
	struct Ad_perl_settings perl_set ;

	//====================================================
	// For use by Perl

	// callback
	void *progress_callback ;

	// Extra data
	void *extra_data ;


	//====================================================

	//-- global information  --
	unsigned last_framenum ;
	struct TS_reader *tsreader ;

	// PTS info for audio & video
	int64_t	first_video_pts ;
	int64_t	first_audio_pts ;

	unsigned first_video_pts_framenum ;

	unsigned prev_video_framenum ;
	int64_t	 prev_video_pts ;
	unsigned prev_audio_framenum ;
	int64_t	 prev_audio_pts ;

	// Set to true to abort run
	unsigned stop_processing ;

	// Indicates to individual algorithms that they are being run together
	unsigned multi_process ;


	//====================================================
	// Detector state
	struct Ad_frame_state	frame_state ;
	struct Ad_logo_state	logo_state ;
	struct Ad_audio_state	audio_state ;

	//====================================================
	// Detector results
	unsigned				results_array_size ;
	struct Ad_results		*results_array ;

	struct Ad_results_list_entry	*results_list ;
	unsigned						results_list_size ;

	struct Ad_frame_totals	frame_totals ;
	struct Ad_logo_totals	logo_totals ;
	struct Ad_audio_totals	audio_totals ;
} Adata ;



/*=============================================================================================*/
// GLOBAL FUNCTIONS
/*=============================================================================================*/

void dbg_print_settings(struct Ad_user_data *user_data);

//---------------------------------------------------------------------------------------------------------------------------
// Results
struct Ad_results *result_entry(struct Ad_user_data *user_data, unsigned framenum) ;
void free_results(struct Ad_user_data *user_data) ;
void free_results_list(struct Ad_user_data *user_data) ;


//---------------------------------------------------------------------------------------------------------------------------
// TS parsing
unsigned pid_hook(unsigned pid, void *hook_data) ;
void init_user_data(struct Ad_user_data *user_data) ;

enum DVB_error run_preprocess(struct Ad_user_data *user_data,
		char *filename, tsparse_progress_hook progress_hook) ;

enum DVB_error run_detect(struct Ad_user_data *user_data,
		char *filename, tsparse_progress_hook progress_hook) ;

#endif /* TS_ADVERT_H_ */

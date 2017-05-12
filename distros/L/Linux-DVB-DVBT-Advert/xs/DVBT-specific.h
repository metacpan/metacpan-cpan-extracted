#include "ts_advert.h"
#include "detect/ad_file.h"

/*---------------------------------------------------------------------------------------------------*/

// If large file support is not included, then make the value do nothing
#ifndef O_LARGEFILE
#define O_LARGEFILE	0
#endif


/*---------------------------------------------------------------------------------------------------*/

static int DVBT_AD_DEBUG = 0 ;



/*---------------------------------------------------------------------------------------------------*/
// MACROS for DVBT-advert

#define HVS_INT_SETTING(h, name, i, prefix)		HVS_INT(h, name, i)
#define HVS_INT_RESULT(h, name, i)				HVS_INT(h, name, i)


// Store result
#define HVS_FRAME_RESULT(h, NAME, IDX)		HVS_INT(h, NAME, user_data->results_array[IDX].frame_results.NAME)
#define HVS_LOGO_RESULT(h, NAME, IDX)		HVS_INT(h, NAME, user_data->results_array[IDX].logo_results.NAME)
#define HVS_AUDIO_RESULT(h, NAME, IDX)		HVS_INT(h, NAME, user_data->results_array[IDX].audio_results.NAME)
#define HVS_RESULT_START
#define HVS_RESULT_END



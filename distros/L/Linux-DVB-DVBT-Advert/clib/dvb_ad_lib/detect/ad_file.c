/*
 * ad_file.c
 *
 *  Created on: 18 Feb 2011
 *      Author: sdprice1
 */

#include "detect/ad_file.h"

//===========================================================================================================================
// CONSTANTS
//

#define MAXLINE			512
#define MAXITEM			128


//===========================================================================================================================
// MACROS
//

//---------------------------------------------------------------------------------------------------------------------------
// Set result
#define _SET_RESULT(HEAD, NAME)	\
	else if (strcmp(head, #HEAD) == 0)	\
	{									\
		results->NAME = val ;			\
	}

#define SET_RESULT(NAME)		_SET_RESULT(NAME, NAME)
#define SET_FRAME_RESULT(NAME)	_SET_RESULT(NAME, frame_results.NAME)
#define SET_LOGO_RESULT(NAME)	_SET_RESULT(NAME, logo_results.NAME)
#define SET_AUDIO_RESULT(NAME)	_SET_RESULT(NAME, audio_results.NAME)

//---------------------------------------------------------------------------------------------------------------------------
// Check result
#define _CHK_RESULT(HEAD, NAME)	\
	else if (strcmp(head, #HEAD) == 0)	\
	{									\
	}

#define CHK_RESULT(NAME)		_CHK_RESULT(NAME, NAME)
#define CHK_FRAME_RESULT(NAME)	_CHK_RESULT(NAME, frame_results.NAME)
#define CHK_LOGO_RESULT(NAME)	_CHK_RESULT(NAME, logo_results.NAME)
#define CHK_AUDIO_RESULT(NAME)	_CHK_RESULT(NAME, audio_results.NAME)

//---------------------------------------------------------------------------------------------------------------------------
// Set setting
#define _SET_SETTING(VAR, NAME)	\
	else if (strcmp(name, #VAR) == 0)	\
	{									\
		user_data->NAME = atoi(valstr) ;			\
	}

#define SET_SETTING(NAME)			_SET_SETTING(NAME, NAME)
#define SET_FRAME_SETTING(NAME)		_SET_SETTING(frame.NAME, frame_settings.NAME)
#define SET_LOGO_SETTING(NAME)		_SET_SETTING(logo.NAME, logo_settings.NAME)
#define SET_AUDIO_SETTING(NAME)		_SET_SETTING(audio.NAME, audio_settings.NAME)

#define SET_PERL_SETTING(NAME)			_SET_SETTING(NAME, perl_set.NAME)
#define SET_FRAME_PERL_SETTING(NAME)	_SET_SETTING(frame.NAME, frame_settings.perl_set.NAME)
#define SET_LOGO_PERL_SETTING(NAME)		_SET_SETTING(logo.NAME, logo_settings.perl_set.NAME)
#define SET_AUDIO_PERL_SETTING(NAME)	_SET_SETTING(audio.NAME, audio_settings.perl_set.NAME)

//---------------------------------------------------------------------------------------------------------------------------
// Check setting
#define _CHK_SETTING(VAR, NAME)	\
	else if (strcmp(name, #VAR) == 0)	\
	{									\
	}

#define CHK_SETTING(NAME)			_CHK_SETTING(NAME, NAME)

//===========================================================================================================================
// FUNCTIONS
//

//---------------------------------------------------------------------------------------------------------------------------
static void _save_result(struct Ad_results *results, char *head, int val)
{
	if (strcmp(head, "frame") == 0)
	{
		results->framenum = val ;
		results->valid_frame = 1 ;
	}

	SET_RESULT(start_pkt)
	SET_RESULT(end_pkt)
	SET_RESULT(gop_pkt)

	SET_FRAME_RESULT(black_frame)
	SET_FRAME_RESULT(scene_frame)
	SET_FRAME_RESULT(size_change)
	SET_FRAME_RESULT(screen_width)
	SET_FRAME_RESULT(screen_height)
	SET_FRAME_RESULT(brightness)
	SET_FRAME_RESULT(uniform)
	SET_FRAME_RESULT(dimCount)
	SET_FRAME_RESULT(sceneChangePercent)

	SET_LOGO_RESULT(logo_frame)
	SET_LOGO_RESULT(match_percent)
	SET_LOGO_RESULT(ave_percent)

	SET_AUDIO_RESULT(audio_framenum)
	SET_AUDIO_RESULT(volume)
	SET_AUDIO_RESULT(max_volume)
	SET_AUDIO_RESULT(sample_rate)
	SET_AUDIO_RESULT(channels)
	SET_AUDIO_RESULT(samples_per_frame)
	SET_AUDIO_RESULT(samples)
	SET_AUDIO_RESULT(framesize)
	SET_AUDIO_RESULT(volume_dB)
	SET_AUDIO_RESULT(silent_frame)

	// unused
	CHK_RESULT(frame_end)

	else
	{
		// UNKNOWN
	}
}


//---------------------------------------------------------------------------------------------------------------------------
static enum DVB_error _check_headings(char (*headings)[MAXLINE], unsigned num_head, unsigned linenum)
{
enum DVB_error error = ERR_NONE ;
unsigned i ;
char *head ;

	for (i=0; i < num_head; i++)
	{
		char *head = headings[i] ;

		if (strcmp(head, "frame") == 0)
		{
		}

		CHK_RESULT(start_pkt)
		CHK_RESULT(end_pkt)
		CHK_RESULT(gop_pkt)

		CHK_FRAME_RESULT(black_frame)
		CHK_FRAME_RESULT(scene_frame)
		CHK_FRAME_RESULT(size_change)
		CHK_FRAME_RESULT(screen_width)
		CHK_FRAME_RESULT(screen_height)
		CHK_FRAME_RESULT(brightness)
		CHK_FRAME_RESULT(uniform)
		CHK_FRAME_RESULT(dimCount)
		CHK_FRAME_RESULT(sceneChangePercent)

		CHK_LOGO_RESULT(logo_frame)
		CHK_LOGO_RESULT(match_percent)
		CHK_LOGO_RESULT(ave_percent)

		CHK_AUDIO_RESULT(audio_framenum)
		CHK_AUDIO_RESULT(volume)
		CHK_AUDIO_RESULT(max_volume)
		CHK_AUDIO_RESULT(sample_rate)
		CHK_AUDIO_RESULT(channels)
		CHK_AUDIO_RESULT(samples_per_frame)
		CHK_AUDIO_RESULT(samples)
		CHK_AUDIO_RESULT(framesize)
		CHK_AUDIO_RESULT(volume_dB)
		CHK_AUDIO_RESULT(silent_frame)

		// unused
		CHK_RESULT(frame_end)

		// error
		else
		{
		unsigned j ;

			// UNKNOWN - ignore
			fprintf(stderr, "Warning: Unknown heading \"%s\" at line %d. This column will be ignored\n", head, linenum) ;

//			for (j=0; j<strlen(head); j++)
//			{
//				fprintf(stderr, "%02x ", head[j]) ;
//				if (j+1 % 32 == 0)
//					fprintf(stderr, "\n") ;
//			}
//			fprintf(stderr, "\n") ;
		}
	}
	return error ;
}


//---------------------------------------------------------------------------------------------------------------------------
static void _save_setting(struct Ad_user_data *user_data, char *name, char *valstr, unsigned linenum)
{
	if (strcmp(name, "detection_method")==0)
	{
		user_data->detection_method = atoi(valstr) ;
	}

	// generic
	SET_SETTING(pid)
	SET_SETTING(audio_pid)

	SET_PERL_SETTING(max_advert)
	SET_PERL_SETTING(min_advert)
	SET_PERL_SETTING(min_program)
	SET_PERL_SETTING(start_pad)
	SET_PERL_SETTING(end_pad)
	SET_PERL_SETTING(min_frames)
	SET_PERL_SETTING(frame_window)
	SET_PERL_SETTING(max_gap)
	SET_PERL_SETTING(reduce_end)
	SET_PERL_SETTING(reduce_min_gap)

	// frame
	SET_FRAME_SETTING(max_black)
	SET_FRAME_SETTING(window_percent)
	SET_FRAME_SETTING(max_brightness)
	SET_FRAME_SETTING(test_brightness)
	SET_FRAME_SETTING(brightness_jump)
	SET_FRAME_SETTING(schange_cutlevel)
	SET_FRAME_SETTING(schange_jump)
	SET_FRAME_SETTING(noise_level)
	SET_FRAME_SETTING(remove_logo)

	SET_FRAME_PERL_SETTING(max_advert)
	SET_FRAME_PERL_SETTING(min_advert)
	SET_FRAME_PERL_SETTING(min_program)
	SET_FRAME_PERL_SETTING(start_pad)
	SET_FRAME_PERL_SETTING(end_pad)
	SET_FRAME_PERL_SETTING(min_frames)
	SET_FRAME_PERL_SETTING(frame_window)
	SET_FRAME_PERL_SETTING(max_gap)
	SET_FRAME_PERL_SETTING(reduce_end)
	SET_FRAME_PERL_SETTING(reduce_min_gap)

	// logo
	SET_LOGO_SETTING(window_percent)
	SET_LOGO_SETTING(logo_window)
	SET_LOGO_SETTING(logo_edge_radius)
	SET_LOGO_SETTING(logo_edge_step)
	SET_LOGO_SETTING(logo_edge_threshold)
	SET_LOGO_SETTING(logo_checking_period)
	SET_LOGO_SETTING(logo_skip_frames)
	SET_LOGO_SETTING(logo_num_checks)
	SET_LOGO_SETTING(logo_ok_percent)
	SET_LOGO_SETTING(logo_max_percentage_of_screen)
	SET_LOGO_SETTING(logo_ave_points)

	SET_LOGO_PERL_SETTING(max_advert)
	SET_LOGO_PERL_SETTING(min_advert)
	SET_LOGO_PERL_SETTING(min_program)
	SET_LOGO_PERL_SETTING(start_pad)
	SET_LOGO_PERL_SETTING(end_pad)
	SET_LOGO_PERL_SETTING(min_frames)
	SET_LOGO_PERL_SETTING(frame_window)
	SET_LOGO_PERL_SETTING(max_gap)
	SET_LOGO_PERL_SETTING(reduce_end)
	SET_LOGO_PERL_SETTING(reduce_min_gap)
	SET_LOGO_SETTING(logo_rise_threshold)
	SET_LOGO_SETTING(logo_fall_threshold)


	// audio
	SET_AUDIO_SETTING(scale)
	SET_AUDIO_SETTING(silence_threshold)

	SET_AUDIO_PERL_SETTING(max_advert)
	SET_AUDIO_PERL_SETTING(min_advert)
	SET_AUDIO_PERL_SETTING(min_program)
	SET_AUDIO_PERL_SETTING(start_pad)
	SET_AUDIO_PERL_SETTING(end_pad)
	SET_AUDIO_PERL_SETTING(min_frames)
	SET_AUDIO_PERL_SETTING(frame_window)
	SET_AUDIO_PERL_SETTING(max_gap)
	SET_AUDIO_PERL_SETTING(reduce_end)
	SET_AUDIO_PERL_SETTING(reduce_min_gap)
	SET_AUDIO_SETTING(silence_window)


	// unused
	CHK_SETTING(increase_min_gap)
	CHK_SETTING(increase_start)
	CHK_SETTING(num_frames)
	CHK_SETTING(total_black_frames)
	CHK_SETTING(total_logo_frames)
	CHK_SETTING(total_scene_frames)
	CHK_SETTING(total_size_frames)

	else
	{
		// ignore
		fprintf(stderr, "Warning: Unknown setting \"%s = %s\"  at line %d\n", name, valstr, linenum) ;
	}

}


//---------------------------------------------------------------------------------------------------------------------------
// Parse det file, which is of the form:
//
//	# audio.frame_window = 6000
//	# audio.max_advert = 6000
//	# audio.max_gap = 250
//	...
//	frame,audio_framenum,ave_percent,black_frame,brightness,channels,dimCount,end_pkt,frame_end,framesize,gop_pkt,logo_frame,match_percent,max_volume,sample_rate,samples,samples_per_frame,sceneChangePercent,scene_frame,screen_height,screen_width,silent_frame,size_change,start_pkt,uniform,volume,volume_dB
//	0,33,0,0,50,2,17,784,0,1152,513,0,65,359,48000,2304,2304,100,1,576,720,0,0,758,3096,150,-53
//	1,34,0,0,60,2,18,810,1,1152,513,0,30,322,48000,2304,2304,12,0,576,720,0,0,785,3153,65,-60
//	2,36,0,0,85,2,12,890,2,1152,513,1,100,1661,48000,2304,2304,25,0,576,720,0,0,811,3409,266,-48
//	3,38,0,0,84,2,12,915,3,1152,513,1,100,4440,48000,2304,2304,6,0,576,720,0,0,891,3394,769,-39
//	4,39,0,0,84,2,12,946,4,1152,513,1,100,4962,48000,2304,2304,5,0,576,720,0,0,916,3397,1013,-36
//	5,41,0,0,84,2,12,1084,5,1152,513,1,100,4444,48000,2304,2304,6,0,576,720,0,0,947,3410,1455,-33
//	...
//
enum DVB_error detect_from_file(struct Ad_user_data *user_data, char *filename)
{
enum DVB_error error = ERR_NONE ;
unsigned linenum=0;
FILE *file ;
char line[MAXLINE];
char varstr[MAXLINE];
char valstr[MAXLINE];
int val ;
unsigned got_head = 0 ;
char *item ;
char head[MAXITEM][MAXLINE] ;
unsigned num_head = 0 ;
unsigned item_num ;
struct Ad_results *results ;
unsigned framenum ;

	user_data->tsreader = NULL ;
	user_data->stop_processing = 0 ;
	user_data->multi_process = 1 ;

	file = fopen(filename,"r") ;
	if (!file)
	{
		return (ERR_FILE) ;
	}

	/* Read file line by line */
	while (fgets(line, MAXLINE, file) && (error == ERR_NONE))
	{
	unsigned len = strlen(line) ;

		++linenum ;

		if (user_data->debug) fprintf(stderr, "[f] <%s> [len=%d %02x %02x]\n", line, len, line[len-2], line[len-1]) ;

		if ((line[len - 1] == (char)0x0A) || (line[len - 1] == (char)0x0D))
		{
			line[--len] = '\0';
		}
		if ((line[len - 1] == (char)0x0A) || (line[len - 1] == (char)0x0D))
		{
			line[--len] = '\0';
		}

		if (got_head)
		{
			// skip comments
			if (line[0] != '#')
			{
				// should be data
				item = strtok(line, ",") ;
				if (item)
				{
					framenum = atoi(item) ;
					if (user_data->debug) fprintf(stderr, "[f] got data : frame %d\n", framenum) ;
					results = result_entry(user_data, framenum) ;

					// handle data...
					item_num = 0 ;
					while (item && (item_num < num_head) )
					{
						if (sscanf(item, "%d", &val)==1)
						{
							// save in user_data
							_save_result(results, head[item_num], val) ;
						}
						++item_num ;
						item = strtok(NULL, ",") ;
					}
				}
			}
		}
		else
		{
			// Not got to header line yet - see if this is a comment
			if (line[0] == '#')
			{
				if (sscanf(line, "# %s = %s", varstr, valstr) == 2)
				{
					// handle setting ...
					if (user_data->debug) fprintf(stderr, "[f] setting : %s = %s\n", varstr, valstr) ;
					_save_setting(user_data, varstr, valstr, linenum) ;
				}
			}
			else
			{
				// may be header line
				item = strtok(line, ",") ;
				if (item && strcmp(item, "frame")==0)
				{
					++got_head ;

					if (user_data->debug) fprintf(stderr, "[f] got header\n") ;

					// handle headings
					if (user_data->debug) fprintf(stderr, "[f] ") ;
					while (item)
					{
						strcpy(head[num_head++], item) ;
						if (user_data->debug) fprintf(stderr, "%s, ", item) ;
						item = strtok(NULL, ",") ;
					}
					if (user_data->debug) fprintf(stderr, "\n") ;

					// check headings
					error = _check_headings(head, num_head, linenum) ;
				}
			}
		}
	}

	/* Close file */
	fclose(file);

	if (user_data->debug) fprintf(stderr, "[f] post-process... \n") ;

	// Fix data
	post_process_results(user_data) ;

	if (user_data->debug) fprintf(stderr, "[f] done \n") ;

    return (error) ;
}

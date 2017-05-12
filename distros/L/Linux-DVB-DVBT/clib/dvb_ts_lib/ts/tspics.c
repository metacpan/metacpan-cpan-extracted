//#include <features.h>

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <ctype.h>
#include <fcntl.h>
#include <inttypes.h>
//#include <sys/time.h>
//#include <sys/types.h>

//#include "advert/ad_debug.h"
#include "ts_parse.h"

static unsigned debug=0 ;
static unsigned ts_debug=0 ;


struct Image_size {

	int height ;
	int width ;
	int size ;

	unsigned valid ;
};

struct Results {

	unsigned start_framenum ;
	unsigned num_frames ;

	// Number of frames actually grabbed
	unsigned num_grabbed_frames ;


	uint32_t **images ;
	struct Image_size *sizes ;
};

static struct Results *results = (struct Results *)0 ;


// This structure contains all of the information & is passed to all callbacks
//
struct Pics_user_data {
	//-- user settings --
	unsigned debug ;
	unsigned ts_debug ;

	// Pid to use
	int	pid ;		// video

	// Start offset
	unsigned start_framenum ;		// used for numbering the frames

	// Number of frames to grab
	unsigned num_frames ;

	// scaling used to subsample
	unsigned scale ;

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

	// current frame number
	unsigned current_framenum ;

};

//---------------------------------------------------------------------------------------------------------------------------
//PPM format:
//
//# A "magic number" for identifying the file type. A ppm image's magic number is the two characters "P6".
//# Whitespace (blanks, TABs, CRs, LFs).
//# A width, formatted as ASCII characters in decimal.
//# Whitespace.
//# A height, again in ASCII decimal.
//# Whitespace.
//# The maximum color value (Maxval), again in ASCII decimal. Must be less than 65536 and more than zero.
//# A single whitespace character (usually a newline).
//# A raster of Height rows, in order from top to bottom. Each row consists of Width pixels, in order from
//  left to right. Each pixel is a triplet of red, green, and blue samples, in that order. Each sample is
//  represented in pure binary by either 1 or 2 bytes. If the Maxval is less than 256, it is 1 byte.
//  Otherwise, it is 2 bytes. The most significant byte is first.
//
static void save_ppm (char *fmt, int width, int height, uint8_t * buf, int num)
{
    char filename[100];
    FILE * ppmfile;

    sprintf (filename, fmt, num);
fprintf(stderr, "Saving %s ...\n", filename);
    ppmfile = fopen (filename, "wb");
    if (!ppmfile) {
	fprintf (stderr, "Could not open file \"%s\".\n", filename);
	exit (1);
    }
    fprintf (ppmfile, "P6\n%d %d\n255\n", width, height);
    fwrite (buf, 3 * width, height, ppmfile);
    fclose (ppmfile);
}

//---------------------------------------------------------------------------------------------------------------------------
void dump_ppm(char *fmt, unsigned width, unsigned height, uint8_t *frame, unsigned framenum)
{
unsigned x, y ;
unsigned w, h ;
uint8_t *img, *pp, *fp ;

	w = width ;
	h = height ;
	img = (uint8_t *)malloc(3 * w * h * sizeof(uint8_t)) ;

	pp = img ;
	fp = frame ;
	for (y = 0; y < height; y ++)
	{
		for (x = 0; x < width; x ++)
		{
		unsigned pixel = *fp++ ;

			*pp++ = pixel ;
			*pp++ = pixel ;
			*pp++ = pixel ;
		}
	}

	save_ppm (fmt, w, h, img, framenum) ;
	free(img) ;
}

//---------------------------------------------------------------------------------------------------------------------------
void free_results()
{
	if (results)
	{
		if (results->images)
		{
			int i ;
			for (i=0; i<results->num_frames; ++i)
			{
				if (results->images[i]) free(results->images[i]) ;

			}
			if (results->sizes) free(results->sizes) ;
			free(results->images) ;
		}
		free(results) ;
	}
}


//---------------------------------------------------------------------------------------------------------------------------
void init_results(unsigned start_framenum, unsigned num_frames)
{
	free_results() ;

	results = (struct Results *)malloc(sizeof(struct Results)) ;
	CLEAR_MEM(results) ;

	results->start_framenum = start_framenum ;
	results->num_frames = num_frames ;
	results->num_grabbed_frames = 0 ;

	results->images = (uint32_t **)malloc(sizeof(uint32_t *) * num_frames) ;
	memset(results->images, 0, sizeof(uint32_t *) * num_frames) ;
	results->sizes = (struct Image_size *)malloc(sizeof(struct Image_size) * num_frames) ;
	memset(results->sizes, 0, sizeof(struct Image_size) * num_frames) ;
}

//---------------------------------------------------------------------------------------------------------------------------
static int _frame_index(unsigned framenum)
{
int index ;

	index = framenum - results->start_framenum ;
	if ((index >= 0) && (index < results->num_frames))
	{
		if (!results)
		{
			index = -2 ;
		}
	}
	else
	{
		index = -1 ;
	}

	return index ;
}

//---------------------------------------------------------------------------------------------------------------------------
static void cleanup_results()
{
unsigned index ;
unsigned height = 576 / 4 ;
unsigned width = 704 / 4 ;

	for (index=0; index < results->num_grabbed_frames; ++index)
	{
		if (!results->sizes[index].valid)
		{
			results->sizes[index].size = width * height ;
			results->sizes[index].height = height ;
			results->sizes[index].width = width ;
			results->images[index] = (uint32_t *)malloc(sizeof(uint32_t) * width * height) ;
			memset(results->images[index], 0, sizeof(uint32_t) * width * height) ;
		}
		else
		{
			height = results->sizes[index].height ;
			width = results->sizes[index].width ;
		}
	}

}

//---------------------------------------------------------------------------------------------------------------------------
static void add_image(unsigned width, unsigned height, uint8_t *frame, unsigned framenum, unsigned scale)
{
	int index = _frame_index(framenum);

	if (index >= 0)
	{
	unsigned x, y ;
	unsigned w, h ;
	uint8_t *fp ;
	uint32_t *pp ;

		w = width / scale ;
		h = height / scale ;

		results->sizes[index].valid = 1 ;
		results->sizes[index].size = w * h ;
		results->sizes[index].height = h ;
		results->sizes[index].width = w ;
		results->images[index] = (uint32_t *)malloc(sizeof(uint32_t) * w * h) ;

		pp = results->images[index] ;
		for (y = 0; y < height; y += scale)
		{
			fp = frame ;
			for (x = 0; x < width; x += scale)
			{
			unsigned pixel = *fp & 0xff ;

				fp += scale ;
				*pp++ = (0xff<<24) + (pixel<<16) + (pixel<<8) + (pixel) ;
			}

			frame += (scale * width) ;
		}

		if (index+1 > results->num_grabbed_frames)
			results->num_grabbed_frames = index+1 ;
	}
}


//---------------------------------------------------------------------------------------------------------------------------
// Initialise the user data
static void init_user_data(struct Pics_user_data *user_data)
{
	user_data->debug = 0 ;
	user_data->ts_debug = 0 ;

	user_data->pid = -1 ;
	user_data->start_framenum = 0 ;
	user_data->num_frames = 10 ;
	user_data->scale = 1 ;


	//////////////////////////////
	// Perl
	user_data->progress_callback = NULL ;
	user_data->extra_data = NULL ;

	//////////////////////////////
	// State
	user_data->tsreader = NULL ;
	user_data->last_framenum = 0 ;
	user_data->current_framenum = 0 ;
}

//---------------------------------------------------------------------------------------------------------------------------
// Only process the one pid when it's been set
static unsigned pid_hook(unsigned pid, void *hook_data)
{
struct Pics_user_data *user_data = (struct Pics_user_data *)hook_data ;

return 1 ;

	if (user_data->pid == -1)
	{
		return 1 ;
	}

	return pid == user_data->pid ;
}


//---------------------------------------------------------------------------------------------------------------------------
static void mpeg2_hook(struct TS_pidinfo *pidinfo, struct TS_frame_info *frameinfo, const mpeg2_info_t *info, void *hook_data)
{
struct Pics_user_data *user_data = (struct Pics_user_data *)hook_data ;
unsigned framenum = frameinfo->framenum ;

if (user_data->debug >= 2) printf("mpeg2_detect_hook() : PID = %d\n", pidinfo->pid) ;

	// set pid
	if (user_data->pid < 0)
	{
		user_data->pid = pidinfo->pid ;
		if (user_data->debug) printf("Locked down TS parsing just to video PID = %d\n", pidinfo->pid) ;
	}

	// Update last frame number
	if (user_data->last_framenum < framenum) user_data->last_framenum = framenum ;

//printf("Frame %d of %d\n", framenum, user_data->num_frames) ;
//{
//	off_t pos ;
//	printf(" ++ Frame %d, Packet %u..%u \n", framenum, frameinfo->pesinfo.start_pkt, frameinfo->pesinfo.end_pkt) ;
//	pos = lseek(user_data->tsreader->file, 0, SEEK_CUR) ;
//	printf(" ++ lseek pos now = %"PRId64"\n", (long long int)pos) ;
//}

	if (user_data->debug >= 10)
	{
		printf("rel frame %d : info=>{\n", framenum) ;
		printf(" width : %u\n", info->sequence->width) ;
		printf(" height : %u\n", info->sequence->height) ;
		printf(" chroma_width : %u\n", info->sequence->chroma_width) ;
		printf(" chroma_height : %u\n", info->sequence->chroma_height) ;
		printf(" byte_rate : %u\n", info->sequence->byte_rate) ;
		printf(" vbv_buffer_size : %u\n", info->sequence->vbv_buffer_size) ;
		printf(" flags : 0x%08x\n", info->sequence->width) ;

		printf(" picture_width : %u\n", info->sequence->picture_width) ;
		printf(" picture_height : %u\n", info->sequence->picture_height) ;
		printf(" display_width : %u\n", info->sequence->display_width) ;
		printf(" display_height : %u\n", info->sequence->display_height) ;
		printf(" pixel_width : %u\n", info->sequence->pixel_width) ;
		printf(" pixel_height : %u\n", info->sequence->pixel_height) ;
		printf(" frame_period : %u\n", info->sequence->frame_period) ;
		printf("}\n") ;
	}


	// Convert image data to PPM format and add to results
	add_image (
		info->sequence->width, info->sequence->height,
		info->display_fbuf->buf[0],
		framenum+user_data->start_framenum,
		user_data->scale) ;

	// stop if required
	if (framenum >= user_data->num_frames)
	{
		// stop now
		tsreader_stop(user_data->tsreader) ;
		return ;
	}
}

//============================================================================================
enum DVB_error run_detect(struct Pics_user_data *user_data,
		char *filename, unsigned skip)
{
struct TS_reader *tsreader ;

	tsreader = tsreader_new(filename) ;
    if (!tsreader)
    {
		fprintf(stderr,"ERROR %s: %s\n",filename,dvb_error_str(dvb_error_code));
		return(ERR_FILE);
    }
    tsreader->num_pkts = 0 ;
    tsreader->skip = skip ;
    tsreader->debug = user_data->ts_debug ;
    tsreader->user_data = user_data ;
    user_data->tsreader = tsreader ;

    if (user_data->debug)
    	printf("Total Num packets=%u\n", tsreader->tsstate->total_pkts) ;

	tsreader->pid_hook = pid_hook ;
	tsreader->mpeg2_hook = mpeg2_hook ;

    // process file
    tsreader_setpos(tsreader, skip, SEEK_SET, 0) ;
    ts_parse(tsreader) ;

    if (user_data->debug)
    	printf("Last frame=%u\n", user_data->last_framenum) ;

    // end
    tsreader_free(tsreader) ;

    return (ERR_NONE) ;
}


//============================================================================================
unsigned grab_pics(char *filename, unsigned start_pkt, unsigned start_framenum, unsigned num_frames, unsigned scale)
{
struct Pics_user_data user_data ;

	init_user_data(&user_data) ;
	user_data.start_framenum = start_framenum ;
	user_data.num_frames = num_frames ;
	user_data.scale = scale ;

	user_data.debug = debug ;
	user_data.ts_debug = ts_debug ;


	init_results(start_framenum, num_frames) ;

    if (user_data.debug)
    {
		printf("Input:  %s\n", filename) ;
		printf("Skipping %u packets, Saving %d frames\n", start_pkt, user_data.num_frames) ;
    }

    //-----------------------------------
	run_detect(&user_data, filename, start_pkt) ;

	//-----------------------------------
	// Ensure we have results for all frames
	cleanup_results() ;

	return results->num_grabbed_frames ;
}

void grab_debug(unsigned set_debug, unsigned set_ts_debug)
{
	debug=set_debug ;
	ts_debug=set_ts_debug ;
}

int grab_size(unsigned framenum)
{
int size = 0 ;

	int index = _frame_index(framenum);
	if (index >= 0)
	{
		size = results->sizes[index].size ;
	}
	return size ;
}

int grab_height(unsigned framenum)
{
int height = 0 ;

	int index = _frame_index(framenum);
	if (index >= 0)
	{
		height = results->sizes[index].height ;
	}
	return height ;
}

int grab_width(unsigned framenum)
{
int width = 0 ;

	int index = _frame_index(framenum);
	if (index >= 0)
	{
		width = results->sizes[index].width ;
	}
	return width ;
}

unsigned char *grab_image(unsigned framenum)
{
unsigned char *image = (unsigned char *)0 ;

	int index = _frame_index(framenum);
	if (index >= 0)
	{
		image = (unsigned char *)results->images[index] ;
	}
	return image ;
}

void grab_free()
{
	free_results() ;
}


//============================================================================================
#ifdef TEST_MAIN
int main(int argc, char *argv[])
{
int debug=0;
char *filename ;
unsigned skip=0 ;
off_t size, pos ;
int pid = -1 ;
int val ;
struct Pics_user_data user_data ;

int c;

	init_user_data(&user_data) ;

	opterr = 0;
    while ((c = getopt (argc, argv, "D:d:s:S:n:")) != -1)
    {
      switch (c)
      {
      case 'd':
    	  user_data.debug = atoi(optarg) ;
        break;

      case 'D':
		debug = atoi(optarg) ;
		break;

      case 's':
		skip = atoi(optarg) ;
		break;

      case 'n':
		user_data.num_frames = atoi(optarg) ;
		break;

      case 'S':
		user_data.start_framenum = atoi(optarg) ;
		break;



        default:
       	  printf("Error: invalid option %c\n", c) ;
          abort ();
        }
    }

    if (optind < argc)
    {
    	filename = argv[optind++] ;
    }
    else
    {
    	printf("Error: Must specify input filename\n") ;
    	abort() ;
    }

    printf("Input:  %s\n", filename) ;
	printf("Skipping %u packets, Saving %d frames\n", skip, user_data.num_frames) ;

    if (pid >= 0)
    {
    	user_data.pid = pid ;
    }

    //-----------------------------------
    run_detect(&user_data, filename, skip) ;

    //-----------------------------------
    // clear mem
//fprintf (stderr, "Free user_data...\n");
//    free_user_data(&user_data) ;

    //-----------------------------------
	fprintf (stderr, "END\n");

}
#endif

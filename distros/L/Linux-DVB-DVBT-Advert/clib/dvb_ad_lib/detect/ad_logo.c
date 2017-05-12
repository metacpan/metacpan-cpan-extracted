/*
 * Logo detection
 *
 */


// TODO: Look for spurious edges and prune them out (i.e. any edges that do not have M other edges close (within a radius of N) ?

//#define DUMP_EDGES
//#define DUMP_TOTALS
//#define DUMP_ALL_TOTALS
//#define DUMP_LOGO
//#define DUMP_LOGO_TEXT
//#define DUMP_LOGO_INFO



#include "ad_logo.h"
#include "ad_debug.h"

//===========================================================================================================================
// CONSTANTS
//===========================================================================================================================

// Logo default Perl settings
#define LOGO_max_advert			(3*60*FPS)
#define LOGO_min_advert			(3*60*FPS)
#define LOGO_min_program		(5*60*FPS)
#define LOGO_start_pad			(2*60*FPS)
#define LOGO_end_pad			(2*60*FPS)
#define LOGO_min_frames 	 	FPS
#define LOGO_frame_window 	 	20
#define LOGO_max_gap 		 	(10*FPS)
#define LOGO_reduce_end			0
#define LOGO_reduce_min_gap	 	(10*FPS)

// settings
#define MIN_EDGES			350
#define MAX_EDGES			40000
#define CHECK_PERCENT		90

// ignore any pixels brighter than this
#define MAX_BRIGHT			200

#define RISE_THRESHOLD		80
#define FALL_THRESHOLD		50

//===========================================================================================================================
// MACROS
//===========================================================================================================================


// print debug if debug setting is high enough
#define logo_dbg_prt(LVL, ARGS)	\
		if (screen_info->settings.debug >= LVL)	printf ARGS

//===========================================================================================================================
// FUNCTIONS
//===========================================================================================================================

//---------------------------------------------------------------------------------------------------------------------------
void dump_edge_ppm(char *fmt, struct Ad_logo_buff *edge, unsigned height, unsigned width, unsigned framenum, unsigned scale)
{
unsigned x, y ;
unsigned w, h ;
uint8_t *img, *pp ;

	w = width ;
	h = height ;
	img = (uint8_t *)malloc(3 * w * h * sizeof(uint8_t)) ;

	pp = img ;
	for (y = 0; y < height; y ++)
	{
		for (x = 0; x < width; x ++)
		{
		unsigned pixel = ((edge->horiz + edge->vert) * 255) / scale ;

			if (pixel > 255) pixel=255;

//			if ((edge->horiz + edge->vert) >= scale)
//			{
//				*pp++ = pixel ;
//				*pp++ = pixel ;
//				*pp++ = 0 ;
//			}
			if (edge->horiz  >= scale/2)
			{
				*pp++ = pixel ;
				*pp++ = pixel ;
				*pp++ = 0 ;
			}
			else if (edge->vert  >= scale/2)
			{
				*pp++ = pixel ;
				*pp++ = pixel ;
				*pp++ = 0 ;
			}
			else
			{
				*pp++ = pixel ;
				*pp++ = pixel ;
				*pp++ = pixel ;
			}
			++edge ;
		}
	}

	save_ppm (fmt, w, h, img, framenum) ;
	free(img) ;

}

//---------------------------------------------------------------------------------------------------------------------------
void dump_logo_ppm(struct Ad_screen_info *screen_info, unsigned framenum)
{
unsigned x, y ;
unsigned w, h ;
uint8_t *img, *pp ;

	w = screen_info->logo_x2 - screen_info->logo_x1 + 1 ;
	h = screen_info->logo_y2 - screen_info->logo_y1 + 1 ;
	img = (uint8_t *)malloc(3 * w * h * sizeof(uint8_t)) ;

	pp = img ;
	for (y = screen_info->logo_y1; y <= screen_info->logo_y2; y ++)
	{
		struct Ad_logo_buff *tp = &screen_info->totals[y * screen_info->width + screen_info->logo_x1] ;
		for (x = screen_info->logo_x1; x <= screen_info->logo_x2; x ++)
		{
			if (tp->horiz >= screen_info->num_frames)
			{
				if (tp->vert >= screen_info->num_frames)
				{
					*pp++ = 0xb0 ;
					*pp++ = 0xb0 ;
					*pp++ = 0xb0 ;
				}
				else
				{
					*pp++ = 0x90 ;
					*pp++ = 0x90 ;
					*pp++ = 0x90 ;
				}
			}
			else
			{
				if (tp->vert >= screen_info->num_frames)
				{
					*pp++ = 0x98 ;
					*pp++ = 0x98 ;
					*pp++ = 0x98 ;
				}
				else
				{
					*pp++ = 0 ;
					*pp++ = 0 ;
					*pp++ = 0 ;
				}
			}
			++tp ;
		}
	}

	save_ppm ("logo%04d.ppm", w, h, img, framenum) ;
	free(img) ;

}

//---------------------------------------------------------------------------------------------------------------------------
void dump_logo_text(struct Ad_screen_info *screen_info)
{
unsigned x, y ;

fprintf(stderr, "\n\n") ;

	for (y = screen_info->logo_y1; y <= screen_info->logo_y2; y ++)
	{
		struct Ad_logo_buff *logo = &screen_info->logo[y * screen_info->width + screen_info->logo_x1] ;
		fprintf(stderr, "%5d: ", y) ;
		for (x = screen_info->logo_x1; x <= screen_info->logo_x2; x++)
		{
			if (logo->horiz)
			{
				if (logo->vert)
				{
					fprintf(stderr, "-+") ;
				}
				else
				{
					fprintf(stderr, " |") ;
				}
			}
			else
			{
				if (logo->vert)
				{
					fprintf(stderr, "--") ;
				}
				else
				{
					fprintf(stderr, "  ") ;
				}
			}
			++logo ;
		}
		fprintf(stderr, "\n") ;
	}
	fprintf(stderr, "\n") ;

}

//---------------------------------------------------------------------------------------------------------------------------
void dump_logo_line(struct Ad_screen_info *screen_info, struct Ad_logo_buff *buff,
		unsigned min_x, unsigned max_x, unsigned y)
{
unsigned x ;
struct Ad_logo_buff *tp = &buff[y * screen_info->width + min_x] ;

	for (x = min_x; x <= max_x; x ++)
	{
		fprintf(stderr, "%02x-%02x ", tp->vert, tp->horiz) ;
		++tp ;
	}
	fprintf(stderr, " : ") ;
}

//---------------------------------------------------------------------------------------------------------------------------
void dump_logo_info(struct Ad_screen_info *screen_info,
		unsigned min_x, unsigned min_y, unsigned max_x, unsigned max_y)
{
unsigned y ;

fprintf(stderr, "LOGO: current frame \t edge detect \t totals\n") ;
	for (y = min_y; y <= max_y; y ++)
	{
//		dump_logo_line(screen_info, screen_info->frame_buffer[screen_info->frame_index], min_x, max_x, y) ;
		dump_logo_line(screen_info, screen_info->edge_detect, min_x, max_x, y) ;
		dump_logo_line(screen_info, screen_info->totals, min_x, max_x, y) ;
		fprintf(stderr, "\n") ;
	}
	fprintf(stderr, "\n") ;
}





//---------------------------------------------------------------------------------------------------------------------------
// Logo data

#if 0
//---------------------------------------------------------------------------------------------------------------------------
// free up the circular buffer
void logo_screen_free(struct Ad_logo_state *logo_state)
{
unsigned findex, i ;
struct Ad_screen_info *screen_info = NULL ;

	for (findex=0; findex < logo_state->screen_info_count && !screen_info; ++findex)
	{
		screen_info = &logo_state->screen_info[logo_state->screen_info_count-1] ;

		for (i=0; i < screen_info->num_frames; i++)
		{
			free(screen_info->frame_buffer[i]) ;
		}
		if (screen_info->num_frames)
		{
			screen_info->num_frames = 0 ;
			free(screen_info->frame_buffer) ;
		}
	}
}
#endif

//---------------------------------------------------------------------------------------------------------------------------
// free up the logo info
void logo_free(struct Ad_logo_state *logo_state)
{
unsigned findex, i ;
struct Ad_screen_info *screen_info = NULL ;

	// free up rest
	if (logo_state->screen_info_count)
	{
		for (findex=0; findex < logo_state->screen_info_count; ++findex)
		{
			screen_info = &logo_state->screen_info[findex] ;
			free(screen_info->totals) ;
			free(screen_info->edge_detect) ;
			free(screen_info->logo) ;

			// free up circular buffers
			if (screen_info->num_frames)
			{
			int i ;

				for (i=0; i < screen_info->num_frames; i++)
				{
					free(screen_info->frame_buffer[i]) ;
				}
				screen_info->num_frames = 0 ;
				free(screen_info->frame_buffer) ;
			}

		}
		logo_state->screen_info_count = 0 ;
		free(logo_state->screen_info) ;
		logo_state->screen_info = NULL ;
	}
}

//---------------------------------------------------------------------------------------------------------------------------
void logo_init(struct Ad_screen_info *screen_info)
{
unsigned i ;
unsigned num_bytes = screen_info->buff_size * sizeof(struct Ad_logo_buff) ;

	// set up fields
	screen_info->dbl_check_count = 0 ;

	screen_info->frames_totalled = 0 ;
	screen_info->frames_stored = 0 ;
	screen_info->frame_index = -1 ;

	memset(screen_info->edge_detect, 0, num_bytes) ;

	// buffering
	for (i=0; i < screen_info->num_frames; i++)
	{
		memset(screen_info->frame_buffer[i], 0, screen_info->buff_size * sizeof(uint8_t)) ;
	}

	// logo
	screen_info->logo_found = 0 ;

	screen_info->logo_edges = 0 ;
	screen_info->logo_y1 = 0 ;		// top left
	screen_info->logo_x1 = 0 ;
	screen_info->logo_y2 = 0 ;		// bottom right
	screen_info->logo_x2 = 0 ;

	screen_info->logo_width = 0 ;	// pre-calc to speed things up
	screen_info->logo_height = 0 ;
	screen_info->logo_area = 0 ;

	screen_info->logo_ave_total = 0 ;
	screen_info->logo_ave_num = 0 ;
	screen_info->logo_ave_index = 0 ;

	memset(screen_info->logo, 0, num_bytes) ;
}



//---------------------------------------------------------------------------------------------------------------------------
// given the current height x width, get (and if necessary create) a screen info record
struct Ad_screen_info *logo_screen_info(struct Ad_logo_settings *logo_settings, struct Ad_logo_state *logo_state, unsigned width, unsigned height)
{
unsigned findex, i ;
struct Ad_screen_info *screen_info = NULL ;

	for (findex=0; findex < logo_state->screen_info_count && !screen_info; ++findex)
	{
		if ( (logo_state->screen_info[findex].height == height) && (logo_state->screen_info[findex].width == width) )
		{
			screen_info = &logo_state->screen_info[findex] ;
		}
	}

	if (!screen_info)
	{
		unsigned num_bytes ;

		// add a new entry
		logo_state->screen_info = (struct Ad_screen_info *)realloc(logo_state->screen_info, ++logo_state->screen_info_count * sizeof(struct Ad_screen_info) ) ;

		// TODO : tidy up...
		if (!logo_state->screen_info) abort() ;

		screen_info = &logo_state->screen_info[logo_state->screen_info_count-1] ;

		// copy settings
		memcpy(&screen_info->settings, logo_settings, sizeof(screen_info->settings)) ;
		screen_info->num_frames = screen_info->settings.logo_window ;


		// set size
		screen_info->height = height ;
		screen_info->width = width ;
		screen_info->buff_size = height * width ;
		num_bytes = screen_info->buff_size * sizeof(struct Ad_logo_buff) ;

		screen_info->start_row = height * (100 - logo_settings->window_percent) / 200 ;
		screen_info->sample_height = height * logo_settings->window_percent / 100 ;
		screen_info->start_col = width * (100 - logo_settings->window_percent) / 200 ;
		screen_info->sample_width = width * logo_settings->window_percent / 100 ;


		// alloc
		screen_info->frame_buffer = (uint8_t **)malloc(screen_info->num_frames * sizeof(uint8_t *)) ;
//	screen_info->logo_pixels = (unsigned *)malloc(screen_info->buff_size * sizeof(unsigned)) ;
		screen_info->edge_detect = (struct Ad_logo_buff *)malloc(num_bytes) ;
		screen_info->logo = (struct Ad_logo_buff *)malloc(num_bytes) ;

		screen_info->totals = (struct Ad_logo_buff *)malloc(num_bytes) ;
		memset(screen_info->totals, 0, num_bytes) ;

		// buffering
		for (i=0; i < screen_info->num_frames; i++)
		{
			screen_info->frame_buffer[i] = (uint8_t *)malloc(screen_info->buff_size * sizeof(uint8_t)) ;
		}
//	memset(screen_info->logo_pixels, 0, screen_info->buff_size * sizeof(unsigned)) ;

		// init
		logo_init(screen_info) ;
	}

	return screen_info ;
}

//---------------------------------------------------------------------------------------------------------------------------
#define INC_TOTAL(fp, tp, name)		\
	if (fp->name) { \
		if (tp->name < screen_info->num_frames) \
			++tp->name ;\
	} else { \
		tp->name = 0;\
	}

#define DEC_TOTAL(fp, tp, name)		\
	if (fp->name) { \
		if (tp->name > 0) \
			--tp->name ;\
	} else { \
		tp->name = 0;\
	}


//static unsigned pixel_x, pixel_y ;


//---------------------------------------------------------------------------------------------------------------------------
// Add to circular buffer
unsigned logo_buffer_frame(struct Ad_screen_info *screen_info, uint8_t *frame, unsigned framenum)
{

	if (++screen_info->frame_index >= screen_info->num_frames)
	{
		screen_info->frame_index = 0 ;
	}

	if (screen_info->frames_stored < screen_info->num_frames)
	{
		// still filling circular buffer
		memcpy(screen_info->frame_buffer[screen_info->frame_index], frame, screen_info->buff_size * sizeof(uint8_t)) ;
		++screen_info->frames_stored ;
	}
	else
	{
		// overwrite
		memcpy(screen_info->frame_buffer[screen_info->frame_index], frame, screen_info->buff_size * sizeof(uint8_t)) ;
	}


}

//---------------------------------------------------------------------------------------------------------------------------
#define EDGE_HORIZ(FRAME,X,Y)  (abs(FRAME[(Y) * width + (X) - edge_radius]   - FRAME[this_pixel]  ) >= edge_level_threshold) || \
								(abs(FRAME[(Y) * width + (X) + edge_radius]   - FRAME[this_pixel]  ) >= edge_level_threshold)

#define EDGE_VERT(FRAME,X,Y)	(abs(FRAME[((Y) - edge_radius) * width + (X)] - FRAME[this_pixel]) >= edge_level_threshold) || \
								(abs(FRAME[((Y) + edge_radius) * width + (X)] - FRAME[this_pixel]) >= edge_level_threshold)


//---------------------------------------------------------------------------------------------------------------------------
// Edge detect & update totals
void edge_detect(struct Ad_screen_info *screen_info, uint8_t *frame)
{
unsigned x, y ;
//struct Ad_logo_buff *edge_frame = screen_info->edge_detect ;
struct Ad_logo_buff *totals = screen_info->totals ;

// for MACROs
unsigned width = screen_info->width ;

unsigned edge_radius = screen_info->settings.logo_edge_radius ;
unsigned edge_step = screen_info->settings.logo_edge_step ;
unsigned edge_level_threshold = screen_info->settings.logo_edge_threshold ;

unsigned start_row = screen_info->start_row ;
unsigned start_col = screen_info->start_col ;
unsigned sample_height = screen_info->sample_height ;
unsigned sample_width = screen_info->sample_width ;

//	// clear results
//	memset(edge_frame, 0, screen_info->buff_size * sizeof(struct Ad_logo_buff)) ;

	if (screen_info->frames_totalled < screen_info->num_frames)
	{
		// still filling circular buffer
		++screen_info->frames_totalled ;
	}

	// adjust sample size
	start_row += edge_radius ;
	sample_height -= 2*edge_radius ;
	start_col += edge_radius ;
	sample_width -= 2*edge_radius ;

	// edge detect
	for (x = start_col; x < sample_width; x += edge_step)
	{
		for (y = start_row; y < sample_height; y += edge_step)
		{
			unsigned this_pixel = y * screen_info->width + x ;

			if ((frame[y * screen_info->width + x - edge_radius] < MAX_BRIGHT) ||
				(frame[y * screen_info->width + x + edge_radius] < MAX_BRIGHT) )
			{
				if (EDGE_HORIZ(frame,x,y))
				{
					if (totals[this_pixel].horiz < screen_info->num_frames)
					{
						totals[this_pixel].horiz++ ;
					}
				}
				else
				{
					totals[this_pixel].horiz = 0;
				}
			}

			if ((frame[(y- edge_radius) * screen_info->width + x ] < MAX_BRIGHT) ||
				(frame[(y+ edge_radius) * screen_info->width + x ] < MAX_BRIGHT) )
			{
				if (EDGE_VERT(frame,x,y))
				{
					if (totals[this_pixel].vert < screen_info->num_frames)
					{
						totals[this_pixel].vert++ ;
					}
				}
				else
				{
					totals[this_pixel].vert = 0;
				}
			}
		}
	}

}


//---------------------------------------------------------------------------------------------------------------------------
// Edge detect on an image buffer
uint8_t *image_edge_detect(uint8_t *image, unsigned height, unsigned width)
{
unsigned x, y ;

uint8_t *totals ;

unsigned edge_radius = 2 ;
unsigned edge_step = 1 ;
unsigned edge_level_threshold = 5 ;

unsigned start_row = 10 ;
unsigned start_col = 10 ;
unsigned sample_height = height-20 ;
unsigned sample_width = width-20 ;

	// clear results
	totals = (uint8_t *)malloc(width * height * sizeof(uint8_t)) ;
	memset(totals, 0, width * height * sizeof(uint8_t)) ;

	// adjust sample size
	start_row += edge_radius ;
	sample_height -= 2*edge_radius ;
	start_col += edge_radius ;
	sample_width -= 2*edge_radius ;

	// edge detect
	for (x = start_col; x < sample_width; x += edge_step)
	{
		for (y = start_row; y < sample_height; y += edge_step)
		{
			unsigned this_pixel = y * width + x ;

			if ((image[y * width + x - edge_radius] < MAX_BRIGHT) ||
				(image[y * width + x + edge_radius] < MAX_BRIGHT) )
			{
				if (EDGE_HORIZ(image,x,y))
				{
					totals[this_pixel]++ ;
				}
			}

			if ((image[(y- edge_radius) * width + x ] < MAX_BRIGHT) ||
				(image[(y+ edge_radius) * width + x ] < MAX_BRIGHT) )
			{
				if (EDGE_VERT(image,x,y))
				{
					totals[this_pixel]++ ;
				}
			}
		}
	}

	return totals ;
}



//---------------------------------------------------------------------------------------------------------------------------
#define MAX_SEARCH 25

//ClearEdgeMaskArea(horiz_edgemask, vert_edgemask); temp=horiz, test=vert
//ClearEdgeMaskArea(vert_edgemask, horiz_edgemask);
//
// void ClearEdgeMaskArea(unsigned char* temp, unsigned char* test) {

enum Edge_type {
	EDGE_HORIZ,
	EDGE_VERT
};

unsigned _got_edge(struct Ad_screen_info *screen_info, unsigned xy, enum Edge_type type)
{
unsigned got = 0 ;

	if (type == EDGE_HORIZ)
	{
//		if (screen_info->totals[xy].horiz >= screen_info->num_frames)
		if (screen_info->logo[xy].horiz)
			++got ;
	}
	else
	{
//		if (screen_info->totals[xy].vert >= screen_info->num_frames)
		if (screen_info->logo[xy].vert)
			++got ;
	}

	return got ;
}

//---------------------------------------------------------------------------------------------------------------------------
void ClearEdgeMaskArea(struct Ad_screen_info *screen_info)
{
int x, y;
int count;
int offset;
int ix,iy;
enum Edge_type src_type, dest_type ;

int edge_step = 1 ;
int border = 10 ;
int	edge_weight = 10;

	for (src_type = EDGE_HORIZ, dest_type = EDGE_VERT; src_type <= EDGE_VERT; ++src_type, --dest_type)
	{
		for (y = border; y < screen_info->height - border; y++)
		{
			for (x = border; x < screen_info->width - border; x++)
			{
				unsigned this_xy = y * screen_info->width + x ;

				count = 0;

				// if source pixel has an edge...
				if (_got_edge(screen_info, this_xy, src_type))
				{
					// check this pixel
					if (_got_edge(screen_info, this_xy, dest_type))
						count++;

					//
					// offset = 1 .. MAX_SEARCH-1 (24)
					//
					// Look for edges around this pixel, start close in (1 away) and work outward
					//
					for (offset = edge_step; (offset < MAX_SEARCH) && !(count >= edge_weight); offset += edge_step)
					{
						//    ix    x
						//     v-----------v
						//
						//
						// y        *
						//
						// iy  +++++++++++++
						//
						// ix = -offset .. offset
						//
						iy = offset;
						for (ix= -offset; ix <= offset; ix += edge_step)
						{
							if (y+iy > 0 && y+iy<screen_info->height && x+ix > 0 && x+ix < screen_info->width &&
									_got_edge(screen_info, (y+iy) * screen_info->width + x+ix, dest_type)
									)
								count++;
						}

						//    ix    x
						//     v-----------v
						//
						// iy  +++++++++++++
						//
						//
						// y        *
						//
						//
						// ix = -offset .. offset
						//
						iy = -offset;
						for (ix= -offset; ix <= offset; ix += edge_step)
						{
							if (y+iy > 0 && y+iy<screen_info->height && x+ix > 0 && x+ix < screen_info->width &&
									_got_edge(screen_info, (y+iy) * screen_info->width + x+ix, dest_type)
									)
								count++;
						}

						//          x      ix
						// iy               +
						//                  +
						//                  +
						// y        *       +
						//                  +
						//                  +
						// iy               +
						//
						// iy = -offset .. offset
						//
						ix = offset;
						for (iy= -offset+edge_step; iy <= offset-edge_step; iy += edge_step)
						{
							if (y+iy > 0 && y+iy<screen_info->height && x+ix > 0 && x+ix < screen_info->width &&
									_got_edge(screen_info, (y+iy) * screen_info->width + x+ix, dest_type)
									)
								count++;
						}

						//          ix      x
						// iy        +
						//           +
						//           +
						// y         +      *
						//           +
						//           +
						// iy        +
						//
						// iy = -offset .. offset
						//
						ix = -offset;
						for (iy= -offset+edge_step; iy <= offset-edge_step; iy += edge_step)
						{
							if (y+iy > 0 && y+iy<screen_info->height && x+ix > 0 && x+ix < screen_info->width &&
									_got_edge(screen_info, (y+iy) * screen_info->width + x+ix, dest_type)
									)
								count++;
						}

					} // for offset

					// clear source pixel edge - keeps being cleared until we've found enough edges
					if (count < edge_weight)
					{
						if (src_type == EDGE_HORIZ)
						{
							screen_info->logo[this_xy].horiz = 0 ;
							--screen_info->logo_edges ;
							logo_dbg_prt(2, ("CLEAR: x %d y %d - horiz (count %d) : edges %d\n", x, y, count, screen_info->logo_edges)) ;
						}
						else
						{
							screen_info->logo[this_xy].vert = 0 ;
							--screen_info->logo_edges ;
							logo_dbg_prt(2, ("CLEAR: x %d y %d - vert (count %d) : edges %d\n", x, y, count, screen_info->logo_edges)) ;
						}
					}
				} // if temp
			} // for x
		} // for y
	}


}




//---------------------------------------------------------------------------------------------------------------------------
#define LOGOBORDER 4
void logo_area(struct Ad_screen_info *screen_info)
{
unsigned x, y ;
unsigned found=0 ;
unsigned edge_radius = screen_info->settings.logo_edge_radius ;
unsigned edge_step = screen_info->settings.logo_edge_step ;

	screen_info->logo_area = 0 ;
	screen_info->logo_x1 = screen_info->width - 1;
	screen_info->logo_y1 = screen_info->height - 1;
	screen_info->logo_x2 = 0;
	screen_info->logo_y2 = 0;

	for (y = screen_info->start_row; y < screen_info->sample_height; y += edge_step)
	{
		for (x = screen_info->start_col; x < screen_info->sample_width; x += edge_step)
		{
			struct Ad_logo_buff *logo = &screen_info->logo[y * screen_info->width + x] ;
			if (logo->horiz || logo->vert)
			{
				if (x - LOGOBORDER < screen_info->logo_x1) screen_info->logo_x1 = x - LOGOBORDER;
				if (y - LOGOBORDER < screen_info->logo_y1) screen_info->logo_y1 = y - LOGOBORDER;
				if (x + LOGOBORDER > screen_info->logo_x2) screen_info->logo_x2 = x + LOGOBORDER;
				if (y + LOGOBORDER > screen_info->logo_y2) screen_info->logo_y2 = y + LOGOBORDER;

				++found ;
			}
		}
	}

	if (screen_info->logo_x1 < edge_radius) screen_info->logo_x1 = edge_radius;
	if (screen_info->logo_x2 > (screen_info->width - edge_radius)) screen_info->logo_x2 = (screen_info->width - edge_radius);
	if (screen_info->logo_y1 < edge_radius) screen_info->logo_y1 = edge_radius;
	if (screen_info->logo_y2 > (screen_info->height - edge_radius)) screen_info->logo_y2 = (screen_info->height - edge_radius);


	if (found)
	{
		screen_info->logo_width = screen_info->logo_x2 - screen_info->logo_x1 ;
		screen_info->logo_height = screen_info->logo_y2 - screen_info->logo_y1 ;
		screen_info->logo_area = screen_info->logo_height * screen_info->logo_width ;
	}

	logo_dbg_prt(2, ("\nSet area [Area: %d,%d .. %d,%d] found=%d\n",
			screen_info->logo_x1,screen_info->logo_y1, screen_info->logo_x2,screen_info->logo_y2,
			found)) ;
}

//---------------------------------------------------------------------------------------------------------------------------
// Create the logo mask
unsigned logo_set(struct Ad_screen_info *screen_info)
{
unsigned x, y, xy ;
struct Ad_logo_buff *tp ;
struct Ad_logo_buff *logo ;
unsigned start_row = screen_info->start_row ;
unsigned start_col = screen_info->start_col ;
unsigned sample_height = screen_info->sample_height ;
unsigned sample_width = screen_info->sample_width ;


unsigned edges=0;

	// clear results
	memset(screen_info->logo, 0, screen_info->buff_size * sizeof(struct Ad_logo_buff)) ;

	for (y = start_row; y < sample_height; y ++)
	{
		xy = y * screen_info->width + start_col ;
		tp = &screen_info->totals[xy] ;
		logo = &screen_info->logo[xy] ;

		for (x = start_col; x < sample_width; x++, tp++, logo++)
		{
			if (tp->horiz >= screen_info->num_frames)
			{
				logo->horiz = 1 ;
			}
			if (tp->vert >= screen_info->num_frames)
			{
				logo->vert = 1 ;
			}
		}
	}
}


//---------------------------------------------------------------------------------------------------------------------------
// Test for logo
unsigned logo_test(struct Ad_screen_info *screen_info, uint8_t *frame)
{
unsigned x, y ;
unsigned matched_edges = 0 ;
unsigned edge_radius = screen_info->settings.logo_edge_radius ;
unsigned edge_level_threshold = screen_info->settings.logo_edge_threshold ;

// for MACROs
unsigned width = screen_info->width ;

	// edge detect
	for (x = screen_info->logo_x1; x <= screen_info->logo_x2; x++)
	{
		for (y = screen_info->logo_y1; y <= screen_info->logo_y2; y ++)
		{
			unsigned this_pixel = y * screen_info->width + x ;

			if (screen_info->logo[this_pixel].horiz)
			{
				if (EDGE_HORIZ(frame,x,y))
				{
					matched_edges++;
				}
			}

			if (screen_info->logo[this_pixel].vert)
			{
				if (EDGE_VERT(frame,x,y))
				{
					matched_edges++;
				}
			}
		}
	}

	return ((matched_edges * 100) + screen_info->logo_edges-1) / screen_info->logo_edges ;
}


//---------------------------------------------------------------------------------------------------------------------------
// Create rolling average of detection percentages
unsigned logo_ave(struct Ad_screen_info *screen_info, unsigned percent)
{
unsigned total ;

	screen_info->logo_ave_total += percent ;

	if (screen_info->logo_ave_num >= screen_info->settings.logo_ave_points)
	{
		// remove oldest first
		screen_info->logo_ave_total -= screen_info->logo_ave_buff[screen_info->logo_ave_index] ;
		total = screen_info->logo_ave_total ;
	}
	else
	{
		++screen_info->logo_ave_num ;

		// clamp at 0% until buffered all samples
		total = 0 ;
	}
	screen_info->logo_ave_buff[screen_info->logo_ave_index] = percent ;
	if (++screen_info->logo_ave_index >= screen_info->settings.logo_ave_points)
	{
		screen_info->logo_ave_index = 0 ;
	}

	return (total + screen_info->logo_ave_num-1) / screen_info->logo_ave_num ;
}

//--------------------------------------------------------------------------------------------------------------------------
// Count up the number of edges in the logo mask
// also sets logo_edges
unsigned CountEdgePixels(struct Ad_screen_info *screen_info)
{
unsigned x, y ;
unsigned edges = 0, hedges = 0, vedges = 0 ;

	for (x = screen_info->logo_x1; x <= screen_info->logo_x2; x++)
	{
		for (y = screen_info->logo_y1; y <= screen_info->logo_y2; y ++)
		{
			unsigned this_pixel = y * screen_info->width + x ;

			if (screen_info->logo[this_pixel].horiz)
			{
				++hedges ;
			}
			if (screen_info->logo[this_pixel].vert)
			{
				++vedges ;
			}
		}
	}

	edges = hedges + vedges ;
	screen_info->logo_edges = edges ;

	logo_dbg_prt(1, ("Edge count - %d (Horiz %d, Vert %d)\n", edges, hedges, vedges)) ;

	if ( (hedges < 50) || (vedges < 50))
	{
		edges = 0 ;
	}
	return (edges);
}

//--------------------------------------------------------------------------------------------------------------------------
static unsigned doublCheckLogoCount = 0 ;

unsigned logo_search(struct Ad_screen_info *screen_info)
{
unsigned logo_edges ;
unsigned logoPercentageOfScreen ;
unsigned logoInfoAvailable = 0 ;

	// create logo mask from totals
	logo_set(screen_info) ;

	// clean the mask
	ClearEdgeMaskArea(screen_info) ;

	// get area
	logo_area(screen_info) ;

	// check area
	logoPercentageOfScreen = screen_info->logo_area * 100 / screen_info->buff_size ;

	// check edge count
	logo_edges = CountEdgePixels(screen_info) ;

	// check current
	if (logo_edges > MIN_EDGES)
	{
		if (logo_edges > MAX_EDGES || logoPercentageOfScreen > screen_info->settings.logo_max_percentage_of_screen)
		{
			logo_dbg_prt(1, ("Edge count - %i\tPercentage of screen - %d%% TOO BIG, CAN'T BE A LOGO.\n",
					logo_edges, logoPercentageOfScreen)) ;

			logoInfoAvailable = 0;
		}
		else
		{
			logo_dbg_prt(1, ("Edge count - %i\tPercentage of screen - %.2f%% May be LOGO - double check count=%d.\n",
					logo_edges, logoPercentageOfScreen * 100.0, doublCheckLogoCount)) ;
			logoInfoAvailable = 1;
		}
	}

	// see if we've done double-checking
	if (logoInfoAvailable)
	{
		doublCheckLogoCount++;
		if (doublCheckLogoCount > screen_info->settings.logo_num_checks)
		{
			// Final check done, found
		}
		else
		{
			logoInfoAvailable = 0;
		}

	}
	else
	{
		// start again
		doublCheckLogoCount = 0;
	}

	// Check in buffers
	if (logoInfoAvailable)
	{
	unsigned findex ;
	unsigned num_good = 0 ;


		logo_dbg_prt(1, ("Double-checking frames for logo.\n")) ;
		for (findex = 0; findex < screen_info->frames_stored; findex++)
		{
			unsigned match_percent = logo_test(screen_info, screen_info->frame_buffer[findex]) ;

			logo_dbg_prt(1, ("Test %d - %d%%\n", findex, match_percent)) ;

			if (match_percent >= screen_info->settings.logo_ok_percent)
			{
				++num_good ;
			}
		}

		if (num_good * 100 >= CHECK_PERCENT * screen_info->frames_stored)
		{
			logoInfoAvailable = 1 ;
		}
		else
		{
			logoInfoAvailable = 0 ;
		}
	}

	return (logoInfoAvailable) ;
}



//---------------------------------------------------------------------------------------------------------------------------
// Initialise the user data
void logo_init_settings(struct Ad_logo_settings *settings)
{
	settings->debug = 0 ;
	settings->logo_window = 50 ;
	settings->logo_edge_radius = 2 ;
	settings->logo_edge_step = 1 ;
	settings->logo_edge_threshold = 5 ;
	settings->logo_checking_period = 20 * 60 * 25 ;
	settings->logo_skip_frames = 25 ;
	settings->logo_num_checks = 5 ;
	settings->logo_ok_percent = 80 ;
	settings->logo_max_percentage_of_screen = 10 ;
	settings->logo_ave_points = 250 ;

	settings->window_percent = WINDOW_PERCENT;

	// Perl settings
	settings->logo_rise_threshold = RISE_THRESHOLD;
	settings->logo_fall_threshold = FALL_THRESHOLD;

	// set_perl_settings(settings, mx_ad, mn_ad, mn_pr, s_pd, e_pd, mn_fr, fr_wn, mx_gp, r_en, r_mn_gp)
	set_perl_settings(settings,
		LOGO_max_advert,
		LOGO_min_advert,
		LOGO_min_program,
		LOGO_start_pad,
		LOGO_end_pad,
		LOGO_min_frames,
		LOGO_frame_window,
		LOGO_max_gap,
		LOGO_reduce_end,
		LOGO_reduce_min_gap
	) ;

}

//---------------------------------------------------------------------------------------------------------------------------
// Initialise the state data
void logo_init_state(struct Ad_logo_state *state)
{
	//-- Per frame size --
	state->screen_info_count = 0 ;
	state->screen_info = NULL ;

	state->logo_found = 0 ;
	state->logo_screen = NULL ;
}

//---------------------------------------------------------------------------------------------------------------------------
// Initialise the detector
void logo_detector_init(struct Ad_logo_settings *settings, struct Ad_logo_state *state)
{
	logo_init_settings(settings) ;
	logo_init_state(state) ;
}

//---------------------------------------------------------------------------------------------------------------------------
// Free up data created by the detector
void logo_detector_free(struct Ad_logo_state *state)
{
	logo_free(state);
}

//---------------------------------------------------------------------------------------------------------------------------
// Initialise the results
void logo_init_results(struct Ad_logo_results *results)
{
	results->logo_frame = 0 ;
	results->match_percent = 0 ;
	results->ave_percent = 0 ;
}

//---------------------------------------------------------------------------------------------------------------------------
// Initialise the totals
void logo_init_totals(struct Ad_logo_totals *totals)
{
	totals->num_logo_frames = 0 ;
}


//---------------------------------------------------------------------------------------------------------------------------
// Run the detector (preprocess data)
void logo_detector_preprocess(struct TS_reader *tsreader, struct TS_pidinfo *pidinfo, struct TS_frame_info *frameinfo, const mpeg2_info_t *info,
		struct Ad_logo_settings *settings, struct Ad_logo_state *state)
{
struct Ad_screen_info *screen_info ;
unsigned framenum = frameinfo->framenum ;

	//== find logo ==

	// Get screen info for this screen size
	screen_info = logo_screen_info(settings, state, info->sequence->width, info->sequence->height) ;


	// only add every Xth frame
	if (framenum % settings->logo_skip_frames != 1) return ;


	logo_dbg_prt(1, ("screen : w %d x h %d\n", screen_info->width, screen_info->height)) ;
	logo_dbg_prt(1, ("FRAME %5d: %d x %d [%d x %d]] ",
			framenum, info->sequence->width, info->sequence->height,
			info->sequence->width, info->sequence->height)) ;

	// add to buffer
	logo_buffer_frame(screen_info, info->display_fbuf->buf[0], framenum) ;

	// edge detect
	edge_detect(screen_info, info->display_fbuf->buf[0]) ;


	// check for search abandon
	if (framenum >= settings->logo_checking_period)
	{
		logo_dbg_prt(1, ("+*+*+ Aborted +*+*+ \n")) ;

		// stop now
		tsreader_stop(tsreader) ;
		return ;
	}


	// Ok to check yet?
	if (screen_info->frames_totalled >= screen_info->num_frames)
	{

		// Sets horiz/vert_edgemask[]
		// Sets logo area
		// checks edge count & area
		// runs matches on buffered frames using current logo
		if(!logo_search(screen_info))
		{
			// logo not found - restart
			logo_dbg_prt(1, ("LOGO not found - restarting...\n")) ;
			logo_init(screen_info) ;
		}
		else
		{
			// STOP
			screen_info->logo_found = 1 ;
			state->logo_found = 1 ;
			state->logo_screen = screen_info ;

			logo_dbg_prt(1, ("+*+*+ Finished +*+*+ \n")) ;

			if (screen_info->settings.debug) dump_logo_text(screen_info) ;
			tsreader_stop(tsreader) ;
		}
	}

}


//---------------------------------------------------------------------------------------------------------------------------
// Run the detector
void logo_detector_run(struct TS_reader *tsreader, struct TS_pidinfo *pidinfo, struct TS_frame_info *frameinfo, const mpeg2_info_t *info,
		struct Ad_logo_settings *settings, struct Ad_logo_state *state, struct Ad_logo_results *results, struct Ad_logo_totals *totals)
{
struct Ad_screen_info *screen_info ;
struct Ad_logo_buff *edge_frame ;
unsigned framenum = frameinfo->framenum ;

unsigned match_percent ;
unsigned ave_percent=0 ;

float time = (float)framenum / 25.0 ;


	// clear down results
	logo_init_results(results) ;

	// Get screen info for this screen size
	screen_info = logo_screen_info(settings, state, info->sequence->width, info->sequence->height) ;

	// skip if not same as logo screen size
	if (screen_info != state->logo_screen) return ;

	// Check for logo match
	match_percent = logo_test(screen_info, info->display_fbuf->buf[0]) ;
	ave_percent = logo_ave(screen_info, match_percent) ;

	// Results
	results->match_percent = match_percent ;
	results->ave_percent = ave_percent ;

	if (match_percent >= settings->logo_ok_percent)
	{
		results->logo_frame = 1 ;
		++totals->num_logo_frames ;

		logo_dbg_prt(1, ("Logo frame %06d [%8.3f s] %d%% <%d%%> : pkt %u [ %u ..  %u]\n",
				framenum, time,
				match_percent,
				ave_percent,
				pidinfo->pktnum,
				frameinfo->pesinfo.start_pkt, frameinfo->pesinfo.end_pkt)) ;
	}
	else
	{
		logo_dbg_prt(1, (" --  frame %06d [%8.3f s] %d%% <%d%%> : pkt %u [ %u ..  %u]\n",
				framenum, time,
				match_percent,
				ave_percent,
				pidinfo->pktnum,
				frameinfo->pesinfo.start_pkt, frameinfo->pesinfo.end_pkt)) ;
	}
}


#ifdef LOGO_STANDALONE

//---------------------------------------------------------------------------------------------------------------------------
// TS parsing

//debug
static char fname[256] ;
static int totals_count=1;
static int totals_pass=1;


//---------------------------------------------------------------------------------------------------------------------------
void mpeg2_logofind_hook(struct TS_pidinfo *pidinfo, struct TS_frame_info *frameinfo, const mpeg2_info_t *info, void *hook_data)
{
struct Ad_user_data *user_data = (struct Ad_user_data *)hook_data ;
struct Ad_screen_info *screen_info ;

	// set pid
	if (user_data->pid < 0)
	{
		user_data->pid = pidinfo->pid ;
		if (user_data->debug) fprintf(stderr, "Locked down TS parsing just to video PID = %d\n", pidinfo->pid) ;
	}

	// Update last frame number
	user_data->last_framenum = framenum ;

	// check for search abandon
	if (framenum >= user_data->logo_settings.logo_checking_period)
	{
		// stop now
		if (user_data->multi_process)
		{
			// indicate to upper-level to stop
			user_data->stop_processing = 1 ;
		}
		else
		{
			tsreader_stop(user_data->tsreader) ;
		}
		return ;
	}



	// Get screen info for this screen size
	screen_info = logo_screen_info(&user_data->logo_settings, &user_data->logo_state, info->sequence->width, info->sequence->height) ;


	// only add every Xth frame
	if (framenum % user_data->logo_settings.logo_skip_frames != 1) return ;


fprintf(stderr, "screen : w %d x h %d\n", screen_info->width, screen_info->height) ;

if (user_data->debug) fprintf(stderr, "FRAME %5d: %d x %d [%d x %d]] ",
		framenum, info->sequence->width, info->sequence->height,
		info->sequence->width, info->sequence->height) ;

if (user_data->debug) fprintf(stderr, " - stored %d totalled %d ",
		screen_info->frames_stored, screen_info->frames_totalled) ;
if (user_data->debug >= 2) fprintf(stderr, "\n") ;


	// add to buffer
	logo_buffer_frame(screen_info, info->display_fbuf->buf[0], framenum) ;

	// edge detect
	edge_detect(screen_info, info->display_fbuf->buf[0]) ;

#ifdef DUMP_ALL_TOTALS
		sprintf(fname, "p%d-totals-%%d.ppm", totals_pass) ;
		dump_edge_ppm(fname, screen_info->totals,
				screen_info->height, screen_info->width, totals_count, 2*screen_info->frames_stored) ;
		totals_count++ ;
#endif

	// Ok to check yet?
	if (screen_info->frames_totalled >= screen_info->num_frames)
	{

		// Sets horiz/vert_edgemask[]
		// Sets logo area
		// checks edge count & area
		// runs matches on buffered frames using current logo
		if(!logo_search(screen_info))
		{
			// logo not found - restart
			fprintf(stderr, "LOGO not found - restarting...\n") ;
			logo_init(screen_info) ;

			totals_count=1 ;
			++totals_pass ;
		}
		else
		{
			// STOP
			screen_info->logo_found = 1 ;
			user_data->logo_state.logo_found = 1 ;
			user_data->logo_state.logo_screen = screen_info ;

			fprintf(stderr, "+*+*+ Finished +*+*+ \n") ;
			dump_logo_text(screen_info) ;
			tsreader_stop(user_data->tsreader) ;
		}
	}
}

//---------------------------------------------------------------------------------------------------------------------------
void mpeg2_logocheck_hook(struct TS_pidinfo *pidinfo, struct TS_frame_info *frameinfo, const mpeg2_info_t *info, void *hook_data)
{
struct Ad_user_data *user_data = (struct Ad_user_data *)hook_data ;
float time = (float)framenum / 25.0 ;
struct Ad_screen_info *screen_info ;
struct Ad_logo_buff *edge_frame ;

unsigned match_percent ;
unsigned ave_percent=0 ;

	// Get screen info for this screen size
	screen_info = logo_screen_info(&user_data->logo_settings, &user_data->logo_state, info->sequence->width, info->sequence->height) ;

	// skip if not same as logo screen size
	if (screen_info != user_data->logo_state.logo_screen) return ;

	// Check for logo match
	match_percent = logo_test(screen_info, info->display_fbuf->buf[0]) ;
//	enhanced_match_percent = logo_enhance_test(screen_info, info->display_fbuf->buf[0]) ;
	ave_percent = logo_ave(screen_info, match_percent) ;
//	if ( (match_percent >= screen_info->logo_ok_percent) || (enhanced_match_percent >= screen_info->logo_ok_percent) )
	if (match_percent >= screen_info->settings.logo_ok_percent)
	{
		fprintf(stderr, "Logo frame %06d [%8.3f s] %d%% <%d%%> : pkt %u [ %u ..  %u]\n",
				framenum, time,
				match_percent,
				ave_percent,
				pidinfo->pktnum,
				frameinfo->pesinfo.start_pkt, frameinfo->pesinfo.end_pkt);
	}
	else
	{
		fprintf(stderr, " --  frame %06d [%8.3f s] %d%% <%d%%> : pkt %u [ %u ..  %u]\n",
				framenum, time,
				match_percent,
				ave_percent,
				pidinfo->pktnum,
				frameinfo->pesinfo.start_pkt, frameinfo->pesinfo.end_pkt);
	}
}


//============================================================================================
enum DVB_error run_logo_find(struct Ad_user_data *user_data,
		char *filename, unsigned num_pkts, unsigned skip)
{
struct TS_reader *tsreader ;

	tsreader = tsreader_new(filename) ;
    if (!tsreader)
    {
		fprintf(stderr,"ERROR %s: %s\n",filename,dvb_error_str(dvb_error_code));
		return(ERR_FILE);
    }
	fprintf(stderr, "Total Num packets=%u\n", tsreader->tsstate->total_pkts) ;

    tsreader->num_pkts = num_pkts ;
    tsreader->skip = skip ;
    tsreader->debug = 0 ;
    tsreader->user_data = user_data ;
    user_data->tsreader = tsreader ;

	tsreader->pid_hook = pid_hook ;
	tsreader->mpeg2_hook = mpeg2_logofind_hook ;


    // process file
    tsreader_setpos(tsreader, 0, SEEK_SET, num_pkts) ;
    ts_parse(tsreader) ;

	fprintf(stderr, "Last frame=%u\n", user_data->last_framenum) ;

    // end
    tsreader_free(tsreader) ;

    return (ERR_NONE) ;
}


//============================================================================================
enum DVB_error run_logo_check(struct Ad_user_data *user_data,
		char *filename, unsigned num_pkts, unsigned skip)
{
struct TS_reader *tsreader ;

	tsreader = tsreader_new(filename) ;
    if (!tsreader)
    {
		fprintf(stderr,"ERROR %s: %s\n",filename,dvb_error_str(dvb_error_code));
		return(ERR_FILE);
    }
	fprintf(stderr, "Total Num packets=%u\n", tsreader->tsstate->total_pkts) ;

    tsreader->num_pkts = num_pkts ;
    tsreader->skip = skip ;
    tsreader->debug = 0 ;
    tsreader->user_data = user_data ;
    user_data->tsreader = tsreader ;

	tsreader->pid_hook = pid_hook ;
	tsreader->mpeg2_hook = mpeg2_logocheck_hook ;


    // process file
    tsreader_setpos(tsreader, 0, SEEK_SET, num_pkts) ;
    ts_parse(tsreader) ;

	fprintf(stderr, "Last frame=%u\n", user_data->last_framenum) ;

    // end
    tsreader_free(tsreader) ;

    return (ERR_NONE) ;
}

#endif

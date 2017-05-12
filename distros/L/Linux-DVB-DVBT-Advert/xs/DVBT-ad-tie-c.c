// VERSION = "1.003"
//
// There are 2 types of tied arrays supported: ADATA and FILTERED
//
// ADATA is basically a link to the results list after running detection. It manages the user_data
// structure and frees it up when finished. This must be available for the lifetime of the analysis.
//
// FILTERED is a filtered view of all the results - i.e. is those entries where a particular parameter
// is >= a threshold. This list contains just the frame number to point at the results list (in ADATA)
// along with some extra info like frame_end and gap. These arrays are created and destroyed at will
//
//


// Standard C code loaded outside XS space. Implements tied HASH connected to advert detect data
#include "ts_advert.h"
#include "ts_cut.h"
#include "ts_split.h"


//========================================================================================================
// CONSTANTS
//========================================================================================================

#define XSCLASS 	"Linux::DVB::DVBT::Advert"
#define MAXKEY		256

//#define DBG_ADAV
//#define DBG_ADAV_DEV	stdout
#define DBG_ADAV_DEV	stderr

//========================================================================================================
// TYPES
//========================================================================================================

//---------------------------------------------------------------------------------------------------------
enum Adav_type {ADAV_NULL=0, ADAV_ADATA, ADAV_FILTERED, ADAV_LOGO, ADAV_CSV} ;
enum Adav_sig {
	ADA_SIGNATURE 		= 0x41444824,
	ADA_FREE_SIGNATURE 	= 0xDEADC0DE
} ;

static char *adav_types[8] = {
		[0 ... 7]		= "UNKNOWN",
		[ADAV_NULL]		= "ADAV_NULL",
		[ADAV_ADATA]	= "ADAV_ADATA",
		[ADAV_FILTERED]	= "ADAV_FILTERED",
		[ADAV_LOGO]		= "ADAV_LOGO",
		[ADAV_CSV]		= "ADAV_CSV",
} ;

//---------------------------------------------------------------------------------------------------------
struct adav_element {
	unsigned	frame ;
	unsigned	frame_end ;
	int			gap ;

} ;

//---------------------------------------------------------------------------------------------------------
struct adav_logo_element {
	unsigned	frame ;
	unsigned	frame_end ;
	int			gap ;

	// these values over ride the real results
	unsigned 	match_percent ;
	unsigned 	ave_percent ;
} ;

//---------------------------------------------------------------------------------------------------------
struct adav_csv_element {
	unsigned	frame ;
//	unsigned	frame_end ;
	HV			*hv ;
} ;


//---------------------------------------------------------------------------------------------------------
struct adav_filter {
	char					key[MAXKEY] ;
	struct adav_element		*data ;
	unsigned 				num_elems ;
} ;

//---------------------------------------------------------------------------------------------------------
struct adav_logo {
	struct adav_logo_element	*data ;
	unsigned 					num_elems ;
	unsigned 					num_alloc ;
} ;

//---------------------------------------------------------------------------------------------------------
struct adav_csv {
	struct adav_csv_element		*data ;
	unsigned 					num_elems ;
} ;


//---------------------------------------------------------------------------------------------------------
typedef struct {
	// Advert detect user_data
	Adata 				*user_data;

	enum Adav_sig  		signature;
	enum Adav_type		type ;

	union {
		struct adav_filter	filter_data ;
		struct adav_logo	logo_data ;
		struct adav_csv		csv_data ;
	} ;

} ADAV;


//========================================================================================================
// MACROS
//========================================================================================================

//---------------------------------------------------------------------------------------------------------
#define ADA_METHOD( name )         const char * const method = #name

#define ADA_CHECK_OBJECT(OBJ)                                                     \
        do {                                                                   \
          if (OBJ == NULL )                                                   \
            Perl_croak(aTHX_ "NULL OBJECT IN " XSCLASS "::%s", method);        \
          if (OBJ->signature != ADA_SIGNATURE)                                \
          {                                                                    \
            if (OBJ->signature == ADA_FREE_SIGNATURE)                                 \
              Perl_croak(aTHX_ "DEAD OBJECT IN " XSCLASS "::%s", method);      \
            Perl_croak(aTHX_ "INVALID OBJECT IN " XSCLASS "::%s", method);     \
          }                                                                    \
          if (OBJ->user_data == NULL || OBJ->type == ADAV_NULL)                          \
            Perl_croak(aTHX_ "OBJECT INCONSITENCY IN " XSCLASS "::%s", method);\
        } while (0)

#define ADA_CHECK_THIS				ADA_CHECK_OBJECT(THIS) ; ada_dbg_printf("== ADAV::%s [%p] type=%s ==\n", method, THIS, adav_types[THIS->type])
#define ADA_END_THIS				ada_dbg_printf("== ADAV::%s [%p] - END ==\n", method, THIS)
#define ADA_CHECK_THIS_NODBG		ADA_CHECK_OBJECT(THIS)
#define ADA_FREE(PTR)				ada_dbg_printf("ADAV free [%p]\n", PTR) ; free(PTR)

#define ADA_UNEXPECTED_CALL			die("Unexpected call to ADAV::%s!", method)

#ifdef DBG_ADAV
static void ada_dbg_printf(char *f, ...)
{
  va_list l;
  va_start(l, f);
  vfprintf(DBG_ADAV_DEV, f, l);
  va_end(l);
}
#else
static void ada_dbg_printf(char *f, ...)	{}
#endif

//---------------------------------------------------------------------------------------------------------

#define _GET_OFFSET(KEY, NAME)							\
	else if (strcmp(key, #KEY) == 0)					\
	{													\
		offset = (void *)&results->NAME ;				\
		key_offset = (int)(offset - base) ;				\
	}


#define GET_OFFSET(NAME)		_GET_OFFSET(NAME, NAME)
#define GET_FRAME_OFFSET(NAME)	_GET_OFFSET(NAME, frame_results.NAME)
#define GET_LOGO_OFFSET(NAME)	_GET_OFFSET(NAME, logo_results.NAME)
#define GET_AUDIO_OFFSET(NAME)	_GET_OFFSET(NAME, audio_results.NAME)


/*

#-----------------------------------------------------------------------------
# Set the gap counts - the distance each frame is from it's previous frame
#
#              numframes=n'                        numframes=n
#              |------------>|                     |----------->|
#                            |<--------------------|
#               _............              gap      _...........
#              | |           :                     | |          :
#   ___________| |___________:_____________________| |__________:____
#              ^             ^                     ^
#            frame=f'     frame_end=e'             frame=f
#
#
#              | f' ..... e' | e'+1  ......... f-1 |
#              |------------>|
#                 n'=e'-f'+1 |
#                            |<--------------------|
#                                gap = (f-1) - (e'+1) + 1
#
#
#
# For frame f:
#
#    gap = f - e' - 1
#

*/

#define CALC_GAP(FRAME, PREV)		(FRAME - PREV -1)

//========================================================================================================
// COMMON FUNCTIONS
//========================================================================================================

//---------------------------------------------------------------------------------------------------------
static void clear_adav(ADAV *this)
{
	this->user_data = 0 ;
	this->signature = ADA_FREE_SIGNATURE ;
	this->type = ADAV_NULL ;
}



//========================================================================================================
// FILTERED FUNCTIONS
//========================================================================================================

//---------------------------------------------------------------------------------------------------------
static int get_key_offset(Adata *user_data, char *key)
{
int key_offset = -1 ;
struct Ad_results *results = user_data->results_list[0].results ;
int *base = (int *)results ;
int *offset ;

	if (!key || (strlen(key)==0) )
	{
		return key_offset ;
	}
	GET_FRAME_OFFSET(black_frame)
	GET_FRAME_OFFSET(scene_frame)
	GET_FRAME_OFFSET(size_change)
	GET_FRAME_OFFSET(screen_width)
	GET_FRAME_OFFSET(screen_height)
	GET_FRAME_OFFSET(brightness)
	GET_FRAME_OFFSET(uniform)
	GET_FRAME_OFFSET(dimCount)
	GET_FRAME_OFFSET(sceneChangePercent)

	GET_LOGO_OFFSET(logo_frame)
	GET_LOGO_OFFSET(match_percent)
	GET_LOGO_OFFSET(ave_percent)

	GET_AUDIO_OFFSET(audio_framenum)
	GET_AUDIO_OFFSET(volume)
	GET_AUDIO_OFFSET(max_volume)
	GET_AUDIO_OFFSET(sample_rate)
	GET_AUDIO_OFFSET(channels)
	GET_AUDIO_OFFSET(samples_per_frame)
	GET_AUDIO_OFFSET(samples)
	GET_AUDIO_OFFSET(framesize)
	GET_AUDIO_OFFSET(volume_dB)
	GET_AUDIO_OFFSET(silent_frame)

	ada_dbg_printf("get_key_offset() + key offset : %d\n", key_offset) ;

	return key_offset ;
}

//---------------------------------------------------------------------------------------------------------
static void create_adav_filter(ADAV *this, Adata *user_data, char *key, int threshold)
{
unsigned i, j ;
int key_offset ;
unsigned ok ;

ada_dbg_printf("create_adav_filter(%s) - START\n", key) ;

	strncpy(this->filter_data.key, key, MAXKEY) ;
	key_offset = get_key_offset(user_data, key) ;

	// Get number of elements
	this->filter_data.num_elems = 0 ;
	for (i=0; i < user_data->results_list_size; i++)
	{
		ok = 0 ;
		if (key_offset < 0)
		{
			ok = 1 ;
		}
		else
		{
			struct Ad_results *results = user_data->results_list[i].results ;
			int *base = (int *)results ;
			int val = *(base + key_offset) ;
			if (val >= threshold)
			{
				ok=1 ;
			}
		}

		if (ok)
		{
			++this->filter_data.num_elems ;
		}
	}

ada_dbg_printf("create_adav_filter(%s) - array size = %d\n", key, this->filter_data.num_elems) ;

	// Create data
	this->filter_data.data = (struct adav_element *)malloc(this->filter_data.num_elems * sizeof(struct adav_element)) ;
	memset(this->filter_data.data, 0, this->filter_data.num_elems * sizeof(struct adav_element)) ;

ada_dbg_printf("create_adav_filter(%s) - data [%p]\n", key, this->filter_data.data) ;

	// Fill data
	for (i=0, j=0; i < user_data->results_list_size; i++)
	{
		struct Ad_results *results = user_data->results_list[i].results ;
		ok = 0 ;

		if (key_offset < 0)
		{
			ok = 1 ;
		}
		else
		{
			int *base = (int *)results ;
			int val = *(base + key_offset) ;
			if (val >= threshold)
			{
				ok=1 ;
			}
		}

		if (ok)
		{
			this->filter_data.data[j].frame = results->video_framenum ;
			this->filter_data.data[j].frame_end = results->video_framenum ;
			this->filter_data.data[j].gap = 0 ;
			j++ ;
		}
	}
ada_dbg_printf("create_adav_filter(%s) - END (j=%d)\n", key, j) ;

}


//---------------------------------------------------------------------------------------------------------
static void free_adav_filter(ADAV *this)
{
ada_dbg_printf("free_adav_filter - START\n") ;
	if (this->filter_data.data)
	{
ada_dbg_printf("free_adav_filter(%s)\n", this->filter_data.key) ;
		ADA_FREE(this->filter_data.data) ;
		this->filter_data.data = 0 ;
		this->filter_data.num_elems = 0 ;
	}
ada_dbg_printf("free_adav_filter - clear adav\n") ;
	clear_adav(this) ;
ada_dbg_printf("free_adav_filter - END\n") ;
}

//---------------------------------------------------------------------------------------------------------
// set the gap value based on frame & frame_end
static void filtered_update_gaps(ADAV *this)
{
unsigned i ;
int prev_frame_end = -1 ;

	for (i=0; i < this->filter_data.num_elems; i++)
	{
		this->filter_data.data[i].gap = CALC_GAP(this->filter_data.data[i].frame, prev_frame_end) ;
		prev_frame_end = this->filter_data.data[i].frame_end ;
	}
}



//========================================================================================================
// LOGO FUNCTIONS
//========================================================================================================

//---------------------------------------------------------------------------------------------------------
static void create_adav_logo(ADAV *this, Adata *user_data)
{
	// Initialise
	this->logo_data.data = 0 ;
	this->logo_data.num_elems = 0 ;
}


//---------------------------------------------------------------------------------------------------------
static void free_adav_logo(ADAV *this)
{
	if (this->logo_data.data)
	{
		ADA_FREE(this->logo_data.data) ;
		this->logo_data.data = 0 ;
		this->logo_data.num_elems = 0 ;
		this->logo_data.num_alloc = 0 ;
	}
	clear_adav(this) ;
}



//---------------------------------------------------------------------------------------------------------
// set the gap value based on frame & frame_end
static void logo_update_gaps(ADAV *this)
{
unsigned i ;
int prev_frame_end = -1 ;

	for (i=0; i < this->logo_data.num_elems; i++)
	{
		this->logo_data.data[i].gap = CALC_GAP(this->logo_data.data[i].frame, prev_frame_end) ;
		prev_frame_end = this->logo_data.data[i].frame_end ;
	}
}

//---------------------------------------------------------------------------------------------------------
// check gaps
#ifdef DBG_ADAV
static void logo_frames_sanity(ADAV *this, int frame)
{
unsigned i ;

	for (i=0; i < this->logo_data.num_elems; i++)
	{
		if (this->logo_data.data[i].gap < 0)
		{
			ada_dbg_printf("<check sanity at frame %d> ??? BAD ??? bad frame=%d\n", frame, i) ;
		}
	}
}
#else
#define logo_frames_sanity(this, frame)
#endif



// Set to 30 minutes (+margin)
#define RESULTS_BLOCKSIZE			(32 * 60 * FPS)
#define STORE_LOGO(IDX, NAME)		HVF_IV(hv, NAME, this->logo_data.data[IDX].NAME)

//---------------------------------------------------------------------------------------------------------
static HV *store_logo(ADAV *this, int idx, HV *hv)
{
SV 	**val;

	ada_dbg_printf(" + store_logo[%d] - curr size=%d (alloc=%d)\n", idx, this->logo_data.num_elems, this->logo_data.num_alloc) ;

	if (idx < 0)
		return hv ;

	// check allocated space - only ever increases
	if ((idx >= this->logo_data.num_alloc) || (!this->logo_data.data))
	{
		// increase size
		this->logo_data.num_alloc += RESULTS_BLOCKSIZE ;
		this->logo_data.data = (struct adav_logo_element *)realloc(this->logo_data.data, this->logo_data.num_alloc * sizeof(struct adav_logo_element)) ;
		memset(&this->logo_data.data[this->logo_data.num_alloc - RESULTS_BLOCKSIZE], 0, RESULTS_BLOCKSIZE * sizeof(struct adav_logo_element)) ;

		ada_dbg_printf(" + + store[%d] inc size - curr size=%d (alloc=%d)\n", idx, this->logo_data.num_elems, this->logo_data.num_alloc) ;

	}

	// set the item
	STORE_LOGO(idx, frame) ;
	STORE_LOGO(idx, frame_end) ;
	STORE_LOGO(idx, match_percent) ;
	STORE_LOGO(idx, ave_percent) ;
	this->logo_data.data[idx].gap = 0 ;

	ada_dbg_printf(" + logo_frame[%d] frame=%d frame_end=%d match=%d ave=%d - curr size=%d\n",
			idx,
			this->logo_data.data[idx].frame,
			this->logo_data.data[idx].frame_end,
			this->logo_data.data[idx].match_percent,
			this->logo_data.data[idx].ave_percent,
			this->logo_data.num_elems) ;


	// update number of elements
	if (idx >= this->logo_data.num_elems)
	{
		this->logo_data.num_elems = idx+1;
		ada_dbg_printf(" + + [%d] news size=%d (alloc=%d)\n", idx, this->logo_data.num_elems, this->logo_data.num_alloc) ;
	}

	return hv ;
}


//---------------------------------------------------------------------------------------------------------
// Shift all array contents down by 'count' ready for an "unshift" command
static void unshift_logo(ADAV *this, int count)
{
int num_blocks ;
struct adav_logo_element *new_data ;

ada_dbg_printf(" + unshift_logo(count=%d) - curr size=%d (alloc=%d)\n", count, this->logo_data.num_elems, this->logo_data.num_alloc) ;

	if (count + this->logo_data.num_elems >= this->logo_data.num_alloc)
	{
		// increase size
		num_blocks = (count / RESULTS_BLOCKSIZE) + 1 ;
		this->logo_data.num_alloc += num_blocks * RESULTS_BLOCKSIZE ;
	}

	new_data = (struct adav_logo_element *)malloc(this->logo_data.num_alloc * sizeof(struct adav_logo_element)) ;
	memset(new_data, 0, this->logo_data.num_alloc * sizeof(struct adav_logo_element)) ;

	memcpy(&new_data[count], this->logo_data.data, this->logo_data.num_elems * sizeof(struct adav_logo_element)) ;

	ADA_FREE(this->logo_data.data) ;
	this->logo_data.data = new_data ;
	this->logo_data.num_elems += count ;

ada_dbg_printf(" + unshift_logo(count=%d) - END : curr size=%d (alloc=%d)\n", count, this->logo_data.num_elems, this->logo_data.num_alloc) ;
}


//========================================================================================================
// CSV FUNCTIONS
//========================================================================================================

//---------------------------------------------------------------------------------------------------------
static void create_adav_csv(ADAV *this, Adata *user_data)
{
unsigned i ;

ada_dbg_printf("create_adav_csv() - START\n") ;

	// Get number of elements
	this->csv_data.num_elems = user_data->results_list_size ;

ada_dbg_printf("create_adav_csv() - array size = %d (%d bytes)\n", this->csv_data.num_elems, (this->csv_data.num_elems * sizeof(struct adav_csv_element)) ) ;

	// Create data
	this->csv_data.data = (struct adav_csv_element *)malloc(this->csv_data.num_elems * sizeof(struct adav_csv_element)) ;

ada_dbg_printf("create_adav_csv() - [%p]\n", this->csv_data.data ) ;

	memset(this->csv_data.data, 0, this->csv_data.num_elems * sizeof(struct adav_csv_element)) ;

	// Fill data
	for (i=0; i < user_data->results_list_size; i++)
	{
		struct Ad_results *results = user_data->results_list[i].results ;
		this->csv_data.data[i].frame = results->video_framenum ;

		this->csv_data.data[i].hv = newHV();
	}

}


//---------------------------------------------------------------------------------------------------------
static void free_adav_csv(ADAV *this)
{
int i ;

ada_dbg_printf("free_adav_csv() - %p\n", this) ;

	if (this->csv_data.data)
	{
		for (i=0; i < this->csv_data.num_elems; i++)
		{
			SvREFCNT_dec(this->csv_data.data[i].hv) ;
		}
		ADA_FREE(this->csv_data.data) ;
		this->csv_data.data = 0 ;
		this->csv_data.num_elems = 0 ;
	}
	clear_adav(this) ;

ada_dbg_printf("free_adav_csv() - %p - END\n", this) ;
}

//---------------------------------------------------------------------------------------------------------
// ASUMPTION: All values are integers (any non-integers are ignored)
static HV *store_csv(ADAV *this, int idx, HV *hv)
{
SV 	*value;
SV 	*newval;
char *key;
I32 len;
HV *csv_hv ;
int ival ;

	ada_dbg_printf(" + store_csv[%d] - curr size=%d\n", idx, this->csv_data.num_elems) ;

	if ((idx < 0) || (idx >= this->csv_data.num_elems))
		return hv ;

	csv_hv = this->csv_data.data[idx].hv ;
	hv_iterinit( hv );
	value = hv_iternextsv( hv, &key, &len );
	while ( value != NULL )
	{
		ada_dbg_printf(" + + store_csv[%d] - %s  ok? %d\n", idx, key, SvIOK(value)) ;
		if ( SvIOK(value) )
		{
			// store/update the value stored in the CSV data for this key
			ival = SvIV(value) ;
 	 		newval = newSViv(ival) ;
 	 		hv_store(csv_hv, key, len, newval, 0);
 			ada_dbg_printf(" + + store_csv[%d] - %s = %d\n", idx, key, ival) ;
		}

		value = hv_iternextsv( hv, &key, &len );
	}

	ada_dbg_printf(" + store_csv[%d] - DONE\n", idx) ;

	return csv_hv ;
}


//---------------------------------------------------------------------------------------------------------
// ASUMPTION: All values are integers (any non-integers are ignored)
static HV *fetch_csv(ADAV *this, int idx, HV *results)
{
HV  *hv ;
SV 	*value;
SV 	*newval;
char *key;
I32 len;
int ival ;

	ada_dbg_printf(" + fetch_csv[%d] - curr size=%d\n", idx, this->csv_data.num_elems) ;

	if ((idx < 0) || (idx >= this->csv_data.num_elems))
		return hv ;

	// update with the csv list stuff
	hv = this->csv_data.data[idx].hv ;
	hv_iterinit( hv );
	value = hv_iternextsv( hv, &key, &len );
	while ( value != NULL )
	{
		// only process if value is a valid integer AND key is not one of the "special" keys
		if ( SvIOK(value) && !(strcmp(key, "frame")==0) )
		{
			// store/update the value returned for this key
			ival = SvIV(value) ;
 	 		newval = newSViv(ival) ;
 	 		hv_store(results, key, len, newval, 0);
 	 		ada_dbg_printf(" + + fetch_csv[%d] - %s = %d\n", idx, key, ival) ;
		}

		value = hv_iternextsv( hv, &key, &len );
	}

	ada_dbg_printf(" + fetch_csv[%d] - DONE\n", idx) ;
	return hv ;
}


//---------------------------------------------------------------------------------------------------------
// Creates the new key for all HASH entries and sets the value to 0
static void csv_add_key(ADAV *this, SV *key)
{
int idx ;
HV  *hv ;
SV 	*value;
SV 	*newval;
I32 len;

	ada_dbg_printf(" + csv_add_key[%s]\n", SvPV_nolen(key)) ;

	// Fill data
	for (idx=0; idx < this->csv_data.num_elems; idx++)
	{
		// update with the csv list stuff
		hv = this->csv_data.data[idx].hv ;
		if (!hv_exists_ent(hv, key, 0))
		{
			newval = newSViv(0) ;
			hv_store_ent(hv, key, newval, 0);
		}
	}
}



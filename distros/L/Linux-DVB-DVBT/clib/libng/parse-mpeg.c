/*
 * parse mpeg program + transport streams.
 *
 */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <ctype.h>
#include <errno.h>
#include <iconv.h>
#include <inttypes.h>

#include "parse-mpeg.h"

// dvb_ts_lib
#include "descriptors/desc_structs.h"

// dvb_lib
#include "dvb_debug.h"
#include "dvb_lib.h"

// TODO: Move into dvb_ts_lib
enum MPEG1_descriptor_ids {
	DESC_ISO639_LANG                   	= 0x0A,		// ISO13818-1 table 2-39
} ;


static const char *stream_type_s[] = {
    [ 0x00          ] = "reserved",
    [ 0x01          ] = "ISO 11172     Video",
    [ 0x02          ] = "ISO 13818-2   Video",
    [ 0x03          ] = "ISO 11172     Audio",
    [ 0x04          ] = "ISO 13818-3   Audio",
    [ 0x05          ] = "ISO 13818-1   private sections",
    [ 0x06          ] = "ISO 13818-1   private data",
    [ 0x07          ] = "ISO 13522     MHEG",
    [ 0x08          ] = "ISO 13818-1   Annex A DSS CC",
    [ 0x09          ] = "ITU-T H.222.1",
    [ 0x0a          ] = "ISO 13818-6   type A",
    [ 0x0b          ] = "ISO 13818-6   type B",
    [ 0x0c          ] = "ISO 13818-6   type C",
    [ 0x0d          ] = "ISO 13818-6   type D",
    [ 0x0e          ] = "ISO 13818-6   auxiliary",
    [ 0x0f ... 0x7f ] = "reserved",
    [ 0x80 ... 0xff ] = "user private",
};

/* ----------------------------------------------------------------------- */

char *psi_charset[0x20] = {
    [ 0x00 ... 0x1f ] = "reserved",
    [ 0x00 ] = "ISO-8859-1",
    [ 0x01 ] = "ISO-8859-5",
    [ 0x02 ] = "ISO-8859-6",
    [ 0x03 ] = "ISO-8859-7",
    [ 0x04 ] = "ISO-8859-8",
    [ 0x05 ] = "ISO-8859-9",
    [ 0x06 ] = "ISO-8859-10",
    [ 0x07 ] = "ISO-8859-11",
    [ 0x08 ] = "ISO-8859-12",
    [ 0x09 ] = "ISO-8859-13",
    [ 0x0a ] = "ISO-8859-14",
    [ 0x0b ] = "ISO-8859-15",
    [ 0x10 ] = "fixme",
    [ 0x11 ] = "UCS-2BE",        // correct?
    [ 0x12 ] = "EUC-KR",
    [ 0x13 ] = "GB2312",
    [ 0x14 ] = "BIG5"
};

char *psi_service_type[0x100] = {
    [ 0x00 ... 0xff ] = "reserved",
    [ 0x80 ... 0xfe ] = "user defined",
    [ 0x01 ] = "digital television service",
    [ 0x02 ] = "digital radio sound service",
    [ 0x03 ] = "teletext service",
    [ 0x04 ] = "NVOD reference service",
    [ 0x05 ] = "NVOD time-shifted service",
    [ 0x06 ] = "mosaic service",
    [ 0x07 ] = "PAL coded signal",
    [ 0x08 ] = "SECAM coded signal",
    [ 0x09 ] = "D/D2-MAC",
    [ 0x0a ] = "FM Radio",
    [ 0x0b ] = "NTSC coded signal",
    [ 0x0c ] = "data broadcast service",
    [ 0x0d ] = "reserved for CI",
    [ 0x0e ] = "RCS Map",
    [ 0x0f ] = "RCS FLS",
    [ 0x10 ] = "DVB MHP service",
};


/* ----------------------------------------------------------------------- */
// DEBUG
/* ----------------------------------------------------------------------- */

/* ----------------------------------------------------------------------- */
void print_stream(struct psi_stream *stream)
{
int i ;
struct list_head *item, *safe, *pitem ;
struct prog_info *pinfo ;

	//    	int                  tsid;
	//
	//        /* network */
	//        int                  netid;
	//        char                 net[PSI_STR_MAX];
	//
	//        int                  frequency;
	//        int                  symbol_rate;
	//        char                 *bandwidth;
	//        char                 *constellation;
	//        char                 *hierarchy;
	//        char                 *code_rate_hp;
	//        char                 *code_rate_lp;
	//        char                 *fec_inner;
	//        char                 *guard;
	//        char                 *transmission;
	//        char                 *polarization;
	//    	  int                  other_freq;
	//    	  int                  *freq_list;
	//
	//        /* status info */
	//        int                  updated;
	//        int					 tuned;
	//
	fprintf(stderr, "TSID %d NETID %d : network %s : freq %d : sr %d : BW %s : Const %s : Hier %s : Code rate hp %s lp %s : FEC %s : Guard %s : Tx %s : Pol %s : Other Freq %d (up %d, tuned %d) : Freq list len=%d\n",
			stream->tsid, stream->netid, stream->net, stream->frequency, stream->symbol_rate,
			stream->bandwidth, stream->constellation, stream->hierarchy, stream->code_rate_hp, stream->code_rate_lp,
			stream->fec_inner, stream->guard, stream->transmission, stream->polarization,
			stream->other_freq,
			stream->updated, stream->tuned,
			stream->freq_list_len
	) ;

	list_for_each(pitem,&stream->prog_info_list)
	{
		pinfo = list_entry(pitem, struct prog_info, next);

		/*			
		int 				 service_id ;
		int 				 service_type ;
		int					 visible ;
		int					 lcn ;
		*/
		fprintf(stderr, "  LCN: %3d  sid 0x%04x type %d visible %d\n",
			pinfo->lcn,
			pinfo->service_id,
			pinfo->service_type,
			pinfo->visible
		) ;
	}

	for (i = 0; i < stream->freq_list_len; i++)
	{
		fprintf(stderr, "  FREQ[%3d] = %d Hz\n", i, stream->freq_list[i]) ;
	}

}

/* ----------------------------------------------------------------------- */
void print_program(struct psi_program *program)
{
struct list_head *item, *safe, *pitem ;
struct freq_info *finfo ;

	//        int                  tsid;
	//         int                  pnr;
	//         int                  version;
	//         int                  running;
	//         int                  ca;
	//
	//         /* program data */
	//         int                  type;
	//         int                  p_pid;             // program
	//         int                  v_pid;             // video
	//         int                  a_pid;             // audio
	//         int                  t_pid;             // teletext
	//         char                 audio[PSI_STR_MAX];
	//         char                 net[PSI_STR_MAX];
	//         char                 name[PSI_STR_MAX];
	//
	//         /* status info */
	//         int                  updated;
	//         int                  seen;

//    if (dvb_debug >= 15)
//    {
//    	fprintf(stderr, "PROG [program=>%p list.next=%p list.prev=%p] ", program, program->next.next, program->next.prev) ;
//    }
	fprintf(stderr, "TSID %d PNR %d : name %s : network %s : running %d : type %d : prog %d, video %d, audio %d, ttext %d, pcr %d : audio %s subtitle %s (up %d / seen %d) : Tuned ", /*by rainbowcrypt*/
			program->tsid, program->pnr, program->name, program->net, program->running,
			program->type, program->p_pid, program->v_pid, program->a_pid, program->t_pid, program->pcr_pid,
			program->audio,
			program->subtitle, /*by rainbowcrypt */
			program->updated, program->seen
	) ;
	
    list_for_each(item,&program->tuned_freq_list) {
        finfo = list_entry(item, struct freq_info, next);
		fprintf(stderr, "%d Hz, ", finfo->frequency) ;
    } 
    
	fprintf(stderr, "\n") ;
}


// FREE =====================================================================

/* ----------------------------------------------------------------------- */
void freq_info_free(struct psi_program *program)
{
    struct freq_info  *finfo;
    struct list_head   *item,*safe;

    list_for_each_safe(item,safe,&program->tuned_freq_list) {
        finfo = list_entry(item, struct freq_info, next);
        list_del(&finfo->next) ;
        free(finfo) ;
    }

}


/* ----------------------------------------------------------------------- */
void program_free(struct psi_program *program)
{
	freq_info_free(program) ;
    free(program);
}




/* ----------------------------------------------------------------------- */
void prog_info_free(struct psi_stream *stream)
{
    struct prog_info  *pinfo;
    struct list_head   *item,*safe;



if (dvb_debug>=20) fprintf(stderr, "!! prog_info_free() !!\n") ;

    list_for_each_safe(item,safe,&stream->prog_info_list) {
		pinfo = list_entry(item, struct prog_info, next);

if (dvb_debug>=20) fprintf(stderr, "!! alloc free - sid=%d [%p] !!\n", pinfo->service_id, pinfo) ;
		
		list_del(&pinfo->next);
		free(pinfo);
    }

if (dvb_debug>=20) fprintf(stderr, "!! prog_info_free() - COMPLETE !!\n") ;
}


/* ----------------------------------------------------------------------- */
void stream_free(struct psi_stream *stream)
{
	if (stream->freq_list_len && stream->freq_list)
	{
		free(stream->freq_list) ;
	}
	prog_info_free(stream) ;
	free(stream);

}


/* ----------------------------------------------------------------------- */
/* handle psi_ structs                                                     */


/* ----------------------------------------------------------------------- */
struct psi_info* psi_info_alloc(void)
{
    struct psi_info *info;

    info = malloc(sizeof(*info));
    memset(info,0,sizeof(*info));
    INIT_LIST_HEAD(&info->streams);
    INIT_LIST_HEAD(&info->programs);
    info->pat_version = PSI_NEW;
    info->sdt_version = PSI_NEW;
    info->nit_version = PSI_NEW;
    return info;
}

/* ----------------------------------------------------------------------- */
void psi_info_free(struct psi_info *info)
{
    struct psi_program *program;
    struct psi_stream  *stream;
    struct list_head   *item,*safe;

    list_for_each_safe(item,safe,&info->streams) {
		stream = list_entry(item, struct psi_stream, next);
		list_del(&stream->next);
		stream_free(stream);
    }
    list_for_each_safe(item,safe,&info->programs) {
		program = list_entry(item, struct psi_program, next);
		list_del(&program->next);
		program_free(program);
    }
    free(info);
}


/* ----------------------------------------------------------------------- */
struct prog_info* prog_info_get(struct psi_stream *stream, int sid, int alloc)
{
    struct prog_info  *pinfo;
    struct list_head  *item;

    list_for_each(item,&stream->prog_info_list) {
        pinfo = list_entry(item, struct prog_info, next);
		if (pinfo->service_id == sid)
		    return pinfo;
    }
    if (!alloc)
		return NULL;
	
    pinfo = malloc(sizeof(*pinfo));
    memset(pinfo,0,sizeof(*pinfo));

if (dvb_debug>=20) fprintf(stderr, "!! malloc - sid=%d [%p] !!\n", sid, pinfo) ;
   
    pinfo->service_id    = sid;

    // flag unset
    pinfo->service_type = -1 ;
    pinfo->visible = -1 ;
    pinfo->lcn = -1 ;

    list_add_tail(&pinfo->next,&stream->prog_info_list);
    return pinfo;
}


/* ----------------------------------------------------------------------- */
struct psi_stream* psi_stream_get(struct psi_info *info, int tsid, int netid, int alloc)
{
    struct psi_stream *stream;
    struct list_head  *item;

if (dvb_debug >= 15) fprintf_timestamp(stderr, "psi_stream_get(tsid=%d, netid=%d [alloc=%d])\n", tsid, netid, alloc) ;

    list_for_each(item,&info->streams) {
        stream = list_entry(item, struct psi_stream, next);
		if (stream->tsid != tsid)
			continue ;
		if (stream->netid != netid)
			continue ;
		
		return stream;
    }
    if (!alloc)
		return NULL;

if (dvb_debug >= 15) fprintf_timestamp(stderr, "## New stream\n", tsid, netid, alloc) ;

    stream = malloc(sizeof(*stream));
    memset(stream,0,sizeof(*stream));

	//    int                  tsid;
	//
	//    /* network */
	//    int                  netid;
	//    char                 net[PSI_STR_MAX];
	//
	//    int                  frequency;
	//    int                  symbol_rate;
	//    char                 *bandwidth;
	//    char                 *constellation;
	//    char                 *hierarchy;
	//    char                 *code_rate_hp;
	//    char                 *code_rate_lp;
	//    char                 *fec_inner;
	//    char                 *guard;
	//    char                 *transmission;
	//    char                 *polarization;
	//    int                  other_freq;
	//    int                  freq_list_len;
	//    int                  *freq_list;
	//
	//    /* status info */
	//    int                  updated;
	//    int					 tuned;
	//    
	//	/* signal quality measure */
	//	unsigned 		ber ;
	//	unsigned		snr ;
	//	unsigned		strength ;
	//	unsigned		uncorrected_blocks ;
	//    
	//    /* program info */
	//    struct list_head     prog_info_list;
	

    INIT_LIST_HEAD(&stream->prog_info_list);
    stream->tsid    = tsid;
    stream->netid = netid ;
    stream->updated = 1;
    stream->tuned = 0;

    // flag unset
    stream->frequency = -1 ;
    stream->symbol_rate = -1 ;

    list_add_tail(&stream->next,&info->streams);
    return stream;
}

/* ----------------------------------------------------------------------- */
// Copy an existing stream but set a new frequency. Then add to the list
struct psi_stream* psi_stream_newfreq(struct psi_info *info, struct psi_stream* src_stream, int frequency)
{
struct psi_stream *stream;
struct prog_info  *pinfo, *src_pinfo;
struct list_head  *item;


    stream = malloc(sizeof(*stream));
    memset(stream,0,sizeof(*stream));
    
    INIT_LIST_HEAD(&stream->prog_info_list);

    stream->frequency    = frequency;

    stream->tsid    = src_stream->tsid;
    stream->netid = src_stream->netid;
    strcpy(stream->net, src_stream->net); 

if (dvb_debug >= 15) fprintf_timestamp(stderr, "psi_stream_newfreq(tsid=%d, netid=%d : freq=%d)\n", stream->tsid, stream->netid, frequency) ;

    stream->symbol_rate = src_stream->symbol_rate;

    stream->bandwidth     = src_stream->bandwidth ;
    stream->constellation = src_stream->constellation ;
    stream->hierarchy     = src_stream->hierarchy ;
    stream->code_rate_hp  = src_stream->code_rate_hp ;
    stream->code_rate_lp  = src_stream->code_rate_lp ;
    stream->guard         = src_stream->guard ;
    stream->transmission  = src_stream->transmission ;
    stream->other_freq    = src_stream->other_freq ;
    stream->freq_list_len = 0 ;
    stream->freq_list     = NULL ;

    stream->updated = 0;
    stream->tuned   = 0;
    
    // copy program information from source stream
    list_for_each(item,&src_stream->prog_info_list) {
        src_pinfo = list_entry(item, struct prog_info, next);

		// copy
		pinfo = prog_info_get(stream, src_pinfo->service_id, /* int alloc */ 1) ;
	    pinfo->service_type = src_pinfo->service_type ;
	    pinfo->visible = src_pinfo->visible ;
	    pinfo->lcn = src_pinfo->lcn ;
    }
     

    list_add_tail(&stream->next,&info->streams);
    return stream;
}


/* ----------------------------------------------------------------------- */
struct freq_info* freq_info_get(struct psi_program *program, int freq)
{
    struct freq_info  *finfo;
    struct list_head  *item;

    list_for_each(item,&program->tuned_freq_list) {
        finfo = list_entry(item, struct freq_info, next);
		if (finfo->frequency == freq)
		    return finfo;
    }
	
    finfo = malloc(sizeof(*finfo));
    memset(finfo,0,sizeof(*finfo));

    finfo->frequency    = freq;

    list_add_tail(&finfo->next,&program->tuned_freq_list);
    return finfo;
}

/* ----------------------------------------------------------------------- */
struct psi_program* psi_program_get(struct psi_info *info, int tsid,
				    int pnr, int tuned_freq, int alloc)
{
    struct psi_program *program;
    struct list_head   *item;

if (dvb_debug >= 15) fprintf(stderr, "<get prog(tsid=%d, pnr=%d, freq=%d, alloc=%d)>\n", tsid, pnr, tuned_freq, alloc) ;
    list_for_each(item,&info->programs) {
        program = list_entry(item, struct psi_program, next);
		if (program->tsid == tsid &&
			program->pnr  == pnr)
		{
if (dvb_debug >= 15) fprintf(stderr, "<< found prog - set freq>>\n") ;
			if (alloc) freq_info_get(program, tuned_freq) ;
if (dvb_debug >= 15) fprintf(stderr, "<< return prog >>\n") ;
if (dvb_debug >= 15) print_program(program) ;
			return program;
		}
    }

    if (!alloc)
    	return NULL;

if (dvb_debug >= 15) fprintf(stderr, "<< create prog (size=%d) >>\n", sizeof(*program)) ;

    program = malloc(sizeof(*program));
    memset(program,0,sizeof(*program));

    INIT_LIST_HEAD(&program->tuned_freq_list);

    program->tsid    = tsid;
    program->pnr     = pnr;
    program->version = PSI_NEW;
    program->updated = 1;
 
if (dvb_debug >= 15) fprintf(stderr, "<< set freq>>\n") ;
   
	// set frequency
	freq_info_get(program, tuned_freq) ;

if (dvb_debug >= 15) fprintf(stderr, "<< set freq done >>\n") ;

//    int                  tsid; X
//    int                  pnr; X
//    int                  version; X
//    int                  running;
//    int                  ca;
//
//    /* program data */
//    int                  type;
//    int                  p_pid;             // program
//    int                  v_pid;             // video
//    int                  a_pid;             // audio
//    int                  t_pid;             // teletext
//    char                 audio[PSI_STR_MAX]; 0
//    char                 net[PSI_STR_MAX]; 0
//    char                 name[PSI_STR_MAX]; 0
//
//    /* status info */
//    int                  updated; X
//    int                  seen;
//
//    /* hmm ... */
//    int                  fd;

    // flag unset
    program->running = -1;
    program->ca = -1;
    program->type = -1;
    program->p_pid = -1;
    program->v_pid = -1;
    program->a_pid = -1;
    program->t_pid = -1;
    program->s_pid = -1;

    list_add_tail(&program->next,&info->programs);

    if (dvb_debug>=2) fprintf(stderr, "## Add program: tsid=%d pnr=%d freq=%d\n", tsid, pnr, tuned_freq) ;

if (dvb_debug >= 15) fprintf(stderr, "<< return prog >>\n") ;
if (dvb_debug >= 15) print_program(program) ;

    return program;
}

/* ----------------------------------------------------------------------- */
/* bit fiddeling                                                           */

unsigned int mpeg_getbits(unsigned char *buf, int start, int count)
{
    unsigned int result = 0;
    unsigned char bit;

    while (count) {
	result <<= 1;
	bit      = 1 << (7 - (start % 8));
	result  |= (buf[start/8] & bit) ? 1 : 0;
	start++;
	count--;
    }
    return result;
}

/* ----------------------------------------------------------------------- */
void hexdump(char *prefix, unsigned char *data, size_t size)
{
    char ascii[17];
    int i;

    for (i = 0; i < size; i++) {
	if (0 == (i%16)) {
	    fprintf(stderr,"%s%s%04x:",
		    prefix ? prefix : "",
		    prefix ? ": "   : "",
		    i);
	    memset(ascii,0,sizeof(ascii));
	}
	if (0 == (i%4))
	    fprintf(stderr," ");
	fprintf(stderr," %02x",data[i]);
	ascii[i%16] = isprint(data[i]) ? data[i] : '.';
	if (15 == (i%16))
	    fprintf(stderr," %s\n",ascii);
    }
    if (0 != (i%16)) {
	while (0 != (i%16)) {
	    if (0 == (i%4))
		fprintf(stderr," ");
	    fprintf(stderr,"   ");
	    i++;
	};
	fprintf(stderr," %s\n",ascii);
    }
}


/* ----------------------------------------------------------------------- */
static void add_audio_pid(struct psi_program *program, int audio_pid, const char *lang)
{
    if (!program->a_pid)
    	program->a_pid = audio_pid;

    int slen = strlen(program->audio);
    snprintf(program->audio + slen, sizeof(program->audio) - slen,
	     "%s%.3s:%d", slen ? " " : "", lang ? lang : "xxx", audio_pid);
}

/* ----------------------------------------------------------------------- */
static char* get_lang_tag(unsigned char *desc, int dlen)
{
    int i,t,l;

    for (i = 0; i < dlen; i += desc[i+1] +2) {
		t = desc[i];
		l = desc[i+1];

		if (DESC_ISO639_LANG == t)
			return (char*) desc+i+2;
    }
    return NULL;
}



/* ----------------------------------------------------------------------- */
/* transport streams                                                       */

static void parse_pmt_desc(unsigned char *desc, int dlen,
			   struct psi_program *program, int pid)
{
    int i,t,l,slen;
    char lang[4] = "" ;
    int audio_pid = -1 ;

    for (i = 0; i < dlen; i += desc[i+1] +2) {
		t = desc[i];
		l = desc[i+1];

		if (dvb_debug>5)
	    fprintf(stderr," parse_pmt_desc() pid=%d t=0x%02x\n",pid,t);

		switch (t) {
			case DESC_ISO639_LANG:
			{
				char *langp = get_lang_tag(desc, dlen) ;
				strncpy(lang, langp, sizeof(lang)) ;
				if (dvb_debug>5) {
					fprintf_timestamp(stderr, " + lang=%s\n", lang) ;
				}
			}
			break;

			case DESC_AC3:
			case DESC_ENHANCED_AC3:
				audio_pid = pid ;
				if (dvb_debug>5) {
					fprintf_timestamp(stderr, " + AC3 pid=%d\n", pid) ;
				}
			break;

			case DESC_TELETEXT:
				if (!program->t_pid)
					program->t_pid = pid;

			    if (dvb_debug>5) {
					fprintf_timestamp(stderr, " + t_pid=%d\n", program->t_pid) ;
			    }
			break;

			case DESC_SUBTITLING: /* subtitles (pmt) */
				if (!program->s_pid)
					program->s_pid = pid;
					slen = strlen(program->subtitle); /*by rainbowcrypt*/
					snprintf(program->subtitle + slen, sizeof(program->subtitle) - slen,
						"%s%.3s:%d",slen ? " " : "", desc+i+2,pid);/*by rainbowcrypt*/
				if (dvb_debug>5)
					fprintf(stderr," subtitles=%3.3s\n",desc+i+2);
		    break;
		}
    }

    // Check to see if we got an audio pid as part of this section
    if (audio_pid >= 0)
    {
    	// add the information to the audio list (and set the audio pid if not already set)
    	add_audio_pid(program, audio_pid, lang) ;
    }
}

/* ----------------------------------------------------------------------- */
static void dump_data(unsigned char *data, int len)
{
    int i;

    for (i = 0; i < len; i++)
    {
//		if (isprint(data[i]))
//			fprintf(stderr,"%c", data[i]);
//		else
//			fprintf(stderr,"\\x%02x", (int)data[i]);
		fprintf(stderr,"0x%02x ", (int)data[i]);
    }
}

/* ----------------------------------------------------------------------- */
void mpeg_dump_desc(unsigned char *desc, int dlen)
{
    int i,j,t,l,l2,l3;

    for (i = 0; i < dlen; i += desc[i+1] +2) {
	t = desc[i];
	l = desc[i+1];

	switch (t) {
	case 0x0a: /* ??? (pmt) */
	    fprintf(stderr," lang=%3.3s",desc+i+2);
	    break;
	case 0x45: /* vbi data (pmt) */
	    fprintf(stderr," vbidata=");
	    dump_data(desc+i+2,l);
	    break;
	case 0x52: /* stream identifier */
	    fprintf(stderr," sid=%d",(int)desc[i+2]);
	    break;
	case 0x56: /* teletext (pmt) */
	    fprintf(stderr," teletext=%3.3s",desc+i+2);
	    break;
	case 0x59: /* subtitles (pmt) */
	    fprintf(stderr," subtitles=%3.3s",desc+i+2);
	    break;
	case 0x6a: /* ac3 (pmt) */
	    fprintf(stderr," ac3");
	    break;

	case 0x40: /* network name (nit) */
	    fprintf(stderr," name=");
	    dump_data(desc+i+2,l);
	    break;
	case 0x43: /* satellite delivery system (nit) */
	    fprintf(stderr," dvb-s");
	    break;
	case 0x44: /* cable delivery system (nit) */
	    fprintf(stderr," dvb-c");
	    break;
	case 0x5a: /* terrestrial delivery system (nit) */
	    fprintf(stderr," dvb-t");
	    break;

	case 0x48: /* service (sdt) */
	    fprintf(stderr," service=%d,",desc[i+2]);
	    l2 = desc[i+3];
	    dump_data(desc+i+4,desc[i+3]);
	    fprintf(stderr,",");
	    dump_data(desc+i+l2+5,desc[i+l2+4]);
	    break;

	case 0x4d: /*  event (eid) */
	    fprintf(stderr," short=[%3.3s|",desc+i+2);
	    l2 = desc[i+5];
	    l3 = desc[i+6+l2];
	    dump_data(desc+i+6,l2);
	    fprintf(stderr,"|");
	    dump_data(desc+i+7+l2,l3);
	    fprintf(stderr,"]");
	    break;
	case 0x4e: /*  event (eid) */
	    fprintf(stderr," *ext event");
	    break;
	case 0x4f: /*  event (eid) */
	    fprintf(stderr," *time shift event");
	    break;
	case 0x50: /*  event (eid) */
	    fprintf(stderr," *component");
	    break;
	case 0x54: /*  event (eid) */
	    fprintf(stderr," content=");
	    for (j = 0; j < l; j+=2)
		fprintf(stderr,"%s0x%02x", j ? "," : "", desc[i+j+2]);
	    break;
	case 0x55: /*  event (eid) */
	    fprintf(stderr," *parental rating");
	    break;

	default:
	    fprintf(stderr," 0x%02x[",desc[i]);
	    dump_data(desc+i+2,l);
	    fprintf(stderr,"]");
	}
    }
}

/* ----------------------------------------------------------------------- */
int mpeg_parse_psi_pat(struct psi_info *info, unsigned char *data, int verbose, int tuned_freq)
{
    struct list_head   *item;
    struct psi_program *pr;
    int tsid,pnr,version,current;
    int j,len,pid;

    len     = mpeg_getbits(data,12,12) + 3 - 4;
    tsid    = mpeg_getbits(data,24,16);
    version = mpeg_getbits(data,42,5);
    current = mpeg_getbits(data,47,1);
    if (!current)
	return len+4;
    if (info->tsid == tsid && info->pat_version == version)
	return len+4;
    info->tsid         = tsid;
    info->pat_version  = version;
    info->pat_updated  = 1;

    if (verbose>1)
		fprintf_timestamp(stderr, "ts [pat]: tsid %d ver %2d [%d/%d]\n",
			tsid, version,
			mpeg_getbits(data,48, 8),
			mpeg_getbits(data,56, 8));
		
    for (j = 64; j < len*8; j += 32) {
		pnr    = mpeg_getbits(data,j+0,16);
		pid    = mpeg_getbits(data,j+19,13);
		if (0 == pnr) {
		    /* network */
		    if (verbose > 2)
			fprintf(stderr,"   pid 0x%04x [network]\n",
				pid);
		} else {
		    /* program */
		    pr = psi_program_get(info, tsid, pnr, tuned_freq, 1);
		    pr->p_pid   = pid;
		    pr->updated = 1;
		    pr->seen    = 1;
		    if (NULL == info->pr)
				info->pr = pr;
		}
    }

    if (verbose > 2) {
		list_for_each(item,&info->programs) {
		    pr = list_entry(item, struct psi_program, next);
		    if (pr->tsid != tsid)
			continue;
		    fprintf(stderr,"   pid 0x%04x => pnr %2d [program map%s]\n",
			    pr->p_pid, pr->pnr,
			    pr->seen ? ",seen" : "");
		}
		fprintf(stderr,"\n");
    }
    return len+4;
}

/* ----------------------------------------------------------------------- */
int mpeg_parse_psi_pmt(struct psi_program *program, unsigned char *data, int verbose, int tuned_freq)
{
    int pnr,version,current;
    int j,len,dlen,type,pid,slen,pcr_pid;
    char *lang;

    len     = mpeg_getbits(data,12,12) + 3 - 4;
    pnr     = mpeg_getbits(data,24,16);
    version = mpeg_getbits(data,42,5);
    current = mpeg_getbits(data,47,1);
    pcr_pid = mpeg_getbits(data,67,13);
    if (!current)
    	return len+4;
    if (program->pnr == pnr && program->version == version)
    	return len+4;
    program->version = version;
    program->updated = 1;
    program->pcr_pid = pcr_pid ;

    dlen = mpeg_getbits(data,84,12);
    /* TODO: decode descriptor? */
    if (verbose>1) {
		fprintf_timestamp(stderr,
			"ts [pmt]: pnr %d ver %2d [%d/%d]  pcr 0x%04x "
			"pid 0x%04x  type %2d #",
			pnr, version,
			mpeg_getbits(data,48, 8),
			mpeg_getbits(data,56, 8),
			pcr_pid,
			program->p_pid, program->type);
		mpeg_dump_desc(data + 96/8, dlen);
		fprintf(stderr,"\n");
    }
    j = 96 + dlen*8;
    program->v_pid = 0;
    program->a_pid = 0;
    program->t_pid = 0;
    program->s_pid = 0;
    memset(program->audio,0,sizeof(program->audio));
    while (j < len*8) {
		type = mpeg_getbits(data,j,8);
		pid  = mpeg_getbits(data,j+11,13);
		dlen = mpeg_getbits(data,j+28,12);

	    if (dvb_debug>1) {
			fprintf_timestamp(stderr, " + type=%2d (0x%02x) pid=%d (0x%04x)\n",
				type, type, pid, pid) ;
	    }

		switch (type) {

		/* video */
		case MPEG1Video:
		case MPEG2Video:
		case MPEG4Video:
		case H264Video:

		    if (!program->v_pid)
				program->v_pid = pid;
		    break;


		/* audio */
		case MPEG1Audio:
		case MPEG2Audio:
		case MPEG2AudioAmd1:
		case AACAudio:
		    lang = get_lang_tag(data + (j+40)/8, dlen);
	    	    add_audio_pid(program, pid, lang) ;
		    break;

		/* private data */
		case PrivSec:
		case PrivData:

		    parse_pmt_desc(data + (j+40)/8, dlen, program, pid);
		    break;
		}
	
		if (dvb_debug >= 2)
		{
		    fprintf(stderr, "   PROG: tsid=%d pnr=%d video=%d audio=%d text=%d sub=%d (freq=%d)\n",
			    program->tsid, program->pnr, 
			    program->v_pid, program->a_pid, program->t_pid, program->s_pid,
			    tuned_freq);
		}
		if ( (verbose > 2) || (dvb_debug >= 3) ) 
		{
		    fprintf(stderr, "   pid 0x%04x (video=%d audio=%d) => %-32s #",
			    pid, 
			    program->v_pid, program->a_pid,
			    stream_type_s[type]);
		    mpeg_dump_desc(data + (j+40)/8, dlen);
		    fprintf(stderr,"\n");
		}

		j += 40 + dlen*8;
    }

    if (verbose > 2)
		fprintf(stderr,"\n");

    return len+4;
}


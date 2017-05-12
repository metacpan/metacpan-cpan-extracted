/*
 * MPEG1/2 transport and program stream parser and demuxer code.
 *
 * (c) 2003 Gerd Knorr <kraxel@bytesex.org>
 *
 */
#ifndef PARSE_MPEG
#define PARSE_MPEG

#include <inttypes.h>
#include "list.h"

extern char *psi_charset[0x20];
extern char *psi_service_type[0x100];


/* ----------------------------------------------------------------------- */
// "Borrowed" from MythTV - http://www.mythtv.org
//
enum MPEG_STREAM_TYPE
{
    // video
    MPEG1Video     = 0x01, ///< ISO 11172-2 (aka MPEG-1)
    MPEG2Video     = 0x02, ///< ISO 13818-2 & ITU H.262 (aka MPEG-2)
    MPEG4Video     = 0x10, ///< ISO 14492-2 (aka MPEG-4)
    H264Video      = 0x1b, ///< ISO 14492-10 & ITU H.264 (aka MPEG-4-AVC)
    OpenCableVideo = 0x80,
    VC1Video       = 0xea, ///< SMPTE 421M video codec (aka VC1) in Blu-Ray

    // audio
    MPEG1Audio     = 0x03, ///< ISO 11172-3
    MPEG2Audio     = 0x04, ///< ISO 13818-3
    MPEG2AudioAmd1 = 0x11, ///< ISO 13818-3/AMD-1 Audio using LATM syntax
    AACAudio       = 0x0f, ///< ISO 13818-7 Audio w/ADTS syntax
    AC3Audio       = 0x81,
    DTSAudio       = 0x8a,

    // DSM-CC Object Carousel
    DSMCC          = 0x08, ///< ISO 13818-1 Annex A DSM-CC & ITU H.222.0
    DSMCC_A        = 0x0a, ///< ISO 13818-6 type A Multi-protocol Encap
    DSMCC_B        = 0x0b, ///< ISO 13818-6 type B Std DSMCC Data
    DSMCC_C        = 0x0c, ///< ISO 13818-6 type C NPT DSMCC Data
    DSMCC_D        = 0x0d, ///< ISO 13818-6 type D Any DSMCC Data
    DSMCC_DL       = 0x14, ///< ISO 13818-6 Download Protocol
    MetaDataPES    = 0x15, ///< Meta data in PES packets
    MetaDataSec    = 0x16, ///< Meta data in metadata_section's
    MetaDataDC     = 0x17, ///< ISO 13818-6 Metadata in Data Carousel
    MetaDataOC     = 0x18, ///< ISO 13818-6 Metadata in Object Carousel
    MetaDataDL     = 0x19, ///< ISO 13818-6 Metadata in Download Protocol

    // other
    PrivSec        = 0x05, ///< ISO 13818-1 private tables   & ITU H.222.0
    PrivData       = 0x06, ///< ISO 13818-1 PES private data & ITU H.222.0

    MHEG           = 0x07, ///< ISO 13522 MHEG
    H222_1         = 0x09, ///< ITU H.222.1

    MPEG2Aux       = 0x0e, ///< ISO 13818-1 auxiliary & ITU H.222.0

    FlexMuxPES     = 0x12, ///< ISO 14496-1 SL/FlexMux in PES packets
    FlexMuxSec     = 0x13, ///< ISO 14496-1 SL/FlexMux in 14496_sections

    MPEG2IPMP      = 0x1a, ///< ISO 13818-10 Digital Restrictions Mangment
    MPEG2IPMP2     = 0x7f, ///< ISO 13818-10 Digital Restrictions Mangment
};



// List of tuned frequencies stored for each program
struct freq_info {
    struct list_head     next;

	int 				 frequency ;
} ;


/* data gathered from NIT during scan - info is added to the stream */
struct prog_info {
    struct list_head     next;

	/* from service_list_descriptor 0x41 */
	int 				 service_id ;
	int 				 service_type ;
	
	/* from descriptor 0x83 */
	int					 visible ;
	int					 lcn ;

} ;


/* ----------------------------------------------------------------------- */

#define PSI_NEW     42  // initial version, valid range is 0 ... 32
#define PSI_STR_MAX 64

struct psi_stream {
    struct list_head     next;
    int                  tsid;

    /* network */
    int                  netid;
    char                 net[PSI_STR_MAX];

    int                  frequency;

    char                 *bandwidth;
    char                 *code_rate_hp;
    char                 *code_rate_lp;
    char                 *constellation;
    char                 *transmission;
    char                 *guard;
    char                 *hierarchy;

    char                 *polarization;		// Not used
    int                  symbol_rate;		// Not used
    char                 *fec_inner;		// Not used

	// Other frequency list    
    int                  other_freq;
    int                  freq_list_len;
    int                  *freq_list;

    /* status info */
    int                  updated;
    int					 tuned;		// set when we've tuned to this transponder's freq

    /* program info i.e. LCN info */
    struct list_head     prog_info_list;
    
};


struct psi_program {
    struct list_head     next;
    int                  tsid;
    int                  pnr;
    int                  version;
    int                  running;
    int                  ca;
    
	// keep a record of the currently tuned frequency when we saw this
    // (it may not relate to the transponder centre freq)
    struct list_head     tuned_freq_list ;
    
    									
    /* program data */
    int                  type;
    int                  p_pid;             // program
    int                  v_pid;             // video
    int                  a_pid;             // audio
    int                  t_pid;             // teletext
    int                  s_pid;             // subtitle
    int                  pcr_pid;           // PCR (program clock reference)
    char                 audio[PSI_STR_MAX];
    char                 subtitle[PSI_STR_MAX]; /*by rainbowcrypt*/
    char                 net[PSI_STR_MAX];
    char                 name[PSI_STR_MAX];

    /* status info */
    int                  updated;
    int                  seen;

    /* hmm ... */
//    int                  fd;
};

struct psi_info {
    int                  tsid;

    struct list_head     streams;
    struct list_head     programs;

    /* status info */
    int                  pat_updated;

    /* hmm ... */
    struct psi_program   *pr;
    int                  pat_version;
    int                  sdt_version;
    int                  nit_version;
};

/* ----------------------------------------------------------------------- */

/* ----------------------------------------------------------------------- */
// DEBUG
/* ----------------------------------------------------------------------- */

/* ----------------------------------------------------------------------- */
void print_stream(struct psi_stream *stream) ;
void print_program(struct psi_program *program) ;

/* ----------------------------------------------------------------------- */

/* handle psi_* */
struct prog_info* prog_info_get(struct psi_stream *stream, int sid, int alloc) ;
void prog_info_free(struct psi_stream *stream) ;

struct psi_info* psi_info_alloc(void);
void psi_info_free(struct psi_info *info);
struct psi_stream* psi_stream_get(struct psi_info *info, int tsid, int netid, int alloc);
struct psi_stream* psi_stream_newfreq(struct psi_info *info, struct psi_stream* src_stream, int frequency);
struct psi_program* psi_program_get(struct psi_info *info, int tsid,
				    int pnr, int tuned_freq, int alloc);

/* misc */
void hexdump(char *prefix, unsigned char *data, size_t size);
void mpeg_dump_desc(unsigned char *desc, int dlen);

/* common */
unsigned int mpeg_getbits(unsigned char *buf, int start, int count);

/* transport stream */
void mpeg_parse_psi_string(char *src, int slen, char *dest, int dlen);
int mpeg_parse_psi_pat(struct psi_info *info, unsigned char *data, int verbose, int tuned_freq);
int mpeg_parse_psi_pmt(struct psi_program *program, unsigned char *data, int verbose, int tuned_freq);

/* DVB stuff */
int mpeg_parse_psi_sdt(struct psi_info *info, unsigned char *data, int verbose, int tuned_freq);
int mpeg_parse_psi_nit(struct psi_info *info, unsigned char *data, int verbose, int tuned_freq);

#endif

#ifndef DVB_EPG
#define DVB_EPG

#include <inttypes.h>
#include <list.h>

#include "dvb.h"


//
//
//                 7 6 5 4 3 2 1 0
//                     | | | | | |
//  he-aac ------------' | | | | |  0x00020
//  surround ------------' | | | |  0x00010
//  multi -----------------' | | |  0x00008
//  dual --------------------' | |  0x00004
//  stereo --------------------' |  0x00002
//  mono ------------------------'
//
#define EPG_FLAG_AUDIO_MONO      (1<<0)
#define EPG_FLAG_AUDIO_STEREO    (1<<1)
#define EPG_FLAG_AUDIO_DUAL      (1<<2)
#define EPG_FLAG_AUDIO_MULTI     (1<<3)
#define EPG_FLAG_AUDIO_SURROUND  (1<<4)
#define EPG_FLAG_AUDIO_HEAAC	 (1<<5)
#define EPG_FLAGS_AUDIO          (0xff)

//
//          15 14 13 12  11 10  9  8
//                        |  |  |  |
//  H264 -----------------'  |  |  |  0x00800
//  HDTV --------------------'  |  |  0x00400
//  16:9 -----------------------'  |  0x00200
//  4:3 ---------------------------'  0x00100
//
#define EPG_FLAG_VIDEO_4_3       (1<< 8)
#define EPG_FLAG_VIDEO_16_9      (1<< 9)
#define EPG_FLAG_VIDEO_HDTV      (1<<10)
#define EPG_FLAG_VIDEO_H264      (1<<11)
#define EPG_FLAGS_VIDEO          (0xff << 8)

// 0x10000
#define EPG_FLAG_SUBTITLES       (1<<16)

/* ----------------------------------------------------------------------- */
struct epgitem {
    struct list_head    next;
    int                 id;
    int                 tsid;
    int                 pnr;
    int                 updated;

    time_t              start;       /* unix epoch */
    time_t              stop;
    unsigned			duration_secs ;

    char                lang[4];
    char                name[128];
    char                stext[256];
    char                *etext;
    char                *cat[4];
    uint64_t            flags;

    char				tva_prog[256] ;
    char				tva_series[256] ;

    /* for the epg store */
    int                 row;
    int                 playing;
    struct station      *station;
};

extern struct list_head epg_list;
extern time_t eit_last_new_record;
extern int    eit_count_records;

/* ----------------------------------------------------------------------- */
struct partitem {
    struct list_head    next;
    int                 pnr;
    int                 tsid;
    int                 parts;
    int                 parts_left;
};
extern struct list_head parts_list;
extern int parts_remaining ;

/* ----------------------------------------------------------------------- */
struct erritem {
    struct list_head    next;
    int                 freq;
    int                 section;
    int                 errors;
};
extern struct list_head errs_list;
extern int total_errors ;

struct eit_state;

struct list_head * get_eit(struct dvb_state *dvb,  int section, int mask, int verbose, int alive);

//extern struct epgitem* eit_lookup(int tsid, int pnr, time_t when, int debug);

#endif

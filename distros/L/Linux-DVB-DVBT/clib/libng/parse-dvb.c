/*
 * parse various TV stuff out of DVB TS streams.
 *
 */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <ctype.h>
#include <errno.h>
#include <iconv.h>

#include "parse-mpeg.h"

// dvb_lib
#include "dvb_debug.h"
#include "dvb_lib.h"

// Enable testing of multi-frequency handling
//#define TEST_MULTIFREQ

#ifdef TEST_MULTIFREQ

//idx = (tsid & 0xf000) >> 12
//
//[4107] 0x100B idx=1
//frequency = 578000000
//
//[8199] 0x2007 idx=2
//frequency = 850000000
//
//[12290] 0x3002 idx=3
//frequency = 713833330
//
//[16384] 0x4000 idx=4
//frequency = 721833330
//
//[20480] 0x5000 idx=5
//frequency = 690000000
//
//[24576] 0x6000 idx=6
//frequency = 538000000
//

// [idx][] - 1st entry is number of freqs, rest of entries are freq list
int other_freqs[8][8] = {
	/* 0 */ {0, 0, 0, 0, 0, 0, 0, 0}, 
	/* 1 */ {3, 111111, 578000000, 12222222, 0, 0, 0, 0}, 
	/* 2 */ {4, 850000000, 21111111, 22222, 233333, 0, 0, 0}, 
	/* 3 */ {2, 311, 713833330, 0, 0, 0, 0, 0}, 
	/* 4 */ {3, 4111, 4222, 721833330, 0, 0, 0, 0}, 
	/* 5 */ {4, 51111, 52222, 53333, 690000000, 0, 0, 0}, 
	/* 6 */ {5, 611111, 622222, 633333, 644444, 538000000, 0, 0}, 
	/* 7 */ {0, 0, 0, 0, 0, 0, 0, 0}, 
} ;  

#endif


/* ----------------------------------------------------------------------- */
static unsigned int unbcd(unsigned int bcd)
{
    unsigned int factor = 1;
    unsigned int ret = 0;
    unsigned int digit;

    while (bcd) {
	digit   = bcd & 0x0f;
	ret    += digit * factor;
	bcd    /= 16;
	factor *= 10;
    }
    return ret;
}

/* ----------------------------------------------------------------------- */
static int iconv_string(char *from, char *to,
			char *src, size_t len,
			char *dst, size_t max)
{
    size_t ilen = (-1 != len) ? len : strlen(src);
    size_t olen = max-1;
    iconv_t ic;

    if (NULL == from)
	return 0;
    ic = iconv_open(to,from);
    if (NULL == ic)
	return 0;

    while (ilen > 0) {
	if (-1 == iconv(ic,&src,&ilen,&dst,&olen)) {
	    /* skip + quote broken byte unless we are out of space */
	    if (E2BIG == errno)
		break;
	    if (olen < 4)
		break;
	    sprintf(dst,"\\x%02x",(int)(unsigned char)src[0]);
	    src  += 1;
	    dst  += 4;
	    ilen -= 1;
	    olen -= 4;
	}
    }
    dst[0] = 0;
    iconv_close(ic);
    return max-1 - olen;
}

/* ----------------------------------------------------------------------- */
static int handle_control_8(unsigned char *src,  int slen,
			    unsigned char *dest, int dlen)
{
    int s,d;

    for (s = 0, d = 0; s < slen && d < dlen;) {
	if (src[s] >= 0x80  &&  src[s] <= 0x9f) {
	    switch (src[s]) {
	    case 0x86: /* <em>  */
	    case 0x87: /* </em> */
		s++;
		break;
	    case 0x1a: /* ^Z    */
		dest[d++] = ' ';
		s++;
		break;
	    case 0x8a: /* <br>  */
		dest[d++] = '\n';
		s++;
		break;
	    default:
		s++;
	    }
	} else {
	    dest[d++] = src[s++];
	}
    }
    return d;
}

/* ----------------------------------------------------------------------- */
void mpeg_parse_psi_string(char *src, int slen, char *dest, int dlen)
{
    char *tmp;
    int tlen ;
    unsigned ch = 0;
    unsigned first_byte = (unsigned)src[0] ;

//fprintf(stderr, "mpeg_parse_psi_string src len=%d [0x%02x ..], dest len=%d\n", slen, first_byte, dlen) ;

    if (first_byte < 0x20) {
		ch = first_byte;
		src++;
		slen--;
    }

    memset(dest,0,dlen);

//fprintf(stderr, " + ch = 0x%02x\n", ch) ;

    if (ch < 0x10) {
//fprintf(stderr, " + handle_control_8()\n") ;
		/* 8bit charset */
		tmp = malloc(slen);
//fprintf(stderr, " + + malloc() %p\n", tmp) ;
		tlen = handle_control_8(src, slen, tmp, slen);
//fprintf(stderr, " + + calling iconv_string() ...\n") ;
		iconv_string(psi_charset[ch], "UTF-8", tmp, tlen, dest, dlen);
//fprintf(stderr, " + + free() %p\n", tmp) ;
		free(tmp);
    } else {
//fprintf(stderr, " + iconv()\n") ;
		/* 16bit charset */
		iconv_string(psi_charset[ch], "UTF-8", src, slen, dest, dlen);
    }
//fprintf(stderr, "mpeg_parse_psi_string - DONE\n") ;
}

/* ======================================================================= */
/* DESCRIPTORS
 * 
 */

/* ----------------------------------------------------------------------- */
static void parse_nit_desc_1(unsigned char *desc, int dlen,
			     char *dest, int max)
{
    int i,t,l;

    if (dvb_debug>1)
		fprintf(stderr,
			"parse_nit_desc_1()\n");

    for (i = 0; i < dlen; i += desc[i+1] +2) {
	t = desc[i];
	l = desc[i+1];

    if (dvb_debug>1)
		fprintf_timestamp(stderr,
			"ts [nit1]: t 0x%02x   l %d\n",
			t, l);

	switch (t) {
	case 0x40:
	    mpeg_parse_psi_string((char*)desc+i+2, l, dest, max);
	    break;
	}
    }
}

/* ----------------------------------------------------------------------- */
static void parse_nit_desc_2(unsigned char *desc, int dlen,
			     struct psi_stream *stream, int tuned_freq)
{
    static char *bw[4] = {
	[ 0 ] = "8",
	[ 1 ] = "7",
	[ 2 ] = "6",
	[ 3 ] = "5",
    };
    static char *co_t[4] = { 
	[ 0 ] = "0",	/* QPSK */
	[ 1 ] = "16",
	[ 2 ] = "64",
    };
    static char *co_c[16] = {
	[ 0 ] = "0",
	[ 1 ] = "16",
	[ 2 ] = "32",
	[ 3 ] = "64",
	[ 4 ] = "128",
	[ 5 ] = "256",
    };
    static char *hi[4] = {
	[ 0 ] = "0",
	[ 1 ] = "1",
	[ 2 ] = "2",
	[ 3 ] = "4",
    };
    static char *ra_t[8] = {
	[ 0 ] = "12",
	[ 1 ] = "23",
	[ 2 ] = "34",
	[ 3 ] = "56",
	[ 4 ] = "78",
    };
    static char *ra_sc[8] = {
	[ 1 ] = "12",
	[ 2 ] = "23",
	[ 3 ] = "34",
	[ 4 ] = "56",
	[ 5 ] = "78",
    };
    static char *gu[4] = {
	[ 0 ] = "32",
	[ 1 ] = "16",
	[ 2 ] = "8",
	[ 3 ] = "4",
    };
    static char *tr[3] = {
	[ 0 ] = "2",
	[ 1 ] = "8",
	[ 2 ] = "4",
    };
    static char *po[4] = {
	[ 0 ] = "H",
	[ 1 ] = "V",
	[ 2 ] = "L",  // circular left
	[ 3 ] = "R",  // circular right
    };
    unsigned int freq,rate,fec;
    int i,j, t,l;

    if (dvb_debug>1)
		fprintf(stderr,
			"parse_nit_desc_2()\n");

    for (i = 0; i < dlen; i += desc[i+1] +2) 
    {
	t = desc[i];
	l = desc[i+1];

    if (dvb_debug>1)
		fprintf_timestamp(stderr,
			"ts [nit2]: t 0x%02x   l %d\n",
			t, l);


	switch (t) {
	case 0x43: /* dvb-s */
	    freq = mpeg_getbits(desc+i+2,  0, 32);
	    rate = mpeg_getbits(desc+i+2, 56, 28);
	    fec  = mpeg_getbits(desc+i+2, 85,  3);
	    stream->frequency     = unbcd(freq)    * 10;
	    stream->symbol_rate   = unbcd(rate*16) * 10;
	    stream->fec_inner     = ra_sc[fec];
	    stream->polarization  = po[   mpeg_getbits(desc+i+2, 49, 2) ];
	    break;
	    
	case 0x44: /* dvb-c */
	    freq = mpeg_getbits(desc+i+2,  0, 32);
	    rate = mpeg_getbits(desc+i+2, 56, 28);
	    fec  = mpeg_getbits(desc+i+2, 85,  3);
	    stream->frequency     = unbcd(freq)    * 100;
	    stream->symbol_rate   = unbcd(rate*16) * 10;
	    stream->fec_inner     = ra_sc[fec];
	    stream->constellation = co_c[ mpeg_getbits(desc+i+2, 52, 4) ];
	    break;
	    
	    
	case 0x5a: /* dvb-t */
		// terrestrial_delivery_system_descriptor

		//	centre_frequency 32 bslbf
		//	bandwidth 3 bslbf
		//	priority 1 bslbf
		//	Time_Slicing_indicator 1 bslbf
		//	MPE-FEC_indicator 1 bslbf
		//	reserved_future_use 2 bslbf
		//	constellation 2 bslbf
		//	hierarchy_information 3 bslbf
		//	code_rate-HP_stream 3 bslbf
		//	code_rate-LP_stream 3 bslbf
		//	guard_interval 2 bslbf
		//	transmission_mode 2 bslbf
		//	other_frequency_flag 1 bslbf
		//	reserved_future_use 32 bslbf

	    stream->frequency     = mpeg_getbits(desc+i+2,  0, 32) * 10;
	    stream->bandwidth     = bw[   mpeg_getbits(desc+i+2, 33, 2) ];
	    stream->constellation = co_t[ mpeg_getbits(desc+i+2, 40, 2) ];
	    stream->hierarchy     = hi[   mpeg_getbits(desc+i+2, 43, 2) ];
	    stream->code_rate_hp  = ra_t[ mpeg_getbits(desc+i+2, 45, 3) ];
	    stream->code_rate_lp  = ra_t[ mpeg_getbits(desc+i+2, 48, 3) ];
	    stream->guard         = gu[   mpeg_getbits(desc+i+2, 51, 2) ];
	    stream->transmission  = tr[   mpeg_getbits(desc+i+2, 54, 1) ];
	    stream->other_freq    = mpeg_getbits(desc+i+2, 55, 1);

if (dvb_debug>2)
	fprintf(stderr,
		"#@f terrestrial_delivery_system_descriptor: TSID %d freq=%d (other=%d) bw=%d (%s MHz) const=%d (%s) hier=%d (%s) rate hi=%d  (%s) rate lo=%d (%s) guard=%d (%s) tr=%d (%s) : up=%d tuned=%d\n",
		stream->tsid,
		stream->frequency,
		stream->other_freq,
		mpeg_getbits(desc+i+2, 33, 2),
		stream->bandwidth,
		mpeg_getbits(desc+i+2, 40, 2),
		stream->constellation,
		mpeg_getbits(desc+i+2, 43, 2),
		stream->hierarchy,
		mpeg_getbits(desc+i+2, 45, 3),
		stream->code_rate_hp,
		mpeg_getbits(desc+i+2, 48, 3),
		stream->code_rate_lp,
		mpeg_getbits(desc+i+2, 51, 2),
		stream->guard,
		mpeg_getbits(desc+i+2, 54, 1),
		stream->transmission,
		stream->updated, stream->tuned
		);
		
// Test where broadcast centre freq is invalid
#ifdef TEST_INVALID_CENTRE

		// mangle the real centre freq
		stream->frequency = stream->tsid ;

#endif


#ifdef TEST_MULTIFREQ

		// mangle the real centre freq
		stream->frequency = stream->tsid ;
		
	    // create freq list from table
		{
		int idx = (stream->tsid & 0xf000) >> 12 ;
		int num_freqs = other_freqs[idx][0] ;
    	unsigned int freq_index ;

if (dvb_debug>1)
	fprintf(stderr,
		"frequency_list_descriptor: num freqs=%d\n",
		num_freqs);
		
	    	
	    	stream->freq_list_len = num_freqs ;
	    	stream->freq_list = malloc(num_freqs * sizeof(int)) ;
	    	memset(stream->freq_list, 0, num_freqs * sizeof(int)) ;
		    for (freq_index=0; freq_index < num_freqs; ++freq_index) 
		    {
			int freq = other_freqs[idx][freq_index+1];
		
			    if (dvb_debug>1)
					fprintf(stderr,
						"frequency_list_descriptor: freq[%d]=%d\n",
						freq_index, freq);
	
				stream->freq_list[freq_index] = freq ;
		    }
	    
		}
#endif

if (dvb_debug > 1)
{
	fprintf(stderr,
		"terrestrial_delivery_system_descriptor:: Freq=%d\n",
		stream->frequency);
	
}
	    break;

	case 0x62: /* freq list */
		{
		unsigned int coding_type ;
		int num_freqs ;
	 
		//	frequency_list_descriptor(){
		//		descriptor_tag 8 uimsbf
		//		descriptor_length 8 uimsbf
		//		reserved_future_use 6 bslbf
		//		coding_type 2 bslbf
		//		for (i=0;I<N;i++){
		//			centre_frequency 32 uimsbf
		//		}
		//	}
		//	Table 54: Coding type values
		//	Coding_type Delivery system
		//	00 			not defined
		//	01 			satellite
		//	10 			cable
		//	11 			terrestrial

	    j = 0;
	    coding_type = mpeg_getbits(desc+i+2,  j+6, 2) ;
	    j+=8 ;
	    
	    num_freqs = (l - 1) / 4 ;

if (dvb_debug>1)
	fprintf(stderr,
		"frequency_list_descriptor: num freqs=%d\n",
		num_freqs);
		
	    if ((coding_type == 3) && (num_freqs > 0))
	    {
	    	unsigned int freq_index=0 ;
	    	
	    	stream->freq_list_len = num_freqs ;
	    	stream->freq_list = malloc(num_freqs * sizeof(int)) ;
	    	memset(stream->freq_list, 0, num_freqs * sizeof(int)) ;
		    while (j < l*8) 
		    {
			int freq ;
		
				freq = mpeg_getbits(desc+i+2,  j, 32) * 10 ;
		
			    if (dvb_debug>1)
					fprintf(stderr,
						"frequency_list_descriptor: freq[%d]=%d\n",
						freq_index, freq);
	
				stream->freq_list[freq_index++] = freq ;
		
				j += 32;
		    }
	    }
	    
		}
	    break;

#ifndef TEST_MULTIFREQ
	    
	case 0x83 : /* LCN */

	    j = 0;
	    while (j < l*8) 
	    {
		int sid, visible, lcn ;
	    struct prog_info  *pinfo;
		
	
			//	service_id 16 uimsbf
			//	visible_service_flag 1 bslbf
			//	reserved 5 bslbf
			//	logical_channel_number 10 uimsbf	
			sid			= mpeg_getbits(desc+i+2,  j, 16) ;
			visible		= mpeg_getbits(desc+i+2,  j+17, 1) ;
			lcn 		= mpeg_getbits(desc+i+2,  j+22, 10) ;
	
		    if (dvb_debug>1)
				fprintf(stderr,
					"#@p LCN: service_id=%d (0x%04x)  visible=%d  lcn=%d (0x%03x)\n",
					sid, sid, visible, lcn, lcn);
					
			pinfo = prog_info_get(stream, sid, 1) ;
			pinfo->visible = visible ;
			pinfo->lcn = lcn ;
	
			j += 32;
	    }

		break ;
#endif

		
	case 0x41:  /* service list descriptor */
	
		//service_list_descriptor(){
		//	descriptor_tag 8 uimsbf
		//	descriptor_length 8 uimsbf
		//	for (i=0;i<N;I++){
		//		service_id 16 uimsbf
		//		service_type 8 uimsbf
		//	}
		//}
	
	    j = 0;
	    while (j < l*8) 
	    {
		int sid, service_type ;
	    struct prog_info  *pinfo;
	
			sid				= mpeg_getbits(desc+i+2,  j, 16) ;
			service_type	= mpeg_getbits(desc+i+2,  j+17, 8) ;
	
		    if (dvb_debug>1)
				fprintf(stderr,
					"service_list_descriptor: service_id=%d (0x%04x)  service_type=%d (0x%02x)\n",
					sid, sid, service_type, service_type);

			pinfo = prog_info_get(stream, sid, 1) ;
			pinfo->service_type = service_type ;
	
			j += 24;
	    }
		break ;	
		
	}
    }
    return;
}

/* ----------------------------------------------------------------------- */
static void parse_sdt_desc(unsigned char *desc, int dlen,
			   struct psi_program *pr, int tuned_freq, int verbose)
{
    int i,t,l;
    char *name,*net;

    for (i = 0; i < dlen; i += desc[i+1] +2) {
	t = desc[i];
	l = desc[i+1];

	switch (t) {
	case 0x48:
	    pr->type = desc[i+2];
	    pr->updated = 1;
	    net = (char*)desc + i+3;
	    name = net + net[0] + 1;
	    mpeg_parse_psi_string(net+1,  net[0],  pr->net,  sizeof(pr->net));
	    mpeg_parse_psi_string(name+1, name[0], pr->name, sizeof(pr->name));

		if (verbose) fprintf(stderr,"    pnr %5d  %s\n", pr->pnr, pr->name);

	    if (dvb_debug > 2)
	    	fprintf(stderr,"#@p parse_sdt_desc() : tuned=%d : tsid=%d pnr=%d name=%s [v=%d a=%d]\n",
	    	tuned_freq,
	    	pr->tsid, pr->pnr, pr->name, pr->v_pid, pr->a_pid);
	    break;
	}
    }
}

/* ======================================================================= */
/* TABLES
 * 
 */

/* ----------------------------------------------------------------------- */
int mpeg_parse_psi_sdt(struct psi_info *info, unsigned char *data, int verbose, int tuned_freq)
{
    static const char *running[] = {
	[ 0       ] = "undefined",
	[ 1       ] = "not running",
	[ 2       ] = "starts soon",
	[ 3       ] = "pausing",
	[ 4       ] = "running",
	[ 5 ... 8 ] = "reserved",
    };
    struct psi_program *pr;
    int tsid,pnr,version,current;
    int j,len,dlen,run,ca;

    len     = mpeg_getbits(data,12,12) + 3 - 4;
    tsid    = mpeg_getbits(data,24,16);
    version = mpeg_getbits(data,42,5);
    current = mpeg_getbits(data,47,1);
    if (!current)
    	return len+4;
    if (info->tsid == tsid && info->sdt_version == version)
    	return len+4;
    info->sdt_version = version;

    if (verbose>1)
		fprintf_timestamp(stderr,
			"ts [sdt]: tsid %d ver %2d [%d/%d]\n",
			tsid, version,
			mpeg_getbits(data,48, 8),
			mpeg_getbits(data,56, 8));

    j = 88;
    while (j < len*8) {
		pnr  = mpeg_getbits(data,j,16);
		run  = mpeg_getbits(data,j+24,3);
		ca   = mpeg_getbits(data,j+27,1);
		dlen = mpeg_getbits(data,j+28,12);
		if (verbose > 2) {
			fprintf(stderr,"   (freq=%d) pnr %3d ca %d %s #",
				tuned_freq, pnr, ca, running[run]);
			mpeg_dump_desc(data+j/8+5,dlen);
			fprintf(stderr,"\n");
		}
		pr = psi_program_get(info, tsid, pnr, tuned_freq, 1);
		parse_sdt_desc(data+j/8+5,dlen,pr,tuned_freq, verbose);
		pr->running = run;
		pr->ca      = ca;
		j += 40 + dlen*8;
    }
    if (verbose > 2)
    	fprintf(stderr,"\n");
    return len+4;
}

/* ----------------------------------------------------------------------- */
//	network_information_section(){
//		table_id	8	uimsbf
//		section_syntax_indicator	1	bslbf
//		reserved_future_use	1	bslbf
//		reserved	2	bslbf
//		section_length	12	uimsbf
//		
//		network_id	16	uimsbf
//		reserved	2	bslbf
//		version_number	5	uimsbf
//		current_next_indicator	1	bslbf
//		section_number	8	uimsbf
//		last_section_number	8	uimsbf
//		
//		reserved_future_use	4	bslbf
//		network_descriptors_length	12	uimsbf
//		for(i=0;i<N;i++){
//			descriptor()
//		}
//		reserved_future_use	4	bslbf
//		transport_stream_loop_length	12	uimsbf
//		for(i=0;i<N;i++){
//			transport_stream_id	16	uimsbf
//			original_network_id	16	uimsbf
//			reserved_future_use	4	bslbf
//			transport_descriptors_length	12	uimsbf
//			for(j=0;j<N;j++){
//				descriptor()
//			}
//		}
//		CRC_32	32	rpchof
//	}
int mpeg_parse_psi_nit(struct psi_info *info, unsigned char *data, int verbose, int tuned_freq)
{
    struct psi_stream *stream;
    char network[PSI_STR_MAX] = "";
    int id,version,current,len;
    int j,dlen,tsid;


    len     = mpeg_getbits(data,12,12) + 3 - 4;
    id      = mpeg_getbits(data,24,16);		/* network_id */
    version = mpeg_getbits(data,42,5);
    current = mpeg_getbits(data,47,1);

    if (!current)
    	return len+4;

    if (0 /* info->id == id */ && info->nit_version == version)
    	return len+4;
    info->nit_version = version;

    j = 80;
    dlen = mpeg_getbits(data,68,12);
    parse_nit_desc_1(data + j/8, dlen, network, sizeof(network));

    if (verbose>1) {
		fprintf_timestamp(stderr,
			"ts [nit]: id %3d ver %2d [%d/%d] #",
			id, version,
			mpeg_getbits(data,48, 8),
			mpeg_getbits(data,56, 8));
		mpeg_dump_desc(data + j/8, dlen);
		fprintf(stderr,"\n");
    }
    j += 16 + 8*dlen;

    while (j < len*8) {
    	tsid = mpeg_getbits(data,j,16);
        dlen = mpeg_getbits(data,j+36,12);
		j += 48;
		
		stream = psi_stream_get(info, tsid, id, 1);	
		
		stream->updated = 1;
		if (network)
			strcpy(stream->net, network);
		parse_nit_desc_2(data + j/8, dlen, stream, tuned_freq);
		if (verbose > 2) {
			fprintf(stderr,"   tsid %3d #", tsid);
			mpeg_dump_desc(data + j/8, dlen);
			fprintf(stderr,"\n");
		}
		j += 8*dlen;
    }

    if (verbose > 2)
    	fprintf(stderr,"\n");

    return len+4;
}

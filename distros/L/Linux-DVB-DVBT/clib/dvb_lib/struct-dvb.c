#include <stdio.h>
#include <sys/ioctl.h>

#include <linux/dvb/frontend.h>
#include <linux/dvb/dmx.h>

/*#include "struct-dump.h"*/
#include "struct-dvb.h"

/* ---------------------------------------------------------------------- */

char *dvb_fe_type[] = {
	[ FE_QPSK ] = "QPSK (dvb-s)",
	[ FE_QAM  ] = "QAM  (dvb-c)",
	[ FE_OFDM ] = "OFDM (dvb-t)",
};

char *dvb_fe_status[32] = {
	"signal",
	"carrier",
	"viterbi",
	"sync",
	"lock",
	"timeout",
	"reinit",
};

char *dvb_fe_caps[32] = {
	"FE_CAN_INVERSION_AUTO",
	"FE_CAN_FEC_1_2",
	"FE_CAN_FEC_2_3",
	"FE_CAN_FEC_3_4",
	
	"FE_CAN_FEC_4_5",
	"FE_CAN_FEC_5_6",
	"FE_CAN_FEC_6_7",
	"FE_CAN_FEC_7_8",
	
	"FE_CAN_FEC_8_9",
	"FE_CAN_FEC_AUTO",
	"FE_CAN_QPSK",
	"FE_CAN_QAM_16",
	
	"FE_CAN_QAM_32",
	"FE_CAN_QAM_64",
	"FE_CAN_QAM_128",
	"FE_CAN_QAM_256",
	
	"FE_CAN_QAM_AUTO",
	"FE_CAN_TRANSMISSION_MODE_AUTO",
	"FE_CAN_BANDWIDTH_AUTO",
	"FE_CAN_GUARD_INTERVAL_AUTO",
	
	"FE_CAN_HIERARCHY_AUTO",
	"?","?","?",
	
	"?","?","?","?",
	
	"?",
	"FE_CAN_RECOVER",
	"FE_CAN_CLEAN_SETUP",
	"FE_CAN_MUTE_TS",
};

char *dvb_fe_bandwidth[] = {
	[ BANDWIDTH_AUTO  ] = "auto",
	[ BANDWIDTH_8_MHZ ] = "8 MHz",
	[ BANDWIDTH_7_MHZ ] = "7 MHz",
	[ BANDWIDTH_6_MHZ ] = "6 MHz",
};

char *dvb_fe_rates[] = {
	[ FEC_AUTO ] = "auto",
	[ FEC_1_2  ] = "1/2",
	[ FEC_2_3  ] = "2/3",
	[ FEC_3_4  ] = "3/4",
	[ FEC_4_5  ] = "4/5",
	[ FEC_5_6  ] = "5/6",
	[ FEC_6_7  ] = "6/7",
	[ FEC_7_8  ] = "7/8",
	[ FEC_8_9  ] = "8/9",
};

char *dvb_fe_modulation[] = {
	[ QAM_AUTO ] = "auto",
	[ QAM_16   ] = "16",
	[ QAM_32   ] = "32",
	[ QAM_64   ] = "64",
	[ QAM_128  ] = "128",
	[ QAM_256  ] = "256",
};

char *dvb_fe_transmission[] = {
	[ TRANSMISSION_MODE_AUTO ] = "auto",
	[ TRANSMISSION_MODE_2K   ] = "2k",
	[ TRANSMISSION_MODE_8K   ] = "8k",
};

char *dvb_fe_guard[] = {
	[ GUARD_INTERVAL_AUTO ] = "auto",
	[ GUARD_INTERVAL_1_4  ] = "1/4",
	[ GUARD_INTERVAL_1_8  ] = "1/8",
	[ GUARD_INTERVAL_1_16 ] = "1/16",
	[ GUARD_INTERVAL_1_32 ] = "1/32",
};

char *dvb_fe_hierarchy[] = {
	[ HIERARCHY_AUTO ] = "auto",
	[ HIERARCHY_NONE ] = "none",
	[ HIERARCHY_1 ]    = "1",
	[ HIERARCHY_2 ]    = "2",
	[ HIERARCHY_4 ]    = "3",
};

char *dvb_fe_inversion[] = {
	[ INVERSION_OFF  ] = "off",
	[ INVERSION_ON   ] = "on",
	[ INVERSION_AUTO ] = "auto",
};

/* ---------------------------------------------------------------------- */

char *dvb_dmx_input[] = {
	[ DMX_IN_FRONTEND      ] = "DMX_IN_FRONTEND",
	[ DMX_IN_DVR           ] = "DMX_IN_DVR",
};

char *dvb_dmx_output[] = {
	[ DMX_OUT_DECODER      ] = "DMX_OUT_DECODER",
	[ DMX_OUT_TAP          ] = "DMX_OUT_TAP",
	[ DMX_OUT_TS_TAP       ] = "DMX_OUT_TS_TAP",
};

char *dvb_dmx_pes_type[] = {
	[ DMX_PES_AUDIO0       ] = "DMX_PES_AUDIO0",
	[ DMX_PES_VIDEO0       ] = "DMX_PES_VIDEO0",
	[ DMX_PES_TELETEXT0    ] = "DMX_PES_TELETEXT0",
	[ DMX_PES_SUBTITLE0    ] = "DMX_PES_SUBTITLE0",
	[ DMX_PES_PCR0         ] = "DMX_PES_PCR0",
	[ DMX_PES_AUDIO1       ] = "DMX_PES_AUDIO1",
	[ DMX_PES_VIDEO1       ] = "DMX_PES_VIDEO1",
	[ DMX_PES_TELETEXT1    ] = "DMX_PES_TELETEXT1",
	[ DMX_PES_SUBTITLE1    ] = "DMX_PES_SUBTITLE1",
	[ DMX_PES_PCR1         ] = "DMX_PES_PCR1",
	[ DMX_PES_AUDIO2       ] = "DMX_PES_AUDIO2",
	[ DMX_PES_VIDEO2       ] = "DMX_PES_VIDEO2",
	[ DMX_PES_TELETEXT2    ] = "DMX_PES_TELETEXT2",
	[ DMX_PES_SUBTITLE2    ] = "DMX_PES_SUBTITLE2",
	[ DMX_PES_PCR2         ] = "DMX_PES_PCR2",
	[ DMX_PES_AUDIO3       ] = "DMX_PES_AUDIO3",
	[ DMX_PES_VIDEO3       ] = "DMX_PES_VIDEO3",
	[ DMX_PES_TELETEXT3    ] = "DMX_PES_TELETEXT3",
	[ DMX_PES_SUBTITLE3    ] = "DMX_PES_SUBTITLE3",
	[ DMX_PES_PCR3         ] = "DMX_PES_PCR3",
	[ DMX_PES_OTHER        ] = "DMX_PES_OTHER",
};

char *dvb_dmx_flags[32] = {
	[ DMX_CHECK_CRC       ] = "DMX_CHECK_CRC",
	[ DMX_ONESHOT         ] = "DMX_ONESHOT",
	[ DMX_IMMEDIATE_START ] = "DMX_IMMEDIATE_START",
};

/* ---------------------------------------------------------------------- */

/* ---------------------------------------------------------------------- */
/*
 * Local variables:
 * c-basic-offset: 8
 * End:
 */

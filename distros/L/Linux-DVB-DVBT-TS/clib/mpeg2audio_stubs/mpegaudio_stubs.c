/*
 * mpegaudio_stubs.c
 *
 *  Created on: 27 Oct 2010
 *      Author: sdprice1
 */

#include <stdint.h>

int l2_select_table(int bitrate, int nb_channels, int freq, int lsf) {return 0 ; }

int decode_init() {return 0; }
int decode_frame(void *data, int *data_size, uint8_t * buf, int buf_size) {return 0; }
int get_samplerate() {return 0; }
int get_channels() {return 0; }
int get_framesize() {return 0; }

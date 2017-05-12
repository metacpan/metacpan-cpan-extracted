/*
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#define MP3_BLOCK_SIZE    8192
#define MAX_FRAME_SIZE    2048

#define FILTER_MPEG1      0x0001
#define FILTER_MPEG2      0x0002
#define FILTER_MPEG25     0x0004
#define FILTER_LAYER1     0x0008
#define FILTER_LAYER2     0x0010
#define FILTER_LAYER3     0x0020
#define FILTER_32000HZ    0x0040
#define FILTER_44100HZ    0x0080
#define FILTER_48000HZ    0x0100
#define FILTER_MONO       0x0200
#define FILTER_STEREO     0x0400

#define ILLEGAL_MPEG_ID   1
#define MPEG1_ID          3
#define MPEG2_ID          2
#define MPEG25_ID         0
#define ILLEGAL_LAYER_ID  0
#define LAYER1_ID         3
#define LAYER2_ID         2
#define LAYER3_ID         1
#define ILLEGAL_SR        3
#define SR_32000HZ        2
#define SR_44100HZ        0
#define SR_48000HZ        1
#define MODE_MONO         3

#define UNKNOWN_START_SAMPLE -1

#define MIN_OVERLAP_SAMPLES_START  576
#define MIN_OVERLAP_SAMPLES_END    1152
#define MASK_ATH_KILL_NO_GAP_START 0x7F
#define MASK_ATH_KILL_NO_GAP_END   0xBF

// FRame REcord Size (in bytes)
#define FRRES             10

// Based on pcutmp3 FrameHeader
typedef struct mp3frame {
  int header32;
  int mpegID;
  int layerID;
  bool crc16_used;
  int bitrate_index;
  int samplingrate_index;
  bool padding;
  bool private_bit_set;
  int mode;
  int mode_extension;
  bool copyrighted;
  bool original;
  int emphasis;
  
  bool valid;
  
  int samplerate;
  int channels;
  int bitrate_kbps;
  int samples_per_frame;
  int bytes_per_slot;
  int frame_size;
} mp3frame;

typedef struct xiltframe {
  uint16_t frame_size;
  bool xing_tag;
  bool info_tag;
  bool lame_tag;
  uint16_t lame_tag_offset;
  uint16_t enc_delay;
  uint16_t enc_padding;
  uint32_t frame_count;
  Buffer *tag;
} xiltframe;

typedef struct mp3cut {
  PerlIO *fh;
  Buffer *buf;
  int filter;
  uint32_t offset;
  int32_t first_frame_offset; // offset to first MP3 frame (after ID3v2, other junk data)
  uint32_t music_frame_count;
  uint16_t max_res;
  uint16_t samples_per_frame;
  uint16_t enc_delay;
  uint16_t enc_padding;
  bool is_vbr;
  int64_t start_sample;
  uint32_t file_size;
  mp3frame *first_frame;
  mp3frame *curr_frame;
  xiltframe *xilt_frame;
  
  // Used for MLLT (MPEG Location Lookup Table)
  bool has_mllt;
  uint16_t max_frame_size;
  uint16_t min_frame_size;
  uint16_t last_frame_size;
  Buffer *mllt_buf;
  
  // Frame file offset lookup cache
  uint32_t cache_frame;
  uint32_t cache_offset;
  uint32_t cache_i;
  
  // Output variables
  uint32_t next_processed_frame;
  uint32_t first_frame_inclusive;
  uint32_t last_frame_exclusive;
  float avg_kbps;
  uint16_t new_enc_delay;
  uint16_t new_enc_padding;
  uint32_t musi_len;
  uint8_t mask_ath;
  uint16_t bit_res;
} mp3cut;

static const int bitrate_map[4][4][16] = {
  { { 0 }, //MPEG2.5
    { 0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, 0 },
    { 0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, 0 },
    { 0, 32, 48, 56, 64, 80, 96, 112, 128, 144, 160, 176, 192, 224, 256, 0 }
  },
  { { 0 } },
  { { 0 }, // MPEG2
    { 0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, 0 },
    { 0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, 0 },
    { 0, 32, 48, 56, 64, 80, 96, 112, 128, 144, 160, 176, 192, 224, 256, 0 }
  }, 
  { { 0 }, // MPEG1
    { 0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 0 },
    { 0, 32, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 384, 0 },
    { 0, 32, 64, 96, 128, 160, 192, 224, 256, 288, 320, 352, 384, 416, 448, 0 }
  }
};

// sample_rate[samplingrate_index]
static const int sample_rate_tbl[ ] = {
  44100, 48000, 32000, 0,
};

static const uint16_t CRC16_TABLE[256] = {
  0x0000, 0xC0C1, 0xC181, 0x0140, 0xC301, 0x03C0, 0x0280, 0xC241, 0xC601, 0x06C0, 0x0780,
  0xC741, 0x0500, 0xC5C1, 0xC481, 0x0440, 0xCC01, 0x0CC0, 0x0D80, 0xCD41, 0x0F00, 0xCFC1,
  0xCE81, 0x0E40, 0x0A00, 0xCAC1, 0xCB81, 0x0B40, 0xC901, 0x09C0, 0x0880, 0xC841, 0xD801,
  0x18C0, 0x1980, 0xD941, 0x1B00, 0xDBC1, 0xDA81, 0x1A40, 0x1E00, 0xDEC1, 0xDF81, 0x1F40,
  0xDD01, 0x1DC0, 0x1C80, 0xDC41, 0x1400, 0xD4C1, 0xD581, 0x1540, 0xD701, 0x17C0, 0x1680,
  0xD641, 0xD201, 0x12C0, 0x1380, 0xD341, 0x1100, 0xD1C1, 0xD081, 0x1040, 0xF001, 0x30C0,
  0x3180, 0xF141, 0x3300, 0xF3C1, 0xF281, 0x3240, 0x3600, 0xF6C1, 0xF781, 0x3740, 0xF501,
  0x35C0, 0x3480, 0xF441, 0x3C00, 0xFCC1, 0xFD81, 0x3D40, 0xFF01, 0x3FC0, 0x3E80, 0xFE41,
  0xFA01, 0x3AC0, 0x3B80, 0xFB41, 0x3900, 0xF9C1, 0xF881, 0x3840, 0x2800, 0xE8C1, 0xE981,
  0x2940, 0xEB01, 0x2BC0, 0x2A80, 0xEA41, 0xEE01, 0x2EC0, 0x2F80, 0xEF41, 0x2D00, 0xEDC1,
  0xEC81, 0x2C40, 0xE401, 0x24C0, 0x2580, 0xE541, 0x2700, 0xE7C1, 0xE681, 0x2640, 0x2200,
  0xE2C1, 0xE381, 0x2340, 0xE101, 0x21C0, 0x2080, 0xE041, 0xA001, 0x60C0, 0x6180, 0xA141,
  0x6300, 0xA3C1, 0xA281, 0x6240, 0x6600, 0xA6C1, 0xA781, 0x6740, 0xA501, 0x65C0, 0x6480,
  0xA441, 0x6C00, 0xACC1, 0xAD81, 0x6D40, 0xAF01, 0x6FC0, 0x6E80, 0xAE41, 0xAA01, 0x6AC0,
  0x6B80, 0xAB41, 0x6900, 0xA9C1, 0xA881, 0x6840, 0x7800, 0xB8C1, 0xB981, 0x7940, 0xBB01,
  0x7BC0, 0x7A80, 0xBA41, 0xBE01, 0x7EC0, 0x7F80, 0xBF41, 0x7D00, 0xBDC1, 0xBC81, 0x7C40,
  0xB401, 0x74C0, 0x7580, 0xB541, 0x7700, 0xB7C1, 0xB681, 0x7640, 0x7200, 0xB2C1, 0xB381,
  0x7340, 0xB101, 0x71C0, 0x7080, 0xB041, 0x5000, 0x90C1, 0x9181, 0x5140, 0x9301, 0x53C0,
  0x5280, 0x9241, 0x9601, 0x56C0, 0x5780, 0x9741, 0x5500, 0x95C1, 0x9481, 0x5440, 0x9C01,
  0x5CC0, 0x5D80, 0x9D41, 0x5F00, 0x9FC1, 0x9E81, 0x5E40, 0x5A00, 0x9AC1, 0x9B81, 0x5B40,
  0x9901, 0x59C0, 0x5880, 0x9841, 0x8801, 0x48C0, 0x4980, 0x8941, 0x4B00, 0x8BC1, 0x8A81,
  0x4A40, 0x4E00, 0x8EC1, 0x8F81, 0x4F40, 0x8D01, 0x4DC0, 0x4C80, 0x8C41, 0x4400, 0x84C1,
  0x8581, 0x4540, 0x8701, 0x47C0, 0x4680, 0x8641, 0x8201, 0x42C0, 0x4380, 0x8341, 0x4100,
  0x81C1, 0x8081, 0x4040
};

int _mp3cut_init(HV *self, mp3cut *mp3c);
int _mp3cut_filter_for(mp3frame *frame);
int _mp3cut_get_next_frame(mp3cut *mp3c, mp3frame *frame);
int _mp3cut_decode_frame(int header32, mp3frame *frame);
int _mp3cut_parse_xing(mp3cut *mp3c);
void _mp3cut_mllt_mark_frame(mp3cut *mp3c, uint16_t frame_size);
void _mp3cut_mllt_construct(mp3cut *mp3c);
uint32_t _mp3cut_mllt_get_frame_count(mp3cut *mp3c);
void _mp3cut_mllt_save(mp3cut *mp3c, const char *file);
void _mp3cut_mllt_load(mp3cut *mp3c, const char *file);
int _mp3cut_read(HV *self, mp3cut *mp3c, SV *buf, int buf_size);
void _mp3cut_skip_id3v2(mp3cut *mp3c);
void _mp3cut_skip(mp3cut *mp3c, uint32_t size);
void _mp3cut_construct_reservoir_frame(mp3cut *mp3c, Buffer *res_frame, uint32_t min_res_size, uint64_t abs_start_sample);
void _mp3cut_construct_xing_frame(mp3cut *mp3c, Buffer *xing_frame, uint32_t frame_count, Buffer *seektable);
void _mp3cut_silence_frame(mp3cut *mp3c);

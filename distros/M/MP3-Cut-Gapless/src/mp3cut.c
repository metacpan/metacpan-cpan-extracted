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

#include "mp3cut.h"

static uint16_t
_crc16(uint16_t crc, uint8_t value)
{
  uint32_t tmp = crc ^ value;
  crc = (crc >> 8) ^ CRC16_TABLE[tmp & 0xFF];
  return crc;
}

static uint32_t
_get_side_info_start(mp3frame *frame)
{
  return frame->crc16_used ? 6 : 4;
}

static uint32_t
_get_side_info_size(mp3frame *frame)
{
  if (frame->mpegID == MPEG1_ID) {
    return frame->channels == 2 ? 32 : 17;
  }
  else {
    return frame->channels == 2 ? 17 : 9;
  }
}

static uint32_t
_get_side_info_end(mp3frame *frame)
{
  return _get_side_info_start(frame) + _get_side_info_size(frame);
}

static uint32_t
_get_frame_file_offset(mp3cut *mp3c, uint32_t frame_index)
{
  uint32_t offset = mp3c->first_frame_offset;
  unsigned char *bptr = buffer_ptr(mp3c->mllt_buf);
  uint32_t max_frame_size = get_u24(&bptr[2]);
  uint32_t bits_for_bytes = bptr[8];
  int f = 1;
  int i = 10;
  
  // If the file has a Xing/Info tag, we really want frame_index + 1
  if (mp3c->xilt_frame->xing_tag || mp3c->xilt_frame->info_tag)
    frame_index++;

  // Improve performance of sequential offset lookups by caching the previous
  // lookup values
  if (mp3c->cache_frame && mp3c->cache_frame <= frame_index) {
    f = mp3c->cache_frame + 1;
    offset = mp3c->cache_offset;
    i = mp3c->cache_i;
    //DEBUG_TRACE("Using cached frame %d offset %d i %d\n", mp3c->cache_frame, offset, i);
  }
    
  // frame_index of 0 will be 0 (start of file)
  
  while (f <= frame_index) {
    switch (bits_for_bytes) {
      case 4:
        if (f % 2 != 0) {
          offset += max_frame_size - ((bptr[i] & 0xF0) >> 4);
        }
        else {
          offset += max_frame_size - (bptr[i] & 0xF);
          i++;
        }
        break;
      case 8:
        offset += max_frame_size - bptr[i++];
        break;
      case 12:      
        if (f % 2 != 0) {
          offset += max_frame_size - (((bptr[i] & 0xFF) << 4) | ((bptr[i+1] & 0xF0) >> 4));
          i++;
        }
        else {
          offset += max_frame_size - (((bptr[i] & 0x0F) << 8) | (bptr[i+1] & 0xFF));
          i += 2;
        }
        break;
    }
    
    f++;
  }
  
  // Cache offsets to speed up sequential access
  mp3c->cache_frame = frame_index;
  mp3c->cache_offset = offset;
  mp3c->cache_i = i;
  
  DEBUG_TRACE("MLLT offset(%d) = %d\n", frame_index, offset);
  
  return offset;
}

static void
_set_curr_frame(mp3cut *mp3c, uint32_t frame_index)
{
  uint32_t frame_offset = _get_frame_file_offset(mp3c, frame_index);
  int fh32;
  
  if (frame_offset >= mp3c->offset) {
    DEBUG_TRACE("_set_curr_frame(%d), skipping to %d\n", frame_index, frame_offset);
    _mp3cut_skip(mp3c, frame_offset - mp3c->offset);
  }
  else {
    // Seek directly
    DEBUG_TRACE("_set_curr_frame(%d), seeking to %d\n", frame_index, frame_offset);
    buffer_clear(mp3c->buf);
    PerlIO_seek(mp3c->fh, frame_offset, SEEK_SET);
  }
  
  // Make sure the header is loaded
  if ( !_check_buf(mp3c->fh, mp3c->buf, 4, MP3_BLOCK_SIZE) ) {
    croak("Unable to read frame %d", frame_index);
  }
  
  // Parse frame header
  fh32 = get_u32( buffer_ptr(mp3c->buf) );
  if ( !_mp3cut_decode_frame(fh32, mp3c->curr_frame) ) {
    // we got the wrong offset, this should never happen
    croak("Invalid frame offset %d for frame %d (%x)", frame_offset, frame_index, fh32);
  }
  
  // Make sure the entire frame is loaded
  if ( !_check_buf(mp3c->fh, mp3c->buf, mp3c->curr_frame->frame_size, MP3_BLOCK_SIZE) ) {
    croak("Unable to read frame %d", frame_index);
  }
  
  mp3c->offset = frame_offset;
}

static uint16_t
_get_frame_size(mp3cut *mp3c)
{
  return mp3c->curr_frame->frame_size;
}

static uint16_t
_get_bit_res_ptr(mp3cut *mp3c)
{
  unsigned char *bptr = buffer_ptr(mp3c->buf);
  uint8_t sis = _get_side_info_start(mp3c->curr_frame);
  uint16_t br_pointer = bptr[sis] & 0xFF;
  
  if (mp3c->curr_frame->mpegID == MPEG1_ID)
    br_pointer = (br_pointer << 1) | ((bptr[sis+1] & 0x80) >> 7);
  
  return br_pointer;
}

static uint16_t
_get_main_data_size(mp3cut *mp3c)
{
  return mp3c->curr_frame->frame_size 
    - _get_side_info_start(mp3c->curr_frame)
    - _get_side_info_size(mp3c->curr_frame);
}

int
_mp3cut_init(HV *self, mp3cut *mp3c)
{
  PerlIO *fh = IoIFP(sv_2io(*(my_hv_fetch(self, "_fh"))));
  mp3frame *frame;
  bool first_frame_found = FALSE;
  int firstkbps = 0;
  int frame_counter = 0;
  unsigned char *bptr;
  bool check_bitrate = TRUE;
  
  Newz(0, frame, sizeof(mp3frame), mp3frame);
  
  mp3c->fh                   = fh;
  mp3c->filter               = 0; // Bug 17441, used to be FILTER_LAYER3 but we need to detect non-MP3 files and abort
  mp3c->offset               = 0;
  mp3c->first_frame_offset   = -1;
  mp3c->music_frame_count    = 0;
  mp3c->max_res              = 0;
  mp3c->samples_per_frame    = 0;
  mp3c->enc_delay            = 576;
  mp3c->enc_padding          = 576 * 3;
  mp3c->is_vbr               = FALSE;
  mp3c->start_sample         = UNKNOWN_START_SAMPLE;
  mp3c->file_size            = _file_size(fh);
  mp3c->next_processed_frame = 0;
  
  mp3c->has_mllt = FALSE;
  mp3c->max_frame_size = 0;
  mp3c->min_frame_size = 0;
  mp3c->last_frame_size = 0;
  
  mp3c->cache_frame = 0;
  mp3c->cache_offset = 0;
  mp3c->cache_i = 0;
  
  // Load cache file if available
  if (my_hv_exists(self, "cache_file")) {
    char *cache = SvPVX(*(my_hv_fetch(self, "cache_file")));
    // XXX add -e test
    _mp3cut_mllt_load(mp3c, cache);
  }
  
  // Seek past ID3 tag
  _mp3cut_skip_id3v2(mp3c);
  
  while ( _mp3cut_get_next_frame(mp3c, frame) ) {
    bptr = buffer_ptr(mp3c->buf);
    
    // Track all frame sizes for MLLT
    // Don't call if we loaded MLLT from cache
    if (!mp3c->has_mllt)
      _mp3cut_mllt_mark_frame(mp3c, frame->frame_size);
    
    if (!first_frame_found) {
      first_frame_found = TRUE;
      firstkbps = frame->bitrate_kbps;
      mp3c->samples_per_frame = frame->samples_per_frame;
      mp3c->max_res = frame->mpegID == MPEG1_ID ? 511 : 255;
      Copy(frame, mp3c->first_frame, 1, mp3frame);
      
      // Tweak filter to make it match frames like this one
      mp3c->filter = _mp3cut_filter_for(frame);
      
      // Parse Xing/Info/LAME tag
      if ( _mp3cut_parse_xing(mp3c) ) {
        if (mp3c->xilt_frame->xing_tag) {
          DEBUG_TRACE("File has Xing tag, is VBR\n");
          mp3c->is_vbr = TRUE;
        }
        frame_counter--;
        if (mp3c->xilt_frame->lame_tag) {
          mp3c->enc_delay   = mp3c->xilt_frame->enc_delay;
          mp3c->enc_padding = mp3c->xilt_frame->enc_padding;
        }
      }
    }
    else {
      if (frame_counter == 0) {
        int sie;
        bool pcut_frame;
        
        check_bitrate = FALSE;
        
        // first music frame, might be a PCUT-tag
        // reservoir-filler frame
        sie = _get_side_info_end(frame);
        
        pcut_frame = (sie + 10 <= frame->frame_size)
          && (bptr[sie]   == 'P')
          && (bptr[sie+1] == 'C')
          && (bptr[sie+2] == 'U')
          && (bptr[sie+3] == 'T');
        
        if (pcut_frame) {
          // bptr[sie+4] tag revision (always 0 for now)
          int64_t t = bptr[sie + 5]; // fetch 40-bit start sample
          t = (t << 8) | (bptr[sie + 6] & 0xFF);
          t = (t << 8) | (bptr[sie + 7] & 0xFF);
          t = (t << 8) | (bptr[sie + 8] & 0xFF);
          t = (t << 8) | (bptr[sie + 9] & 0xFF);
          mp3c->start_sample = t;
          
          DEBUG_TRACE("Found PCUT tag, start sample %llu\n", mp3c->start_sample);
        }
        else {
          int o, e;
          for (o = _get_side_info_start(frame), e = _get_side_info_end(frame); o < e; o++) {
            if (bptr[o] != 0) {
              check_bitrate = TRUE;
              break;
            }
          }
        }
      }
      // we don't want the first "music frame" to be checked if it's possibly a PCUT generated reservoir frame
      if (check_bitrate && frame->bitrate_kbps != firstkbps) {
        DEBUG_TRACE("Bitrate changed, file is VBR\n");
        mp3c->is_vbr = TRUE;
        check_bitrate = FALSE;
      }
    }
    
    // Break out if we have a cache file
    if (mp3c->has_mllt && frame_counter >= 0) {
      frame_counter += _mp3cut_mllt_get_frame_count(mp3c);
      
      if (mp3c->xilt_frame->xing_tag || mp3c->xilt_frame->info_tag)
        frame_counter--;
      
      break;
    }
    
    frame_counter++;
    
    mp3c->offset += frame->frame_size;
    if (mp3c->offset > mp3c->file_size)
      mp3c->offset = mp3c->file_size;
    
    _mp3cut_skip(mp3c, frame->frame_size);
  }
  
  mp3c->music_frame_count = frame_counter;
  
  DEBUG_TRACE("Frame count: %u\n", frame_counter);

  Safefree(frame);
  
  // Construct MLLT data, unless we have this from cache
  if (!mp3c->has_mllt) {
    _mp3cut_mllt_construct(mp3c);
    
    mp3c->has_mllt = TRUE;
  
    // Save cache file if requested
    if (my_hv_exists(self, "cache_file")) {
      char *file = SvPVX(*(my_hv_fetch(self, "cache_file")));
      _mp3cut_mllt_save(mp3c, file);
    }
  }
  
  return 1;
}

static void
_mp3cut_setup_filter(int filter, int *masker, int *masked)
{
  *masker = 0xFFE00000;
  *masked = 0xFFE00000;
  
  if ((filter & FILTER_MPEG1) != 0) {
    *masker |= 0x00180000;
    *masked |= 0x00180000;
  }
  else if ((filter & FILTER_MPEG2) != 0) {
    *masker |= 0x00180000;
    *masked |= 0x00100000;
  }
  
  if ((filter & FILTER_LAYER1) != 0) {
    *masker |= 0x00060000;
    *masked |= 0x00060000;
  }
  else if ((filter & FILTER_LAYER2) != 0) {
    *masker |= 0x00060000;
    *masked |= 0x00040000;
  }
  else if ((filter & FILTER_LAYER3) != 0) {
    *masker |= 0x00060000;
    *masked |= 0x00020000;
  }
  
  if ((filter & FILTER_32000HZ) != 0) {
    *masker |= 0x00000C00;
    *masked |= 0x00000800;
  }
  else if ((filter & FILTER_44100HZ) != 0) {
    *masker |= 0x00000C00;
    *masked |= 0x00000000;
  }
  else if ((filter & FILTER_48000HZ) != 0) {
    *masker |= 0x00000C00;
    *masked |= 0x00000400;
  }
  
  if ((filter & FILTER_MONO) != 0) {
    *masker |= 0x000000C0;
    *masked |= 0x000000C0;
  }
}

int
_mp3cut_filter_for(mp3frame *frame)
{
  int filter = 0;
  
  if ( !frame->valid )
    return 0;
  
  switch (frame->mpegID) {
    case MPEG1_ID:
      filter |= FILTER_MPEG1;
      break;
    case MPEG2_ID:
      filter |= FILTER_MPEG2;
      break;
    case MPEG25_ID:
      filter |= FILTER_MPEG25;
      break;
  }
  
  if (frame->channels == 1)
    filter |= FILTER_MONO;
  else
    filter |= FILTER_STEREO;
  
  switch (frame->samplingrate_index) {
    case SR_32000HZ:
      filter |= FILTER_32000HZ;
      break;
    case SR_44100HZ:
      filter |= FILTER_44100HZ;
      break;
    case SR_48000HZ:
      filter |= FILTER_48000HZ;
      break;
  }
  
  switch (frame->layerID) {
    case LAYER1_ID:
      filter |= FILTER_LAYER1;
      break;
    case LAYER2_ID:
      filter |= FILTER_LAYER2;
      break;
    case LAYER3_ID:
      filter |= FILTER_LAYER3;
      break;
  }
  
  return filter;
}

int
_mp3cut_get_next_frame(mp3cut *mp3c, mp3frame *frame)
{
  int masker, masked;
  int ret = 0;
  unsigned char *bptr;
  int len;
  int i = 0;
  
  if ((int)(mp3c->file_size - mp3c->offset) < 10) {
    // Reached the end of the file
    goto out;
  }
  
  if ( !_check_buf(mp3c->fh, mp3c->buf, 10, MP3_BLOCK_SIZE) ) {
    goto out;
  }
  
  _mp3cut_setup_filter(mp3c->filter, &masker, &masked);
  
  bptr = buffer_ptr(mp3c->buf);
  len = buffer_len(mp3c->buf);
  
  for (i = 0; i < len - 4; i++) {
    if ( bptr[i] == 0xFF ) {
      // sync-word
      int header32 = bptr[i] << 24 | bptr[i+1] << 16 | bptr[i+2] << 8 | bptr[i+3];
      
      if ((header32 & masker) == masked) {
        // header
        DEBUG_TRACE("header @ %d: %x\n", i, header32);
        
        if ( _mp3cut_decode_frame(header32, frame) ) {
          // Abort if this is not an MP3 frame, we can't process layer 1 or layer 2 files
          if (frame->layerID != LAYER3_ID)
            croak("Cannot gaplessly process file, the first frame was not an MP3 frame.\n");
          
          // valid frame, skip to it in the buffer
          buffer_consume(mp3c->buf, i);
          mp3c->offset += i;
          
          // Remember the first frame's offset
          if (mp3c->first_frame_offset == -1)
            mp3c->first_frame_offset = mp3c->offset;
          
          DEBUG_TRACE("Frame @ %d: %dkbps %dkHz size %d\n", mp3c->offset, frame->bitrate_kbps, frame->samplerate, frame->frame_size);
          
          ret = 1;
          goto out;
        }
      }
    }
  }
  
  buffer_clear(mp3c->buf);
  
out:
  return ret;
}

int
_mp3cut_decode_frame(int header32, mp3frame *frame)
{
  frame->header32 = header32;
  
  frame->mpegID             = (frame->header32 >> 19) & 3;
  frame->layerID            = (frame->header32 >> 17) & 3;
  frame->crc16_used         = (frame->header32 & 0x00010000) == 0;
  frame->bitrate_index      = (frame->header32 >> 12) & 0xF;
  frame->samplingrate_index = (frame->header32 >> 10) & 3;
  frame->padding            = (frame->header32 & 0x00000200) != 0;
  frame->private_bit_set    = (frame->header32 & 0x00000100) != 0;
  frame->mode               = (frame->header32 >> 6) & 3;
  frame->mode_extension     = (frame->header32 >> 4) & 3;
  frame->copyrighted        = (frame->header32 & 0x00000008) != 0;
  frame->original           = (frame->header32 & 0x00000004) == 0; // bit set -> copy
  frame->emphasis           = frame->header32 & 3;
  
  frame->valid = (frame->mpegID != ILLEGAL_MPEG_ID) 
    && (frame->layerID != ILLEGAL_LAYER_ID)
    && (frame->bitrate_index != 0)
    && (frame->bitrate_index != 15)
    && (frame->samplingrate_index != ILLEGAL_SR);
  
  if (!frame->valid) {
    return 0;
  }
  
  frame->samplerate = sample_rate_tbl[ frame->samplingrate_index ];
  
  if (frame->mpegID == MPEG2_ID)
    frame->samplerate >>= 1; // 16,22,48 kHz
  
  if (frame->mpegID == MPEG25_ID)
    frame->samplerate >>= 2; // 8,11,24 kHz
  
  frame->channels = (frame->mode == MODE_MONO) ? 1 : 2;
  
  frame->bitrate_kbps = bitrate_map[ frame->mpegID ][ frame->layerID ][ frame->bitrate_index ];
  
  if (frame->layerID == LAYER1_ID) {
    // layer 1: always 384 samples/frame and 4byte-slots
    frame->samples_per_frame = 384;
    frame->bytes_per_slot = 4;
  }
  else {
    // layer 2: always 1152 samples/frame
    // layer 3: MPEG1: 1152 samples/frame, MPEG2/2.5: 576 samples/frame
    frame->samples_per_frame = ((frame->mpegID == MPEG1_ID) || (frame->layerID == LAYER2_ID)) ? 1152 : 576;
    frame->bytes_per_slot = 1;
  }
  
  frame->frame_size = ((frame->bitrate_kbps * 125) * frame->samples_per_frame) / frame->samplerate;
  
  if (frame->bytes_per_slot > 1)
    frame->frame_size -= frame->frame_size % frame->bytes_per_slot;
  
  if (frame->padding)
    frame->frame_size += frame->bytes_per_slot;

  return 1;
}

int
_mp3cut_parse_xing(mp3cut *mp3c)
{
  mp3frame frame;
  int ofs = 0;
  unsigned char *data = buffer_ptr(mp3c->buf);
  int fh32 = get_u32(data);
  uint8_t flags;
  int tag_end_ofs;
  int crc = 0;
  int i, t;
  
  _mp3cut_decode_frame(fh32, &frame);
  
  ofs += 4 + _get_side_info_size(&frame);
  
  mp3c->xilt_frame->xing_tag    = (data[ofs] == 'X' && data[ofs+1] == 'i' && data[ofs+2] == 'n' && data[ofs+3] == 'g');
  mp3c->xilt_frame->info_tag    = (data[ofs] == 'I' && data[ofs+1] == 'n' && data[ofs+2] == 'f' && data[ofs+3] == 'o');
  mp3c->xilt_frame->lame_tag    = FALSE;
  mp3c->xilt_frame->frame_count = 0;
  
#ifdef AUDIO_SCAN_DEBUG
  if (mp3c->xilt_frame->xing_tag) {
    DEBUG_TRACE("Valid Xing tag found\n");
  }
  else if (mp3c->xilt_frame->info_tag) {
    DEBUG_TRACE("Valid Info tag found\n");
  }
#endif
  
  if ( !mp3c->xilt_frame->xing_tag && !mp3c->xilt_frame->info_tag ) {
    DEBUG_TRACE("No Xing/Info tag found\n");
    return 0;
  }
  
  ofs += 4;
  
  mp3c->xilt_frame->frame_size = frame.frame_size;
  
  buffer_init(mp3c->xilt_frame->tag, frame.frame_size);
  Copy( buffer_ptr(mp3c->buf), buffer_ptr(mp3c->xilt_frame->tag), frame.frame_size, uint8_t );
  mp3c->xilt_frame->tag->end = frame.frame_size;
  
  flags = data[ofs+3] & 0xFF;
  ofs += 4;
  
  if ((flags & 0x01) != 0) {
    unsigned char *f = data + ofs;
    mp3c->xilt_frame->frame_count = GET_INT32BE(f);
    ofs += 4;
    DEBUG_TRACE("Xing Frames: %d\n", mp3c->xilt_frame->frame_count);
  }
  
  if ((flags & 0x02) != 0)
    ofs += 4; // skip byte count
  if ((flags & 0x04) != 0)
    ofs += 100; // skip seek table
  if ((flags & 0x08) != 0)
    ofs += 4; // skip VBR scale
  
  tag_end_ofs = ofs + 0x24;
  
  for (i = 0; i < tag_end_ofs - 2; i++)
    crc = _crc16(crc, data[i] & 0xFF);
  
  mp3c->xilt_frame->lame_tag = (data[ofs] == 'L' && data[ofs+1] == 'A' && data[ofs+2] == 'M' && data[ofs+3] == 'E');
  
  if ( !mp3c->xilt_frame->lame_tag ) {
    mp3c->xilt_frame->lame_tag = (data[ofs] = 'G' && data[ofs+1] == 'O' && data[ofs+2] == 'G' && data[ofs+3] == 'O');
  }
  
  // Verify CRC16
  if (((((data[tag_end_ofs - 2] << 8) | (data[tag_end_ofs - 1] & 0xFF)) ^ crc) & 0xFFFF) != 0) {
    mp3c->xilt_frame->lame_tag = FALSE;
  }
  
  if (mp3c->xilt_frame->lame_tag) {
    mp3c->xilt_frame->lame_tag_offset = ofs - 4;
    DEBUG_TRACE("Valid LAME tag found\n");
  }
  
  // Read delay/padding
  ofs += 0x15;
  t = data[ofs+1] & 0xFF;
  mp3c->xilt_frame->enc_delay   = ((data[ofs] & 0xFF) << 4) | (t >> 4);
  mp3c->xilt_frame->enc_padding = ((t & 0x0F) << 8) | (data[ofs+2] & 0xFF);
  
  if ( !mp3c->xilt_frame->lame_tag ) {
    if (mp3c->xilt_frame->enc_delay > 2880 || mp3c->xilt_frame->enc_padding > 2304) {
      mp3c->xilt_frame->enc_delay = 576;
      mp3c->xilt_frame->enc_padding = 0;
    }
  }
  
  DEBUG_TRACE("  LAME delay %d, padding %d\n", mp3c->xilt_frame->enc_delay, mp3c->xilt_frame->enc_padding);
  
  return 1;
}

void
_mp3cut_mllt_mark_frame(mp3cut *mp3c, uint16_t frame_size)
{
  // Track min/max frame size
  if (frame_size > mp3c->max_frame_size) {
    mp3c->max_frame_size = frame_size;
    DEBUG_TRACE("max_frame_size set to %d\n", mp3c->max_frame_size);
  }
  
  if (!mp3c->min_frame_size || frame_size < mp3c->min_frame_size) {
    mp3c->min_frame_size = frame_size;
    DEBUG_TRACE("min_frame_size set to %d\n", mp3c->min_frame_size);
  }
  
  mp3c->last_frame_size = frame_size;
  
  // Store frame offset, this assumes we are called in frame order
  buffer_put_int(mp3c->mllt_buf, mp3c->offset);
}

void
_mp3cut_mllt_construct(mp3cut *mp3c)
{
  uint16_t max_frame_deviation = 0;
  uint32_t ms_per_frame = 0;
  uint8_t bits_for_bytes = 0;
  unsigned char *bptr = buffer_ptr(mp3c->mllt_buf);
  uint32_t mllt_buf_len = buffer_len(mp3c->mllt_buf);
  uint32_t o = 0; // 32-bit offsets
  uint32_t m = 0; // packed MLLT offsets
  uint32_t f = 0; // frame count
  
  /*
  MPEG frames between reference  $xx xx       $00 $01
  Bytes between reference        $xx xx xx    <max frame size in file>
  Milliseconds between reference $xx xx xx    <ms per frame (rounded)>
  Bits for bytes deviation       $xx          <max needed to represent max deviation>
  Bits for milliseconds dev.     $xx          $00 (ms/frame is constant)
  (bits + bits must = multiple of 4)

  Then for every reference the following data is included;
   Deviation in bytes         %xxx....
   Deviation in milliseconds  %xxx....
  */
  
  max_frame_deviation = mp3c->max_frame_size - mp3c->min_frame_size;
  ms_per_frame = (int)(mp3c->first_frame->samplerate / mp3c->first_frame->samples_per_frame);
  
  // Should never have a deviation > 4095 (12 bits)
  if (max_frame_deviation > 0xFF)
    bits_for_bytes = 12;
  else if (max_frame_deviation > 0xF)
    bits_for_bytes = 8;
  else
    bits_for_bytes = 4;
  
  // We could get even more efficient here for CBR files,
  // but this is necessary to match the MLLT spec which requires multiples of 4
  
  DEBUG_TRACE("max_frame_deviation %d, ms_per_frame %d, bits_for_bytes %d\n", max_frame_deviation, ms_per_frame, bits_for_bytes);
  
  // Replace the 32-bit offset values in mllt_buf with packed byte deviation data
  for (o = 0; o <= mllt_buf_len - 4; o += 4) {
    uint32_t offset = get_u32(&bptr[o]);
    uint32_t next_offset;
    
    if (o <= mllt_buf_len - 8)
      next_offset = get_u32(&bptr[o+4]);
    else
      next_offset = offset + mp3c->last_frame_size;
    
    if (bits_for_bytes == 8) {
      // simple case
      // XXX need test
      bptr[m++] = (uint8_t)(mp3c->max_frame_size - (next_offset - offset));
    }
    else if (bits_for_bytes == 4) {
      uint8_t dev = (mp3c->max_frame_size - (next_offset - offset)) & 0xF;
      if (f % 2 == 0) {
        bptr[m] = dev;
      }
      else {
        bptr[m] = (bptr[m] << 4) | dev;
        m++;
      }
    }
    else { // 12 bits
      uint16_t dev = (uint16_t)(mp3c->max_frame_size - (next_offset - offset)) & 0xFFF;
      if (f % 2 == 0) {
        bptr[m]   = (dev >> 4) & 0xFF;
        bptr[m+1] = (dev & 0xF) << 4;
        m += 2;
      }
      else {
        bptr[m-1] = bptr[m-1] | ((dev >> 8) & 0xF);
        bptr[m]   = dev & 0xFF;
        m++;
      }
    }
    
    f++;
  }
  
  // Add space for the 10-byte MLLT header info
  Move(mp3c->mllt_buf->buf, mp3c->mllt_buf->buf + 10, m, unsigned char);
  
  // Construct MLLT header
  put_u16(&bptr[0], 1);                    // Frames between reference, always 1
  put_u24(&bptr[2], mp3c->max_frame_size); // Bytes between reference
  put_u24(&bptr[5], ms_per_frame);         // Milliseconds between reference
  bptr[8] = bits_for_bytes;                // Bits for bytes deviation
  bptr[9] = 0;                             // Bits for milliseconds deviation  
  
  mp3c->mllt_buf->end = m + 10;
  
  DEBUG_TRACE("MLLT data encoded to %d bytes\n", buffer_len(mp3c->mllt_buf));
  //buffer_dump(mp3c->mllt_buf, 0);
}

uint32_t
_mp3cut_mllt_get_frame_count(mp3cut *mp3c)
{
  unsigned char *bptr = buffer_ptr(mp3c->mllt_buf);
  uint8_t bits_for_bytes = bptr[8];
  
  return ((buffer_len(mp3c->mllt_buf) - 10) * 8) / bits_for_bytes;
}

void
_mp3cut_mllt_save(mp3cut *mp3c, const char *file)
{
  PerlIO *cache = PerlIO_open(file, "w");
  if (cache == NULL) {
    warn("Unable to open cache file %s for writing: %s\n", file, strerror(errno));
  }
  else {
    unsigned char *bptr = buffer_ptr(mp3c->mllt_buf);
    int n = 1;
    int buf_size = buffer_len(mp3c->mllt_buf);
  
    while (n > 0 && buf_size > 0) {
      n = PerlIO_write(cache, bptr, buf_size > MP3_BLOCK_SIZE ? MP3_BLOCK_SIZE : buf_size);
      bptr += n;
      buf_size -= n;
    }
  
    if (n < 0) {
      // XXX error writing, wipe cache file and warn
    }
    else {
      DEBUG_TRACE("Saved MLLT cache file\n");
    }
  
    PerlIO_close(cache);
  }
}

void
_mp3cut_mllt_load(mp3cut *mp3c, const char *file)
{
  PerlIO *cache = PerlIO_open(file, "r");
  if (cache == NULL) {
    //warn("Unable to open cache file %s for reading: %s\n", file, strerror(errno));
  }
  else {
    int read;
    off_t mllt_file_size = _file_size(cache);
    void *buf = buffer_append_space(mp3c->mllt_buf, mllt_file_size);
    
    if ( (read = PerlIO_read(cache, buf, mllt_file_size)) != mllt_file_size ) {
      if ( PerlIO_error(cache) ) {
        warn("Error reading cache file: %s\n", strerror(errno));
      }
      else {
        warn("Error: Unable to read entire cache file.\n");
      }
      PerlIO_close(cache);
      return;
    }
    
    PerlIO_close(cache);
    
    mp3c->has_mllt = TRUE;
    
    DEBUG_TRACE("Loaded MLLT cache file\n");
  }
}   
    
void
_mp3cut_skip_id3v2(mp3cut *mp3c)
{
  unsigned char *bptr;
  uint32_t id3_size = 0;
  
  if ( !_check_buf(mp3c->fh, mp3c->buf, 10, MP3_BLOCK_SIZE) ) {
    return;
  }
  
  bptr = buffer_ptr(mp3c->buf);
  if (
    (bptr[0] == 'I' && bptr[1] == 'D' && bptr[2] == '3') &&
    bptr[3] < 0xff && bptr[4] < 0xff &&
    bptr[6] < 0x80 && bptr[7] < 0x80 && bptr[8] < 0x80 && bptr[9] < 0x80
  ) {
    id3_size = 10 + (bptr[6]<<21) + (bptr[7]<<14) + (bptr[8]<<7) + bptr[9];

    if (bptr[5] & 0x10) {
      // footer present
      id3_size += 10;
    }
    
    DEBUG_TRACE("Skipping ID3v2 tag, size %d\n", id3_size);
    
    _mp3cut_skip(mp3c, id3_size);
    
    mp3c->offset = id3_size;
  }
}

void
_mp3cut_skip(mp3cut *mp3c, uint32_t size)
{
  if ( buffer_len(mp3c->buf) >= size ) {
    buffer_consume(mp3c->buf, size);
    
    //DEBUG_TRACE("  skipped buffer data size %d\n", size);
  }
  else {
    PerlIO_seek(mp3c->fh, size - buffer_len(mp3c->buf), SEEK_CUR);
    buffer_clear(mp3c->buf);
    
    //DEBUG_TRACE("  seeked past %d bytes to %d\n", size, (int)PerlIO_tell(mp3c->fh));
  }
}

int
_mp3cut_read(HV *self, mp3cut *mp3c, SV *buf, int buf_size)
{
  // Initialize buf SV
  sv_setpvn(buf, "", 0);
  
  if ( mp3c->next_processed_frame == 0 ) {
    // Beginning of file, add pre-frames and Xing/LAME tag
    int need_bytes_from_res;
    int got_bytes_from_res = 0;
    uint32_t need_pre_frames = 0;
    uint32_t first_frame_num = 0;
    uint64_t start_sample = 0;
    uint64_t end_sample = 0;
    uint64_t sample_count = mp3c->music_frame_count * mp3c->samples_per_frame - mp3c->enc_delay - mp3c->enc_padding;
    Buffer res_frame;
    Buffer seektable;
    Buffer xing_frame;
    
    mp3c->bit_res = 0;
    
    // Reset input buffer
    buffer_clear(mp3c->buf);
    PerlIO_seek(mp3c->fh, 0, SEEK_SET);
    mp3c->offset = 0;
    
    // Seek past ID3 tag
    _mp3cut_skip_id3v2(mp3c);
    
    DEBUG_TRACE("sample_count %llu\n", sample_count);
    
    // Convert milliseconds to samples
    if (my_hv_exists(self, "start_ms")) {
      uint32_t start_ms = SvIV(*(my_hv_fetch(self, "start_ms")));
      start_sample = (int)((start_ms * 1.0 / 10) * (mp3c->first_frame->samplerate * 1.0 / 100));
      DEBUG_TRACE("start_sample %llu\n", start_sample);
    }
    
    if (my_hv_exists(self, "end_ms")) {
      uint32_t end_ms = SvIV(*(my_hv_fetch(self, "end_ms")));
      end_sample = (int)((end_ms * 1.0 / 10) * (mp3c->first_frame->samplerate * 1.0 / 100));
      DEBUG_TRACE("end_sample %llu\n", end_sample);
    }
    else {
      end_sample = sample_count;
    }

    //start_sample = MAX(start_sample, mp3c->enc_delay); // XXX pcutmp3 has -encDelay here, bug?
    end_sample   = MIN(end_sample, sample_count);

    DEBUG_TRACE("Sample count %llu, actual start sample %llu, actual end sample %llu, orig enc delay %u, orig enc padding %u\n",
      sample_count, start_sample, end_sample, mp3c->enc_delay, mp3c->enc_padding);

    mp3c->first_frame_inclusive = MAX(0, (int)((start_sample + mp3c->enc_delay - MIN_OVERLAP_SAMPLES_START) / mp3c->samples_per_frame));
    mp3c->last_frame_exclusive  = MIN(mp3c->music_frame_count, (int)((end_sample + mp3c->enc_delay + MIN_OVERLAP_SAMPLES_END + mp3c->samples_per_frame - 1) / mp3c->samples_per_frame));
    mp3c->new_enc_delay = mp3c->enc_delay + (int)(start_sample - mp3c->first_frame_inclusive * mp3c->samples_per_frame);
    mp3c->new_enc_padding = (mp3c->last_frame_exclusive - mp3c->first_frame_inclusive) * mp3c->samples_per_frame - mp3c->new_enc_delay - (end_sample - start_sample);

    DEBUG_TRACE("first_frame_inclusive %u, last_frame_exclusive %u, new_enc_delay %u, new_enc_padding %u\n",
      mp3c->first_frame_inclusive, mp3c->last_frame_exclusive, mp3c->new_enc_delay, mp3c->new_enc_padding);
    
    mp3c->mask_ath = 0xFF;
    if (start_sample != 0)
      mp3c->mask_ath &= MASK_ATH_KILL_NO_GAP_START;

    if (end_sample != sample_count)
      mp3c->mask_ath &= MASK_ATH_KILL_NO_GAP_END;
    
    first_frame_num = mp3c->first_frame_inclusive;
    
    _set_curr_frame(mp3c, mp3c->first_frame_inclusive);
    need_bytes_from_res = _get_bit_res_ptr(mp3c);
    
    while (
         mp3c->first_frame_inclusive - need_pre_frames > 0
      && need_bytes_from_res > got_bytes_from_res
      && mp3c->new_enc_delay + 1152 <= 4095
    ) {
      need_pre_frames++;
      _set_curr_frame(mp3c, mp3c->first_frame_inclusive - need_pre_frames);
      got_bytes_from_res += _get_main_data_size(mp3c);
    }
    
    DEBUG_TRACE("need_pre_frames: %d, got_bytes_from_res %d\n", need_pre_frames, got_bytes_from_res);
    
    if (need_pre_frames == 0) {
      // force writing of PCUT tag frame
      need_pre_frames = 1;
    }
    
    if (need_pre_frames > 0) {
      uint64_t new_abs_start_sample = start_sample;
      
      first_frame_num--;
      mp3c->new_enc_delay += mp3c->samples_per_frame;
      
      buffer_init(&res_frame, MAX_FRAME_SIZE);
      
      // Keep absolute start sample from previous PCUT tag if any
      if (mp3c->start_sample != UNKNOWN_START_SAMPLE) {
        new_abs_start_sample += mp3c->start_sample;
      }
      
      _mp3cut_construct_reservoir_frame(mp3c, &res_frame, need_bytes_from_res, new_abs_start_sample);
    }
    
    // Construct new Xing seektable
    {
      int ofs00, ofsXX, i;
      float avg_bytes_per_frame;
      float avg_bytes_per_sec;
      unsigned char *seekptr;
      
      buffer_init(&seektable, 100);
      seekptr = buffer_ptr(&seektable);
      
      _set_curr_frame(mp3c, MAX(0, mp3c->last_frame_exclusive - 1)); // for ofsXX
      
      ofs00 = _get_frame_file_offset(mp3c, mp3c->first_frame_inclusive) - buffer_len(&res_frame);
      ofsXX = _get_frame_file_offset(mp3c, MAX(0, mp3c->last_frame_exclusive - 1)) + _get_frame_size(mp3c);
      mp3c->musi_len = ofsXX - ofs00;
      avg_bytes_per_frame = (ofsXX * 1.0 - ofs00) / (mp3c->last_frame_exclusive - mp3c->first_frame_inclusive);
      avg_bytes_per_sec   = avg_bytes_per_frame * mp3c->first_frame->samplerate / mp3c->first_frame->samples_per_frame;
      mp3c->avg_kbps      = avg_bytes_per_sec / 125.0;
      
      DEBUG_TRACE("ofs00 %d, ofsXX %d, musi_len %d\n", ofs00, ofsXX, mp3c->musi_len);
      DEBUG_TRACE("avg_bytes_per_frame %f, avg_bytes_per_sec %f, avg_kbps %f\n", avg_bytes_per_frame, avg_bytes_per_sec, mp3c->avg_kbps);
      
      for (i = 0; i < 100; i++) {
        int fidx = (int)( 0.5 + (mp3c->first_frame_inclusive + (i + 1.0) / 101 * (mp3c->last_frame_exclusive - mp3c->first_frame_inclusive)) );
        seekptr[i] = (uint8_t)( 0.5 + ((_get_frame_file_offset(mp3c, MAX(0, fidx)) - ofs00) * 255.0 / (ofsXX - ofs00)) );
        //DEBUG_TRACE("  fidx %d, seekptr[%d] %d\n", fidx, i, seekptr[i]);
      }
      
      seektable.end = 100;
    }
    
    // create new Xing/Info/LAME tag
    _mp3cut_construct_xing_frame(mp3c, &xing_frame, mp3c->last_frame_exclusive - first_frame_num, &seektable);
    sv_catpvn(buf, buffer_ptr(&xing_frame), buffer_len(&xing_frame));
    buf_size -= buffer_len(&xing_frame);
    buffer_free(&xing_frame);
    buffer_free(&seektable);
    
    // add pre frame(s)
    if (need_pre_frames > 0) {
      DEBUG_TRACE("preframe, need_bytes_from_res %d\n", need_bytes_from_res);
      if (need_bytes_from_res > 0) {
        Buffer res;
        int fi;
        
        buffer_init(&res, 511);
        
        for (fi = mp3c->first_frame_inclusive - need_pre_frames; fi < mp3c->first_frame_inclusive; fi++) {
          int fl, mdss;
          
          DEBUG_TRACE("  Handling res for frame %d\n", fi);
          
          _set_curr_frame(mp3c, fi);
          fl  = _get_frame_size(mp3c);
          mdss = _get_main_data_size(mp3c);
          
          if (mdss >= 511) {
            DEBUG_TRACE("    mdss %d, copying 511 bytes at offset %d\n", mdss, fl - 511);
            Copy((char *)buffer_ptr(mp3c->buf) + fl - 511, (char *)buffer_ptr(&res), 511, uint8_t);
          }
          else { // XXX need test
            int move = 511 - mdss;
            DEBUG_TRACE("    mdss %d, moving %d bytes\n", mdss, move);
            
            Move((char *)buffer_ptr(&res) + 511 - move, (char *)buffer_ptr(&res), move, uint8_t);
            Copy((char *)buffer_ptr(mp3c->buf) + fl - mdss, (char *)buffer_ptr(&res) + move, mdss, uint8_t);
          }
        }
        
        Copy(
          (char *)buffer_ptr(&res) + 511 - need_bytes_from_res,
          (char *)buffer_ptr(&res_frame) + buffer_len(&res_frame) - need_bytes_from_res,
          need_bytes_from_res,
          uint8_t
        );
        
        buffer_free(&res);
      }
      
      sv_catpvn(buf, buffer_ptr(&res_frame), buffer_len(&res_frame));
      buf_size -= buffer_len(&res_frame);
      mp3c->bit_res = need_bytes_from_res;
    }
    
    buffer_free(&res_frame);
  }

  // add regular frames, up to buf_size, with at least one regular frame every time
  {
    int fi, fl;
  
    for (fi = MAX(mp3c->first_frame_inclusive, mp3c->next_processed_frame); fi < mp3c->last_frame_exclusive; fi++) {
      DEBUG_TRACE("Handling frame %d\n", fi);
      _set_curr_frame(mp3c, fi);
      fl = _get_frame_size(mp3c);
    
      if ( _get_bit_res_ptr(mp3c) > mp3c->bit_res ) { // XXX need test
        DEBUG_TRACE("    Writing silence frame (bit res ptr %d > bit_res %d)\n", _get_bit_res_ptr(mp3c), mp3c->bit_res);
        _mp3cut_silence_frame(mp3c);
      }
        
      mp3c->bit_res = MIN(mp3c->bit_res + _get_main_data_size(mp3c), mp3c->max_res);
      DEBUG_TRACE("bit_res %d\n", mp3c->bit_res);
    
      mp3c->next_processed_frame = fi + 1;
      
      sv_catpvn(buf, buffer_ptr(mp3c->buf), fl);
      buf_size -= fl;
      
      if (buf_size <= 0)
        break;
    }
  }
  
  return sv_len(buf);
}

void
_mp3cut_construct_reservoir_frame(mp3cut *mp3c, Buffer *res_frame, uint32_t min_res_size, uint64_t abs_start_sample)
{
  unsigned char *dest = buffer_ptr(res_frame);
  int h32 = mp3c->first_frame->header32 | 0x00010000; // switch off CRC usage
  mp3frame frame;
  int bri, i;
  
  // increase for 10-byte header inclusion
  min_res_size += 10;
  
  // Find best res frame size from lowest bitrate to highest
  for (bri = 1; bri <= 14; bri++) {
    int side_info_end, main_data_size;
    
    h32 = (h32 & 0xFFFF0FFF) + (bri << 12);
    _mp3cut_decode_frame(h32, &frame);
    side_info_end = _get_side_info_end(&frame);
    main_data_size = frame.frame_size - side_info_end;
    
    if (main_data_size >= min_res_size) {
      put_u32(dest, h32);
      for (i = 4; i < side_info_end; i++)
        dest[i] = 0;
      for (i = side_info_end; i < frame.frame_size; i++)
        dest[i] = 'x';
      dest[side_info_end]     = 'P';
      dest[side_info_end + 1] = 'C';
      dest[side_info_end + 2] = 'U';
      dest[side_info_end + 3] = 'T';
      dest[side_info_end + 4] = 0; // revision 0
      dest[side_info_end + 5] = (abs_start_sample >> 32) & 0xFF;
      dest[side_info_end + 6] = (abs_start_sample >> 24) & 0xFF;
      dest[side_info_end + 7] = (abs_start_sample >> 16) & 0xFF;
      dest[side_info_end + 8] = (abs_start_sample >> 8) & 0xFF;
      dest[side_info_end + 9] = abs_start_sample & 0xFF;
      
      res_frame->end = frame.frame_size;
      break;
    }
  }
  
  DEBUG_TRACE("res frame size %d\n", buffer_len(res_frame));
}

void
_mp3cut_construct_xing_frame(mp3cut *mp3c, Buffer *xing_frame, uint32_t frame_count, Buffer *seektable)
{
  int fh32 = mp3c->first_frame->header32 | 0x00010000; // disable CRC if any
  int frame_size = 0;
  int tag_offset = 0;
  int i;
  unsigned char *dest;
  uint16_t enc_delay = mp3c->new_enc_delay;
  uint16_t enc_padding = mp3c->new_enc_padding;
  uint16_t crc = 0;
      
  // Calculate optimal header frame size
  {
    mp3frame frame;
    float min_dist = 9999;
    
    for (i = 1; i < 15; i++) {
      int th32 = (fh32 & 0xFFFF0FFF) | (i << 12);
      _mp3cut_decode_frame(th32, &frame);
      if (frame.frame_size >= 0xC0) {
        int ikbps = frame.bitrate_kbps;
        float dist = fabs(mp3c->avg_kbps - ikbps);
        if (dist < min_dist) {
          min_dist = dist;
          fh32 = th32;
          frame_size = frame.frame_size;
          tag_offset = _get_side_info_size(&frame) + 4;
        }
      }
    }
    
    DEBUG_TRACE("Xing frame size %d, tag offset %d\n", frame_size, tag_offset);
    buffer_init(xing_frame, frame_size);
    dest = buffer_ptr(xing_frame);
  }
  
  Zero(dest, frame_size, uint8_t);
  
  put_u32(dest, fh32);
  
  if (mp3c->is_vbr) {
    dest[tag_offset++] = 'X';
    dest[tag_offset++] = 'i';
    dest[tag_offset++] = 'n';
    dest[tag_offset++] = 'g';
  }
  else {
    dest[tag_offset++] = 'I';
    dest[tag_offset++] = 'n';
    dest[tag_offset++] = 'f';
    dest[tag_offset++] = 'o';
  }
  dest[tag_offset++] = 0;
  dest[tag_offset++] = 0;
  dest[tag_offset++] = 0;
  dest[tag_offset++] = 0x0F;
  put_u32(&dest[tag_offset], frame_count);
  tag_offset += 4;
  put_u32(&dest[tag_offset], frame_size + mp3c->musi_len);
  tag_offset += 4;
  Copy(buffer_ptr(seektable), &dest[tag_offset], 100, uint8_t);
  tag_offset += 100;
  put_u32(&dest[tag_offset], 50); // vbr scale
  tag_offset += 4;
  
  if (mp3c->xilt_frame->lame_tag) {
    Copy((char *)buffer_ptr(mp3c->xilt_frame->tag) + mp3c->xilt_frame->lame_tag_offset, &dest[tag_offset - 4], 40, uint8_t);
    tag_offset += 4;
    // delete LAME's replaygain tag
    for (i = 0; i < 8; i++)
      dest[tag_offset + 0x07 + i] = 0;
    // delete no-gap flags
    dest[tag_offset + 0x0F] &= mp3c->mask_ath;
  }
  else {
    dest[tag_offset++] = 'L';
    dest[tag_offset++] = 'A';
    dest[tag_offset++] = 'M';
    dest[tag_offset++] = 'E';
  }
  
  enc_delay = MAX(0, MIN(enc_delay, 4095));
  enc_padding = MAX(0, MIN(enc_padding, 4095));
  dest[tag_offset + 0x11] = (enc_delay >> 4) & 0xFF;
  dest[tag_offset + 0x12] = ((enc_delay & 0xF) << 4) | ((enc_padding >> 8) & 0xF);
  dest[tag_offset + 0x13] = enc_padding & 0xFF;
  put_u32(&dest[tag_offset + 0x18], frame_size + mp3c->musi_len);
  
  for (i = 0; i < 190; i++)
    crc = _crc16(crc, dest[i] & 0xFF);
  
  put_u16(&dest[tag_offset + 0x1E], crc);
  
  xing_frame->end = frame_size;
}

void
_mp3cut_silence_frame(mp3cut *mp3c)
{
  unsigned char *data = buffer_ptr(mp3c->buf);
  uint8_t siend = _get_side_info_end(mp3c->first_frame);
  bool crc_used = ((data[1] & 1) == 0);
  int i;
  
  for (i = 4; i <= siend; i++)
    data[i] = 0;
  
  if (crc_used) {
    uint16_t crc = 0xFFFF;
    int o2;
    
    crc = _crc16(crc, data[2]);
    crc = _crc16(crc, data[3]);
    for (o2 = 6; o2 < siend; o2++)
      crc = _crc16(crc, data[o2]);
    put_u16(&data[4], crc);
  }
}

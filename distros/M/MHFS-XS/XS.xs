#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include <stdint.h>

#include "FLAC/stream_encoder.h"

#define MA_NO_ENCODING
#define MA_NO_DEVICE_IO
#define MA_NO_THREADING
#define MA_NO_GENERATION
#define MINIAUDIO_IMPLEMENTATION
#include "miniaudio/miniaudio.h"

// verify dr_flac is included, or attempt to include it
#if !defined(dr_flac_h) || !defined(dr_flac_c)
#if defined(dr_flac_h) || defined(dr_flac_c)
#error "miniaudio only partially declared and defined dr_flac"
#endif
#pragma message("miniaudio did not declare dr_flac, attempting to include")
#define DR_FLAC_IMPLEMENTATION
#include "dr_flac.h"
#endif

typedef void *(* malloc_ptr) (size_t);
typedef void  (* free_ptr)   (void*);
typedef void *(* realloc_ptr)(void *, size_t); 

typedef struct {
	malloc_ptr  malloc;
	free_ptr    free;
	realloc_ptr realloc;
    drflac *pFlac;

    FLAC__StreamEncoder *encoder;
	uint8_t *flacbuffer;
    uint64_t flacbuffersize;	
    uint64_t file_offset;
    uint64_t largest_offset;

} MHFS_XS_Track;

typedef struct {
    #ifdef MULTIPLICITY
    tTHX context;
    #endif
    SV *returnData;
} MHFS_XS_Track_meta_userData;
#ifdef MULTIPLICITY
#define MHFS_XS_Track_meta_save_context(X) (X)->context = aTHX
#define MHFS_XS_Track_meta_load_context(X) pTHX = (X)->context
#else
#define MHFS_XS_Track_meta_save_context(X)
#define MHFS_XS_Track_meta_load_context(X)
#endif

#define MIN(a,b) (((a)<(b))?(a):(b))

MHFS_XS_Track *_MHFS_XS_Track_new(const char *filename, malloc_ptr mymalloc, free_ptr myfree, realloc_ptr myrealloc)
{
    MHFS_XS_Track *track = mymalloc(sizeof(MHFS_XS_Track));
    if(track == NULL) return NULL;
	memset(track, 0, sizeof(*track));    
    track->malloc  = mymalloc ? mymalloc : &malloc;
	track->free    = myfree  ? myfree: &free;
	track->realloc = myrealloc ? myrealloc : &realloc;
    track->pFlac = drflac_open_file(filename, NULL);
    if (track->pFlac == NULL) {
        return NULL;
    }

	return track;
}

uint64_t _MHFS_XS_Track_get_totalPCMFrameCount(const char *filename)
{
    ma_uint64 totalPCMFrameCount = 0;
    ma_decoder decoder;
    if(ma_decoder_init_file(filename, NULL, &decoder) == MA_SUCCESS)
    {
        ma_decoder_get_length_in_pcm_frames(&decoder, &totalPCMFrameCount);
        ma_decoder_uninit(&decoder);
    }
    else
    {
        printf("failed to open ma_decoder\n");
    }
    return (uint64_t)totalPCMFrameCount;
}

FLAC__StreamEncoderWriteStatus writecb(const FLAC__StreamEncoder *encoder, const FLAC__byte buffer[], size_t bytes, unsigned samples, unsigned current_frame, void *client_data)
{
    //fprintf(stderr, "writecb %u %u\n", bytes, samples);
    MHFS_XS_Track *track = (MHFS_XS_Track*)client_data;
    // + 1 for terminating 0
    if((track->file_offset + bytes + 1) > track->flacbuffersize)
    {
        fprintf(stderr, "reallocating to %zu\n", track->flacbuffersize + (bytes * 2));
        track->flacbuffer = track->realloc(track->flacbuffer, track->flacbuffersize + (bytes * 2));
        if(track->flacbuffer == NULL)
        {
            return  FLAC__STREAM_ENCODER_WRITE_STATUS_FATAL_ERROR;
        }
        track->flacbuffersize = track->flacbuffersize + (bytes * 2);        
    }
    
    
    memcpy(&track->flacbuffer[track->file_offset], buffer, bytes);
    track->file_offset += bytes;
    if(track->file_offset > track->largest_offset) track->largest_offset = track->file_offset;
    return FLAC__STREAM_ENCODER_WRITE_STATUS_OK;
}





FLAC__StreamEncoderSeekStatus seekcb(const FLAC__StreamEncoder *encoder, FLAC__uint64 absolute_byte_offset, void *client_data)
{
    MHFS_XS_Track *track = (MHFS_XS_Track*)client_data;
    track->file_offset = absolute_byte_offset;
    return FLAC__STREAM_ENCODER_SEEK_STATUS_OK;
}

FLAC__StreamEncoderTellStatus tellcb(const FLAC__StreamEncoder *encoder, FLAC__uint64 *absolute_byte_offset, void *client_data)
{
     MHFS_XS_Track *track = (MHFS_XS_Track*)client_data;
     *absolute_byte_offset = track->file_offset;
     return FLAC__STREAM_ENCODER_TELL_STATUS_OK;
}

static __attribute__((always_inline)) inline int32_t sar(const int32_t value, const int shift)
{
    return value < 0 ? ~(~value >> shift) : value >> shift;
}

bool _MHFS_XS_Track_get_flac(MHFS_XS_Track *track, uint64_t start, size_t count)
{
    track->file_offset     = 0;
    track->largest_offset  = 0;
	track->flacbuffersize = count * sizeof(FLAC__int32);		
    drflac *pFlac = track->pFlac;
    unsigned samplesize;
    if(pFlac->bitsPerSample == 16)
    {
        samplesize = 2;
    }
    else if(pFlac->bitsPerSample == 24)
    {
        samplesize = 4;
    }
    else
    {
        fprintf(stderr, "ERROR: Bits Per Sample of %u, not supported\n", pFlac->bitsPerSample);
        return false;
    }

	track->flacbuffer = track->malloc(track->flacbuffersize);
    if(track->flacbuffer == NULL)
    {
        return false;
    }
   

	/* allocate the encoder */
	if((track->encoder = FLAC__stream_encoder_new()) == NULL) {
		fprintf(stderr, "ERROR: allocating encoder\n");
		return true;
	}

    FLAC__bool ok = true;
	FLAC__StreamEncoderInitStatus init_status;
    
	//ok &= FLAC__stream_encoder_set_verify(track->encoder, true);
	ok &= FLAC__stream_encoder_set_verify(track->encoder, false);
	ok &= FLAC__stream_encoder_set_compression_level(track->encoder, 5);
	ok &= FLAC__stream_encoder_set_channels(track->encoder, pFlac->channels);
	ok &= FLAC__stream_encoder_set_bits_per_sample(track->encoder, pFlac->bitsPerSample);
	ok &= FLAC__stream_encoder_set_sample_rate(track->encoder, pFlac->sampleRate);
	ok &= FLAC__stream_encoder_set_total_samples_estimate(track->encoder, count);

	if(!ok) {
		goto _MHFS_XS_Track_get_flac_cleanup;
	}
    
	//init_status = FLAC__stream_encoder_init_stream(track->encoder, &writecb, &seekcb, &tellcb, NULL, track);
	init_status = FLAC__stream_encoder_init_stream(track->encoder, &writecb, NULL, NULL, NULL, track);
	if(init_status != FLAC__STREAM_ENCODER_INIT_STATUS_OK) {
		fprintf(stderr, "ERROR: initializing encoder: %s\n", FLAC__StreamEncoderInitStatusString[init_status]);
		goto _MHFS_XS_Track_get_flac_cleanup;
	}

   
    if(!drflac_seek_to_pcm_frame(pFlac, start))
    {
        goto _MHFS_XS_Track_get_flac_cleanup;    
    }    

    long unsigned rawSamplesSize = count * pFlac->channels * samplesize;
    fprintf(stderr, "seeked to absolute, allocating %lu\n", rawSamplesSize);
    void *rawSamples = malloc(rawSamplesSize);
    if(rawSamples == NULL)
    {
        goto _MHFS_XS_Track_get_flac_cleanup;
    }
    FLAC__int32 *fbuffer = malloc(sizeof(FLAC__int32)*count * pFlac->channels);
    if(fbuffer == NULL)
    {
        goto _MHFS_XS_Track_get_flac_cleanup;
    }
    if(pFlac->bitsPerSample == 16)
    {
        int16_t *raw16Samples = (int16_t*)rawSamples;
        if(drflac_read_pcm_frames_s16(track->pFlac, count, raw16Samples) != count)
        {
            free(fbuffer);
            free(rawSamples);
            goto _MHFS_XS_Track_get_flac_cleanup;       
        }
        unsigned i;
        for( i = 0; i < (count * pFlac->channels) ; i++)
        {
            fbuffer[i] = raw16Samples[i];       
        }
    }
    else
    {
        int32_t *raw32Samples = (int32_t*)rawSamples;
        if(drflac_read_pcm_frames_s32(track->pFlac, count, raw32Samples) != count)
        {
            free(fbuffer);
            free(rawSamples);
            goto _MHFS_XS_Track_get_flac_cleanup;       
        }
        unsigned i;
        for( i = 0; i < (count * pFlac->channels) ; i++)
        {
            // drflac outputs 24 bit audio to the higher bits of int32_t, we need it represented as a normal integer for libflac
            fbuffer[i] = sar(raw32Samples[i], 8);                       
        }
    }   
    
    if(!FLAC__stream_encoder_process_interleaved(track->encoder, fbuffer, count))
    {
        fprintf(stderr, "   state: %s\n", FLAC__StreamEncoderStateString[FLAC__stream_encoder_get_state(track->encoder)]);
        free(fbuffer);
        free(rawSamples);
        goto _MHFS_XS_Track_get_flac_cleanup;        
    }
    free(rawSamples);
    free(fbuffer);   
    
    if(FLAC__stream_encoder_finish(track->encoder))
    {
        fprintf(stderr, "should be encoded by now\n");
		FLAC__stream_encoder_delete(track->encoder);
        track->encoder = NULL;
		return true;
    }    
   
_MHFS_XS_Track_get_flac_cleanup:
	FLAC__stream_encoder_delete(track->encoder);
    track->encoder = NULL;
	return false;
}

bool _MHFS_XS_Track_wavvfs_read_range(MHFS_XS_Track *track, uint64_t start, uint64_t end)
{
    if(start > end)
    {
        return false;
    }
    drflac *pFlac = track->pFlac;
    track->flacbuffersize = (end - start) + 1 + 1;
    if((track->flacbuffersize - 1)	> (44 + (pFlac->totalPCMFrameCount * pFlac->channels * (pFlac->bitsPerSample/8))))
    {
        return false;    
    }
    track->largest_offset  = track->flacbuffersize - 1;
	track->flacbuffer = track->malloc(track->flacbuffersize);
    if(track->flacbuffer == NULL)
    {
        return false;
    }   
    
    uint64_t bytesleft = track->largest_offset;
    if(start < 44) {
        // WAVE_FORMAT_EXTENSIBLE doesn't exist
        uint32_t audio_data_size = pFlac->totalPCMFrameCount * pFlac->channels * (pFlac->bitsPerSample/8);
        uint8_t data[44];
        memcpy(data, "RIFF", 4);
        uint32_t chunksize = audio_data_size + 36;
        memcpy(&data[4], &chunksize, 4);
        memcpy(&data[8], "WAVEfmt ", 8);
        uint32_t pcm = 16;
        memcpy(&data[16], &pcm, 4);
        uint16_t audioformat = 1;
        memcpy(&data[20], &audioformat, 2);
        uint16_t numchannels = pFlac->channels;
        memcpy(&data[22], &numchannels, 2);
        uint32_t samplerate = pFlac->sampleRate;
        memcpy(&data[24], &samplerate, 4);
        uint32_t byterate = samplerate * numchannels * (pFlac->bitsPerSample / 8);
        memcpy(&data[28], &byterate, 4);
        uint16_t blockalign = numchannels * (pFlac->bitsPerSample / 8);
        memcpy(&data[32], &blockalign, 2);
        uint16_t bitspersample = pFlac->bitsPerSample;
        memcpy(&data[34], &bitspersample, 2);
        memcpy(&data[36], "data", 4);
        memcpy(&data[40], &audio_data_size, 4);
        unsigned tcopy = MIN(44, end+1) - start;
        memcpy(&track->flacbuffer[start], data, tcopy);
        bytesleft -= tcopy;         
    }
    if(bytesleft == 0)
    {
        return true;
    }


    unsigned samplesize = (pFlac->bitsPerSample/8);
    unsigned pcmframesize = (pFlac->channels * (pFlac->bitsPerSample/8));
    unsigned startframe = 0;
    unsigned skipsample = 0;
    unsigned skipbytes  = 0;
    if(start > 44)
    {
        startframe = (start-44) / pcmframesize;
        skipbytes = (start-44) % pcmframesize;
        skipsample = skipbytes / samplesize;
        skipbytes = skipbytes % samplesize;
        fprintf(stderr, "skipping %u samples and %u bytes\n", skipsample, skipbytes);   
    }
    unsigned endframe = (end-44) / pcmframesize;
    unsigned framecount = endframe - startframe + 1;
    
    fprintf(stderr, "startframe %u endframe %u framecount %u\n", startframe, endframe, framecount);
    if(!drflac_seek_to_pcm_frame(pFlac, startframe))
    {
        return false;   
    }

    {
        int32_t *raw32Samples = malloc(framecount * pFlac->channels * sizeof(int32_t));
        if(raw32Samples == NULL)
        {
            return false;
        }        
        if(drflac_read_pcm_frames_s32(track->pFlac, framecount, raw32Samples) != framecount)
        {
            free(raw32Samples);
            return false;     
        }

        unsigned flacbufferpos = track->largest_offset-bytesleft;
        unsigned sampleindex;
        for( sampleindex = skipsample; bytesleft > 0; sampleindex++)
        {
            unsigned tocopy = (bytesleft > samplesize ? samplesize : bytesleft) - skipbytes;
            
            // drflac decodes to the high bytes, skip the unneeded low bytes
            skipbytes += (sizeof(int32_t) - samplesize);

            // copy the parts of the sample we want and encode as little endian
            int32_t sample = sar(raw32Samples[sampleindex], (skipbytes * 8));
            skipbytes = 0;                
            bytesleft -= tocopy;
            while(tocopy)
            {
                track->flacbuffer[flacbufferpos++] = sample;
                sample = sar(sample, 8);
                tocopy--; 
            }            
        }
        free(raw32Samples);
    }
    return true;    
}

void * _MHFS_XS_Track_get_wav_seg(MHFS_XS_Track *track, uint64_t start, size_t count)
{
    drflac *pFlac = track->pFlac;
    // read in the desired amount of samples   
    if(!drflac_seek_to_pcm_frame(pFlac, start))
    {
        return NULL;
    }     
    fprintf(stderr, "seeked to absolute\n");
    track->largest_offset = 44+ (count * pFlac->channels * sizeof(int16_t));
    uint8_t *data =  track->malloc(((size_t)count * pFlac->channels * sizeof(int16_t)) + 44 + 1);
    if(data == NULL)
    {
        return NULL;
    }
    memcpy(data, "RIFF", 4);
    uint32_t chunksize = (count * pFlac->channels * sizeof(int16_t)) + 36;
    memcpy(&data[4], &chunksize, 4);
    memcpy(&data[8], "WAVEfmt ", 8);
    uint32_t pcm = 16;
    memcpy(&data[16], &pcm, 4);
    uint16_t audioformat = 1;
    memcpy(&data[20], &audioformat, 2);
    uint16_t numchannels = pFlac->channels;
    memcpy(&data[22], &numchannels, 2);
    uint32_t samplerate = pFlac->sampleRate;
    memcpy(&data[24], &samplerate, 4);
    uint32_t byterate = samplerate * numchannels * (pFlac->bitsPerSample / 8);
    memcpy(&data[28], &byterate, 4);
    uint16_t blockalign = numchannels * (pFlac->bitsPerSample / 8);
    memcpy(&data[32], &blockalign, 2);
    uint16_t bitspersample = pFlac->bitsPerSample;
    memcpy(&data[34], &bitspersample, 2);
    memcpy(&data[36], "data", 4);
    uint32_t totalsize = count * pFlac->channels * sizeof(int16_t);
    memcpy(&data[40], &totalsize, 4);
    
    int16_t *rawSamples = (int16_t*)(data + 44); 
    if(drflac_read_pcm_frames_s16(track->pFlac, count, rawSamples) != count)
    {
        free(data);
        return NULL;    
    }
    
    return (void*)data;
}

void _MHFS_XS_Track_on_meta(void* pUserData, drflac_metadata* pMetadata)
{
    MHFS_XS_Track_meta_userData *pMetaUserData = pUserData;
    MHFS_XS_Track_meta_load_context(pMetaUserData);
    if(pMetadata->type == DRFLAC_METADATA_BLOCK_TYPE_VORBIS_COMMENT)
    {
        fprintf(stderr, "Found vorbiscomment\n");

        AV *array = newAV();
        drflac_vorbis_comment_iterator ci;
        drflac_init_vorbis_comment_iterator(&ci, pMetadata->data.vorbis_comment.commentCount, pMetadata->data.vorbis_comment.pComments);
        const char *res;
        uint32_t commentlen;
        while((res = drflac_next_vorbis_comment(&ci, &commentlen)) != NULL)
        {
            char buf[256];
            uint32_t tocopy = (sizeof(buf) > commentlen) ? commentlen : sizeof(buf) - 1;
            memcpy(buf, res, tocopy);
            buf[tocopy] = '\0';
            fprintf(stderr, "comment: %s\n", buf);
            SV *theSV = newSVpv(buf, tocopy);
            av_push(array, theSV);
        }
        pMetaUserData->returnData = (SV*)array;
    }
}

void _MHFS_XS_Track_delete(MHFS_XS_Track *track)
{
    drflac_close(track->pFlac);
    track->free(track);
}

void *MHFS_XS_Track_perl_malloc(size_t size)
{
	void *ret;
	Newx(ret, size, uint8_t);
	return ret;
}

void MHFS_XS_Track_perl_free(void *ptr)
{
    Safefree(ptr);
}

void *MHFS_XS_Track_perl_realloc(void *ptr, size_t size)
{
	Renew(ptr, size, uint8_t);
	return ptr;
}

typedef MHFS_XS_Track* P_MHFS_XS_Track;

MODULE = MHFS::XS		PACKAGE = MHFS::XS

P_MHFS_XS_Track
new(filename)
        const char *filename
	CODE:		
		MHFS_XS_Track *track = _MHFS_XS_Track_new(filename, &MHFS_XS_Track_perl_malloc, &MHFS_XS_Track_perl_free, &MHFS_XS_Track_perl_realloc);		
		if(track != NULL)
		{
	        RETVAL = track;
		}
		else
		{
			/* to do exception instead?*/
			RETVAL = (P_MHFS_XS_Track)&PL_sv_undef;
		}
		
	OUTPUT:
        RETVAL


void 
DESTROY(track)
        P_MHFS_XS_Track track
	CODE:
		_MHFS_XS_Track_delete(track);
		fprintf(stderr, "deleted decoder\n");

SV *
get_flac(track, start, count)
        P_MHFS_XS_Track track
		UV start
		size_t count
	CODE:
	    fprintf(stderr, "_pointer %p\n", track);
		SV *data = NULL;		
		if(_MHFS_XS_Track_get_flac(track, start, count))
		{
			fprintf(stderr, "flacbuffer at %p largest_offset %"PRIu64"\n", track->flacbuffer,track->largest_offset);
			track->flacbuffer[track->largest_offset] = '\0';
			data = newSV(0);
			sv_usepvn_flags(data, (char*)track->flacbuffer, track->largest_offset, SV_SMAGIC | SV_HAS_TRAILING_NUL);
			fprintf(stderr, "pvx %p\n", SvPVX(data));
		}
        else
        {
            data = &PL_sv_undef;
        }
	RETVAL = data;
    OUTPUT:
        RETVAL

SV *
wavvfs_read_range(track, start, end)
        P_MHFS_XS_Track track
		UV start
		UV end
	CODE:
        SV *data = NULL;
        if(_MHFS_XS_Track_wavvfs_read_range(track, start, end))
        {
            track->flacbuffer[track->largest_offset] = '\0';
			data = newSV(0);
			sv_usepvn_flags(data, (char*)track->flacbuffer, track->largest_offset, SV_SMAGIC | SV_HAS_TRAILING_NUL);
			fprintf(stderr, "pvx %p\n", SvPVX(data));
        }
        else
        {
            data = &PL_sv_undef;
        }
    RETVAL = data;
    OUTPUT:
        RETVAL
        
SV *
get_wav_seg(track, start, count)
        P_MHFS_XS_Track track
		UV start
		size_t count
	CODE:
        SV *data = NULL;
        void *wav = _MHFS_XS_Track_get_wav_seg(track, start, count);
        if(wav)
        {
            track->flacbuffer[track->largest_offset] = '\0';
			data = newSV(0);
			sv_usepvn_flags(data, (char*)wav, track->largest_offset, SV_SMAGIC | SV_HAS_TRAILING_NUL);
			fprintf(stderr, "pvx %p\n", SvPVX(data));
        }
        else
        {
            data = &PL_sv_undef;
        }
    RETVAL = data;
    OUTPUT:
        RETVAL

AV *
get_vorbis_comments(filename)
        const char *filename
	CODE:
        MHFS_XS_Track_meta_userData metaUserData;
        MHFS_XS_Track_meta_save_context(&metaUserData);
        metaUserData.returnData = &PL_sv_undef;
        drflac *pFlac = drflac_open_file_with_metadata(filename, &_MHFS_XS_Track_on_meta, &metaUserData, NULL);
        drflac_close(pFlac);
    RETVAL = (AV*)metaUserData.returnData;
    sv_2mortal((SV*)RETVAL);
    OUTPUT:
        RETVAL

SV *
get_totalPCMFrameCount(filename)
        const char *filename
    CODE:
        RETVAL = newSVuv(_MHFS_XS_Track_get_totalPCMFrameCount(filename));
    OUTPUT:
        RETVAL

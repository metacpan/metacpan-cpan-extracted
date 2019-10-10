#ifdef __cplusplus
extern "C" {
#endif
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#define NEED_newCONSTSUB
#include "ppport.h"
#include <mp4v2/mp4v2.h>

typedef MP4FileHandle MP4__LibMP4v2;

static void
mp4_log_callback(MP4LogLevel loglevel, const char* fmt, va_list ap_)
{
    dTHX;
    va_list ap;
    va_copy(ap, ap_);
    vwarn(fmt, &ap);
    va_end(ap);
}

#define DEFINE_CONST(stash, export, name, sv) \
do { \
    newCONSTSUB(stash, name, sv); \
    av_push(export, newSVpvs(name)); \
} while (0)

MODULE = MP4::LibMP4v2 PACKAGE = MP4::LibMP4v2

BOOT:
{
    MP4SetLogCallback(mp4_log_callback);
    MP4LogSetLevel(MP4_LOG_NONE);

    HV* stash = gv_stashpv("MP4::LibMP4v2", 1);
    AV* export = get_av("MP4::LibMP4v2::EXPORT", GV_ADD);

    /* LOG_LEVEL */
    DEFINE_CONST(stash, export, "MP4_LOG_NONE",     newSViv(MP4_LOG_NONE));
    DEFINE_CONST(stash, export, "MP4_LOG_ERROR",    newSViv(MP4_LOG_ERROR));
    DEFINE_CONST(stash, export, "MP4_LOG_WARNING",  newSViv(MP4_LOG_WARNING));
    DEFINE_CONST(stash, export, "MP4_LOG_INFO",     newSViv(MP4_LOG_INFO));
    DEFINE_CONST(stash, export, "MP4_LOG_VERBOSE1", newSViv(MP4_LOG_VERBOSE1));
    DEFINE_CONST(stash, export, "MP4_LOG_VERBOSE2", newSViv(MP4_LOG_VERBOSE2));
    DEFINE_CONST(stash, export, "MP4_LOG_VERBOSE3", newSViv(MP4_LOG_VERBOSE3));
    DEFINE_CONST(stash, export, "MP4_LOG_VERBOSE4", newSViv(MP4_LOG_VERBOSE4));
    /* TRACK_TYPE */
    DEFINE_CONST(stash, export, "MP4_OD_TRACK_TYPE",       newSVpvs(MP4_OD_TRACK_TYPE));
    DEFINE_CONST(stash, export, "MP4_SCENE_TRACK_TYPE",    newSVpvs(MP4_SCENE_TRACK_TYPE));
    DEFINE_CONST(stash, export, "MP4_AUDIO_TRACK_TYPE",    newSVpvs(MP4_AUDIO_TRACK_TYPE));
    DEFINE_CONST(stash, export, "MP4_VIDEO_TRACK_TYPE",    newSVpvs(MP4_VIDEO_TRACK_TYPE));
    DEFINE_CONST(stash, export, "MP4_HINT_TRACK_TYPE",     newSVpvs(MP4_HINT_TRACK_TYPE));
    DEFINE_CONST(stash, export, "MP4_CNTL_TRACK_TYPE",     newSVpvs(MP4_CNTL_TRACK_TYPE));
    DEFINE_CONST(stash, export, "MP4_TEXT_TRACK_TYPE",     newSVpvs(MP4_TEXT_TRACK_TYPE));
    DEFINE_CONST(stash, export, "MP4_SUBTITLE_TRACK_TYPE", newSVpvs(MP4_SUBTITLE_TRACK_TYPE));
    DEFINE_CONST(stash, export, "MP4_SUBPIC_TRACK_TYPE",   newSVpvs(MP4_SUBPIC_TRACK_TYPE));
    DEFINE_CONST(stash, export, "MP4_CLOCK_TRACK_TYPE",    newSVpvs(MP4_CLOCK_TRACK_TYPE));
    DEFINE_CONST(stash, export, "MP4_MPEG7_TRACK_TYPE",    newSVpvs(MP4_MPEG7_TRACK_TYPE));
    DEFINE_CONST(stash, export, "MP4_OCI_TRACK_TYPE",      newSVpvs(MP4_OCI_TRACK_TYPE));
    DEFINE_CONST(stash, export, "MP4_IPMP_TRACK_TYPE",     newSVpvs(MP4_IPMP_TRACK_TYPE));
    DEFINE_CONST(stash, export, "MP4_MPEGJ_TRACK_TYPE",    newSVpvs(MP4_MPEGJ_TRACK_TYPE));
    /* TIME_SCALE */
    DEFINE_CONST(stash, export, "MP4_SECONDS_TIME_SCALE",      newSViv(MP4_SECONDS_TIME_SCALE));
    DEFINE_CONST(stash, export, "MP4_MILLISECONDS_TIME_SCALE", newSViv(MP4_MILLISECONDS_TIME_SCALE));
    DEFINE_CONST(stash, export, "MP4_MICROSECONDS_TIME_SCALE", newSViv(MP4_MICROSECONDS_TIME_SCALE));
    DEFINE_CONST(stash, export, "MP4_NANOSECONDS_TIME_SCALE",  newSViv(MP4_NANOSECONDS_TIME_SCALE));
    /* TIME_SCALE (short name) */
    DEFINE_CONST(stash, export, "MP4_SECS_TIME_SCALE",  newSViv(MP4_SECS_TIME_SCALE));
    DEFINE_CONST(stash, export, "MP4_MSECS_TIME_SCALE", newSViv(MP4_MSECS_TIME_SCALE));
    DEFINE_CONST(stash, export, "MP4_USECS_TIME_SCALE", newSViv(MP4_USECS_TIME_SCALE));
    DEFINE_CONST(stash, export, "MP4_NSECS_TIME_SCALE", newSViv(MP4_NSECS_TIME_SCALE));
    /* MP4 MPEG-4 Audio types */
    DEFINE_CONST(stash, export, "MP4_MPEG4_AAC_MAIN_AUDIO_TYPE",       newSViv(MP4_MPEG4_AAC_MAIN_AUDIO_TYPE));
    DEFINE_CONST(stash, export, "MP4_MPEG4_AAC_LC_AUDIO_TYPE",         newSViv(MP4_MPEG4_AAC_LC_AUDIO_TYPE));
    DEFINE_CONST(stash, export, "MP4_MPEG4_AAC_SSR_AUDIO_TYPE",        newSViv(MP4_MPEG4_AAC_SSR_AUDIO_TYPE));
    DEFINE_CONST(stash, export, "MP4_MPEG4_AAC_LTP_AUDIO_TYPE",        newSViv(MP4_MPEG4_AAC_LTP_AUDIO_TYPE));
    DEFINE_CONST(stash, export, "MP4_MPEG4_AAC_HE_AUDIO_TYPE",         newSViv(MP4_MPEG4_AAC_HE_AUDIO_TYPE));
    DEFINE_CONST(stash, export, "MP4_MPEG4_AAC_SCALABLE_AUDIO_TYPE",   newSViv(MP4_MPEG4_AAC_SCALABLE_AUDIO_TYPE));
    DEFINE_CONST(stash, export, "MP4_MPEG4_CELP_AUDIO_TYPE",           newSViv(MP4_MPEG4_CELP_AUDIO_TYPE));
    DEFINE_CONST(stash, export, "MP4_MPEG4_HVXC_AUDIO_TYPE",           newSViv(MP4_MPEG4_HVXC_AUDIO_TYPE));
    DEFINE_CONST(stash, export, "MP4_MPEG4_TTSI_AUDIO_TYPE",           newSViv(MP4_MPEG4_TTSI_AUDIO_TYPE));
    DEFINE_CONST(stash, export, "MP4_MPEG4_MAIN_SYNTHETIC_AUDIO_TYPE", newSViv(MP4_MPEG4_MAIN_SYNTHETIC_AUDIO_TYPE));
    DEFINE_CONST(stash, export, "MP4_MPEG4_WAVETABLE_AUDIO_TYPE",      newSViv(MP4_MPEG4_WAVETABLE_AUDIO_TYPE));
    DEFINE_CONST(stash, export, "MP4_MPEG4_MIDI_AUDIO_TYPE",           newSViv(MP4_MPEG4_MIDI_AUDIO_TYPE));
    DEFINE_CONST(stash, export, "MP4_MPEG4_ALGORITHMIC_FX_AUDIO_TYPE", newSViv(MP4_MPEG4_ALGORITHMIC_FX_AUDIO_TYPE));
    DEFINE_CONST(stash, export, "MP4_MPEG4_ALS_AUDIO_TYPE",            newSViv(MP4_MPEG4_ALS_AUDIO_TYPE));
    DEFINE_CONST(stash, export, "MP4_MPEG4_LAYER1_AUDIO_TYPE",         newSViv(MP4_MPEG4_LAYER1_AUDIO_TYPE));
    DEFINE_CONST(stash, export, "MP4_MPEG4_LAYER2_AUDIO_TYPE",         newSViv(MP4_MPEG4_LAYER2_AUDIO_TYPE));
    DEFINE_CONST(stash, export, "MP4_MPEG4_LAYER3_AUDIO_TYPE",         newSViv(MP4_MPEG4_LAYER3_AUDIO_TYPE));
    DEFINE_CONST(stash, export, "MP4_MPEG4_SLS_AUDIO_TYPE",            newSViv(MP4_MPEG4_SLS_AUDIO_TYPE));
}

PROTOTYPES: DISABLE

void
set_log_level(klass, verbosity)
    const char* klass;
    MP4LogLevel verbosity;
CODE:
    MP4LogSetLevel(verbosity);

MP4LogLevel
get_log_level(klass)
    const char* klass;
CODE:
    RETVAL = MP4LogGetLevel();
OUTPUT:
    RETVAL

void
optimize(klass, filename, new_filename = NULL)
    const char* klass;
    const char* filename;
    const char* new_filename;
CODE:
    if (!MP4Optimize(filename, new_filename)) {
        croak("Failed to optimize: %s", filename);
    }

MP4::LibMP4v2
read(klass, filename)
    const char* klass;
    const char* filename;
CODE:
    RETVAL = MP4Read(filename);
    if (RETVAL == MP4_INVALID_FILE_HANDLE) {
        croak("Failed to open file: %s", filename);
    }
OUTPUT:
    RETVAL

void
DESTROY(self)
    MP4::LibMP4v2 self;
CODE:
    if (MP4_IS_VALID_FILE_HANDLE(self)) {
        MP4Close(self, 0);
    }

const char*
get_file_name(self)
    MP4::LibMP4v2 self;
CODE:
    RETVAL = MP4GetFilename(self);
OUTPUT:
    RETVAL

SV*
info(self, track_id = MP4_INVALID_TRACK_ID)
    MP4::LibMP4v2 self;
    MP4TrackId track_id;
PREINIT:
    char* info;
CODE:
    info = MP4Info(self, track_id);
    if (info == NULL) {
        XSRETURN_UNDEF;
    }
    RETVAL = newSVpv(info, 0);
OUTPUT:
    RETVAL

bool
have_atom(self, atom_name)
    MP4::LibMP4v2 self;
    const char* atom_name;
CODE:
    RETVAL = MP4HaveAtom(self, atom_name);
OUTPUT:
    RETVAL

uint64_t
get_integer_property(self, prop_name)
    MP4::LibMP4v2 self;
    const char* prop_name;
PREINIT:
    uint64_t retvalue;
CODE:
    if (!MP4GetIntegerProperty(self, prop_name, &retvalue)) {
        XSRETURN_UNDEF;
    }
    RETVAL = retvalue;
OUTPUT:
    RETVAL

float
get_float_property(self, prop_name)
    MP4::LibMP4v2 self;
    const char* prop_name;
PREINIT:
    float retvalue;
CODE:
    if (!MP4GetFloatProperty(self, prop_name, &retvalue)) {
        XSRETURN_UNDEF;
    }
    RETVAL = retvalue;
OUTPUT:
    RETVAL

SV*
get_string_property(self, prop_name)
    MP4::LibMP4v2 self;
    const char* prop_name;
PREINIT:
    const char* retvalue;
CODE:
    if (!MP4GetStringProperty(self, prop_name, &retvalue)) {
        XSRETURN_UNDEF;
    }
    RETVAL = newSVpv(retvalue, 0);
OUTPUT:
    RETVAL

AV*
get_bytes_property(self, prop_name)
    MP4::LibMP4v2 self;
    const char* prop_name;
PREINIT:
    uint8_t* value;
    uint32_t i, size;
CODE:
    if (!MP4GetBytesProperty(self, prop_name, &value, &size)) {
        XSRETURN_UNDEF;
    }
    RETVAL = newAV();
    for (i = 0; i < size; i++) {
        av_push(RETVAL, newSVuv(value[i]));
    }
    free(value);
OUTPUT:
    RETVAL

MP4Duration
get_duration(self)
    MP4::LibMP4v2 self;
CODE:
    RETVAL = MP4GetDuration(self);
OUTPUT:
    RETVAL

uint32_t
get_time_scale(self)
    MP4::LibMP4v2 self;
CODE:
    RETVAL = MP4GetTimeScale(self);
OUTPUT:
    RETVAL

uint8_t
get_od_profile_level(self)
    MP4::LibMP4v2 self;
CODE:
    RETVAL = MP4GetODProfileLevel(self);
OUTPUT:
    RETVAL

uint8_t
get_scene_profile_level(self)
    MP4::LibMP4v2 self;
CODE:
    RETVAL = MP4GetSceneProfileLevel(self);
OUTPUT:
    RETVAL

uint8_t
get_video_profile_level(self, track_id = MP4_INVALID_TRACK_ID)
    MP4::LibMP4v2 self;
    MP4TrackId track_id;
CODE:
    RETVAL = MP4GetVideoProfileLevel(self, track_id);
OUTPUT:
    RETVAL

uint8_t
get_audio_profile_level(self)
    MP4::LibMP4v2 self;
CODE:
    RETVAL = MP4GetAudioProfileLevel(self);
OUTPUT:
    RETVAL

uint8_t
get_graphics_profile_level(self)
    MP4::LibMP4v2 self;
CODE:
    RETVAL = MP4GetGraphicsProfileLevel(self);
OUTPUT:
    RETVAL

uint32_t
get_number_of_tracks(self, type = NULL, subtype = 0)
    MP4::LibMP4v2 self;
    const char* type;
    uint8_t subtype;
CODE:
    RETVAL = MP4GetNumberOfTracks(self, type, subtype);
OUTPUT:
    RETVAL

MP4TrackId
find_track_id(self, index, type = NULL, subtype = 0)
    MP4::LibMP4v2 self;
    uint16_t index;
    const char* type;
    uint8_t subtype;
CODE:
    RETVAL = MP4FindTrackId(self, index, type, subtype);
OUTPUT:
    RETVAL

uint16_t
find_track_index(self, track_id)
    MP4::LibMP4v2 self;
    MP4TrackId track_id;
CODE:
    RETVAL = MP4FindTrackIndex(self, track_id);
OUTPUT:
    RETVAL

MP4Duration
get_track_duration_per_chunk(self, track_id)
    MP4::LibMP4v2 self;
    MP4TrackId track_id;
PREINIT:
    MP4Duration duration;
CODE:
    if (!MP4GetTrackDurationPerChunk(self, track_id, &duration)) {
        XSRETURN_UNDEF;
    }
    RETVAL = duration;
OUTPUT:
    RETVAL

bool
have_track_atom(self, track_id, atom_name)
    MP4::LibMP4v2 self;
    MP4TrackId track_id;
    const char* atom_name;
CODE:
    RETVAL = MP4HaveTrackAtom(self, track_id, atom_name);
OUTPUT:
    RETVAL

const char*
get_track_type(self, track_id)
    MP4::LibMP4v2 self;
    MP4TrackId track_id;
CODE:
    RETVAL = MP4GetTrackType(self, track_id);
OUTPUT:
    RETVAL

const char*
get_track_media_data_name(self, track_id)
    MP4::LibMP4v2 self;
    MP4TrackId track_id;
CODE:
    RETVAL = MP4GetTrackMediaDataName(self, track_id);
OUTPUT:
    RETVAL

SV*
get_track_media_original_format(self, track_id)
    MP4::LibMP4v2 self;
    MP4TrackId track_id;
PREINIT:
    char original_format[8];
CODE:
    if (!MP4GetTrackMediaDataOriginalFormat(self, track_id, original_format, sizeof(original_format))) {
        XSRETURN_UNDEF;
    }
    RETVAL = newSVpvn(original_format, sizeof(original_format));
OUTPUT:
    RETVAL

MP4Duration
get_track_duration(self, track_id)
    MP4::LibMP4v2 self;
    MP4TrackId track_id;
CODE:
    RETVAL = MP4GetTrackDuration(self, track_id);
OUTPUT:
    RETVAL

uint32_t
get_track_time_scale(self, track_id)
    MP4::LibMP4v2 self;
    MP4TrackId track_id;
CODE:
    RETVAL = MP4GetTrackTimeScale(self, track_id);
OUTPUT:
    RETVAL

SV*
get_track_language(self, track_id)
    MP4::LibMP4v2 self;
    MP4TrackId track_id;
PREINIT:
    char code[4];
CODE:
    if (!MP4GetTrackLanguage(self, track_id, code)) {
        XSRETURN_UNDEF;
    }
    RETVAL = newSVpv(code, 0);
OUTPUT:
    RETVAL

SV*
get_track_name(self, track_id)
    MP4::LibMP4v2 self;
    MP4TrackId track_id;
PREINIT:
    char* name;
CODE:
    if (!MP4GetTrackName(self, track_id, &name)) {
        XSRETURN_UNDEF;
    }
    RETVAL = newSVpvn(name, 0);
OUTPUT:
    RETVAL

uint8_t
get_track_audio_mpeg4_type(self, track_id)
    MP4::LibMP4v2 self;
    MP4TrackId track_id;
CODE:
    RETVAL = MP4GetTrackAudioMpeg4Type(self, track_id);
OUTPUT:
    RETVAL

uint8_t
get_track_esds_object_type_id(self, track_id)
    MP4::LibMP4v2 self;
    MP4TrackId track_id;
CODE:
    RETVAL = MP4GetTrackEsdsObjectTypeId(self, track_id);
OUTPUT:
    RETVAL

MP4Duration
get_track_fixed_sample_duration(self, track_id)
    MP4::LibMP4v2 self;
    MP4TrackId track_id;
CODE:
    RETVAL = MP4GetTrackFixedSampleDuration(self, track_id);
OUTPUT:
    RETVAL

uint32_t
get_track_bit_rate(self, track_id)
    MP4::LibMP4v2 self;
    MP4TrackId track_id;
CODE:
    RETVAL = MP4GetTrackBitRate(self, track_id);
OUTPUT:
    RETVAL

AV*
get_track_video_metadata(self, track_id)
    MP4::LibMP4v2 self;
    MP4TrackId track_id;
PREINIT:
    uint8_t *config;
    uint32_t i, size;
CODE:
    if (!MP4GetTrackVideoMetadata(self, track_id, &config, &size)) {
        XSRETURN_UNDEF;
    }
    RETVAL = newAV();
    for (i = 0; i < size; i++) {
        av_push(RETVAL, newSVuv(config[i]));
    }
    MP4Free(config);
OUTPUT:
    RETVAL

AV*
get_track_es_configuration(self, track_id)
    MP4::LibMP4v2 self;
    MP4TrackId track_id;
PREINIT:
    uint8_t *config;
    uint32_t i, size;
CODE:
    if (!MP4GetTrackESConfiguration(self, track_id, &config, &size)) {
        XSRETURN_UNDEF;
    }
    RETVAL = newAV();
    for (i = 0; i < size; i++) {
        av_push(RETVAL, newSVuv(config[i]));
    }
    MP4Free(config);
OUTPUT:
    RETVAL

uint32_t
get_track_h264_length_size(self, track_id)
    MP4::LibMP4v2 self;
    MP4TrackId track_id;
PREINIT:
    uint32_t size;
CODE:
    if (!MP4GetTrackH264LengthSize(self, track_id, &size)) {
        XSRETURN_UNDEF;
    }
    RETVAL = size;
OUTPUT:
    RETVAL

MP4SampleId
get_track_number_of_samples(self, track_id)
    MP4::LibMP4v2 self;
    MP4TrackId track_id;
CODE:
    RETVAL = MP4GetTrackNumberOfSamples(self, track_id);
OUTPUT:
    RETVAL

uint16_t
get_track_video_width(self, track_id)
    MP4::LibMP4v2 self;
    MP4TrackId track_id;
CODE:
    RETVAL = MP4GetTrackVideoWidth(self, track_id);
OUTPUT:
    RETVAL

uint16_t
get_track_video_height(self, track_id)
    MP4::LibMP4v2 self;
    MP4TrackId track_id;
CODE:
    RETVAL = MP4GetTrackVideoHeight(self, track_id);
OUTPUT:
    RETVAL

double
get_track_video_frame_rate(self, track_id)
    MP4::LibMP4v2 self;
    MP4TrackId track_id;
CODE:
    RETVAL = MP4GetTrackVideoFrameRate(self, track_id);
OUTPUT:
    RETVAL

int
get_track_audio_channels(self, track_id)
    MP4::LibMP4v2 self;
    MP4TrackId track_id;
CODE:
    RETVAL = MP4GetTrackAudioChannels(self, track_id);
OUTPUT:
    RETVAL

bool
is_isma_cryp_media_track(self, track_id)
    MP4::LibMP4v2 self;
    MP4TrackId track_id;
CODE:
    RETVAL = MP4IsIsmaCrypMediaTrack(self, track_id);
OUTPUT:
    RETVAL

uint64_t
get_track_integer_property(self, track_id, prop_name)
    MP4::LibMP4v2 self;
    MP4TrackId track_id;
    const char* prop_name;
PREINIT:
    uint64_t retvalue;
CODE:
    if (!MP4GetTrackIntegerProperty(self, track_id, prop_name, &retvalue)) {
        XSRETURN_UNDEF;
    }
    RETVAL = retvalue;
OUTPUT:
    RETVAL

float
get_track_float_property(self, track_id, prop_name)
    MP4::LibMP4v2 self;
    MP4TrackId track_id;
    const char* prop_name;
PREINIT:
    float retvalue;
CODE:
    if (!MP4GetTrackFloatProperty(self, track_id, prop_name, &retvalue)) {
        XSRETURN_UNDEF;
    }
    RETVAL = retvalue;
OUTPUT:
    RETVAL

SV*
get_track_string_property(self, track_id, prop_name)
    MP4::LibMP4v2 self;
    MP4TrackId track_id;
    const char* prop_name;
PREINIT:
    const char* retvalue;
CODE:
    if (!MP4GetTrackStringProperty(self, track_id, prop_name, &retvalue)) {
        XSRETURN_UNDEF;
    }
    RETVAL = newSVpv(retvalue, 0);
OUTPUT:
    RETVAL

AV*
get_track_bytes_property(self, track_id, prop_name)
    MP4::LibMP4v2 self;
    MP4TrackId track_id;
    const char* prop_name;
PREINIT:
    uint8_t* value;
    uint32_t i, size;
CODE:
    if (!MP4GetTrackBytesProperty(self, track_id, prop_name, &value, &size)) {
        XSRETURN_EMPTY;
    }
    RETVAL = newAV();
    for (i = 0; i < size; i++) {
        av_push(RETVAL, newSVuv(value[i]));
    }
    MP4Free(value);
OUTPUT:
    RETVAL

SV*
get_hint_track_rtp_payload(self, track_id)
    MP4::LibMP4v2 self;
    MP4TrackId track_id;
PREINIT:
    char* name;
CODE:
    if (!MP4GetHintTrackRtpPayload(self, track_id, &name, NULL, NULL, NULL)) {
        XSRETURN_UNDEF;
    }
    RETVAL = newSVpv(name, 0);
OUTPUT:
    RETVAL

uint64_t
convert_from_movie_duration(self, duration, time_scale)
    MP4::LibMP4v2 self;
    MP4Duration duration;
    uint32_t time_scale;
CODE:
    RETVAL = MP4ConvertFromMovieDuration(self, duration, time_scale);
OUTPUT:
    RETVAL

uint64_t
convert_from_track_timestamp(self, track_id, timestamp, time_scale)
    MP4::LibMP4v2 self;
    MP4TrackId track_id;
    MP4Timestamp timestamp;
    uint32_t time_scale;
CODE:
    RETVAL = MP4ConvertFromTrackTimestamp(self, track_id, timestamp, time_scale);
OUTPUT:
    RETVAL

MP4Timestamp
convert_to_track_timestamp(self, track_id, timestamp, time_scale)
    MP4::LibMP4v2 self;
    MP4TrackId track_id;
    uint64_t timestamp;
    uint32_t time_scale;
CODE:
    RETVAL = MP4ConvertToTrackTimestamp(self, track_id, timestamp, time_scale);
OUTPUT:
    RETVAL

uint64_t
convert_from_track_duration(self, track_id, duration, time_scale)
    MP4::LibMP4v2 self;
    MP4TrackId track_id;
    MP4Duration duration;
    uint32_t time_scale;
CODE:
    RETVAL = MP4ConvertFromTrackDuration(self, track_id, duration, time_scale);
OUTPUT:
    RETVAL

MP4Duration
convert_to_track_duration(self, track_id, duration, time_scale)
    MP4::LibMP4v2 self;
    MP4TrackId track_id;
    uint64_t duration;
    uint32_t time_scale;
CODE:
    RETVAL = MP4ConvertToTrackDuration(self, track_id, duration, time_scale);
OUTPUT:
    RETVAL

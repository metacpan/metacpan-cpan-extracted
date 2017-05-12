#ifdef __cplusplus
"C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <errno.h>

#include "ffmpeg.h"

/* these are from cmdutils.h, declared here so we don't need to link cmdutils.o */
void show_help_options(const OptionDef *options, const char *msg, int mask, int value){}
void print_error(const char *filename, int err){}
void parse_options(int argc, char **argv, const OptionDef *options){}

/* todo, make av_log() store the error log in a perl-accessible SV* */
/* void av_log(void *avcl, int level, const char *fmt, ...){} */

MODULE = FFmpeg PACKAGE = FFmpeg

PROTOTYPES: DISABLE

int
foo(self)
	SV *self;

	CODE:
	RETVAL = 1234;

	OUTPUT:
	RETVAL

void
_init_ffmpeg (self)
	SV *self;

	CODE:
	av_register_all();

void
_run_ffmpeg(self)
	SV *self;

	CODE:
	av_encode(output_files, nb_output_files, input_files, nb_input_files, stream_maps, nb_stream_maps);

#// **********************************************************************
#//
#// setter functions to affect ffmpeg.c behavior.  these serve the same
#// purpose as ffmpeg's commandline options.
#//
#// **********************************************************************

void
_cleanup(self)
	SV *self;

	CODE:
	nb_input_files  = 0;
	nb_output_files = 0;
	nb_stream_maps  = 0;
	      /* main options */
	//    { "L", 0, {(void*)show_license}, "show license" },
	//    { "h", 0, {(void*)show_help}, "show help" },
	//    { "version", 0, {(void*)show_version}, "show version" },
	//    { "formats", 0, {(void*)show_formats}, "show available formats, codecs, protocols, ..." },


#//    { "f", HAS_ARG, {(void*)opt_format}, "force format", "fmt" },
void
_set_format(self, arg)
	SV *self;
	char *arg;

	CODE:
	opt_format(arg);

#//    { "img", HAS_ARG, {(void*)opt_image_format}, "force image format", "img_fmt" },
void
_set_image_format(self, arg)
	SV *self;
	char *arg;

	CODE:
	opt_image_format(arg);

#//    { "i", HAS_ARG, {(void*)opt_input_file}, "input file name", "filename" },
void
_set_input_file(self, arg)
	SV *self;
	char *arg;

	CODE:
	opt_input_file(arg);

#//    { "y", OPT_BOOL, {(void*)&file_overwrite}, "overwrite output files" },
void
_set_overwrite(self, o)
	SV *self;
	int o;

	CODE:
	file_overwrite = o;

#//E    { "map", HAS_ARG | OPT_EXPERT, {(void*)opt_map}, "set input stream mapping", "file:stream[:syncfile:syncstream]" },
#//E    { "map_meta_data", HAS_ARG | OPT_EXPERT, {(void*)opt_map_meta_data}, "set meta data information of outfile from infile", "outfile:infile" },
#//    { "t", HAS_ARG, {(void*)opt_recording_time}, "set the recording time", "duration" },
void
_set_recording_time(self, arg)
	SV *self;
	char *arg;

	CODE:
	opt_recording_time(arg);

#//    { "fs", HAS_ARG | OPT_INT, {(void*)&limit_filesize}, "set the limit file size", "limit_size" }, //
#//    { "ss", HAS_ARG, {(void*)opt_start_time}, "set the start time offset", "time_off" },
void
_set_start_time(self, arg)
	SV *self;
	char *arg;

	CODE:
	opt_start_time(arg);

#//    { "itsoffset", HAS_ARG, {(void*)opt_input_ts_offset}, "set the input ts offset", "time_off" },
#//    { "title", HAS_ARG | OPT_STRING, {(void*)&str_title}, "set the title", "string" },
#//    { "timestamp", HAS_ARG, {(void*)&opt_rec_timestamp}, "set the timestamp", "time" },
#//    { "author", HAS_ARG | OPT_STRING, {(void*)&str_author}, "set the author", "string" },
#//    { "copyright", HAS_ARG | OPT_STRING, {(void*)&str_copyright}, "set the copyright", "string" },
#//    { "comment", HAS_ARG | OPT_STRING, {(void*)&str_comment}, "set the comment", "string" },
#//E    { "benchmark", OPT_BOOL | OPT_EXPERT, {(void*)&do_benchmark}, "add timings for benchmarking" },
#//E    { "dump", OPT_BOOL | OPT_EXPERT, {(void*)&do_pkt_dump}, "dump each input packet" },
#//E    { "hex", OPT_BOOL | OPT_EXPERT, {(void*)&do_hex_dump}, "when dumping packets, also dump the payload" },
#//E    { "re", OPT_BOOL | OPT_EXPERT, {(void*)&rate_emu}, "read input at native frame rate", "" },
#//E    { "loop_input", OPT_BOOL | OPT_EXPERT, {(void*)&loop_input}, "loop (current only works with images)" },
#//E    { "loop_output", HAS_ARG | OPT_INT | OPT_EXPERT, {(void*)&loop_output}, "number of times to loop output in formats that support looping (0 loops forever)", "" },
#//    { "v", HAS_ARG, {(void*)opt_verbose}, "control amount of logging", "verbose" },
void
_set_verbose(self, v)
	SV *self;
	int v;

	CODE:
	verbose = v;

#//    { "target", HAS_ARG, {(void*)opt_target}, "specify target file type (\"vcd\", \"svcd\", \"dvd\", \"dv\", \"dv50\", \"pal-vcd\", \"ntsc-svcd\", ...)", "type" },
#//E    { "threads", HAS_ARG | OPT_EXPERT, {(void*)opt_thread_count}, "thread count", "count" },
#//E    { "vsync", HAS_ARG | OPT_INT | OPT_EXPERT, {(void*)&video_sync_method}, "video sync method", "" },
#//E    { "async", HAS_ARG | OPT_INT | OPT_EXPERT, {(void*)&audio_sync_method}, "audio sync method", "" },
#//E    { "vglobal", HAS_ARG | OPT_INT | OPT_EXPERT, {(void*)&video_global_header}, "video global header storage type", "" },
#//E    { "copyts", OPT_BOOL | OPT_EXPERT, {(void*)&copy_ts}, "copy timestamps" },
#//E    { "shortest", OPT_BOOL | OPT_EXPERT, {(void*)&opt_shortest}, "finish encoding within shortest input" }, //
#//E    { "dts_delta_threshold", HAS_ARG | OPT_INT | OPT_EXPERT, {(void*)&dts_delta_threshold}, "timestamp discontinuity delta threshold", "" },
#    /* video options */ 
#//    { "b", HAS_ARG | OPT_VIDEO, {(void*)opt_video_bitrate}, "set video bitrate (in kbit/s)", "bitrate" },
void
_set_video_bitrate(self, arg)
	SV *self;
	char *arg;

	CODE:
	opt_video_bitrate(arg);

#//    { "vframes", OPT_INT | HAS_ARG | OPT_VIDEO, {(void*)&max_frames[CODEC_TYPE_VIDEO]}, "set the number of video frames to record", "number" },
#//    { "aframes", OPT_INT | HAS_ARG | OPT_AUDIO, {(void*)&max_frames[CODEC_TYPE_AUDIO]}, "set the number of audio frames to record", "number" },
#//    { "dframes", OPT_INT | HAS_ARG, {(void*)&max_frames[CODEC_TYPE_DATA]}, "set the number of data frames to record", "number" },
#//    { "r", HAS_ARG | OPT_VIDEO, {(void*)opt_frame_rate}, "set frame rate (Hz value, fraction or abbreviation)", "rate" },
void
_set_video_rate(self, arg)
    SV *self;
    char *arg;

    CODE:
    opt_frame_rate(arg);

#//    { "s", HAS_ARG | OPT_VIDEO, {(void*)opt_frame_size}, "set frame size (WxH or abbreviation)", "size" },
void
_set_video_geometry(self, arg)
	SV *self;
	char *arg;

	CODE:
	opt_frame_size(arg);

#//    { "aspect", HAS_ARG | OPT_VIDEO, {(void*)opt_frame_aspect_ratio}, "set aspect ratio (4:3, 16:9 or 1.3333, 1.7777)", "aspect" },
#//E    { "pix_fmt", HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)opt_frame_pix_fmt}, "set pixel format", "format" },
#//    { "croptop", HAS_ARG | OPT_VIDEO, {(void*)opt_frame_crop_top}, "set top crop band size (in pixels)", "size" },
#//    { "cropbottom", HAS_ARG | OPT_VIDEO, {(void*)opt_frame_crop_bottom}, "set bottom crop band size (in pixels)", "size" },
#//    { "cropleft", HAS_ARG | OPT_VIDEO, {(void*)opt_frame_crop_left}, "set left crop band size (in pixels)", "size" },
#//    { "cropright", HAS_ARG | OPT_VIDEO, {(void*)opt_frame_crop_right}, "set right crop band size (in pixels)", "size" },
#//    { "padtop", HAS_ARG | OPT_VIDEO, {(void*)opt_frame_pad_top}, "set top pad band size (in pixels)", "size" },
#//    { "padbottom", HAS_ARG | OPT_VIDEO, {(void*)opt_frame_pad_bottom}, "set bottom pad band size (in pixels)", "size" },
#//    { "padleft", HAS_ARG | OPT_VIDEO, {(void*)opt_frame_pad_left}, "set left pad band size (in pixels)", "size" },
#//    { "padright", HAS_ARG | OPT_VIDEO, {(void*)opt_frame_pad_right}, "set right pad band size (in pixels)", "size" },
#//    { "padcolor", HAS_ARG | OPT_VIDEO, {(void*)opt_pad_color}, "set color of pad bands (Hex 000000 thru FFFFFF)", "color" },
#//E    { "g", HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)opt_gop_size}, "set the group of picture size", "gop_size" },
#//E    { "intra", OPT_BOOL | OPT_EXPERT | OPT_VIDEO, {(void*)&intra_only}, "use only intra frames"},
#//    { "vn", OPT_BOOL | OPT_VIDEO, {(void*)&video_disable}, "disable video" },
#//E    { "vdt", OPT_INT | HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)&video_discard}, "discard threshold", "n" },
#//E    { "qscale", HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)opt_qscale}, "use fixed video quantiser scale (VBR)", "q" },
#//E    { "qmin", HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)opt_qmin}, "min video quantiser scale (VBR)", "q" },
#//E    { "qmax", HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)opt_qmax}, "max video quantiser scale (VBR)", "q" },
#//E    { "lmin", HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)opt_lmin}, "min video lagrange factor (VBR)", "lambda" },
#//E    { "lmax", HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)opt_lmax}, "max video lagrange factor (VBR)", "lambda" },
#//E    { "mblmin", HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)opt_mb_lmin}, "min macroblock quantiser scale (VBR)", "q" },
#//E    { "mblmax", HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)opt_mb_lmax}, "max macroblock quantiser scale (VBR)", "q" },
#//E    { "qdiff", HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)opt_qdiff}, "max difference between the quantiser scale (VBR)", "q" },
#//E    { "qblur", HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)opt_qblur}, "video quantiser scale blur (VBR)", "blur" },
#//E    { "qsquish", HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)opt_qsquish}, "how to keep quantiser between qmin and qmax (0 = clip, 1 = use differentiable function)", "squish" },
#//E    { "qcomp", HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)opt_qcomp}, "video quantiser scale compression (VBR)", "compression" },
#//E    { "rc_init_cplx", HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)opt_rc_initial_cplx}, "initial complexity for 1-pass encoding", "complexity" },
#//E    { "b_qfactor", HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)opt_b_qfactor}, "qp factor between p and b frames", "factor" },
#//E    { "i_qfactor", HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)opt_i_qfactor}, "qp factor between p and i frames", "factor" },
#//E    { "b_qoffset", HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)opt_b_qoffset}, "qp offset between p and b frames", "offset" },
#//E    { "i_qoffset", HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)opt_i_qoffset}, "qp offset between p and i frames", "offset" },
#//E    { "ibias", HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)opt_ibias}, "intra quant bias", "bias" },
#//E    { "pbias", HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)opt_pbias}, "inter quant bias", "bias" },
#//E    { "rc_eq", HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)opt_video_rc_eq}, "set rate control equation", "equation" },
#//E    { "rc_override", HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)opt_video_rc_override_string}, "rate control override for specific intervals", "override" },
#//    { "bt", HAS_ARG | OPT_VIDEO, {(void*)opt_video_bitrate_tolerance}, "set video bitrate tolerance (in kbit/s)", "tolerance" },
#//    { "maxrate", HAS_ARG | OPT_VIDEO, {(void*)opt_video_bitrate_max}, "set max video bitrate tolerance (in kbit/s)", "bitrate" },
#//    { "minrate", HAS_ARG | OPT_VIDEO, {(void*)opt_video_bitrate_min}, "set min video bitrate tolerance (in kbit/s)", "bitrate" },
#//    { "bufsize", HAS_ARG | OPT_VIDEO, {(void*)opt_video_buffer_size}, "set ratecontrol buffer size (in kByte)", "size" },
#//    { "vcodec", HAS_ARG | OPT_VIDEO, {(void*)opt_video_codec}, "force video codec ('copy' to copy stream)", "codec" },
void
_set_video_codec(self, arg)
	SV *self;
	char *arg;

	CODE:
	opt_video_codec(arg);

#//E    { "me", HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)opt_motion_estimation}, "set motion estimation method", "method" },
#//E    { "me_threshold", HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)opt_me_threshold}, "motion estimaton threshold",  "" },
#//E    { "mb_threshold", HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)opt_mb_threshold}, "macroblock threshold",  "" },
#//E    { "bf", HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)opt_b_frames}, "use 'frames' B frames", "frames" },
#//E    { "preme", HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)opt_pre_me}, "pre motion estimation", "" },
#//E    { "bug", HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)opt_workaround_bugs}, "workaround not auto detected encoder bugs", "param" },
#//E    { "ps", HAS_ARG | OPT_EXPERT, {(void*)opt_packet_size}, "set packet size in bits", "size" },
#//E    { "error", HAS_ARG | OPT_EXPERT, {(void*)opt_error_rate}, "error rate", "rate" },
#//E    { "strict", HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)opt_strict}, "how strictly to follow the standards", "strictness" },
#//    { "sameq", OPT_BOOL | OPT_VIDEO, {(void*)&same_quality}, "use same video quality as source (implies VBR)" },
#//    { "pass", HAS_ARG | OPT_VIDEO, {(void*)&opt_pass}, "select the pass number (1 or 2)", "n" },
#//    { "passlogfile", HAS_ARG | OPT_STRING | OPT_VIDEO, {(void*)&pass_logfilename}, "select two pass log file name", "file" },
#//E    { "deinterlace", OPT_BOOL | OPT_EXPERT | OPT_VIDEO, {(void*)&do_deinterlace}, "deinterlace pictures" },
#//E    { "psnr", OPT_BOOL | OPT_EXPERT | OPT_VIDEO, {(void*)&do_psnr}, "calculate PSNR of compressed frames" },
#//E    { "vstats", OPT_BOOL | OPT_EXPERT | OPT_VIDEO, {(void*)&do_vstats}, "dump video coding statistics to file" },
#//E    { "vhook", HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)add_frame_hooker}, "insert video processing module", "module" },
#//E    { "intra_matrix", HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)opt_intra_matrix}, "specify intra matrix coeffs", "matrix" },
#//E    { "inter_matrix", HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)opt_inter_matrix}, "specify inter matrix coeffs", "matrix" },
#//E    { "top", HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)opt_top_field_first}, "top=1/bottom=0/auto=-1 field first", "" },
#//E    { "sc_threshold", HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)opt_sc_threshold}, "scene change threshold", "threshold" },
#//E    { "me_range", HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)opt_me_range}, "limit motion vectors range (1023 for DivX player)", "range" },
#//E    { "dc", OPT_INT | HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)&intra_dc_precision}, "intra_dc_precision", "precision" },
#//E    { "mepc", OPT_INT | HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)&me_penalty_compensation}, "motion estimation bitrate penalty compensation", "factor (1.0 = 256)" },
#//E    { "vtag", HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)opt_video_tag}, "force video tag/fourcc", "fourcc/tag" },
#//E    { "skip_threshold", OPT_INT | HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)&frame_skip_threshold}, "frame skip threshold", "threshold" },
#//E    { "skip_factor", OPT_INT | HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)&frame_skip_factor}, "frame skip factor", "factor" },
#//E    { "skip_exp", OPT_INT | HAS_ARG | OPT_EXPERT | OPT_VIDEO, {(void*)&frame_skip_exp}, "frame skip exponent", "exponent" },
#//    { "newvideo", OPT_VIDEO, {(void*)opt_new_video_stream}, "add a new video stream to the current output stream" },
#//E    { "genpts", OPT_BOOL | OPT_EXPERT | OPT_VIDEO, { (void *)&genpts }, "generate pts" },
#//E    { "qphist", OPT_BOOL | OPT_EXPERT | OPT_VIDEO, { (void *)&qp_hist }, "show QP histogram" },
#    /* audio options */
#//    { "ab", HAS_ARG | OPT_AUDIO, {(void*)opt_audio_bitrate}, "set audio bitrate (in kbit/s)", "bitrate", },
void
_set_audio_bitrate(self, arg)
	SV *self;
	char *arg;

	CODE:
	opt_audio_bitrate(arg);

#//    { "aq", OPT_FLOAT | HAS_ARG | OPT_AUDIO, {(void*)&audio_qscale}, "set audio quality (codec-specific)", "quality", },
#//    { "ar", HAS_ARG | OPT_AUDIO, {(void*)opt_audio_rate}, "set audio sampling rate (in Hz)", "rate" },
void
_set_audio_rate(self, arg)
	SV *self;
	char *arg;

	CODE:
	opt_audio_rate(arg);

#//    { "ac", HAS_ARG | OPT_AUDIO, {(void*)opt_audio_channels}, "set number of audio channels", "channels" },
#//    { "an", OPT_BOOL | OPT_AUDIO, {(void*)&audio_disable}, "disable audio" },
#//    { "acodec", HAS_ARG | OPT_AUDIO, {(void*)opt_audio_codec}, "force audio codec ('copy' to copy stream)", "codec" },
void
_set_audio_codec(self, arg)
	SV *self;
	char *arg;

	CODE:
	opt_audio_codec(arg);

#//E    { "atag", HAS_ARG | OPT_EXPERT | OPT_AUDIO, {(void*)opt_audio_tag}, "force audio tag/fourcc", "fourcc/tag" },
#//    { "vol", OPT_INT | HAS_ARG | OPT_AUDIO, {(void*)&audio_volume}, "change audio volume (256=normal)" , "volume" }, //
#//    { "newaudio", OPT_AUDIO, {(void*)opt_new_audio_stream}, "add a new audio stream to the current output stream" },
#//    { "alang", HAS_ARG | OPT_STRING | OPT_AUDIO, {(void *)&audio_language}, "set the ISO 639 language code (3 letters) of the current audio stream" , "code" },
#    /* subtitle options */
#//    { "scodec", HAS_ARG | OPT_SUBTITLE, {(void*)opt_subtitle_codec}, "force subtitle codec ('copy' to copy stream)", "codec" },
#//    { "newsubtitle", OPT_SUBTITLE, {(void*)opt_new_subtitle_stream}, "add a new subtitle stream to the current output stream" },
#//    { "slang", HAS_ARG | OPT_STRING | OPT_SUBTITLE, {(void *)&subtitle_language}, "set the ISO 639 language code (3 letters) of the current subtitle stream" , "code" },
#    /* grab options */
#//E    { "vd", HAS_ARG | OPT_EXPERT | OPT_VIDEO | OPT_GRAB, {(void*)opt_video_device}, "set video grab device", "device" },
#//E    { "vc", HAS_ARG | OPT_EXPERT | OPT_VIDEO | OPT_GRAB, {(void*)opt_video_channel}, "set video grab channel (DV1394 only)", "channel" },
#//E    { "tvstd", HAS_ARG | OPT_EXPERT | OPT_VIDEO | OPT_GRAB, {(void*)opt_video_standard}, "set television standard (NTSC, PAL (SECAM))", "standard" },
#//E    { "ad", HAS_ARG | OPT_EXPERT | OPT_AUDIO | OPT_GRAB, {(void*)opt_audio_device}, "set audio device", "device" },
#    /* G.2 grab options */
#//E    { "grab", HAS_ARG | OPT_EXPERT | OPT_GRAB, {(void*)opt_grab}, "request grabbing using", "format" },
#//E    { "gd", HAS_ARG | OPT_EXPERT | OPT_VIDEO | OPT_GRAB, {(void*)opt_grab_device}, "set grab device", "device" },
#    /* muxer options */
#//E    { "muxrate", OPT_INT | HAS_ARG | OPT_EXPERT, {(void*)&mux_rate}, "set mux rate", "rate" },
#//E    { "packetsize", OPT_INT | HAS_ARG | OPT_EXPERT, {(void*)&mux_packet_size}, "set packet size", "size" },
#//E    { "muxdelay", OPT_FLOAT | HAS_ARG | OPT_EXPERT, {(void*)&mux_max_delay}, "set the maximum demux-decode delay", "seconds" },
#//E    { "muxpreload", OPT_FLOAT | HAS_ARG | OPT_EXPERT, {(void*)&mux_preload}, "set the initial demux-decode delay", "seconds" },
#
#//E    { "absf", HAS_ARG | OPT_AUDIO | OPT_EXPERT, {(void*)opt_audio_bsf}, "", "bitstream filter" },
#//E    { "vbsf", HAS_ARG | OPT_VIDEO | OPT_EXPERT, {(void*)opt_video_bsf}, "", "bitstream filter" },
#
#//E    { "default", OPT_FUNC2 | HAS_ARG | OPT_AUDIO | OPT_VIDEO | OPT_EXPERT, {(void*)opt_default}, "generic catch all option", "" },


#//
void
_set_output_file(self, arg)
	SV *self;
	char *arg;

	CODE:
	opt_output_file(arg);

#// **********************************************************************
#//
#// custom functions to access libavcodec/libavformat file/stream metadata
#// from perl.
#//
#// **********************************************************************

HV*
_image_formats(self)
	SV *self;

	CODE:
	{

	HV *hash = newHV();

	AVInputFormat *ifmt;
	AVOutputFormat *ofmt;
	AVImageFormat *image_fmt;
	URLProtocol *up;
	AVCodec *p, *p2;
	const char **pp, *last_name;

	last_name = "000";

	for (image_fmt = first_image_format; image_fmt != NULL; image_fmt = image_fmt->next) {

		hv_store(
			hash, image_fmt->name, strlen(image_fmt->name), 
			newSVpvf("%s%s", image_fmt->img_read ? "D":" ", 
			image_fmt->img_write ? "E":" "), 0
		);
	}

	RETVAL = hash;

	}

	OUTPUT:
	RETVAL

HV* _file_formats(self)
	SV *self;

	CODE:
	{

	HV *hash = newHV();

	AVInputFormat *ifmt;
	AVOutputFormat *ofmt;
	AVImageFormat *image_fmt;
	URLProtocol *up;
	AVCodec *p, *p2;
	const char **pp, *last_name;

	// hv_store(hash, "callalert", strlen("callalert"), newSVpv("jkl;",0), 0);

	last_name = "000";

	for(;;) {

		int decode = 0;
		int encode = 0;
		const char *name=NULL;
		const char *longname=NULL;
		const char *mimetype=NULL;
        const char *extensions=NULL;

		for (ofmt = first_oformat; ofmt != NULL; ofmt = ofmt->next) {

		if ((name == NULL || strcmp(ofmt->name, name)<0) && strcmp(ofmt->name, last_name)>0) {
			name= ofmt->name;
			longname= ofmt->long_name;
			mimetype= ofmt->mime_type;
            extensions= ofmt->extensions;
			encode=1;
		}

		}

		for (ifmt = first_iformat; ifmt != NULL; ifmt = ifmt->next) {

			if ((name == NULL || strcmp(ifmt->name, name) < 0) && strcmp(ifmt->name, last_name)>0) {
				name= ifmt->name;
				longname= ifmt->long_name;
                extensions= ifmt->extensions;
				encode=0;
			}

			if (name && strcmp(ifmt->name, name) == 0) {
				decode = 1;
			}
		}

		if (name == NULL) {
			break;
		}

		last_name= name;
		HV *codec = newHV();

		hv_store(hash, name, strlen(name), newRV_noinc((SV *) codec), 0);

		hv_store(codec,"capabilities",strlen("capabilities"),
			newSVpvf("%s%s", decode ? "D":" ", encode ? "E":" "),0
		);

		hv_store(codec,"name",strlen("name"), newSVpvf("%s",name),0);
		hv_store(codec,"description",strlen("description"), newSVpvf("%s",longname),0);

		if (mimetype) {
			hv_store(codec,"mime_type",strlen("mime_type"), newSVpvf("%s",mimetype),0);
		}

		if (extensions) {
			hv_store(codec,"extensions",strlen("extensions"), newSVpvf("%s",extensions),0);
		}
	}

	RETVAL = hash;
	}

	OUTPUT:
	RETVAL

int
_init_AVFormatContext(self)
	SV *self;

	CODE:
	RETVAL = (int)av_malloc(sizeof(AVFormatContext));

	OUTPUT:
	RETVAL

void
_free_AVFormatContext(self, ic_addr)
	SV *self;
	int ic_addr;

	CODE:
	{

	AVFormatContext *ic = (AVFormatContext *) ic_addr;
	av_free(ic);

	}

HV*
_init_streamgroup(self, ic_addr, filename)
	SV *self;
	int ic_addr;
	char *filename;

	CODE:
	{
	HV *hash = newHV();
	HV *stream = newHV();

	hv_store(hash,"stream",strlen("stream"), newRV_noinc((SV *) stream),0);

	AVFormatContext *ic = (AVFormatContext *) ic_addr;
	AVFormatParameters params, *ap = &params;
	int err, i, flags;
	char buf[256];

	ap->image_format = image_format;

	err = av_open_input_file(&ic, filename, file_iformat, 0, ap);

	if (err < 0) {
		hv_store(hash,"error",strlen("error"),newSVpvf("av_open_input_file returned: %d", err),0);
		XSRETURN_UNDEF;
	}

	err = av_find_stream_info(ic);

	if (err < 0) {
		hv_store(
			hash,"error",strlen("error"),
			newSVpvf("av_find_stream_info could not find codec parameters; returned: %d", err),0
		);

		XSRETURN_UNDEF;
	}

	hv_store(hash,"format",strlen("format"), newSVpvf("%s", ic->iformat->name,PL_na), 0);

	hv_store(hash,"url",   strlen("url"), newSVpvf("%s",filename),0);
	hv_store(hash,"title",strlen("title"), newSVpvf("%s",ic->title),0);
	hv_store(hash,"author",strlen("author"), newSVpvf("%s",ic->author),0);
	hv_store(hash,"copyright",strlen("copyright"), newSVpvf("%s",ic->copyright),0);
	hv_store(hash,"comment",strlen("comment"), newSVpvf("%s",ic->comment),0);
	hv_store(hash,"album",strlen("album"), newSVpvf("%s",ic->album),0);
	hv_store(hash,"genre",strlen("genre"), newSVpvf("%s",ic->genre),0);

	hv_store(hash,"year",strlen("year"), newSViv(ic->year),0);
	hv_store(hash,"track",strlen("track"), newSViv(ic->track),0);
	hv_store(hash,"file_size",strlen("file_size"), newSViv(ic->file_size),0);
	hv_store(hash,"data_offset",strlen("data_offset"), newSViv(ic->data_offset),0);

	if (ic->duration != AV_NOPTS_VALUE) {

        //
        // moving away from Time::Piece, let's try giving back the raw AVFormatContext duration
        // and time base (inverse seconds) to perl, and manipulating in there.  i suspect
        // this HH:MM:SS formatting is somehow causing malloc() unitialized memory problems under
        // mod_perl.
        //
		//int hours, mins, secs, dsecs;
		//secs  = ic->duration / AV_TIME_BASE;
		//dsecs = ic->duration % AV_TIME_BASE;
		//mins  = secs / 60;
		//secs %= 60;
		//hours = mins / 60;
		//mins %= 60;
		//hv_store(hash,"duration",strlen("duration"), newSVpvf("%02d:%02d:%02d", hours, mins, secs), 0);

        hv_store(hash,"duration",strlen("duration"),newSVpvf("%u",ic->duration), 0);
        hv_store(hash,"AV_TIME_BASE",strlen("AV_TIME_BASE"),newSViv(AV_TIME_BASE), 0);
	}

	hv_store(hash,"bit_rate",strlen("bit_rate"), newSViv(ic->bit_rate),0);

	for (i = 0; i < ic->nb_streams; i++) {

		AVStream *st = ic->streams[i];

		HV *tstream = newHV();

		char stream_name[9];
		snprintf(stream_name, 10, "stream%02d", i);

		hv_store(stream,stream_name,strlen(stream_name), newRV_noinc((SV *) tstream),0);

		AVCodecContext *ctx = st->codec;
		AVCodec *codec = ctx->codec;

		/* AVFormatContext values */
		hv_store(tstream,"index",strlen("index"), newSViv(st->index),0);
		hv_store(tstream,"id",strlen("id"), newSViv(st->id),0);
		hv_store(tstream,"real_frame_rate",strlen("real_frame_rate"), newSVnv(av_q2d(st->r_frame_rate)),0);
//fprintf(stderr,"A %f\n", av_q2d(st->r_frame_rate));
		hv_store(tstream,"real_frame_rate_base",strlen("real_frame_rate_base"), newSVnv(av_q2d(st->time_base)),0);
//fprintf(stderr,"B %f\n", av_q2d(st->time_base));
		//hv_store(tstream,"real_frame_rate_base",strlen("real_frame_rate_base"), newSViv(av_q2d(st->time_base)),0);
		hv_store(tstream,"start_time",strlen("start_time"), newSViv(st->start_time),0);
		hv_store(tstream,"duration",strlen("duration"), newSViv(st->duration),0);

		hv_store(tstream,"quality",strlen("quality"), newSVnv(st->quality),0);

		/* AVCodecContext values */
		hv_store(tstream,"bit_rate",strlen("bit_rate"), newSViv(ctx->bit_rate),0);
		hv_store(tstream,"bit_rate_tolerance",strlen("bit_rate_tolerance"), newSViv(ctx->bit_rate_tolerance),0);
//fprintf(stderr,"C %f\n", av_q2d(ctx->time_base));
		hv_store(tstream,"video_rate",strlen("video_rate"), newSVnv(av_q2d(ctx->time_base)),0);
		hv_store(tstream,"width",strlen("width"), newSViv(ctx->width),0);
		hv_store(tstream,"height",strlen("height"), newSViv(ctx->height),0);
		hv_store(tstream,"sample_rate",strlen("sample_rate"), newSViv(ctx->sample_rate),0);
		hv_store(tstream,"channels",strlen("channels"), newSViv(ctx->channels),0);
		hv_store(tstream,"sample_format",strlen("sample_format"), newSViv(ctx->sample_fmt),0);

		/* do we want to initalize these???
		hv_store(tstream,"video_geometry",strlen("video_geometry"), newSViv(ctx->frame_size),0);
		hv_store(tstream,"frame_number",strlen("frame_number"), newSViv(ctx->frame_number),0);
		hv_store(tstream,"real_pict_number",strlen("real_pict_number"), newSViv(ctx->real_pict_num),0);

		hv_store(tstream,"codec_name",strlen("codec_name"), newSVpvf("%s",ctx->codec_name),0); */

		hv_store(tstream,"codec_id",strlen("codec_id"), newSViv(ctx->codec_id),0);
		hv_store(tstream,"codec_tag",strlen("codec_tag"), newSVuv(ctx->codec_tag),0);

		/* PixelFormat - initialize?
		hv_store(tstream,"color_table_id",strlen("color_table_id"), newSViv(ctx->color_table_id),0); */
	}

	RETVAL = hash;
	}

	OUTPUT:
	RETVAL

HV*
_codecs(self)
	SV *self;

	CODE:
	{

	HV *hash = newHV();

	AVInputFormat *ifmt;
	AVOutputFormat *ofmt;
	AVImageFormat *image_fmt;
	URLProtocol *up;
	AVCodec *p, *p2;
	const char **pp, *last_name;

	last_name = "000";

	for (;;) {

		int decode=0;
		int encode=0;
		int cap=0;

		p2 = NULL;

		for (p = first_avcodec; p != NULL; p = p->next) {

			if ((p2==NULL || strcmp(p->name, p2->name)<0) && strcmp(p->name, last_name) > 0) {
				p2= p;
				decode= encode= cap=0;
			}

			if (p2 && strcmp(p->name, p2->name) == 0) {

				if (p->decode) decode = 1;
				if (p->encode) encode = 1;
				cap |= p->capabilities;
			}

		}

		if (p2 == NULL) {
			break;
		}

		last_name= p2->name;

		hv_store(hash, p2->name, strlen(p2->name),
			newSVpvf(
				"[%x]%s%s%s", p2->id, decode ? "D" : " ", 
				encode ? "E" : " ", p2->type == CODEC_TYPE_AUDIO ? "A" : "V"
			), 0
		);
	}

	RETVAL = hash;

	}

	OUTPUT:
	RETVAL

/*
 * Perl settings
 *
 */

#ifndef AD_PERL_STRUCT_H_
#define AD_PERL_STRUCT_H_

#include "ts_parse.h"

//-----------------------------------------------------------------------------------------------------------------------------------------
// Defaults for these settings

#define DEF_max_advert			(3*60*FPS)
#define DEF_min_advert			(3*60*FPS)
#define DEF_min_program			(5*60*FPS)
#define DEF_start_pad			(2*60*FPS)
#define DEF_end_pad				(2*60*FPS)
#define DEF_min_frames 	 		2
#define DEF_frame_window 	 	4
#define DEF_max_gap 		 	10
#define DEF_reduce_end			0
#define DEF_reduce_min_gap	 	60*FPS

#define set_def_perl_setting(settings, name)	settings->perl_set.name = DEF_##name
#define set_perl_setting(settings, name, val)	settings->perl_set.name = val
#define set_default_perl_settings(settings)		\
		set_def_perl_setting(settings, max_advert) ;\
		set_def_perl_setting(settings, min_advert) ;\
		set_def_perl_setting(settings, min_program) ;\
		set_def_perl_setting(settings, start_pad) ;\
		set_def_perl_setting(settings, end_pad) ;\
		set_def_perl_setting(settings, min_frames) ;\
		set_def_perl_setting(settings, frame_window) ;\
		set_def_perl_setting(settings, max_gap) ;\
		set_def_perl_setting(settings, reduce_end) ;\
		set_def_perl_setting(settings, reduce_min_gap) ;

// Specify the actual values - different for each detector type
#define set_perl_settings(settings, mx_ad, mn_ad, mn_pr, s_pd, e_pd, mn_fr, fr_wn, mx_gp, r_en, r_mn_gp)		\
		set_perl_setting(settings, max_advert, mx_ad) ;\
		set_perl_setting(settings, min_advert, mn_ad) ;\
		set_perl_setting(settings, min_program, mn_pr) ;\
		set_perl_setting(settings, start_pad, s_pd) ;\
		set_perl_setting(settings, end_pad, e_pd) ;\
		set_perl_setting(settings, min_frames, mn_fr) ;\
		set_perl_setting(settings, frame_window, fr_wn) ;\
		set_perl_setting(settings, max_gap, mx_gp) ;\
		set_perl_setting(settings, reduce_end, r_en) ;\
		set_perl_setting(settings, reduce_min_gap, r_mn_gp) ;


//-----------------------------------------------------------------------------------------------------------------------------------------
// Structure of settings only used by Perl
//
struct Ad_perl_settings {
	unsigned max_advert ;
	unsigned min_advert ;
	unsigned min_program ;
	unsigned start_pad ;
	unsigned end_pad ;
	unsigned min_frames ;
	unsigned frame_window ;
	unsigned max_gap ;
	unsigned reduce_end ;
	unsigned reduce_min_gap ;
} ;

#endif

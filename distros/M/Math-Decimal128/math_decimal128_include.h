
#ifdef OLDPERL
#define SvUOK SvIsUV
#endif

#ifndef Newx
#  define Newx(v,n,t) New(0,v,n,t)
#endif

/* A perl bug in perl-5.20 onwards can break &PL_sv_yes and  *
 * &PL_sv_no. In the overload subs we therefore instead      *
 * use  SvTRUE_nomg_NN where possible, which is available    *
 * beginning with perl-5.18.0.                               *
 * Otherwise we continue using &PL_sv_yes as original        *
 * (&PL_sv_no is not used by this module.)                   *
 * See See https://github.com/sisyphus/math-decimal64/pull/1 */

#if defined SvTRUE_nomg_NN
#define SWITCH_ARGS SvTRUE_nomg_NN(third)
#else
#define SWITCH_ARGS third==&PL_sv_yes
#endif

/*************************************************************
 * In certain situations SvIVX and SvUVX cause crashes on    *
 * mingw-w64 x64 builds. Behaviour varies with different     *
 * versions of perl, different versions of gcc and different *
 *  versions of mingw-runtime. I've just taken a blanket     *
 *  approach - I don't think the minimal gain in performance *
 *  offered by SvIVX/SvUVX over SvIV/SvUV justifies going to *
 *  much trouble. Hence we define the following:             *
 *************************************************************/

#ifdef __MINGW64__
#define M_D128_SvIV SvIV
#define M_D128_SvUV SvUV
#else
#define M_D128_SvIV SvIVX
#define M_D128_SvUV SvUVX
#endif

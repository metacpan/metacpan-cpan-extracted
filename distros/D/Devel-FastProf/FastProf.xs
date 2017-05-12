/* -*- Mode: C -*- */

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <string.h>
#include <stdio.h>
#include <sys/file.h>
#include <sys/types.h>
#include <unistd.h>

static FILE *out = 0;
static char *outname;

static HV *file_id_hv;

#if defined (HAS_GETTIMEOD)
static struct timeval old_time;
#else
static UV old_time[2];
static int (*u2time)(pTHX_ UV *) = 0;
#endif

static struct tms old_tms;
static int usecputime = 1;
static int canfork = 0;

static char *old_fn = "";
static IV old_line = 0;


#define putmark(mark) putc(-(mark), out)
#define putpvn(str, len) { putiv(aTHX_ (len)); fwrite((str), 1, (len), out); }
#define putpv(str) { STRLEN len = strlen((str)); putpvn((str), len); }
#define put0() putc(0, (out))

#if !defined(OutCopFILE)
#define OutCopFILE CopFILE
#endif

/* some kind of huffman encoding for numbers */

static void
_putiv(pTHX_ U32 n) {
    n-=128;
    if (n < 16384) {
        putc((n>>8) | 0x80, out);
        putc(n & 0xff, out);
    }
    else {
        n -= 16384;
        if (n < 2097152) {
            putc((n>>16) | 0xc0, out);
            putc((n>>8) & 0xff, out);
            putc(n & 0xff, out);
        }
        else {
            n -= 2097152;
            if (n < 268435456) {
                putc((n>>24) | 0xe0, out);
                putc((n>>16) & 0xff, out);
                putc((n>>8) & 0xff, out);
                putc(n & 0xff, out);
            }
            else {
                n -= 268435456;
                putc(0xf0, out);
                putc((n>>24), out);
                putc((n>>16) & 0xff, out);
                putc((n>>8) & 0xff, out);
                putc(n & 0xff, out);
            }
        }
    }
}

static void
putiv(pTHX_ I32 i32) {
    U32 n = (U32)i32;
    if (n < 128)
        putc(n, out);
    else 
        _putiv(aTHX_ n);
}

static void
putav(pTHX_ AV *av) {
    UV nl = av_len(av)+1;
    UV i;
    putiv(aTHX_ nl);
    for (i=0; i<nl; i++) {
        SV **psv = av_fetch(av, i, 0);
        STRLEN ll;
        char *data;
        if (psv) {
            data = SvPV(*psv, ll);
            putpvn(data, ll);
        }
        else {
            put0();
        }
    }
}

static IV
fgetiv(pTHX_ FILE *in) {
    int c0 = getc(in);
    if (c0 < 128) {
	if (c0 < 0) croak ("unexpected end of file");
	return c0;
    }
    else {
	int c1 = getc(in);
	if (c0 < 192) {
	    return 128 + c1 + ((c0 & 0x3f) << 8);
	}
	else {
	    int c2 = getc(in);
	    if (c0 < 224) {
		return (128 + 16384) + c2 + ((c1 + ((c0 & 0x1f) << 8)) << 8);
	    }
	    else {
		int c3 = getc(in);
		if (c0 < 240) {
		    return (128 + 16384 + 2097152) + c3 + ((c2 + ((c1 + ((c0 & 0x0f) << 8)) << 8)) << 8);
		}
		else {
		    int c4 = getc(in);
		    if (c0 == 240) {
			return (128 + 16384 + 2097152 + 268435456) + c4 + ((c3 + ((c2 + (c1 << 8)) << 8)) << 8);
		    }
		    else {
			Perl_croak(aTHX_ "bad file format");
		    }
		}
	    }
	}
    }
}

static char
fgetmark(pTHX_ FILE *in) {
    int c = getc(in);
    if (c < 240) {
	ungetc(c, in);
	return 0;
    }
    return ((-c) & 0x0f);
}

static void psv(SV *sv) {
    dTHX;
    Perl_sv_dump(aTHX_ sv);
}

static SV *
_fgetpvn(pTHX_ FILE *in, IV len) {
    if (len) {
	SV *sv = newSV(len);
	char *buffer = SvPVX(sv);
	int count = fread(buffer, 1, len, in);
	if (count < len) {
	    SvREFCNT_dec(sv);
	    Perl_croak(aTHX_ "unexpected end of file");
	}
	buffer[len] = '\0';
	SvPOK_on(sv);
	SvCUR_set(sv, len);
	return sv;
    }
    return newSVpvn("", 0);
}

static SV *
fgetpv(pTHX_ FILE *in) {
    return _fgetpvn(aTHX_ in, fgetiv(aTHX_ in));
}

static AV*
fgetav(pTHX_ FILE *in) {
    AV *av = newAV();
    IV lines = fgetiv(aTHX_ in);
    IV i;
    for (i=0; i<lines; i++) {
	SV *sv = fgetpv(aTHX_ in);
	av_store(av, i, sv);
    }
    return av;
}

static int
fneof(FILE *in) {
    int c = getc(in);
    if (c != EOF) {
	ungetc(c, in);
	return 1;
    }
    return 0;
}

static AV *
get_file_src(pTHX_ char *fn) {
    char *avname;
    AV *lines;
    SV *src = newSVpv("main::_<", 8);

    sv_catpv(src, fn);
    avname = SvPV_nolen(src);
    lines = get_av(avname, 0);
    SvREFCNT_dec(src);
    return lines;
}

static UV
get_file_id(pTHX_ char *fn) {
    static IV file_id_generator = 0;
    SV ** pe;
    UV id;
    STRLEN fnl = strlen(fn);

    pe = hv_fetch(file_id_hv, fn, fnl, TRUE);
    if (SvOK(*pe))
	return SvUV(*pe);

    ++file_id_generator;
	
    putmark(1);
    putiv(aTHX_ file_id_generator);
    putpvn(fn, fnl);
	
    sv_setiv(*pe, file_id_generator);

    if ((fn[0] == '(' && (strncmp("eval", fn+1, 4)==0 || 
			  strncmp("re_eval", fn+1, 7)==0 ) ) ||
	(fn[0] == '-' && fn[1] == 'e' && fn[2] == '\0')) {

	AV *lines = get_file_src(aTHX_ fn);
	if (lines) {
	    putmark(2);
	    putiv(aTHX_ file_id_generator);
	    putav(aTHX_ lines);
	}
    }
    return file_id_generator;
}

static IV
mapid(pTHX_ HV *fpidmap, IV pid, IV fid) {
    static IV lfpid = 0;
    static SV *key = 0;
    SV **ent;
    char *k;
    STRLEN l;
    if (!key) key = newSV(30);
    sv_setpvf(key, "%d:%d", pid, fid);
    k = SvPV(key, l);
    ent = hv_fetch(fpidmap, k, l, TRUE);
    if (!SvOK(*ent))
	sv_setiv(*ent, ++lfpid);
    return SvIV(*ent);
}

static void
flock_and_header(pTHX) {
    static IV lpid = 0;
    IV pid = getpid();
    if (pid != lpid && lpid) {
	out = fopen(outname, "ab");
	if (!out)
	    Perl_croak(aTHX_ "unable to reopen file %s", outname);

	flock(fileno(out), LOCK_EX);
	fseek(out, 0, SEEK_END);

	putmark(5);
	putiv(aTHX_ pid);

	putmark(6);
	putiv(aTHX_ lpid);

    }
    else {
	flock(fileno(out), LOCK_EX);
	fseek(out, 0, SEEK_END);

	putmark(5);
	putiv(aTHX_ pid);
    }
    lpid = pid;
}


MODULE = Devel::FastProf		PACKAGE = DB
PROTOTYPES: DISABLE

void DB(...)
PPCODE:
    {
        IV ticks;
        if (usecputime) {
            struct tms buf;
            times(&buf);
            ticks = buf.tms_utime - old_tms.tms_utime + buf.tms_stime - old_tms.tms_stime;
        }
        else {
#if defined(HAS_GETTIMEOD)
            struct timeval time;
            gettimeofday(&time, NULL);
            if (time.tv_sec < old_time.tv_sec + 2000) {
                ticks = (time.tv_sec - old_time.tv_sec) * 1000000 + time.tv_usec - old_time.tv_usec;
            }
#else
            UV time[2];
            (*u2time)(aTHX_ time);
            if (time[0] < old_time[0] + 2000) {
                ticks = (time[0] - old_time[0]) * 1000000 + time[1] - old_time[1];
            }
#endif
            else {
                ticks = 2000000000;
            }
        }
        if (out) { /* out should never be NULL anyway */
            IV fid;
            IV line;
            char *file;
#if (PERL_VERSION < 8) || ((PERL_VERSION == 8) && (PERL_SUBVERSION < 8))
            PERL_CONTEXT *cx = cxstack + cxstack_ix;
#endif
            if (canfork)
                flock_and_header(aTHX);
#if (PERL_VERSION < 8) || ((PERL_VERSION == 8) && (PERL_SUBVERSION < 8))
            file = OutCopFILE(cx->blk_oldcop);
            line = CopLINE(cx->blk_oldcop);
#else
            file = OutCopFILE(PL_curcop);
            line = CopLINE(PL_curcop);
#endif
            if (strcmp(file, old_fn)) {
                fid = get_file_id(aTHX_ file);
                putmark(7);
                putiv(aTHX_ fid);
                old_fn = file;
            }
            putiv(aTHX_ line);
            if (ticks < 0) ticks = 0;
            putiv(aTHX_ ticks);
            
            if (canfork) {
                fflush(out);
                flock(fileno(out), LOCK_UN);
            }
        }
        if (usecputime) {
            times(&old_tms);
        }
        else {
#if defined (HAS_GETTIMEOD)
            gettimeofday(&old_time, NULL);
#else
            (*u2time)(aTHX_ old_time);
#endif
        }
    }

void _finish()
PPCODE:
    {
        if (out) {
            if (canfork) {
                flock_and_header(aTHX);
                fflush(out);
                flock(fileno(out), LOCK_UN);
            }
            fclose(out);
            out = NULL;
        }
    }


void _init(char *_outname, int _usecputime, int _canfork)
PPCODE:
    {
        out = fopen(_outname, "wb");
        if (!out) Perl_croak(aTHX_ "unable to open file %s for writing", _outname);
        fwrite("D::FP-" XS_VERSION "\0\0\0\0\0\0\0", 1, 12, out);
        putmark(3);
        if (_usecputime) {
            usecputime = 1;
            putiv(aTHX_ sysconf(_SC_CLK_TCK));
            times(&old_tms);
        }
        else {
            putiv(aTHX_ 1000000);
            usecputime = 0;
#if defined (HAS_GETTIMEOD)
            gettimeofday(&old_time, NULL);
#else
            {
                SV **svp = hv_fetch(PL_modglobal, "Time::U2time", 12, 0);
                if (!svp || !SvIOK(*svp)) Perl_croak(aTHX_ "Time::HiRes is required");
                u2time = INT2PTR(int(*)(pTHX_ UV*), SvIV(*svp));
            }
            (*u2time)(aTHX_ old_time);
#endif
        }
        if (_canfork) {
            canfork = 1;
            outname = strdup(_outname);
        }
        file_id_hv = get_hv("DB::file_id", TRUE);
    }


MODULE = Devel::FastProf		PACKAGE = Devel::FastProf::Reader

void _read_file(char *infn)
PPCODE:
    {
        HV *ticks = get_hv("Devel::FastProf::Reader::TICKS", TRUE);
        HV *count = get_hv("Devel::FastProf::Reader::COUNT", TRUE);
        AV *fn = get_av("Devel::FastProf::Reader::FN", TRUE);
        AV *src = get_av("Devel::FastProf::Reader::SRC", TRUE);
        HV *fpidmap = get_hv("Devel::FastProf::Reader::FPIDMAP", TRUE);
        HV *ppid = get_hv("Devel::FastProf::Reader::PPID", TRUE);
        float inv_ticks_per_second = 1.0;
        IV lfid = 0, nfid = 0, lline;
        int not_first = 0;
        IV pid = 0;
        SV *key = sv_2mortal(newSV(30));
        char *k;
        STRLEN l;
        SV **ent;
        char head[12];
        HV *pidlfid = (HV*)sv_2mortal((SV*)newHV());
        HV *pidlline = (HV*)sv_2mortal((SV*)newHV());

        FILE *in = fopen(infn, "rb");
        if (!in) Perl_croak(aTHX_ "unable to open %s for reading", infn);

        if ((fread(head, 1, 12, in) != 12) || strncmp(head, "D::FP-" XS_VERSION, 12))
            Perl_croak(aTHX_ "bad header, input file has not been generated by Devel::FastProf " XS_VERSION);

        while (fneof(in)) {
            IV mark = fgetmark(aTHX_ in);
            switch (mark) {
            case 0: /* line execution timestamp */
            {
                IV line = fgetiv(aTHX_ in);
                IV delta = fgetiv(aTHX_ in);
                /* fprintf(stderr, "fid: %d, line: %d, delta: %d\n", fid, line, delta); */
                if (not_first) {
                    SV **tsv, **csv;
                    /* SV *key = newSVpvf("%d:%d", lfid, lline); */
                    sv_setpvf(key, "%d:%d", lfid, lline);
                    k = SvPV(key, l);
                    tsv = hv_fetch(ticks, k, l, TRUE);
                    csv = hv_fetch(count, k, l, TRUE);
                    if (tsv && csv) {
                        float old = SvOK(*tsv) ? SvNV(*tsv) : 0.0;
                        /* printf("delta: %d\n", delta); */
                        sv_setnv(*tsv, old + delta * inv_ticks_per_second);
                        sv_inc(*csv);
                    }
                    else {
                        Perl_croak(aTHX_ "internal error");
                    }
                }
                else {
                    not_first = 1;
                }
                lfid = nfid;
                lline = line;
                break;
            }
            case 1: /* filename comming */
            {
                IV fid = pid ? mapid(aTHX_ fpidmap, pid, fgetiv(aTHX_ in)) : fgetiv(aTHX_ in);
                SV *fsv = fgetpv(aTHX_ in);
                av_store(fn, fid, fsv);
                break;
            }
            case 2: /* src comming */
            {
                IV fid = pid ? mapid(aTHX_ fpidmap, pid, fgetiv(aTHX_ in)) : fgetiv(aTHX_ in);
                AV *lines = fgetav(aTHX_ in);
                SV *ref = newRV_noinc((SV*)lines);
                av_store(src, fid, ref);
                break;
            }
            case 3: /* ticks per second */
            {
                IV tps = fgetiv(aTHX_ in);
                if (!tps)
                    Perl_croak(aTHX_ "bad parameter value: ticks_per_second = 0");
                
                inv_ticks_per_second = 1.0 / tps;
                break;
            }
            case 4:
            {
                Perl_croak(aTHX_ "obsolete file format");
            }
            case 5:
            {
                if (not_first) {
                    sv_setiv(key, pid);
                    k = SvPV(key, l);
                    ent = hv_fetch(pidlfid, k, l, TRUE);
                    sv_setiv(*ent, lfid);
                    ent = hv_fetch(pidlline, k, l, TRUE);
                    sv_setiv(*ent, lline);
                }            
                pid = fgetiv(aTHX_ in);
                sv_setiv(key, pid);
                k = SvPV(key, l);
                ent = hv_fetch(pidlfid, k, l, 0);
                if (ent) {
                    not_first = 1;
                    lfid = SvIV(*ent);
                    ent = hv_fetch(pidlline, k, l, TRUE);
                    lline = SvIV(*ent);
                }
                else {
                    not_first = 0;
                }
                break;
            }
            case 6:
            {
                sv_setiv(key, pid);
                k = SvPV(key, l);
                ent = hv_fetch(ppid, k, l, TRUE);
                sv_setiv(*ent, fgetiv(aTHX_ in));
                break;
            }
            case 7:
            {
                IV fid = fgetiv(aTHX_ in);
                nfid = pid ? mapid(aTHX_ fpidmap, pid, fid) : fid;
                /* fprintf(stderr, "lfid: %d\n", nfid); fflush(stderr); */
                
                break;
            }
            default:
                Perl_croak(aTHX_ "bad file format");
            }
        }
    }

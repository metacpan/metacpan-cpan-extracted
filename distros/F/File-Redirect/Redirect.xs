#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "perliol.h"


PerlIO_funcs unix, mapped, redirected;
struct IPerlLIO old_lio;
struct IPerlDir old_dir;

static void
fill_stat_t( AV * av_stat, Stat_t *st)
{
	if ( av_len(av_stat) != 12 ) croak("panic: stat array is not 12-long:%d", av_len(av_stat));

#define AVx(n) (*(av_fetch(av_stat,n,0)))
	st-> st_dev   = SvIV(AVx(0));
	st-> st_ino   = SvIV(AVx(1));
	st-> st_mode  = SvUV(AVx(2));
	st-> st_nlink = SvUV(AVx(3));
#if Uid_t_size > IVSIZE
	st-> st_uid = SvNV(AVx(4));
#else
#   if Uid_t_sign <= 0
	st-> st_uid = SvIV(AVx(4));
#   else
	st-> st_uid = SvUV(AVx(4));
#   endif
#endif
#if Gid_t_size > IVSIZE
	st-> st_uid = SvNV(AVx(5));
#else
#   if Gid_t_sign <= 0
	st-> st_uid = SvIV(AVx(5));
#   else
	st-> st_uid = SvUV(AVx(5));
#   endif
#endif
#ifdef USE_STAT_RDEV
	st-> st_rdev = SvUV(AVx(6));
#endif
#if Off_t_size > IVSIZE
	st-> st_size = SvUV(AVx(7));
#else
	st-> st_size = SvIV(AVx(7));
#endif
#ifdef BIG_TIME
	st-> st_atime = SvNV(AVx(8));
	st-> st_mtime = SvNV(AVx(8));
	st-> st_ctime = SvNV(AVx(8));
#else
	st-> st_atime = SvIV(AVx(8));
	st-> st_mtime = SvIV(AVx(8));
	st-> st_ctime = SvIV(AVx(8));
#endif
#ifdef USE_STAT_BLOCKS
	st-> st_blksize = SvUV(AVx(9));
	st-> st_blocks  = SvUV(AVx(9));
#endif
#undef AVx
}

static int
is_path_redirected_sv( SV * path )
{
	int result;
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK( sp);
	XPUSHs( path );
	PUTBACK;
	perl_call_pv("File::Redirect::is_path_redirected", G_SCALAR);
	result = POPi;
	PUTBACK;
	FREETMPS;
	LEAVE;
	return result;
}

#define is_path_redirected_pv(pv) is_path_redirected_sv(sv_2mortal(newSVpv(pv,PL_na)))

static int
new_stat(struct IPerlLIO* lio, const char* path, Stat_t* st)
{
	int ret;
	SV * result;
	dSP;

	if (!is_path_redirected_pv(path)) 
		return old_lio.pNameStat(lio,path,st);

	ENTER;
	SAVETMPS;
	PUSHMARK( sp);
	XPUSHs( newSVpv( path, PL_na ));
	PUTBACK;
	perl_call_pv("File::Redirect::Stat", G_SCALAR);
	result = POPs;
	if ( !result && SvOK( result )) 
		croak("bad return type");

	if ( SvROK(result)) {
		switch ( SvTYPE(SvRV(result))) {
		case SVt_PVAV:
			fill_stat_t((AV*) SvRV(result), st);
			ret = 0;
			break;
		default:
			croak("bad return type:%d", SvTYPE(SvRV(result)));
		}
	} else {
		errno = SvIV( result);
		ret = -1;
	}

	PUTBACK;
	FREETMPS;
	LEAVE;

	return ret;
}

static IV
PerlIOredirect_close(pTHX_ PerlIO * f)
{
	SV * handle;
	IV ret;
	
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK( sp);
	XPUSHs(newSVuv( PTR2UV( PerlIOBase( f))));
	PUTBACK;
	perl_call_pv("File::Redirect::Close", G_SCALAR);
	SPAGAIN;
	ret = POPi;
	PUTBACK;
	FREETMPS;
	LEAVE;

	redirected.Close(aTHX_ f);

	if ( ret == 0 )
		return 0;

	errno = ret;
	return -1;
}


static PerlIO*
PerlIOredirect_open(pTHX_ PerlIO_funcs *tab,
			PerlIO_list_t *layers, IV n, const char *mode,
			int fd, int imode, int perm,
			PerlIO *f, int narg, SV **args) {

	SV * handle;
	PerlIO * proxy;
	dSP;

	if ( fd != -1 || narg != 1)
		goto UNIX_OPEN; 

	if ( !is_path_redirected_sv(args[0])) 
		goto UNIX_OPEN;

	ENTER;
	SAVETMPS;
	PUSHMARK( sp);
	XPUSHs( newSVsv( args[0]));
	XPUSHs( newSVpv( mode, PL_na ));
	PUTBACK;
	perl_call_pv("File::Redirect::Open", G_SCALAR);
        SPAGAIN;
	handle = newSVsv(POPs);
	PUTBACK;
	FREETMPS;
	LEAVE;

	if (SvROK(handle)) {
		IO * io;
		PerlIO * proxy = IoIFP(sv_2io(handle)), *p;
		redirected = *(PerlIOBase(proxy)-> tab);

		mapped = *(PerlIOBase(proxy)-> tab);
		mapped.Close = PerlIOredirect_close;
		PerlIOBase(proxy)-> tab = &mapped;

		return proxy;
	} else {
		errno = SvIV(handle);
		return NULL;
	}

UNIX_OPEN:
	return unix.Open(aTHX_ tab, layers, n, mode, fd, imode, perm, f, narg, args);
}

// #define PerlLIO_chmod(file, mode)					\
// 	(*PL_LIO->pChmod)(PL_LIO, (file), (mode))
// #define PerlLIO_chown(file, owner, group)				\
// 	(*PL_LIO->pChown)(PL_LIO, (file), (owner), (group))
// #define PerlLIO_link(oldname, newname)					\
// 	(*PL_LIO->pLink)(PL_LIO, (oldname), (newname))
// #define PerlLIO_lstat(name, buf)					\
// 	(*PL_LIO->pLstat)(PL_LIO, (name), (buf))
// #define PerlLIO_rename(oname, newname)					\
// 	(*PL_LIO->pRename)(PL_LIO, (oname), (newname))
// #define PerlLIO_unlink(file)						\
// 	(*PL_LIO->pUnlink)(PL_LIO, (file))
// #define PerlLIO_utime(file, time)					\
// 	(*PL_LIO->pUtime)(PL_LIO, (file), (time))

// #define PerlDir_mkdir(name, mode)				\
// 	(*PL_Dir->pMakedir)(PL_Dir, (name), (mode))
// #define PerlDir_chdir(name)					\
// 	(*PL_Dir->pChdir)(PL_Dir, (name))
// #define PerlDir_rmdir(name)					\
// 	(*PL_Dir->pRmdir)(PL_Dir, (name))
// #define PerlDir_close(dir)					\
// 	(*PL_Dir->pClose)(PL_Dir, (dir))
// #define PerlDir_open(name)					\
// 	(*PL_Dir->pOpen)(PL_Dir, (name))
// #define PerlDir_read(dir)					\
// 	(*PL_Dir->pRead)(PL_Dir, (dir))
// #define PerlDir_rewind(dir)					\
// 	(*PL_Dir->pRewind)(PL_Dir, (dir))
// #define PerlDir_seek(dir, loc)					\
// 	(*PL_Dir->pSeek)(PL_Dir, (dir), (loc))
// #define PerlDir_tell(dir)					\
// 	(*PL_Dir->pTell)(PL_Dir, (dir))
// #ifdef WIN32
// #define PerlDir_mapA(dir)					\
// 	(*PL_Dir->pMapPathA)(PL_Dir, (dir))
// #define PerlDir_mapW(dir)					\
// 	(*PL_Dir->pMapPathW)(PL_Dir, (dir))
// #endif


MODULE = File::Redirect PACKAGE = File::Redirect

BOOT:
{
	int ok = 1;
	PerlIO_funcs *old = PL_known_layers-> array[0]. funcs;
	if ( strcmp(old-> name, "unix") != 0) {
		warn("this perl is incompatible with redirect: IO layer 'unix' is not found");
		ok = 0;
	}
	unix = *old;

	old_lio = *PL_LIO;
	old_dir = *PL_Dir;

	if ( ok) {
		old-> Open = PerlIOredirect_open;
		PL_LIO-> pNameStat = new_stat;
	}
}

UV
handle2iobase(fh)
SV* fh;
  CODE:
    RETVAL = PTR2UV(PerlIOBase(IoIFP(sv_2io(fh))));
  OUTPUT:
    RETVAL


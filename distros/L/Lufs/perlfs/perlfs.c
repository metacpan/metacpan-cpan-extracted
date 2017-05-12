/* june 2003 - Raoul Zwart - rlzwart@cpan.org */

#include "perlfs.h"
#include "list.h"

struct option {
	char *key;
	char *value;
	struct list_head list;
};  

struct domain {
	char *name;
	struct list_head properties;
	struct list_head list;
};

EXTERN_C void xs_init (pTHX);
EXTERN_C void boot_DynaLoader (pTHX_ CV* cv);

EXTERN_C void
xs_init(pTHX) {
    char *file = __FILE__;
    // dXSUB_SYS;
    newXS("DynaLoader::boot_DynaLoader", boot_DynaLoader, file);
}

void* 
perlfs_init(struct list_head *cfg, struct dir_cache *cache, struct credentials *cred, void** dus) {
    struct perlfs_context *c;
	
    if(!(c = malloc(sizeof(struct perlfs_context)))){
        return NULL;
    }

#ifdef USE_MUTEX
	if (mutex == NULL) {
		static pthread_mutex_t mut = PTHREAD_MUTEX_INITIALIZER;
		mutex = &mut;
	}
#endif
    c->cache = cache;
    c->cred = cred;
    c->cfg = cfg;
	
	if (perl == NULL) {
		LOCK_MUTEX(c);
		_create_perl(c);
		_init_perl(c);
		_setup_perl(c);
		perl = c->perl;
		UNLOCK_MUTEX(c);
	}
	else {
		c->perl = perl;
	}
    
    return c;
}

void
_create_perl(struct perlfs_context* c) {
	/* we already own the mutex when this is called */
    c->perl = perl_alloc();
    perl_construct(c->perl);

    char *embedding[] = { "", "-e", "0" };
    perl_parse(c->perl, xs_init, 3, embedding, NULL);
    PL_exit_flags |= PERL_EXIT_DESTRUCT_END;
    perl_run(c->perl);
}

void
_init_perl(struct perlfs_context* c) {
    eval_pv("use Lufs;Lufs->new", TRUE);
}

static struct domain*
find_domain(struct list_head *conf, char *name){
    struct list_head *p;
    struct domain *cls;
    
    list_for_each(p, conf){
		cls = list_entry(p, struct domain, list);
		if(!strcmp(name, cls->name)){
			TRACE("domain found");
			return cls;
		}
    }
    
    return NULL;
}   

void
_setup_perl(struct perlfs_context* c) {
    char *host, *port, *root;
    if (!(host=(char *)lu_opt_getchar(c->cfg, "MOUNT", "host"))) {
        ERROR("You must specify a class name using the `single dot instead of double colon' notation");
        host = "Lufs.Stub";
    }
    if (!(port=(char *)lu_opt_getchar(c->cfg, "MOUNT", "port"))) {
        port = "";
    }
    if (!(root=(char *)lu_opt_getchar(c->cfg, "MOUNT", "root"))) {
        root = "/";
    }
    dSP;
    ENTER;
    SAVETMPS;
    HV *h = newHV();
	SV *ref;
	struct domain *class;
	struct option *prop;
	struct list_head *p;

	/*
		hv_store(h, "host", 4, newSVpv(host, strlen(host)), 0);
		hv_store(h, "root", 4, newSVpv(root, strlen(root)), 0);
		hv_store(h, "port", 4, newSVpv(port, strlen(port)), 0);
	*/
	class = find_domain(c->cfg, "MOUNT");
	list_for_each(p, &class->properties) {
		prop = list_entry(p, struct option, list);
		hv_store(h, prop->key, strlen(prop->key), newSVpv(prop->value, strlen(prop->value)), 0);
	}
	ref = newRV((SV *)h);
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(ref));
    PUTBACK;
    call_pv("Lufs::C::_init",G_DISCARD);
    FREETMPS;
    LEAVE;
}
    

    
void*
perlfs_free(struct perlfs_context* c) {
	/*
	LOCK_MUTEX(c);
    perl_destruct(c->perl);
    perl_free(c->perl);
	UNLOCK_MUTEX(c);
#ifdef USE_MUTEX
	pthread_mutex_destroy(&c->mutex);
#endif
    free(c);
	*/
    return NULL;
}

int
perlfs_mount(struct perlfs_context* c) {
	LOCK_MUTEX(c);
    eval_pv("Lufs::C::mount", TRUE);
	UNLOCK_MUTEX(c);
    return 1;
}

void*
perlfs_umount(struct perlfs_context* c) {
	LOCK_MUTEX(c);
    eval_pv("Lufs::C::umount",TRUE);
	UNLOCK_MUTEX(c);
    return NULL;
}

int
perlfs_readdir(struct perlfs_context* c, char* file, struct directory* dir) {
	LOCK_MUTEX(c);
    AV *l = newAV();
    SV *ref;
    struct lufs_fattr fattr;
    int ret, count;
    ref = newRV((SV *)l);
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(file,0)));
    XPUSHs(ref);
    PUTBACK;
    count = call_pv("Lufs::C::readdir",G_SCALAR);
    SPAGAIN;
    if (count != 1) {
        TRACE("trouble");
    }
    ret = POPi;
    PUTBACK;
    FREETMPS;
    LEAVE;
	UNLOCK_MUTEX(c);
    if (ret == 0) {
        TRACE("Lufs::C::readdir returned 0, bailing out");
        return -1;
    }
    int i;
    char *e;
    for (i=0;i<=av_len(l);i++) {
        e = getarstring(l,i);
        if (perlfs_stat(c,e,&fattr) < 0) {
        }
        else {
            lu_cache_add2dir(dir,e,NULL,&fattr);
        }
    }
    return 0;
}

void
fattr2hash(struct lufs_fattr *attr, HV *h) {
    hv_store(h, "f_ino", 5, newSVnv(attr->f_ino), 0);
    hv_store(h, "f_mode", 6, newSVnv(attr->f_mode), 0);
    hv_store(h, "f_nlink", 7, newSVnv(attr->f_nlink), 0);
    hv_store(h, "f_uid", 5, newSVnv(attr->f_uid), 0);
    hv_store(h, "f_gid", 5, newSVnv(attr->f_gid), 0);
    hv_store(h, "f_rdev", 6, newSVnv(attr->f_rdev), 0);
    hv_store(h, "f_size", 6, newSVnv(attr->f_size), 0);
    hv_store(h, "f_atime", 7, newSVnv(attr->f_atime), 0);
    hv_store(h, "f_mtime", 7, newSVnv(attr->f_mtime), 0);
    hv_store(h, "f_ctime", 7, newSVnv(attr->f_ctime), 0);
    hv_store(h, "f_blksize", 9, newSVnv(attr->f_blksize), 0);
    hv_store(h, "f_blocks", 8, newSVnv(attr->f_blocks), 0);
}

void
hash2fattr(HV *h, struct lufs_fattr *attr) {
    attr->f_ino = getlong(h,"f_ino");
    attr->f_mode = getlong(h,"f_mode");
    attr->f_nlink = getlong(h,"f_nlink");
    attr->f_uid = getlong(h,"f_uid");
    attr->f_gid = getlong(h,"f_gid");
    attr->f_rdev = getlong(h,"f_rdev");
    attr->f_size = getlong(h,"f_size");
    attr->f_atime = getlong(h,"f_atime");
    attr->f_mtime = getlong(h,"f_mtime");
    attr->f_ctime = getlong(h,"f_ctime");
    attr->f_blksize = getlong(h,"f_blksize");
    attr->f_blocks = getlong(h,"f_blocks");
}
/*
void
dir2hash(struct directory* dir, HV *h) {
    //hv_store(h, "d_name", 6, newSVnv(dir->d_name), 0);
    //hv_store(h, "d_stamp", 7, newSVnv(dir->d_stamp), 0);
}

void
hash2dir(HV* h, struct directory* dir) {
    dir = malloc(sizeof(struct directory));
    TRACE("DIRNAAM....");
    TRACE(dir->d_name);
    //dir->d_name = getstring(h, "d_name");
    //dir->d_stamp = getlong(h, "d_stamp");
}
*/
char *
getstring(HV * source, char * fieldname) 
{
    SV ** sv = hv_fetch(source, fieldname, strlen(fieldname), FALSE);
    if(!SvOK(*sv)) {
        TRACE("Error - hv_fetch %s returned bad sv\n", fieldname);
    }
    return SvPV(*sv, PL_na);
}

char *
getarstring(AV * source, I32 i) {
    SV ** sv = av_fetch(source, i, FALSE);
    return SvPV(*sv, PL_na);
}

long
getlong(HV * source, char * fieldname)
{
    SV ** sv = hv_fetch(source, fieldname, strlen(fieldname), FALSE);
    if(!SvOK(*sv)) {
        TRACE("Error - hv_fetch %s returned bad sv\n", fieldname);
    }
    return SvIV(*sv);
}

int
perlfs_stat(struct perlfs_context* c, char* file, struct lufs_fattr* attr) {
	LOCK_MUTEX(c);
    HV *h = newHV();
    SV* ref;
    int count;
    int ret;
    fattr2hash(attr,h);
    ref = newRV((SV *)h);
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(file,0)));
    XPUSHs(ref);
    PUTBACK;
    count = call_pv("Lufs::C::stat",G_SCALAR);
    SPAGAIN;
    ret = POPi;
    PUTBACK;
	FREETMPS;
	LEAVE;
	UNLOCK_MUTEX(c);
    if (!ret>0) {
        TRACE("stat(%s) failed",file);
        return -1;
    }
    hash2fattr(h,attr);
    return 0;
}

int
perlfs_mkdir(struct perlfs_context* c, char* file, int mode) {
	LOCK_MUTEX(c);
    int ret, count;
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(file,0)));
    XPUSHs(sv_2mortal(newSViv(mode)));
    PUTBACK;
    count = call_pv("Lufs::C::mkdir",G_SCALAR);
    SPAGAIN;
    ret = POPi;
    PUTBACK;
	FREETMPS;
	LEAVE;
	UNLOCK_MUTEX(c);
    if (!ret>0) {
        return -1;
    }
    return 0;
}

int
perlfs_rmdir(struct perlfs_context* c, char* file) {
	LOCK_MUTEX(c);
    int ret, count;
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(file,0)));
    PUTBACK;
    count = call_pv("Lufs::C::rmdir",G_SCALAR);
    SPAGAIN;
    ret = POPi;
    PUTBACK;
	FREETMPS;
	LEAVE;
	UNLOCK_MUTEX(c);
    if (!ret>0) {
        return -1;
    }
    return 0;
}

int
perlfs_create(struct perlfs_context* c, char* file, int mode) {
	LOCK_MUTEX(c);
    int ret, count;
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(file,0)));
    XPUSHs(sv_2mortal(newSViv(mode)));
    PUTBACK;
    count = call_pv("Lufs::C::create",G_SCALAR);
    SPAGAIN;
    ret = POPi;
    PUTBACK;
	FREETMPS;
	LEAVE;
	UNLOCK_MUTEX(c);
    if (!ret>0) {
        return -1;
    }
    return 0;
}

int
perlfs_unlink(struct perlfs_context* c, char* file) {
	LOCK_MUTEX(c);
    int ret, count;
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(file,0)));
    PUTBACK;
    count = call_pv("Lufs::C::unlink",G_SCALAR);
    SPAGAIN;
    ret = POPi;
    PUTBACK;
    FREETMPS;
    LEAVE;
	UNLOCK_MUTEX(c);
    if (!ret>0) {
        return -1;
    }
    return 0;
}

int
perlfs_rename(struct perlfs_context* c, char* file_a, char* file_b) {
	LOCK_MUTEX(c);
    int ret, count;
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(file_a,0)));
    XPUSHs(sv_2mortal(newSVpv(file_b,0)));
    PUTBACK;
    count = call_pv("Lufs::C::rename",G_SCALAR);
    SPAGAIN;
    ret = POPi;
    PUTBACK;
    FREETMPS;
    LEAVE;
	UNLOCK_MUTEX(c);
    if (!ret>0) {
        return -1;
    }
    return 0;
}

int
perlfs_open(struct perlfs_context* c, char* file, unsigned mode) {
	LOCK_MUTEX(c);
    int ret, count;
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(file,0)));
    XPUSHs(sv_2mortal(newSViv((int)mode)));
    PUTBACK;
    count = call_pv("Lufs::C::open",G_SCALAR);
    SPAGAIN;
    ret = POPi;
    PUTBACK;
    FREETMPS;
    LEAVE;
	UNLOCK_MUTEX(c);
    if (!ret>0) {
        return -1;
    }
    return 0;
}

int
perlfs_release(struct perlfs_context* c, char* file) {
	LOCK_MUTEX(c);
    int ret, count;
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(file,0)));
    PUTBACK;
    count = call_pv("Lufs::C::release",G_SCALAR);
    SPAGAIN;
    ret = POPi;
    PUTBACK;
    FREETMPS;
    LEAVE;
	UNLOCK_MUTEX(c);
    if (!ret>0) {
        return -1;
    }
    return 0;
}

int
perlfs_read(struct perlfs_context* c, char* file, long long offset, unsigned long count, char* buf) {
	LOCK_MUTEX(c);
    int ret;
    int cnt;
    dSP;
    SV* data;
    char* tmp;
    ENTER;
    SAVETMPS;
    data = sv_2mortal(newSVpv("",0));
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(file,0)));
    XPUSHs(sv_2mortal(newSViv(offset)));
    XPUSHs(sv_2mortal(newSViv(count)));
    XPUSHs(data);
    PUTBACK;
    cnt = call_pv("Lufs::C::read",G_SCALAR);
    SPAGAIN;
    ret = POPi;
    PUTBACK;
    if (ret<0) {
        FREETMPS;
        LEAVE;
		UNLOCK_MUTEX(c);
        return -1;
    }
    tmp = SvPV(data,ret);
    memmove(buf,tmp,ret);
    FREETMPS;
    LEAVE;
	UNLOCK_MUTEX(c);
    return ret;
}

int
perlfs_write(struct perlfs_context* c, char* file, long long offset, unsigned long count, char* buf) {
	LOCK_MUTEX(c);
    int cnt;
    unsigned long ret;
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(file,0)));
    XPUSHs(sv_2mortal(newSViv(offset)));
    XPUSHs(sv_2mortal(newSViv(count)));
    XPUSHs(sv_2mortal(newSVpv(buf,count)));
    PUTBACK;
    cnt = call_pv("Lufs::C::write",G_SCALAR);
    SPAGAIN;
    ret = POPi;
    PUTBACK;
	FREETMPS;
	LEAVE;
	UNLOCK_MUTEX(c);
    if (!ret>0) {
        return -1;
    }
    //perlfs_touch(c,file);
    return ret;
}

int
perlfs_readlink(struct perlfs_context* c, char* file, char* buf, int bufsiz) {
    /*
       #include <unistd.h>

       int readlink(const char *path, char *buf, size_t bufsiz);

        DESCRIPTION
        
        readlink  places  the  contents of the symbolic link path in the buffer
        buf, which has size bufsiz.  readlink does not append a  NUL  character
        to  buf.   It will truncate the contents (to a length of bufsiz charac-
        ters), in case the buffer is too small to hold all of the contents.

    */
	LOCK_MUTEX(c);
    int count, ret;
    dSP;
    SV *data;
    char *tmp;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    data = sv_2mortal(newSVpv("",0));
    XPUSHs(sv_2mortal(newSVpv(file,0)));
    XPUSHs(data);
    PUTBACK;
    count = call_pv("Lufs::C::readlink",G_SCALAR);
    SPAGAIN;
    ret = POPi;
    if (!ret > 0) {
		PUTBACK;
		FREETMPS;
		LEAVE;
		UNLOCK_MUTEX(c);
        return -1;
    }
    tmp = SvPV(data,ret);
    memmove(buf,tmp,ret);
    PUTBACK;
	FREETMPS;
	LEAVE;
	UNLOCK_MUTEX(c);
    return ret;
}

int
perlfs_link(struct perlfs_context* c, char* file_a, char* file_b) {
	LOCK_MUTEX(c);
    int ret, count;
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(file_a,0)));
    XPUSHs(sv_2mortal(newSVpv(file_b,0)));
    PUTBACK;
    count = call_pv("Lufs::C::link",G_SCALAR);
    SPAGAIN;
    ret = POPi;
    PUTBACK;
    FREETMPS;
    LEAVE;
	UNLOCK_MUTEX(c);
    if (!ret>0) {
        return -1;
    }
    return 0;
}

int
perlfs_symlink(struct perlfs_context* c, char* file_a, char* file_b) {
	LOCK_MUTEX(c);
    int ret, count;
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(file_a,0)));
    XPUSHs(sv_2mortal(newSVpv(file_b,0)));
    PUTBACK;
    count = call_pv("Lufs::C::symlink",G_SCALAR);
    SPAGAIN;
    ret = POPi;
    PUTBACK;
    FREETMPS;
    LEAVE;
	UNLOCK_MUTEX(c);
    if (!ret>0) {
        return -1;
    }
    return 0;
}

int
perlfs_setattr(struct perlfs_context* c, char* file, struct lufs_fattr* attr) {
	LOCK_MUTEX(c);
    int count;
    int ret;
    dSP;
    HV *h = newHV();
    SV* ref;
    fattr2hash(attr,h);
    ref = newRV((SV *)h);
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(file,0)));
    XPUSHs(ref);
    PUTBACK;
    count = call_pv("Lufs::C::setattr",G_SCALAR);
    SPAGAIN;
    ret = POPi;
    PUTBACK;
    FREETMPS;
    LEAVE;
	UNLOCK_MUTEX(c);
    if (!ret>0) {
        return -1;
    }
    return 0;
}

void
perlfs_touch(struct perlfs_context* c, char* file) {
    struct lufs_fattr fattr;
    struct lufs_fattr* a = &fattr;
	LOCK_MUTEX(c);
    if (perlfs_stat(c,file,a) < 0) {
        TRACE("stat '%s' failed",file);
		UNLOCK_MUTEX(c);
    }
    else {
        a->f_atime = time(NULL);
        a->f_mtime = time(NULL);
        perlfs_setattr(c,file,a);
		UNLOCK_MUTEX(c);
    }
}


/* misc routines */


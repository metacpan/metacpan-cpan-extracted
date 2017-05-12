#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "string.h"
#include "rsync.h"
#include <sys/stat.h>

typedef struct file_list *File__RsyncP__FileList;

/*
 * Pick an integer setting out of the hash ref opts.  If the argument
 * isn't a hash, or doesn't contain param, then returns def.
 */
static int getHashInt(SV *opts, char *param, int def)
{
    SV **vp;

    if ( !opts || !SvROK(opts)
               || SvTYPE(SvRV(opts)) != SVt_PVHV
               || !(vp = hv_fetch((HV*)SvRV(opts), param, strlen(param), 0))
               || !*vp ) {
        return def;
    }
    return SvIV(*vp);
}

/*
 * Pick an unsigned integer setting out of the hash ref opts.  If the
 * argument isn't a hash, or doesn't contain param, then returns def.
 */
static unsigned int getHashUInt(SV *opts, char *param, int def)
{
    SV **vp;

    if ( !opts || !SvROK(opts)
               || SvTYPE(SvRV(opts)) != SVt_PVHV
               || !(vp = hv_fetch((HV*)SvRV(opts), param, strlen(param), 0))
               || !*vp ) {
        return def;
    }
    return SvUV(*vp);
}

/*
 * Pick a string setting out of the hash ref opts.  If the argument
 * isn't a hash, or doesn't contain param, then returns def.
 */
static int getHashString(SV *opts, char *param, char *def,
                          char *result, int maxLen)
{
    SV **vp;
    char *str;
    STRLEN len;

    if ( !opts || !SvROK(opts)
               || SvTYPE(SvRV(opts)) != SVt_PVHV
               || !(vp = hv_fetch((HV*)SvRV(opts), param, strlen(param), 0))
               || !*vp ) {
        if ( !def )
            return -1;
        strcpy(result, def);
        return 0;
    } else {
        str = (char*)SvPV(*vp, len);
        if ( len >= maxLen ) {
            return -1;
        }
        memcpy(result, str, len);
        result[len] = '\0';
    }
    return 0;
}

/*
 * Pick a double setting out of the hash ref opts.  If the argument
 * isn't a hash, or doesn't contain param, then returns def.
 */
static double getHashDouble(SV *opts, char *param, double def)
{
    SV **vp;

    if ( !opts || !SvROK(opts)
               || SvTYPE(SvRV(opts)) != SVt_PVHV
               || !(vp = hv_fetch((HV*)SvRV(opts), param, strlen(param), 0))
               || !*vp ) {
        return def;
    }
    return SvNV(*vp);
}

/*
 * Check if a hash value defined.
 */
static int isHashDefined(SV *opts, char *param)
{
    SV **vp;

    if ( !opts || !SvROK(opts)
               || SvTYPE(SvRV(opts)) != SVt_PVHV
               || !(vp = hv_fetch((HV*)SvRV(opts), param, strlen(param), 0))
               || !*vp ) {
        return 0;
    }
    return 1;
}

MODULE = File::RsyncP::FileList		PACKAGE = File::RsyncP::FileList		

PROTOTYPES: DISABLE

File::RsyncP::FileList
new(packname = "File::RsyncP::FileList", opts = NULL)
	char *packname
	SV* opts
    CODE:
    {
        int preserve_hard_links = getHashInt(opts, "preserve_hard_links", 0);
        RETVAL = flist_new(1, "FileList new", preserve_hard_links);
        RETVAL->preserve_links   = getHashInt(opts, "preserve_links", 1);
        RETVAL->preserve_uid     = getHashInt(opts, "preserve_uid",   1);
        RETVAL->preserve_gid     = getHashInt(opts, "preserve_gid",   1);
        RETVAL->preserve_devices = getHashInt(opts, "preserve_devices", 0);
        RETVAL->always_checksum  = getHashInt(opts, "always_checksum", 0);
        RETVAL->preserve_hard_links = preserve_hard_links;
        RETVAL->protocol_version = getHashInt(opts, "protocol_version", 26);
        RETVAL->eol_nulls        = getHashInt(opts, "from0", 0);
    }
    OUTPUT:
	RETVAL

void
DESTROY(flist)
	File::RsyncP::FileList	flist
    CODE:
    {
        flist_free(flist);
    }

unsigned int
count(flist)
	File::RsyncP::FileList	flist
    CODE:
    {
        RETVAL = flist->count;
    }
    OUTPUT:
        RETVAL

unsigned int
fatalError(flist)
	File::RsyncP::FileList	flist
    CODE:
    {
        RETVAL = flist->fatalError;
    }
    OUTPUT:
        RETVAL

unsigned int
decodeDone(flist)
	File::RsyncP::FileList	flist
    CODE:
    {
        RETVAL = flist->decodeDone;
    }
    OUTPUT:
        RETVAL

int
decode(flist, bytesSV)
    PREINIT:
	STRLEN nBytes;
    INPUT:
	File::RsyncP::FileList	flist
	SV *bytesSV
	unsigned char *bytes = (unsigned char *)SvPV(bytesSV, nBytes);
    CODE:
    {
        RETVAL = flistDecodeBytes(flist, bytes, nBytes);
    }
    OUTPUT:
        RETVAL

SV*
get(flist, index)
    INPUT:
	File::RsyncP::FileList	flist
        unsigned int index
    CODE:
    {
        HV *rh;
        struct file_struct *file;

        if ( index >= flist->count || !flist->files[index]->basename ) {
            XSRETURN_UNDEF; 
        }
        file = flist->files[index];
        rh = (HV *)sv_2mortal((SV *)newHV());
        if ( file->basename )
            hv_store(rh, "basename", 8, newSVpv(file->basename, 0), 0);
        if ( file->dirname )
            hv_store(rh, "dirname",  7, newSVpv(file->dirname, 0), 0);
        if ( S_ISLNK(file->mode) && file->u.link )
            hv_store(rh, "link",     4, newSVpv(file->u.link, 0), 0);
        if ( S_ISREG(file->mode) && file->u.sum )
            hv_store(rh, "sum",      3, newSVpv(file->u.sum, 0), 0);
        if ( IS_DEVICE(file->mode) ) {
            hv_store(rh, "rdev",        4, newSVnv((double)file->u.rdev), 0);
            hv_store(rh, "rdev_major", 10,
                            newSVnv((double)major(file->u.rdev)), 0);
            hv_store(rh, "rdev_minor", 10,
                            newSVnv((double)minor(file->u.rdev)), 0);
        }
        hv_store(rh, "name",    4, newSVpv(f_name(file), 0), 0);
        hv_store(rh, "uid",     3, newSVnv((double)((unsigned)file->uid)), 0);
        hv_store(rh, "gid",     3, newSVnv((double)((unsigned)file->gid)), 0);
        hv_store(rh, "mode",    4, newSVnv((double)((unsigned)file->mode)), 0);
        hv_store(rh, "mtime",   5,
			    newSVnv((double)((unsigned)file->modtime)), 0);
        hv_store(rh, "size",    4, newSVnv(file->length), 0);
        if ( flist->preserve_hard_links ) {
            if ( flist->link_idev_data_done ) {
                /*
                 * already run the hardlink linking code, so the link_u
                 * union has the links data in place
                 */
                if ( file->link_u.links ) {
                    /*
                     * return the name of the file this one is linked to
                     */
                    hv_store(rh, "hlink", 5, 
                        newSVpv(f_name(file->link_u.links->to), 0), 0);
                    if ( file == file->link_u.links->to ) {
                        /*
                         * Add flag if this is ourselves
                         */
                        hv_store(rh, "hlink_self", 10, newSVnv((double)1.0), 0);
                    }
                }
            } else {
                if ( file->link_u.idev ) {
                    hv_store(rh, "dev", 3, newSVnv(file->link_u.idev->dev), 0);
                    hv_store(rh, "inode", 5,
                        newSVnv(file->link_u.idev->inode), 0);
                }
            }
        }
        RETVAL = newRV((SV*)rh);
    }
    OUTPUT:
        RETVAL

unsigned int
flagGet(flist, index)
    INPUT:
	File::RsyncP::FileList flist
        unsigned int index
    CODE:
    {
        if ( index >= flist->count ) {
            XSRETURN_UNDEF; 
        }
        RETVAL = flist->files[index]->flags & FLAG_USER_BOOL ? 1 : 0;
    }
    OUTPUT:
        RETVAL

void
flagSet(flist, index, value)
    INPUT:
	File::RsyncP::FileList flist
        unsigned int index
        unsigned int value
    CODE:
    {
        if ( index < flist->count ) {
            if ( value ) {
                flist->files[index]->flags |= FLAG_USER_BOOL;
            } else {
                flist->files[index]->flags &= ~FLAG_USER_BOOL;
            }
        }
    }

void
clean(flist)
    INPUT:
	File::RsyncP::FileList	flist
    CODE:
    {
        clean_flist(flist, 0, 1);
    }

void
init_hard_links(flist)
    INPUT:
	File::RsyncP::FileList	flist
    CODE:
    {
        init_hard_links(flist);
    }

void
encode(flist, data)
    INPUT:
	File::RsyncP::FileList	flist
	SV* data
    CODE:
    {
        struct file_struct *file;
        char sum[SUM_LENGTH];
        char thisname[MAXPATHLEN];
        char linkname[MAXPATHLEN];
        int alloc_len, basename_len, dirname_len, linkname_len, sum_len;
        char *basename, *dirname, *bp;
        unsigned short flags = 0;
        unsigned int mode = getHashUInt(data, "mode", 0);

        unsigned int file_struct_len;
        struct file_struct f_test;

        /* Figure out how big the file_struct is without trailing padding */
        file_struct_len = offsetof(struct file_struct, flags)
                        + sizeof f_test.flags;

        if (!flist || !flist->count)    /* Ignore lastdir when invalid. */
                flist->encode_lastdir_len = -1;

        if ( getHashString(data, "name", NULL, thisname, MAXPATHLEN-1) ) {
            printf("flist encode: empty or too long name\n");
            return;
        }
        clean_fname(thisname, 0);

        memset(sum, 0, SUM_LENGTH);

        if ( S_ISLNK(mode) && getHashString(data, "link", NULL, linkname,
                                            MAXPATHLEN-1) ) {
            printf("flist encode: link name is too long\n");
            return;
        }

        if ((basename = strrchr(thisname, '/')) != NULL) {
            dirname_len = ++basename - thisname; /* counts future '\0' */
            if (flist->encode_lastdir_len == dirname_len - 1
                    && strncmp(thisname, flist->encode_lastdir,
                                   flist->encode_lastdir_len) == 0) {
                dirname = flist->encode_lastdir;
                dirname_len = 0; /* indicates no copy is needed */
            } else
                dirname = thisname;
        } else {
            basename = thisname;
            dirname = NULL;
            dirname_len = 0;
        }
        basename_len = strlen(basename) + 1; /* count the '\0' */

        linkname_len = S_ISLNK(mode) ? strlen(linkname) + 1 : 0;

        sum_len = flist->always_checksum && S_ISREG(mode) ? MD4_SUM_LENGTH : 0;

        alloc_len = file_struct_len + dirname_len + basename_len
            + linkname_len + sum_len;
        if (flist) {
            bp = pool_alloc(flist->file_pool, alloc_len,
                "receive_file_entry");
        } else {
            if (!(bp = malloc(sizeof(char) * alloc_len))) {
                printf("out of memory: receive_file_entry");
                return;
            }
        }

        file = (struct file_struct *)bp;
        memset(bp, 0, file_struct_len);
        bp += file_struct_len;

        file->flags   = flags;
        file->modtime = getHashUInt(data, "mtime", 0);
        file->length  = getHashDouble(data, "size", 0.0);
        file->mode    = mode;
        file->uid     = getHashUInt(data, "uid", 0);
        file->gid     = getHashUInt(data, "gid", 0);

        if (flist->preserve_hard_links && flist->idev_pool) {
            if (flist->protocol_version < 28) {
                if (S_ISREG(mode))
                        file->link_u.idev = pool_talloc(
                            flist->idev_pool, struct idev, 1,
                            "inode_table");
            } else {
                if (!S_ISDIR(mode) && isHashDefined(data, "inode"))
                        file->link_u.idev = pool_talloc(
                            flist->idev_pool, struct idev, 1,
                            "inode_table");
            }
        }
        if (file->link_u.idev) {
            file->F_DEV = getHashDouble(data, "dev", 0.0);
            file->F_INODE = getHashDouble(data, "inode", 0.0);
        }

        if (dirname_len) {
            file->dirname = flist->encode_lastdir = bp;
            flist->encode_lastdir_len = dirname_len - 1;
            memcpy(bp, dirname, dirname_len - 1);
            bp += dirname_len;
            bp[-1] = '\0';
        } else if (dirname)
            file->dirname = dirname;

        file->basename = bp;
        memcpy(bp, basename, basename_len);
        bp += basename_len;

        if (flist->preserve_devices && IS_DEVICE(mode)) {
            if ( isHashDefined(data, "rdev_major") ) {
                file->u.rdev = makedev(getHashUInt(data, "rdev_major", 0),
                                       getHashUInt(data, "rdev_minor", 0));
            } else if ( isHashDefined(data, "rdev") ) {
                file->u.rdev = getHashUInt(data, "rdev", 0);
            } else {
                printf("File::RsyncP::FileList::encode: missing rdev on device file %s\n",
                                thisname);
                file->u.rdev = 0;
            }
        }

        if (linkname_len) {
            file->u.link = bp;
            memcpy(bp, linkname, linkname_len);
            bp += linkname_len;
        }

        if (sum_len) {
            file->u.sum = bp;
            /* TODO */
            memset(bp, 0, sum_len);
            /*bp += sum_len;*/
        }

        file->basedir = NULL;           /* TODO */

        flist_expand(flist);

        if (file->basename[0]) {
            flist->files[flist->count++] = file;
            send_file_entry(flist, file, 0 /* TODO base_flags */);
        }
    }

SV*
encodeData(flist)
    INPUT:
	File::RsyncP::FileList	flist
    CODE:
    {
        if ( !flist->outBuf || flist->outPosn == 0 ) {
            ST(0) = sv_2mortal(newSVpv("", 0));
        } else {
            ST(0) = sv_2mortal(newSVpv((char*)flist->outBuf, flist->outPosn));
            flist->outPosn = 0;
        }
    }

int
exclude_check(flist, pathSV, isDir)
    PREINIT:
	STRLEN pathLen;
    INPUT:
	File::RsyncP::FileList flist
	SV *pathSV
	unsigned char *path = (unsigned char *)SvPV(pathSV, pathLen);
        unsigned int isDir
    CODE:
    {
        RETVAL = check_exclude(flist, (char*)path, isDir);
    }
    OUTPUT:
        RETVAL

void
exclude_add(flist, patternSV, flags)
    PREINIT:
	STRLEN patternLen;
    INPUT:
	File::RsyncP::FileList flist
	SV *patternSV
	unsigned char *pattern = (unsigned char *)SvPV(patternSV, patternLen);
        unsigned int flags
    CODE:
    {
        add_exclude(flist, (char*)pattern, flags);
    }

void
exclude_add_file(flist, fileNameSV, flags)
    PREINIT:
	STRLEN fileNameLen;
    INPUT:
	File::RsyncP::FileList flist
	SV *fileNameSV
	unsigned char *fileName = (unsigned char *)SvPV(fileNameSV, fileNameLen);
        unsigned int flags
    CODE:
    {
        add_exclude_file(flist, (char*)fileName, flags);
    }

void
exclude_cvs_add(flist)
    INPUT:
	File::RsyncP::FileList flist
    CODE:
    {
        add_cvs_excludes(flist);
    }

void
exclude_list_send(flist)
    INPUT:
	File::RsyncP::FileList flist
    CODE:
    {
        send_exclude_list(flist);
    }

void
exclude_list_receive(flist)
    INPUT:
	File::RsyncP::FileList flist
    CODE:
    {
        recv_exclude_list(flist);
    }

void
exclude_list_clear(flist)
    INPUT:
	File::RsyncP::FileList flist
    CODE:
    {
        clear_exclude_list(&flist->exclude_list);
    }

SV *
exclude_list_get(flist)
    INPUT:
	File::RsyncP::FileList flist
    CODE:
        {
            AV *result;
            struct exclude_struct *ent;

            result = (AV *)sv_2mortal((SV *)newAV());

            for (ent = flist->exclude_list.head; ent; ent = ent->next) {
                HV *rh = (HV *)sv_2mortal((SV *)newHV());
                hv_store(rh, "pattern", 7,
                         newSVpvn(ent->pattern, strlen(ent->pattern)), 0);
                hv_store(rh, "flags", 5,
                         newSVnv((double)ent->match_flags), 0);
                av_push(result, newRV((SV *)rh));
            }
            RETVAL = newRV((SV *)result);
        }
    OUTPUT:
        RETVAL

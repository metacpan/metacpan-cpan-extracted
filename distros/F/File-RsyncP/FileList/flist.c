/* 
   Copyright (C) Andrew Tridgell 1996
   Copyright (C) Paul Mackerras 1996
   Copyright (C) 2001, 2002 by Martin Pool <mbp@samba.org>
   
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

/** @file flist.c
 * Generate and receive file lists
 *
 * @todo Get rid of the string_area optimization.  Efficiently
 * allocating blocks is the responsibility of the system's malloc
 * library, not of rsync.
 *
 * @sa http://lists.samba.org/pipermail/rsync/2000-June/002351.html
 *
 **/

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <dirent.h>
#include <math.h>

#include <XSUB.h>

#include "rsync.h"

extern struct stats stats;

static char empty_sum[MD4_SUM_LENGTH];
static unsigned int file_struct_len;


void init_flist(void)
{
    struct file_struct f;

    /* Figure out how big the file_struct is without trailing padding */
    file_struct_len = offsetof(struct file_struct, flags) + sizeof f.flags;
}

static int to_wire_mode(mode_t mode)
{
    if (S_ISLNK(mode) && (_S_IFLNK != 0120000)) {
        return (mode & ~(_S_IFMT)) | 0120000;
    }
    return (int) mode;
}

static mode_t from_wire_mode(int mode)
{
    if ((mode & (_S_IFMT)) == 0120000 && (_S_IFLNK != 0120000)) {
        return (mode & ~(_S_IFMT)) | _S_IFLNK;
    }
    return (mode_t) mode;
}

/* we need this function because of the silly way in which duplicate
   entries are handled in the file lists - we can't change this
   without breaking existing versions */
static int flist_up(struct file_list *flist, int i)
{
    while (!flist->files[i]->basename) i++;
    return i;
}

/**
 * Make sure @p flist is big enough to hold at least @p flist->count
 * entries.
 **/
void flist_expand(struct file_list *flist)
{
    struct file_struct **new_ptr;

    if (flist->count < flist->malloced)
        return;

    if (flist->malloced < FLIST_START)
        flist->malloced = FLIST_START;
    else if (flist->malloced >= FLIST_LINEAR)
        flist->malloced += FLIST_LINEAR;
    else
        flist->malloced *= 2;

    /*
     * In case count jumped or we are starting the list
     * with a known size just set it.
     */
    if (flist->malloced < flist->count)
        flist->malloced = flist->count;

    new_ptr = realloc_array(flist->files, struct file_struct *,
                            flist->malloced);

    flist->files = new_ptr;

    if (!flist->files)
        out_of_memory("flist_expand");
}

static void readfd(struct file_list *f, unsigned char *buffer, size_t N)
{
    if ( f->inError || f->inPosn + N > f->inLen ) {
        memset(buffer, 0, N);
        f->inError = 1;
        return;
    }
    memcpy(buffer, f->inBuf + f->inPosn, N);
    f->inPosn += N;
}

int32 read_int(struct file_list *f)
{
    unsigned char b[4];
    int32 ret;

    readfd(f,b,4);
    ret = b[0] | b[1] << 8 | b[2] << 16 | b[3] << 24;
    if (ret == (int32)0xffffffff) return -1;
    return ret;
}

int64 read_longint(struct file_list *f)
{
    int32 ret = read_int(f);
    double d;

    if (ret != (int32)0xffffffff) {
        return ret;
    }
    d  = (uint32)read_int(f);
    d += ((uint32)read_int(f)) * 65536.0 * 65536.0;
    return d;
}

void read_buf(struct file_list *f,char *buf,size_t len)
{
    readfd(f, (unsigned char*)buf, len);
}

void read_sbuf(struct file_list *f,char *buf,size_t len)
{
    read_buf(f,buf,len);
    buf[len] = 0;
}

unsigned char read_byte(struct file_list *f)
{
    unsigned char c;
    read_buf (f, (char *)&c, 1);
    return c;
}

void receive_file_entry(struct file_list *f, struct file_struct **fptr,
			       unsigned short flags)
{
    /*
     * originally static variables to maintain state; now in file_list.
     */
    time_t modtime = f->modtime;
    mode_t mode = f->mode;
    uint64 dev = f->dev;
    dev_t rdev = f->rdev;
    uint32 rdev_major = f->rdev_major;
    uid_t uid = f->uid;
    gid_t gid = f->gid;
    char lastname[MAXPATHLEN];
    char *lastdir = f->lastdir;
    int lastdir_depth = f->lastdir_depth;
    int lastdir_len = f->lastdir_len;

    /*
     * original auto variables
     */
    char thisname[MAXPATHLEN];
    unsigned int l1 = 0, l2 = 0;
    int alloc_len, basename_len, dirname_len, linkname_len, sum_len;
    OFF_T file_length;
    char *basename, *dirname, *bp;
    struct file_struct *file;

    if (!fptr) {
        f->modtime = 0; f->mode = 0;
        f->dev = 0; f->rdev = makedev(0, 0);
        f->rdev_major = 0;
        f->uid = 0; f->gid = 0;
        *f->lastname = '\0';
        f->lastdir_len = -1;
        return;
    }

    if (flags & XMIT_SAME_NAME)
        l1 = read_byte(f);

    if (flags & XMIT_LONG_NAME)
        l2 = read_int(f);
    else
        l2 = read_byte(f);

    if (l2 >= MAXPATHLEN - l1) {
        fprintf(stderr, "overflow: flags=0x%x l1=%d l2=%d, lastname=%s\n",
                            flags, l1, l2, f->lastname);
        f->fatalError = 1;
        return;
    }

    strlcpy(thisname, f->lastname, l1 + 1);
    read_sbuf(f, &thisname[l1], l2);
    thisname[l1 + l2] = 0;

    strlcpy(lastname, thisname, MAXPATHLEN);

    clean_fname(thisname, 0);

    if (f->sanitize_paths) {
        sanitize_path(thisname, thisname, "", 0);
    }

    if ((basename = strrchr(thisname, '/')) != NULL) {
        dirname_len = ++basename - thisname; /* counts future '\0' */
        if (lastdir_len == dirname_len - 1
            && strncmp(thisname, lastdir, lastdir_len) == 0) {
                dirname = lastdir;
                dirname_len = 0; /* indicates no copy is needed */
        } else
                dirname = thisname;
    } else {
        basename = thisname;
        dirname = NULL;
        dirname_len = 0;
    }
    basename_len = strlen(basename) + 1; /* count the '\0' */

    file_length = read_longint(f);

    if (!(flags & XMIT_SAME_TIME))
            modtime = (time_t)read_int(f);
    if (!(flags & XMIT_SAME_MODE))
            mode = from_wire_mode(read_int(f));

    if (f->preserve_uid && !(flags & XMIT_SAME_UID))
            uid = (uid_t)read_int(f);
    if (f->preserve_gid && !(flags & XMIT_SAME_GID))
            gid = (gid_t)read_int(f);

    if (f->preserve_devices) {
        if (f->protocol_version < 28) {
            if (IS_DEVICE(mode)) {
                    if (!(flags & XMIT_SAME_RDEV_pre28))
                            rdev = (dev_t)read_int(f);
            } else
                    rdev = makedev(0, 0);
        } else if (IS_DEVICE(mode)) {
            uint32 rdev_minor;
            if (!(flags & XMIT_SAME_RDEV_MAJOR))
                    rdev_major = read_int(f);
            if (flags & XMIT_RDEV_MINOR_IS_SMALL)
                    rdev_minor = read_byte(f);
            else
                    rdev_minor = read_int(f);
            rdev = makedev(rdev_major, rdev_minor);
        }
    }

    if (f->preserve_links && S_ISLNK(mode)) {
        linkname_len = read_int(f) + 1; /* count the '\0' */
        if (linkname_len <= 0 || linkname_len > MAXPATHLEN) {
            fprintf(stderr, "overflow on symlink: linkname_len=%d\n",
                        linkname_len - 1);
            f->fatalError = 1;
            return;
        }
    } else {
        linkname_len = 0;
    }

    sum_len = f->always_checksum && S_ISREG(mode) ? MD4_SUM_LENGTH : 0;

    alloc_len = file_struct_len + dirname_len + basename_len
              + linkname_len + sum_len;

    /*
     * make sure we have enough input data left to complete the file
     * structure.
     *
     * TODO
     */

    bp = pool_alloc(f->file_pool, alloc_len, "receive_file_entry");

    file = *fptr = (struct file_struct *)bp;
    memset(bp, 0, file_struct_len);
    bp += file_struct_len;

    file->flags = flags & XMIT_TOP_DIR ? FLAG_TOP_DIR : 0;
    file->modtime = modtime;
    file->length = file_length;
    file->mode = mode;
    file->uid = uid;
    file->gid = gid;

    if (dirname_len) {
        file->dirname = lastdir = bp;
        lastdir_len = dirname_len - 1;
        memcpy(bp, dirname, dirname_len - 1);
        bp += dirname_len;
        bp[-1] = '\0';
        if (f->sanitize_paths)
            lastdir_depth = count_dir_elements(lastdir);
    } else if (dirname) {
        file->dirname = dirname;
    }

    file->basename = bp;
    memcpy(bp, basename, basename_len);
    bp += basename_len;

    if (f->preserve_devices && IS_DEVICE(mode))
        file->u.rdev = rdev;

    if (linkname_len) {
        file->u.link = bp;
        read_sbuf(f, bp, linkname_len - 1);
        if (f->sanitize_paths)
            sanitize_path(bp, bp, "", lastdir_depth);
        bp += linkname_len;
    }

    if (f->preserve_hard_links && f->protocol_version < 28 && S_ISREG(mode))
        flags |= XMIT_HAS_IDEV_DATA;
    if (flags & XMIT_HAS_IDEV_DATA) {
        uint64 inode;
        if (f->protocol_version < 26) {
            dev = read_int(f);
            inode = read_int(f);
        } else {
            if (!(flags & XMIT_SAME_DEV))
                dev = read_longint(f);
            inode = read_longint(f);
        }
        if (f->idev_pool) {
            file->link_u.idev = pool_talloc(f->idev_pool,
                struct idev, 1, "inode_table");
            file->F_INODE = inode;
            file->F_DEV = dev;
        }
/*
        fprintf(stderr, "Got inode %d, dev %d, idev = %p, idev_pool = %p\n",
                (int32)inode, (int32)dev, file->link_u.idev, f->idev_pool);
*/
    }

    if (f->always_checksum) {
        char *sum;
        if (sum_len) {
            file->u.sum = sum = bp;
            /*bp += sum_len;*/
        } else if (f->protocol_version < 28) {
            /* Prior to 28, we get a useless set of nulls. */
            sum = empty_sum;
        } else
            sum = NULL;
        if (sum) {
            read_buf(f, sum, f->protocol_version < 21 ? 2 : MD4_SUM_LENGTH);
        }
    }

    /*
     * It's important that we don't update anything in f before
     * this point.  If we ran out of input bytes then we need to
     * resume after the caller appends more bytes.
     */
    if ( f->inError ) {
        pool_free(f->file_pool, alloc_len, bp);
	return;
    }

    f->modtime = modtime;
    f->mode = mode;
    f->dev = dev;
    f->rdev = rdev;
    f->rdev_major = rdev_major;
    f->uid = uid;
    f->gid = gid;
    strlcpy(f->lastname, lastname, MAXPATHLEN);
    f->lastname[MAXPATHLEN - 1] = 0;
    if ( lastdir )
	f->lastdir = lastdir;
    f->lastdir_depth = lastdir_depth;
    f->lastdir_len = lastdir_len;

/* fprintf(stderr, "Got name thisname %s\n", thisname); */
}

static void writefd(struct file_list *f, char *buf, size_t len)
{
    if ( !f->outBuf ) {
        f->outLen = 32768 + len;
        f->outBuf = malloc(f->outLen);
    } else if ( f->outPosn + len > f->outLen ) {
        f->outLen = 32768 + f->outPosn + len;
        f->outBuf = realloc(f->outBuf, f->outLen);
    }
    memcpy(f->outBuf + f->outPosn, buf, len);
    f->outPosn += len;
}

void write_int(struct file_list *f,int32 x)
{
    char b[4];
    b[0] = x >> 0;
    b[1] = x >> 8;
    b[2] = x >> 16;
    b[3] = x >> 24;
    writefd(f,b,4);
}

/*
 * Note: int64 may actually be a 32-bit type if ./configure couldn't find any
 * 64-bit types on this platform.
 */
void write_longint(struct file_list *f, int64 x)
{
    char b[8];

    if (x <= 0x7FFFFFFF) {
        write_int(f, (int)x); 
        return;
    }               
            
#ifdef INT64_IS_OFF_T
    if (sizeof (int64) < 8) {
        fprintf(stderr, "write_longint: Integer overflow: attempted 64-bit offset\n");
    }
#endif

    write_int(f, (int32)0xFFFFFFFF);
    SIVAL(b,0,(x&0xFFFFFFFF));
    SIVAL(b,4,((x>>32)&0xFFFFFFFF));

    writefd(f,b,8);
}

void write_buf(struct file_list *f,char *buf,size_t len)
{
    writefd(f,buf,len);
}

/* write a string to the connection */
void write_sbuf(struct file_list *f,char *buf)
{
    write_buf(f, buf, strlen(buf));
}

void write_byte(struct file_list *f,unsigned char c)
{
    write_buf(f,(char *)&c,1);
}

void send_file_entry(struct file_list *f, struct file_struct *file,
                     unsigned short base_flags)
{
    time_t modtime = f->modtime;
    mode_t mode = f->mode;
    uint64 dev = f->dev;
    dev_t rdev = f->rdev;
    uint32 rdev_major = f->rdev_major;
    uid_t uid = f->uid;
    gid_t gid = f->gid;
    char lastname[MAXPATHLEN];

    unsigned short flags;
    char fname[MAXPATHLEN];
    int l1, l2;

    strlcpy(lastname, f->lastname, MAXPATHLEN);

    if (!file) {
        write_byte(f, 0);
        f->modtime = 0; f->mode = 0;
        f->dev = 0; f->rdev = makedev(0, 0);
        f->rdev_major = 0;
        f->uid = 0; f->gid = 0;
        *f->lastname = '\0';
        return;
    }

    f_name_to(file, fname);

    flags = base_flags;

    if (file->mode == mode)
        flags |= XMIT_SAME_MODE;
    else
        mode = file->mode;

    if (f->preserve_devices) {
        if (f->protocol_version < 28) {
            if (IS_DEVICE(mode)) {
                if (file->u.rdev == rdev)
                    flags |= XMIT_SAME_RDEV_pre28;
                else
                    rdev = file->u.rdev;
            } else
                rdev = makedev(0, 0);
        } else if (IS_DEVICE(mode)) {
            rdev = file->u.rdev;
            if ((uint32)major(rdev) == rdev_major)
                flags |= XMIT_SAME_RDEV_MAJOR;
            else
                rdev_major = major(rdev);
            if ((uint32)minor(rdev) <= 0xFFu)
                flags |= XMIT_RDEV_MINOR_IS_SMALL;
        }
    }

    if (file->uid == uid)
        flags |= XMIT_SAME_UID;
    else
        uid = file->uid;
    if (file->gid == gid)
        flags |= XMIT_SAME_GID;
    else
        gid = file->gid;
    if (file->modtime == modtime)
        flags |= XMIT_SAME_TIME;
    else
        modtime = file->modtime;

    if (file->link_u.idev) {
        if (file->F_DEV == dev) {
            if (f->protocol_version >= 28)
                flags |= XMIT_SAME_DEV;
        } else
            dev = file->F_DEV;
        flags |= XMIT_HAS_IDEV_DATA;
    }

    for (l1 = 0;
        lastname[l1] && (fname[l1] == lastname[l1]) && (l1 < 255);
        l1++) {}
    l2 = strlen(fname+l1);

    if (l1 > 0)
        flags |= XMIT_SAME_NAME;
    if (l2 > 255)
        flags |= XMIT_LONG_NAME;

    /* We must make sure we don't send a zero flag byte or the
     * other end will terminate the flist transfer.  Note that
     * the use of XMIT_TOP_DIR on a non-dir has no meaning, so
     * it's harmless way to add a bit to the first flag byte. */
    if (f->protocol_version >= 28) {
        if (!flags && !S_ISDIR(mode))
            flags |= XMIT_TOP_DIR;
        if ((flags & 0xFF00) || !flags) {
            flags |= XMIT_EXTENDED_FLAGS;
            write_byte(f, flags);
            write_byte(f, flags >> 8);
        } else
            write_byte(f, flags);
    } else {
        if (!(flags & 0xFF) && !S_ISDIR(mode))
            flags |= XMIT_TOP_DIR;
        if (!(flags & 0xFF))
            flags |= XMIT_LONG_NAME;
        write_byte(f, flags);
    }

    if (flags & XMIT_SAME_NAME)
        write_byte(f, l1);
    if (flags & XMIT_LONG_NAME)
        write_int(f, l2);
    else
        write_byte(f, l2);
    write_buf(f, fname + l1, l2);

    write_longint(f, file->length);
    if (!(flags & XMIT_SAME_TIME))
        write_int(f, modtime);
    if (!(flags & XMIT_SAME_MODE))
        write_int(f, to_wire_mode(mode));
    if (f->preserve_uid && !(flags & XMIT_SAME_UID)) {
/*
        TODO
        if (!numeric_ids)
            add_uid(uid);
*/
        write_int(f, uid);
    }
    if (f->preserve_gid && !(flags & XMIT_SAME_GID)) {
/*
        TODO
        if (!numeric_ids)
            add_gid(gid);
*/
        write_int(f, gid);
    }
    if (f->preserve_devices && IS_DEVICE(mode)) {
        if (f->protocol_version < 28) {
            if (!(flags & XMIT_SAME_RDEV_pre28))
                write_int(f, (int)rdev);
        } else {
            if (!(flags & XMIT_SAME_RDEV_MAJOR))
                write_int(f, major(rdev));
            if (flags & XMIT_RDEV_MINOR_IS_SMALL)
                write_byte(f, minor(rdev));
            else
                write_int(f, minor(rdev));
        }
    }
    if (f->preserve_links && S_ISLNK(mode)) {
        int len = strlen(file->u.link);
        write_int(f, len);
        write_buf(f, file->u.link, len);
    }

    if (flags & XMIT_HAS_IDEV_DATA) {
        if (f->protocol_version < 26) {
            /* 32-bit dev_t and ino_t */
            write_int(f, dev);
            write_int(f, file->F_INODE);
        } else {
            /* 64-bit dev_t and ino_t */
            if (!(flags & XMIT_SAME_DEV))
                    write_longint(f, dev);
            write_longint(f, file->F_INODE);
/*
            fprintf(stderr, "file %s sending dev 0x%x%x, inode 0x%x%x\n",
                    fname,
                    (unsigned int)(file->F_DEV >> 32),
                    (unsigned int)(file->F_DEV),
                    (unsigned int)(file->F_INODE >> 32),
                    (unsigned int)(file->F_INODE)
                );
*/
        }
    }

    if (f->always_checksum) {
        char *sum;
        if (S_ISREG(mode))
            sum = file->u.sum;
        else if (f->protocol_version < 28) {
            /* Prior to 28, we sent a useless set of nulls. */
            sum = empty_sum;
        } else
            sum = NULL;
        if (sum) {
            write_buf(f, sum,
                f->protocol_version < 21 ? 2 : MD4_SUM_LENGTH);
        }
    }

    f->modtime = modtime;
    f->mode = mode;
    f->dev = dev;
    f->rdev = rdev;
    f->rdev_major = rdev_major;
    f->uid = uid;
    f->gid = gid;

    strlcpy(f->lastname, fname, MAXPATHLEN);
}

int flistDecodeBytes(struct file_list *f, unsigned char *bytes, uint32 nBytes)
{
    unsigned short flags;

    f->inBuf = bytes;
    f->inLen = nBytes;
    f->inFileStart = f->inPosn = 0;
    f->inError = 0;
    f->fatalError = 0;
    f->decodeDone = 0;
    for ( flags = read_byte(f); flags; flags = read_byte(f) ) {
        int i = f->count;

        flist_expand(f);

        if (f->protocol_version >= 28 && (flags & XMIT_EXTENDED_FLAGS))
                flags |= read_byte(f) << 8;

        receive_file_entry(f, &f->files[i], flags);
        if ( f->inError ) {
            /*
                fprintf(stderr, "Returning on input error, posn = %d\n",
                        f->inPosn);
            */
            break;
        }
#if 0
        if (S_ISREG(f->files[i]->mode))
                stats.total_size += f->files[i]->length;
#endif

        f->count++;
        f->inFileStart = f->inPosn;
    }
    if ( f->fatalError ) {
        return -1;
    } else if ( f->inError ) {
        return f->inFileStart;
    } else {
        f->decodeDone = 1;
        return f->inPosn;
    }
}

#ifndef HAVE_STRLCPY
/* Like strncpy but does not 0 fill the buffer and always null 
 * terminates. bufsize is the size of the destination buffer.
 * 
 * Returns the index of the terminating byte. */
size_t strlcpy(char *d, const char *s, size_t bufsize)
{
        size_t len = strlen(s);
        size_t ret = len;
        if (bufsize <= 0) return 0;
        if (len >= bufsize) len = bufsize-1;
        memcpy(d, s, len);
        d[len] = 0;
        return ret;
}
#endif

/* we need to supply our own strcmp function for file list comparisons
   to ensure that signed/unsigned usage is consistent between machines. */
int u_strcmp(const char *cs1, const char *cs2)
{
    const uchar *s1 = (const uchar *)cs1;
    const uchar *s2 = (const uchar *)cs2;

    while (*s1 && *s2 && (*s1 == *s2)) {
        s1++; s2++;
    }

    return (int)*s1 - (int)*s2;
}

/*
 * XXX: This is currently the hottest function while building the file
 * list, because building f_name()s every time is expensive.
 **/
int file_compare(struct file_struct **file1, struct file_struct **file2)
{
    struct file_struct *f1 = *file1;
    struct file_struct *f2 = *file2;
            
    if (!f1->basename && !f2->basename)
            return 0;
    if (!f1->basename)
            return -1;
    if (!f2->basename)
            return 1; 
    if (f1->dirname == f2->dirname) 
            return u_strcmp(f1->basename, f2->basename);
    return f_name_cmp(f1, f2);
}

int flist_find(struct file_list *flist, struct file_struct *f)
{
    int low = 0, high = flist->count - 1;

    while (high >= 0 && !flist->files[high]->basename) high--;

    if (high < 0)
        return -1;

    while (low != high) {
        int mid = (low + high) / 2;
        int ret = file_compare(&flist->files[flist_up(flist, mid)],&f);
        if (ret == 0)
            return flist_up(flist, mid);
        if (ret > 0)
            high = mid;
        else
            low = mid + 1;
    }

    if (file_compare(&flist->files[flist_up(flist, low)], &f) == 0)
        return flist_up(flist, low);
    return -1;
}

/*
 * Free up any resources a file_struct has allocated
 * and clear the file.
 */
void clear_file(int i, struct file_list *flist)
{
    if (flist->idev_pool && flist->files[i]->link_u.idev)
        pool_free(flist->idev_pool, 0, flist->files[i]->link_u.idev);
    memset(flist->files[i], 0, file_struct_len);
}

struct file_list *flist_new(int with_hlink, char *msg, int preserve_hard_links)
{
    struct file_list *flist;

    init_flist();
    flist = new(struct file_list);
    if (!flist)
        out_of_memory(msg);
    
    memset(flist, 0, sizeof (struct file_list)); 
            
    if (!(flist->file_pool = pool_create(FILE_EXTENT, 0,
        out_of_memory, POOL_INTERN)))
            out_of_memory(msg);
                       
    if (with_hlink && preserve_hard_links) {
        if (!(flist->idev_pool = pool_create(HLINK_EXTENT,
            sizeof (struct idev), out_of_memory, POOL_INTERN)))
                out_of_memory(msg);
    }

    return flist;
}

/*
 * free up all elements in a flist
 */
void flist_free(struct file_list *flist)
{
        pool_destroy(flist->file_pool);
        pool_destroy(flist->idev_pool);
        pool_destroy(flist->hlink_pool);
        free(flist->files);
        if ( flist->hlink_list )
            free(flist->hlink_list);
        if ( flist->exclude_list.head )
            clear_exclude_list(&flist->exclude_list);
        free(flist);
}

/*
 * This routine ensures we don't have any duplicate names in our file list.
 * duplicate names can cause corruption because of the pipelining
 */
void clean_flist(struct file_list *flist, int strip_root, int no_dups)
{
    int i, prev_i = 0;

    if (!flist || flist->count == 0)
        return;

    qsort(flist->files, flist->count,
        sizeof flist->files[0], (int (*)())file_compare);

    for (i = no_dups? 0 : flist->count; i < flist->count; i++) {
        if (flist->files[i]->basename) {
            prev_i = i;
            break;
        }
    }
    while (++i < flist->count) {
        if (!flist->files[i]->basename)
            continue;
        if (f_name_cmp(flist->files[i], flist->files[prev_i]) == 0) {
/*
            fprintf(stderr, "removing duplicate name %s from file list %d\n",
                    f_name(flist->files[i]), i);
*/
            /* Make sure that if we unduplicate '.', that we don't
             * lose track of a user-specified starting point (or
             * else deletions will mysteriously fail with -R). */
            if (flist->files[i]->flags & FLAG_TOP_DIR)
                flist->files[prev_i]->flags |= FLAG_TOP_DIR;

            clear_file(i, flist);
        } else
            prev_i = i;
    }

    if (strip_root) {
        /* we need to strip off the root directory in the case
           of relative paths, but this must be done _after_
           the sorting phase */
        for (i = 0; i < flist->count; i++) {
            if (flist->files[i]->dirname &&
                flist->files[i]->dirname[0] == '/') {
                    memmove(&flist->files[i]->dirname[0],
                            &flist->files[i]->dirname[1],
                            strlen(flist->files[i]->dirname));
            }

            if (flist->files[i]->dirname &&
                !flist->files[i]->dirname[0]) {
                    flist->files[i]->dirname = NULL;
            }
        }
    }
}

enum fnc_state { fnc_DIR, fnc_SLASH, fnc_BASE };

/* Compare the names of two file_struct entities, just like strcmp()
 * would do if it were operating on the joined strings.  We assume
 * that there are no 0-length strings.
 */
int f_name_cmp(struct file_struct *f1, struct file_struct *f2)
{
    int dif;
    const uchar *c1, *c2;
    enum fnc_state state1, state2;

    if (!f1 || !f1->basename) {
        if (!f2 || !f2->basename)
            return 0;
        return -1;
    }
    if (!f2 || !f2->basename)
        return 1;

    if (!(c1 = (uchar*)f1->dirname)) {
        state1 = fnc_BASE;
        c1 = (uchar*)f1->basename;
    } else if (!*c1) {
        state1 = fnc_SLASH;
        c1 = (uchar*)"/";
    } else
        state1 = fnc_DIR;
    if (!(c2 = (uchar*)f2->dirname)) {
        state2 = fnc_BASE;
        c2 = (uchar*)f2->basename;
    } else if (!*c2) {
        state2 = fnc_SLASH;
        c2 = (uchar*)"/";
    } else
        state2 = fnc_DIR;

    while (1) {
        if ((dif = (int)*c1 - (int)*c2) != 0)
            break;
        if (!*++c1) {
            switch (state1) {
            case fnc_DIR:
                state1 = fnc_SLASH;
                c1 = (uchar*)"/";
                break;
            case fnc_SLASH:
                state1 = fnc_BASE;
                c1 = (uchar*)f1->basename;
                break;
            case fnc_BASE:
                break;
            }
        }
        if (!*++c2) {
            switch (state2) {
            case fnc_DIR:
                state2 = fnc_SLASH;
                c2 = (uchar*)"/";
                break;
            case fnc_SLASH:
                state2 = fnc_BASE;
                c2 = (uchar*)f2->basename;
                break;
            case fnc_BASE:
                if (!*c1)
                    return 0;
                break;
            }
        }
    }

    return dif;
}


/* Return a copy of the full filename of a flist entry, using the indicated
 * buffer.  No size-checking is done because we checked the size when creating
 * the file_struct entry.
 */
char *f_name_to(struct file_struct *f, char *fbuf)
{
    if (!f || !f->basename)
        return NULL;

    if (f->dirname) {
        int len = strlen(f->dirname);
        memcpy(fbuf, f->dirname, len);
        fbuf[len] = '/';
        strcpy(fbuf + len + 1, f->basename);
    } else
        strcpy(fbuf, f->basename);
    return fbuf;
}


/* Like f_name_to(), but we rotate through 5 static buffers of our own.
 */
char *f_name(struct file_struct *f)
{
    static char names[5][MAXPATHLEN];
    static unsigned int n;

    n = (n + 1) % (sizeof names / sizeof names[0]);

    return f_name_to(f, names[n]);
}

/* Turns multiple adjacent slashes into a single slash, gets rid of "./"
 * elements (but not a trailing dot dir), removes a trailing slash, and
 * optionally collapses ".." elements (except for those at the start of the
 * string).  If the resulting name would be empty, change it into a ".". */
unsigned int clean_fname(char *name, BOOL collapse_dot_dot)
{
    char *limit = name - 1, *t = name, *f = name;
    int anchored;

    if (!name)
        return 0;

    if ((anchored = *f == '/') != 0)
        *t++ = *f++;
    while (*f) {
        /* discard extra slashes */
        if (*f == '/') {
            f++;
            continue;
        }
        if (*f == '.') {
            /* discard "." dirs (but NOT a trailing '.'!) */
            if (f[1] == '/') {
                f += 2;
                continue;
            }
            /* collapse ".." dirs */
            if (collapse_dot_dot
                    && f[1] == '.' && (f[2] == '/' || !f[2])) {
                char *s = t - 1;
                if (s == name && anchored) {
                    f += 2;
                    continue;
                }
                while (s > limit && *--s != '/') {}
                if (s != t - 1 && (s < name || *s == '/')) {
                    t = s + 1;
                    f += 2;
                    continue;
                }
                limit = t + 2;
            }
        }
        while (*f && (*t++ = *f++) != '/') {}
    }

    if (t > name+anchored && t[-1] == '/')
        t--;
    if (t == name)
        *t++ = '.';
    *t = '\0';

    return t - name;
}

/* Make path appear as if a chroot had occurred.  This handles a leading
 * "/" (either removing it or expanding it) and any leading or embedded
 * ".." components that attempt to escape past the module's top dir.
 *
 * If dest is NULL, a buffer is allocated to hold the result.  It is legal
 * to call with the dest and the path (p) pointing to the same buffer, but
 * rootdir will be ignored to avoid expansion of the string.
 *
 * The rootdir string contains a value to use in place of a leading slash.
 * Specify NULL to get the default of lp_path(module_id).
 *
 * If depth is > 0, it is a count of how many '..'s to allow at the start
 * of the path.
 *
 * We also clean the path in a manner similar to clean_fname() but with a
 * few differences: 
 *
 * Turns multiple adjacent slashes into a single slash, gets rid of "." dir
 * elements (INCLUDING a trailing dot dir), PRESERVES a trailing slash, and
 * ALWAYS collapses ".." elements (except for those at the start of the
 * string up to "depth" deep).  If the resulting name would be empty,
 * change it into a ".". */
char *sanitize_path(char *dest, const char *p, const char *rootdir, int depth)
{
    char *start, *sanp;
    int rlen = 0;

    if (dest != p) {
        int plen = strlen(p);
        if (*p == '/') {
            if (!rootdir)
                rootdir = "";
            rlen = strlen(rootdir);
            depth = 0;
            p++;
        }
        if (dest) {
            if (rlen + plen + 1 >= MAXPATHLEN)
                return NULL;
        } else if (!(dest = new_array(char, rlen + plen + 1)))
            out_of_memory("sanitize_path");
        if (rlen) {
            memcpy(dest, rootdir, rlen);
            if (rlen > 1)
                dest[rlen++] = '/';
        }
    }

    start = sanp = dest + rlen;
    while (*p != '\0') {
        /* discard leading or extra slashes */
        if (*p == '/') {
            p++;
            continue;
        }
        /* this loop iterates once per filename component in p.
         * both p (and sanp if the original had a slash) should
         * always be left pointing after a slash
         */
        if (*p == '.' && (p[1] == '/' || p[1] == '\0')) {
            /* skip "." component */
            p++;
            continue;
        }
        if (*p == '.' && p[1] == '.' && (p[2] == '/' || p[2] == '\0')) {
            /* ".." component followed by slash or end */
            if (depth <= 0 || sanp != start) {
                p += 2;
                if (sanp != start) {
                    /* back up sanp one level */
                    --sanp; /* now pointing at slash */
                    while (sanp > start && sanp[-1] != '/') {
                        /* skip back up to slash */
                        sanp--;
                    }
                }
                continue;
            }
            /* allow depth levels of .. at the beginning */
            depth--;
            /* move the virtual beginning to leave the .. alone */
            start = sanp + 3;
        }
        /* copy one component through next slash */
        while (*p && (*sanp++ = *p++) != '/') {}
    }
    if (sanp == dest) {
        /* ended up with nothing, so put in "." component */
        *sanp++ = '.';
    }
    *sanp = '\0';

    return dest;
}

void out_of_memory(char *str)
{               
    fprintf(stderr, "ERROR: File::RsyncP out of memory in %s\n", str);
    exit(1);
}       

int count_dir_elements(const char *p) 
{       
    int cnt = 0, new_component = 1;
    while (*p) {
        if (*p++ == '/')
            new_component = 1;
        else if (new_component) {
            new_component = 0;
            cnt++;
        }
    }
    return cnt;
}       

#define MALLOC_MAX 0x40000000
             
void *_new_array(unsigned int size, unsigned long num)
{
        if (num >= MALLOC_MAX/size) 
                return NULL;
        return malloc(size * num);
}

void *_realloc_array(void *ptr, unsigned int size, unsigned long num)
{   
        if (num >= MALLOC_MAX/size) 
                return NULL;
        /* No realloc should need this, but just in case... */
        if (!ptr)
                return malloc(size * num);
        return realloc(ptr, size * num);
}

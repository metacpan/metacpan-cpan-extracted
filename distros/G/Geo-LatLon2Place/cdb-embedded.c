/* embeddable/static cdb version by schmorp */

/* cdb.h: public cdb include file
 *
 * This file is a part of tinycdb package by Michael Tokarev, mjt@corpit.ru.
 * Public domain.
 */

#ifndef TINYCDB_VERSION
#define TINYCDB_VERSION 0.78

#ifdef __cplusplus
extern "C" {
#endif

typedef unsigned int cdbi_t; /* compatibility */

/* common routines */
static unsigned cdb_hash(const void *buf, unsigned len);
static unsigned cdb_unpack(const unsigned char buf[4]);
static void cdb_pack(unsigned num, unsigned char buf[4]);

struct cdb {
  int cdb_fd;			/* file descriptor */
  /* private members */
  unsigned cdb_fsize;		/* datafile size */
  unsigned cdb_dend;		/* end of data ptr */
  const unsigned char *cdb_mem; /* mmap'ed file memory */
  unsigned cdb_vpos, cdb_vlen;	/* found data */
  unsigned cdb_kpos, cdb_klen;	/* found key */
};

#define CDB_STATIC_INIT {0,0,0,0,0,0,0,0}

#define cdb_datapos(c) ((c)->cdb_vpos)
#define cdb_datalen(c) ((c)->cdb_vlen)
#define cdb_keypos(c) ((c)->cdb_kpos)
#define cdb_keylen(c) ((c)->cdb_klen)
#define cdb_fileno(c) ((c)->cdb_fd)

static int cdb_init(struct cdb *cdbp, int fd);
static void cdb_free(struct cdb *cdbp);

static int cdb_read(const struct cdb *cdbp,
             void *buf, unsigned len, unsigned pos);
#define cdb_readdata(cdbp, buf) \
        cdb_read((cdbp), (buf), cdb_datalen(cdbp), cdb_datapos(cdbp))
#define cdb_readkey(cdbp, buf) \
        cdb_read((cdbp), (buf), cdb_keylen(cdbp), cdb_keypos(cdbp))

static const void *cdb_get(const struct cdb *cdbp, unsigned len, unsigned pos);
#define cdb_getdata(cdbp) \
        cdb_get((cdbp), cdb_datalen(cdbp), cdb_datapos(cdbp))
#define cdb_getkey(cdbp) \
        cdb_get((cdbp), cdb_keylen(cdbp), cdb_keypos(cdbp))

static int cdb_find(struct cdb *cdbp, const void *key, unsigned klen);

struct cdb_find {
  struct cdb *cdb_cdbp;
  unsigned cdb_hval;
  const unsigned char *cdb_htp, *cdb_htab, *cdb_htend;
  unsigned cdb_httodo;
  const void *cdb_key;
  unsigned cdb_klen;
};

static int cdb_findinit(struct cdb_find *cdbfp, struct cdb *cdbp,
                 const void *key, unsigned klen);
static int cdb_findnext(struct cdb_find *cdbfp);

#define cdb_seqinit(cptr, cdbp) ((*(cptr))=2048)
static int cdb_seqnext(unsigned *cptr, struct cdb *cdbp);

/* old simple interface */
/* open file using standard routine, then: */
static int cdb_seek(int fd, const void *key, unsigned klen, unsigned *dlenp);
static int cdb_bread(int fd, void *buf, int len);

/* cdb_make */

struct cdb_make {
  int cdb_fd;			/* file descriptor */
  /* private */
  unsigned cdb_dpos;		/* data position so far */
  unsigned cdb_rcnt;		/* record count so far */
  unsigned char cdb_buf[4096];	/* write buffer */
  unsigned char *cdb_bpos;	/* current buf position */
  struct cdb_rl *cdb_rec[256];	/* list of arrays of record infos */
};

enum cdb_put_mode {
  CDB_PUT_ADD = 0,	/* add unconditionnaly, like cdb_make_add() */
#define CDB_PUT_ADD	CDB_PUT_ADD
  CDB_FIND = CDB_PUT_ADD,
  CDB_PUT_REPLACE,	/* replace: do not place to index OLD record */
#define CDB_PUT_REPLACE	CDB_PUT_REPLACE
  CDB_FIND_REMOVE = CDB_PUT_REPLACE,
  CDB_PUT_INSERT,	/* add only if not already exists */
#define CDB_PUT_INSERT	CDB_PUT_INSERT
  CDB_PUT_WARN,		/* add unconditionally but ret. 1 if exists */
#define CDB_PUT_WARN	CDB_PUT_WARN
  CDB_PUT_REPLACE0,	/* if a record exists, fill old one with zeros */
#define CDB_PUT_REPLACE0 CDB_PUT_REPLACE0
  CDB_FIND_FILL0 = CDB_PUT_REPLACE0
};

static int cdb_make_start(struct cdb_make *cdbmp, int fd);
static int cdb_make_add(struct cdb_make *cdbmp,
                 const void *key, unsigned klen,
                 const void *val, unsigned vlen);
static int cdb_make_exists(struct cdb_make *cdbmp,
                    const void *key, unsigned klen);
static int cdb_make_find(struct cdb_make *cdbmp,
                  const void *key, unsigned klen,
                  enum cdb_put_mode mode);
static int cdb_make_put(struct cdb_make *cdbmp,
                 const void *key, unsigned klen,
                 const void *val, unsigned vlen,
                 enum cdb_put_mode mode);
static int cdb_make_finish(struct cdb_make *cdbmp);

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /* include guard */

/* cdb_int.h: internal cdb library declarations
 *
 * This file is a part of tinycdb package by Michael Tokarev, mjt@corpit.ru.
 * Public domain.
 */

#include <errno.h>
#include <string.h>

#ifndef EPROTO
# define EPROTO EINVAL
#endif

#define internal_function static

struct cdb_rec {
  unsigned hval;
  unsigned rpos;
};

struct cdb_rl {
  struct cdb_rl *next;
  unsigned cnt;
  struct cdb_rec rec[254];
};

static int _cdb_make_write(struct cdb_make *cdbmp,
		    const void *ptr, unsigned len);
static int _cdb_make_fullwrite(int fd, const unsigned char *buf, unsigned len);
static int _cdb_make_flush(struct cdb_make *cdbmp);
static int _cdb_make_add(struct cdb_make *cdbmp, unsigned hval,
                  const void *key, unsigned klen,
                  const void *val, unsigned vlen);

/* cdb_find.c: cdb_find routine
 *
 * This file is a part of tinycdb package by Michael Tokarev, mjt@corpit.ru.
 * Public domain.
 */

static int
cdb_find(struct cdb *cdbp, const void *key, unsigned klen)
{
  const unsigned char *htp;	/* hash table pointer */
  const unsigned char *htab;	/* hash table */
  const unsigned char *htend;	/* end of hash table */
  unsigned httodo;		/* ht bytes left to look */
  unsigned pos, n;

  unsigned hval;

  if (klen >= cdbp->cdb_dend)	/* if key size is too large */
    return 0;

  hval = cdb_hash(key, klen);

  /* find (pos,n) hash table to use */
  /* first 2048 bytes (toc) are always available */
  /* (hval % 256) * 8 */
  htp = cdbp->cdb_mem + ((hval << 3) & 2047); /* index in toc (256x8) */
  n = cdb_unpack(htp + 4);	/* table size */
  if (!n)			/* empty table */
    return 0;			/* not found */
  httodo = n << 3;		/* bytes of htab to lookup */
  pos = cdb_unpack(htp);	/* htab position */
  if (n > (cdbp->cdb_fsize >> 3) /* overflow of httodo ? */
      || pos < cdbp->cdb_dend /* is htab inside data section ? */
      || pos > cdbp->cdb_fsize /* htab start within file ? */
      || httodo > cdbp->cdb_fsize - pos) /* entrie htab within file ? */
    return errno = EPROTO, -1;

  htab = cdbp->cdb_mem + pos;	/* htab pointer */
  htend = htab + httodo;	/* after end of htab */
  /* htab starting position: rest of hval modulo htsize, 8bytes per elt */
  htp = htab + (((hval >> 8) % n) << 3);

  for(;;) {
    pos = cdb_unpack(htp + 4);	/* record position */
    if (!pos)
      return 0;
    if (cdb_unpack(htp) == hval) {
      if (pos > cdbp->cdb_dend - 8) /* key+val lengths */
	return errno = EPROTO, -1;
      if (cdb_unpack(cdbp->cdb_mem + pos) == klen) {
	if (cdbp->cdb_dend - klen < pos + 8)
	  return errno = EPROTO, -1;
	if (memcmp(key, cdbp->cdb_mem + pos + 8, klen) == 0) {
	  n = cdb_unpack(cdbp->cdb_mem + pos + 4);
	  pos += 8;
	  if (cdbp->cdb_dend < n || cdbp->cdb_dend - n < pos + klen)
	    return errno = EPROTO, -1;
	  cdbp->cdb_kpos = pos;
	  cdbp->cdb_klen = klen;
	  cdbp->cdb_vpos = pos + klen;
	  cdbp->cdb_vlen = n;
	  return 1;
	}
      }
    }
    httodo -= 8;
    if (!httodo)
      return 0;
    if ((htp += 8) >= htend)
      htp = htab;
  }

}

/* cdb_hash.c: cdb hashing routine
 *
 * This file is a part of tinycdb package by Michael Tokarev, mjt@corpit.ru.
 * Public domain.
 */

static unsigned
cdb_hash(const void *buf, unsigned len)
{
  register const unsigned char *p = (const unsigned char *)buf;
  register const unsigned char *end = p + len;
  register unsigned hash = 5381;	/* start value */
  while (p < end)
    hash = (hash + (hash << 5)) ^ *p++;
  return hash;
}

/* cdb_init.c: cdb_init, cdb_free and cdb_read routines
 *
 * This file is a part of tinycdb package by Michael Tokarev, mjt@corpit.ru.
 * Public domain.
 */

#include <sys/types.h>
#ifdef _WIN32
# include <windows.h>
#else
# include <sys/mman.h>
# ifndef MAP_FAILED
#  define MAP_FAILED ((void*)-1)
# endif
#endif
#include <sys/stat.h>

static int
cdb_init(struct cdb *cdbp, int fd)
{
  struct stat st;
  unsigned char *mem;
  unsigned fsize, dend;
#ifdef _WIN32
  HANDLE hFile, hMapping;
#endif

  /* get file size */
  if (fstat(fd, &st) < 0)
    return -1;
  /* trivial sanity check: at least toc should be here */
  if (st.st_size < 2048)
    return errno = EPROTO, -1;
  fsize = st.st_size < 0xffffffffu ? st.st_size : 0xffffffffu;
  /* memory-map file */
#ifdef _WIN32
  hFile = (HANDLE) _get_osfhandle(fd);
  if (hFile == (HANDLE) -1)
    return -1;
  hMapping = CreateFileMapping(hFile, NULL, PAGE_READONLY, 0, 0, NULL);
  if (!hMapping)
    return -1;
  mem = (unsigned char *)MapViewOfFile(hMapping, FILE_MAP_READ, 0, 0, 0);
  CloseHandle(hMapping);
  if (!mem)
    return -1;
#else
  mem = (unsigned char*)mmap(NULL, fsize, PROT_READ, MAP_SHARED, fd, 0);
  if (mem == MAP_FAILED)
    return -1;
#endif /* _WIN32 */

  cdbp->cdb_fd = fd;
  cdbp->cdb_fsize = fsize;
  cdbp->cdb_mem = mem;

#if 0
  /* XXX don't know well about madvise syscall -- is it legal
     to set different options for parts of one mmap() region?
     There is also posix_madvise() exist, with POSIX_MADV_RANDOM etc...
  */
#ifdef MADV_RANDOM
  /* set madvise() parameters. Ignore errors for now if system
     doesn't support it */
  madvise(mem, 2048, MADV_WILLNEED);
  madvise(mem + 2048, cdbp->cdb_fsize - 2048, MADV_RANDOM);
#endif
#endif

  cdbp->cdb_vpos = cdbp->cdb_vlen = 0;
  cdbp->cdb_kpos = cdbp->cdb_klen = 0;
  dend = cdb_unpack(mem);
  if (dend < 2048) dend = 2048;
  else if (dend >= fsize) dend = fsize;
  cdbp->cdb_dend = dend;

  return 0;
}

static void
cdb_free(struct cdb *cdbp)
{
  if (cdbp->cdb_mem) {
#ifdef _WIN32
    UnmapViewOfFile((void*) cdbp->cdb_mem);
#else
    munmap((void*)cdbp->cdb_mem, cdbp->cdb_fsize);
#endif /* _WIN32 */
    cdbp->cdb_mem = NULL;
  }
  cdbp->cdb_fsize = 0;
}

static const void *
cdb_get(const struct cdb *cdbp, unsigned len, unsigned pos)
{
  if (pos > cdbp->cdb_fsize || cdbp->cdb_fsize - pos < len) {
    errno = EPROTO;
    return NULL;
  }
  return cdbp->cdb_mem + pos;
}

static int
cdb_read(const struct cdb *cdbp, void *buf, unsigned len, unsigned pos)
{
  const void *data = cdb_get(cdbp, len, pos);
  if (!data) return -1;
  memcpy(buf, data, len);
  return 0;
}

/* cdb_make_add.c: basic cdb_make_add routine
 *
 * This file is a part of tinycdb package by Michael Tokarev, mjt@corpit.ru.
 * Public domain.
 */

#include <stdlib.h> /* for malloc */

int internal_function
_cdb_make_add(struct cdb_make *cdbmp, unsigned hval,
              const void *key, unsigned klen,
              const void *val, unsigned vlen)
{
  unsigned char rlen[8];
  struct cdb_rl *rl;
  unsigned i;
  if (klen > 0xffffffff - (cdbmp->cdb_dpos + 8) ||
      vlen > 0xffffffff - (cdbmp->cdb_dpos + klen + 8))
    return errno = ENOMEM, -1;
  i = hval & 255;
  rl = cdbmp->cdb_rec[i];
  if (!rl || rl->cnt >= sizeof(rl->rec)/sizeof(rl->rec[0])) {
    rl = (struct cdb_rl*)malloc(sizeof(struct cdb_rl));
    if (!rl)
      return errno = ENOMEM, -1;
    rl->cnt = 0;
    rl->next = cdbmp->cdb_rec[i];
    cdbmp->cdb_rec[i] = rl;
  }
  i = rl->cnt++;
  rl->rec[i].hval = hval;
  rl->rec[i].rpos = cdbmp->cdb_dpos;
  ++cdbmp->cdb_rcnt;
  cdb_pack(klen, rlen);
  cdb_pack(vlen, rlen + 4);
  if (_cdb_make_write(cdbmp, rlen, 8) < 0 ||
      _cdb_make_write(cdbmp, key, klen) < 0 ||
      _cdb_make_write(cdbmp, val, vlen) < 0)
    return -1;
  return 0;
}

static int
cdb_make_add(struct cdb_make *cdbmp,
             const void *key, unsigned klen,
             const void *val, unsigned vlen) {
  return _cdb_make_add(cdbmp, cdb_hash(key, klen), key, klen, val, vlen);
}

/* cdb_unpack.c: unpack 32bit integer
 *
 * This file is a part of tinycdb package by Michael Tokarev, mjt@corpit.ru.
 * Public domain.
 */

static inline unsigned
cdb_unpack(const unsigned char buf[4])
{
  unsigned n = buf[3];
  n <<= 8; n |= buf[2];
  n <<= 8; n |= buf[1];
  n <<= 8; n |= buf[0];
  return n;
}

/* cdb_make.c: basic cdb creation routines
 *
 * This file is a part of tinycdb package by Michael Tokarev, mjt@corpit.ru.
 * Public domain.
 */

#include <unistd.h>
#include <stdlib.h>
#include <string.h>

static inline void
cdb_pack(unsigned num, unsigned char buf[4])
{
  buf[0] = num & 255; num >>= 8;
  buf[1] = num & 255; num >>= 8;
  buf[2] = num & 255;
  buf[3] = num >> 8;
}

static int
cdb_make_start(struct cdb_make *cdbmp, int fd)
{
  memset(cdbmp, 0, sizeof(*cdbmp));
  cdbmp->cdb_fd = fd;
  cdbmp->cdb_dpos = 2048;
  cdbmp->cdb_bpos = cdbmp->cdb_buf + 2048;
  return 0;
}

int internal_function
_cdb_make_fullwrite(int fd, const unsigned char *buf, unsigned len)
{
  while(len) {
    int l = write(fd, buf, len);
    if (l > 0) {
      len -= l;
      buf += l;
    }
    else if (l < 0 && errno != EINTR)
      return -1;
  }
  return 0;
}

int internal_function
_cdb_make_flush(struct cdb_make *cdbmp) {
  unsigned len = cdbmp->cdb_bpos - cdbmp->cdb_buf;
  if (len) {
    if (_cdb_make_fullwrite(cdbmp->cdb_fd, cdbmp->cdb_buf, len) < 0)
      return -1;
    cdbmp->cdb_bpos = cdbmp->cdb_buf;
  }
  return 0;
}

int internal_function
_cdb_make_write(struct cdb_make *cdbmp, const void *ptr_, unsigned len)
{
  const unsigned char *ptr = (const unsigned char *)ptr_;
  unsigned l = sizeof(cdbmp->cdb_buf) - (cdbmp->cdb_bpos - cdbmp->cdb_buf);
  cdbmp->cdb_dpos += len;
  if (len > l) {
    memcpy(cdbmp->cdb_bpos, ptr, l);
    cdbmp->cdb_bpos += l;
    if (_cdb_make_flush(cdbmp) < 0)
      return -1;
    ptr += l; len -= l;
    l = len / sizeof(cdbmp->cdb_buf);
    if (l) {
      l *= sizeof(cdbmp->cdb_buf);
      if (_cdb_make_fullwrite(cdbmp->cdb_fd, ptr, l) < 0)
        return -1;
      ptr += l; len -= l;
    }
  }
  if (len) {
    memcpy(cdbmp->cdb_bpos, ptr, len);
    cdbmp->cdb_bpos += len;
  }
  return 0;
}

static int
cdb_make_finish_internal(struct cdb_make *cdbmp)
{
  unsigned hcnt[256];		/* hash table counts */
  unsigned hpos[256];		/* hash table positions */
  struct cdb_rec *htab;
  unsigned char *p;
  struct cdb_rl *rl;
  unsigned hsize;
  unsigned t, i;

  if (((0xffffffff - cdbmp->cdb_dpos) >> 3) < cdbmp->cdb_rcnt)
    return errno = ENOMEM, -1;

  /* count htab sizes and reorder reclists */
  hsize = 0;
  for (t = 0; t < 256; ++t) {
    struct cdb_rl *rlt = NULL;
    i = 0;
    rl = cdbmp->cdb_rec[t];
    while(rl) {
      struct cdb_rl *rln = rl->next;
      rl->next = rlt;
      rlt = rl;
      i += rl->cnt;
      rl = rln;
    }
    cdbmp->cdb_rec[t] = rlt;
    if (hsize < (hcnt[t] = i << 1))
      hsize = hcnt[t];
  }

  /* allocate memory to hold max htable */
  htab = (struct cdb_rec*)malloc((hsize + 2) * sizeof(struct cdb_rec));
  if (!htab)
    return errno = ENOENT, -1;
  p = (unsigned char *)htab;
  htab += 2;

  /* build hash tables */
  for (t = 0; t < 256; ++t) {
    unsigned len, hi;
    hpos[t] = cdbmp->cdb_dpos;
    if ((len = hcnt[t]) == 0)
      continue;
    for (i = 0; i < len; ++i)
      htab[i].hval = htab[i].rpos = 0;
    for (rl = cdbmp->cdb_rec[t]; rl; rl = rl->next)
      for (i = 0; i < rl->cnt; ++i) {
       hi = (rl->rec[i].hval >> 8) % len;
        while(htab[hi].rpos)
          if (++hi == len)
            hi = 0;
        htab[hi] = rl->rec[i];
      }
    for (i = 0; i < len; ++i) {
      cdb_pack(htab[i].hval, p + (i << 3));
      cdb_pack(htab[i].rpos, p + (i << 3) + 4);
    }
    if (_cdb_make_write(cdbmp, p, len << 3) < 0) {
      free(p);
      return -1;
    }
  }
  free(p);
  if (_cdb_make_flush(cdbmp) < 0)
    return -1;
  p = cdbmp->cdb_buf;
  for (t = 0; t < 256; ++t) {
    cdb_pack(hpos[t], p + (t << 3));
    cdb_pack(hcnt[t], p + (t << 3) + 4);
  }
  if (lseek(cdbmp->cdb_fd, 0, 0) != 0 ||
      _cdb_make_fullwrite(cdbmp->cdb_fd, p, 2048) != 0)
    return -1;

  return 0;
}

static void
cdb_make_free(struct cdb_make *cdbmp)
{
  unsigned t;
  for(t = 0; t < 256; ++t) {
    struct cdb_rl *rl = cdbmp->cdb_rec[t];
    while(rl) {
      struct cdb_rl *tm = rl;
      rl = rl->next;
      free(tm);
    }
  }
}

static int
cdb_make_finish(struct cdb_make *cdbmp)
{
  int r = cdb_make_finish_internal(cdbmp);
  cdb_make_free(cdbmp);
  return r;
}


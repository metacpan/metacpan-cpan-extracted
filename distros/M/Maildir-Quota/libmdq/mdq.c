/*
   Copyright 2000, 2001, 2002, 2003 Laurent Wacrenier

   This file is part of PLL libmdq.

   PLL libmdq is free software; you can redistribute it and/or modify
   it under the terms of the GNU Lesser Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   PLL libmdq is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU Lesser Public License for more details.

   You should have received a copy of the GNU Lesser Public License
   along with PLL lmtpd; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

*/

#include "config.h"

static char const rcsid[] UNUSED =
"$Id: mdq.c,v 1.17 2005/02/01 17:56:42 lwa Exp $" ;

#include <sys/types.h>
#include <sys/stat.h>
#include <sys/param.h>

#include <dirent.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include <time.h>

#include "mdq.h"

static char const rcsid_h[] UNUSED = MDQ_H_RCSID ;

int mdq_trash_quota = 0;

#define MAILDIRQUOTA_RECALCULATE_DELAY (15 * 60)
#define MAILDIRSIZE_BUFLEN 5120
#define TRASH "Trash"


#define strerrno strerror(errno)

const char *mdq_version = MDQ_VERSION;

static int _error(const char *message, ...) {
  if (mdq_error) {
    va_list ap;
    va_start(ap, message);
    mdq_error(message, ap);
    va_end(ap);
  }
  return -1;
}

#if __STDC_VERSION__ >= 199901L || __GNUC__ >= 3
#define error(...)    _error("[mdq] " __VA_ARGS__) 
#elif __GNUC__ <= 2
#define error(x...)   _error("[mdq] " x)
#else
#error Need C99 or GCC
#endif

static int mdq_add_dirsize(char *root, char *folder, char *subdir,
			   time_t *stamp, long *bytes, long *files) {

  char fn[MAXPATHLEN+1];
  if (snprintf(fn, MAXPATHLEN, "%s/%s/%s", root, folder, subdir) >= MAXPATHLEN)
    return error("filename too long '%s/%s/%s'", root, folder, subdir);

  if (stamp) {
    struct stat sb;
    if (stat(fn, &sb) == -1) 
      return -1; /* be quiet */
    /*      return error("unable to stat(%s): %s", fn, strerrno); */
    if (sb.st_mtime > *stamp) 
      *stamp = sb.st_mtime;
  }
  
  if (bytes || files) {
    DIR *dir;
    struct dirent *dp;
    if ((dir = opendir(fn)) == NULL) 
      return error("opendir(%s): %s", fn, strerrno);
    while((dp = readdir(dir)) != NULL) {
      if (dp->d_name[0] != '.') {
	char *end = strchr(dp->d_name, ':');
	char *pos = strstr(dp->d_name, ",S=");
	/*      printf("count %s/%s/%s\n", folder, subdir, dp->d_name); */
	if (pos && (!end || pos < end)) {
	  if (end  == NULL ||
	      strncmp(end+1, "2,", sizeof("2,") -1) != 0 ||
	      (!mdq_trash_quota && strchr(end+sizeof(":2,")-1, 'T') == 0)) {
	    unsigned long size = strtoul(pos + sizeof(",S=")-1 , NULL, 10);
	    if (bytes) *bytes += size;
	    if (files) *files += 1;
	  }
	} else {
	  if (snprintf(fn, MAXPATHLEN, "%s/%s/%s/%s",
		       root, folder, subdir, dp->d_name) < MAXPATHLEN) {
	    struct stat sb;
	    if (bytes && lstat(fn, &sb) == 0 && S_ISREG(sb.st_mode))
	      *bytes += sb.st_size;
	    if (files) *files += 1;
	  }
	}
      }
    }
    closedir(dir);
  }
  return 0;
}

static int mdq_getrealsize(char *dir, time_t *stamp,
			       long *bytes, long *files) {
  DIR *dirp;
  int remove_trash = !mdq_trash_quota;
  if (bytes) *bytes = 0;
  if (files) *files = 0;
  if (stamp) *stamp = 0;
  dirp = opendir(dir);
  if (dirp) {
    struct dirent *dp;
    while((dp = readdir(dirp)) != NULL) {
      if (dp->d_name[0] == '.' &&
	  !(dp->d_name[1] == '.' && dp->d_name[2] == 0)) {
	if (remove_trash && strcmp(dp->d_name +1, TRASH) == 0) {
	  remove_trash = 0; /* present once */
	} else {
	  mdq_add_dirsize(dir, dp->d_name, "new", stamp, bytes, files); 
	  mdq_add_dirsize(dir, dp->d_name, "cur", stamp, bytes, files);
	}
      }
    }
    closedir(dirp);
  }
  return 0;
}

static int mdq_readquotadescr(char *s, long *bytes, long *files) {
  char *se;

  *bytes = -1;
  *files = -1;
  while(1) {
    long l = strtol(s, &se, 10);
    if (l == 0 && se == s)
      break;
    if (*se == 'S')
      *bytes = l;
    else if (*se == 'C') 
      *files = l;
    else
      break;
    s = se+1;
  }
  return 0;
}

static int mdq_recalculate(MDQ *q) {
  char tmp[MAXPATHLEN+1];
  char maildirsize[MAXPATHLEN+1];
  char buf[1024];
  char *buf_c;
  time_t saved_time;
  time_t time;

  q->bytes = 0;
  q->files = 0;

/* avoid endless recalculations on error */
  q->need_checksize = 0; 
  q->has_recalculate = 1;

  if (q->fd >= 0) {
    close(q->fd);
    q->fd = -1;
  }
  if (snprintf(tmp, MAXPATHLEN, "%s/tmp/maildirsize.%lu.XXXXXX", 
	       q->dir, (unsigned long)getpid()) >= MAXPATHLEN)
    return error("filename too long '%s/tmp/maildirsize.%lu.XXXXXX'",
		 q->dir, (unsigned long)getpid());

  if (snprintf(maildirsize, MAXPATHLEN, "%s/maildirsize", q->dir)>= MAXPATHLEN)
    return error("filename too long '%s/maildirsize'", q->dir);

  mdq_getrealsize(q->dir, &saved_time, &q->bytes, &q->files);

  q->fd = mkstemp(tmp);
  if (q->fd == -1)
    return error("mkstemp(%s): %s", tmp, strerrno);

  buf_c = buf;
  if (q->max_bytes>0) {
    buf_c += sprintf(buf_c, "%ldS", q->max_bytes);
    if (q->max_files>0)
      buf_c += sprintf(buf_c, ",");
  }
  if (q->max_files>0)
    buf_c += sprintf(buf_c, "%ldC", q->max_files);

  buf_c += sprintf(buf_c, "\n");
  if (q->bytes > 0 && q->files > 0)
    buf_c += sprintf(buf_c, "%ld %ld\n", q->bytes, q->files);

  write(q->fd, buf, buf_c-buf);
  fsync(q->fd);

  if (rename(tmp, maildirsize) == -1) {
    close(q->fd);
    q->fd = -1;
    unlink(tmp);
    return error("rename(%s, %s): %s", tmp, maildirsize, strerrno);
  }
  mdq_getrealsize(q->dir, &time, NULL, NULL);
  if (time > saved_time) {
    close(q->fd);
    q->fd = -1;
    unlink(maildirsize);
  }
  return 0;
}

static int mdq_checksize(MDQ *q, int getinfo) {
  char buf[MAILDIRSIZE_BUFLEN+2];
  char *buf_end;
  ssize_t buflen;
#if 0
  struct stat sb;
#endif
  char *eol, *bol;
  long bytes_diff, files_diff;
  long max_bytes, max_files;
  char fn[MAXPATHLEN+1];

  if (snprintf(fn, MAXPATHLEN, "%s/maildirsize", q->dir) >= MAXPATHLEN)
    return error("filename too long '%s/maildirsize'", q->dir);

  if (q->fd == -1) {
    q->fd = open(fn, O_RDWR);
    if (q->fd == -1) {
      if (errno == ENOENT) {
	if (getinfo)
	  return -1;
	return mdq_recalculate(q);
      }
      else
	return error("open(%s): %s", fn, strerrno);
    }
    fcntl(q->fd, F_SETFD, FD_CLOEXEC);
#if 0
    if (fstat(q->fd, &sb) == -1) {
      error("fstat(%s): %s", fn, strerrno);
      close(q->fd);
      q->fd = -1;
      return -1;
    } 
    if (sb.st_size > MAILDIRSIZE_BUFLEN)
      return mdq_recalculate(q);
#endif
  }

  buflen = read(q->fd, buf, MAILDIRSIZE_BUFLEN);

  if (buflen < 0 || buflen >= MAILDIRSIZE_BUFLEN) {
    close(q->fd);
    q->fd = -1;
    return mdq_recalculate(q);
  }

  buf_end = buf + buflen;
  eol = memchr(buf, '\n', buflen);
  if (eol == NULL)
    return error("no EOL on fist line in %s", fn);
  *eol = 0;
  mdq_readquotadescr(buf, &max_bytes, &max_files);
  if (getinfo) {
    q->max_bytes = max_bytes;
    q->max_files = max_files;
  } else if (max_bytes != q->max_bytes || max_files != q->max_files)
      return mdq_recalculate(q);
  bol = eol + 1;
  bytes_diff = 0;
  files_diff = 0;
  while(bol < buf_end) {
    eol = memchr(bol, '\n', buf_end - bol);
    if (eol == NULL) 
      break;
    *eol = 0;
    bytes_diff += strtol(bol, &bol, 10);
    files_diff += strtol(bol, &bol, 10);
    bol = eol + 1;
  }
  q->bytes = bytes_diff;
  q->files = files_diff;
  q->need_checksize = 0;
  return 0;
}

static int mdq_quota_check(MDQ *q, long bytes, long files) {
  if (q->need_checksize)
    return 0; /* something wrong */
  if ((q->max_bytes > 0 && bytes >= 0 && 
       q->bytes + q->added_bytes + bytes > q->max_bytes) ||
      (q->max_files > 0 && files >= 0 &&
       q->files + q->added_files + files > q->max_files))
    return -1;
  else
    return 0;
}

int mdq_test(MDQ *q, long bytes, long files) {
  if (!q)
    return 0;
  if (q->need_checksize)
    mdq_checksize(q, 0);
  if (q->need_checksize) { /* something wrong */
    return 0;
  }
  
  if (mdq_quota_check(q, bytes, files) == -1) {
    struct stat sb;
    if (q->has_recalculate == 0 &&  q->fd != -1 && fstat(q->fd, &sb) == 0 && 
	sb.st_mtime + MAILDIRQUOTA_RECALCULATE_DELAY < time(NULL) ) {
      if (mdq_recalculate(q) == -1)
	return -1;
      if (mdq_quota_check(q, bytes, files) == -1) 
	  return -1;
    } else {
      return -1;
    }
  }
  return 0;
  
}

long mdq_get(MDQ *q, int what) {
  if (q == NULL || mdq_test(q, 0, 0) == -1)
    return -1;
  switch(what) {
  case MDQ_BYTES_CURRENT:
    return q->bytes + q->added_bytes;
  case MDQ_BYTES_MAX:
    return q->max_bytes;
  case MDQ_FILES_CURRENT:
    return q->files + q->added_files;
  case MDQ_FILES_MAX:
    return q->max_files;
  }
  return -1;
}

void mdq_add(MDQ *q, long bytes, long files) {
  if (!q) 
    return;
  if (q->need_checksize)
    mdq_checksize(q, 0);
  if (q->need_checksize)  /* something wrong */
    return;
  q->added_bytes += bytes;
  q->added_files += files;
  return;
}

MDQ *mdq_open(char *dir, char *quotastr) {
  char fn[MAXPATHLEN];
  struct stat sb;
  MDQ *q;
  long max_bytes=-1, max_files=-1;

  if (quotastr) {
    if (*quotastr == 0)
      return NULL;
    mdq_readquotadescr(quotastr, &max_bytes, &max_files);
    if (max_bytes <= 0 && max_files <=0)
      return NULL;
  }

  q = malloc(sizeof(MDQ));

  if (q == NULL) {
    error("creating MDQ: %s", strerrno);
    return NULL;
  }
  q->max_bytes = max_bytes;
  q->max_files = max_files;
  q->added_bytes = 0;
  q->added_files = 0;
  q->need_checksize = 1;
  q->has_recalculate = 0;
  q->fd = -1;

  if (snprintf(fn, MAXPATHLEN, "%s/maildirfolder", dir)>= MAXPATHLEN) {
    free(q);
    return NULL;
  }
  if (stat(fn, &sb) == 0) {
    if (snprintf(fn, MAXPATHLEN, "%s/..", dir)>= MAXPATHLEN) {
      free(q);
      return NULL;
    }
    q->dir = strdup(fn);
  } else
    q->dir = strdup(dir);

  if (q->dir == NULL) {
    free(q);
    error("malloc: %s", strerrno);
    return NULL;
  }

  if (quotastr == NULL && mdq_checksize(q, 1) != 0 &&
      q->max_bytes <0 && q->max_files < 0) {
    free(q->dir);
    free(q);
    return NULL;
  }
  return q;
}

void mdq_close(MDQ *q) {
  if (q) {
    if (q->fd>=0) {
      if (q->added_files != 0 && q->added_bytes != 0) {
	char buf[1024];
	char *buf_c = buf;
	buf_c += sprintf(buf_c, "%8ld %4ld\n", q->added_bytes, q->added_files);
	write(q->fd, buf, buf_c - buf);
	fsync(q->fd);
      }
      close(q->fd);
    }
    if (q->dir)
      free(q->dir);
    free(q);
  }
  return;
}


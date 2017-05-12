/*
 * $Id: IXP.xs 18 2010-06-03 13:50:07Z gomor $
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <ixp.h>

SV *
stat_c2sv(IxpStat *stat)
{
   HV *out     = newHV();
   SV *out_ref = newRV_noinc((SV *)out);

   if (stat != NULL) {
      hv_store(out, "type", 4, newSViv(stat->type), 0);
      hv_store(out, "dev", 3, newSViv(stat->dev), 0);
      hv_store(out, "mode", 4, newSViv(stat->mode), 0);
      hv_store(out, "atime", 5, newSViv(stat->atime), 0);
      hv_store(out, "mtime", 5, newSViv(stat->mtime), 0);
      hv_store(out, "length", 6, newSViv(stat->length), 0);
      hv_store(out, "name", 4, newSVpv(stat->name, 0), 0);
      hv_store(out, "uid", 3, newSVpv(stat->uid, 0), 0);
      hv_store(out, "gid", 3, newSVpv(stat->gid, 0), 0);
      hv_store(out, "muid", 4, newSVpv(stat->muid, 0), 0);
   }

   return out_ref;
}

MODULE = Lib::IXP  PACKAGE = Lib::IXP
PROTOTYPES: DISABLE

IxpClient *
ixp_mount(address)
      char *address

IxpClient *
ixp_mountfd(fd)
      int fd

void
ixp_unmount(c)
      IxpClient *c

int
ixp_clientfd(c)
      IxpClient *c
   CODE:
      RETVAL = c->fd;
   OUTPUT:
      RETVAL

IxpCFid *
ixp_create(c, name, perm, mode)
      IxpClient *c
      char *name
      unsigned int perm
      unsigned char mode

IxpCFid *
ixp_open(c, name, mode)
      IxpClient *c
      char *name
      unsigned char mode

int
ixp_remove(c, path)
      IxpClient *c
      char *path

SV *
ixp_stat(c, path)
      IxpClient *c
      char *path
   INIT:
      IxpStat *s;
   CODE:
      s = ixp_stat(c, path);
      if (s == NULL) {
         XSRETURN_UNDEF;
      }
      RETVAL = stat_c2sv(s);
      ixp_freestat(s);
   OUTPUT:
      RETVAL

long
ixp_read(f, buf, count)
      IxpCFid *f
      void *buf
      long count

long
ixp_write(f, buf, count)
      IxpCFid *f
      void *buf
      long count

int
ixp_close(f)
      IxpCFid *f

char *
ixp_errbuf()

IxpMsg *
ixp_message(data, length, mode)
      unsigned char *data
      unsigned int length
      unsigned int mode
   INIT:
      static IxpMsg msg;
   CODE:
      msg = ixp_message(data, length, mode);
      RETVAL = &msg;
   OUTPUT:
      RETVAL

#
# High-level functions
#

SV *
xread(socket, file, fd)
      char *socket
      char *file
      int fd
   INIT:
      IxpClient *client;
      IxpCFid *fid;
      char *buf, *out;
      int read, count, alloc;
   CODE:
      client = ixp_mount(socket);
      if (client == NULL) {
         XSRETURN_UNDEF;
      }
      fid = ixp_open(client, file, P9_OREAD);
      if (fid == NULL) {
         ixp_unmount(client);
         XSRETURN_UNDEF;
      }
      read = 0;
      alloc = fid->iounit;
      out = ixp_emalloc(alloc);
      buf = ixp_emalloc(fid->iounit);
      memset(out, '\0', alloc);
      while ((count = ixp_read(fid, buf, fid->iounit)) > 0) {
         read += count;
         if (fd >= 0) {
            write(fd, buf, count);
         }
         if (read > alloc) {
            alloc += count;
            out = ixp_erealloc(out, alloc);
         }
         strncat(out, buf, count);
      }
      if (count == -1) {
         ixp_unmount(client);
         free(out);
         free(buf);
         free(fid);
         XSRETURN_UNDEF;
      }
      RETVAL = newSVpv(out, 0);
      ixp_unmount(client);
      free(out);
      free(buf);
      free(fid);
   OUTPUT:
      RETVAL

long
xwrite(socket, file, data)
      char *socket
      char *file
      char *data
   INIT:
      IxpClient *client;
      IxpCFid *fid;
      long written;
      size_t len;
   CODE:
      client = ixp_mount(socket);
      if (client == NULL) {
         XSRETURN_UNDEF;
      }
      fid = ixp_open(client, file, P9_OWRITE);
      if (fid == NULL) {
         ixp_unmount(client);
         XSRETURN_UNDEF;
      }
      len = strlen(data);
      if ((written = ixp_write(fid, data, len)) != len) {
         ixp_unmount(client);
         free(fid);
         XSRETURN_UNDEF;
      }
      RETVAL = written;
      ixp_unmount(client);
      free(fid);
   OUTPUT:
      RETVAL

SV *
xls(socket, file)
      char *socket
      char *file
   INIT:
      IxpClient *client = NULL;
      IxpStat *stat = NULL;
      IxpCFid *fid = NULL;
      AV *out = NULL;
      int nstat, mstat, count, i;
      char *buf = NULL;
      IxpMsg m;
   CODE:
      client = ixp_mount(socket);
      if (client == NULL) {
         XSRETURN_UNDEF;
      }
      out = newAV();
      stat = ixp_stat(client, file);
      if (stat == NULL) {
         ixp_unmount(client);
         XSRETURN_UNDEF;
      }

      if ((stat->mode & P9_DMDIR) == 0) {
         av_push(out, stat_c2sv(stat));
         ixp_freestat(stat);
      }
      else {
         ixp_freestat(stat);
         fid = ixp_open(client, file, P9_OREAD);
         if (fid == NULL) {
            ixp_unmount(client);
            XSRETURN_UNDEF;
         }
         nstat = 0;
         mstat = 16;
         stat = ixp_emalloc(sizeof(*stat) * mstat);
         buf = ixp_emalloc(fid->iounit);
         while ((count = ixp_read(fid, buf, fid->iounit)) > 0) {
            m = ixp_message(buf, count, MsgUnpack);
            while (m.pos < m.end) {
               if (nstat == mstat) {
                  mstat <<= 1;
                  stat = ixp_erealloc(stat, sizeof(*stat) * mstat);
               }
               ixp_pstat(&m, &stat[nstat++]);
            }
         }
         for (i=0; i<nstat; i++) {
            av_push(out, stat_c2sv(&stat[i]));
            ixp_freestat(&stat[i]);
         }
         free(stat);
         if (count == -1) {
            ixp_unmount(client);
            free(fid);
            XSRETURN_UNDEF;
         }
      }
      RETVAL = newRV_noinc((SV *)out);
      ixp_unmount(client);
      if (fid != NULL) {
         free(fid);
      }
   OUTPUT:
      RETVAL

long
xcreate(socket, file, data)
      char *socket
      char *file
      char *data
   INIT:
      IxpClient *client;
      IxpCFid *fid;
      long written;
   CODE:
      client = ixp_mount(socket);
      if (client == NULL) {
         XSRETURN_UNDEF;
      }
      fid = ixp_create(client, file, 0777, P9_OWRITE);
      if (fid == NULL) {
         ixp_unmount(client);
         XSRETURN_UNDEF;
      }
      written = 0;
      if ((fid->qid.type & P9_DMDIR) == 0) {
         if ((written = ixp_write(fid, data, strlen(data))) != strlen(data)) {
            ixp_unmount(client);
            free(fid);
            XSRETURN_UNDEF;
         }
      }
      RETVAL = written;
      ixp_unmount(client);
      free(fid);
   OUTPUT:
      RETVAL

long
xremove(socket, file)
      char *socket
      char *file
   INIT:
      IxpClient *client;
   CODE:
      client = ixp_mount(socket);
      if (client == NULL) {
         XSRETURN_UNDEF;
      }
      if (ixp_remove(client, file) == 0) {
         ixp_unmount(client);
         XSRETURN_UNDEF;
      }
      RETVAL = 1;
      ixp_unmount(client);
   OUTPUT:
      RETVAL

int snprint_sockaddr(char *buffer, size_t buflen, struct sockaddr *addr) {
   char tmp[256];
   int port;
   if (addr->sa_family == AF_INET) {
      if (!inet_ntop(addr->sa_family, &((struct sockaddr_in*)addr)->sin_addr, tmp, sizeof(tmp)))
         snprintf(tmp, sizeof(tmp), "(invalid?)");
      port= ntohs(((struct sockaddr_in*)addr)->sin_port);
      return snprintf(buffer, buflen, "inet %s:%d", tmp, port);
   }
#ifdef AF_INET6
   else if (addr->sa_family == AF_INET6) {
      if (!inet_ntop(addr->sa_family, &((struct sockaddr_in6*)addr)->sin6_addr, tmp, sizeof(tmp)))
         snprintf(tmp, sizeof(tmp), "(invalid?)");
      port= ntohs(((struct sockaddr_in6*)addr)->sin6_port);
      return snprintf(buffer, buflen, "inet6 [%s]:%d", tmp, port);
   }
#endif
#ifdef AF_UNIX
   else if (addr->sa_family == AF_UNIX) {
      return snprintf(buffer, buflen, "unix %s", ((struct sockaddr_un*)addr)->sun_path);
   }
#endif
}

int parse_signal(SV *name_sv) {
   char *name;
   if (looks_like_number(name_sv))
      return SvIV(name_sv);
   name= SvPV_nolen(name_sv);
   if (!strcmp(name, "SIGKILL")) return SIGKILL;
   if (!strcmp(name, "SIGTERM")) return SIGTERM;
   if (!strcmp(name, "SIGUSR1")) return SIGUSR1;
   if (!strcmp(name, "SIGUSR2")) return SIGUSR2;
   if (!strcmp(name, "SIGALRM")) return SIGALRM;
   if (!strcmp(name, "SIGABRT")) return SIGABRT;
   if (!strcmp(name, "SIGINT" )) return SIGINT;
   if (!strcmp(name, "SIGHUP" )) return SIGHUP;
   croak("Unimplemented signal name %s", name);
}

int fileno_from_sv(SV *sv) {
   PerlIO *io;
   GV *gv;
   SV *rv;

   if (!SvOK(sv)) // undef
      return -1;

   if (!SvROK(sv)) // scalar, is it only digits?
      return looks_like_number(sv)? SvIV(sv) : -1;

   // is it a globref?
   rv= SvRV(sv);
   if (SvTYPE(rv) == SVt_PVGV) {
      io= IoIFP(GvIOp((GV*) rv));
      return PerlIO_fileno(io);
   }
   
   return -1;
}

int snprint_fd_table(char *buf, size_t sizeof_buf, int max_fd) {
   struct stat statbuf;
   struct sockaddr_storage addr;
   size_t len= 0;
   int i, j, n_closed;

   len= snprintf(buf, sizeof_buf, "File descriptors {\n");
   for (i= 0; i < max_fd; i++) {
      socklen_t addr_len= sizeof(addr);
      char * bufpos= buf + len;
      size_t avail= sizeof_buf > len? sizeof_buf - len : 0;

      if (fstat(i, &statbuf) < 0) {
         // Find the next valid fd
         for (j= i+1; j < max_fd; j++)
            if (fstat(j, &statbuf) == 0)
               break;
         if (j - i >= 2)
            len += snprintf(bufpos, avail, "%4d-%d: (closed)\n", i, j-1);
         else
            len += snprintf(bufpos, avail, "%4d: (closed)\n", i);
         i= j;
      }
      else if (!S_ISSOCK(statbuf.st_mode)) {
         char pathbuf[64];
         char linkbuf[256];
         int got;
         snprintf(pathbuf, sizeof(pathbuf), "/proc/%d/fd/%d", getpid(), i);
         pathbuf[sizeof(pathbuf)-1]= '\0';
         got= readlink(pathbuf, linkbuf, sizeof(linkbuf));
         if (got > 0 && got < sizeof(linkbuf)) {
            linkbuf[got]= '\0';
            len += snprintf(bufpos, avail, "%4d: %s\n", i, linkbuf);
         } else {
            len += snprintf(bufpos, avail, "%4d: (not a socket, no proc/fd?)\n", i);
         }
      }
      else {
         if (getsockname(i, (struct sockaddr*) &addr, &addr_len) < 0) {
            len += snprintf(bufpos, avail, "%4d: (getsockname failed)", i);
         }
         else if (addr.ss_family == AF_INET) {
            char addr_str[INET6_ADDRSTRLEN];
            struct sockaddr_in *sin= (struct sockaddr_in*) &addr;
            inet_ntop(AF_INET, &sin->sin_addr, addr_str, sizeof(addr_str));
            len += snprintf(bufpos, avail, "%4d: inet [%s]:%d", i, addr_str, ntohs(sin->sin_port));
         }
         else if (addr.ss_family == AF_UNIX) {
            struct sockaddr_un *sun= (struct sockaddr_un*) &addr;
            char *p;
            // sanitize socket name, which will be random bytes if anonymous
            for (p= sun->sun_path; *p; p++)
               if (*p <= 0x20 || *p >= 0x7F)
                  *p= '?';
            len += snprintf(bufpos, avail, "%4d: unix [%s]", i, sun->sun_path);
         }
         else {
            len += snprintf(bufpos, avail, "%4d: ? socket family %d", i, addr.ss_family);
         }
         bufpos= buf + len;
         avail= sizeof_buf > len? sizeof_buf - len : 0;

         // Is it connected to anything?
         if (getpeername(i, (struct sockaddr*) &addr, &addr_len) == 0) {
            if (addr.ss_family == AF_INET) {
               char addr_str[INET6_ADDRSTRLEN];
               struct sockaddr_in *sin= (struct sockaddr_in*) &addr;
               inet_ntop(AF_INET, &sin->sin_addr, addr_str, sizeof(addr_str));
               len += snprintf(bufpos, avail, " -> [%s]:%d\n", addr_str, ntohs(sin->sin_port));
            }
            else if (addr.ss_family == AF_UNIX) {
               struct sockaddr_un *sun= (struct sockaddr_un*) &addr;
               char *p;
               // sanitize socket name, which will be random bytes if anonymous
               for (p= sun->sun_path; *p; p++)
                  if (*p <= 0x20 || *p >= 0x7F)
                     *p= '?';
               len += snprintf(bufpos, avail, " -> unix [%s]\n", sun->sun_path);
            }
            else {
               len += snprintf(bufpos, avail, " -> socket family %d\n", addr.ss_family);
            }
         }
         else {
            len++;
            if (avail > 0)
               bufpos[0]= '\n';
         }
      }
   }
   // Did it all fit in the buffer, including NUL terminator?
   if (len + 3 <= sizeof_buf) {
      buf[len++]= '}';
      buf[len++]= '\n';
      buf[len  ]= '\0';
   }
   else { // overwrite last 2 chars to end with newline and NUL
      if (sizeof_buf > 1) buf[sizeof_buf-2]= '\n';
      if (sizeof_buf > 0) buf[sizeof_buf-1]= '\0';
      len= sizeof_buf-1;
   }
   return len;
}

#if 0
// neat idea, but no real need for it right now
int get_fd_table(AV *out, int max_fd) {
   struct stat statbuf;
   size_t len= 0;
   int i, j, k, n_closed;
   pid_t pid= 0;

   for (i= 0; i < max_fd; i++) {
      if (fstat(i, &statbuf) < 0)
         continue;
      else if (!S_ISSOCK(statbuf.st_mode)) {
         char pathbuf[64];
         char linkbuf[256];
         int got;
         if (!pid) pid= getpid();
         
         // Prefer whatever /proc/sel/fd/N says.
         snprintf(pathbuf, sizeof(pathbuf), "/proc/%d/fd/%d", pid, i);
         pathbuf[sizeof(pathbuf)-1]= '\0';
         got= readlink(pathbuf, linkbuf, sizeof(linkbuf));
         if (got > 0 && got <= sizeof(linkbuf)) {
            sv= newSVpvn(linkbuf, got);
         }
         // for systems without /prod/self/fd, give a simple approximation
         else if (S_ISREG(statbuf.st_mode)) {
            sv= newSVpvs("file");
         } else if (S_ISDIR(statbuf.st_mode)) {
            sv= newSVpvs("dir");
         } else if (S_ISCHR(statbuf.st_mode)) {
            sv= newSVpvs("chardevice");
         } else if (S_ISBLK(statbuf.st_mode)) {
            sv= newSVpvs("blockdev");
         } else if (S_ISFIFO(statbuf.st_mode)) {
            sv= newSVpvs("pipe");
         } else {
            sv= newSVpvs("unknown");
         }
      }
      else {
         SV *sname= NULL, *pname= NULL;
         int protocol= -1, family= -1;
         const char *clname;
         struct sockaddr_storage addr;
         socklen_t addr_len= sizeof(addr);
         if (getsockname(i, (struct sockaddr*) &addr, &addr_len) == 0) {
            sname= newSVpvn((char*) &addr, addr_len);
            family= addr.ss_family;
         }

         addr_len= sizeof(addr);
         if (getpeername(i, (struct sockaddr*) &addr, &addr_len) == 0) {
            pname= newSVpvn((char*) &addr, addr_len);
            family= addr.ss_family;
         }

         if (family == -1) {
            int len = sizeof(family);
            if (getsockopt(i, SOL_SOCKET, SO_FAMILY, &family, &len) == -1) {
               perror("getsockopt SO_FAMILY");
               family= -1;
            }
         }

         if (protocol == -1) {
            int len = sizeof(family);
            if (getsockopt(i, SOL_SOCKET, SO_PROTOCOL, &protocol, &len) == -1) {
               perror("getsockopt SO_PROTOCOL");
               protocol= -1;
            }
         }

         if (family == AF_INET) {
            clname= (protocol == SOCK_STREAM)? "IO::SocketAlarm::FdInfo::TCP"
               : (protocol == SOCK_DGRAM)? "IO::SocketAlarm::FdInfo::UDP"
               : "IO::SocketAlarm::FdInfo::INET";
         }
#ifdef AF_INET6
         else if (family == AF_INET6) {
            clname= (protocol == SOCK_STREAM)? "IO::SocketAlarm::FdInfo::TCP6"
               : (protocol == SOCK_DGRAM)? "IO::SocketAlarm::FdInfo::UDP6"
               : "IO::SocketAlarm::FdInfo::INET6";
         }
#endif
#ifdef AF_UNIX
         else if (family == AF_UNIX) {
            clname= (protocol == SOCK_STREAM)? "IO::SocketAlarm::FdInfo::UNIX"
               : (protocol == SOCK_DGRAM)? "IO::SocketAlarm::FdInfo::UNIX_DGRAM"
               : (protocol == SOCK_SEQPACKET)? "IO::SocketAlarm::FdInfo::UNIX_SEQPACKET"
               : "IO::SocketAlarm::FdInfo::UNIX";
         }
#endif
         else clname= "IO::SocketAlarm::FdInfo";
      }
   }
}
#endif

// This loads now_ts with the current clock time if it was not already initialized.
// Use tv_nsec == -1 as an indicator of being uninitialized.
bool lazy_build_now_ts(struct timespec *now_ts) {
   if (now_ts->tv_nsec == -1) {
      if (clock_gettime(CLOCK_MONOTONIC, now_ts) != 0) {
         perror("clock_gettime(CLOCK_MONOTONIC)");
         now_ts->tv_nsec= -1; // ensure remains undefined
         return false; // kind of a serious error... but this runs from the background thread, so can't call 'croak'
      }
   }
   return true;
}

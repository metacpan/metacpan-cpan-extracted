#include <sys/stat.h>
#include <stdlib.h>
#include <string.h>

#if defined(_WIN32) && !defined(__CYGWIN__)
typedef unsigned int uid_t;
typedef unsigned int gid_t;
typedef unsigned int nlink_t;
typedef unsigned int blksize_t;
typedef unsigned int blkcnt_t;
#endif

struct stat *
stat___stat(const char *filename)
{
  struct stat *self;
  self = malloc(sizeof(struct stat));
  if(stat(filename, self) == -1)
  {
    free(self);
    return NULL;
  }
  return self;
}

struct stat *
stat___lstat(const char *filename)
{
  struct stat *self;
  self = malloc(sizeof(struct stat));
#if !defined(_WIN32) || defined(__CYGWIN__)
  if(lstat(filename, self) == -1)
#else
  if(stat(filename, self) == -1)
#endif
  {
    free(self);
    return NULL;
  }
  return self;
}

struct stat *
stat___fstat(int fd)
{
  struct stat *self;
  self = malloc(sizeof(struct stat));
  if(fstat(fd, self) == -1)
  {
    free(self);
    return NULL;
  }
  return self;
}

struct stat *
stat___new(void)
{
  struct stat *self;
  self = malloc(sizeof(struct stat));
  return self;
}

struct stat *
stat__clone(struct stat *other)
{
  struct stat *self;
  self = malloc(sizeof(struct stat));
  if(other == NULL)
  {
    memset(self, 0, sizeof(struct stat));
  }
  else
  {
    memcpy(self, other, sizeof(struct stat));
  }
  return self;
}

dev_t
stat__dev(struct stat *self)
{
  return self->st_dev;
}

ino_t
stat__ino(struct stat *self)
{
  return self->st_ino;
}

mode_t
stat__mode(struct stat *self)
{
  return self->st_mode;
}

nlink_t
stat__nlink(struct stat *self)
{
  return self->st_nlink;
}

uid_t
stat__uid(struct stat *self)
{
  return self->st_uid;
}

gid_t
stat__gid(struct stat *self)
{
  return self->st_gid;
}

dev_t
stat__rdev(struct stat *self)
{
  return self->st_rdev;
}

off_t
stat__size(struct stat *self)
{
  return self->st_size;
}

time_t
stat__atime(struct stat *self)
{
  return self->st_atime;
}

time_t
stat__mtime(struct stat *self)
{
  return self->st_mtime;
}

time_t
stat__ctime(struct stat *self)
{
  return self->st_ctime;
}

#if !defined(_WIN32) || defined(__CYGWIN__)
blksize_t
stat__blksize(struct stat *self)
{
  return self->st_blksize;
}

blkcnt_t
stat__blocks(struct stat *self)
{
  return self->st_blocks;
}
#endif

void
stat__DESTROY(struct stat *self)
{
  free(self);
}

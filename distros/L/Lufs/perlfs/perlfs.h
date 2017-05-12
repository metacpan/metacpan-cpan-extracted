#include <stdlib.h>
#include <dirent.h>
#include <fcntl.h>
#include <stdio.h>
#include <utime.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <lufs/proto.h>
#include <lufs/fs.h>
#include <EXTERN.h>
#ifdef DEBUG
#undef DEBUG
#endif
#include <perl.h>
#include <pthread.h>

#ifdef USE_MUTEX
#define LOCK_MUTEX(c) pthread_mutex_lock(mutex)
#define UNLOCK_MUTEX(c) pthread_mutex_unlock(mutex)
#else
#define LOCK_MUTEX(c)
#define UNLOCK_MUTEX(c)
#endif


struct perlfs_context {
    PerlInterpreter *perl;
    struct dir_cache *cache;
    struct credentials *cred;
    struct list_head *cfg;
	pthread_mutex_t *mutex;
};

static PerlInterpreter *perl; /* just one for now */
static pthread_mutex_t mut;
static pthread_mutex_t *mutex;

char * getarstring(AV *, I32);
void _create_perl(struct perlfs_context*);
void _init_perl(struct perlfs_context*);
void _setup_perl(struct perlfs_context*);
long getlong(HV *, char *);
char * string(HV *, I32);
char * getarstring(AV *, I32);


void* perlfs_init(struct list_head *, struct dir_cache *,struct credentials *, void**);
void* perlfs_free(struct perlfs_context*);
void* perlfs_umount(struct perlfs_context*);

int perlfs_mount(struct perlfs_context*);
int perlfs_readdir(struct perlfs_context*, char*, struct directory*);
int perlfs_stat(struct perlfs_context*, char*, struct lufs_fattr*);
int perlfs_mkdir(struct perlfs_context*, char*, int);
int perlfs_rmdir(struct perlfs_context*, char*);
int perlfs_create(struct perlfs_context*, char*, int);
int perlfs_unlink(struct perlfs_context*, char*);
int perlfs_rename(struct perlfs_context*, char*, char*);
int perlfs_open(struct perlfs_context*, char*, unsigned);
int perlfs_release(struct perlfs_context*, char*);
int perlfs_read(struct perlfs_context*, char*, long long, unsigned long, char*);
int perlfs_write(struct perlfs_context*, char*, long long, unsigned long, char*);
int perlfs_readlink(struct perlfs_context*, char*, char*, int );
int perlfs_link(struct perlfs_context*, char*, char*);
int perlfs_symlink(struct perlfs_context*, char*, char*);
int perlfs_setattr(struct perlfs_context*, char*, struct lufs_fattr*);

void perlfs_touch(struct perlfs_context*, char*);


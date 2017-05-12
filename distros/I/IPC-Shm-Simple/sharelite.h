
/*
 * sharelite.h - part of IPC::Shm::Simple
 *
 * Originally part of IPC::ShareLite by Maurice Aubrey.
 *
 * Adapted 2/2005 by Kevin Cody-Little <kcody@cpan.org>
 *
 * This code may be modified or redistributed under the terms
 * of either the Artistic or GNU General Public licenses, at
 * the modifier or redistributor's discretion.
 *
 */


#ifndef __SHARELITE_H__
#define __SHARELITE_H__

/* Default shared memory segment size.  Each segment is the *
 * same size.  Maximum size is system-dependent (SHMMAX).   *
 * CHANGED 2/2005 by Kevin Cody-Little <kcody@cpan.org>     *
 * seems this should probably track system page size        *
 * also, now chunk segments can be of different size        *
 * SEG_SIZE is the default, applies when size < MIN_SIZE    */
#define SHARELITE_SEG_SIZE 4096
#define SHARELITE_MIN_SIZE  256

/* Magic value for detecting whether sharelite.c created the segment * 
 * ADDED 2/2005 by Kevin Cody-Little <kcody@cpan.org>                */
#define SHARELITE_MAGIC 0x4C524550  /* 'PERL' */

/* Lock constants used internally by us.  They happen to be the same *
 * as for flock(), but that's purely coincidental                    *
 * CHANGED 2/2005 by Kevin Cody-Little <kcody@cpan.org>              *
 * Lock constants are now imported from <sys/file.h>                 *
 * internal implementation doesn't care, but interface standards do  */

/* Structure at the top of every shared memory segment.      *
 * next_shmid is used to construct a linked-list of          *
 * segments.                                                 *
 * REVAMPED 2/7/2005 by Kevin Cody-Little <kcody@cpan.org>   *
 * length and version moved to top segment Descriptor        */
typedef struct {
  unsigned int	 shm_magic;
  int		 next_shmid;
} Header;

/* Structure just under the top of the first segment    *
 * ADDED 2/2005 by Kevin Cody-Little <kcody@cpan.org>   */
typedef struct {
  int		 seg_semid;     /* segment lock semaphore     */
  int		 seg_perms;     /* segment creation flags     */
  int		 data_serial;   /* incremented on write       */
  unsigned int	 data_length;   /* total data in all chunks   */
  unsigned int	 data_chunks;   /* number of chunk segments   */
  unsigned int	 size_topseg;   /* total size of main segment */
  unsigned int	 size_chunkseg; /* total size of appended seg */
  unsigned int	 nrefs;		/* number of references       */
} Descriptor;

/* Structure for the per-process segment list.  This list    *
 * is similar to the shared memory linked-list, but contains *
 * the actual shared memory addresses returned from the      *
 * shmat() calls.  Since the addresses are mapped into each  *
 * process's data segment, we cannot make them global.       *
 * This linked-list may be shorter than the shared memory    *
 * linked-list -- nodes are added on to this list on an      *
 * as-needed basis                                           *
 * REVAMPED 2/2005 by Kevin Cody-Little <kcody@cpan.org>     *
 * NOTE: Might also be -longer- than the shared memory list  */
typedef struct node {
  int		 shmid;		/* doublecheck freshness of this list  */
  char		*shmdata;	/* pointer to shared data storage area */
  Header	*shmhead;	/* pointer to shared segment header    */
  Descriptor	*shminfo;	/* pointer to Descriptor in top shmseg */
  struct node	*next;		/* private memory pointer to next Node */
} Node;

/* The primary structure for this library.  We pass this back *
 * and forth to perl                                          *
 * REVAMPED 2/2005 by Kevin Cody-Little <kcody@cpan.org>      *
 * NOTE, we actually pass the pointer value back and forth    */
typedef struct {
  key_t         key;		/* ipckey requested at instantiation   */
  int           semid;		/* semid of assosciated lock semaphore */
  int           shmid;		/* shmid of top shared memory segment  */
  int           flags;		/* mode and perms set at instantiation */
  int           size_data;	/* available data size in top shmseg   */
  short		remove;		/* boolean, remove segment in shmdt    */
  short         lock;		/* current application lock status     */
  Node         *head;		/* first attached segment pointer      */
  Node         *tail;		/* last attached segment pointer       */
} Share;                

/* prototypes */
/* MOSTLY NEW 2/2005 by Kevin Cody-Little <kcody@cpan.org> */

/* attach to a segment by its shmid */
Share	*sharelite_shmat(int shmid);
/* attach to a segment by its ipckey, if it exists */
Share	*sharelite_attach(key_t key);
/* create a new segment by its ipckey, if one doesn't exist */
Share	*sharelite_create(key_t key, int segsize, int flags);

/* detach from the segment, removing it if requested */
int	 sharelite_shmdt(Share *share);
/* indicates the segment should be removed when all processes have detached */
int	 sharelite_remove(Share *share);

/* change the locking status of the semaphore */
int	 sharelite_lock(Share *share, int flags); 
/* check the locking status of the semaphore */
int	 sharelite_locked(Share *share, int flags);

/* store a block of raw binary data */
int	 sharelite_store(Share *share, char *data, int length);
/* fetch back a block of raw binary data */
int	 sharelite_fetch(Share *share, char **data);

/* NOTE: The key is only unique when it isn't IPC_PRIVATE. *
 * The shmid is always unique.                             */

/* report the ipckey of the top segment */
int      sharelite_key(Share *share);
/* report the shmid of the top segment */
int      sharelite_shmid(Share *share);

/* NOTE: These accessors will only work on valid, i.e. attached segments */

/* report the mode flags used at creation */
int      sharelite_flags(Share *share);
/* report the total bytes currently stored */
int	 sharelite_length(Share *share);
/* report the serial number stored in the top segment Descriptor */
int	 sharelite_serial(Share *share);
/* report the number of shm segments in use by the share */
int	 sharelite_nsegments(Share *share);
/* report the size of the top segment */
int	 sharelite_top_seg_size(Share *share);
/* report the number of active connections */
int	 sharelite_nconns(Share *share);
/* report the number of counted references */
int	 sharelite_nrefs(Share *share);
/* increment the reference counter */
int	 sharelite_incref(Share *share);
/* decrement the reference counter */
int	 sharelite_decref(Share *share);

/* NOTE: The size of the chunk segments can only be set before the     *
 * first chunk segment is created. When there are chunks present, this *
 * function will set errno = EINVAL and return -1. Chunks are removed  *
 * from the system when a write leaves them unused.                    */

/* report or set the size of any subsequent chunk segments */
int	 sharelite_chunk_seg_size(Share *share, int size);

/* NOTE: When a process sets the IPC_RMID flag via sharelite_remove during  *
 * its sharelite_shmdt call, the segment doesn't actually get removed until *
 * all other processes have detached. However, the locking semaphore gets   *
 * removed immediately. Thus, the sharelite_is_valid call is necessary to   *
 * detect when an error is due to another process having removed the share  */

/* report that the segment is still valid (not removed) */
int      sharelite_is_valid(Share *share);

#endif /* define __SHARELITE_H__ */

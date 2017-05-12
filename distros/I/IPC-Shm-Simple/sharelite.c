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

#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include <sys/types.h>
#include <sys/file.h>
#include <sys/ipc.h>
#include <sys/shm.h>

#ifndef errno 
extern int errno;
#endif


#include "sharelite.h"
#include "sharelite_shm.h"
#include "sharelite_sem.h"

#define CALL_NEEDS_SHARE(A)		\
	if ( share == NULL ) {		\
		errno = EINVAL;		\
		return (A);		\
	}

#define CALL_NEEDS_SHARE_AND_HEAD(A)		\
	if (    ( share == NULL )		\
	     || ( share->head == NULL ) ) {	\
		errno = EINVAL;			\
		return (A);			\
	}


/* CREATE / ATTACH SHARED SEGMENT FUNCTIONS */

inline
Share *_sharelite_shmat( key_t key, int shmid ) {
	Share *share;

	/* _sharelite_shm_attach expects a blank share object */
	if ( ( share = (Share *) calloc( 1, sizeof( Share ) ) ) == NULL )
		return NULL;

	/* both are expected; key is used if shmid == -1 */
	share->key   = key;
	share->shmid = shmid;

	/* can't attach to an unknown anonymous segment */
	if ( ( shmid == -1 ) && ( key == IPC_PRIVATE ) ) {
		errno = EINVAL;
		return NULL;
	}

	/* fetching the top node also inits the list pointers in share */
	if ( _sharelite_shm_attach( share ) < 0 ) {
		free( share );
		return NULL;
	}

	/* initialize the process private state variables */
	share->key   = key; /* only to provide a default */
	share->lock  = LOCK_UN;

	share->flags = share->head->shminfo->seg_perms;
	share->semid = share->head->shminfo->seg_semid;

	share->size_data  = share->head->shminfo->size_topseg
                          - ( sizeof( Header ) + sizeof( Descriptor ) );

	return share;
}

Share *sharelite_shmat( int shmid ) {

	return _sharelite_shmat( IPC_PRIVATE, shmid );
}

Share *sharelite_attach( key_t key ) {

	return _sharelite_shmat( key, -1 );
}

Share *sharelite_create( key_t key, int segsize, int flags ) {
	Share *share;
	Node *node;
	int semid;

	/* unsure what the minimum size is, but there -must- be one... */
	if ( segsize < SHARELITE_MIN_SIZE )
		segsize = SHARELITE_SEG_SIZE;

	/* _sharelite_seg_create expects a blank share object */
	if ( ( share = calloc( 1, sizeof( Share ) ) ) == NULL )
		return NULL;

	/* get a new locked semaphore to go with our segment */
	if ( ( semid = _sharelite_sem_create( flags ) ) == -1 ) {
		free( share );
		return NULL;
	}

	/* no error checking - any ipckey is valid, plus IPC_PRIVATE */
	share->key = key;

	/* mask out all but the lower nine bits - permissions */
	share->flags = flags & 0x01FF;

	/* fetching the new top node also inits the list pointers in share */
	if ( _sharelite_shm_create( share, segsize ) < 0 ) {
		_sharelite_sem_remove( semid );
		free( share );
		return NULL;
	}

	node = share->head;

	/* initialize the process private state variables */
	share->lock  = LOCK_EX;
	share->semid = semid;

	/* the existence of this value marks the segment as valid */
	node->shminfo->seg_semid = semid;

	return share;
}


/* DETACH / DESTROY SHARED SEGMENT FUNCTIONS */
#include <stdio.h>
/* ignores error conditions; this would be called by a destructor */
int sharelite_shmdt( Share *share ) {

	CALL_NEEDS_SHARE(-1);

	if ( share->remove ) {
		REQ_EX_LOCK(share);
		_sharelite_sem_remove( share->semid );
		_sharelite_shm_remove( share, NULL );
		/* no END_EX_LOCK; we just removed the semaphore */
	} else {
		if ( share->lock & LOCK_EX )
			REL_EX_LOCK(share);
		if ( share->lock & LOCK_SH )
			REL_SH_LOCK(share);
		_sharelite_shm_forget( share, NULL );
	}

	free( share );

	return 0;
}

/* just sets a flag; removal happens on detach, just like the syscall */
int sharelite_remove( Share *share ) {

	CALL_NEEDS_SHARE(-1);

	share->remove = 1;

	return 0;
}

/* USER INITIATED LOCK */

/* returns  0 on success -- requested operation performed    *
 * returns -1 on error                                       *
 * returns  1 if LOCK_NB specified and operation would block */
int sharelite_lock(Share *share, int flags) {
	int nonblock, lockmode, rc;

	CALL_NEEDS_SHARE(-1);

	/* at this layer we demand an argument */
	if ( ! flags ) {
		errno = EINVAL;
		return -1;
	}

	/* Check for invalid combination of flags.  Invalid combinations *
	 * are attempts to obtain *both* an exclusive and shared lock or *
	 * to both obtain and release a lock at the same time            */ 
	if ( ( ( flags & LOCK_EX ) && ( flags & LOCK_SH ) ) ||
	     ( ( flags & LOCK_UN ) &&
	       ( ( flags & LOCK_SH ) || ( flags & LOCK_EX ) ) ) ) {
		errno = EINVAL;
		return -1;
	}

	nonblock = ( flags & LOCK_NB ) == LOCK_NB;

	lockmode = flags & ~ LOCK_NB;

	/* succeed if we already have the requested lock type */
	if ( share->lock == lockmode )
		return 0;

	/* release a lock; this is simpler logic than asserting one */
	if ( lockmode & LOCK_UN ) {

		if ( share->lock & LOCK_SH )
			rc = REL_SH_LOCK(share);
		else
			rc = REL_EX_LOCK(share);

		if ( rc == 0 )
			share->lock = LOCK_UN;

		return rc;
	}

	/* clear the old incorrect lock if necessary */
	if ( ! ( share->lock & LOCK_UN ) ) {

		rc = 0;

		if ( share->lock & LOCK_SH )
			rc = REL_SH_LOCK(share);
		else
			rc = REL_EX_LOCK(share);

		if ( rc < 0 )
			return -1;

	}

	/* set the new lock */
	if ( lockmode & LOCK_EX ) {

		rc = nonblock
			? GET_EX_LOCK_NB(share)
			: GET_EX_LOCK(share);

	} else if ( lockmode & LOCK_SH ) {

		rc = nonblock
			? GET_SH_LOCK_NB(share)
			: GET_SH_LOCK(share);

	} else {

		errno = EINVAL;
		rc = -1;

	}

	if ( nonblock && ( rc < 0 ) && ( errno == EAGAIN ) )
		return 1;

	if ( rc == 0 )
		share->lock = lockmode;

	return rc;
}


int sharelite_locked( Share *share, int flags ) {

	CALL_NEEDS_SHARE(-1);

	return share->lock == flags;
}


/* SHARELITE INPUT-OUTPUT FUNCTIONS */

int sharelite_store( Share *share, char *data, int length ) {
	char *srcaddr;
	char *dstaddr;
	Node *node;
	int left, size, chunk;

	CALL_NEEDS_SHARE_AND_HEAD(-1);

	REQ_EX_LOCK(share);

	node   = share->head;

	/* set to zero so if the write bombs, we don't get corrupt data */
	node->shminfo->data_length = 0;

	/* fetch the first and subsequent chunk sizes */
	size    = share->size_data;
	chunk   = node->shminfo->size_chunkseg - sizeof( Header );

	/* initialize the copy pointers */
	dstaddr = node->shmdata;
	srcaddr = data;

	/* decide if the data will fit in the top segment */
	if ( length < size ) {
		size = length;
		left = 0;
	} else
		left = length - size;

	/* copy data to top segment */
	if ( memcpy( dstaddr, srcaddr, size ) == NULL ) {
		END_EX_LOCK(share);
		return -1;
	}

	/* copy any chunks to their own segments */
	while ( left ) {

		/* catches other processes freeing shared segments */
		if ( node->next != NULL ) 
			if ( node->next->shmid != node->shmhead->next_shmid )
				if ( _sharelite_shm_forget( share, node ) == -1 ) {
					END_EX_LOCK(share);
					return -1;
				}

		/* catches running into the end of the attached segments */
		if ( node->next == NULL )
			if ( _sharelite_shm_append( share ) == -1 ) {
				END_EX_LOCK(share);
				return -1;
			}

		/* advance the pointers */
		node     = node->next;
		dstaddr  = node->shmdata;
		srcaddr += size;
		size     = ( left > chunk ) ? chunk : left;

		/* copy a chunk to its segment */
		if ( memcpy( dstaddr, srcaddr, size ) == NULL ) {
			END_EX_LOCK(share);
			return -1;
		}

		/* adjust remaining data size */
		left -= size;

	}

	/* deallocate unneeded chunk segments */
	_sharelite_shm_remove( share, node );

	/* increment serial and save length */
	node->shminfo->data_serial++;
	node->shminfo->data_length = length;

	END_EX_LOCK(share);

	return 0;
}

int sharelite_fetch( Share *share, char **data ) {
	char *srcaddr;
	char *dstaddr;
	Node *node;
	int length, left, size, chunk;

	CALL_NEEDS_SHARE_AND_HEAD(-1);

	node   = share->head;
	length = node->shminfo->data_length;

	if ( ( *data = dstaddr = (char *) malloc( length ) ) == NULL )
		return -1;

	REQ_SH_LOCK(share);

	size    = share->size_data;
	chunk   = node->shminfo->size_chunkseg - sizeof( Header );
	srcaddr = node->shmdata;

	if ( length < size ) {
		size = length;
		left = 0;
	} else
		left = length - size;

	if ( memcpy( dstaddr, srcaddr, size ) == NULL ) {
		END_SH_LOCK(share);
		return -1;
	}

	while ( left ) {

		if ( node->next != NULL ) 
			if ( node->next->shmid != node->shmhead->next_shmid )
				if ( _sharelite_shm_forget( share, node ) == -1 ) {
					END_SH_LOCK(share);
					return -1;
				}

		if ( node->next == NULL )
			if ( _sharelite_shm_append( share ) == -1 ) {
				END_SH_LOCK(share);
				return -1;
			}

		node     = node->next;
		srcaddr  = node->shmdata;
		dstaddr += size;
		size     = ( left > chunk ) ? chunk : left;

		if ( memcpy( dstaddr, srcaddr, size ) == NULL ) {
			END_SH_LOCK(share);
			return -1;
		}

		left -= size;

	}

	END_SH_LOCK(share);

	return length;
}


/* SHARELITE OBJECT ACCESSOR FUNCTIONS */

int sharelite_key( Share *share ) {

	CALL_NEEDS_SHARE(-1);

	return share->key;
}

int sharelite_shmid( Share *share ) {

	CALL_NEEDS_SHARE(-1);

	return share->shmid;
}

int sharelite_flags( Share *share ) {

	CALL_NEEDS_SHARE(-1);

	return share->flags;
}

int sharelite_length( Share *share ) {

	CALL_NEEDS_SHARE_AND_HEAD(-1);

	return share->head->shminfo->data_length;
}

int sharelite_serial( Share *share ) {

	CALL_NEEDS_SHARE_AND_HEAD(-1);

	return share->head->shminfo->data_serial;
}

int sharelite_nsegments( Share *share ) {

	CALL_NEEDS_SHARE_AND_HEAD(-1);

	return share->head->shminfo->data_chunks + 1;
}

int sharelite_top_seg_size( Share *share ) {

	CALL_NEEDS_SHARE_AND_HEAD(-1);

	return share->head->shminfo->size_topseg;
}

int sharelite_chunk_seg_size( Share *share, int segsize ) {

	CALL_NEEDS_SHARE_AND_HEAD(-1);

	if ( segsize > 0 ) {
		/* trying to set a new segment size */

		REQ_EX_LOCK(share);

		if ( share->head->shminfo->data_length > share->size_data ) {
			/* there are chunk segments defined already */
			END_EX_LOCK(share);
			errno = EINVAL;
			return -1;
		}

		share->head->shminfo->size_chunkseg = segsize;

		END_EX_LOCK(share);

	}

	return share->head->shminfo->size_chunkseg;
}

int sharelite_nconns( Share *share ) {

	CALL_NEEDS_SHARE_AND_HEAD(-1);

	return _sharelite_shm_nconns( share );
}

int sharelite_nrefs( Share *share ) {

	CALL_NEEDS_SHARE_AND_HEAD(-1);

	return share->head->shminfo->nrefs;
}

int sharelite_incref( Share *share ) {

	CALL_NEEDS_SHARE_AND_HEAD(-1);

	REQ_EX_LOCK(share);
	share->head->shminfo->nrefs++;
	END_EX_LOCK(share);

	return share->head->shminfo->nrefs;
}

int sharelite_decref( Share *share ) {

	CALL_NEEDS_SHARE_AND_HEAD(-1);

	REQ_EX_LOCK(share);
	share->head->shminfo->nrefs--;
	END_EX_LOCK(share);

	return share->head->shminfo->nrefs;
}

int sharelite_is_valid( Share *share ) {

	CALL_NEEDS_SHARE(-1);

	return _sharelite_sem_access( share->semid ) == 0;
}


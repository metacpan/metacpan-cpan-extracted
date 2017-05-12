
/*
 * sharelite_shm.c - part of IPC::Shm::Simple
 *
 * Derived from parts of IPC::ShareLite by Maurice Aubrey.
 *
 * Copyright (c) 2/2005 by Kevin Cody-Little <kcody@cpan.org>
 *
 * This code may be modified or redistributed under the terms
 * of either the Artistic or GNU General Public licenses, at
 * the modifier or redistributor's discretion.
 *
 */

#include <stdlib.h>
#include <errno.h>

#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/shm.h>

#include "sharelite.h"
#include "sharelite_shm.h"

/* --- SHARED SEGMENT NODE FUNCTIONS --- */

/* shmat to an existing segment shmid and return a valid Node structure */
Node *_shmseg_shmat( int shmid ) {
	char *shmaddr;
	Node *node;

	if ( ( shmaddr = shmat( shmid, (char *) NULL, 0 ) ) == (void *) -1 )
		return NULL;

	if ( ( node = malloc( sizeof( Node ) ) ) == NULL ) {
		shmid = errno;
		shmdt( shmaddr );
		errno = shmid; /* does malloc define this? */
		return NULL;
	}

	node->shmid   = shmid;
	node->shmhead = (Header *) shmaddr;
	node->shmdata = shmaddr + sizeof( Header );

	node->next    = NULL;
	node->shminfo = NULL;

	return node;
}

/* shmdt from a segment and free its Node structure, possibly remove segment */
int _shmseg_shmdt( Node *node, int remove ) {

	if ( remove ) {

		node->shminfo->data_chunks--;

		if ( shmctl( node->shmid, IPC_RMID, NULL ) == -1 )
			if ( shmctl( node->shmid, IPC_RMID, NULL ) == -1 )
				return -1;

	}

	if ( shmdt( node->shmhead ) == -1 )
		return -1;

	free( node );

	return 0;
}

/* allocate and zero a new segment and return a valid Node structure */
Node *_shmseg_alloc( key_t key, int size, int flags, int is_top_node ) {
	Node *node;
	int myflags, shmid;

	flags   = flags & 0x01FF; /* only want lower nine bits - perms */
	myflags = flags | IPC_CREAT | IPC_EXCL;

	if ( ( shmid = shmget( key, size, myflags ) ) == -1 )
		return NULL;

	if ( ( node = _shmseg_shmat( shmid ) ) == NULL ) {
		shmctl( shmid, IPC_RMID, NULL );
		return NULL;
	}

	node->shmhead->shm_magic  = SHARELITE_MAGIC;
	node->shmhead->next_shmid = -1;

	/* FIXME: fetch actual size via shmctl */

	if ( is_top_node ) {

		node->shminfo  = (Descriptor *) node->shmdata;
		node->shmdata += sizeof( Descriptor );

		node->shminfo->seg_perms     = flags;
		node->shminfo->size_topseg   = size;
		node->shminfo->size_chunkseg = size;

		node->shminfo->seg_semid     = -1;
		node->shminfo->data_chunks   = 0;
		node->shminfo->data_serial   = 1;
		node->shminfo->data_length   = 0;
		node->shminfo->nrefs         = 0;

		if ( key != IPC_PRIVATE )
			node->shminfo->nrefs = 1;

	}

	return node;
}


/* --- SHARED SEGMENT LIST FUNCTIONS --- */

/* attach to an existing top segment given a shmid or ipckey */
int _sharelite_shm_attach( Share *share ) {
	Node *node;
	int shmid;

	if ( ( shmid = share->shmid ) == -1 ) {

		if ( ( shmid = shmget( share->key, 0, 0 ) ) == -1 )
			return -1;

		share->shmid = shmid;

	}

	if ( ( node = _shmseg_shmat( shmid ) ) == NULL )
		return -1;

	/* the shmid doesn't point to a sharelite segment */
	if ( node->shmhead->shm_magic != SHARELITE_MAGIC ) {
		_shmseg_shmdt( node, 0 );
		errno = EFAULT;
		return -1;
	}

	node->shminfo  = (Descriptor *) node->shmdata;
	node->shmdata += sizeof( Descriptor );

	share->head = share->tail = node;

	return 0;
}

/* create a new top segment given an ipckey (possibly IPC_PRIVATE) */
int _sharelite_shm_create( Share *share, int size ) {
	Node *node;
	int flags;

	flags = share->flags;

	if ( ( node = _shmseg_alloc( share->key, size, flags, 1 ) ) == NULL )
		return -1;

	share->shmid      = node->shmid;
	share->size_data  = node->shminfo->size_topseg 
				- ( sizeof( Header ) + sizeof( Descriptor ) );

	share->head = share->tail = node;

	return 0;
}

/* attach the next segment, creating one if necessary */
int _sharelite_shm_append( Share *share ) {
	Node *node;
	int shmid;

	if ( ( shmid = share->tail->shmhead->next_shmid ) != -1 ) {
		/* attach an existing linked segment */

		if ( ( node = _shmseg_shmat( shmid ) ) == NULL )
			return -1;

		/* the shmid doesn't point to a sharelite segment */
		if ( node->shmhead->shm_magic != SHARELITE_MAGIC ) {
			_shmseg_shmdt( node, 0 );
			errno = EFAULT;
			return -1;
		}

		share->tail->next = node;
		share->tail       = node;

	} else {
		/* create a new linked segment */
		int key, size, mode;

		key  = IPC_PRIVATE;
		size = share->head->shminfo->size_chunkseg;
		mode = share->head->shminfo->seg_perms;

		if ( ( node = _shmseg_alloc( key, size, mode, 0 ) ) == NULL )
			return -1;

		/* update shared linked list */
		share->tail->shmhead->next_shmid = node->shmid;

		/* update process private linked list */
		share->tail->next = node;
		share->tail       = node;

	}

	node->shminfo = share->head->shminfo;
	node->shminfo->data_chunks++;

	return 0;
}


#define _SHMSEG_TRUNC_SETUP_MACRO_	\
	if ( last == NULL ) {		\
		node = share->head;	\
		share->head = NULL;	\
		share->tail = NULL;	\
	} else {			\
		node = last->next;	\
		last->next = NULL;	\
		share->tail = last;	\
	}

/* nondestructively free stale Node structures   */
int _sharelite_shm_forget( Share *share, Node *last ) {
	Node *node, *next;

	if ( share->tail == last )
		return 0;

	_SHMSEG_TRUNC_SETUP_MACRO_

	while ( node != NULL ) {
		next = node->next;
		if ( _shmseg_shmdt( node, 0 ) == -1 )
			return -1;
		node = next;
	}

	return 0;
}

/* remove unneeded segments from the system         */
int _sharelite_shm_remove( Share *share, Node *last ) {
	Node *node, *next;

	_SHMSEG_TRUNC_SETUP_MACRO_

	if ( last != NULL )
		last->shmhead->next_shmid = -1;

	while ( node != NULL ) {
		next = node->next;
		if ( _shmseg_shmdt( node, 1 ) == -1 )
			return -1;
		node = next;
	}

	return 0;
}

/* get the number of active connections             */
int _sharelite_shm_nconns( Share *share ) {
	struct shmid_ds buf;

	if ( shmctl( share->shmid, IPC_STAT, &buf ) == -1 )
		return -1;

	return (int) buf.shm_nattch;
}



/*
 * sharelite_shm.h - part of IPC::Shm::Simple
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


#ifndef __SHARELITE_SHM_H__
#define __SHARELITE_SHM_H__

#include "sharelite.h"


/* --- SHARED SEGMENT LIST FUNCTIONS --- */

/* TODO: document which share-> fields are read as arguments */

/* attach to an existing key or shmid and init it     */
int _sharelite_shm_attach( Share *share );

/* create a new shmid and initialize it, expects key  */
int _sharelite_shm_create( Share *share, int size );

/* attach the next segment, creating one if necessary *
 * called when the Node list is too short             */
int _sharelite_shm_append( Share *share );

/* nondestructively free stale Node structures  *
 * called when another process removed segments *
 * or when the whole share is being detached    */
int _sharelite_shm_forget( Share *share, Node *last );

/* remove unneeded segments from the system            *
 * called when a write operation leaves extra segments *
 * or when the whole share is being deallocated        */
int _sharelite_shm_remove( Share *share, Node *last );

/* retrieve the number of active connections           *
 * implemented using the shmctl call                   */
int _sharelite_shm_nconns( Share *share );


#endif /* define __SHARELITE_SHM_H__ */


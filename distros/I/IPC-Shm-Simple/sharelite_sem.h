
/*
 * sharelite_sem.h - part of IPC::Shm::Simple
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


#ifndef __SHARELITE_SEM_H__
#define __SHARELITE_SEM_H__

#include <stdlib.h>
#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/sem.h>
#include <errno.h>


/* --- DEFINE MACROS FOR SEMAPHORE OPERATIONS --- *
 *   assumes called with Share from sharelite.h   */

/* Next six macros are raw semaphore set/release lock commands */

#define GET_EX_LOCK(A)     semop((A)->semid, &ex_lock[0],    3)
#define GET_EX_LOCK_NB(A)  semop((A)->semid, &ex_lock_nb[0], 3)
#define REL_EX_LOCK(A)     semop((A)->semid, &ex_unlock[0],  1)
#define GET_SH_LOCK(A)     semop((A)->semid, &sh_lock[0],    2)
#define GET_SH_LOCK_NB(A)  semop((A)->semid, &sh_lock_nb[0], 2)
#define REL_SH_LOCK(A)     semop((A)->semid, &sh_unlock[0],  1) 

/* Next two macros indicate the enclosed block requires an exclusive lock */

#define REQ_EX_LOCK(A)						\
		if ( ! ( (A)->lock & LOCK_EX ) ) {		\
			if ( (A)->lock & LOCK_SH )		\
				if ( REL_SH_LOCK((A)) < 0 )	\
					return -1;		\
			if ( GET_EX_LOCK((A)) < 0 )		\
				return -1;			\
		}

#define END_EX_LOCK(A)						\
		if ( ! ( (A)->lock & LOCK_EX ) ) {		\
			if ( REL_EX_LOCK((A)) < 0 )		\
				return -1;			\
			if ( (A)->lock & LOCK_SH )		\
				if ( GET_SH_LOCK((A)) < 0 )	\
					return -1;		\
		}

/* Next two macros indicate the enclosed block requires a shared lock */

#define REQ_SH_LOCK(A)						\
		if ( (A)->lock & LOCK_UN ) 	 		\
			if ( GET_SH_LOCK((A)) < 0 )		\
				return -1;

#define END_SH_LOCK(A)						\
		if ( (A)->lock & LOCK_UN )			\
			if ( REL_SH_LOCK((A)) < 0 )		\
				return -1;


/* --- DEFINE STRUCTURES FOR MANIPULATING SEMAPHORES --- */

static struct sembuf ex_lock[3] = {
  { 0, 0, 0 },				/* wait for readers to finish */
  { 1, 0, 0 },				/* wait for writers to finish */
  { 1, 1, SEM_UNDO }			/* assert write lock */
};

static struct sembuf ex_lock_nb[3] = {
  { 0, 0, IPC_NOWAIT },			/* wait for readers to finish */
  { 1, 0, IPC_NOWAIT },			/* wait for writers to finish */
  { 1, 1, (SEM_UNDO | IPC_NOWAIT) }	/* assert write lock */     
};

static struct sembuf ex_unlock[1] = {
  { 1, -1, (SEM_UNDO | IPC_NOWAIT) }	/* remove write lock */
};

static struct sembuf sh_lock[2] = {
  { 1, 0, 0 },				/* wait for writers to finish */
  { 0, 1, SEM_UNDO }			/* assert shared read lock */
};

static struct sembuf sh_lock_nb[2] = {
  { 1, 0, IPC_NOWAIT },			/* wait for writers to finish */
  { 0, 1, (SEM_UNDO | IPC_NOWAIT) }	/* assert shared read lock */
};                
static struct sembuf sh_unlock[1] = {
  { 0, -1, (SEM_UNDO | IPC_NOWAIT) }	/* remove shared read lock */
};                                 


/* --- SEMAPHORE CREATE/REMOVE FUNCTIONS --- */

/* create and exclusively lock a new semaphore, and return its semid */
inline
int _sharelite_sem_create( int flags ) {
	int semid;

	semid = semget( IPC_PRIVATE, 2, flags | IPC_CREAT | IPC_EXCL);

	if ( semid == -1 )
		return -1;

	if ( semop( semid, &ex_lock[0], 3 ) == -1 ) {
		semctl( semid, 0, IPC_RMID );
		return -1;
	}

	return semid;
}

/* remove a semaphore from the system, any further ops to return -EIDRM */
inline
int _sharelite_sem_remove( int semid ) {

	if ( semctl( semid, 0, IPC_RMID ) == -1 )
		return -1;

	return 0;
}

/* access the semaphore somehow to see that it still exists */
inline
int _sharelite_sem_access( int semid ) {

	if ( semctl( semid, 0, GETPID ) == -1 )
		return -1;

	return 0;
}


#endif /* define __SHARELITE_SEM_H__ */


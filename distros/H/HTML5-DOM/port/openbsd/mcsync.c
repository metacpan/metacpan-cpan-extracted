/*
	Simulates mutex using semaphore
	Because MyHTML call phtread_mutex_unlock without before call phtread_mutex_lock
	And it crashes on OpenBSD
*/

#include "mycore/utils/mcsync.h"

#ifndef MyCORE_BUILD_WITHOUT_THREADS
#include <pthread.h>
#include <semaphore.h>

#if ((defined(__GNUC__) && __GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 7)) || defined(__ATOMIC_SEQ_CST))
#define MyCORE_MCSYNC_SPINLOCK_PRESENT
#endif

#ifdef MyCORE_MCSYNC_SPINLOCK_PRESENT
static mcsync_status_t mcsync_static_atomic_lock(void *spinlock) {
	int compare = 0;
	while (!__atomic_compare_exchange_n((int *)spinlock, &compare, 1, 0, __ATOMIC_SEQ_CST, __ATOMIC_SEQ_CST)) {}
	return MCSYNC_STATUS_OK;
}

static mcsync_status_t mcsync_static_atomic_unlock(void *spinlock) {
	__atomic_store_n((int*)spinlock, 0, __ATOMIC_SEQ_CST);
	return MCSYNC_STATUS_OK;
}
#endif /* MyCORE_MCSYNC_SPINLOCK_PRESENT */

/* spinlock */
void * mcsync_spin_create(void) {
#ifndef MyCORE_MCSYNC_SPINLOCK_PRESENT
	return mcsync_mutex_create();
#else
	return mycore_calloc(1, sizeof(int));
#endif
}

mcsync_status_t mcsync_spin_init(void *spinlock) {
#ifndef MyCORE_MCSYNC_SPINLOCK_PRESENT
	return mcsync_mutex_init(spinlock);
#else
	return MCSYNC_STATUS_OK;
#endif
}

void mcsync_spin_clean(void *spinlock) {
#ifdef MyCORE_MCSYNC_SPINLOCK_PRESENT
	*((int*)spinlock) = 0;
#endif
}

void mcsync_spin_destroy(void *spinlock) {
#ifdef MyCORE_MCSYNC_SPINLOCK_PRESENT
	mycore_free(spinlock);
#else
	mcsync_mutex_destroy(spinlock);
#endif
}

mcsync_status_t mcsync_spin_lock(void *spinlock) {
#ifdef MyCORE_MCSYNC_SPINLOCK_PRESENT
	return mcsync_static_atomic_lock(spinlock);
#else
	return mcsync_mutex_lock(spinlock);
#endif
}

mcsync_status_t mcsync_spin_unlock(void *spinlock) {
#ifdef MyCORE_MCSYNC_SPINLOCK_PRESENT
	return mcsync_static_atomic_unlock(spinlock);
#else
	return mcsync_mutex_unlock(spinlock);
#endif
}

/* fake "mutex" using semaphore */
void * mcsync_mutex_create(void) {
	void *mutex = mycore_calloc(1, sizeof(sem_t));
	if (mutex == NULL)
		return NULL;
	return (void *) mutex;
}
								   
mcsync_status_t mcsync_mutex_init(void *mutex) {
	if (sem_init(mutex, 0, 1))
		return MCSYNC_STATUS_NOT_OK;
	return MCSYNC_STATUS_OK;
}

void mcsync_mutex_clean(void *mutex) {
	/* clean function */
}

void mcsync_mutex_destroy(void *mutex) {
	sem_destroy(mutex);
	mycore_free(mutex);
}

mcsync_status_t mcsync_mutex_lock(void *mutex) {
	if (sem_wait(mutex) == 0)
		return MCSYNC_STATUS_OK;
	return MCSYNC_STATUS_NOT_OK;
}
								   
mcsync_status_t mcsync_mutex_try_lock(void *mutex) {
	if (sem_trywait(mutex) == 0)
		return MCSYNC_STATUS_OK;
	return MCSYNC_STATUS_NOT_OK;
}

mcsync_status_t mcsync_mutex_unlock(void *mutex) {
	if (sem_post(mutex) == 0)
		return MCSYNC_STATUS_OK;
	return MCSYNC_STATUS_NOT_OK;
}

#endif

/*
 * sample_hashtable.h — A toy hash table for testing indentation
 */

#ifndef SAMPLE_HASHTABLE_H
#define SAMPLE_HASHTABLE_H

#include <stdlib.h>
#include <string.h>

#define HT_INITIAL_CAP 16
#define HT_LOAD_FACTOR 0.75

typedef struct ht_entry {
	char *key;
	void *value;
	struct ht_entry *next;
} ht_entry_t;

typedef struct {
	ht_entry_t **buckets;
	size_t capacity;
	size_t size;
} hashtable_t;

static unsigned long ht_hash(const char *str) {
	unsigned long hash = 5381;
	int c;
	while ((c = *str++))
		hash = ((hash << 5) + hash) + c;
	return hash;
}

static hashtable_t *ht_create(void) {
	hashtable_t *ht = (hashtable_t *)malloc(sizeof(hashtable_t));
	if (!ht) return NULL;
	ht->capacity = HT_INITIAL_CAP;
	ht->size = 0;
	ht->buckets = (ht_entry_t **)calloc(ht->capacity, sizeof(ht_entry_t *));
	if (!ht->buckets) {
		free(ht);
		return NULL;
	}
	return ht;
}

static void *ht_get(hashtable_t *ht, const char *key) {
	unsigned long idx = ht_hash(key) % ht->capacity;
	ht_entry_t *e = ht->buckets[idx];
	while (e) {
		if (strcmp(e->key, key) == 0)
			return e->value;
		e = e->next;
	}
	return NULL;
}

static int ht_set(hashtable_t *ht, const char *key, void *value) {
	unsigned long idx = ht_hash(key) % ht->capacity;
	ht_entry_t *e = ht->buckets[idx];

	/* Update existing */
	while (e) {
		if (strcmp(e->key, key) == 0) {
			e->value = value;
			return 0;
		}
		e = e->next;
	}

	/* Insert new */
	ht_entry_t *ne = (ht_entry_t *)malloc(sizeof(ht_entry_t));
	if (!ne) return -1;
	ne->key = strdup(key);
	ne->value = value;
	ne->next = ht->buckets[idx];
	ht->buckets[idx] = ne;
	ht->size++;
	return 0;
}

static void ht_free(hashtable_t *ht) {
	size_t i;
	for (i = 0; i < ht->capacity; i++) {
		ht_entry_t *e = ht->buckets[i];
		while (e) {
			ht_entry_t *next = e->next;
			free(e->key);
			free(e);
			e = next;
		}
	}
	free(ht->buckets);
	free(ht);
}

/* Conditional compilation for thread safety */
#ifdef HT_THREADSAFE
#include <pthread.h>

typedef struct {
	hashtable_t *ht;
	pthread_mutex_t lock;
} safe_hashtable_t;

static safe_hashtable_t *safe_ht_create(void) {
	safe_hashtable_t *sht = (safe_hashtable_t *)malloc(sizeof(safe_hashtable_t));
	if (!sht) return NULL;
	sht->ht = ht_create();
	if (!sht->ht) {
		free(sht);
		return NULL;
	}
	pthread_mutex_init(&sht->lock, NULL);
	return sht;
}
#endif /* HT_THREADSAFE */

#endif /* SAMPLE_HASHTABLE_H */

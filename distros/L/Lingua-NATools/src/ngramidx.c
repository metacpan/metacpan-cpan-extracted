/* -*- Mode: C; c-file-style: "stroustrup" -*- */

/* NATools - Package with parallel corpora tools
 * Copyright (C) 2002-2012  Alberto Simões
 *
 * This package is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

#include "ngramidx.h"
#include <sys/types.h>
#include <sys/stat.h>

#define CACHE_SIZE 100000

static int file_exists(const char* filename) {
    struct stat sb;
    int rc = stat(filename, &sb);

    if (rc == 0) {
        if (S_ISREG(sb.st_mode))
            return 1;
        else
            return 0;
    } else
        return 0;
}

static void ngramidx_sqlite3_pragmas(sqlite3* dbh) {
    sqlite3_exec(dbh, "PRAGMA page_size = 4096;",     NULL, NULL, NULL);
    sqlite3_exec(dbh, "PRAGMA temp_store = MEMORY;",  NULL, NULL, NULL);
    sqlite3_exec(dbh, "PRAGMA cache_size = 1000000;", NULL, NULL, NULL);
    sqlite3_exec(dbh, "PRAGMA synchronous = OFF;",    NULL, NULL, NULL);
    sqlite3_exec(dbh, "PRAGMA count_changes = 0;",    NULL, NULL, NULL);
}

/**
 * @brief Create a new SQLite database for ngrams
 *
 * This function checks if a SQLite database exists. If it does, it is
 * opened. If not it is created.
 *
 * @param filename name for the SQLite file
 * @param n number of ngrams of the database (2,3,4 or -1 for all)
 * @return the new SQLite object
 */
SQLite* ngram_index_new(const char* filename, int n) { 
    SQLite* res;
    char *errmsg = NULL;
    int rc;

    if (n!=-1 && n!=2 && n!=3 && n!=4)  return NULL;

    res = (SQLite *) malloc(sizeof(SQLite));
    res -> n = n;

    if (file_exists(filename)) {

	rc = sqlite3_open(filename, &(res->dbh));
	if( rc ){
	    fprintf(stderr, "Can't open database: %s\n", sqlite3_errmsg(res->dbh));
	    sqlite3_close(res->dbh);
            free(res);
	    exit(1);
	}

        ngramidx_sqlite3_pragmas(res->dbh);

    } else {

	rc = sqlite3_open(filename, &(res->dbh));
	if( rc ){
	    fprintf(stderr, "Can't open database: %s\n", sqlite3_errmsg(res->dbh));
	    sqlite3_close(res->dbh);
            free(res);
	    exit(1);
	}

        ngramidx_sqlite3_pragmas(res->dbh);
        if (n == 2 || n == -1) {
            rc = sqlite3_exec(
                res->dbh,
                "CREATE TABLE bigrams (word1 INTEGER, word2 INTEGER, "
                "occs INTEGER, PRIMARY KEY (word1, word2))",
                NULL, NULL, &errmsg);
            if (rc != SQLITE_OK) {
                fprintf(stderr, "Error creating table: %s\n", errmsg);
                sqlite3_free(errmsg);
                sqlite3_close(res->dbh);
                free(res);
                exit(1);
            }
        }

        if (n == 3 || n == -1) {
            rc = sqlite3_exec(
                res->dbh,
                "CREATE TABLE trigrams (word1 INTEGER, word2 INTEGER, "
                "word3 INTEGER, "
                "occs INTEGER, PRIMARY KEY (word1, word2, word3))",
                NULL, NULL, &errmsg);
	
            if (rc != SQLITE_OK) {
                fprintf(stderr, "Error creating table: %s\n", errmsg);
                sqlite3_free(errmsg);
                sqlite3_close(res->dbh);
                free(res);
                exit(1);
            }
        }

        if (n == 4 || n == -1) {
            rc = sqlite3_exec(
                res->dbh,
                "CREATE TABLE tetragrams (word1 INTEGER, word2 INTEGER, "
                "word3 INTEGER, word4 INTEGER, "
                "occs INTEGER, PRIMARY KEY (word1, word2, word3, word4))",
                NULL, NULL, &errmsg);
	
            if (rc != SQLITE_OK) {
                fprintf(stderr, "Error creating table: %s\n", errmsg);
                sqlite3_free(errmsg);
                sqlite3_close(res->dbh);
                free(res);
                exit(1);
            }
        }
    }

    sqlite3_exec(res->dbh, "BEGIN", NULL, NULL, NULL);

    /* Let's initialize our beloved cache :D */
    if (n==2 || n==-1) 
        res->bigram_cache    = g_hash_table_new(g_str_hash, g_str_equal); 
    if (n==3 || n==-1)
        res->trigram_cache   = g_hash_table_new(g_str_hash, g_str_equal);
    if (n==4 || n==-1)
        res->tetragram_cache = g_hash_table_new(g_str_hash, g_str_equal);

    return res;
} 



SQLite* ngram_index_open_and_attach(const char* template) {
    SQLite* db = NULL;
    char *temp_file = NULL;
    char *temp_command = NULL;
    int n;

    for (n=2; n<=4; ++n) {
    	temp_file = g_strdup_printf(template, n);
    	if (!db) {
    	    db = ngram_index_open(temp_file, n);
    	    g_free(temp_file);
    	    if (!db) return NULL;
    	} else {
    	    if (n==3) {
    		    temp_command = g_strdup_printf("ATTACH \"%s\" as trigrams;", temp_file);
    	    } else if (n==4) {
    		    temp_command = g_strdup_printf("ATTACH \"%s\" as tetragrams;", temp_file);
    	    }
    	    sqlite3_exec(db->dbh, temp_command, NULL, NULL, NULL);
    	    g_free(temp_command);	    
    	    g_free(temp_file);	    
    	}
    }
    db -> n = -1;
    return db;
}

SQLite* ngram_index_open(const char* filename, int n) { 
    SQLite *res;
    int rc;

    if (n!=-1 && n!=2 && n!=3 && n!=4)  return NULL;

    res = (SQLite*) malloc(sizeof(SQLite));
    res -> n = n;

    rc = sqlite3_open(filename, &(res->dbh));
    if( rc ){
	fprintf(stderr, "Can't open database: %s\n", sqlite3_errmsg(res->dbh));
	sqlite3_close(res->dbh);
	free(res);
	return NULL;
    }

    ngramidx_sqlite3_pragmas(res->dbh);
    return res;
 } 


void ngram_index_close(SQLite *sqstruct) { 
    sqlite3 *db = sqstruct->dbh;
    int       n = sqstruct->n;
    sqlite3_exec(db, "BEGIN", NULL, NULL, NULL);

    /* Dump our final cache */
    if (n==-1 || n==2) {
        g_hash_table_foreach_steal(sqstruct->bigram_cache,    
                                   bigram_free_cache,    
                                   (gpointer) db);
        g_hash_table_destroy(sqstruct->bigram_cache);
    }
    if (n==-1 || n==3) {
        g_hash_table_foreach_steal(sqstruct->trigram_cache,
                                   trigram_free_cache,
                                   (gpointer) db);
        g_hash_table_destroy(sqstruct->trigram_cache);
    }
    if (n==-1 || n==4) {
        g_hash_table_foreach_steal(sqstruct->tetragram_cache,
                                   tetragram_free_cache,
                                   (gpointer) db);
        g_hash_table_destroy(sqstruct->tetragram_cache);
    }

    /* COMMIT COMMIT!! */
    sqlite3_exec(db, "END", NULL, NULL, NULL);
    sqlite3_close(db);
    free(sqstruct);
} 

static int set_exists(void *exists, int argc, char **argv, char **azColName) {
    *((nat_uint32_t*)exists) = (nat_uint32_t)g_ascii_strtoull(argv[0], NULL, 10);
    return 0;
}

void bigram_add_occurrence(SQLite* sqstruct, nat_uint32_t w1, nat_uint32_t w2) {
    sqlite3 *db = sqstruct->dbh;
    nat_uint32_t * counter;
    char *token = NULL;

    if (sqstruct->n != -1 && sqstruct->n != 2) return;

    /* Use our beloved cache */
    token = g_strdup_printf("%u|%u", w1, w2);
    counter = (nat_uint32_t *) g_hash_table_lookup(sqstruct->bigram_cache, token);

    if(counter) 
        (*counter)++;
    else {
        counter = (nat_uint32_t*) g_malloc(sizeof(nat_uint32_t));
        *counter = 1;
    }
    g_hash_table_insert(sqstruct->bigram_cache, token, counter); 

    if(g_hash_table_size(sqstruct->bigram_cache) > CACHE_SIZE) {
        g_hash_table_foreach_steal(sqstruct->bigram_cache, bigram_free_cache, (gpointer) db);
    }
    /* END cache */
}

void trigram_add_occurrence(SQLite* sqstruct, nat_uint32_t w1, nat_uint32_t w2, nat_uint32_t w3) {
    sqlite3 *db = sqstruct->dbh;
    nat_uint32_t * counter;
    char *token = NULL;

    if (sqstruct->n != -1 && sqstruct->n != 3) return;

    /* Use our beloved cache */
    token = g_strdup_printf("%u|%u|%u", w1, w2, w3);
    counter = (nat_uint32_t *) g_hash_table_lookup(sqstruct->trigram_cache, token);

    if(counter) 
        (*counter)++;
    else {
        counter = (nat_uint32_t*) g_malloc(sizeof(nat_uint32_t));
        *counter = 1;
    }
    g_hash_table_insert(sqstruct->trigram_cache, token, counter); 

    if(g_hash_table_size(sqstruct->trigram_cache) > CACHE_SIZE) {
        g_hash_table_foreach_steal(sqstruct->trigram_cache, trigram_free_cache, (gpointer) db);
    }
    /* END cache */
}

void tetragram_add_occurrence(SQLite* sqstruct, nat_uint32_t w1, nat_uint32_t w2, nat_uint32_t w3, nat_uint32_t w4) {
    sqlite3 *db = sqstruct->dbh;
    nat_uint32_t * counter;
    char *token = NULL;

    if (sqstruct->n != -1 && sqstruct->n != 4) return;

    /* Use our beloved cache */
    token = g_strdup_printf("%u|%u|%u|%u", w1, w2, w3, w4);
    counter = (nat_uint32_t *) g_hash_table_lookup(sqstruct->tetragram_cache, token);

    if(counter) 
        (*counter)++;
    else {
        counter = (nat_uint32_t*) g_malloc(sizeof(nat_uint32_t));
        *counter = 1;
    }
    g_hash_table_insert(sqstruct->tetragram_cache, token, counter); 

    if(g_hash_table_size(sqstruct->tetragram_cache) > CACHE_SIZE) {
        g_hash_table_foreach_steal(sqstruct->tetragram_cache, tetragram_free_cache, (gpointer) db);
    }
    /* END cache */
}

gboolean bigram_free_cache(gpointer key, gpointer value, gpointer user_data) {
    int rc;
    char * query = NULL;
    char * skey   = (char *)    key;
    nat_uint32_t * nvalue = (nat_uint32_t *) value;
    char *errmsg  = NULL;
    nat_uint32_t exists = 0;
    nat_uint32_t w1, w2;
    sqlite3 *db = (sqlite3 *) user_data;

    sscanf(skey, "%u|%u", &w1, &w2);
    
    query =  g_strdup_printf("SELECT occs FROM bigrams  WHERE word1=%u AND word2=%u",
		     w1, w2);

    rc = sqlite3_exec(db, query, set_exists, &exists, &errmsg);

    g_free(query);

    if (rc != SQLITE_OK) {
	fprintf(stderr, "Error searching for bigram: %s\n", errmsg);
	sqlite3_free(errmsg);
	sqlite3_close(db);
	exit(1);
    }

    if (exists) {
	query = g_strdup_printf("UPDATE bigrams SET occs = %u WHERE word1=%u AND word2=%u",
				exists + (*nvalue), w1, w2);
    } else {
	query = g_strdup_printf("INSERT INTO bigrams VALUES(%u,%u,%u)",
				w1, w2, *nvalue);
    }

    rc = sqlite3_exec(db, query, NULL, NULL, &errmsg);

    g_free(query);

    if (rc != SQLITE_OK) {
	fprintf(stderr, "Error inserting/updating bigram: %s\n", errmsg);
	sqlite3_free(errmsg);
	sqlite3_close(db);
	exit(1);
    }

    g_free(skey);
    g_free(nvalue);
    return TRUE;
} 

gboolean trigram_free_cache(gpointer key, gpointer value, gpointer user_data) {
    int rc;
    char * query = NULL;
    char * skey   = (char *)    key;
    nat_uint32_t * nvalue = (nat_uint32_t *) value;
    char *errmsg  = NULL;
    nat_uint32_t exists = 0;
    nat_uint32_t w1, w2, w3;
    sqlite3 *db = (sqlite3 *) user_data;

    sscanf(skey, "%u|%u|%u", &w1, &w2, &w3);

    query =  g_strdup_printf("SELECT occs FROM trigrams  WHERE word1=%u AND word2=%u AND word3=%u",
		                     w1, w2, w3);

    rc = sqlite3_exec(db, query, set_exists, &exists, &errmsg);
    g_free(query);

    if (rc != SQLITE_OK) {
	fprintf(stderr, "Error searching for trigram: %s\n", errmsg);
	sqlite3_free(errmsg);
	sqlite3_close(db);
	exit(1);
    }

    if (exists) {
	query = g_strdup_printf("UPDATE trigrams SET occs = %u WHERE word1=%u AND word2=%u AND word3=%u",
				exists + (*nvalue), w1, w2, w3);
    } else {
	query = g_strdup_printf("INSERT INTO trigrams VALUES(%u,%u,%u,%u)",
				w1, w2, w3, *nvalue);
    }

    rc = sqlite3_exec(db, query, NULL, NULL, &errmsg);

    g_free(query);


    if (rc != SQLITE_OK) {
	fprintf(stderr, "Error inserting/updating trigram: %s\n", errmsg);
	sqlite3_free(errmsg);
	sqlite3_close(db);
	exit(1);
    }

    g_free(skey);
    g_free(nvalue);
    return TRUE;
} 


gboolean tetragram_free_cache(gpointer key, gpointer value, gpointer user_data) {
    int rc;
    char * query = NULL;
    char * skey   = (char *)    key;
    nat_uint32_t * nvalue = (nat_uint32_t *) value;
    char *errmsg  = NULL;
    nat_uint32_t exists = 0;
    nat_uint32_t w1, w2, w3, w4;
    sqlite3 *db = (sqlite3 *) user_data;

    sscanf(skey, "%u|%u|%u|%u", &w1, &w2, &w3, &w4);

    query =  g_strdup_printf("SELECT occs FROM tetragrams WHERE "
                             "word1=%u AND word2=%u AND word3=%u AND word4=%u",
                             w1, w2, w3, w4);

    rc = sqlite3_exec(db, query, set_exists, &exists, &errmsg);

    g_free(query);

    if (rc != SQLITE_OK) {
	fprintf(stderr, "Error searching for tetragram: %s\n", errmsg);
	sqlite3_free(errmsg);
	sqlite3_close(db);
	exit(1);
    }

    if (exists) {
	query = g_strdup_printf("UPDATE tetragrams SET occs = %u WHERE "
                                "word1=%u AND word2=%u AND word3=%u AND word4=%u",
				exists + (*nvalue), w1, w2, w3, w4);
    } else {
	query = g_strdup_printf("INSERT INTO tetragrams VALUES(%u,%u,%u,%u,%u)",
				w1, w2, w3, w4, *nvalue);
    }

    rc = sqlite3_exec(db, query, NULL, NULL, &errmsg);

    g_free(query);

    if (rc != SQLITE_OK) {
	fprintf(stderr, "Error inserting/updating tetragram: %s\n", errmsg);
	sqlite3_free(errmsg);
	sqlite3_close(db);
	exit(1);
    }

    g_free(skey);
    g_free(nvalue);
    return TRUE;
} 


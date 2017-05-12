/* -*- Mode: C; c-file-style: "stroustrup" -*- */

/* NATools - Package with parallel corpora tools
 * Copyright (C) 1998-2001  Djoerd Hiemstra
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

#ifndef __SRVSHARED_H__
#define __SRVSHARED_H__

#include <unistd.h>
#include <string.h>
#include <ctype.h>

#include <EXTERN.h>
#include <perl.h>


#include <NATools/words.h>
#include "invindex.h"
#include "corpusinfo.h"
#include "dictionary.h"


#define DONE(fd)	write(fd, "** DONE **\n", 11)
#define ERROR(fd)       write(fd, "** SYNTAX ERROR **\n", 19)


typedef struct _tu {
    char *source;
    char *target;
    double quality;
} TU;

int send_TU(int sd, TU* tu);
void destroy_TU(TU* tu);
char *convert_sentence(Words *W, CorpusCell *sentence);
TU* create_TU(CorpusInfo *corpus, double q, CorpusCell *source, CorpusCell *target);
GSList* dump_conc(int fd, CorpusInfo *corpus, int direction,
		  nat_boolean_t both, nat_boolean_t exact_match,
		  wchar_t words[50][150], int i);
GSList* dump_ngrams(int fd, CorpusInfo *corpus, int direction,
                    wchar_t words[50][150], int n);
CorpusCell *corpus_retrieve_sentence(CorpusInfo* corpus,
				     nat_boolean_t source,
				     const nat_uchar_t chunk,
				     nat_uint32_t sentence,
				     double *kwalitee);

double* rank_load(CorpusInfo *corpus, const char* file, const nat_uint32_t size);
#endif

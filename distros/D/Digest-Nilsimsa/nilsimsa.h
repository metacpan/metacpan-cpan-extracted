/***************************************************************************
                        nilsimsa.h  -  global defines
                             -------------------
    begin                : Mon May 14 2001
    copyright            : (C) 2001 by cmeclax
    email                : cmeclax@ixazon.dynip.com
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

#ifndef NILSIMSA_H
#define NILSIMSA_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#define tran3(a,b,c,n) (((tran[((a)+(n))&255]^tran[(b)]*((n)+(n)+1))+tran[(c)^tran[n]])&255)
#define INVALID 0
#define LITERALCODE 1
#define FILECODE 2
#define ALLOWRULE 3
#define DENYRULE 4


typedef char nscode[32];
struct nsrecord
{int acc[256]  /* counts each trigram's hash */;
 int total     /* total number of trigrams counted */;
 int threshold /* mean of all numbers in acc */;
 int nilsmi    /* nilsimsa be ti bei le terkarbi; used as sort key */;
 int flag      /* is this a literal code, a file, an allow rule, or a deny rule? */;
 int priority  /* try all priority 1 rules after all priority 0 rules */;
 long filepos  /* position of this line in the rule file */;
 char code[32] /* the nilsimsa code as a bit vector */;
 char *name    /* the filename or code from the command line */;
 };

int nilsimsa(struct nsrecord *a,struct nsrecord *b);
void aggregate(int n);
void codetostr(struct nsrecord *a,char *str);
int strtocode(char *str,struct nsrecord *a);

int accbuf(unsigned char *buf,int len,struct nsrecord *a);
void dprint(char *msg);
void filltran();

#endif

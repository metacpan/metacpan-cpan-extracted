/* -*- Mode: C; c-file-style: "stroustrup" -*- */

/**
 * @file
 * @brief routines to manage the library specific aspects
 *
 * Copyright 1994-2010 Ulisses Pinto & José João Almeida & Alberto Simões
 *                     Projecto Natura, Universidade do Minho
 */

#include <string.h>

#include "jsconfig.h"
#include "jspell.h"
#include "proto.h"
#include "defmt.h"

/** personal dictionary */
hash_info pers;

/** replacement "dic", can't be static */    
hash_info repl;

/** ...  */
struct genflagent gentable[MASKBITS];    /* CHANGE NEW */

/**
 * @brief ...
 */
char *advance_beg(char *buf)
{
    char hadlf;
    int len;

    currentchar = buf;
    len = strlen(currentchar) - 1;
    hadlf = currentchar[len] == '\n';
    if (hadlf)
        currentchar[len] = 0;

    /* stdout shouldn't be necessary */
    skip_ntroff_text_formaters(hadlf, stdout);
    return skiptoword(currentchar);
}

// JJ #if 0
char *get_next_word(char *buf, char *next_word)
{
    char *word_ini, *word_end, *p;
    int i;

    word_ini = advance_beg(buf);
    if (*word_ini) {   /* there is in fact a word */
        word_end = skipoverword(word_ini);

        i = 0;
        p = word_ini;
        while (p != word_end) {
            next_word[i] = *p;
            i++;
            p++;
        }
        next_word[i] = '\0';
    }
    else word_end = NULL;
    return word_end;
}
// #endif

/**
 * @brief ...
 *
 * solutions should already be allocated in the calling module
 */
void word_info(char *word,
               char solutions[MAXPOSSIBLE][MAXSOLLEN],
               char near_misses[MAXPOSSIBLE][MAXSOLLEN])
{
    int old_cflag, old_lflag;
    
    old_cflag = cflag;
    old_lflag = lflag;
    cflag = 0;
    lflag = 0;
    strcpy(contextbufs[0], word);
    
    checkline(stdout);

    copy_array(solutions, sol_out);
    copy_array(near_misses, misses_out);

    cflag = old_cflag;
    lflag = old_lflag;
}


#if 0
static void insert_word(char *word, char *class, char *flags, char *comm)
{
    char fg, aux[MAXSOLLEN];

    fg = hashheader.flagmarker;
    sprintf(aux, "%s%c%s%c%s%c%s", word, fg, class, fg, flags, fg, comm);
    treeinsert(aux, ICHARTOSSTR_SIZE, 1);
}
#endif

/**
 *
 */
#if 0
static void accept_word(char *word, char *class, char *flags, char *comm)
{
    char fg, aux[MAXSOLLEN];

    fg = hashheader.flagmarker;
    sprintf(aux, "%s%c%s%c%s%c%s", word, fg, class, fg, flags, fg, comm);
    treeinsert(aux, ICHARTOSSTR_SIZE, 0);
}
#endif

#if 0
/* replace_word(char *start, char *word, char **curchar) */
char* replace_word(char *start, char *word, char *curchar)
{
    char *word_ini;
    char *aux = curchar;
    char saux[SET_SIZE + MAXSTRINGCHARS];

    strcpy(saux,word);
    word_ini = advance_beg(start);
    replace_token(word_ini, word_ini, saux, &aux);
    return aux;
}
#endif

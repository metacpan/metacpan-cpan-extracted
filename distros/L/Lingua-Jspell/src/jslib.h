#ifndef __JSLIB_H__
#define __JSLIB_H__

/*----------------------------------------------------------------------------\
| JSLIB.H                                                                     |
\----------------------------------------------------------------------------*/

/* Copyright 1994 by Ulisses Pinto & Jose' Joa~o Almeida, Universidade do Minho
 */
/* Version 1.00 */

/* max number of solutions for a word */
#define MAXPOSSIBLE 50
/* max number of caracters a solution */
#define MAXSOLLEN 255

typedef char sol_type[MAXSOLLEN]; 
typedef sol_type sols_type[MAXPOSSIBLE]; 

#define exis_sol(x) x[0]

void word_info(char *word,
               char solutions[MAXPOSSIBLE][MAXSOLLEN],
               char near_misses[MAXPOSSIBLE][MAXSOLLEN]);
/*
char *word;
sols_type solutions;
sols_type near_misses; */

void init_jspell();
/*char *opt;*/

/*char *strg; */
/* possible flags: g,G,P,m,y,Y
    g - display "good" options only         ;  G - put g option off
    P - suppress root/affix combinations    ;  m - put P option off
    y - suppress typing errors combinations ;  Y - put y option off
*/

char *get_next_word();
/* char *buf, *next_word; */

void get_roots();
/* char *word;
   sols_type solutions;
   char in_dic[MAXPOSSIBLE]; */
/* you should initialize jspell with -cf to print out the flags */

void insert_word();
/* char *word, char *class, char *flags, char *comm */

void accept_word();
/* char *word, char *class, char *flags, char *comm */

char * replace_word();
/*  char *start, char *word, char *curchar */
/*   start - points to the position in the buffer where we want the word 
        to be replaced
     tok - the new token (word) that will replace
     curchar - the position in the buffer where the old word ends
        returns position where new word ends */


/*----------------------------------------*/

typedef unsigned int ID_TYPE; 

char *word_f_id(ID_TYPE id);
/* word from id: returns a pointer to the word corresponding to this id */

ID_TYPE word_id(char *word, char *feats, int *status);
/* this function gives a unique identifier for a given word */

char *class_f_id(ID_TYPE id);
/* class from id: returns a pointer to the class corresponding to this id */

char *flags_f_id(ID_TYPE id);
/* class from id: returns a string with the flags of this word */

/*---------------------------------------------------------------------*/
/* Feature processing                                                  */
/*---------------------------------------------------------------------*/
/* #define MAXFEALEN 20                                                */

#endif

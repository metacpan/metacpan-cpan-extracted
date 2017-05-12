/*---------------------------------------------------------------------------\
| GCLASS.C                                                                   |
\---------------------------------------------------------------------------*/

/* Este programa dada uma string do tipo
   lex(pal_ori, class_ori, class_pre, class_suf, class_suf2)
   retorna uma nova class. que e' a juncao das da 
     class_ori com class_pre com class_suf com class_suf2
*/

#include <ctype.h>
#include <stdio.h>
#include <string.h>

typedef struct feature {
   char name[20];
   char value[20];
} feature;

#define MAX_FEATURES 20
#define ACCENTS "·ÈÌÛ˙Á„ı‚ÍÙ˚‡Ò"


/*---------------------------------------------------------------------------*/

static void remove_spaces(char *st_in, char *st_lex)
{
   int i;

   i = 0;
   while (*st_in != '\0') {
      if (*st_in != ' ') {
         st_lex[i] = *st_in;
         i++;
      }
      st_in++;
   }
   st_lex[i] = '\0';
}

/*---------------------------------------------------------------------------*/

static char *advance_begin(char *st_lex) {
    while (*st_lex != '[' && *st_lex != '\0')
	st_lex++;
    return st_lex;
}

#if 0
static char *advance_pre(char *st_lex)
{
    st_lex++;   /* advance_comma */
    while (*st_lex != ',' && *st_lex != '\0')  /* advance [] do pre*/
	st_lex++;
    st_lex++;   /* advance_comma */
    return st_lex;
}
#endif

/*---------------------------------------------------------------------------*/

static char *new_var(char *st_lex, feature *table, int i_table)
{
   int i;

   i = 0;
   while (isalnum(*st_lex)) {
      table[i_table].name[i] = *st_lex;
      i++;
      st_lex++;
   }
   table[i_table].name[i] = '\0';
   if (i == 0 || (*st_lex != '=')) {
      fprintf(stderr, 
      "Invalid situation in new_var() in gclass module(%c%c)\n",*st_lex,*(st_lex+1));
      return NULL;
   }
   return st_lex;
}

static char *new_value(char *st_lex, feature *table, int i_table)
{
   int i;

   i = 0;
   while (isalnum(*st_lex) || (*st_lex == '_') || strchr(ACCENTS,*st_lex)) {
      table[i_table].value[i] = *st_lex;
      i++;
      st_lex++;
   }
   if (i == 0 || (*st_lex != ',' && *st_lex != ']')) {
      fprintf(stderr, "Invalid value in new_value() in gclass module\n");
   }
   table[i_table].value[i] = '\0';   /* mark end of table */
   return st_lex;
}

static char *advance_eq(char *st_lex)
{
    if (*st_lex == '=') {
       st_lex++;
       return st_lex;
    }
    else {
      fprintf(stderr, "= sign not found in gclass module\n");
      return 0;
    }
}

/*---------------------------------------------------------------------------*/

static char *build_table(char *st_lex,  feature *table, int *it)
{
   int i_table;

   i_table = 0;
   st_lex += 1;   /* advance [ */
   while (st_lex && *st_lex != ']' && *st_lex != '\0') {
      if (!(st_lex = new_var(st_lex, table, i_table))) return 0;
      if (!(st_lex = advance_eq(st_lex))) return 0;
      if (!(st_lex = new_value(st_lex, table, i_table))) return 0;
      i_table++;   /* indi'ce do pro'ximo slot a preencher */
      if (*st_lex == ',') st_lex++;
   }
   if (*st_lex == ']') st_lex++;   /* advance ']' */
   table[i_table].name[0] = '\0';
   *it = i_table;
   return st_lex;
}

/*---------------------------------------------------------------------------*/

static int in(char *find, feature *table, int it1)
{
   int i;

   i = 0;
   while (i < it1 && strcmp(table[i].name, find))
      i++;
   if (i == it1)   /* not found */
      return -1;
   else return i;
}

static int merge_tables(feature *table1, feature *table2, int it1, int it2)
{
   int i, pos;

   for (i = 0; i < it2; i++) {  /* for each member of it2: */
      if ((pos = in(table2[i].name, table1, it1)) != -1)   /* found */
         table1[pos] = table2[i];
      else {   /* new feature */
         table1[it1] = table2[i];
         it1++;
      }
   }
   table1[it1].name[0] = '\0';   /* mark end of table */
   return it1;
}

/*---------------------------------------------------------------------------*/

static void build_resp(feature *table, char *st_glob, int it1)
{
   int i;
   char aux[40];

   st_glob[0] = '[';
   st_glob[1] = '\0';
   for (i = 0; i < it1; i++) {
      sprintf(aux, "%s=%s", table[i].name, table[i].value);
      strcat(st_glob, aux);
      if (i < it1-1) {
         strcat(st_glob, ",");
      }
   }
   strcat(st_glob, "]");
}

/*---------------------------------------------------------------------------*/

int gclass(char *st_in, char *st_glob)
{
   int it1, it2;
   char st_aux[80];
   char *st_lex;

   feature table[MAX_FEATURES];   /* tabela com as features da class_ori */
   feature table2[MAX_FEATURES];  /* tabela com as features da class_dest */

   remove_spaces(st_in, st_aux);
   st_lex = st_aux;
   st_lex = advance_begin(st_lex);
   if (!(st_lex = build_table(st_lex, table, &it1))) {
      fprintf(stderr, "-1 %s\n", st_aux);
      return 0;
   }
   st_lex = advance_begin(st_lex);
   if (!(st_lex = build_table(st_lex, table2, &it2))) {
      fprintf(stderr, "-2 %s\n", st_aux);
      return 0;
   }
   it1 = merge_tables(table, table2, it1, it2);
   st_lex = advance_begin(st_lex);
   if (!(st_lex = build_table(st_lex, table2, &it2))) {
      fprintf(stderr, "-2 %s\n", st_aux);
      return 0;
   }
   it1 = merge_tables(table, table2, it1, it2);
   st_lex = advance_begin(st_lex);
   if (!(st_lex = build_table(st_lex, table2, &it2))) {
      fprintf(stderr, "-2 %s\n", st_aux);
      return 0;
   }
   it1 = merge_tables(table, table2, it1, it2);
   build_resp(table, st_glob, it1);
   return 1;
}

/*---------------------------------------------------------------------------*/

int jclass(char *st_in)
{
   int it1, it2;
   char *st_lex = st_in;
   char *st_mid;

   feature table[MAX_FEATURES];   /* tabela com as features da class_ori */
   feature table2[MAX_FEATURES];  /* tabela com as features da class_dest */

   remove_spaces(st_in, st_lex);
   st_mid = st_lex = advance_begin(st_lex);
   if (!(st_lex = build_table(st_lex, table, &it1))) {
      fprintf(stderr, "-1 %s\n", st_in);
      return 0;
   }
   st_lex = advance_begin(st_lex);
   if (!(st_lex = build_table(st_lex, table2, &it2))) {
      fprintf(stderr, "-2 %s\n", st_in);
      return 0;
   }
   it1 = merge_tables(table, table2, it1, it2);
   st_lex = advance_begin(st_lex);
   if (!(st_lex = build_table(st_lex, table2, &it2))) {
      fprintf(stderr, "-2 %s\n", st_in);
      return 0;
   }
   it1 = merge_tables(table, table2, it1, it2);
   st_lex = advance_begin(st_lex);
   if (!(st_lex = build_table(st_lex, table2, &it2))) {
      fprintf(stderr, "-2 %s\n", st_in);
      return 0;
   }
   it1 = merge_tables(table, table2, it1, it2);
   build_resp(table, st_mid, it1);
   strcat(st_mid,")");
   return 1;
}

/*
main()
{
   char st_new[255];

   char ex[]="lex(ABANDONEI, [CL=v,SCL=tr,T=inf], [Fsem=inv], [T=pp,N=s,P=1], [P=2])";
   gclass(ex, st_new);

   printf("Velha=%s\nnova string= %s\n", ex,st_new);
}
*/

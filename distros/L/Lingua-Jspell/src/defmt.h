#ifndef __DEFMT_H__
#define __DEFMT_H__

void  skip_ntroff_text_formaters(int hadlf, FILE *ofile);
void  put_flag_info(char *strg_out);
char* cut_by_dollar(char *staux);
char* macro(char *strg);
void  get_roots(char *word,
		char solutions[MAXPOSSIBLE][MAXSOLLEN],
		char in_dic[MAXPOSSIBLE]);
void compound_info(char *strg_out, char *word, char *root, char *root_class,
                   char *pre_class, char *suf_class, char *suf2_class);
/* Skip to beginning of a word */
char *skiptoword(char *bufp);     

/* Return pointer to end of a word */
char *skipoverword(char *bufp);   

void checkline(FILE *ofile);

void replace_token(char *buf, char *start, register char *tok, char **curchar);

void jclass(char*,char*);

void copy_array();

void copy_array2();


#endif

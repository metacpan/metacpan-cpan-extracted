#include <stdio.h>
#include <string.h>
#include "jslib.h"

 extern char islib; 

#define SEP_SOL " "
#define END_SOL "\n"
#define COL_SEP "#"

static int novo(int n, int i, char solutions[MAXPOSSIBLE][MAXSOLLEN]){
 int j;
 for(j=0;j<i;j++) {
    if(strncmp(solutions[j],solutions[i],n)==0) return 0;}
 return 1;}

extern char o_form[80];

void jjflags(char *w )
{
    char solutions[MAXPOSSIBLE][MAXSOLLEN];
    char near_misses[MAXPOSSIBLE][MAXSOLLEN];
    char radical[30];
    char classi[30];
    char imp_cla[30];
    char w2[30];
    int i, r, imposed, k;
    ID_TYPE id;
    int  old_islib;
    char  old_o_form[80];

    old_islib = islib;

    strcpy(old_o_form, o_form);
    strcpy(o_form, "%s|%s");

    islib = 1;

    imposed = sscanf(w, "%[^/]/%s", w2, imp_cla) ;
    
    printf("%s%s", w2, COL_SEP);

    word_info(w2, solutions, near_misses);
    if (solutions[0][0]) {
        i=0;
        k=0;
        while (solutions[i][0]) {
            char *flags;
            sscanf(solutions[i],"%[^|]|%[^,]",radical,classi);
            /* printf("(%s)=(%s)(%s).\n",solutions[i],radical,classi); */
            if(( (imposed ==1) || (strcmp(classi,imp_cla) == 0 )) &&  
               novo(strlen(radical)+strlen(classi)+1,i,solutions)){
                if (k) printf("%s", SEP_SOL);
                printf("%s", radical);
                id=word_id(radical,classi,&r);
                if(r) {
                    flags = flags_f_id(id);
                    printf("/%s",flags);
                }
                k++;
            }
            i++;
        }
    }
    printf("%s", END_SOL); 
    islib = old_islib;
    strcpy(o_form,old_o_form);
}

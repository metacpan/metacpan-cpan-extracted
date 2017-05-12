#include <stdio.h>
#include <string.h>
#include "jslib.h"

int main(){
  int i;
  sols_type s1, s2;
  char word[200];
  init_jspell("-d port -W 0 -a -J");
  while( fgets(word,200,stdin)){
     if( word[strlen(word)-1]=='\n'){word[strlen(word)-1]='\0' ;}
     word_info(word, s1, s2);
     if(s1[0][0]){ puts("morph:");
                   for(i=0; s1[i][0]; i++){ puts(s1[i]);}}
     if(s2[0][0]){ puts("near_misses:");
                   for(i=0; s2[i][0]; i++){ puts(s2[i]);}}
  }
  return 0;
} 

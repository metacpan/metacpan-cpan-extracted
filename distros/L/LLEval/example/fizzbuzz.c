#!lleval
#include <string.h>
#include <stdio.h>
char *fizz(int n){ return n % 3 ? "" : "Fizz"; }
char *buzz(int n){ return n % 5 ? "" : "Buzz"; }
char *fizzbuzz(char *buf, int n){
  strcpy(buf, fizz(n));
  strcat(buf, buzz(n));
  if (!strlen(buf)) sprintf(buf, "%d", n);
  return buf;
}
void main(){
  int i;
  char buf[12];
  for (i = 1; i <= 30; i++){
    printf("%s\n", fizzbuzz(buf, i));
  }
}


#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/select.h>

volatile char * test;
struct timeval tv;

int main() {
    test = malloc(100);
    test = "HALLLOOOOOOHHHHHHHBBBBBAAHHHHHHHAJJLDLKEJJJJLLLLLLL";
    while (1) {
       printf("%s\n", test);
       tv.tv_sec = 5;
       tv.tv_usec = 0;
       select(0,0,0,0,&tv);
       //sleep(1);
    }
}

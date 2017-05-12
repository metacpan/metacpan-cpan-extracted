#include <stdio.h>
#include <unistd.h>

int main(int argc, char* argv[]) {
    int i;
    char hashbang1[256]; 
    char hashbang2[256]; 
    char * index;
    char * newargv[32];
    char * path = &hashbang1[2];
    FILE * fp = fopen(argv[1], "r");
    
    memset(hashbang1, '\0', sizeof(hashbang1));
    memset(hashbang2, '\0', sizeof(hashbang2));

    fgets(hashbang1, sizeof(hashbang1) - 2, fp);
    fclose(fp);
    strcpy(path + strlen(path) - 1, ".pl");
    fp = fopen(path, "r");
    fgets(hashbang2, sizeof(hashbang2), fp);
    index = hashbang2;
    while (*index && *index != ' ') 
        index++;
    *index = '\0';
    newargv[0] = hashbang2 + 2;
    newargv[1] = path;
    for (i = 1; i <= argc; i++)
        newargv[i+1] = argv[i];
    newargv[i+1] = NULL;

    execv(newargv[0], newargv);
    
    return 0;
}


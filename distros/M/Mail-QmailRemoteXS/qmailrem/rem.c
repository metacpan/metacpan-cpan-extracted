#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include "qmailrem.h"

static char rcsid[] = "$Id$";

int main(int argc, char **argv)
{
    char *ret;
    ret = mail("boxable.com","reed@rip.corp.nbci.com","reed@boxable.com","test","rip.corp.nbci.com",120,120);
    printf("%s",ret);
    exit(0);
}


#include <stdio.h>
#include <stdlib.h>
#include <NATools/words.h>
#include <glib.h>
#include <wchar.h>

#include "unicode.c"

wchar_t* chomp(wchar_t *str) {
    wchar_t *rts = str;
    while(*str) {
	if (*str == L'\n') {
	    *str = L'\0';
	}
	str++;
    }
    return rts;
}

int main(void) {
    wchar_t buff[100];
    Words *lst;
    FILE *fd;

    init_locale();

    lst = words_new();
    printf("ok 1\n");

    fd = fopen("t/bin/words.input", "r");
    if (!fd) return 1;

    while(!feof(fd)) {
	fgetws(buff, 100, fd);
	chomp(buff);
	if (!feof(fd)) {
	    words_add_word(lst, wcs_dup(buff));
	}
    }
    fclose(fd);
    printf("ok 2\n");

    if (words_save(lst, "t/bin/words.output.bin") != TRUE) return 1;

    printf("ok 3\n");

    words_free(lst);

    lst = words_quick_load("t/bin/words.output.bin");
    if (!lst) return 1;

    printf("ok 4\n");

    fd = fopen("t/bin/words.input", "r");
    while(!feof(fd)) {
	fgetws(buff, 100, fd);
	if (!feof(fd)) {
	    if (words_get_id(lst, chomp(buff)) == 0) {
		fprintf(stderr, "Word %ls returned 0\n", buff);
		return 1;
	    }
	}
    }
    printf("ok 5\n");

    fclose(fd);

    return 0;
}


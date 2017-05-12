#include <stdio.h>
#include <stdlib.h>
#include <NATools/corpus.h>

int main(void) {
    CorpusCell *crp;
    int i;
    Corpus *corpus;
    char buff[10];
    FILE *input, *output;

    corpus = corpus_new();
    if (!corpus) return 1;
    printf("ok 1\n");

    input = fopen("t/bin/corpus.input", "r");
    if (!input) return 1;

    while(!feof(input)) {
	fgets(buff, 10, input);
	if (!feof(input)) {
	    nat_uint32_t id = atoi(buff);
	    corpus_add_word(corpus, id, 1);
	}
    }
    fclose(input);
    printf("ok 2\n");

    if (corpus_save(corpus, "t/bin/corpus.output.gz")) {
	return 1;
    }
    printf("ok 3\n");

    corpus_free(corpus);
    corpus = corpus_new();
    if (!corpus) return 1;
    printf("ok 4\n");

    if (corpus_load(corpus, "t/bin/corpus.output.gz")) {
	return 1;
    } 
    printf("ok 5\n");

    crp = corpus_first_sentence(corpus);
    if (!crp) return 1;
    printf("ok 6\n");

    output = fopen("t/bin/corpus.output", "w");
    if (!output) return 1;
    
    do {
	i = 0;
	while(crp[i].word) {
	    fprintf(output, "%d\n", crp[i++].word);
	}
	fprintf(output, "0\n");
    } while((crp = corpus_next_sentence(corpus)));
    fclose(output);

    printf("ok 7\n");
    return 0;
}

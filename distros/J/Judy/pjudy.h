#include <string.h>

typedef struct {
	char *ptr;
	STRLEN length;
} Str;

typedef Word_t UWord_t;
typedef Word_t IWord_t;

Word_t
pvtJudyHSMemUsedV(Pvoid_t PJLArray, Word_t remainingLength, Word_t keyLength );

Word_t
pvtJudyHSMemUsed( Pvoid_t PJHSArray );

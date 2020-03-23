/* utf8_decode.h */

#define UTF8_END   -1
#define UTF8_ERROR -2

typedef struct utf8_decode_s {
    int the_index;
    int the_length;
    int the_char;
    int the_byte;
    const char* the_input;
} utf8_decode_t;

extern int  utf8_decode_at_byte(utf8_decode_t *u);
extern int  utf8_decode_at_character(utf8_decode_t *u);
extern void utf8_decode_init(const char p[], int length, utf8_decode_t *u);
extern int  utf8_decode_next(utf8_decode_t *u);

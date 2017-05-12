#include <stdio.h>
#include <ctype.h>

#define NIBBLE_BITS 4
#define NIBBLE (1 << NIBBLE_BITS)

static void preamble(void);
static void decode_table(const char* name);
static void encode_table(const char* name);
static void state_table(const char* name);
static void coda(void);

int main(int argc, char* argv[])
{
    preamble();
    decode_table("uri_decode_tbl");
    encode_table("uri_encode_tbl");
    state_table("uri_state_tbl");

    coda();

    return 0;
}

static void preamble(void)
{
    printf("/*\n");
    printf(" *  THIS FILE WAS GENERATED AUTOMATICALLY\n");
    printf(" *\n");
    printf(" *  DON'T EDIT IT BY HAND!\n");
    printf(" *  (unless you know what you are doing)\n");
    printf(" */\n");
    printf("\n");
    printf("#define NIBBLE_BITS 4\n");
    printf("#define MAKE_BYTE(nh, nl) (((nh) << NIBBLE_BITS) | (nl))\n");
    printf("\n");
}

static void coda(void)
{
    printf("/*\n");
    printf(" *  END OF FILE\n");
    printf(" */\n");
}

/*
 * Generate a table with decode values to be used for any character.
 */
static void decode_table(const char* name)
{
    printf("/*\n");
    printf(" * Table has a 0 if that character cannot be a hex digit;\n");
    printf(" * otherwise it has the decimal value for that hex digit.\n");
    printf(" */\n");
    printf("static char %s[%d] =\n", name, NIBBLE*NIBBLE);
    printf("/*");
    for (unsigned char r = 0; r < NIBBLE; ++r) {
        printf("%5x", r);
    }
    printf(" */\n{\n");
    for (unsigned char r = 0; r < NIBBLE; ++r) {
        unsigned char m = r << NIBBLE_BITS;
        printf("   ");
        for (unsigned char c = 0; c < NIBBLE; ++c) {
            unsigned char x = m | c;
            int hex = 0;
            int dig = 0;

            /*
             * If the character is a valid hexadecimal digit,
             * the table will contain its value; otherwise
             * it will have a zero.
             */
            if (x >= '0' && x <= '9') {
                hex = 1;
                dig = x - '0';
            }
            else if (x >= 'a' && x <= 'f') {
                hex = 1;
                dig = x - 'a' + 10;
            }
            else if (x >= 'A' && x <= 'F') {
                hex = 1;
                dig = x - 'A' + 10;
            }
            printf(" %3d,", hex ? dig : 0);
        }
        printf("  /* %1x: %3d ~ %3d */\n", r, m, m + NIBBLE - 1);
    }
    printf("};\n\n");
}

/*
 * Generate a table which identifies characters that must be URL-encoded.
 */
static void encode_table(const char* name)
{
    printf("/*\n");
    printf(" * Table has a 0 if that character doesn't need to be encoded;\n");
    printf(" * otherwise it has a string with the character encoded in hex digits.\n");
    printf(" */\n");
    printf("static char* %s[%d] =\n", name, NIBBLE*NIBBLE);
    printf("/");
    for (unsigned char r = 0; r < NIBBLE; ++r) {
        printf("%c%5x", r == 0 ? '*' : ' ', r);
    }
    printf(" */\n{\n");
    for (unsigned char r = 0; r < NIBBLE; ++r) {
        unsigned char m = r << NIBBLE_BITS;
        printf("   ");
        for (unsigned char c = 0; c < NIBBLE; ++c) {
            unsigned char x = m | c;
            int plain = (isalnum(x) ||
                         x == '-' ||
                         x == '_' ||
                         x == '.' ||
                         x == '~');
            if (plain) {
                printf("   0 ,");
            } else {
                printf("\"%%%02x\",", (unsigned int) x);
            }
        }
        printf("  /* %1x: %3d ~ %3d */\n", r, m, m + NIBBLE - 1);
    }
    printf("};\n\n");
}

#define URI_STATE_START  0
#define URI_STATE_NAME   1
#define URI_STATE_EQUALS 2
#define URI_STATE_VALUE  3
#define URI_STATE_END    4
#define URI_STATE_ERROR  5

static void state_table(const char* name)
{
    static const char* states[] =
    {
        "URI_STATE_START",
        "URI_STATE_NAME",
        "URI_STATE_EQUALS",
        "URI_STATE_VALUE",
        "URI_STATE_END",
        "URI_STATE_ERROR",
    };
    int size = sizeof(states) / sizeof(states[0]);
    printf("/*\n");
    printf(" * Table has the next state given last read character and current state.\n");
    printf(" */\n");
    printf("\n");

    for (int state = 0; state < size; ++state) {
        printf("#define %-20.20s %2d\n", states[state], state);
    }
    printf("\n");
    printf("/* Minimum state that indicates we must terminate processing */\n");
    printf("#define %-20.20s %s\n", "URI_STATE_TERMINATE", "URI_STATE_END");
    printf("\n");

    printf("static char %s[%d][%d] =\n", name, NIBBLE*NIBBLE, size+1);
    printf("/* ");
    for (int state = 0; state < size; ++state) {
        printf("%5d", state);
    }
    printf("*/\n");
    printf("{\n");
    for (int x = 0; x < 256; ++x) {
        char c = (char) x;
        printf("    {");
        for (int state = 0; state < size; ++state) {
            int next = state;
            if (c == '\0' || c == ';') {
                /* If we see the end and are in state NAME, we consider
                 * it an error, because we demmand to at least have
                 * seen an '='. */
                if (state == URI_STATE_EQUALS ||
                    state == URI_STATE_VALUE) {
                    next = URI_STATE_END;
                } else {
                    next = URI_STATE_ERROR;
                }
            } else if (isspace(c)) {
                /* remain in same state */
            } else if (c == '=') {
                /* A '=' switches from NAME to EQUALS... */
                if (state == URI_STATE_NAME) {
                    next = URI_STATE_EQUALS;
                /* ... or from EQUALS to VALUE (as first character in VALUE) */
                } else if (state == URI_STATE_EQUALS) {
                    next = URI_STATE_VALUE;
                /* ... or remains in VALUE... */
                } else if (state == URI_STATE_VALUE) {
                /* ... otherwise it is an error. */
                } else {
                    next = URI_STATE_ERROR;
                }
            } else {
                /* Any other character either marks the fact that
                 * we are entering state NAME or VALUE, or that
                 * we are remaining in those states. */
                if (state == URI_STATE_START) {
                    next = URI_STATE_NAME;
                } else if (state == URI_STATE_EQUALS) {
                    next = URI_STATE_VALUE;
                } else {
                    /* remain in same state */
                }
            }
            printf("%3d, ", next);
        }
        printf("},  /* %2x -- %3d -- %c */\n", x, x, isprint(c) ? c : '.');
    }
    printf("};\n\n");
}

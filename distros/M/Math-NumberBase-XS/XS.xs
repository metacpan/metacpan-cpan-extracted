#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

typedef struct {
    int base;
    AV *symbols;
    HV *symbol_value_map;
} MathNumberBaseXS;

/* Free allocated memory for the C structure */
static void free_data(void *ptr) {
    if (!ptr) return;

    MathNumberBaseXS *data = (MathNumberBaseXS *)ptr;

    /* Avoid interfering with Perl's reference management */
    data->symbols = NULL;
    data->symbol_value_map = NULL;

    Safefree(data);
}

/* XS Definitions */
MODULE = Math::NumberBase::XS  PACKAGE = Math::NumberBase::XS

PROTOTYPES: ENABLE

void
DESTROY(self)
    SV *self;
CODE:
    MAGIC *mg = mg_find(SvRV(self), 'P');
    if (mg && mg->mg_ptr) {
        free_data(mg->mg_ptr);
        mg->mg_ptr = NULL;
    }

void
_init(self, base, symbols, symbol_value_map)
    SV *self;
    int base;
    AV *symbols;
    HV *symbol_value_map;
CODE:
    MathNumberBaseXS *data;

    /* Check and clean up existing MAGIC */
    MAGIC *mg = mg_find(SvRV(self), 'P');
    if (mg && mg->mg_ptr) {
        free_data(mg->mg_ptr);
        mg->mg_ptr = NULL;
    }

    /* Allocate new memory for the C structure */
    Newxz(data, 1, MathNumberBaseXS);
    data->base = base;

    /* Increment reference counts for Perl-managed objects */
    SvREFCNT_inc((SV *)symbols);
    data->symbols = symbols;

    SvREFCNT_inc((SV *)symbol_value_map);
    data->symbol_value_map = symbol_value_map;

    /* Attach the new C structure to the Perl object via MAGIC */
    sv_magic(SvRV(self), NULL, 'P', (const char *)data, 0);
    SvMAGIC(SvRV(self))->mg_flags |= MGf_DUP;

int
_get_base(self)
    SV *self;
CODE:
    MAGIC *mg = mg_find(SvRV(self), 'P');
    if (!mg || !mg->mg_ptr) croak("Object not initialized");

    MathNumberBaseXS *data = (MathNumberBaseXS *)mg->mg_ptr;
    RETVAL = data->base;
OUTPUT:
    RETVAL

AV *
_get_symbols(self)
    SV *self;
CODE:
    MAGIC *mg = mg_find(SvRV(self), 'P');
    if (!mg || !mg->mg_ptr) croak("Object not initialized");

    MathNumberBaseXS *data = (MathNumberBaseXS *)mg->mg_ptr;

    /* Increment reference count before returning to Perl */
    RETVAL = data->symbols;
    SvREFCNT_inc((SV *)RETVAL);
OUTPUT:
    RETVAL

HV *
_get_symbol_value_map(self)
    SV *self;
CODE:
    MAGIC *mg = mg_find(SvRV(self), 'P');
    if (!mg || !mg->mg_ptr) croak("Object not initialized");

    MathNumberBaseXS *data = (MathNumberBaseXS *)mg->mg_ptr;

    /* Increment reference count before returning to Perl */
    RETVAL = data->symbol_value_map;
    SvREFCNT_inc((SV *)RETVAL);
OUTPUT:
    RETVAL

UV
_to_decimal(self, string)
    SV *self;
    SV *string;
CODE:
    MAGIC *mg = mg_find(SvRV(self), 'P');
    if (!mg || !mg->mg_ptr) croak("Object not initialized");

    MathNumberBaseXS *data = (MathNumberBaseXS *)mg->mg_ptr;

    int base = data->base;
    HV *symbol_value_map = data->symbol_value_map;

    UV result = 0;
    UV power = 1; /* Start with base^0 = 1 */

    /* Ensure the input is defined */
    if (!SvOK(string)) {
        croak("Input string is undefined");
    }

    /* Convert input to a string */
    STRLEN len;
    const char *input = SvPVutf8(string, len);

    if (len == 0) {
        croak("Input string is empty");
    }

    /* Process the string from right to left */
    for (int i = len - 1; i >= 0; i--) {
        char char_at_pos = input[i];

        /* Fetch the character's value from the symbol_value_map */
        SV **value_sv = hv_fetch(symbol_value_map, &char_at_pos, 1, 0);
        if (!value_sv || !SvOK(*value_sv)) {
            croak("Invalid character '%c' in input string", char_at_pos);
        }

        int value = SvIV(*value_sv); /* Get the integer value for the character */

        /* Accumulate the result */
        result += value * power;

        /* Update power = power * base */
        if (i > 0) { /* Avoid overflow on the last iteration */
            UV new_power = power * base;
            if (new_power < power) { /* Detect overflow */
                croak("Overflow occurred while calculating power");
            }
            power = new_power;
        }
    }

    RETVAL = result;
OUTPUT:
    RETVAL

const char *
_from_decimal(self, in_decimal)
    SV *self;
    UV in_decimal;
CODE:
    MAGIC *mg = mg_find(SvRV(self), 'P');
    if (!mg || !mg->mg_ptr) croak("Object not initialized");

    MathNumberBaseXS *data = (MathNumberBaseXS *)mg->mg_ptr;

    int base = data->base;
    AV *symbols = data->symbols;

    STRLEN result_len = 0;
    STRLEN buffer_size = 64; /* Initial buffer size */
    char *buffer = (char *)malloc(buffer_size);

    if (!buffer) {
        croak("Memory allocation failed");
    }

    /* Null-terminate the buffer */
    buffer[0] = '\0';

    while (in_decimal > 0) {
        /* Get the current symbol index */
        int index = in_decimal % base;

        /* Fetch the symbol from the symbols array */
        SV **symbol_sv = av_fetch(symbols, index, 0);
        if (!symbol_sv || !SvOK(*symbol_sv)) {
            free(buffer);
            croak("Invalid symbol for index %d", index);
        }

        /* Get the symbol as a string */
        STRLEN symbol_len;
        const char *symbol = SvPV(*symbol_sv, symbol_len);

        /* Expand the buffer if necessary */
        while (result_len + symbol_len + 1 >= buffer_size) {
            buffer_size *= 2;
            buffer = (char *)realloc(buffer, buffer_size);
            if (!buffer) {
                croak("Memory reallocation failed");
            }
        }

        /* Shift the existing content to make room for the new symbol */
        memmove(buffer + symbol_len, buffer, result_len + 1); /* Include the null terminator */
        memcpy(buffer, symbol, symbol_len);                  /* Copy the new symbol */
        result_len += symbol_len;

        /* Update the number */
        in_decimal /= base;
    }

    /* If the number is zero, add the first symbol */
    if (result_len == 0) {
        SV **symbol_sv = av_fetch(symbols, 0, 0);
        if (!symbol_sv || !SvOK(*symbol_sv)) {
            free(buffer);
            croak("Invalid symbol for index 0");
        }

        STRLEN symbol_len;
        const char *symbol = SvPV(*symbol_sv, symbol_len);

        /* Expand the buffer if necessary */
        while (symbol_len + 1 >= buffer_size) {
            buffer_size = symbol_len + 1;
            buffer = (char *)realloc(buffer, buffer_size);
            if (!buffer) {
                croak("Memory allocation failed");
            }
        }

        memcpy(buffer, symbol, symbol_len);
        buffer[symbol_len] = '\0'; /* Null-terminate explicitly */
    }

    RETVAL = buffer;

    /* Free the buffer in XS automatically */
    Safefree(buffer);
OUTPUT:
    RETVAL

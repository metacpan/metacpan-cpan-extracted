/* src/simd/mds_dispatch.c — populates the 256-byte handler-kind table. */
#include "mds_dispatch.h"

#define T MDS_K_TEXT

const uint8_t mds_dispatch[256] = {
    /* 0x00 */ T,T,T,T,T,T,T,T,T, MDS_K_TAB, MDS_K_NEWLINE, T,T, MDS_K_CR, T,T,
    /* 0x10 */ T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,
    /* 0x20 */ MDS_K_SPACE,        MDS_K_BANG,         MDS_K_QUOTE,        MDS_K_HASH,
               T,                  T,                  MDS_K_AMP,          T,
               MDS_K_PAREN_OPEN,   MDS_K_PAREN_CLOSE,  MDS_K_STAR,         MDS_K_PLUS,
               T,                  MDS_K_DASH,         MDS_K_DOT,          T,
    /* 0x30 */ T,T,T,T,T,T,T,T,T,T, MDS_K_COLON, T, MDS_K_LT, MDS_K_EQ, MDS_K_GT, T,
    /* 0x40 */ T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,
    /* 0x50 */ T,T,T,T,T,T,T,T,T,T,T,
               MDS_K_BRACKET_OPEN, MDS_K_BACKSLASH, MDS_K_BRACKET_CLOSE, T, MDS_K_UNDERSCORE,
    /* 0x60 */ MDS_K_BACKTICK, T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,
    /* 0x70 */ T,T,T,T,T,T,T,T,T,T,T,T, MDS_K_PIPE, T, MDS_K_TILDE, T,
    /* 0x80 */ T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,
    /* 0x90 */ T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,
    /* 0xA0 */ T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,
    /* 0xB0 */ T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,
    /* 0xC0 */ T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,
    /* 0xD0 */ T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,
    /* 0xE0 */ T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,
    /* 0xF0 */ T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,T,
};

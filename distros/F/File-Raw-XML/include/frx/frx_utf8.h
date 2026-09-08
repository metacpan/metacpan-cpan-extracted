#ifndef FRX_UTF8_H
#define FRX_UTF8_H

/* UTF-8 in, scalars out, and the three character classes XML names.
 *
 * frx_utf8_decode reads one scalar and returns its byte length, or 0 when
 * the bytes are not UTF-8: a truncated sequence, a bad continuation byte,
 * an overlong form, a surrogate, or anything above U+10FFFF. The table is
 * the one in RFC 3629 section 4, which is the whole definition of "valid".
 *
 * The three predicates are XML 1.0 fifth edition, sections 2.2 and 2.3,
 * transcribed range by range from the specification text. Char excludes
 * the C0 controls other than TAB, LF and CR, the surrogates, and U+FFFE and
 * U+FFFF; the decoder already refuses surrogates, so the Char check after a
 * decode is what catches the last two, which are valid UTF-8 and not XML.
 *
 * No SIMD. The documents are kilobytes and the cost is the signature
 * check, not the scan.
 *
 * Needs nothing. */

/* byte length of the scalar at p, 0 when not UTF-8; *cp gets the scalar */
static size_t
frx_utf8_decode(const unsigned char *p, size_t n, unsigned long *cp)
{
    unsigned char c;
    if (!n) return 0;
    c = p[0];
    if (c < 0x80) { *cp = c; return 1; }
    if (c < 0xC2) return 0;                              /* continuation or overlong 2-byte lead */
    if (c < 0xE0) {
        if (n < 2 || (p[1] & 0xC0) != 0x80) return 0;
        *cp = ((unsigned long)(c & 0x1F) << 6) | (p[1] & 0x3F);
        return 2;
    }
    if (c < 0xF0) {
        if (n < 3 || (p[1] & 0xC0) != 0x80 || (p[2] & 0xC0) != 0x80) return 0;
        if (c == 0xE0 && p[1] < 0xA0) return 0;          /* overlong */
        if (c == 0xED && p[1] >= 0xA0) return 0;         /* surrogate */
        *cp = ((unsigned long)(c & 0x0F) << 12)
            | ((unsigned long)(p[1] & 0x3F) << 6) | (p[2] & 0x3F);
        return 3;
    }
    if (c < 0xF5) {
        if (n < 4 || (p[1] & 0xC0) != 0x80 || (p[2] & 0xC0) != 0x80
                  || (p[3] & 0xC0) != 0x80) return 0;
        if (c == 0xF0 && p[1] < 0x90) return 0;          /* overlong */
        if (c == 0xF4 && p[1] >= 0x90) return 0;         /* above U+10FFFF */
        *cp = ((unsigned long)(c & 0x07) << 18)
            | ((unsigned long)(p[1] & 0x3F) << 12)
            | ((unsigned long)(p[2] & 0x3F) << 6) | (p[3] & 0x3F);
        return 4;
    }
    return 0;
}

/* the scalar as UTF-8 into out (at least 4 bytes); returns the length */
static size_t
frx_utf8_encode(unsigned long cp, unsigned char *out)
{
    if (cp < 0x80) { out[0] = (unsigned char)cp; return 1; }
    if (cp < 0x800) {
        out[0] = (unsigned char)(0xC0 | (cp >> 6));
        out[1] = (unsigned char)(0x80 | (cp & 0x3F));
        return 2;
    }
    if (cp < 0x10000) {
        out[0] = (unsigned char)(0xE0 | (cp >> 12));
        out[1] = (unsigned char)(0x80 | ((cp >> 6) & 0x3F));
        out[2] = (unsigned char)(0x80 | (cp & 0x3F));
        return 3;
    }
    out[0] = (unsigned char)(0xF0 | (cp >> 18));
    out[1] = (unsigned char)(0x80 | ((cp >> 12) & 0x3F));
    out[2] = (unsigned char)(0x80 | ((cp >> 6) & 0x3F));
    out[3] = (unsigned char)(0x80 | (cp & 0x3F));
    return 4;
}

/* XML 1.0 section 2.2: Char */
static int
frx_is_char(unsigned long c)
{
    return c == 0x9 || c == 0xA || c == 0xD
        || (c >= 0x20 && c <= 0xD7FF)
        || (c >= 0xE000 && c <= 0xFFFD)
        || (c >= 0x10000 && c <= 0x10FFFF);
}

/* XML 1.1 second edition, section 2.2, production [2]: Char */
static int
frx_is_char11(unsigned long c)
{
    return (c >= 0x1 && c <= 0xD7FF)
        || (c >= 0xE000 && c <= 0xFFFD)
        || (c >= 0x10000 && c <= 0x10FFFF);
}

/* XML 1.1 second edition, section 2.2, production [2a]: RestrictedChar.
 * Production [1] subtracts `Char* RestrictedChar Char*` from the document,
 * so one of these written literally anywhere is not well-formed; as a
 * character reference it is a Char and allowed. #x0 is neither. */
static int
frx_is_restricted11(unsigned long c)
{
    return (c >= 0x1 && c <= 0x8) || c == 0xB || c == 0xC
        || (c >= 0xE && c <= 0x1F) || (c >= 0x7F && c <= 0x84)
        || (c >= 0x86 && c <= 0x9F);
}

/* XML 1.1 second edition, section 2.3, productions [4] and [4a]. They are
 * the productions XML 1.0 fifth edition adopted word for word, so the
 * name tables below serve both versions; a document's version selects
 * nothing here, and the comment says so rather than a second copy. */

/* XML 1.0 section 2.3: NameStartChar, without the colon - the lexer
 * handles the QName colon rule itself */
static int
frx_is_name_start(unsigned long c)
{
    return (c >= 'A' && c <= 'Z') || c == '_' || (c >= 'a' && c <= 'z')
        || (c >= 0xC0 && c <= 0xD6) || (c >= 0xD8 && c <= 0xF6)
        || (c >= 0xF8 && c <= 0x2FF) || (c >= 0x370 && c <= 0x37D)
        || (c >= 0x37F && c <= 0x1FFF) || (c >= 0x200C && c <= 0x200D)
        || (c >= 0x2070 && c <= 0x218F) || (c >= 0x2C00 && c <= 0x2FEF)
        || (c >= 0x3001 && c <= 0xD7FF) || (c >= 0xF900 && c <= 0xFDCF)
        || (c >= 0xFDF0 && c <= 0xFFFD) || (c >= 0x10000 && c <= 0xEFFFF);
}

/* XML 1.0 section 2.3: NameChar, without the colon */
static int
frx_is_name_char(unsigned long c)
{
    return frx_is_name_start(c)
        || c == '-' || c == '.' || (c >= '0' && c <= '9') || c == 0xB7
        || (c >= 0x300 && c <= 0x36F) || (c >= 0x203F && c <= 0x2040);
}

/* Namespaces in XML section 4: an NCName is a Name with no colon. What
 * xml:id's value must be (xml:id section 4), and what a prefix is. */
static int
frx_is_ncname(const char *p, size_t n)
{
    size_t i = 0;
    int first = 1;
    if (!n) return 0;
    while (i < n) {
        unsigned long cp;
        size_t k;
        unsigned char c = (unsigned char)p[i];
        if (c < 0x80) { cp = c; k = 1; }
        else {
            k = frx_utf8_decode((const unsigned char *)p + i, n - i, &cp);
            if (!k) return 0;
        }
        if (cp == ':') return 0;
        if (first ? !frx_is_name_start(cp) : !frx_is_name_char(cp)) return 0;
        first = 0;
        i += k;
    }
    return 1;
}

/* XML 1.0 section 2.3: S */
static int
frx_is_s(unsigned char c)
{
    return c == 0x20 || c == 0x9 || c == 0xA || c == 0xD;
}

#endif /* FRX_UTF8_H */

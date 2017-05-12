/* Type for adding whitespace. */

typedef struct json_ws {
    SV * news;
    SV * olds;
    /* Length of new string. */
    unsigned int news_l;
    /* Copy point. */
    char * q;
    /* Origin */
    char * p;
    /* Top of token tree. */
    json_token_t * t;
    /* Token under examination now. */
    json_token_t * next;

    /* Whitespace to add before and after. */
    char * before[n_json_tokens];
    char * after[n_json_tokens];
    int array_depth;
    int object_depth;
    char * array_indent;
    char * object_indent;
}
json_ws_t;

static void copy_whitespace (json_ws_t * ws, char * w)
{
    char * q;
    q = ws->q;
    while (*w) {
	*q++ = *w++;
    }
    ws->q = q;
}

static INLINE int whitespace_json (json_ws_t * ws)
{
    /* Copy place. */
    char * c;
    /* Value of q at entry to this routine, used to calculate added
       length. */
    char * qorig;
    json_token_t * next;
    char * q;

    q = ws->q;
    qorig = q;
    next = ws->next;

    while (next) {
	/* Copy start of string. */
	copy_whitespace (ws, ws->before[next->type]);
	switch (next->type) {
	case json_token_object:
	    *q++ = '{';
	    ws->object_depth++;
	    ws->q = q;
	    q += whitespace_json (ws);
	    ws->object_depth--;
	    *q++ = '}';
	    break;
	case json_token_array:
	    *q++ = '[';
	    ws->array_depth++;
	    ws->q = q;
	    q += whitespace_json (ws);
	    ws->object_depth--;
	    *q++ = ']';
	    break;
	case json_token_string:
	case json_token_key:
	case json_token_literal:
	case json_token_number:
	    for (c = ws->p + next->start; c <= ws->p + next->end; c++) {
		*q++ = *c;
	    }
	    break;
	case json_token_comma:
	    *q++ = ',';
	    break;
	case json_token_colon:
	    *q++ = ':';
	    break;
	default:
	    croak ("unhandled token type %d", next->type);
	}
	/* Copy end of string. */
	c = ws->after[next->type];
	while (*c) {
	    *q++ = *c++;
	}
	next = next->next;
    }
    return q - qorig;
}

static int copy_json (char * p, char * q, json_token_t * t)
{
    /* Loop variable. */
    json_token_t * next;
    /* Copy place. */
    char * c;
    /* Value of q at entry to this routine, used to calculate added
       length. */
    char * qorig;

    next = t;
    qorig = q;
    while (next) {
	switch (next->type) {
	case json_token_object:
	    *q++ = '{';
	    q += copy_json (p, q, next->child);
	    *q++ = '}';
	    break;
	case json_token_array:
	    *q++ = '[';
	    q += copy_json (p, q, next->child);
	    *q++ = ']';
	    break;
	case json_token_string:
	case json_token_key:
	case json_token_literal:
	case json_token_number:
	    for (c = p + next->start; c <= p + next->end; c++) {
		*q++ = *c;
	    }
	    break;
	case json_token_comma:
	    *q++ = ',';
	    break;
	case json_token_colon:
	    *q++ = ':';
	    break;
	default:
	    croak ("unhandled token type %d", next->type);
	}
	next = next->next;
    }
    return q - qorig;
}

/* Remove all the whitespace. */

static SV * strip_whitespace (json_token_t * tokens, SV * json)
{
    SV * stripped;
    char * p;
    char * q;
    /* Original length. */
    STRLEN l;
    /* Length of output. */
    unsigned int m;
    p = SvPV (json, l);
    stripped = newSV (l);
    /* Tell Perl it's a string. */
    SvPOK_on (stripped);
    /* Set UTF-8 if necessary. */
    if (SvUTF8 (json)) {
	SvUTF8_on (stripped);
    }
    /* Get a pointer to the string inside "stripped". */
    q = SvPVX (stripped);
    m = copy_json (p, q, tokens);
    /* Set the length. */
    SvCUR_set (stripped, m);
    return stripped;
}

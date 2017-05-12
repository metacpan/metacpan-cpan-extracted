/*
 * defmt.c - Handle formatter constructs, mostly by scanning over them.
 *
 * Copyright (c), 1983, by Pace Willisson
 *
 * Copyright 1992, 1993, Geoff Kuenning, Granada Hills, CA
 * All rights reserved.
 *
 * Copyright 1994 by Ulisses Pinto & Jose' Joa~o Almeida, Universidade do Minho
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All modifications to the source code must be clearly marked as
 *    such.  Binary redistributions based on modified source code
 *    must be clearly marked as modified versions in the documentation
 *    and/or other materials provided with the distribution.
 * 4. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgment:
 *      This product includes software developed by Geoff Kuenning and
 *      other unpaid contributors.
 * 5. The name of Geoff Kuenning may not be used to endorse or promote
 *    products derived from this software without specific prior
 *    written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY GEOFF KUENNING AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL GEOFF KUENNING OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * The TeX code is originally by Greg Schaffer, with many improvements from
 * Ken Stevens.  The nroff code is primarily from Pace Willisson, although
 * other people have improved it.
 */

#include <ctype.h>
#include <string.h>
#include "jsconfig.h"
#include "jspell.h"
#include "proto.h"
#include "msgs.h"
#include "defmt.h"
#include "good.h"


#define ISTEXTERM(c)   (((c) == TEXLEFTCURLY) || \
                        ((c) == TEXRIGHTCURLY) || \
                        ((c) == TEXLEFTSQUARE) || \
                        ((c) == TEXRIGHTSQUARE))
#define ISMATHCH(c)    (((c) == TEXBACKSLASH) || \
                        ((c) == TEXDOLLAR) || \
                        ((c) == TEXPERCENT))

char aux[3][MAXSOLLEN];

/* 
 *
 */
char is_sign(char ch) {
    int i = 0;

    while (signs[i] != '\0' && signs[i] != ch)	i++;
    if (signs[i] == ch)  return 1;
    else return 0;                
}

char *macro(char *strg) {
    static int c = 0;
    int i, i2, i3;
    char def[20];
    struct dent *d;

    c++;   /* para rodar */
    if (c == 3) c = 0;

    i = i2 = 0;
    while (strg[i] && i2 < MAXSOLLEN)  {
	if (strg[i] != MACRO_MARK) {
	    aux[c][i2] = strg[i];
	    i++;
	    i2++;
	}
	else {  /* substitution */
	    def[0] = strg[i];    /* put # */
	    i++;                /* advance # */
	    i3 = 1;
	    while (((strg[i] >= 'a' && strg[i] <= 'z') ||
		    (strg[i] >= 'A' && strg[i] <= 'Z') ||
		    (strg[i] >= '0' && strg[i] <= '9'))  && (i3 < 20))  {
		def[i3] = strg[i];
		i++;
		i3++;
	    }
	    def[i3] = '\0';
	    /* printf("DEB def=%s", def); */
	    if ((d = lookup(strtosichar(def, 0), 0))) {
            if (i2+strlen(d->jclass) < MAXSOLLEN)
               strcpy(aux[c]+i2, d->jclass);
            i2 += strlen(d->jclass);
         }
         else fprintf(stderr, DEFMT_C_MACRO_NOT_FOUND, def);
      }
   }
   if (i2 < MAXSOLLEN)  /* ok */
      aux[c][i2] = '\0';
   else fprintf(stderr, DEFMT_C_MACRO_SP_OUT);
/*   printf("DEB aux[c]=%s", aux[c]); */
   return aux[c];
}



/*---------------------------------------------------------------------------*
 * TeX routines                                                              *
 *---------------------------------------------------------------------------*/

static void TeX_open_paren(char **bufp) {
    while (**bufp && **bufp != TEXLEFTCURLY)
	(*bufp)++;
}

/*
 *
 */

static void TeX_skip_parens(char **bufp) {
    while (**bufp && **bufp != TEXRIGHTCURLY)
	(*bufp)++;
}

/*
 * Skips the begin{ARG}, and optionally up to two {PARAM}{PARAM}'s to
 * the begin if they are required.  However, Only skips if on this
 * line.
 */
static void TeX_skip_args(char **bufp) {
    register int skip_cnt = 0; /* Max of 2. */

    if (strncmp(*bufp, "tabular", 7) == 0
	|| strncmp(*bufp, "minipage", 8) == 0
	|| strncmp(*bufp, "tabular*", 8) == 0)
	skip_cnt++;

    TeX_skip_parens(bufp);        /* Skip to the end of the \begin{} parens */

    if (**bufp)
	(*bufp)++;
    else
	return;

    if (skip_cnt--)
	TeX_skip_parens(bufp);        /* skip 1st {PARAM}. */
    else
	return;

    if (**bufp)
	(*bufp)++;
    else
	return;

    if (skip_cnt)
	TeX_skip_parens(bufp);        /* skip to end of 2nd {PARAM}. */
}

/*
 *
 */
static int TeX_LR_check(int begin_p, char **bufp) {
    TeX_open_paren(bufp);
    if (**bufp == 0)  {
	LaTeX_Mode = 'm';
	return 0;        /* remain in math mode until '}' encountered. */
    }
    else
	LaTeX_Mode = 'P';

    if (strncmp(++(*bufp), "minipage", 8) == 0) {
	TeX_skip_parens(bufp);
	if (**bufp)
	    (*bufp)++;
	if (begin_p) {
	    TeX_skip_parens(bufp); /* now skip opt. args if on this line. */
	    math_mode += 2;
	    /* indicate minipage mode. */
	    math_mode += ((math_mode & 127) - 1) * 128;
	}
	else {
	    math_mode -= (math_mode & 127) * 128;
	    if (math_mode < 0) {
		fprintf(stderr, DEFMT_C_LR_MATH_ERROR);
		math_mode = 1;
	    }
	}
	return 1;
    }
    (*bufp)--;
    return 0;
}

/*
 *
 */
static int TeX_LR_begin(char **bufp) {
    if ((strncmp(*bufp, "mbox", 4) == 0)
	|| (strncmp(*bufp, "makebox", 7) == 0)
	|| (strncmp(*bufp, "fbox", 4) == 0)
	|| (strncmp(*bufp, "framebox", 8) == 0))
	math_mode += 2;
    else if ((strncmp(*bufp, "parbox", 6) == 0)
	     || (strncmp(*bufp, "raisebox", 8) == 0)) {
        math_mode += 2;
        TeX_open_paren(bufp);
        if (**bufp)
	    (*bufp)++;
        else
	    LaTeX_Mode = 'r'; /* same as reference -- skip {} */
    }
    else if (strncmp(*bufp, "begin", 5) == 0)
	return TeX_LR_check(1, bufp);        /* minipage */
    else
	return 0;

    /* skip tex command name and optional or width arguments. */
    TeX_open_paren(bufp);
    return 1;
}

/*
 *
 */

static int TeX_math_check(int cont_char, char **bufp) {
    TeX_open_paren(bufp);
    /* Check for end of line, continue later. */
    if (**bufp == 0) {
	LaTeX_Mode = (char) cont_char;
	return 0;
    }
    else
	LaTeX_Mode = 'P';
    
    if (strncmp(++(*bufp), "equation", 8) == 0
	|| strncmp(*bufp, "eqnarray", 8) == 0
	|| strncmp(*bufp, "displaymath", 11) == 0
	|| strncmp(*bufp, "array", 5) == 0
	|| strncmp(*bufp, "picture", 7) == 0
#ifdef IGNOREBIB
	|| strncmp(*bufp, "thebibliography", 15) == 0
#endif
	|| strncmp(*bufp, "math", 4) == 0)
    {
	(*bufp)--;
	TeX_skip_parens(bufp);
	return 1;
    }
    if (cont_char == 'b')
	TeX_skip_args(bufp);
    else
	TeX_skip_parens(bufp);
    return 0;
}

/*
 * must check for \begin{mbox} or whatever makes new text region.
 */
static int TeX_math_end(char **bufp) {
    if (TeX_comment)
	return 0;
    else if (**bufp == TEXDOLLAR) {
	if ((*bufp)[1] == TEXDOLLAR)
	    (*bufp)++;
	return 1;
    }
    else if (**bufp == TEXPERCENT) {
	TeX_comment = 1;
	return 0;
    }
    /* processing extended TeX command */
    (*bufp)++;
    if (**bufp == TEXRIGHTPAREN  ||  **bufp == TEXRIGHTSQUARE)
	return 1;
    if (TeX_LR_begin(bufp))        /* check for switch back to LR mode */
	return 1;
    if (strncmp(*bufp, "end", 3) == 0)
	/* find environment that is ending */
	return TeX_math_check('e', bufp);
    else
	return 0;
}

/*
 *
 */
static void TeX_skip_check(char **bufp) {
    int charlen;

    /* ADDITIONALLY, MAY WANT TO ADD:
     * input, include, includeonly, documentstyle, pagestyle, pagenumbering
     * WITH TWO {} {}'S TO SKIP:
     * setcounter, addtocounter, setlength, addtolength, settowidth
     */
    
    if (strncmp(*bufp, "end", 3) == 0
	|| strncmp(*bufp, "vspace", 6) == 0
	|| strncmp(*bufp, "hspace", 6) == 0
	|| strncmp(*bufp, "cite", 4) == 0
	|| strncmp(*bufp, "ref", 3) == 0
	|| strncmp(*bufp, "parbox", 6) == 0
	|| strncmp(*bufp, "label", 5) == 0
	|| strncmp(*bufp, "input", 5) == 0
	|| strncmp(*bufp, "nocite", 6) == 0
	|| strncmp(*bufp, "include", 7) == 0
	|| strncmp(*bufp, "includeonly", 11) == 0
	|| strncmp(*bufp, "documentstyle", 13) == 0
#ifndef IGNOREBIB
	|| strncmp(*bufp, "bibliography", 12) == 0
	|| strncmp(*bufp, "bibitem", 7) == 0
#endif
	|| strncmp(*bufp, "hyphenation", 11) == 0
	|| strncmp(*bufp, "pageref", 7) == 0) {
	TeX_skip_parens(bufp);
	if (**bufp == 0)
	    LaTeX_Mode = 'r';
    } else if (strncmp(*bufp, "rule", 4) == 0) {       /* skip two args. */
	TeX_skip_parens(bufp);
	if (**bufp == 0)        /* Only skips one {} if not on same line. */
	    LaTeX_Mode = 'r';
	else {                       /* Skip second arg. */
	    (*bufp)++;
	    TeX_skip_parens(bufp);
	    if (**bufp == 0)
		LaTeX_Mode = 'r';
	}
    } else {
	/* Optional tex arguments sometimes should and
	 * sometimes shouldn't be checked
	 * (eg \section [C Programming] {foo} vs
	 *     \rule [3em] {0.015in} {5em})
	 * SO -- we'll just igore it rather than make a full LaTeX parser.
	 */

	/* Must look at the space after the command. */
	while (**bufp
	       && (l1_isstringch(*bufp, charlen, 0)
		   || iswordch(chartoichar (**bufp))))
	{
	    if (!isstringch(*bufp + charlen, 0)
		&& !iswordch(chartoichar((*bufp)[charlen])))
		break;
	    *bufp += charlen;
	}
    }
}

/*
 *
 */
static int TeX_math_begin(char **bufp) {
    if (**bufp == TEXDOLLAR) {
	if ((*bufp)[1] == TEXDOLLAR)
	    (*bufp)++;
	return 1;
    }
    while (**bufp == TEXBACKSLASH) {
	(*bufp)++; /* check for null char here? */
	if (**bufp == TEXLEFTPAREN  ||  **bufp == TEXLEFTSQUARE)
	    return 1;
	if (strncmp(*bufp, "begin", 5) == 0) {
	    if (TeX_math_check('b', bufp))
		return 1;
	    else
		(*bufp)--;
	} else {
	    TeX_skip_check(bufp);
	    return 0;
	}
    }
    /*
     * Ignore references for the tib (1) bibliography system, that
     * is, text between a ``[.'' or ``<.'' and ``.]'' or ``.>''.
     * We don't care whether they match, tib doesn't care either.
     *
     * A limitation is that the entire tib reference must be on one
     * line, or we break down and check the remainder anyway.
     */
    if ((**bufp == TEXLEFTSQUARE  ||  **bufp == TEXLEFTANGLE)
	&& (*bufp)[1] == TEXDOT) {
	(*bufp)++;
	while (**bufp) {
	    if (*(*bufp)++ == TEXDOT
		&& (**bufp == TEXRIGHTSQUARE  ||  **bufp == TEXRIGHTANGLE))
		return TeX_math_begin(bufp);
	}
	return 0;
    }
    else
	return 0;
}


/*
 * Skip to beginning of a word
 */
char *skiptoword(char *bufp) {
    /* char strg_out[80]; */

    while (*bufp &&  (!isstringch(bufp, 0)  &&  (!iswordch(chartoichar (*bufp))
						 || isboundarych(chartoichar(*bufp))
						 || (tflag && (math_mode & 1) && !TeX_comment))
		      && (!signal_is_word || !is_sign(*bufp)))) {
	/* check paren necessity... */
	if (tflag) { /* TeX or LaTeX stuff */
	    /* Odd numbers mean we are in "math mode" */
	    /* Even numbers mean we are in LR or */
	    /* paragraph mode */
	    if (!TeX_comment) {       /* Don't check comments */
		if (*bufp == TEXPERCENT)
		    TeX_comment = 1;
		else if (math_mode & 1) {
		    if ((LaTeX_Mode == 'e' && TeX_math_check('e', &bufp))
			|| (LaTeX_Mode == 'm' && TeX_LR_check(1, &bufp)))
			math_mode--;    /* end math mode */
		    else {
			while (*bufp  && !ISMATHCH(*bufp))
			    bufp++;
			if (*bufp == 0)
			    break;
			if (TeX_math_end(&bufp))
			    math_mode--;
		    }
		    if (math_mode < 0) {
			fprintf(stderr, DEFMT_C_TEX_MATH_ERROR);
			math_mode = 0;
		    }
		} else {
		    if (math_mode > 1 && *bufp == TEXRIGHTCURLY
			&& (math_mode < (math_mode & 127) * 128))
			math_mode--;    /* re-enter math */
		    else if (LaTeX_Mode == 'm'
			     || (math_mode && (math_mode >= (math_mode & 127) * 128)
				 &&  (strncmp(bufp, "\\end", 4) == 0))) {
			if (TeX_LR_check(0, &bufp))
			    math_mode--;
		    }
		    else if (LaTeX_Mode == 'b'  &&  TeX_math_check('b', &bufp)) {
			/* continued begin */
			math_mode++;
		    }
		    else if (LaTeX_Mode == 'r') {
			/* continued "reference" */
			TeX_skip_parens(&bufp);
			LaTeX_Mode = 'P';
		    }
		    else if (TeX_math_begin(&bufp))
			/* checks references and */
			/* skips \ commands */
			math_mode++;
		}
	    if (*bufp == 0)
		break;
            }
	}
	else {                       /* formatting escape sequences */
	    if (*bufp == NRBACKSLASH) {
		switch (bufp[1]) {
		case 'f':
		    if (bufp[2] == NRLEFTPAREN) {
			/* font change: \f(XY */
			bufp += 5;
		    }
		    else {
			/* ) */
			/* font change: \fX */
			bufp += 3;
		    }
		    continue;
		case 's':
		    /* size change */
		    bufp += 2;
		    if (*bufp == '+'  ||  *bufp == '-')
			bufp++;
		    /* This looks wierd 'cause we assume *bufp is now a digit */
		    bufp++;
		    if (isdigit(*bufp))
			bufp++;
		    continue;
		default:
		    if (bufp[1] == NRLEFTPAREN) {
			/* extended char set escape:  \(XX) */
			bufp += 4;
			continue;
		    }
		    else if (bufp[1] == NRSTAR) {
			if (bufp[2] == NRLEFTPAREN)
			    bufp += 5;
			else
			    bufp += 3;
			continue;
		    }
		    break;
		}
	    }
	}
	bufp++;
    }
    if (*bufp == '\0')
	TeX_comment = 0;
    return bufp;
}

/*
 * Return pointer to end of a word
 */
char *skipoverword(char *bufp) {
/*  bufp  - Start of word -- MUST BE A REAL START */
    register char *lastboundary;
    register int   scharlen; /* Length of a string character */

    if (signal_is_word && is_sign(*bufp))
	return bufp+1;

    lastboundary = NULL;
    for (  ;  ;  ) {
	if (*bufp == '\0') {
	    TeX_comment = 0;
	    break;
	}
	else if (l_isstringch(bufp, scharlen, 0)) {
	    bufp += scharlen;
	    lastboundary = NULL;
	}
	/*
	 * Note that we get here if a character satisfies
	 * isstringstart() but isn't in the string table;  this
	 * allows string characters to start with word characters.
	 */
	else if (iswordch(chartoichar(*bufp))) {
	    bufp++;
	    lastboundary = NULL;
	} else if (isboundarych(chartoichar(*bufp))) {
	    if (lastboundary == NULL)
		lastboundary = bufp;
	    bufp++;
	} else
	    break;                        /* End of the word */
    }
    /*
    * If the word ended in one or more boundary characters,
    * the address of the first of these is in lastboundary, and it
    * is the end of the word.  Otherwise, bufp is the end.
    */
    return (lastboundary != NULL) ? lastboundary : bufp;
}

/*
 *
 */
char *cut_by_dollar(char *staux) {
    while (*staux != '$' && *staux != '\0')
	staux++;
    if (*staux != '\0') {
	*staux = '\0';
	staux++;
    }
    return staux;
}

static char root[INPUTWORDLEN], *root_class, used_flags[5];
static char pre_class[MAXCLASS], suf_class[MAXCLASS], suf2_class[MAXCLASS];

/* static char staux[MAXCLASS]; */

void treat_caps(char *root, int captype1) {
    ichar_t iroot[INPUTWORDLEN];
    
    if (captype1 == ANYCASE || captype1 == CAPITALIZED) {
	strtoichar(iroot, root, INPUTWORDLEN, 1);
	lowcase(iroot);
	/* ichartostr(root, lowcase(strtosichar(root, 1)), INPUTWORDLEN, 1); */
	if (captype1 == CAPITALIZED)
	    iroot[0] = mytoupper(iroot[0]);
	ichartostr(root, iroot, INPUTWORDLEN, 1);
    }
}

/*
 * fills suf_class, suf2_class, pre_class, root and root_class
 * variables
 */
void get_info(struct success hit) {
    int i;

    strcpy(root, hit.dictent->word);
    treat_caps(root, captype(hit.dictent->flagfield));

    root_class = hit.dictent->jclass;
    
    i = 0;
    pre_class[0] = suf_class[0] = suf2_class[0] = '\0';   /* null string */
    if (hit.prefix) {
	ichartostr(pre_class, (hit.prefix)->jclass, (hit.prefix)->classl+1, 1);
	used_flags[i++] = BITTOCHAR(hit.prefix->flagbit);
    }
    if (hit.suffix) {
	ichartostr(suf_class, (hit.suffix)->jclass, (hit.suffix)->classl+1, 1);
	used_flags[i++] = BITTOCHAR(hit.suffix->flagbit);
    }
    if (hit.suffix2) {
	ichartostr(suf2_class, (hit.suffix2)->jclass, (hit.suffix2)->classl+1, 1);
	used_flags[i++] = BITTOCHAR(hit.suffix2->flagbit);
    }
    used_flags[i] = '\0';
    
    if (hit.dictent->jclass[0] == '$') {  
	/* $ means "forced" derivation */
	/* class format: $root word$root word class$word class */
	strcpy(suf2_class, suf_class);
	strcpy(root/*staux*/, root_class+1);
	/* root = staux; */
	root_class = cut_by_dollar(root);
	strcpy(suf_class, cut_by_dollar(root_class));
    }
}

/*
 *
 */
void cab_pipe_resp(char *strg_out, char exists_ch, char *word, int posinline) {
    sprintf(strg_out, "%c %s %d :", exists_ch, word, posinline);
}

void compound_info(char *strg_out, char *word, char *root, char *root_class,
                   char *pre_class, char *suf_class, char *suf2_class) {
    char form_aux[MAXWLEN+MAXSOLLEN];

    sprintf(form_aux, "%s%s%s", word, SEP3, o_form);
    sprintf(strg_out, form_aux, ichartosstr(strtosichar(macro(root), 1), 0),
	    macro(root_class), pre_class, macro(suf_class), suf2_class);
    put_flag_info(strg_out);
}

/*
 *
 */
void copy_array(char ar1[MAXPOSSIBLE][MAXSOLLEN],
                char ar2[MAXPOSSIBLE][MAXSOLLEN]) {
    int i = -1;
    do {
      i++;
      strcpy(ar1[i], ar2[i]);
    } while (ar2[i][0] != '\0');
}

/*
 *
 */
void copy_array2(char ar1[MAXPOSSIBLE], char ar2[MAXPOSSIBLE]) {
    int i;
    
    for (i = 0; i < MAXPOSSIBLE; i++)
      ar1[i] = ar2[i];
}

/*
 *
 */
void get_roots(char *word, char solutions[MAXPOSSIBLE][MAXSOLLEN],
	       char in_dic[MAXPOSSIBLE])
{
    /* solutions should already be allocated in the calling module */
    int old_cflag, old_lflag, old_islib;

    old_cflag = cflag;
    old_lflag = lflag;
    old_islib = islib;
    cflag = 1;
    lflag = 1;
    islib = 1;
    strcpy(contextbufs[0], word);
    checkline(stdout);
    copy_array(solutions, sol_out2);
    copy_array2(in_dic, is_in_dic);
    cflag = old_cflag;
    lflag = old_lflag;
    islib = old_islib;
}


static void treat_sign(FILE *ofile) {
    char strg_out[MAXSOLLEN];

    sprintf(strg_out, o_form, ichartosstr(itoken, 1), "CAT=punct", "", "", "");
    if (islib) {
	strcpy(sol_out[0], strg_out);
	sol_out[1][0] = '\0';
	numhits = 0;
	try_direct_match_in_dic(itoken, itoken, 1, 0, 1);
    }  else if (!terse)
	fprintf(ofile, "%s%s", strg_out, SEP4);
}

/*
 *
 */
static void treat_minword(FILE *ofile) {
    if (islib) {
	strcpy(sol_out[0], "*");
	sol_out[1][0] = '\0';
    } else if (!terse)
	fprintf(ofile, "*");
}

/*
 *
 */
void put_flag_info(char *strg_out) {
    if (showflags) {
	strcat(strg_out, "/");
	strcat(strg_out, used_flags);
    }

    if (Jflag){
	jclass(strg_out,strg_out); 
    }
}

/*
 *
 */
static void treat_good(FILE *ofile) {
    register int i;
    char strg_out[MAXSOLLEN];
    
    if (!islib) {
	cab_pipe_resp(strg_out, '*', ctoken,
		      (int) ((currentchar - contextbufs[0]) - strlen(ctoken)));
	if (!terse)
	    fprintf(ofile, "%s", strg_out);
    }

    for (i = 0; i < numhits; i++) {
	get_info(hits[i]);
	sprintf(strg_out, o_form, ichartosstr(strtosichar(macro(root), 1), 0),
		macro(root_class), pre_class, macro(suf_class), suf2_class);
	put_flag_info(strg_out);

	if (islib)
	    strcpy(sol_out[i], strg_out);
	else {
	    if (i < numhits-1)
		strcat(strg_out, SEP1);
	    if (!terse)
		fprintf(ofile, "%s", strg_out);
	}
    }
    if (islib)
	sol_out[i][0] = '\0';
    else if (!terse)
	fprintf(ofile, "%s", SEP4);
}

/*
 *
 */
static void treat_compoundgood(FILE *ofile) {
    /* compound-word match */
    if (!terse)
	fprintf(ofile, "-\n");      /* ??????????? a mudar */
}


/*
 *
 */
static void treat_not_good(FILE *ofile) {
    register int i;
    char strg_out[MAXSOLLEN];

    if (!gflag) {
	makepossibilities(itoken);
	if (pcount) {
	    /* print &, ctoken, the character offset and the possibilities */
	    if (!islib) {
		cab_pipe_resp(strg_out, '&', ctoken,
			      (int) ((currentchar - contextbufs[0]) - strlen(ctoken)));
		fprintf(ofile, "%s", strg_out);
	    }
	    for (i = 0;  i < my_poss_count/*MAXPOSSIBLE*/;  i++) {
		get_info(my_poss[i].suc);
		compound_info(strg_out, my_poss[i].word,
			      root, root_class, pre_class, suf_class, suf2_class);
		if (islib) {
		    strcpy(misses_out[i], strg_out);
                } else {
		    if (i < my_poss_count-1) {
			if (i != easypossibilities-1) strcat(strg_out, SEP1);
			else                          strcat(strg_out, SEP2);
                    }
		    fprintf(ofile, "%s", strg_out);
		}
	    }
	    misses_out[i][0] = '\0';
	    if (!islib)
		fprintf(ofile, SEP4);
	}
	else if (!islib) {
	    /* No possibilities found for word TOKEN */
	    cab_pipe_resp(strg_out, '&', ctoken,
			  (int) ((currentchar - contextbufs[0]) - strlen(ctoken)));
	    if (!terse) {
		fprintf(ofile, "%s", strg_out);
		fprintf(ofile, SEP4);
	    }
	}
    }
    else if (!islib) {
	cab_pipe_resp(strg_out, '&', ctoken,
		      (int) ((currentchar - contextbufs[0]) - strlen(ctoken)));
	fprintf(ofile, "%s", strg_out);
	fprintf(ofile, SEP4);
    }
}


/*
 *
 */
char process_aflag(FILE *ofile, int ilen) {
    if (is_sign(itoken[0])) {
	treat_sign(ofile);
	return 0;   /* or should be 1 ??? */
    }
    if (ilen <= minword) {   /* length of Word makes it always legal */
	treat_minword(ofile);
	return 1;   /* continue; */
    }
    
    if (bgood(itoken, 0, 0, 0))
	treat_good(ofile);
    else
	if (compoundgood(itoken))
	    treat_compoundgood(ofile);
	else treat_not_good(ofile);
    return 0;   /* don't continue */
}

/*
 *
 */
void skip_ntroff_text_formaters(int hadlf, FILE *ofile) {
    if (!tflag) {     /* nroff/troff mode */
	/* skip over .if */
	if (*currentchar == NRDOT
	    && (strncmp(currentchar + 1, "if t", 4) == 0
		||  strncmp(currentchar + 1, "if n", 4) == 0)) {
	    copyout(&currentchar, 5);
	    while (*currentchar && myspace(chartoichar(*currentchar)))
		copyout(&currentchar, 1);
	}

	/* skip over .ds XX or .nr XX */
	if (*currentchar == NRDOT
	    && (strncmp(currentchar + 1, "ds ", 3) == 0
		||  strncmp(currentchar + 1, "de ", 3) == 0
		||  strncmp(currentchar + 1, "nr ", 3) == 0)) {
	    copyout(&currentchar, 4);
	    while (*currentchar && myspace(chartoichar(*currentchar)))
		copyout(&currentchar, 1);
	    while (*currentchar && !myspace(chartoichar(*currentchar)))
		copyout(&currentchar, 1);
	    if (*currentchar == 0) {         /* end of line */
		if (!islib && !lflag && (aflag || hadlf))
		    putc('\n', ofile);
		return;
	    }
	}
    }

    if (*currentchar == NRDOT &&  /* we don't wanna lose every dot */
	(*(currentchar+1) == '\0' || *(currentchar+1) == ' '))
	return;
    
    /* if this is a formatter command, skip over it */
    if (!tflag && *currentchar == NRDOT) {
	while (*currentchar && !myspace(chartoichar(*currentchar))) {
	    if (!aflag && !lflag)
		(void) putc(*currentchar, ofile);
	    currentchar++;
	}
	if (*currentchar == 0) {
	    if (!islib && !lflag && (aflag  ||  hadlf))
		putc('\n', ofile);
	    return;
	}
    }
}

/*
 *
 */
void checkline(FILE *ofile) {
    register char *p;
    register char *endp;
    int hadlf;        /* had linefeed */
    register int len;
    int ilen;

    if (islib) {
	sol_out[0][0] = '\0';
	misses_out[0][0] = '\0';
    }
    currentchar = contextbufs[0];
    len = strlen(contextbufs[0]) - 1;
    hadlf = contextbufs[0][len] == '\n';
    if (hadlf)
	contextbufs[0][len] = 0;

    skip_ntroff_text_formaters(hadlf, ofile);

    for (;;) {
	p = skiptoword(currentchar);
	if (p != currentchar)
	    copyout(&currentchar, p - currentchar);

	if (*currentchar == 0)
	    break;

	p = ctoken;
	endp = skipoverword(currentchar);
	while (currentchar < endp  &&  p < ctoken + sizeof ctoken - 1)
	    *p++ = *currentchar++;
	*p = 0;
	if (strtoichar(itoken, ctoken, INPUTWORDLEN * sizeof(ichar_t), 0))
	    fprintf(stderr, WORD_TOO_LONG(ctoken));
	ilen = icharlen(itoken);

	i_word_created = 0;   /* important to the -c,-l flag */
	/* the -c also activates the lflag */
	if (lflag) {   /* lflag - produce a list of misspelled words */
	    if (ilen > minword
		&& !bgood(itoken, 0, 0, 0)  &&  !cflag  &&  !compoundgood(itoken))
		fprintf(ofile, "%s\n", ctoken);
	    
	}
	else {
	    if (aflag) {      /* do not remove these brackets */
		if (process_aflag(ofile, ilen))
		    continue;
	    }
	    else {
		if (!quit) {
		    jcorrect(ctoken, itoken, &currentchar);
		}
	    }
	}
	if (!aflag && !lflag)
	    fprintf(ofile, "%s", ctoken);
    }
    
    if (!islib && !lflag && (aflag  ||  hadlf))
	putc('\n', ofile);
}

/**
 * buf - the buffer where the modifications will be made
 * start - points to the position in the buffer where we want the word to be replaced
 * tok - the new token (word) that will replace
 * curchar - the position in the buffer where the old word ends
 */
void replace_token(char *buf, char *start, register char *tok, char **curchar) {
    char copy[BUFSIZ];
    char *p, *q, *ew;
    
    strcpy(copy, buf);

    for (p = buf, q = copy; p != start; p++, q++)
	*p = *q;
    q += *curchar - start;   /* advance old word in buffer q */

    /* copy the new word to the desired postion in buf */
    ew = skipoverword(tok);    /* ew points to the position at the end of token */
    while (tok < ew)
      *p++ = *tok++;
    
    *curchar = p;
    
    if (*tok) {
	/* The token changed to two words.  Split it up and save the
	** second one for later.  */
	*p++ = *tok;
	*tok++ = '\0';
	while (*tok)
	    *p++ = *tok++;
    }
    
    /* copy the remaining of the buffer */
    while((*p++ = *q++))
	;
}


/*
 * this should give only root words
 */
ID_TYPE word_id(char *word, char *feats, int *status) {
    int old_cflag, old_lflag;
    ID_TYPE id;
    int i, n_eq, flen;
    char root1[INPUTWORDLEN];
    
    old_cflag = cflag;
    old_lflag = lflag;
    cflag = lflag = 0;
    strcpy(contextbufs[0], word);
    checkline(stdout);
    cflag = old_cflag;
    lflag = old_lflag;
    
    id = 0;
    n_eq = 0;
    flen = strlen(feats);

    for (i = 0; i < numhits; i++) {
	get_info(hits[i]);
	strcpy(root1, ichartosstr(strtosichar(macro(root), 1), 0));
	if (strcmp(root1, word) == 0 &&               /* root word matches */
	    strncmp(feats, macro(root_class), flen) == 0) {
	    if (n_eq == 0)
		/* printf("dictent=%p, hashtbl=%p subtraindo dá: %d sizeof=%d\n",
		   hits[i].dictent, hashtbl, hits[i].dictent - hashtbl, sizeof(struct dent)); */
		id = (ID_TYPE) (hits[i].dictent - hashtbl);
	    n_eq++;
	}
    }
    /* if (n_eq == 0)
       fprintf(stderr, "numhits=%d, hits[0]=%s, word=%s, root=%s, root1=%s\n",
       numhits, hits[0].dictent->word, word, root, root1);*/  /* DEBUG */
    *status = n_eq;
    return id;
}

char *word_f_id(ID_TYPE id) {
    struct dent *pd;
    static char root[INPUTWORDLEN];

    pd = hashtbl + id;
    /* printf("s=%s pos=%d\n", ichartosstr(s, 0), hash(s, hashsize));*/  /*DEB*/
    strcpy(root, pd->word);
    treat_caps(root, captype(pd->flagfield));
    return ichartosstr(strtosichar(macro(root), 1), 0);
}

char *class_f_id(ID_TYPE id) {
    struct dent *pd;
    static char jclass[MAXCLASS];

    pd = hashtbl + id;
    strcpy(jclass, macro(pd->jclass));
    return jclass;
}

#define MAXFLAGS 32
char *flags_f_id(ID_TYPE id) {
    int i, bit;
    struct dent *pd;
    static char flags[MAXFLAGS];

    pd = hashtbl + id;
    i = 0;
    for (bit = 0; bit < LARGESTFLAG && i < MAXFLAGS; bit++)
	if (TSTMASKBIT(pd->mask, bit))
	    flags[i++] = BITTOCHAR(bit);
    flags[i] = '\0';
    return flags;
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *\
 * Copyright 1999 and 2002 by Daniel Bump and the Free Software      *
 * Foundation.                                                       *
 *                                                                   *
 * This program is free software; you can redistribute it and/or     *
 * modify it under the terms of the GNU General Public License as    *
 * published by the Free Software Foundation - version 2             *
 *                                                                   *
 * This program is distributed in the hope that it will be useful,   *
 * but WITHOUT ANY WARRANTY; without even the implied warranty of    *
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the     *
 * GNU General Public License in file COPYING for more details.      *
 *                                                                   *
 * You should have received a copy of the GNU General Public         *
 * License along with this program; if not, write to the Free        *
 * Software Foundation, Inc., 59 Temple Place - Suite 330,           *
 * Boston, MA 02111, USA.                                            *
\* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

 /* This program contains code (including the original primitive sgf
  * parser) from GNU Go 2.0. It is similar in spirit to sgf2tex and
  * produces a metapost file from an sgf file.
  *
  * Metapost is included in most modern TeX distributions. It may
  * be called 'mpost' or 'mp'. Look for the manual, called 'mpman.ps'.
  *
  * USAGE: -i <inputfile> -o <outputfile> [other options]
  * 
  * The other options are described in the help string. They
  * allow you to control which moves are printed, which number
  * to start with, which portion of the board to print, which
  * TeX fonts to use. You can label stones or empty vertices
  * with letters, and you can label stones with triangle marks.
  * 
  * Running the outputfile through metapost creates an encapulated
  * postscript file. If the output file is called "<name>.mp" the
  * postscript file is called "<name>.1". This may be included in a TeX
  * document. Your tex file must include:
  *
  * \input epsf
  *
  * After this, include the diagram with \epsffile{[filename].1}.
  *
  */

 /* Available TeX fonts are described in Knuth, "Computer Modern Typefaces" */

#define VERSION "1.0"

#define DEFAULT_FONT "cmssbx10"     /* default font for numerals */
#define BIGNUMBER_FONT "cmr10"       /* font for numbers > 99     */
#define ITALIC_FONT "cmbxti10"      /* font for letters          */

#include <string.h>
#include <stdlib.h>
#include <stdarg.h>
#include <unistd.h>
#include <stdio.h>
#include <assert.h>

#define DEBUG(fmt, args...)  do { if (debug) gprintf(fmt, ##args); } \
                                    while(0)
#define OTHER_COLOR(color)  (WHITE+BLACK-(color))
#define MAX_BOARD 19         /* maximum supported board size        */
#define MAX_LABELS 26

int debug = 0;
int board_size = 19;
int movenum = 1;
int new_number = 0; /* start numbering at 0 */
int left_column = 1;
int right_column = 19;
int top_row = 19;
int bottom_row = 1;
char fontstring[16];
char italfontstring[16];
char bignumberstring[16];
float scale = 1.;

int p[MAX_BOARD][MAX_BOARD];
int plast[MAX_BOARD][MAX_BOARD];
int black_captured, white_captured;
int board_image[MAX_BOARD][MAX_BOARD];
int label[MAX_BOARD][MAX_BOARD];

#define EMPTY 0
#define WHITE 1
#define BLACK 2
#define TRIANGLE 3

#define PROLOG "path a, b;\n\
a = fullcircle scaled sx;\n\
b = (0*sx, .45*sx)--(.39*sx, -.225*sx)--(-.39*sx,-.225*sx)--cycle;\n\
\n\
def whitestone(expr n, m, k) =\n\
begingroup;\n\
fill a shifted (n*z1+m*z2) withcolor white;\n\
label(k, n*z1+m*z2) withcolor black;\n\
draw a shifted (n*z1+m*z2);\n\
endgroup;\n\
enddef;\n\
\n\
vardef blackstone(expr n, m, k) =\n\
begingroup;\n\
fill a shifted (n*z1+m*z2) withcolor black;\n\
label(k, n*z1+m*z2) withcolor white;\n\
endgroup;\n\
enddef;\n\
\n\
vardef triangleblackstone(expr n, m) =\n\
begingroup;\n\
fill a shifted (n*z1+m*z2) withcolor black;\n\
draw b shifted (n*z1+m*z2) withcolor white;\n\
endgroup;\n\
enddef;\n\
\n\
vardef trianglewhitestone(expr n, m) =\n\
begingroup;\n\
fill a shifted (n*z1+m*z2) withcolor white;\n\
draw b shifted (n*z1+m*z2) withcolor black;\n\
endgroup;\n\
enddef;\n\
\n\
beginfig(1);\n\
z0=(0,0);\n\
z1=(sx,0);\n\
z2=(0,sy);\n"

#define HELP "-i <input file>\n\
-o <output file>\n\
-s <start move>       first NUMBERED move number or board location\n\
-e <end move>         last move number or board location displayed\n\
-n <num>              first numbered stone gets this numeral\n\
-l <left column>      limit portion of board printed\n\
-r <right column>\n\
-t <top row>\n\
-b <bottom row>\n\
-L <location>:<label> (e.g. -L a:K3) mark the location with this label\n\
-T <location>         mark this stone with a triangle\n\
-S <scale factor>     scaling factor (default 1.0\n\
-F <font name>        (e.g. \"cmr8\") TeX font for numbers\n\
-I <font name>        (e.g. \"cmti8\") TeX font for letters\n\
-B <font name>        TeX font for numbers > 99\n\
-h                    print this message\n\
-d                    print debugging traces\n\
-v                    print version\n\
\n\
If the output file is called <name>.mp, run metapost on it to get\n\
an encapsulated postscript file called <name>.1.\n\
*** Messages beginning with three asterisks require attention.\n"

int load_sgf(FILE *input, FILE *outfile, char *fromstr, char *untilstr);
int check_for_capture(int m, int n, int color);
void gprintf(const char *fmt, ...);
void sethand(int h);
void updateboard(int i, int j, int color);

int
main (int argc, char **argv)
{
  char *infilename = NULL;
  char *outfilename = NULL;
  char *untilstring = NULL;
  char *fromstring = NULL;
  char *labelstring = NULL;
  int c, index;
  int i, j;
  FILE *sgffile, *mpfile;

  memset(p, 0, sizeof(p));
  memset(label, 0, sizeof(label));
  memset(board_image, 0, sizeof(board_image));
  opterr = 0;
  strcpy(fontstring, DEFAULT_FONT);
  strcpy(italfontstring, ITALIC_FONT);
  strcpy(bignumberstring, BIGNUMBER_FONT);
  
  while ((c = getopt (argc, argv, "b:B:de:F:hi:I:l:L:n:o:r:s:S:t:T:v")) != -1)
    switch (c) {

    case 'i':
      infilename = optarg;
      break;

    case 'o':
      outfilename = optarg;
      break;

    case 's':
      fromstring = optarg;
      break;

    case 'e':
      untilstring = optarg;
      break;

    case 'F':
      strcpy(fontstring, optarg);
      break;

    case 'I':
      strcpy(italfontstring, optarg);
      break;

    case 'B':
      strcpy(bignumberstring, optarg);
      break;

    case 'n': 
      new_number = atoi(optarg);
      break;

    case 'l':
      left_column = atoi(optarg);
      break;

    case 'r':
      right_column = atoi(optarg);
      break;

    case 'b':
      bottom_row = atoi(optarg);
      break;

    case 't':
      top_row = atoi(optarg);
      break;

    case 'd':
      debug = 1;
      break;

    case 'h':
      fprintf(stderr, HELP);
      return 0;

    case 'L':
      {
	char this_label;
	int li, lj;

	labelstring = optarg;      
	this_label = *labelstring;
	labelstring++;
	labelstring++;
	lj = *labelstring - 'A';
	if (*labelstring >= 'I')
	  --lj;
	li = board_size - atoi(labelstring+1);
	label[li][lj] = this_label;
      }
      break;

    case 'T':
      {
	int li, lj;

	labelstring = optarg;
	lj = *labelstring - 'A';
	if (*labelstring >= 'I')
	  --lj;
	li = board_size - atoi(labelstring+1);

	label[li][lj] = -TRIANGLE;
      }
      break;

    case 'S':
      scale = atof(optarg);
      break;

    case 'v':
      fprintf(stderr, "Version %s\n", VERSION);
      return 0;

    case '?':
      if (isprint (optopt))
	fprintf (stderr, "Unknown option `-%c'.\n", optopt);
      else
          fprintf (stderr,
                   "Unknown option character `\\x%x'.\n",
                   optopt);
      fprintf(stderr, HELP);
      return 1;
    default:
      abort ();
    }
  if (!infilename) {
    fprintf(stderr, "sgf2mpost: no input filename given\n");
    fprintf(stderr, HELP);
    return;
  }
  
  if (strcmp(outfilename, "-") == 0) 
    mpfile = stdout;
  else
    mpfile = fopen(outfilename, "w");
  if (!mpfile) {
    fprintf(stderr, "Can not open %s\n", outfilename);
    return;
  }

  sgffile = fopen(infilename, "r");

  load_sgf(sgffile, mpfile, fromstring, untilstring);
  if (!sgffile || fclose(sgffile))
    fprintf(stderr, "unable to close sgf file\n");
  if (!mpfile || fclose(mpfile))
    fprintf(stderr, "unable to close mp file\n");

  return 0;
}

int 
load_sgf(FILE *input, FILE *outfile, char *fromstr, char *untilstr)
{
  /* use a simple state engine : 
  * 0 = skipping junk, looking for ';' or 'H'
  * 1 = seen ';'  - looking for A or B/W.
  * 2 = seen B/W, looking for [
  * 3 = skip until ], then return to 1  
  *       (eg for PW, see P, skip to the ],  then state 1)
  * 4 = seen 'H', looking for A
  * 5 = seen 'S', looking for Z
  * 6 = seen 'A', looking for B or W
  * 7 = seen 'AB' or 'AW', adding stones
  * 8 = seen '[' while adding stones
  */

  int state = 0;
  float ll, rr, tt, bb;
  int bigfonts = 0;

  /* if we see AB[], we need to return to state 1, else state 0 */
  int nextstate = 0;  
  int color = 0;
  int c, n, m, i, j;
  int k;
  
  int untilm = -1, untiln = -1;
  int until = 9999;
  int from_m = -1, from_n = -1;
  int from = 1;
  int numbering = 0;

  if (movenum <= 99)
    fprintf(outfile, "defaultfont:=\"%s\";\n", fontstring);
  else {
    fprintf(outfile, "defaultfont:=\"%s\";\n", bignumberstring);
    bigfonts = 1;
  }

  if (!input) {
    perror("Cannot open sgf file");
    return 1;
  }
  
 reparse_untilstr:
  
  if (fromstr) {
    if (*fromstr > '0' && *fromstr <= '9') {
      from = atoi(fromstr);
      DEBUG("Loading from move %d\n", from);
    }
    else {
      from_n = *fromstr - 'A';
      if (*fromstr >= 'I')
	--from_n;

      from_m = board_size - atoi(fromstr+1);
      DEBUG("Loading from move at %d,%d (%m)\n", 
	    from_m, from_n, from_m, from_n);
    }
  }
  if (untilstr) {
    if (*untilstr > '0' && *untilstr <= '9') {
      until = atoi(untilstr);
      DEBUG("Loading until move %d\n", until);
    }
    else {
      untiln = *untilstr - 'A';
      if (*untilstr >= 'I')
	--untiln;
      untilm = board_size - atoi(untilstr+1);
      DEBUG("Loading until move at %d,%d (%m)\n", 
	    untilm, untiln, untilm, untiln);
    }
  }

  while ((c = getc(input)) != EOF) {
    if (0)
      gprintf("%c", c);

    switch (state) {

    case 0:
      if (c == ';') 
	state = 1;
      if (c == 'H') 
	state = 4;
      if (c == 'S') 
	state = 5;
      if (c == 'A') 
	state = 6;
      break;
      
    case 1:
      if ('A' <= c && c <= 'Z') {
	if (c == 'A') state = 6;
	else if (c == 'H') state = 4;
	else if (c == 'S') state = 5;
	else if (c == 'A') state = 6;
	else if (c == 'B' || c == 'W') {
	  if (c == 'B') color = BLACK;
	  if (c == 'W') color = WHITE;
	  state = 2;
	}
	else state = 3;
      }
      break;

    case 2:
      if (c == 'L') 
	state = 0;
      else if (c == '[') {
	n = getc(input)-'a';
	m = getc(input)-'a';
	getc(input);
	
	DEBUG("load_sgf : Adding [%c%c] = %m\n", 'a'+n, 'a'+m, m, n);
	if (!numbering
	    && movenum >= from || (m == from_m && n == from_n)) {
	  if (left_column <= 1)
	    ll = 0.;
	  else
	    ll = (float) left_column-1.5;
	  if (right_column >= board_size)
	    rr = (float) board_size-1.;
	  else
	    rr = right_column-0.5;
	  if (bottom_row <= 1)
	    bb = 0.;
	  else
	    bb = (float) bottom_row-1.5;
	  if (top_row >= board_size)
	    tt = (float) board_size-1.;
	  else
	    tt = top_row-0.5;

	  DEBUG("Move specified by from reached\n");
	  fprintf(outfile, "sx:=%.2f*17; sy:=%.2f*19;\n", scale, scale);
	  fprintf(outfile, PROLOG, VERSION);
	  /* mark hoshi points */
	  if (board_size == 19 || board_size == 13) {
	    fprintf(outfile, "pickup pencircle scaled 2.5;\n");
	    if (left_column-1 <= 3
		&& right_column-1 >= 3
		&& bottom_row-1 <= 3
		&& top_row-1 >= 3)
	      fprintf(outfile, "drawdot z0+3*z1+3*z2;\n");
	    if (left_column-1 <= 3
		&& right_column-1 >= 3
		&& bottom_row-1 <= 9
		&& top_row-1 >= 9)
	      fprintf(outfile, "drawdot z0+3*z1+9*z2;\n");
	    if (left_column-1 <= 3
		&& right_column-1 >= 3
		&& bottom_row-1 <= 15
		&& top_row-1 >= 15)
	      fprintf(outfile, "drawdot z0+3*z1+15*z2;\n");
	    if (left_column-1 <= 9
		&& right_column-1 >= 9
		&& bottom_row-1 <= 3
		&& top_row-1 >= 3)
	      fprintf(outfile, "drawdot z0+9*z1+3*z2;\n");
	    if (left_column-1 <= 9
		&& right_column-1 >= 9
		&& bottom_row-1 <= 9
		&& top_row-1 >= 9)
	      fprintf(outfile, "drawdot z0+9*z1+9*z2;\n");
	    if (left_column-1 <= 9
		&& right_column-1 >= 9
		&& bottom_row-1 <= 15
		&& top_row-1 >= 15)
	      fprintf(outfile, "drawdot z0+9*z1+15*z2;\n");
	    if (left_column-1 <= 15
		&& right_column-1 >= 15
		&& bottom_row-1 <= 3
		&& top_row-1 >= 3)
	      fprintf(outfile, "drawdot z0+15*z1+3*z2;\n");
	    if (left_column-1 <= 15
		&& right_column-1 >= 15
		&& bottom_row-1 <= 9
		&& top_row-1 >= 9)
	      fprintf(outfile, "drawdot z0+15*z1+9*z2;\n");
	    if (left_column-1 <= 15
		&& right_column-1 >= 15
		&& bottom_row-1 <= 15
		&& top_row-1 >= 15)
	      fprintf(outfile, "drawdot z0+15*z1+15*z2;\n");
	  }
	  fprintf(outfile, "pickup pencircle scaled 1;\n");
	  /* draw horizontal lines */
	  fprintf(outfile, "for i=%d upto %d:\n", bottom_row-1, top_row-1);
	  fprintf(outfile, "draw z0+%.1f*z1+i*z2--z0+%.1f*z1+i*z2;\nendfor;\n",
		  ll, rr);
	  /* draw vertical lines */
	  fprintf(outfile, "for i=%d upto %d:\n", left_column-1, right_column-1);
	  fprintf(outfile, "draw z0+%.1f*z2+i*z1--z0+%.1f*z2+i*z1;\nendfor;\n",
		  bb, tt);
	  /* draw edges */
	  fprintf(outfile, "pickup pencircle scaled 1.5;\n");
	  if (left_column <= 1)
	    fprintf(outfile, "draw z0+%.1f*z2--z0+%.1f*z2;\n", bb, tt);
	  if (right_column >= board_size)
	    fprintf(outfile, "draw z0+%.1f*z2+%d*z1--z0+%.1f*z2+%d*z1;\n", 
		    bb, board_size-1, tt, board_size-1);
	  if (bottom_row <= 1)
	    fprintf(outfile, "draw z0+%.1f*z1--z0+%.1f*z1;\n", ll, rr);
	  if (top_row >= board_size)
	    fprintf(outfile, "draw z0+%.1f*z1+%d*z2--z0+%.1f*z1+%d*z2;\n", 
		    ll, board_size-1, rr, board_size-1);
	  fprintf(outfile, "pickup pencircle scaled 1;\n");
	  
	  numbering = 1;
	  for (i = 0; i < board_size; i++)
	    for (j = 0; j < board_size; j++) {
	      if (i <= board_size-bottom_row 
		  && i >= board_size-top_row
		  && j <= right_column-1
		  && j >= left_column-1) {
		if (p[i][j] == BLACK) {
		  if (label[i][j] == -TRIANGLE) {
		    fprintf(outfile, "triangleblackstone(%d, %d);\n", 
			    j, board_size-1-i);
		    board_image[i][j] = -TRIANGLE;
		  }
		  else {
		    fprintf(outfile, "blackstone(%d, %d, \"\");\n", 
			    j, board_size-1-i);
		    board_image[i][j] = -BLACK;
		  }
		}
		else if (p[i][j] == WHITE) {
		  if (label[i][j] == -TRIANGLE) {
		    fprintf(outfile, "trianglewhitestone(%d, %d);\n", 
			    j, board_size-1-i);
		    board_image[i][j] = -TRIANGLE;
		  }
		  else {
		    fprintf(outfile, "whitestone(%d, %d, \"\");\n", 
			    j, board_size-1-i);
		    board_image[i][j] = -WHITE;
		  }
		}
	      }
	    }
	}
	if (n < board_size && m < board_size)
	  updateboard(m, n, color);
	if (numbering) {
	  if (m <= board_size-bottom_row 
	      && m >= board_size-top_row
	      && n <= right_column-1
	      && n >= left_column-1) {
	    if (board_image[m][n] != 0) {
	      if (board_image[m][n] > 0)
		gprintf("*** %d at %d\n", movenum, board_image[m][n]);
	      else {
		if (label[m][n] > 0)
		  gprintf("*** %d at %c\n", movenum, label[m][n]);
		else 
		  gprintf("*** %d at %m\n", movenum, m, n);
	      }
	    }
	    else {
	      board_image[m][n] = movenum;
	      if ((new_number > 99 || (new_number == 0 && movenum > 99))
		  && !bigfonts) {
		fprintf(outfile, "defaultfont:=\"%s\";\n", bignumberstring);
		bigfonts = 1;
	      }
	      if (p[m][n] == BLACK)
		fprintf(outfile, "blackstone(%d, %d, \"%d\");\n", 
			n, board_size-1-m, new_number ? new_number : movenum);
	      else if (p[m][n] == WHITE)
		fprintf(outfile, "whitestone(%d, %d, \"%d\");\n", 
			n, board_size-1-m, new_number ? new_number : movenum);
	    }
	  }
	  else {
	    if ((m == board_size && n == board_size)
		|| (m == 19 && n == 19))
	      fprintf(stderr, "*** PASS at %d\n", movenum);
	    else 
	      gprintf("*** %m outside limits of displayed board at move %d\n",
		      m, n, movenum);
	  }
	}
	if (movenum == until || (m == untilm && n == untiln)) {
	  DEBUG("Move specified by until reached\n");
	  goto the_end;
	}
	movenum++;
	if (new_number && numbering)
	  new_number++;
	state = 0;
      }
      else {
	fprintf(stderr,
		"analyze: error parsing sgf file - state = 2, (c = '%c'\n", c);
	return 1;
      }
      break;
      
    case 3:
      if (c == ']') state = 1;
      break;
      
    case 4:
      if (c == 'A') {
	if ((c = getc(input)) != '[') {
	  fprintf(stderr,"error parsing sgf file - state = 4, c = '%c'\n", c);
	  abort();
	}
	n = getc(input)-'0'; /* handicap game */
	DEBUG("load_sgf : Handicap %d\n", n);
	sethand(n);
      }
      state = 0;
      break;

    case 5:
      if (c == 'Z') {
	if ((c = getc(input)) != '[') {
	  fprintf(stderr,"error parsing sgf file - state = 4, c = '%c'\n", c);
	  abort();
	}
	n = getc(input)-'0';
	if (n == 1)
	  n = 10 + getc(input)-'0';
	board_size = n;
	DEBUG("load_sgf : Board size %d\n", n);
	/* an "until" move was parsed assuming board size 19. Reparse */
	if (top_row == 19)
	  top_row = board_size;
	if (right_column == 19)
	  right_column = board_size;

	state = 3;
	goto reparse_untilstr;  /* crude, but effective ! */
      }
      state = 0;
      break;

    case 6:
      if (c == 'B') {
	color = BLACK;
	state = 7;
      }
      else if (c == 'W') {
	color = WHITE;
	state = 7;
      }
      else state = 1;
      break;

    case 7:
      if ('A' <= c && c <= 'Z') {
	if (c == 'A')
	  state = 6;
	else
	  state = 3;
      }
      else if (c == ';')
	state = 1;
      else if (c == '[')
	state = 8;
      else state = 0;
      break;
      
    case 8:
      n = c-'a';
      m = getc(input)-'a';
	
      DEBUG("load_sgf : Adding [%c%c] = %m\n", 'a'+n, 'a'+m, m, n);
      p[m][n] = color;
      c = getc(input);
      c = getc(input);
      if (c == '[')
	state = 8;
      else if (c == ';')
	state = 1;
      else state = 0;
      break;
    }
  }

 the_end:
  /* Now print the labels */
  fprintf(outfile, "defaultfont:=\"%s\";\n", italfontstring);
  for (m = 0; m < board_size; m++)
    for (n = 0; n < board_size; n++)
      if (label[m][n] > 0) {
	if (board_image[m][n] > 0)
	  gprintf("*** attempt to label a numbered position at %m\n", m, n);
	else {
	  if (board_image[m][n] == -BLACK) {
	    DEBUG("label %c at (%d,%d)\n", label[m][n], m, n);
	    fprintf(outfile, 
		    "label (\"%c\", %d*z1+%d*z2) withcolor white;\n",
		    label[m][n], n, board_size-1-m);
	  }
	  else {
	    DEBUG("label %c at (%d,%d)\n", label[m][n], m, n);
	    if (board_image[m][n] != -WHITE)
	      fprintf(outfile, "fill a shifted (%d*z1+%d*z2) withcolor white;\n",
		      n, board_size-1-m);
	    fprintf(outfile, "label (\"%c\", %d*z1+%d*z2);\n",
		    label[m][n], n, board_size-1-m);
	  }
	}
      }
  fprintf(outfile, "endfig;\nend;\n");
  DEBUG("End of load_sgf\n\n\n");
  return 0;
}


/*
 * Place a "color" on the board at i,j, and remove
 * any captured stones.
 */

void updateboard(int i, int j, int color)
{
  int other = OTHER_COLOR(color);

  assert(i >= 0 && i < board_size && j >= 0 && j < board_size);
  if (p[i][j] != EMPTY) {
    gprintf("Stone overlay problem at %m!\n", i, j);
    gprintf("Try reducing the move range with -s and -e.\n");
    abort();
  }

  p[i][j] = color;

  if (1)
    DEBUG("Update board : %m = %d\n", i,j, color);

  if (i > 0 && p[i-1][j] == other)
    check_for_capture(i-1, j, other);
  if (i < board_size-1 && p[i+1][j] == other)
    check_for_capture(i+1, j, other);
  if (j > 0 && p[i][j-1] == other)
    check_for_capture(i, j-1, other);
  if (j < board_size-1 && p[i][j+1] == other)
    check_for_capture(i, j+1, other);

}

/* if string at m,n has no liberties, remove it from
 * the board. Return the number of stones captured.
 */

int check_for_capture(int m, int n, int color)
{
  char mx[MAX_BOARD][MAX_BOARD];
  int i,j;
  int finished = 0;
  int captured = 0;

  assert(p[m][n] == color);
  memset(mx, 0, sizeof(mx));
  
  /* mark the string: look for unmarked elements. We are
   * finished when we can't find any. If we notice a liberty,
   */
  mx[m][n] = 1;
  finished = 0;
  while (!finished) {
    finished = 1;
    for (i = 0; i < board_size; ++i)
      for (j = 0; j < board_size; ++j)
	if (p[i][j] == color && !mx[i][j])
	  if (i > 0 && mx[i-1][j]
	      || i < board_size-1 && mx[i+1][j]
	      || j > 0 && mx[i][j-1]
	      || j < board_size-1 && mx[i][j+1]) {
	    finished = 0;
	    mx[i][j] = 1;
	  }
  }
  /* Now see if there's a liberty. */
  for (i = 0; i < board_size; ++i)
    for (j = 0; j < board_size; ++j)
      if (p[i][j] == EMPTY)
	if (i > 0 && mx[i-1][j]
	    || i < board_size-1 && mx[i+1][j]
	    || j > 0 && mx[i][j-1]
	    || j < board_size-1 && mx[i][j+1])
	  return 0;
  /* No liberty. Remove it. */
  for (i = 0; i < board_size; ++i)
    for (j = 0; j < board_size; ++j)
      if (mx[i][j]) {
	assert(p[i][j] == color);
	p[i][j] = EMPTY;
	captured++;
      }
  DEBUG("Checking %m captures %d stones at move %d\n", m, n, captured, movenum);
  return captured;
}

/* From GNU Go.
 *
 * Accepts %c, %d and %s as usual. But it
 * also accepts %m, which takes TWO integers and writes a move
 * Nasty bodge : %o at start means outdent (ie cancel indent)
 */

static void 
vgprintf(const char *fmt, va_list ap)
{
  if (fmt[0] == '%' && fmt[1] == 'o')
    fmt +=2;  /* cancel indent */
  for ( ; *fmt ; ++fmt ) {
    if (*fmt == '%') {
      switch (*++fmt) {
      case 'c':
      {
	/* rules of promotion => passed as int, not char */
	int c = va_arg(ap, int);  
	putc(c, stderr);
	break;
      }
      case 'd':
      {
	int d = va_arg(ap, int);
	fprintf(stderr, "%d", d);
	break;
      }
      case 's':
      {
	char *s = va_arg(ap, char*);
	assert( (int)s >= board_size );  /* in case %s used in place of %m */
	fputs(s, stderr);
	break;
      }
      case 'm':
      {
	char movename[4];
	int m = va_arg(ap, int);
	int n = va_arg(ap, int);
	if ((m == board_size && n == board_size)
	    || (m == 19 && n == 19)) {
	  fprintf(stderr, "PASS");
	  break;
	}
	assert(m < board_size && n < board_size);
	if (m < 0 || n < 0)
	  fputs("??",stderr);
	else {                       /* generate the move name */
	  if (n < 8)
	    movename[0] = n + 65;
	  else
	    movename[0] = n + 66;
	  sprintf(movename + 1, "%d", board_size - m);
	}
	fputs(movename, stderr);
	break;
      }
      default:
	fprintf(stderr, "\n\nUnknown format character '%c'\n", *fmt);
	break;
      }
    }
    else
      putc(*fmt, stderr);
  }
}



/* required wrapper around vgprintf */
void 
gprintf(const char *fmt, ...)
{
  va_list ap;
  va_start(ap, fmt);
  vgprintf(fmt, ap);
  va_end(ap);
}

/* set handicap stones */

static const int places[][2] = {

  {2,-2}, {-2,2}, {2,2}, {-2,-2},  /* first 4 are easy */
                                   /* for 5, {0,0} is explicitly placed */
  {0,2},  {0,-2},                  /* for 6 these two are placed */
                                   /* for 7, {0,0} is explicitly placed */
  {2,0}, {-2,0},                   /* for 8, these two are placed */
  {0,0},                           /* plain sailing after here for 9 onwards */
  {1,-1}, {-1,1}, {1,1}, {-1,-1},
  {-5,5}, {5,-5}, {5,5}, {-5,-5}

};


void
sethand(int h)
/* set up handicap pieces */
{
  int x;

  int three = board_size > 9 ? 3 : 2;
  int mid = board_size/2;

  /* special-case 5 and 7 */

  if (h == 5 || h == 7) {
    p[mid][mid] = BLACK;
    h--;
  }

  for (x = 0; x < h; ++x) {
    int i = places[x][0];
    int j = places[x][1];

    /* translate the encoded values to board co-ordinates */

    if (i == 2) i = three; /* 2 or 3 */
    if (i == -2) i = -three;

    if (j == 2) j = three;
    if (j == -2) j = -three;

    if (i == 0) i = mid;
    if (j == 0) j = mid;

    if ( i < 0) i += board_size-1;
    if ( j < 0) j += board_size-1;

    p[i][j] = BLACK;
  }
}



/*
 * Local Variables:
 * tab-width: 8
 * c-basic-offset: 2
 * End:
 */

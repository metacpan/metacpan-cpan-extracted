#include <unistd.h>
#include <string.h>
#include <ctype.h>
#include <stdio.h>
#include "jsconfig.h"
#include "jspell.h"
#include "proto.h"
#include "msgs.h"
#include "defmt.h"
#include "good.h"
/* this #define is necessay to term.h */
#define MAIN2

#include "myterm.h"


static char *input(int l, int c, char *st_out, char *st, int max);
static char *jgetline(int l, int c, register char *s, int max);

/*---------------------------------------------------------------------------*/
/*---------------------------------------------------------------------------*/

void givehelp()
{
#ifdef COMMANDFORSPACE
   char ch;
#endif

#ifndef NOCURSES
   erase();
#endif
   printhelp(stdout);

   fprintf(stdout, "\r\n\r\n");
   fprintf(stdout, CORR_C_HELP_TYPE_SPACE);
   fflush(stdout);
#ifdef COMMANDFORSPACE
   ch = GETKEYSTROKE();
   if (ch != ' ' && ch != '\n' && ch != '\r')
      ungetc(ch, stdin);
#else
   while (GETKEYSTROKE() != ' ')
       ;
#endif
}

/*---------------------------------------------------------------------------*/
/*---------------------------------------------------------------------------*/

#ifdef REGEX_LOOKUP
static void regex_dict_lookup(char *cmd, char *grepstr)
{
   char *rval;
   int whence = 0;
   int quitlookup = 0;
   int count = 0;
   int ch;

   sprintf(cmd, "^%s$", grepstr);
   while (!quitlookup  &&  (rval = do_regex_lookup(cmd, whence)) != NULL) {
      whence = 1;
      printf("%s\r\n", rval);;
      if ((++count % (li - 1)) == 0) {
         inverse();
         printf(CORR_C_MORE_PROMPT);
         normal();
         fflush(stdout);
         if ((ch = GETKEYSTROKE()) == 'q'
             ||  ch == 'Q'  ||  ch == 'x'  ||  ch == 'X' )
             quitlookup = 1;
         /*
          * The following line should blank out the -- more -- even on
          * magic-cookie terminals.
          */
         printf(CORR_C_BLANK_MORE);
         fflush(stdout);
      }
   }
   if (rval == NULL) {
      inverse();
      printf(CORR_C_END_LOOK);
      normal();
      fflush(stdout);
      GETKEYSTROKE();
   }
}

#endif /* REGEX_LOOKUP */

/*---------------------------------------------------------------------------*/

static void lookharder(char *string)
{
   char cmd[150], grepstr[100];
   register char *g, *s;
#ifndef REGEX_LOOKUP
   register int wild = 0;
#ifdef LOOK
   static int look = -1;
#endif /* LOOK */
#endif /* REGEX_LOOKUP */

   g = grepstr;
   for (s = string; *s != '\0'; s++) {
      if (*s == '*') {
#ifndef REGEX_LOOKUP
         wild++;
#endif /* REGEX_LOOKUP */
         *g++ = '.';
         *g++ = '*';
      }
      else
         *g++ = *s;
   }
   *g = '\0';
   if (grepstr[0]) {
#ifdef REGEX_LOOKUP
      regex_dict_lookup(cmd, grepstr);
#else /* REGEX_LOOKUP */
#ifdef LOOK
      /* now supports automatic use of look - gms */
      if (!wild && look) {
         /* no wild and look(1) is possibly available */
         sprintf(cmd, "%s %s %s", LOOK, grepstr, WORDS);
         if (shellescape(cmd))
            return;
         else
            look = 0;
      }
#endif /* LOOK */
      /* string has wild card chars or look not avail */
      if (!wild)
         strcat(grepstr, ".*");        /* work like look */
      sprintf(cmd, "%s ^%s$ %s", EGREPCMD, grepstr, WORDS);
      shellescape(cmd);
#endif /* REGEX_LOOKUP */
   }
}

/*---------------------------------------------------------------------------*/
/*---------------------------------------------------------------------------*/

void escr_ini(char *strg)
{
#ifndef NOCURSES
   move(li - 1, 0);
#endif
   printf("%s", strg);
   fflush(stdout);
}

/*---------------------------------------------------------------------------*/

int show_menu(char solutions[MAXPOSSIBLE][MAXSOLLEN], char in_dic[MAXPOSSIBLE])
{
#ifndef NOCURSES
   int i, l, c = 0;
   int option;
   char ch;

   l = 3 + contextsize;
   i = 0;
   move(l, c);
   printf(CORR_C_NO_OPT);
   while (solutions[i][0] != '\0') {

      move(l + 1 + i, c);
      if (in_dic[i]) putchar('*');
      else putchar(' ');
      printf(" %d-%s", i+1, solutions[i]);
      i++;
   }
   if (i < easypossibilities)
      /* Remove garbage that is in the screen */
      while (i < easypossibilities && l + 1 + i < li) {
         move(l + 1 + i, c);
         erase_EOL();
         i++;
      }
   escr_ini("Option: ");

   ch = (GETKEYSTROKE() & NOPARITY);
   if (ch == '!')
      option = -1;
   else if (ch == '0') option = 0;
   else {
      option = ch - '0';
      if (i >= 10) {
         putchar(ch); fflush(stdout);
         ch = (GETKEYSTROKE() & NOPARITY);
         if (ch >= '0' && ch <= '9')   /* valid number */
            option = option * 10 + (ch - '0');
      }
   }

   escr_ini("                                          ");
   return option;
#endif
}

/*---------------------------------------------------------------------------*/

char ask_class_flag(char *word, char *sclass, char *sflag, char *scomm, char **curchar)
{
   char solutions[MAXPOSSIBLE][MAXSOLLEN];
   char in_dic[MAXPOSSIBLE];
   int old_showflags;
   char sol;
   char   auxcontextbufs[BUFSIZ]; /* Context of current line */
   char   *auxcurtchar;        /* Location in contextbufs */

   old_showflags = showflags;
   showflags = 1;

   strcpy(auxcontextbufs, contextbufs[0]);
   auxcurtchar = *curchar;
   get_roots(word, solutions, in_dic);
   strcpy(contextbufs[0], auxcontextbufs);
   *curchar = auxcurtchar;

   showflags = old_showflags;
   if (solutions[0][0] == '\0')
      sol = 0;
   else {
      sol = show_menu(solutions, in_dic);
      if (sol == -1) return 0;
   }
   sclass[0] = sflag[0] = scomm[0] = '\0';
   if (sol == 0) {
      input(li-1, 0, "Class: ", sclass, MAXCLASS-1);
      escr_ini("                                                            ");

      input(li-1, 0, "Flags: ", sflag, 40-1);
      escr_ini("                                          ");

      input(li-1, 0, "Comment: ", scomm, MAXCLASS-1);
      escr_ini("                                                            ");
   }
   else {
      strcpy(word, sep_sol[sol-1].root);
      strcpy(sclass, sep_sol[sol-1].root_class);
      strcpy(sflag, sep_sol[sol-1].flag);
      scomm[0] = '\0';
   }
   return 1;
}

/*---------------------------------------------------------------------------*/

int dic_insert(char *ctok, ichar_t *itok, int put_lower, char **curchar)
{
   char aux[MAXSOLLEN], sclass[MAXCLASS], sflag[40], scomm[MAXCLASS], fg;
   char word[MAXSOLLEN];
   int res;
   char   auxcontextbufs[BUFSIZ]; /* Context of current line */
   char   *auxcurtchar;        /* Location in contextbufs */
   char    auxctoken[MAXWLEN]; /* necessary for not changing original text when inserting */

   strcpy(auxctoken, ctok);    /* because ctok is modified in ask_class_flag */
   if (ask_class_flag(ctok, sclass, sflag, scomm, curchar)) {
      fg = hashheader.flagmarker;
      if (put_lower) {
         itok = strtosichar(ctok, 0);
         lowcase(itok);
         strcpy(word, ichartosstr(itok, 1));
      }
      else strcpy(word, ichartosstr(strtosichar(ctok, 0), 1));
      sprintf(aux, "%s%c%s%c%s%c%s", word, fg, sclass, fg, sflag, fg, scomm);

      strcpy(auxcontextbufs, contextbufs[0]);
      auxcurtchar = *curchar;

      treeinsert(aux, ICHARTOSSTR_SIZE, 1);

      strcpy(contextbufs[0], auxcontextbufs);
      *curchar = auxcurtchar;

      changes = 1;
      res = 1;
   }
   else res = 0;
   strcpy(ctok, auxctoken);
#ifndef NOCURSES
   clear();
#endif
   fflush(stdout);
   return res;
}

/*---------------------------------------------------------------------------*/

void show_possibilities(int col_ht)
{
#ifndef NOCURSES
   int i;

   for (i = 0; i < pcount; i++) {
#ifdef BOTTOMCONTEXT
      move(2 + (i % col_ht), (maxposslen + 8) * (i / col_ht));
#else /* BOTTOMCONTEXT */
      move(3 + contextsize + (i % col_ht), (maxposslen + 8) * (i / col_ht));
#endif /* BOTTOMCONTEXT */
      if (i >= easypossibilities)
         printf("??: %s", possibilities[i]);
      else if (easypossibilities >= 10  &&  i < 10)
          printf("0%d: %s", i, possibilities[i]);
      else
         printf("%2d: %s", i, possibilities[i]);
   }
#endif
}

/*---------------------------------------------------------------------------*/

static int show_char(register char **cp, int linew, int output)
/* output - NZ to actually do output */
{
   register int ch, i, width;
   int len;
   ichar_t ichar;

   ch = **cp;
   if (l1_isstringch(*cp, len, 0))
      ichar = SET_SIZE + laststringch;
   else
      ichar = chartoichar(ch);
   if (!vflag  &&  iswordch(ichar)  &&  len == 1) {
      if (output)
         putchar(ch);
      (*cp)++;
      return 1;
   }
   if (ch == '\t') {
      if (output)
         putchar('\t');
      (*cp)++;
      return 8 - (linew & 0x07);
   }
   /*
    * Character is non-printing, or it's ISO and vflag is set.  Display
    * it in "cat -v" form.  For string characters, display every element
    * separately in that form.
    */
   width = 0;
   for (i = 0;  i < len;  i++) {
      ch = *(*cp)++;
      if (ch > '\177') {
         if (output) {
            putchar('M');
            putchar('-');
         }
         width += 2;
         ch &= 0x7f;
      }
      if (ch < ' '  ||  ch == '\177') {
         if (output) {
            putchar('^');
            if (ch == '\177')
               putchar('?');
            else
               putchar(ch + 'A' - '\001');
         }
         width += 2;
      }
      else {
         if (output)
            putchar(ch);
         width += 1;
      }
   }
   return width;
}

/*---------------------------------------------------------------------------*/

static void show_line(char *line, register char *invstart, register int invlen)
{
   register int width;

   width = invlen ? (sg << 1) : 0;
   width++;                /* To avoid writing last character on line */
   while (line != invstart  &&  width < co)
      width += show_char(&line, width, 1);
   if (invlen) {
      inverse();
      invstart += invlen;
      while (line != invstart  &&  width < co)
         width += show_char(&line, width, 1);
      normal();
   }
   while (*line  &&  width < co)
      width += show_char(&line, width, 1);
   printf("\r\n");
}


/*---------------------------------------------------------------------------*/

static int line_size(char *buf, register char *bufend)
{
   register int width;

   for (width = 0;  buf < bufend  &&  *buf;  )
      width += show_char(&buf, width, 0);
   return width;
}

/*---------------------------------------------------------------------------*/

void show_context(char *ctok, char **curchar, char *begintoken)
{
#ifndef NOCURSES
   int i;
   char *start_l2;

#ifdef BOTTOMCONTEXT
   move(li - contextsize - 1 - minimenusize, 0);
#else /* BOTTOMCONTEXT */
   move(2, 0);
#endif /* BOTTOMCONTEXT */
   for (i = contextsize;  --i > 0;  )
      show_line(contextbufs[i], contextbufs[i], 0);

   start_l2 = contextbufs[0];
   if (line_size(contextbufs[0], *curchar) > co - (sg << 1) - 1) {
      start_l2 = begintoken - (co / 2);
      while (start_l2 < begintoken) {
         i = line_size(start_l2, *curchar) + 1;
         if (i + (sg << 1) <= co)
            break;
         start_l2 += i - co;
      }
      if (start_l2 > begintoken)
         start_l2 = begintoken;
      if (start_l2 < contextbufs[0])
         start_l2 = contextbufs[0];
   }
   show_line(start_l2, begintoken, (int) strlen(ctok));
#endif
}

/*---------------------------------------------------------------------------*/

void show_possibilities_context(char *ctok, char **curchar, char *begintoken)
{
#ifndef NOCURSES
   int col_ht, ncols;

   /*
    * Make sure we have enough room on the screen to hold the
    * possibilities.  Reduce the list if necessary.  co / (maxposslen + 8)
    * is the maximum number of columns that will fit.  col_ht is the
    * height of the columns.  The constant 4 allows 2 lines (1 blank) at
    * the top of the screen, plus another blank line between the
    * columns and the context, plus a final blank line at the bottom
    * of the screen for command entry (R, L, etc).
    */
   col_ht = li - contextsize - 4 - minimenusize;
   ncols = co / (maxposslen + 8);
   if (pcount > ncols * col_ht)
      pcount = ncols * col_ht;

#ifdef EQUAL_COLUMNS
   /* Equalize the column sizes.  The last column will be short. */
   col_ht = (pcount + ncols - 1) / ncols;
#endif

   show_possibilities(col_ht);

   show_context(ctok, curchar, begintoken);

   if (minimenusize != 0) {
      move(li - 2, 0);
      printf(CORR_C_MINI_MENU);
   }
#endif
}


/*---------------------------------------------------------------------------*/

int do_replace(char *ctok, ichar_t *itok, char **curchar, char *begintoken)
{
#ifndef NOCURSES
   move(li - 1, 0);
   if (readonly) {
      putchar(7);
      printf("%s ", CORR_C_READONLY);
   }
   if (input(li -1, 0, CORR_C_REPLACE_WITH, ctok, MAXWLEN-1) == NULL) {
      putchar(7);
      /* Put it back */
      ichartostr(ctok, itok, sizeof ctok, 0);
      return 0;
   }
   else {
      replace_token(contextbufs[0], begintoken, ctok, curchar);
      if (strtoichar(itok, ctok, INPUTWORDLEN * sizeof(ichar_t), 0)) {  /* havia BUG no ispell 3.1? */
         putchar(7);
         printf(WORD_TOO_LONG(ctok));  fflush(stdout);
         getchar();
         return 0;
      }
      changes = 1;
   }
   erase();
#endif
   return 1;
}

/*---------------------------------------------------------------------------*/

int do_replace_all(char *ctok, ichar_t *itok, char **curchar, char *begintoken)
{
   struct dent *d;
   ichar_t nitok[MAXWLEN];

   mk_upper(itok, nitok);
   if ((d = treelookup(nitok, &repl))) {
      strcpy(ctok, ichartosstr(strtosichar(d->jclass, 1), 0));
      replace_token(contextbufs[0], begintoken, ctok, curchar);
      return 1;
   }
   else
      return 0;   /* not found for replace all */
}

/*---------------------------------------------------------------------------*/

int aided_replacement(char c, char *ctok, char **curchar, char *begintoken)
{
#ifndef NOCURSES
   int i;

   i = c - '0';
   if (easypossibilities >= 10) {
      c = GETKEYSTROKE() & NOPARITY;
      if (c >= '0'  &&  c <= '9')
         i = i * 10 + c - '0';
      else if (c != '\r'  &&  c != '\n') {
           putchar(7);
           return 0;   /* no sucesseful replacement */
      }
   }
   if (i < easypossibilities) {
      strcpy(ctok, possibilities[i]);
      changes = 1;
      replace_token(contextbufs[0], begintoken, ctok, curchar);
      erase();
      if (readonly) {
         move(li - 1, 0);
         putchar(7);
         printf("%s", CORR_C_READONLY);
         fflush(stdout);
         sleep((unsigned) 2);
      }
      return 1;   /* success - advance word */
   }
   putchar(7);
#endif
   return 0;   /* try other key */
}

/*---------------------------------------------------------------------------*/

void inter_list()
{
#ifndef NOCURSES
   char buf[100];

   move(li - 1, 0);
   printf(CORR_C_LOOKUP_PROMPT);
   buf[0] = '\0';
   if (jgetline(li-1, strlen(CORR_C_LOOKUP_PROMPT), buf, 99) == NULL) {
      putchar(7);
      erase();
   }
   else {
      printf("\r\n");
      fflush(stdout);
      lookharder(buf);
      erase();
   }
#endif
}

/*---------------------------------------------------------------------------*/

void out_shell()
{
#ifndef NOCURSES
   char buf[200];

   move(li - 1, 0);
   putchar('!');
   buf[0] = '\0';
   if (jgetline(li-1, 1, buf, 199) == NULL) {
      putchar(7);
      erase();
      fflush(stdout);
   }
   else {
      printf("\r\n");
      fflush(stdout);
      shellescape(buf);
      erase();
   }
#endif
}

/*---------------------------------------------------------------------------*/

void possible_quit()
{
   int c;

   if (changes) {
      printf(CORR_C_CONFIRM_QUIT);
      fflush(stdout);
      c = (GETKEYSTROKE() & NOPARITY);
   }
   else
       c = 'y';
   if (c == 'y' || c == 'Y') {
#ifndef NOCURSES
      erase();
#endif
      fflush(stdout);
      done(0);
   }
}

/*---------------------------------------------------------------------------*/

void screen_update(char *ctok)
{
#ifndef NOCURSES
   erase();
#endif
   printf("    %s", ctok);
   if (currentfile)
      printf(CORR_C_FILE_LABEL, currentfile);
   if (readonly)
      printf(" %s", CORR_C_READONLY);
   printf("\r\n\r\n");
}

/*---------------------------------------------------------------------------*/

void jcorrect(char *ctok, ichar_t *itok, 
             char **curchar  /* pointer to pointer to end of word to correct */
             )
{
   register int c;
   // char word[MAXWLEN];
   char *begintoken,  /*  pointer to the begining of the word to correct */
       old_ctok[MAXWLEN];
   int checkagain, leave_options, paint_scr, create_poss;

   begintoken = *curchar - strlen(ctok);

   if (icharlen(itok) <= minword)
      return;                        /* Accept very short words */

   checkagain = 1;
   while (checkagain && !bgood(itok, 0, 0, 0) && !compoundgood(itok)
          && !do_replace_all(ctok, itok, curchar, begintoken)) {

      checkagain = 0;
      paint_scr = 1;
      create_poss = 1;
      do {
         if (create_poss) {
            if (!gflag)        /* CHANGE */
               makepossibilities(itok);
            else easypossibilities = 0;
            create_poss = 0;
         }
         if (paint_scr) {
            screen_update(ctok);
            show_possibilities_context(ctok, curchar, begintoken);
         }

         leave_options = 1;
         fflush(stdout);
         switch (c = (GETKEYSTROKE() & NOPARITY)) {
            case 'Z' & 037:     stop();
#ifndef NOCURSES
                                erase();
#endif
                                leave_options = 0;
                                break;

            case ' ':           
#ifndef NOCURSES
								erase();
#endif
                                fflush(stdout);
                                break;

            case 'q': case 'Q': possible_quit();
                                leave_options = 0;
                                break;

            case 'i': case 'I': leave_options = dic_insert(ctok, itok, 0, curchar);
                                break;

            case 'u': case 'U': leave_options = dic_insert(ctok, itok, 1, curchar);
                                break;

            case 'a': case 'A': treeinsert(ichartosstr(strtosichar(ctok,0), 1),
                                           ICHARTOSSTR_SIZE, 0);
#ifndef NOCURSES
                                erase();
#endif
                                fflush(stdout);
                                break;

            case 'L' & 037:     leave_options = 0;
                                break;

            case '?':           givehelp();
                                leave_options = 0;
                                break;

            case '!':           out_shell();
                                leave_options = 0;
                                break;

            case 'r': case 'R': do_replace(ctok, itok, curchar, begintoken);
                                if (!(icharlen(itok) <= minword)) /* Accept very short replacements */
                                   checkagain = 1;
                                break;

            case 'e': case 'E': strcpy(old_ctok, ichartosstr(strtosichar(ctok, 0), 1));
                                do_replace(ctok, itok, curchar, begintoken);
                                /*if (!(icharlen(itok) <= minword))*/ /* Accept very short replacements */
                                /*   checkagain = 1;*/
                                ins_repl_all(old_ctok,
                                             ichartosstr(strtosichar(ctok, 0), 1));
                                break;

            case '0': case '1': case '2': case '3': case '4':
            case '5': case '6': case '7': case '8': case '9':
               leave_options = aided_replacement(c, ctok, curchar, begintoken);
               break;

            case 'l': case 'L': inter_list();
                                leave_options = 0;
                                break;

            case 'x': case 'X': quit = 1;
#ifndef NOCURSES
                                erase();
#endif
                                fflush(stdout);
                                break;

            case '\r':          /* This makes typing \n after single digits */
            case '\n':          leave_options = 0;      /* ..less obnoxious */
                                paint_scr = 0;
                                break;

            default:            putchar(7);
                                leave_options = 0;
                                paint_scr = 0;
                                break;
         }
      } while (!leave_options);
   }

}


/*---------------------------------------------------------------------------*/

char *input(int l, int c, char *st_out, char *st, int max)
{
#ifndef NOCURSES
   move(l, c);
   printf("%s", st_out);
   return jgetline(l, c+strlen(st_out), st, max);
#endif
}

/*---------------------------------------------------------------------------*/

char *tratar_cursores(char ch, char *s, char *p, char *p_end, int l, int c) {
    return p;
}

void screen_erase(char *p, char *s, char *p_end, int l, int c) {
#ifndef NOCURSES
   char *p1;

   p1 = p;
   while (p1 != p_end) {
      putchar(*p1);
      p1++;
   }
   putchar(' ');
   move(l, c+(p-s));
#endif
}

static char *jgetline(int l, int c, register char *s, int max)
{
#ifndef NOCURSES
   register char *p, *p_end, *p1;
   register int   ch;
   int insert = 1;

   init_filt();
   p = p_end = s + strlen(s);
   printf("%s", s);
   for (  ;  ;  ) {
      fflush(stdout);
      ch = (GETKEYSTROKE() & NOPARITY);
      if (ch == ('G' & 037))
         return NULL;
      else if (ch == '\n' || ch == '\r') {
              return s;
           }
      ch = jfilter(ch);
      switch (ch) {
         case BACKSPACE: if (p != s) {
                            p--;
                            p_end--;
                            for (p1 = p; p1 <= p_end; p1++)
                               *p1 = *(p1 + 1);
                            backup();
                            screen_erase(p, s, p_end, l, c);
                       }
                       break;
         case CLEFT:   if (p != s) {
                          p--;
                          backup();
                       }
                       break;
          case CRIGHT: if (p != p_end) {
                          p++;
                          curs_right();
                       }
                       break;
           case HOME:  p = s;
                       move(l, c);
                       break;
           case END_:  p = p_end;
                       move(l, c+strlen(s));
                       break;
           case INS :  insert = !insert;
                       break;
           case DEL :  if (p != p_end) {
                          p_end--;
                          for (p1 = p; p1 <= p_end; p1++)
                             *p1 = *(p1 + 1);
                          screen_erase(p, s, p_end, l, c);
                       }
                       break;
           default:    if (insert)  {
                          if (strlen(s) < max) {
                             p_end++;
                             for (p1 = p_end; p1 > p; p1--)
                                *p1 = *(p1-1);
                             *p++ = (char) ch;
                             putchar(ch);
                             p1 = p;
                             while (p1 != p_end)
                                putchar(*p1++);
                             move(l, c+(p-s));
                          }
                       }
                       else {  /* overwrite */
                          if (strlen(s) < max || *p != '\0') {
                             if (*p == '\0') {
                                p_end++;
                                *(p_end) = '\0';
                             }
                             *p++ = (char) ch;
                             putchar(ch);
                          }
                       }
           }   /* end case */
   }  /* end for */
#endif
}

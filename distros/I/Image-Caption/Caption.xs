#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* -*- Mode: C; indent-tabs-mode: nil; c-basic-offset: 2 -*-
   Copyright © 2001 Jamie Zawinski <jwz@jwz.org>

   ppmcaption.c --- command-line processing

   Permission to use, copy, modify, distribute, and sell this software and its
   documentation for any purpose is hereby granted without fee, provided that
   the above copyright notice appear in all copies and that both that
   copyright notice and this permission notice appear in supporting
   documentation.  No representations are made about the suitability of this
   software for any purpose.  It is provided "as is" without express or 
   implied warranty.

   Usage:
     ppmcaption -font ncenB24.bdf -scale 0.34 -blur 3 \
        -pos  '10 -10' -left  -text 'The DNA Lounge' \
        -pos '-10 -10' -right -text '%a, %d-%b-%Y %l:%M:%S %p %Z' \
      infile outfile
*/

#include "config.h"
#include "ppm-lite.h"
#include "font-bdf.h"

#include "builtin.h"

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/time.h>
#include <sys/stat.h>

#undef countof
#define countof(x) (sizeof((x))/sizeof(*(x)))

static void
usage (const char *msg, const char *arg)
{
  if (msg)
    {
      fprintf (stderr, msg, arg);
      fprintf (stderr, "\n");
    }

  exit(1);
}

static struct { const char *name; unsigned long hex; }
color_names[] = {
  { "black",   0x000000 },
  { "silver",  0xC0C0C0 },
  { "gray",    0x808080 },
  { "white",   0xFFFFFF },
  { "maroon",  0x800000 },
  { "red",     0xFF0000 },
  { "purple",  0x800080 },
  { "fuchsia", 0xFF00FF },
  { "green",   0x008000 },
  { "lime",    0x00FF00 },
  { "olive",   0x808000 },
  { "yellow",  0xFFFF00 },
  { "navy",    0x000080 },
  { "blue",    0x0000FF },
  { "teal",    0x008080 },
  { "aqua",    0x00FFFF }
};


static unsigned long
parse_color (const char *color)
{
  const char *s;
  int i;

  for (i = 0; i < countof(color_names); i++)
    {
      if (!strcasecmp (color, color_names[i].name))
        return color_names[i].hex;
    }

  if (color[0] == '#') color++;
  s = color;
  if (strlen(s) != 6) goto FAIL;
  for (; *s; s++)
    if (! ((*s >= '0' && *s <= '9') ||
           (*s >= 'A' && *s <= 'F') ||
           (*s >= 'a' && *s <= 'f')))
      {
      FAIL:
        usage ("unparsable color name \"%s\": try #RRGGBB", color);
      }

# define DEHEX(N) (((N) >= '0' && (N) <= '9') ? (N)-'0' : \
                   ((N) >= 'A' && (N) <= 'F') ? (N)-'A'+10 : (N)-'a'+10)
  s = color;
  return (((DEHEX(s[0]) << 4 | DEHEX(s[1])) << 16) |
          ((DEHEX(s[2]) << 4 | DEHEX(s[3])) << 8) |
          ((DEHEX(s[4]) << 4 | DEHEX(s[5]))));
# undef DEHEX
}

MODULE = Image::Caption    PACKAGE = Image::Caption    

PROTOTYPES: ENABLED

SV *
add_caption(fr, width, height, ...)
  INPUT:
          SV *    fr
    int width
    int height
  PREINIT:
    STRLEN n_a;
    char *s;
    char dummy;
    int i;
    struct ppm *ppm = 0;
    static struct font *font = 0;
    int pos_p = 0;
    int pos_x = 0;
    int pos_y = 0;
    int opacity = 255;
    int alignment = 1;
    int verbose = 0;
    unsigned long fg = 0x000000;
    unsigned long bg = 0xFFFFFF;

    time_t now = time ((time_t *) 0);

    unsigned char *prgba;
    unsigned char *prgba_end;
    unsigned char *pfr;
    unsigned char *pfr_end;

    int ncmds = 0;
    int saw_text = 0;
    int argc = items - 3;

    char **argv = (char **) calloc (sizeof(*argv), argc+1);
    char **cmds = (char **) calloc (sizeof(*cmds), argc+1);
   CODE: 
    // fake up argv, save re-coding jwz's stuff
    for (i = 3; i < items; i++)
      argv[i-2] = (char *)SvPV(ST(i), n_a);

    // process arguments into cmds array
    for (i = 1; i < argc; i++)
      {
      if (argv[i][0] == '-' && argv[i][1] == '-' && argv[i][2])
        argv[i]++;
          
      if (!strcmp (argv[i], "-help"))
        usage(0, 0);
      else if (!strcmp (argv[i], "-font") ||
               !strcmp (argv[i], "-scale") ||
               !strcmp (argv[i], "-blur") ||
               !strcmp (argv[i], "-opacity") ||
               !strcmp (argv[i], "-fg") ||
               !strcmp (argv[i], "-bg") ||
               !strcmp (argv[i], "-time") ||
               !strcmp (argv[i], "-text"))
        {
        if (!strcmp (argv[i], "-text"))
          saw_text = 1;

        if (!argv[i+1] || argv[i+1][0] == '-')
          usage("argument required for `%s'", argv[i]);

        if (verbose > 1)
          fprintf (stderr, "parse: \"%s\" \"%s\"\n",
            argv[i], argv[i+1]);

        cmds[ncmds++] = argv[i++];
        cmds[ncmds++] = argv[i];
        }
      else if (!strcmp (argv[i], "-left") ||
               !strcmp (argv[i], "-right") ||
               !strcmp (argv[i], "-center"))
        {
        cmds[ncmds++] = argv[i];

        if (verbose > 1)
          fprintf (stderr, "parse: \"%s\"\n", argv[i]);
        }
      else if (!strcmp (argv[i], "-pos"))
        {
        /* Allow:
           { "-pos", "x", "y" }
           { "-pos", "x y" }
           { "-pos", "x,y" }
         */
        int x, y;

        if (!argv[i+1])
          usage("argument required for `%s'", argv[i]);

        cmds[ncmds++] = argv[i++];

        while ((s = strchr(argv[i], ',')))
          *s = ' ';
        while ((s = strchr(argv[i], '/')))
          *s = ' ';

        if (2 == sscanf (argv[i], " %d %d %c", &x, &y, &dummy)) /* "x y" */
          {
          if (verbose > 1)
            fprintf (stderr, "parse: \"%s\" \"%s\"\n",

          cmds[ncmds-1], argv[i]);
          cmds[ncmds++] = argv[i];
          }
        else if (1 == sscanf (argv[i],   " %d %c", &x, &dummy) && /* "x" */
                 1 == sscanf (argv[i+1], " %d %c", &y, &dummy))   /* "y" */
          {
          char *s = (char *) malloc(strlen(argv[i]) + strlen(argv[i+1]) + 4);

          strcpy (s, argv[i++]);
          strcat (s, " ");
          strcat (s, argv[i]);

          if (verbose > 1)
            fprintf (stderr, "parse: \"%s\" \"%s\" \"%s\" ==> \"%s\"\n",
              cmds[ncmds-1], argv[i-1], argv[i], s);

          cmds[ncmds++] = strdup (s);
          }
        else
          usage("-pos \"%s\" unparsable (should be \"X Y\")", argv[i]);
        }
      else if (!strcmp (argv[i], "-verbose") || !strcmp (argv[i], "-v"))
        verbose++;
      else if (!strcmp (argv[i], "-vv"))
        verbose += 2;
      else
        usage("unrecognised argument: `%s'", argv[i]);
      }

    if (ncmds == 0)
      usage("no commands specified.", "");
    else if (!saw_text)
      usage("no -text specified.", "");

    // create ppm struct from arguments
    ppm = (struct ppm *) calloc (1, sizeof(*ppm));
    ppm->type = 6;
    ppm->width = width;
    ppm->height = height;
    ppm->rgba = (unsigned char *) calloc (1, (ppm->width + 2) * (ppm->height + 2) * 4);

    // promote from RGB to RGBA
    prgba = ppm->rgba;
    prgba_end = prgba + ppm->width*ppm->height*4;

    pfr = SvPV_nolen(fr);
    pfr_end = SvEND(fr);

    while (prgba < prgba_end) {
      *prgba++ = *pfr++;
      *prgba++ = *pfr++;
      *prgba++ = *pfr++;
      *prgba++ = 255;
    }

    if (verbose)
      fprintf(stderr, "width: %d, height: %d, type: %d\n", ppm->width, ppm->height, ppm->type);

    for (i = 0; i < ncmds; i++)
      {
        if (!strcmp (cmds[i], "-font"))
          {
            i++;
            if (font) free_font (font);

            if (verbose)
              fprintf (stderr, "loading font %s\n", cmds[i]);

            if (!strcmp(cmds[i], "builtin"))
              font = copy_font (&builtin_font);
            else
              font = read_bdf (cmds[i]);
          }
        else if (!strcmp (cmds[i], "-pos"))
          {
            i++;
            if (2 != sscanf (cmds[i], "%d %d %c", &pos_x, &pos_y, &dummy))
              usage("-pos \"%s\" unparsable (should be \"X Y\")", cmds[i]);

            if (pos_x < 0) pos_x = ppm->width  + pos_x;
            if (pos_y < 0) pos_y = ppm->height + pos_y;
            pos_p = 1;

            if (verbose)
              fprintf (stderr, "position: %d %d\n", pos_x, pos_y);
          }
        else if (!strcmp (cmds[i], "-scale"))
          {
            float scale;
            i++;
            if (1 != sscanf (cmds[i], "%f %c", &scale, &dummy))
              usage("-scale \"%s\" unparsable (should be a float)", cmds[i]);

            if (!font) font = copy_font (&builtin_font);

            if (!font) usage ("-font must preceed -scale", "");

            if (verbose)
              fprintf (stderr, "scale: %.2f\n", scale);

            scale_font (font, scale);
          }
        else if (!strcmp (cmds[i], "-blur"))
          {
            int b;
            i++;
            if (1 != sscanf (cmds[i], "%d %c", &b, &dummy))
              usage("-blur \"%s\" unparsable (should be a number of pixels)",
                    cmds[i]);

            if (b > 0)
              {
                if (!font) font = copy_font (&builtin_font);

                if (!font) usage ("-font must preceed -blur", "");

                if (verbose)
                  fprintf (stderr, "blur: %d\n", b);

                halo_font (font, b);
              }
          }
        else if (!strcmp (cmds[i], "-fg"))
          {
            i++;
            fg = parse_color (cmds[i]);
            if (verbose)
              fprintf (stderr, "fg: 0x%06lX\n", fg);
          }
        else if (!strcmp (cmds[i], "-bg"))
          {
            i++;
            bg = parse_color (cmds[i]);

            if (verbose)
              fprintf (stderr, "bg: 0x%06lX\n", bg);
          }
        else if (!strcmp (cmds[i], "-opacity"))
          {
            float op;
            i++;
            if (1 != sscanf (cmds[i], "%f %c", &op, &dummy) ||
                op <= 0.0 || op > 1.0)
              usage ("-opacity \"%s\" unparsable (should be a float (0, 1]",
                     cmds[i]);

            if (verbose)
              fprintf (stderr, "opacity: %.2f\n", op);

            opacity = 255 * op;
          }
        else if (!strcmp (cmds[i], "-left"))
          {
            alignment = 1;
            if (verbose)
              fprintf (stderr, "alignment: left\n");
          }
        else if (!strcmp (cmds[i], "-right"))
          {
            alignment = -1;
            if (verbose)
              fprintf (stderr, "alignment: right\n");
          }
        else if (!strcmp (cmds[i], "-center"))
          {
            alignment = 0;
            if (verbose)
              fprintf (stderr, "alignment: center\n");
          }
        else if (!strcmp (cmds[i], "-text"))
          {
            char *text = cmds[++i];
            if (!font) font = copy_font (&builtin_font);

            if (!font) usage ("-font must preceed -text", "");

            if (!pos_p) usage ("-pos must preceed -text", "");

            if (strchr (text, '%'))
              {
                struct tm *tm = localtime (&now);
                int L = strlen(text) + 100;
                char *t2 = (char *) malloc (L);
                strftime (t2, L-1, text, tm);
                text = t2;
              }

            if (verbose)
              fprintf (stderr, "text: \"%s\", pos_x: %d, pos_y: %d, font_ascent: %d, alignment: %d, opacity: %d\n", text, pos_x, pos_y, font->ascent, alignment, opacity);

            draw_string (font, text, ppm,
                         pos_x,
                         pos_y - font->ascent,
                         alignment, fg, bg, opacity);
          }
        else
          abort();
      }

    if (verbose)
      fprintf (stderr, "done.\n");

    // Demote back to RGB from RGBA
    pfr = SvPV_nolen(fr);
    pfr_end = SvEND(fr);

    prgba = ppm->rgba;
    prgba_end = prgba + ppm->width * ppm->height * 4;

    while (prgba < prgba_end) {
      *pfr++ = *prgba++;
      *pfr++ = *prgba++;
      *pfr++ = *prgba++;
      prgba++;
    }

    if (ppm)
      free_ppm(ppm);
  OUTPUT:
    fr

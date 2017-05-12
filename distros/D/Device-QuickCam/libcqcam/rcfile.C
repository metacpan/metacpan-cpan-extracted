/* libcqcam - shared Color Quickcam routines
 * Copyright (C) 1996-1998 by Patrick Reynolds
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

// Handler for configuration files
// This is mostly compatible with qcam-style config files

#include "rcfile.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pwd.h>
#include <unistd.h>

const char *qcrc_filename[] = {
  "~/.cqcrc",
  "/etc/cqcam.conf",
  "/usr/local/etc/cqcam.conf",
  "~/.qcrc",
  "/etc/qcam.conf",
  "/usr/local/etc/qcam.conf",
  0
};

const char *directives[][2] = {
  { "port", "-P" },
  { "width", "-x" },
  { "height", "-y" },
  { "top", "-t" },
  { "left", "-l" },
  { "transfer", "-s" }, { "decimation", "-s" },
  { "brightness", "-b" },
  { "contrast", "-c" },
  { "whitebal", "-w" },
  { "blacklevel", "-B" },
  { "hue", "-H" },
  { "saturation", "-S" },
  { 0, 0 }
};

rcfile_t::rcfile_t(void) {
  nswitches = 0;
  FILE *qcrc = NULL;
  int i;
  for (i=0; qcrc_filename[i] != 0 && qcrc == NULL; i++) {
    if (qcrc_filename[i][0] == '~') {
      char *tmp = resolve_home_dir(qcrc_filename[i]);
      qcrc = fopen(tmp, "r");
      delete[] tmp;
    }
    else
      qcrc = fopen(qcrc_filename[i], "r");
#ifdef DEBUG
    fprintf(stderr, "Config file %s %sfound.\n", qcrc_filename[i], 
      qcrc?"":"not ");
#endif
  }
  if (qcrc == NULL) {
#ifdef DEBUG
    fprintf(stderr, "No config files found.\n");
#endif
    return;
  }
  while (!feof(qcrc)) {
    char buf[200], word1[100], word2[100];
    char *p;
    fgets(buf, 200, qcrc);
    if ((p = strchr(buf, '#')) != NULL)
      *p = '\0';
    sscanf(buf, "%s %s", word1, word2);
    if (!feof(qcrc) && *buf != '\0' && *buf != '\n') {
      for (i=0; directives[i][0]; i++)
        if (!strcasecmp(word1, directives[i][0])) {
          switches[nswitches] = new char[strlen(word1) + 1];
          strcpy(switches[nswitches], directives[i][1]);
          values[nswitches] = new char[strlen(word2) + 1];
          strcpy(values[nswitches], word2);
          nswitches++;
          break;
        }
#ifdef DEBUG
      if (!directives[i][0])
        fprintf(stderr, "Unrecognized option in config file: %s %s\n", 
          word1, word2);
#endif
    }
  } 
#ifdef DEBUG     
  for (int q=0; q<nswitches; q++)
    fprintf(stderr, "%s %s ", switches[q], values[q]);
  fprintf(stderr, "\n");
#endif
}

rcfile_t::~rcfile_t(void) {
  for (int i=0; i<nswitches; i++) {
    delete[] switches[i];
    delete[] values[i];
  }
}

char *resolve_home_dir(const char *fn) {
  char *ret;
  // try the $HOME environment variable
  if (getenv("HOME") != NULL) {
    ret = new char[strlen(getenv("HOME")) + strlen(fn)];
    strcpy(ret, getenv("HOME"));
    strcat(ret, fn + 1);
    return ret;
  }
  struct passwd *pw = getpwuid(getuid());
  if (!pw) {
    ret = new char[strlen(fn) + 1];
    strcpy(ret, fn);
    return ret;
  }
  ret = new char[strlen(pw->pw_dir) + strlen(fn)];
  strcpy(ret, pw->pw_dir);
  strcat(ret, fn + 1);
  return ret;
}

void rcfile_t::get(char **sw, char **val, int reset) {
  static int c = 0;
  if (reset)
    c = 0;
  if (c == nswitches) {
    *sw = NULL;
    *val = NULL;
  }
  else {
    *sw = switches[c];
    *val = values[c];
    c++;
  }
}

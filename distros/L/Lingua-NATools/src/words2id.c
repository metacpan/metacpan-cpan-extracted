/* -*- Mode: C; c-file-style: "stroustrup" -*- */

/* NATools - Package with parallel corpora tools
 * Copyright (C) 2002-2012  Alberto Simões
 *
 * This package is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.         See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

#include <wchar.h>
#include <stdio.h>
#include <NATools/words.h>
#include "standard.h"
#include "unicode.h"

/**
 * @file
 * @brief converts words to identifiers based on a lexicon file.
 *
 * @todo Check if we should maintain this file or just... delete it
 */

/** 
 * @brief Main program
 *
 * Arguments are the lexicon file, a text file with the words to be
 * encoded (one word by line), and optionally a binary file where to
 * store the binary words identifiers. If not supplied, the output
 * will be done to stdout, with an integer by line.
 */
int main(int argc, char *argv[])
{
    Words *lst;
    FILE *fd;
    FILE *fd2 = NULL;
    wchar_t buff[150];

    init_locale();
    
    if (argc != 3 && argc != 4) {
        printf("Usage:\n");
        printf("  nat-words2id lexic wrdLst [output.bin]\n");
        return 1;
    }

    lst = words_quick_load(argv[1]);
    if (!lst) return 1;
    
    fd = fopen(argv[2], "r");
    if (!fd) return 1;

    if (argc == 4) {
        fd2 = fopen(argv[3], "wb");
        if (!fd2) return 1;
    }

    while(!feof(fd)) {
        fgetws(buff, 150, fd);
        if (!feof(fd)) {
            nat_uint32_t id;
            id = words_get_id(lst, chomp(buff));
            if (id) {
                if (argc == 4) {
                    fwrite(&id, sizeof(nat_uint32_t), 1, fd2);
                } else {
                    printf("%d\n", id);
                }
            }
        }
    }
    
    fclose(fd);

    return 0;
}

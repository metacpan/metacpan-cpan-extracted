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

#include <stdio.h>
#include "natdict.h"

/**
 * @file
 * @brief Main program to add NATools dictionary files
 */

/**
 * @brief Main program.
 *
 * Is the main program. Number of arguments should be at least three.
 * The arguments are the name of the dictionary to be generated, and a
 * list of names of dictionaries to be added up.
 */
int main(int argc, char *argv[])
{
    NATDict *d1;
    NATDict *d2;
    NATDict *d3 = NULL;
    int cntr = 3;

    if (argc < 4) {
        printf("USAGE:\n\tnat-ntd-add <sumdic> <dic1> <dic2> ...\n");
        return 0;
    }

    d1 = natdict_open(argv[2]);
    if (!d1) { 
        printf("Error loading dictionary: %s\n", argv[2]); 
        return 1; 
    }
        
    while(cntr < argc) {
        d2 = natdict_open(argv[cntr]);
        if (!d2) { 
            printf("Error loading dictionary: %s\n", argv[cntr]); 
            return 1; 
        }
        cntr++;
        
        d3 = natdict_add(d1, d2);
        d1 = d3;
        d3 = NULL;
    }
    natdict_save(d1, argv[1]);
    return 0;
}

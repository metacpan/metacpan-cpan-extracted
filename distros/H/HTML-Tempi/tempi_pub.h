/*   
		Tempi - A HTML Template system
    Copyright (C) 2002  Roger Faust <roger_faust@bluewin.ch>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
		
*/

#ifndef TEMPI_PUB_H
#define TEMPI_PUB_H 1

#define NO_INIT_RUN "tempi_init hasn't been running yet"
#define NO_FREE_MEMORY_RUN "tempi_free hasn't been running yet"

char *parse_block (char *name);
char *set_var (char *name, char *value);
char *get_parsed (void);
char *init (char *argv);
char *free_memory (void);
char *reinit (void);

#endif

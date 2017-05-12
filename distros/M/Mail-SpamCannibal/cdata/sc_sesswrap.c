/*
 * sc_sesswrap.c
 * version 1.00 8-13-03
 *
 * wrapper to allow suid execution of perl script
 *
 * Copyright 2003, Michael Robinton <michael@bizsystems.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *
 */

#include <stdio.h>
#include <string.h> 
#include <unistd.h>

/*	allowed wrapper names are:
 *
 *		sc_sesswrap
 *		sc_remotewrap
 *
 *	allowed executable names are:
 *
 *		sc_session.pl
 *		sc_remote.pl
 */

int main (int argc, char * argv[])
{
  char alias_script[255];
  char sorry[] = "sorry";
  char * name;
  enum { sc_sesswrap, sc_remotewrap } function;

  strcpy(alias_script,argv[0]);

  if ((name = strrchr(alias_script,'/')) == NULL)
    name = alias_script;
  else
    name += 1;
    
  if(!strcmp (name,"sc_sesswrap"))
    strcpy(name,"sc_session.pl\0");

  else if (!strcmp (name,"sc_remotewrap"))
    strcpy(name,"sc_remote.pl\0");
  
  else
    exit(-1);
  
  if ( argv[1] != NULL && (strcmp(argv[1], "admin")) == 0)
  	argv[1] = sorry;
  execv(alias_script, argv);
  exit(-1);
}

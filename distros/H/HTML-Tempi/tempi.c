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

#ifndef TEMPI_C
#define TEMPI_C 1
#endif

/*starting to whole stuff*/
char *
init (char *argv)
{
  int temp_i;

  /*YY_BUFFER_STATE temp_buffer; */
  /*int _yyi; */

  if (init_done)
    {
      s_strfree (&temp_string);
      s_strcat (&temp_string,
		"Init has already been running, use first tempi_reinit ()");
      return (temp_string.value);
    }

  free_memory_done = false;
  ablock = &fblock;
  temp_string.value = NULL;
  temp_string.size = 0;
  temp_string.memory = 0;
  parst.value = NULL;
  parst.size = 0;
  parst.memory = 0;

  if (!init_run)
    {
      flex_output.value = s_malloc (REALLOC_STRING_BIG);
      flex_output.size = 1;
      flex_output.memory = REALLOC_STRING_BIG;
      *flex_output.value = '\0';
      for (temp_i = 0; temp_i < MAX_BLOCK_DEP; temp_i++)
	{
	  (block_names[temp_i]).value = NULL;
	  (block_names[temp_i]).size = 0;
	  (block_names[temp_i]).memory = 0;
	}
      a_file.value = NULL;
      a_file.size = 0;
      a_file.memory = 0;
      block_counter = 0;
      line_counter = 0;
      block_counter_real = 0;
      track_file = NULL;
      for (temp_i = 0; temp_i < MAX_FILE_DEP; temp_i++)
	{
	  (files.files)[temp_i] = NULL;
	}
      files.open = 0;
      for (temp_i = 0; temp_i < MAX_FILE_DEP; temp_i++)
	{
	  (buffers.buffers)[temp_i] = NULL;
	}
      buffers.open = 0;
      add_block_name (MAIN_BLOCK_NAME);
      s_strcat (&(block_names[0]), MAIN_BLOCK_NAME);
      temp_i = errno;
      errno = 0;
      yyin = fopen (argv, "r");
      if (errno)
	{
	  s_strfree (&temp_string);
	  s_strcat (&temp_string, "Couldn't open file ");
	  s_strcat (&temp_string, argv);
	  return (temp_string.value);
	  /*s_error (NULL); */
	}
      errno = temp_i;
      s_strcat (&a_file, argv);
      block_counter_real++;
      temp_i = yylex ();
      if (temp_i == ERROR_DURING_PARSING)
	return (temp_string.value);
      for (temp_i = 0; temp_i < MAX_BLOCK_DEP; temp_i++)
	{
	  s_strfree (&block_names[temp_i]);
	}
      s_strfree (&a_file);
      s_strfree (&flex_output);
      init_run = true;
    }
  init_done = true;
  make_out_struct ();
  return (NULL);
}


/*
 * collecting the output of flex (overriding builtin ECHO macro with this
 * function)
 */
void
get_flex_output (void)
{
  flex_output.size += yyleng;
  /*a terrible debugging session has shown my, that we need this controll */
  /*this functions depens on getting a true string in flex_output, but */
  /*we can not count on that, so we have to prouve that flex_output.size */
  /*is at last 2 byte (one for the char we want, and one for the \0) */
  if (flex_output.size == 1)
    flex_output.size++;
  while (flex_output.memory < flex_output.size)
    {
      flex_output.memory += REALLOC_STRING_BIG;
      flex_output.value = s_realloc (flex_output.value, flex_output.memory);
    }
  /*it's very important, to avoid strcat, since it would 
     slow down the whole thing by about 100% (depending on 
     each block size, since c has always to calculait the 
     size of a string (in contrast to pascal :-), but we will 
     store it for us...) */
  if (yyleng == 1)
    {
      *(flex_output.value + flex_output.size - 2) = *yytext;
      *(flex_output.value + flex_output.size - 1) = '\0';
    }
  else
    strcat (flex_output.value, yytext);
}


/*
 * adding output to a block, creating a new one
 */
void
add_block_value (char *value)
{
  ablock->next = s_malloc (sizeof (block));
  if (value == NULL)
    ablock->value = NULL;
  else
    {
      ablock->value = s_malloc (1 + strlen (value));
      strcpy (ablock->value, value);
    }
  ablock = ablock->next;
  ablock->next = NULL;
  ablock->is_var = false;
  ablock->is_last = false;
}

/*
 * adds a name to a block
 */
void
add_block_name (char *name)
{
  if (name == NULL)
    ablock->name = NULL;
  else
    {
      ablock->name = s_malloc (1 + strlen (name));
      strcpy (ablock->name, name);
    }
}

/*
 * will create the output data structure
 */
void
make_out_struct (void)
{
  int temp_i;
  out = s_malloc ((1 + block_counter_real) * sizeof (string));
  for (temp_i = 0; temp_i <= block_counter_real; temp_i++)
    {
      out[temp_i].value = NULL;
      out[temp_i].size = 0;
      out[temp_i].memory = 0;
    }
}

/*
 * copy a block to the output string
 */
char *
parse_block (char *name)
{
  int temp_i = 0;
  bool c = true, found = false;
  string aname[MAX_BLOCK_DEP];
  if (!init_done)
    return (NO_INIT_RUN);
  for (temp_i = 0; temp_i <= MAX_BLOCK_DEP; temp_i++)
    aname[temp_i].value = NULL;
  temp_i = 0;
  ablock = &fblock;
  while (ablock->next != NULL)
    {
      if ((strcmp (ablock->name, name)) == 0)
	{
	  found = true;
	  s_strcat (&out[temp_i], ablock->value);
	  c = true;
	  if (ablock->is_last)
	    return (NULL);
	}
      else if (!(ablock->is_var))
	c = false;
      if (!(ablock->is_var))
	temp_i++;
      else if (c)
	s_strcat (&out[temp_i], ablock->value);
      ablock = ablock->next;
    }
  if (found)
    return (NULL);
  s_strfree (&temp_string);
  s_strcat (&temp_string, "Block ");
  s_strcat (&temp_string, name);
  s_strcat (&temp_string, " doesn't exist");
  return (temp_string.value);
}

/*
 * set a var with a value
 */
char *
set_var (char *name, char *value)
{
  bool found = false;
  if (!init_done)
    return (NO_INIT_RUN);
  ablock = &fblock;
  while (ablock->next != NULL)
    {
      if (ablock->is_var)
	{
	  if ((strcmp (ablock->name, name)) == 0)
	    {
	      found = true;
	      ablock->value = s_realloc (ablock->value, 1 + strlen (value));
	      strcpy (ablock->value, value);
	    }
	}
      ablock = ablock->next;
    }
  if (found)
    return (NULL);
  else
    {
      s_strfree (&temp_string);
      s_strcat (&temp_string, "Variable ");
      s_strcat (&temp_string, name);
      s_strcat (&temp_string, " doesn't exist");
      return (temp_string.value);
    }
}

/*
 * makes a string out of all parsed data
 */
char *
get_parsed ()
{
  int temp_i;
  if (!init_done)
    return (NULL);
  parst.value = NULL;
  for (temp_i = 0; temp_i <= block_counter_real; temp_i++)
    {
      s_strcat (&parst, out[temp_i].value);
    }
  return parst.value;
}

/*
 * will free no more used memory (at least i hope so...)
 */
char *
free_memory ()
{
  int temp_i;
  if (!init_done)
    return (NO_INIT_RUN);
  for (temp_i = 0; temp_i <= block_counter_real; temp_i++)
    {
      s_strfree (&out[temp_i]);
    }
  s_free (out);
  s_strfree (&parst);
  s_strfree (&temp_string);
  init_done = false;
  free_memory_done = true;
  return (NULL);
}

void
free_memory_rest ()
{
  block *temp;
  ablock = &fblock;
  /* this may seem very stupid, but it's necesary, since 
     fblock isn't dynamic memory, what would cause free  
     to fail terrible */
  if (ablock->value != NULL)
    s_free (ablock->value);
  if (ablock->name != NULL)
    s_free (ablock->name);
  ablock = ablock->next;
  while (ablock->next != NULL)
    {
      if (ablock->value != NULL)
	s_free (ablock->value);
      if (ablock->name != NULL)
	s_free (ablock->name);
      temp = ablock->next;
      s_free (ablock);
      ablock = temp;
    }
  s_free (ablock);
  free_memory ();
}

char *
reinit ()
{
  if ((!init_done) && (!free_memory_done))
    return (NO_INIT_RUN);
  if (!free_memory_done)
    return (NO_FREE_MEMORY_RUN);
  free_memory_rest ();
  init_run = false;
  init_done = false;
  free_memory_done = false;
  return (NULL);
}

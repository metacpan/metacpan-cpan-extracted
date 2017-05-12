%{
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

#include <errno.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

#include "libs.h"

#include "tempi.h"

#include "tempi_vars.h"

%}
%x MATCH_BLOCK_1
%x MATCH_BLOCK_2
%x MATCH_FILE_1
%x MATCH_FILE_2
%x MATCH_VAR_1
%x MATCH_VAR_2

%option noyywrap

BLOCK_START "<!--BLOCK:"
BLOCK_NAME [[:alnum:]]+
BLOCK_END "-->"

BLOCK_ENDE "<!--END"[[:alnum:]:]*"-->"

FILE_START "<!--FILE:"
FILE_NAME [[:alnum:]./_]+
FILE_END "-->"

VAR_START "{"
VAR_NAME [[:alnum:]]+
VAR_END "}"

%%
{BLOCK_START}{BLOCK_NAME}{BLOCK_END}	{

	/*will match a block*/
	/*going into the MATCH_BLOCK section*/
	
	if (block_counter >= (MAX_BLOCK_DEP - 1))
		{
			s_strfree (&temp_string);
			s_strcat (&temp_string, "");
			snprintf (temp_string.value, temp_string.memory, "Max block dep reached at line %i, in file %s", line_counter, a_file.value);
			/*s_error (temp_string.value);*/
			return (ERROR_DURING_PARSING);
		}
	block_counter_real++;
	
	BEGIN (MATCH_BLOCK_1);
	temp_buffer = YY_CURRENT_BUFFER;
	yy_scan_string (yytext);
}


<MATCH_BLOCK_1>{BLOCK_START}	{
	
	/*match just to the name of the block*/
	
	BEGIN (MATCH_BLOCK_2);
}


<MATCH_BLOCK_2>{BLOCK_NAME}	{

	/*will match the name of the block*/
	/*leaving the MATCH_BLOCK section*/

	BEGIN (0);
	add_block_value (flex_output.value);
	s_strfree (&flex_output);
	s_strcat (&(block_names[++block_counter]), yytext);
	add_block_name ((block_names[block_counter]).value);
	yy_delete_buffer (YY_CURRENT_BUFFER); 
	yy_switch_to_buffer (temp_buffer);
}


{BLOCK_ENDE}	{

	/*will match the end of a block*/
	
	block_counter_real++;
	
	ablock->is_last = true;
	add_block_value (flex_output.value);
	s_strfree (&flex_output);
	s_strfree (&(block_names[block_counter]));
	add_block_name ((block_names[--block_counter]).value);	
}




{FILE_START}{FILE_NAME}{FILE_END}	{
						
	/*will match load file tag and get the name*/
	/*going into the MATCH_FILE section*/

	BEGIN (MATCH_FILE_1);
	temp_buffer = YY_CURRENT_BUFFER;
	yy_scan_string (yytext);
}


<MATCH_FILE_1>{FILE_START}	{

	/*matching just to the file name*/

	if (buffers.open >= (MAX_FILE_DEP - 1))
		{
			s_strfree (&temp_string);
			s_strcat (&temp_string, "");
			snprintf (temp_string.value, temp_string.memory, "Max file dep reached at line %i, in file %s", line_counter, a_file.value);
			/*s_error (temp_string.value);*/
			return (ERROR_DURING_PARSING);
		}

	BEGIN (MATCH_FILE_2);
}


<MATCH_FILE_2>{FILE_NAME}	{
	
	/*matching the file name*/
	/*leaving the MATCH_FILE section*/
			
	BEGIN (0);
	_yyi = errno;
	errno = 0;
	yyin = fopen (yytext, "r");
	if (yyin == NULL)
		{
			s_strfree (&temp_string);
			s_strcat (&temp_string, "");
			snprintf (temp_string.value, temp_string.memory, "Couldn't open file %s, loaded from line %i in file %s", yytext, line_counter, a_file.value);
			/*s_error (temp_string.value);*/
			return (ERROR_DURING_PARSING);
		}
	else
		errno = _yyi;
	s_strfree (&a_file);
	s_strcat (&a_file, yytext);
	(buffers.buffers)[buffers.open++] = temp_buffer;
	yy_switch_to_buffer (yy_create_buffer (yyin, YY_BUF_SIZE));
}




{VAR_START}{VAR_NAME}{VAR_END}	{

	/*matching a variable*/
	/*going into the MATCH_VAR section*/

	BEGIN (MATCH_VAR_1);
	temp_buffer = YY_CURRENT_BUFFER;
	yy_scan_string (yytext);				
}


<MATCH_VAR_1>{VAR_START}	{

	/*matching just to the variable's name*/
	
	block_counter_real++;
	BEGIN (MATCH_VAR_2);
}


<MATCH_VAR_2>{VAR_NAME}	{

	/*matching the variables name*/
	/*leaving MATCH_VAR section*/
	
	add_block_value (flex_output.value);
	s_strfree (&flex_output);
	add_block_name (yytext);
	ablock->is_var = true;
	add_block_value (NULL);
	add_block_name ((block_names[block_counter]).value);
	BEGIN (0);
	yy_delete_buffer (YY_CURRENT_BUFFER); 
	yy_switch_to_buffer (temp_buffer);			
}




\n	{
	
	/*just counting lines (for information on error's)*/
	ECHO;
	line_counter ++;
}




<<EOF>>	{

	/*end of file*/
	
	if (files.open == 0)
		{
			add_block_value (flex_output.value);
			if (block_counter < 0)
				{
					s_strfree (&temp_string);
					s_strcat (&temp_string, "");
					snprintf (temp_string.value, temp_string.memory, "To many close block tags in file %s", a_file.value);
					/*s_error (temp_string.value);*/
					return (ERROR_DURING_PARSING);					
				}
			if (block_counter > 0)
				{
					s_strfree (&temp_string);
					s_strcat (&temp_string, "");
					snprintf (temp_string.value, temp_string.memory, "Not enough close block tags in file %s", a_file.value);
					/*s_error (temp_string.value);*/
					return (ERROR_DURING_PARSING);					
				}
			yyterminate ();
		}
	yy_delete_buffer (YY_CURRENT_BUFFER);
	yy_switch_to_buffer ((buffers.buffers)[--buffers.open]); 
}
%%
#include "tempi.c"

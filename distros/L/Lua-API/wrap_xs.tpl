/* [% proto %] */

typedef struct {[% FOREACH arg IN args %]
  [% arg.cdef %];
[%- END %]
  [% "${type} retval;" UNLESS type == 'void' %]
} [% structname %];

int [% fwrap %] ( lua_State *L )
{
    [% structname %] *data = ([% structname %] *) lua_touserdata( L, -1 );

    /* ...remove it from the stack */
    lua_pop( L, 1 );

    /* call the function; return value in the struct bypassing Lua */
    [% "data->retval = " UNLESS type == 'void' %][% lua_funcname -%]( L, 
[%- FOREACH arg IN args -%]
data->[%- arg.name -%][%- ", "  IF ! loop.last -%] [%- END -%] );

    /* return value is ignored as this is called via lua_pcall */
    return 0;
}

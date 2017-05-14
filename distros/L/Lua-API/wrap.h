/* long luaL_checklong (lua_State *L, int narg); */

typedef struct {
  int narg;
  long retval;
} checklong_S;

int wrap_checklong ( lua_State *L )
{
    checklong_S *data = (checklong_S *) lua_touserdata( L, -1 );

    /* ...remove it from the stack */
    lua_pop( L, 1 );

    /* call the function; return value in the struct bypassing Lua */
    data->retval = luaL_checklong( L, data->narg );

    /* return value is ignored as this is called via lua_pcall */
    return 0;
}
/* void luaL_checktype (lua_State *L, int narg, int t); */

typedef struct {
  int narg;
  int t;
  
} checktype_S;

int wrap_checktype ( lua_State *L )
{
    checktype_S *data = (checktype_S *) lua_touserdata( L, -1 );

    /* ...remove it from the stack */
    lua_pop( L, 1 );

    /* call the function; return value in the struct bypassing Lua */
    luaL_checktype( L, data->narg, data->t );

    /* return value is ignored as this is called via lua_pcall */
    return 0;
}
/* void luaL_checkany (lua_State *L, int narg); */

typedef struct {
  int narg;
  
} checkany_S;

int wrap_checkany ( lua_State *L )
{
    checkany_S *data = (checkany_S *) lua_touserdata( L, -1 );

    /* ...remove it from the stack */
    lua_pop( L, 1 );

    /* call the function; return value in the struct bypassing Lua */
    luaL_checkany( L, data->narg );

    /* return value is ignored as this is called via lua_pcall */
    return 0;
}
/* void luaL_argcheck (lua_State *L, int cond, int narg, const char *extramsg); */

typedef struct {
  int cond;
  int narg;
  const char *extramsg;
  
} argcheck_S;

int wrap_argcheck ( lua_State *L )
{
    argcheck_S *data = (argcheck_S *) lua_touserdata( L, -1 );

    /* ...remove it from the stack */
    lua_pop( L, 1 );

    /* call the function; return value in the struct bypassing Lua */
    luaL_argcheck( L, data->cond, data->narg, data->extramsg );

    /* return value is ignored as this is called via lua_pcall */
    return 0;
}
/* int luaL_checkint (lua_State *L, int narg); */

typedef struct {
  int narg;
  int retval;
} checkint_S;

int wrap_checkint ( lua_State *L )
{
    checkint_S *data = (checkint_S *) lua_touserdata( L, -1 );

    /* ...remove it from the stack */
    lua_pop( L, 1 );

    /* call the function; return value in the struct bypassing Lua */
    data->retval = luaL_checkint( L, data->narg );

    /* return value is ignored as this is called via lua_pcall */
    return 0;
}
/* int luaL_argerror (lua_State *L, int narg, const char *extramsg); */

typedef struct {
  int narg;
  const char *extramsg;
  int retval;
} argerror_S;

int wrap_argerror ( lua_State *L )
{
    argerror_S *data = (argerror_S *) lua_touserdata( L, -1 );

    /* ...remove it from the stack */
    lua_pop( L, 1 );

    /* call the function; return value in the struct bypassing Lua */
    data->retval = luaL_argerror( L, data->narg, data->extramsg );

    /* return value is ignored as this is called via lua_pcall */
    return 0;
}
/* lua_Integer luaL_optinteger (lua_State *L, int narg, lua_Integer d); */

typedef struct {
  int narg;
  lua_Integer d;
  lua_Integer retval;
} optinteger_S;

int wrap_optinteger ( lua_State *L )
{
    optinteger_S *data = (optinteger_S *) lua_touserdata( L, -1 );

    /* ...remove it from the stack */
    lua_pop( L, 1 );

    /* call the function; return value in the struct bypassing Lua */
    data->retval = luaL_optinteger( L, data->narg, data->d );

    /* return value is ignored as this is called via lua_pcall */
    return 0;
}
/* const char *luaL_checklstring (lua_State *L, int narg, size_t *l); */

typedef struct {
  int narg;
  size_t *l;
  const char * retval;
} checklstring_S;

int wrap_checklstring ( lua_State *L )
{
    checklstring_S *data = (checklstring_S *) lua_touserdata( L, -1 );

    /* ...remove it from the stack */
    lua_pop( L, 1 );

    /* call the function; return value in the struct bypassing Lua */
    data->retval = luaL_checklstring( L, data->narg, data->l );

    /* return value is ignored as this is called via lua_pcall */
    return 0;
}
/* int luaL_checkoption (lua_State *L, int narg, const char *def, const char *const lst[]); */

typedef struct {
  int narg;
  const char *def;
  const char * const * lst;
  int retval;
} checkoption_S;

int wrap_checkoption ( lua_State *L )
{
    checkoption_S *data = (checkoption_S *) lua_touserdata( L, -1 );

    /* ...remove it from the stack */
    lua_pop( L, 1 );

    /* call the function; return value in the struct bypassing Lua */
    data->retval = luaL_checkoption( L, data->narg, data->def, data->lst );

    /* return value is ignored as this is called via lua_pcall */
    return 0;
}
/* int luaL_optint (lua_State *L, int narg, int d); */

typedef struct {
  int narg;
  int d;
  int retval;
} optint_S;

int wrap_optint ( lua_State *L )
{
    optint_S *data = (optint_S *) lua_touserdata( L, -1 );

    /* ...remove it from the stack */
    lua_pop( L, 1 );

    /* call the function; return value in the struct bypassing Lua */
    data->retval = luaL_optint( L, data->narg, data->d );

    /* return value is ignored as this is called via lua_pcall */
    return 0;
}
/* void *luaL_checkudata (lua_State *L, int narg, const char *tname); */

typedef struct {
  int narg;
  const char *tname;
  void * retval;
} checkudata_S;

int wrap_checkudata ( lua_State *L )
{
    checkudata_S *data = (checkudata_S *) lua_touserdata( L, -1 );

    /* ...remove it from the stack */
    lua_pop( L, 1 );

    /* call the function; return value in the struct bypassing Lua */
    data->retval = luaL_checkudata( L, data->narg, data->tname );

    /* return value is ignored as this is called via lua_pcall */
    return 0;
}
/* const char *luaL_checkstring (lua_State *L, int narg); */

typedef struct {
  int narg;
  const char * retval;
} checkstring_S;

int wrap_checkstring ( lua_State *L )
{
    checkstring_S *data = (checkstring_S *) lua_touserdata( L, -1 );

    /* ...remove it from the stack */
    lua_pop( L, 1 );

    /* call the function; return value in the struct bypassing Lua */
    data->retval = luaL_checkstring( L, data->narg );

    /* return value is ignored as this is called via lua_pcall */
    return 0;
}
/* long luaL_optlong (lua_State *L, int narg, long d); */

typedef struct {
  int narg;
  long d;
  long retval;
} optlong_S;

int wrap_optlong ( lua_State *L )
{
    optlong_S *data = (optlong_S *) lua_touserdata( L, -1 );

    /* ...remove it from the stack */
    lua_pop( L, 1 );

    /* call the function; return value in the struct bypassing Lua */
    data->retval = luaL_optlong( L, data->narg, data->d );

    /* return value is ignored as this is called via lua_pcall */
    return 0;
}
/* const char *luaL_optlstring (lua_State *L, int narg, const char *d, size_t *l); */

typedef struct {
  int narg;
  const char *d;
  size_t *l;
  const char * retval;
} optlstring_S;

int wrap_optlstring ( lua_State *L )
{
    optlstring_S *data = (optlstring_S *) lua_touserdata( L, -1 );

    /* ...remove it from the stack */
    lua_pop( L, 1 );

    /* call the function; return value in the struct bypassing Lua */
    data->retval = luaL_optlstring( L, data->narg, data->d, data->l );

    /* return value is ignored as this is called via lua_pcall */
    return 0;
}
/* lua_Number luaL_checknumber (lua_State *L, int narg); */

typedef struct {
  int narg;
  lua_Number retval;
} checknumber_S;

int wrap_checknumber ( lua_State *L )
{
    checknumber_S *data = (checknumber_S *) lua_touserdata( L, -1 );

    /* ...remove it from the stack */
    lua_pop( L, 1 );

    /* call the function; return value in the struct bypassing Lua */
    data->retval = luaL_checknumber( L, data->narg );

    /* return value is ignored as this is called via lua_pcall */
    return 0;
}
/* int luaL_typerror (lua_State *L, int narg, const char *tname);
 */

typedef struct {
  int narg;
  const char *tname;
  int retval;
} typerror_S;

int wrap_typerror ( lua_State *L )
{
    typerror_S *data = (typerror_S *) lua_touserdata( L, -1 );

    /* ...remove it from the stack */
    lua_pop( L, 1 );

    /* call the function; return value in the struct bypassing Lua */
    data->retval = luaL_typerror( L, data->narg, data->tname );

    /* return value is ignored as this is called via lua_pcall */
    return 0;
}
/* const char *luaL_optstring (lua_State *L, int narg, const char *d); */

typedef struct {
  int narg;
  const char *d;
  const char * retval;
} optstring_S;

int wrap_optstring ( lua_State *L )
{
    optstring_S *data = (optstring_S *) lua_touserdata( L, -1 );

    /* ...remove it from the stack */
    lua_pop( L, 1 );

    /* call the function; return value in the struct bypassing Lua */
    data->retval = luaL_optstring( L, data->narg, data->d );

    /* return value is ignored as this is called via lua_pcall */
    return 0;
}
/* lua_Integer luaL_checkinteger (lua_State *L, int narg); */

typedef struct {
  int narg;
  lua_Integer retval;
} checkinteger_S;

int wrap_checkinteger ( lua_State *L )
{
    checkinteger_S *data = (checkinteger_S *) lua_touserdata( L, -1 );

    /* ...remove it from the stack */
    lua_pop( L, 1 );

    /* call the function; return value in the struct bypassing Lua */
    data->retval = luaL_checkinteger( L, data->narg );

    /* return value is ignored as this is called via lua_pcall */
    return 0;
}
/* lua_Number luaL_optnumber (lua_State *L, int narg, lua_Number d); */

typedef struct {
  int narg;
  lua_Number d;
  lua_Number retval;
} optnumber_S;

int wrap_optnumber ( lua_State *L )
{
    optnumber_S *data = (optnumber_S *) lua_touserdata( L, -1 );

    /* ...remove it from the stack */
    lua_pop( L, 1 );

    /* call the function; return value in the struct bypassing Lua */
    data->retval = luaL_optnumber( L, data->narg, data->d );

    /* return value is ignored as this is called via lua_pcall */
    return 0;
}

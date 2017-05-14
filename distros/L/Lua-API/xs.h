long
luaL_checklong(L, narg )
	lua_State *	L
        int narg
     PREINIT:
        int stacklen;
	int stackpos;
/* long luaL_checklong (lua_State *L, int narg); */
        checklong_S data;
	data.narg = narg;
     CODE:
         /* catch Lua error and transform it into a Perl one by
	   calling a C wrapper, duplicating the stack so that
	   it can be checked*/
        stacklen = lua_gettop( L );
	if ( ! lua_checkstack( L, stacklen + 2 ) )
            croak( "Perl Lua::API::wrap_checklong: error extending stack\n" );
        /* push C wrapper */
        lua_pushcfunction(L, &wrap_checklong );
	/* duplicate stack  */
	for( stackpos = 1 ; stackpos <= stacklen ; stackpos++ )
	   lua_pushvalue( L, stackpos );
	/* push struct containing the parameters */
	lua_pushlightuserdata( L, &data );
        if ( lua_pcall( L, stacklen+1, 0, 0 ) ) {
	  SV *rv = newSV(0);
	  SV *sv = newSVrv( rv, "Lua::API::State::Error" );
          sv_setsv((SV*) get_sv("@", GV_ADD), rv);
  	  croak(NULL);
        }
        
        /* no error; extract return value from call and pass it up */
        else {
          RETVAL = data.retval;
        }
     OUTPUT:
          RETVAL
                  
void
luaL_checktype(L, narg, t )
	lua_State *	L
        int narg
        int t
     PREINIT:
        int stacklen;
	int stackpos;
/* void luaL_checktype (lua_State *L, int narg, int t); */
        checktype_S data;
	data.narg = narg;
	data.t = t;
     CODE:
         /* catch Lua error and transform it into a Perl one by
	   calling a C wrapper, duplicating the stack so that
	   it can be checked*/
        stacklen = lua_gettop( L );
	if ( ! lua_checkstack( L, stacklen + 2 ) )
            croak( "Perl Lua::API::wrap_checktype: error extending stack\n" );
        /* push C wrapper */
        lua_pushcfunction(L, &wrap_checktype );
	/* duplicate stack  */
	for( stackpos = 1 ; stackpos <= stacklen ; stackpos++ )
	   lua_pushvalue( L, stackpos );
	/* push struct containing the parameters */
	lua_pushlightuserdata( L, &data );
        if ( lua_pcall( L, stacklen+1, 0, 0 ) ) {
	  SV *rv = newSV(0);
	  SV *sv = newSVrv( rv, "Lua::API::State::Error" );
          sv_setsv((SV*) get_sv("@", GV_ADD), rv);
  	  croak(NULL);
        }
        
void
luaL_checkany(L, narg )
	lua_State *	L
        int narg
     PREINIT:
        int stacklen;
	int stackpos;
/* void luaL_checkany (lua_State *L, int narg); */
        checkany_S data;
	data.narg = narg;
     CODE:
         /* catch Lua error and transform it into a Perl one by
	   calling a C wrapper, duplicating the stack so that
	   it can be checked*/
        stacklen = lua_gettop( L );
	if ( ! lua_checkstack( L, stacklen + 2 ) )
            croak( "Perl Lua::API::wrap_checkany: error extending stack\n" );
        /* push C wrapper */
        lua_pushcfunction(L, &wrap_checkany );
	/* duplicate stack  */
	for( stackpos = 1 ; stackpos <= stacklen ; stackpos++ )
	   lua_pushvalue( L, stackpos );
	/* push struct containing the parameters */
	lua_pushlightuserdata( L, &data );
        if ( lua_pcall( L, stacklen+1, 0, 0 ) ) {
	  SV *rv = newSV(0);
	  SV *sv = newSVrv( rv, "Lua::API::State::Error" );
          sv_setsv((SV*) get_sv("@", GV_ADD), rv);
  	  croak(NULL);
        }
        
void
luaL_argcheck(L, cond, narg, extramsg )
	lua_State *	L
        int cond
        int narg
        const char * extramsg
     PREINIT:
        int stacklen;
	int stackpos;
/* void luaL_argcheck (lua_State *L, int cond, int narg, const char *extramsg); */
        argcheck_S data;
	data.cond = cond;
	data.narg = narg;
	data.extramsg = extramsg;
     CODE:
         /* catch Lua error and transform it into a Perl one by
	   calling a C wrapper, duplicating the stack so that
	   it can be checked*/
        stacklen = lua_gettop( L );
	if ( ! lua_checkstack( L, stacklen + 2 ) )
            croak( "Perl Lua::API::wrap_argcheck: error extending stack\n" );
        /* push C wrapper */
        lua_pushcfunction(L, &wrap_argcheck );
	/* duplicate stack  */
	for( stackpos = 1 ; stackpos <= stacklen ; stackpos++ )
	   lua_pushvalue( L, stackpos );
	/* push struct containing the parameters */
	lua_pushlightuserdata( L, &data );
        if ( lua_pcall( L, stacklen+1, 0, 0 ) ) {
	  SV *rv = newSV(0);
	  SV *sv = newSVrv( rv, "Lua::API::State::Error" );
          sv_setsv((SV*) get_sv("@", GV_ADD), rv);
  	  croak(NULL);
        }
        
int
luaL_checkint(L, narg )
	lua_State *	L
        int narg
     PREINIT:
        int stacklen;
	int stackpos;
/* int luaL_checkint (lua_State *L, int narg); */
        checkint_S data;
	data.narg = narg;
     CODE:
         /* catch Lua error and transform it into a Perl one by
	   calling a C wrapper, duplicating the stack so that
	   it can be checked*/
        stacklen = lua_gettop( L );
	if ( ! lua_checkstack( L, stacklen + 2 ) )
            croak( "Perl Lua::API::wrap_checkint: error extending stack\n" );
        /* push C wrapper */
        lua_pushcfunction(L, &wrap_checkint );
	/* duplicate stack  */
	for( stackpos = 1 ; stackpos <= stacklen ; stackpos++ )
	   lua_pushvalue( L, stackpos );
	/* push struct containing the parameters */
	lua_pushlightuserdata( L, &data );
        if ( lua_pcall( L, stacklen+1, 0, 0 ) ) {
	  SV *rv = newSV(0);
	  SV *sv = newSVrv( rv, "Lua::API::State::Error" );
          sv_setsv((SV*) get_sv("@", GV_ADD), rv);
  	  croak(NULL);
        }
        
        /* no error; extract return value from call and pass it up */
        else {
          RETVAL = data.retval;
        }
     OUTPUT:
          RETVAL
                  
int
luaL_argerror(L, narg, extramsg )
	lua_State *	L
        int narg
        const char * extramsg
     PREINIT:
        int stacklen;
	int stackpos;
/* int luaL_argerror (lua_State *L, int narg, const char *extramsg); */
        argerror_S data;
	data.narg = narg;
	data.extramsg = extramsg;
     CODE:
         /* catch Lua error and transform it into a Perl one by
	   calling a C wrapper, duplicating the stack so that
	   it can be checked*/
        stacklen = lua_gettop( L );
	if ( ! lua_checkstack( L, stacklen + 2 ) )
            croak( "Perl Lua::API::wrap_argerror: error extending stack\n" );
        /* push C wrapper */
        lua_pushcfunction(L, &wrap_argerror );
	/* duplicate stack  */
	for( stackpos = 1 ; stackpos <= stacklen ; stackpos++ )
	   lua_pushvalue( L, stackpos );
	/* push struct containing the parameters */
	lua_pushlightuserdata( L, &data );
        if ( lua_pcall( L, stacklen+1, 0, 0 ) ) {
	  SV *rv = newSV(0);
	  SV *sv = newSVrv( rv, "Lua::API::State::Error" );
          sv_setsv((SV*) get_sv("@", GV_ADD), rv);
  	  croak(NULL);
        }
        
        /* no error; extract return value from call and pass it up */
        else {
          RETVAL = data.retval;
        }
     OUTPUT:
          RETVAL
                  
lua_Integer
luaL_optinteger(L, narg, d )
	lua_State *	L
        int narg
        lua_Integer d
     PREINIT:
        int stacklen;
	int stackpos;
/* lua_Integer luaL_optinteger (lua_State *L, int narg, lua_Integer d); */
        optinteger_S data;
	data.narg = narg;
	data.d = d;
     CODE:
         /* catch Lua error and transform it into a Perl one by
	   calling a C wrapper, duplicating the stack so that
	   it can be checked*/
        stacklen = lua_gettop( L );
	if ( ! lua_checkstack( L, stacklen + 2 ) )
            croak( "Perl Lua::API::wrap_optinteger: error extending stack\n" );
        /* push C wrapper */
        lua_pushcfunction(L, &wrap_optinteger );
	/* duplicate stack  */
	for( stackpos = 1 ; stackpos <= stacklen ; stackpos++ )
	   lua_pushvalue( L, stackpos );
	/* push struct containing the parameters */
	lua_pushlightuserdata( L, &data );
        if ( lua_pcall( L, stacklen+1, 0, 0 ) ) {
	  SV *rv = newSV(0);
	  SV *sv = newSVrv( rv, "Lua::API::State::Error" );
          sv_setsv((SV*) get_sv("@", GV_ADD), rv);
  	  croak(NULL);
        }
        
        /* no error; extract return value from call and pass it up */
        else {
          RETVAL = data.retval;
        }
     OUTPUT:
          RETVAL
                  
const char *
luaL_checklstring(L, narg, l )
	lua_State *	L
        int narg
        size_t & l = NO_INIT
     PREINIT:
        int stacklen;
	int stackpos;
/* const char *luaL_checklstring (lua_State *L, int narg, size_t *l); */
        checklstring_S data;
	data.narg = narg;
	data.l = &l;
     CODE:
         /* catch Lua error and transform it into a Perl one by
	   calling a C wrapper, duplicating the stack so that
	   it can be checked*/
        stacklen = lua_gettop( L );
	if ( ! lua_checkstack( L, stacklen + 2 ) )
            croak( "Perl Lua::API::wrap_checklstring: error extending stack\n" );
        /* push C wrapper */
        lua_pushcfunction(L, &wrap_checklstring );
	/* duplicate stack  */
	for( stackpos = 1 ; stackpos <= stacklen ; stackpos++ )
	   lua_pushvalue( L, stackpos );
	/* push struct containing the parameters */
	lua_pushlightuserdata( L, &data );
        if ( lua_pcall( L, stacklen+1, 0, 0 ) ) {
	  SV *rv = newSV(0);
	  SV *sv = newSVrv( rv, "Lua::API::State::Error" );
          sv_setsv((SV*) get_sv("@", GV_ADD), rv);
  	  croak(NULL);
        }
        
        /* no error; extract return value from call and pass it up */
        else {
          RETVAL = data.retval;
        }
     OUTPUT:
          RETVAL
          l
        
int
luaL_checkoption(L, narg, def, lst )
	lua_State *	L
        int narg
        const char * def
        const char * const * lst
     PREINIT:
        int stacklen;
	int stackpos;
/* int luaL_checkoption (lua_State *L, int narg, const char *def, const char *const lst[]); */
        checkoption_S data;
	data.narg = narg;
	data.def = def;
	data.lst = lst;
     CODE:
         /* catch Lua error and transform it into a Perl one by
	   calling a C wrapper, duplicating the stack so that
	   it can be checked*/
        stacklen = lua_gettop( L );
	if ( ! lua_checkstack( L, stacklen + 2 ) )
            croak( "Perl Lua::API::wrap_checkoption: error extending stack\n" );
        /* push C wrapper */
        lua_pushcfunction(L, &wrap_checkoption );
	/* duplicate stack  */
	for( stackpos = 1 ; stackpos <= stacklen ; stackpos++ )
	   lua_pushvalue( L, stackpos );
	/* push struct containing the parameters */
	lua_pushlightuserdata( L, &data );
        if ( lua_pcall( L, stacklen+1, 0, 0 ) ) {
	  SV *rv = newSV(0);
	  SV *sv = newSVrv( rv, "Lua::API::State::Error" );
          sv_setsv((SV*) get_sv("@", GV_ADD), rv);
  	  croak(NULL);
        }
        
        /* no error; extract return value from call and pass it up */
        else {
          RETVAL = data.retval;
        }
     OUTPUT:
          RETVAL
                  
int
luaL_optint(L, narg, d )
	lua_State *	L
        int narg
        int d
     PREINIT:
        int stacklen;
	int stackpos;
/* int luaL_optint (lua_State *L, int narg, int d); */
        optint_S data;
	data.narg = narg;
	data.d = d;
     CODE:
         /* catch Lua error and transform it into a Perl one by
	   calling a C wrapper, duplicating the stack so that
	   it can be checked*/
        stacklen = lua_gettop( L );
	if ( ! lua_checkstack( L, stacklen + 2 ) )
            croak( "Perl Lua::API::wrap_optint: error extending stack\n" );
        /* push C wrapper */
        lua_pushcfunction(L, &wrap_optint );
	/* duplicate stack  */
	for( stackpos = 1 ; stackpos <= stacklen ; stackpos++ )
	   lua_pushvalue( L, stackpos );
	/* push struct containing the parameters */
	lua_pushlightuserdata( L, &data );
        if ( lua_pcall( L, stacklen+1, 0, 0 ) ) {
	  SV *rv = newSV(0);
	  SV *sv = newSVrv( rv, "Lua::API::State::Error" );
          sv_setsv((SV*) get_sv("@", GV_ADD), rv);
  	  croak(NULL);
        }
        
        /* no error; extract return value from call and pass it up */
        else {
          RETVAL = data.retval;
        }
     OUTPUT:
          RETVAL
                  
void *
luaL_checkudata(L, narg, tname )
	lua_State *	L
        int narg
        const char * tname
     PREINIT:
        int stacklen;
	int stackpos;
/* void *luaL_checkudata (lua_State *L, int narg, const char *tname); */
        checkudata_S data;
	data.narg = narg;
	data.tname = tname;
     CODE:
         /* catch Lua error and transform it into a Perl one by
	   calling a C wrapper, duplicating the stack so that
	   it can be checked*/
        stacklen = lua_gettop( L );
	if ( ! lua_checkstack( L, stacklen + 2 ) )
            croak( "Perl Lua::API::wrap_checkudata: error extending stack\n" );
        /* push C wrapper */
        lua_pushcfunction(L, &wrap_checkudata );
	/* duplicate stack  */
	for( stackpos = 1 ; stackpos <= stacklen ; stackpos++ )
	   lua_pushvalue( L, stackpos );
	/* push struct containing the parameters */
	lua_pushlightuserdata( L, &data );
        if ( lua_pcall( L, stacklen+1, 0, 0 ) ) {
	  SV *rv = newSV(0);
	  SV *sv = newSVrv( rv, "Lua::API::State::Error" );
          sv_setsv((SV*) get_sv("@", GV_ADD), rv);
  	  croak(NULL);
        }
        
        /* no error; extract return value from call and pass it up */
        else {
          RETVAL = data.retval;
        }
     OUTPUT:
          RETVAL
                  
const char *
luaL_checkstring(L, narg )
	lua_State *	L
        int narg
     PREINIT:
        int stacklen;
	int stackpos;
/* const char *luaL_checkstring (lua_State *L, int narg); */
        checkstring_S data;
	data.narg = narg;
     CODE:
         /* catch Lua error and transform it into a Perl one by
	   calling a C wrapper, duplicating the stack so that
	   it can be checked*/
        stacklen = lua_gettop( L );
	if ( ! lua_checkstack( L, stacklen + 2 ) )
            croak( "Perl Lua::API::wrap_checkstring: error extending stack\n" );
        /* push C wrapper */
        lua_pushcfunction(L, &wrap_checkstring );
	/* duplicate stack  */
	for( stackpos = 1 ; stackpos <= stacklen ; stackpos++ )
	   lua_pushvalue( L, stackpos );
	/* push struct containing the parameters */
	lua_pushlightuserdata( L, &data );
        if ( lua_pcall( L, stacklen+1, 0, 0 ) ) {
	  SV *rv = newSV(0);
	  SV *sv = newSVrv( rv, "Lua::API::State::Error" );
          sv_setsv((SV*) get_sv("@", GV_ADD), rv);
  	  croak(NULL);
        }
        
        /* no error; extract return value from call and pass it up */
        else {
          RETVAL = data.retval;
        }
     OUTPUT:
          RETVAL
                  
long
luaL_optlong(L, narg, d )
	lua_State *	L
        int narg
        long d
     PREINIT:
        int stacklen;
	int stackpos;
/* long luaL_optlong (lua_State *L, int narg, long d); */
        optlong_S data;
	data.narg = narg;
	data.d = d;
     CODE:
         /* catch Lua error and transform it into a Perl one by
	   calling a C wrapper, duplicating the stack so that
	   it can be checked*/
        stacklen = lua_gettop( L );
	if ( ! lua_checkstack( L, stacklen + 2 ) )
            croak( "Perl Lua::API::wrap_optlong: error extending stack\n" );
        /* push C wrapper */
        lua_pushcfunction(L, &wrap_optlong );
	/* duplicate stack  */
	for( stackpos = 1 ; stackpos <= stacklen ; stackpos++ )
	   lua_pushvalue( L, stackpos );
	/* push struct containing the parameters */
	lua_pushlightuserdata( L, &data );
        if ( lua_pcall( L, stacklen+1, 0, 0 ) ) {
	  SV *rv = newSV(0);
	  SV *sv = newSVrv( rv, "Lua::API::State::Error" );
          sv_setsv((SV*) get_sv("@", GV_ADD), rv);
  	  croak(NULL);
        }
        
        /* no error; extract return value from call and pass it up */
        else {
          RETVAL = data.retval;
        }
     OUTPUT:
          RETVAL
                  
const char *
luaL_optlstring(L, narg, d, l )
	lua_State *	L
        int narg
        const char * d
        size_t & l = NO_INIT
     PREINIT:
        int stacklen;
	int stackpos;
/* const char *luaL_optlstring (lua_State *L, int narg, const char *d, size_t *l); */
        optlstring_S data;
	data.narg = narg;
	data.d = d;
	data.l = &l;
     CODE:
         /* catch Lua error and transform it into a Perl one by
	   calling a C wrapper, duplicating the stack so that
	   it can be checked*/
        stacklen = lua_gettop( L );
	if ( ! lua_checkstack( L, stacklen + 2 ) )
            croak( "Perl Lua::API::wrap_optlstring: error extending stack\n" );
        /* push C wrapper */
        lua_pushcfunction(L, &wrap_optlstring );
	/* duplicate stack  */
	for( stackpos = 1 ; stackpos <= stacklen ; stackpos++ )
	   lua_pushvalue( L, stackpos );
	/* push struct containing the parameters */
	lua_pushlightuserdata( L, &data );
        if ( lua_pcall( L, stacklen+1, 0, 0 ) ) {
	  SV *rv = newSV(0);
	  SV *sv = newSVrv( rv, "Lua::API::State::Error" );
          sv_setsv((SV*) get_sv("@", GV_ADD), rv);
  	  croak(NULL);
        }
        
        /* no error; extract return value from call and pass it up */
        else {
          RETVAL = data.retval;
        }
     OUTPUT:
          RETVAL
          l
        
lua_Number
luaL_checknumber(L, narg )
	lua_State *	L
        int narg
     PREINIT:
        int stacklen;
	int stackpos;
/* lua_Number luaL_checknumber (lua_State *L, int narg); */
        checknumber_S data;
	data.narg = narg;
     CODE:
         /* catch Lua error and transform it into a Perl one by
	   calling a C wrapper, duplicating the stack so that
	   it can be checked*/
        stacklen = lua_gettop( L );
	if ( ! lua_checkstack( L, stacklen + 2 ) )
            croak( "Perl Lua::API::wrap_checknumber: error extending stack\n" );
        /* push C wrapper */
        lua_pushcfunction(L, &wrap_checknumber );
	/* duplicate stack  */
	for( stackpos = 1 ; stackpos <= stacklen ; stackpos++ )
	   lua_pushvalue( L, stackpos );
	/* push struct containing the parameters */
	lua_pushlightuserdata( L, &data );
        if ( lua_pcall( L, stacklen+1, 0, 0 ) ) {
	  SV *rv = newSV(0);
	  SV *sv = newSVrv( rv, "Lua::API::State::Error" );
          sv_setsv((SV*) get_sv("@", GV_ADD), rv);
  	  croak(NULL);
        }
        
        /* no error; extract return value from call and pass it up */
        else {
          RETVAL = data.retval;
        }
     OUTPUT:
          RETVAL
                  
int
luaL_typerror(L, narg, tname )
	lua_State *	L
        int narg
        const char * tname
     PREINIT:
        int stacklen;
	int stackpos;
/* int luaL_typerror (lua_State *L, int narg, const char *tname);
 */
        typerror_S data;
	data.narg = narg;
	data.tname = tname;
     CODE:
         /* catch Lua error and transform it into a Perl one by
	   calling a C wrapper, duplicating the stack so that
	   it can be checked*/
        stacklen = lua_gettop( L );
	if ( ! lua_checkstack( L, stacklen + 2 ) )
            croak( "Perl Lua::API::wrap_typerror: error extending stack\n" );
        /* push C wrapper */
        lua_pushcfunction(L, &wrap_typerror );
	/* duplicate stack  */
	for( stackpos = 1 ; stackpos <= stacklen ; stackpos++ )
	   lua_pushvalue( L, stackpos );
	/* push struct containing the parameters */
	lua_pushlightuserdata( L, &data );
        if ( lua_pcall( L, stacklen+1, 0, 0 ) ) {
	  SV *rv = newSV(0);
	  SV *sv = newSVrv( rv, "Lua::API::State::Error" );
          sv_setsv((SV*) get_sv("@", GV_ADD), rv);
  	  croak(NULL);
        }
        
        /* no error; extract return value from call and pass it up */
        else {
          RETVAL = data.retval;
        }
     OUTPUT:
          RETVAL
                  
const char *
luaL_optstring(L, narg, d )
	lua_State *	L
        int narg
        const char * d
     PREINIT:
        int stacklen;
	int stackpos;
/* const char *luaL_optstring (lua_State *L, int narg, const char *d); */
        optstring_S data;
	data.narg = narg;
	data.d = d;
     CODE:
         /* catch Lua error and transform it into a Perl one by
	   calling a C wrapper, duplicating the stack so that
	   it can be checked*/
        stacklen = lua_gettop( L );
	if ( ! lua_checkstack( L, stacklen + 2 ) )
            croak( "Perl Lua::API::wrap_optstring: error extending stack\n" );
        /* push C wrapper */
        lua_pushcfunction(L, &wrap_optstring );
	/* duplicate stack  */
	for( stackpos = 1 ; stackpos <= stacklen ; stackpos++ )
	   lua_pushvalue( L, stackpos );
	/* push struct containing the parameters */
	lua_pushlightuserdata( L, &data );
        if ( lua_pcall( L, stacklen+1, 0, 0 ) ) {
	  SV *rv = newSV(0);
	  SV *sv = newSVrv( rv, "Lua::API::State::Error" );
          sv_setsv((SV*) get_sv("@", GV_ADD), rv);
  	  croak(NULL);
        }
        
        /* no error; extract return value from call and pass it up */
        else {
          RETVAL = data.retval;
        }
     OUTPUT:
          RETVAL
                  
lua_Integer
luaL_checkinteger(L, narg )
	lua_State *	L
        int narg
     PREINIT:
        int stacklen;
	int stackpos;
/* lua_Integer luaL_checkinteger (lua_State *L, int narg); */
        checkinteger_S data;
	data.narg = narg;
     CODE:
         /* catch Lua error and transform it into a Perl one by
	   calling a C wrapper, duplicating the stack so that
	   it can be checked*/
        stacklen = lua_gettop( L );
	if ( ! lua_checkstack( L, stacklen + 2 ) )
            croak( "Perl Lua::API::wrap_checkinteger: error extending stack\n" );
        /* push C wrapper */
        lua_pushcfunction(L, &wrap_checkinteger );
	/* duplicate stack  */
	for( stackpos = 1 ; stackpos <= stacklen ; stackpos++ )
	   lua_pushvalue( L, stackpos );
	/* push struct containing the parameters */
	lua_pushlightuserdata( L, &data );
        if ( lua_pcall( L, stacklen+1, 0, 0 ) ) {
	  SV *rv = newSV(0);
	  SV *sv = newSVrv( rv, "Lua::API::State::Error" );
          sv_setsv((SV*) get_sv("@", GV_ADD), rv);
  	  croak(NULL);
        }
        
        /* no error; extract return value from call and pass it up */
        else {
          RETVAL = data.retval;
        }
     OUTPUT:
          RETVAL
                  
lua_Number
luaL_optnumber(L, narg, d )
	lua_State *	L
        int narg
        lua_Number d
     PREINIT:
        int stacklen;
	int stackpos;
/* lua_Number luaL_optnumber (lua_State *L, int narg, lua_Number d); */
        optnumber_S data;
	data.narg = narg;
	data.d = d;
     CODE:
         /* catch Lua error and transform it into a Perl one by
	   calling a C wrapper, duplicating the stack so that
	   it can be checked*/
        stacklen = lua_gettop( L );
	if ( ! lua_checkstack( L, stacklen + 2 ) )
            croak( "Perl Lua::API::wrap_optnumber: error extending stack\n" );
        /* push C wrapper */
        lua_pushcfunction(L, &wrap_optnumber );
	/* duplicate stack  */
	for( stackpos = 1 ; stackpos <= stacklen ; stackpos++ )
	   lua_pushvalue( L, stackpos );
	/* push struct containing the parameters */
	lua_pushlightuserdata( L, &data );
        if ( lua_pcall( L, stacklen+1, 0, 0 ) ) {
	  SV *rv = newSV(0);
	  SV *sv = newSVrv( rv, "Lua::API::State::Error" );
          sv_setsv((SV*) get_sv("@", GV_ADD), rv);
  	  croak(NULL);
        }
        
        /* no error; extract return value from call and pass it up */
        else {
          RETVAL = data.retval;
        }
     OUTPUT:
          RETVAL
                  

[% type %]
[% lua_funcname %](L, [%- FOREACH arg IN args -%]
[%- arg.name -%][%- ", "  IF ! loop.last -%] [%- END -%] )
	lua_State *	L
[%- FOREACH arg IN args %]
        [% arg.xsdef %]
[%- END %]
     PREINIT:
        int stacklen;
	int stackpos;
/* [% proto %] */
        [% structname %] data;
	[%- FOREACH input IN inputs %]
	[% "data.${input} = ${input};" -%]
	[%- END -%]
	[%- FOREACH output IN outputs %]
	[% "data.${output} = &${output};" -%]
	[%- END %]
     CODE:
         /* catch Lua error and transform it into a Perl one by
	   calling a C wrapper, duplicating the stack so that
	   it can be checked*/
        stacklen = lua_gettop( L );
	if ( ! lua_checkstack( L, stacklen + 2 ) )
            croak( "Perl Lua::API::wrap_[% func %]: error extending stack\n" );
        /* push C wrapper */
        lua_pushcfunction(L, &[%- fwrap -%] );
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
        [% IF type != 'void' %]
        /* no error; extract return value from call and pass it up */
        else {
          RETVAL = data.retval;
        }
     OUTPUT:
          RETVAL
          [% "$output\n" FOREACH output IN outputs -%]
        [% END %]

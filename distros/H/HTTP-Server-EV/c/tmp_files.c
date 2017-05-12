///// Work with tempfiles

	static SV* create_tmp (struct req_state *state){
		HV* hash = newHV();
		state->tmpfile_obj = sv_bless( newRV_noinc((SV*) hash) ,   gv_stashpv( "HTTP::Server::EV::MultipartFile", GV_ADD) );
		
		hv_store(hash, "size", 4, (SV*) newSViv(0) , 0);
		
		SV* filename =newSVpv(state->buf2, state->buf2_pos);
		SvUTF8_on(filename);
		hv_store(hash, "name" , 4 , filename , 0);
		
		SV* parent = newSVsv(state->req_obj);
		sv_rvweaken(parent);
		hv_store(hash, "parent_req", 10, parent , 0);
		
		state->body_chunk_pos = 0;
		
		dSP;
		ENTER;
		SAVETMPS;

		PUSHMARK (SP);
		XPUSHs (state->tmpfile_obj);

		PUTBACK;
			call_method ("_new", G_DISCARD);
		// PUTBACK;
		FREETMPS;
		LEAVE;
		
		return state->tmpfile_obj;
	}
	
	
	static void tmp_putc (struct req_state *state, char chr){
		
		state->body_chunk[state->body_chunk_pos] = chr;
		state->body_chunk_pos++;
		
		
		if(state->body_chunk_pos >= BODY_CHUNK_BUFSIZ){
			dSP;
			ENTER;
			SAVETMPS;

			PUSHMARK (SP);
			XPUSHs (state->tmpfile_obj);
			XPUSHs ( sv_2mortal(
				newSVpvn( state->body_chunk, BODY_CHUNK_BUFSIZ-2 )
			));
			
			PUTBACK;
				call_method ("_flush", G_DISCARD);
			// PUTBACK;
			FREETMPS;
			LEAVE;
			
			state->body_chunk[0] = state->body_chunk[BODY_CHUNK_BUFSIZ-2];
			state->body_chunk[1] = state->body_chunk[BODY_CHUNK_BUFSIZ-1];
			state->body_chunk_pos = 2;
		}
	}
	
	
	static char tmp_close(struct req_state *state){
		char wait = 0; // reports to main cycle if it need to return and wait for IO complete
		
		
		if(state->body_chunk_pos > 2){
			wait = 1; 
		
			dSP;
			ENTER;
			SAVETMPS;

			PUSHMARK (SP);
			XPUSHs (state->tmpfile_obj);
			XPUSHs ( sv_2mortal(
				newSVpvn( state->body_chunk, state->body_chunk_pos-2 )
			));
			
			PUTBACK;
				call_method ("_flush", G_DISCARD);
			// PUTBACK;
			FREETMPS;
			LEAVE;
		};
		
		
		dSP;
		ENTER;
		SAVETMPS;

		PUSHMARK (SP);
		XPUSHs (state->tmpfile_obj);

		PUTBACK;
			call_method ("_done", G_VOID);
		// PUTBACK;
		FREETMPS;
		LEAVE;
		
		return wait;
}


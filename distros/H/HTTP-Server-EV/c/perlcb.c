//// Callbacks ////
static void init_cgi_obj(struct req_state *state){
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	XPUSHs( state->req_obj );
	PUTBACK;
	
	call_method ("new", G_DISCARD);
	
	FREETMPS;
	LEAVE;
};

static void call_perl(struct req_state *state){
	hv_store(state->rethash, "received", 8, newSViv(1) , 0);
	
	ev_timer_stop(EV_DEFAULT, &(state->timer) ); 
	
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	XPUSHs( state->req_obj );
	PUTBACK;
	
	call_sv(state->parent_listener->callback, G_VOID);
	free_state( state );
	
	
	FREETMPS;
	LEAVE;
};

static void call_pre_callback(struct req_state *state){
	init_cgi_obj(state);
	
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	XPUSHs( state->req_obj );
	PUTBACK;
	
	
	call_sv(state->parent_listener->pre_callback, G_VOID);
	
	FREETMPS;
	LEAVE;
};

static void perl_drop_conn_cb(struct req_state *state){
	if (state->reading >= BODY_M_NOTHING || state->reading == REQ_DROPED_BY_PERL){
			dSP;
			ENTER;
			SAVETMPS;
			PUSHMARK(SP);
			XPUSHs( state->req_obj );
			PUTBACK;
			
			call_sv(state->parent_listener->error_callback, G_VOID);
			
			FREETMPS;
			LEAVE;
		}
};



///// parsers state saving and memory allocating /////
struct req_state* *accepted;
static int accepted_pos = 0;

static int *accepted_stack;
static int accepted_stack_pos = 0;

static int accepted_allocated = 0;

struct req_state * alloc_state (){

	// alocate memory if needed
	if( ! accepted_stack_pos ){ 
		int i = accepted_allocated;
		
		accepted_allocated += ALLOCATE;

		if(!( 
				( accepted = (struct req_state **) realloc(accepted,  accepted_allocated * sizeof(struct req_state*) ) ) && 
				( accepted_stack = (int *) realloc(accepted_stack,  accepted_allocated * sizeof(int) ) )
			)
		  ){ return NULL; }

		
		// push in stack list of free to use elements
		for(; i < accepted_allocated; i++){ 
			char *state_memory;
			if(!( state_memory = malloc(
							sizeof(struct req_state) + //state
							SOCKREAD_BUFSIZ + 		// accepted[i]->buffer
							BUFFERS_SIZE +			// accepted[i]->buf 
							BUFFERS_SIZE + 			// accepted[i]->buf2
							BUFFERS_SIZE +			// accepted[i]->boundary
							BODY_CHUNK_BUFSIZ		//accepted[i]->body_chunk
					) ))
			{ return NULL; }
			
			accepted[i] = (struct req_state *) state_memory;
			state_memory += sizeof(struct req_state);
			
			accepted[i]->buffer = state_memory;
			state_memory += SOCKREAD_BUFSIZ;

			accepted[i]->buf = state_memory;
			state_memory += BUFFERS_SIZE;

			accepted[i]->buf2 = state_memory;
			state_memory += BUFFERS_SIZE;

			accepted[i]->boundary = state_memory;
			state_memory += BUFFERS_SIZE;
			
			accepted[i]->body_chunk = state_memory;

			
			accepted_stack[accepted_stack_pos] = i;
			accepted_stack_pos++;
		}
	}
	
	//get element from stack
	
	--accepted_stack_pos;
	struct req_state *state = accepted[ accepted_stack[accepted_stack_pos] ];
	state->saved_to = accepted_stack[accepted_stack_pos]; 
	
	//set fields to defaults
	
	
	memset( ((char *)state) + sizeof(struct req_state),
		0,  
		SOCKREAD_BUFSIZ + 		// accepted[i]->buffer
		BUFFERS_SIZE +			// accepted[i]->buf 
		BUFFERS_SIZE + 			// accepted[i]->buf2
		BUFFERS_SIZE +			// accepted[i]->boundary
		BODY_CHUNK_BUFSIZ		//accepted[i]->body_chunk
	);
	
	state->buf_pos = 0 ;
	state->buf2_pos = 0 ;
	state->match_pos = 0;
	
	state->buffer_pos = 0;
	state->body_chunk_pos = 0;
	
	state->reading = REQ_METHOD;
	
	state->content_length = 0;
	state->total_readed = 0;
	
	state->headers_end_match_pos = 0;
	state->headers_sep_match_pos = 0;
	
	
	//state->get = newHV();
	//state->get_a = newHV();
	
	state->multipart_name_match_pos = 0;
	state->multipart_filename_match_pos = 0;
	
	state->multipart_data_count = 0;
	
	state->headers = newHV();
	
	state->post = newHV();
	state->post_a = newHV();
	
	state->file = newHV();
	state->file_a = newHV();
	
	state->rethash = newHV();
	
	hv_store(state->rethash, "stack_pos", 9, (SV*) newSViv(state->saved_to) , 0);
	
	hv_store(state->rethash, "post" , 4, newRV_noinc((SV*)state->post), 0);
	hv_store(state->rethash, "post_a" , 6, newRV_noinc((SV*)state->post_a), 0);
	hv_store(state->rethash, "file" , 4, newRV_noinc((SV*)state->file), 0);
	hv_store(state->rethash, "file_a" , 6, newRV_noinc((SV*)state->file_a), 0);
	hv_store(state->rethash, "headers" , 7, newRV_noinc((SV*)state->headers), 0);
	
	state->req_obj = sv_bless( 
			newRV_noinc((SV*)state->rethash) ,
			gv_stashpv( "HTTP::Server::EV::CGI", GV_ADD) 
		);
	

	
	return state; // return pointer to allocated struct
}


static void free_state(struct req_state *state){
	SvREFCNT_dec(state->req_obj);
	accepted_stack[accepted_stack_pos] = state->saved_to;
	accepted_stack_pos++;
}

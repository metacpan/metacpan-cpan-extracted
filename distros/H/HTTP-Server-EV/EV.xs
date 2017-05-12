#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "EVAPI.h"
#include <sys/types.h>
#include <sys/socket.h>
#include <errno.h>


#define MAX_LISTEN_PORTS 24
#define ALLOCATE 1 
#define BUFFERS_SIZE 4100


//max multipart form fields
#ifndef MAX_DATA
	#define MAX_DATA 1024
#endif

#ifndef SOCKREAD_BUFSIZ
	#define SOCKREAD_BUFSIZ 8192
#endif

//multipart form field value limited by one chunk size. Also it's file receiving buffer - file piece stored on disc(and on_file_write_called) when BODY_CHUNK_BUFSIZ bytes received
#ifndef BODY_CHUNK_BUFSIZ
	#define BODY_CHUNK_BUFSIZ 51200
#endif

#ifndef MAX_URLENCODED_BODY
	#define MAX_URLENCODED_BODY 102400
#endif


#include "c/hse.h"
#include "c/tmp_files.c"
#include "c/memory.c"
#include "c/perlcb.c"



static void push_to_hash(HV* hash, char *key, int  klen, SV* data){
		SV** arrayref;
		if(arrayref = hv_fetch(hash, key, klen, 0)){
			av_push((AV*) SvRV( *arrayref ) , data);
			SvREFCNT_inc(data);
		} else {
			hv_store(hash, key, klen, newRV_noinc((SV*) av_make(1, &data )  )  , 0);
		}
	}


static int search(char input, char *line, int *match_pos ){
	if(input == line[ *match_pos ]){
		(*match_pos)++;
		
		if(! line[ *match_pos ] ){
			*match_pos = 0;
			return 1;
		}
	}else{
		*match_pos = 0;
	};
	return 0;
}

//////////

static void drop_conn (struct req_state *state, struct ev_loop *loop){
	
	perl_drop_conn_cb(state);
	
	ev_io_stop(loop, &(state->io) ); 
	ev_timer_stop(EV_DEFAULT, &(state->timer) ); 
	
	close( state->io.fd );
	
	ev_io_start(EV_DEFAULT, &( state->parent_listener->io) ); 	
	free_state(state);
}


static void timer_cb(struct ev_loop *loop, ev_timer *w, int revents) {
	drop_conn( (struct req_state *) w->data , loop);
}

#define COPY_CURRENT_CHAR_TO(CHR_BUF_NAME, CHR_BUF_SIZE) \
	state-> CHR_BUF_NAME [ state-> CHR_BUF_NAME ## _pos ] = state->buffer[state->buffer_pos];\
	state-> CHR_BUF_NAME ## _pos ++;\
	if(state-> CHR_BUF_NAME ## _pos >= CHR_BUF_SIZE){ return drop_conn(state, loop); }\
	
#define CONN_DROP_IF(EXPR) \
	if(EXPR){ return drop_conn(state, loop); }
	
	
static void handler_cb (struct ev_loop *loop, ev_io *w, int revents){
	struct req_state *state = (struct req_state *)w;
	
	struct sockaddr *buf;
	int bufsize = sizeof(struct sockaddr);
	
	CONN_DROP_IF(state->reading == REQ_DROPED_BY_PERL);
	
	if(!state->buffer_pos){ //called to read new data
		if( ( state->readed = PerlSock_recvfrom(w->fd, state->buffer, SOCKREAD_BUFSIZ,  0, buf, &bufsize) ) <= 0 ){
			// connection closed or error
			return drop_conn(state, loop);
		}
	} //else - woken up from suspending. Process existent data
	
	//reset timeout
	if (state->timeout != 0.)
		ev_timer_again(loop, &(state->timer));
	
	//write only shit...
	for(; state->buffer_pos < state->readed ; state->buffer_pos++ ){
		
		if(state->reading == REQ_DROPED_BY_PERL)
			return drop_conn(state, loop);
			
		if(state->reading & (1 << 7) )// 7 bit set - suspended
			return;
		
		// Read req string
		if(state->reading <= HEADERS_NOTHING) {
			if( search( state->buffer[state->buffer_pos], "\r\n", &state->headers_end_match_pos ) ){
				
				CONN_DROP_IF(!state->buf2_pos);  //no url
				
				// save to headers hash
				hv_store(state->headers, "REQUEST_METHOD" , 14 , newSVpv(state->buf, state->buf_pos) , 0);
				hv_store(state->headers, "REQUEST_URI" , 11 , newSVpv(state->buf2, state->buf2_pos) , 0);
				
				state->reading = HEADER_NAME;
				state->buf_pos = 0;
				state->buf2_pos = 0;
			}
			
			if(state->reading == URL_STRING){ // reading url string
				if(state->buffer[state->buffer_pos] == ' '){
					state->reading = HEADERS_NOTHING;
				}
				else{
					COPY_CURRENT_CHAR_TO(buf2, BUFFERS_SIZE);
				}
			}
			else if(state->reading == REQ_METHOD) { // reading request method
				if(state->buffer[state->buffer_pos] == ' '){ //end of reading request method
					state->reading = URL_STRING;
				}else{
					COPY_CURRENT_CHAR_TO(buf, BUFFERS_SIZE);
				}
			}
			
		}
		
		
		// read headers
		else if(state->reading <= HEADER_VALUE){
			if( search( state->buffer[state->buffer_pos], "\r\n", &state->headers_end_match_pos ) ){
				
				// end of headers
				if(state->buf_pos == 1){
					SV** hashval; 
					char *str;
					
					CONN_DROP_IF((! (hashval = hv_fetch(state->headers, "REQUEST_METHOD" , 14 , 0) ) ) );
					
					str = SvPV_nolen(*hashval);
					
					// method POST
					if( strEQ("POST", str) ){
						
						CONN_DROP_IF(! (hashval = hv_fetch(state->headers, "HTTP_CONTENT-LENGTH" , 19 , 0) ) );
						
						str = SvPV_nolen(*hashval);
						
						state->content_length = atoi(str);
						
						CONN_DROP_IF(! (hashval = hv_fetch(state->headers, "HTTP_CONTENT-TYPE" , 17 , 0) ) );
						
						STRLEN len;
						str = SvPV(*hashval, len);
						
						// multipart post data
						if((len > 3) && (str[0]=='m' || str[0]=='M') && (str[1]=='u' || str[1]=='U') && (str[2]=='l' || str[2]=='L') ){ 
							int i; int pos = 2;
							char reading_boundary = 0;
							state->boundary[0] = state->boundary[1] = '-';
							
							for(i = 0; i < len; i++){
								if(reading_boundary){
									state->boundary[pos] = str[i];
									pos++;
								}else
								if(str[i] == '='){ reading_boundary = 1; }
							}
							
							CONN_DROP_IF( (pos < 2) || !reading_boundary );
							
							
							state->reading = BODY_M_NOTHING;
							call_pre_callback(state);
						}
						// urlencoded data
						else{ 
							CONN_DROP_IF(state->content_length > MAX_URLENCODED_BODY);
							
							state->reading = BODY_URLENCODED;
							hv_store(state->rethash, "REQUEST_BODY" , 12 , newSV(1024) , 0);
						}
						
						//printf("Boundary: %s \nLen: %d", state->boundary, state->content_length);
						goto end_headers_reading;
					}
					// method GET
					else {
						init_cgi_obj(state);
						call_perl(state);
						ev_io_stop(loop, w); 
						break;
					}
					
				}
				
				state->reading = HEADER_NAME;
				if(state->buf2_pos > 0){state->buf2_pos -= 1;}  // because we don`t need "\r" in value
				
				//save to headers hash
				SV* val = newSVpv(state->buf2, state->buf2_pos);
				SvREFCNT_inc(val);
				
				hv_store(state->headers, state->buf , state->buf_pos , val , 0);
				
				
				char uc_string[BUFFERS_SIZE+6];
				
				uc_string[0]='H';
				uc_string[1]='T';
				uc_string[2]='T';
				uc_string[3]='P';
				uc_string[4]='_';
				
				int i = 0;
				for(; i < state->buf_pos; i++){
					uc_string[i+5] = toUPPER( state->buf[i] );
				}
				
				hv_store(state->headers, uc_string , state->buf_pos+5 , val , 0);
				
				
				end_headers_reading: // goto shit
				
				state->buf_pos = 0;
				state->buf2_pos = 0;
				
				continue;
			}
			if( state->reading < HEADER_VALUE && search( state->buffer[state->buffer_pos], ": ", &state->headers_sep_match_pos) ){
				state->buf_pos -= 1; // because we don`t need ":" in name
				state->reading = HEADER_VALUE;
				continue;
			}
			
			if(state->reading == HEADER_NAME){ // read header name to buf
				COPY_CURRENT_CHAR_TO(buf, BUFFERS_SIZE);
			}
			else{  // read header value to buf2
				COPY_CURRENT_CHAR_TO(buf2, BUFFERS_SIZE);
			}
		}
		// read urlencoded body
		else if(state->reading == BODY_URLENCODED ){
			SV** hashval; 
			CONN_DROP_IF(! (hashval = hv_fetch(state->rethash, "REQUEST_BODY" , 12 , 0) ) ); // drop will never happen...
			int bytes_to_read = state->readed - state->buffer_pos;
			
			if( (state->total_readed + bytes_to_read) > state->content_length ){
				bytes_to_read = state->content_length - state->total_readed;
			}
			
			sv_catpvn(*hashval, &state->buffer[state->buffer_pos] , bytes_to_read );
			state->total_readed += bytes_to_read;
			
			if( state->total_readed >= state->content_length ){
				init_cgi_obj(state);
				call_perl(state);
				ev_io_stop(loop, w); 
				return;
			};
			break;
		}
		//////////////////// Reading multipart //////////////////////////
		else {
			state->total_readed++;
			//reading multipart data or file
			if(state->reading < BODY_M_HEADERS){
			
				if(state->buffer[state->buffer_pos] == state->boundary[state->match_pos]){
					state->match_pos++;
					
					if(! state->boundary[state->match_pos] ){ //matched all boundary
						state->match_pos = 0;
						//printf("\nBoundary matched\n");
								
								if(state->reading == BODY_M_DATA){
									SV* data =  newSVpv(
										state->body_chunk_pos-2 > 0 ? state->body_chunk : "", 
										state->body_chunk_pos-2 );
									SvUTF8_on(data);
									
									hv_store(state->post, state->buf , state->buf_pos , data , 0) ;
									push_to_hash(state->post_a , state->buf , state->buf_pos, data);
									
									state->body_chunk_pos = 0;
									state->buf_pos = 0;
								}
								else if(state->reading == BODY_M_FILE){
								//end of file reading
									state->buf_pos = 0;
									state->buf2_pos = 0;
									
									state->reading = BODY_M_HEADERS;
									
									// processing always suspended after tmp_close call
									if(tmp_close(state)) //tmp_close returns TRUE if needs wait for IO 
										return;
								}
								
								state->reading = BODY_M_HEADERS;
								
					}
				}
				else{
					// reading form input
					if(state->reading == BODY_M_DATA){
						if(state->match_pos){
							int bound_i;
									
							for(bound_i = 0; bound_i < state->match_pos; bound_i++){
								state->body_chunk[state->body_chunk_pos] = state->boundary[bound_i];
								state->body_chunk_pos++;
										
								CONN_DROP_IF(state->body_chunk_pos >= BODY_CHUNK_BUFSIZ);
							}		
						}
						
						COPY_CURRENT_CHAR_TO(body_chunk, BODY_CHUNK_BUFSIZ);
								
					}
					// reading form file
					else if(state->reading == BODY_M_FILE){
						if(state->match_pos){ //append false boundary match
							int bound_i = 0;
							for(; bound_i < state->match_pos; bound_i++){
								tmp_putc(state, state->boundary[bound_i]);
							};
						};
							

						//append char
						tmp_putc(state, state->buffer[state->buffer_pos]);
					};
							
					state->match_pos = 0;
				}
			}
			// Reading multipart headers
			else if(state->reading >= BODY_M_HEADERS){
					//buf - name
					//buf2 - filename
					
				// searching for name
				if(search(state->buffer[state->buffer_pos], " name=\"", &state->multipart_name_match_pos) && !(state->buf_pos)){
					state->reading = BODY_M_HEADERS_NAME;
					//printf("Name match\n");
					continue;
				}
				// reading name
				else if(state->reading == BODY_M_HEADERS_NAME){
					if(state->buffer[state->buffer_pos] == '"'){
						state->reading = BODY_M_HEADERS;
						continue;
					}else{
						COPY_CURRENT_CHAR_TO(buf, BUFFERS_SIZE);
					}
				}
				
				// searching for filename
				else if(!(state->buf2_pos) && search(state->buffer[state->buffer_pos], "filename=\"", &state->multipart_filename_match_pos)){
					state->reading = BODY_M_HEADERS_FILENAME;
					//printf("FileName match\n");
					continue;
				}
				// reading filename
				else if(state->reading == BODY_M_HEADERS_FILENAME){
					if(state->buffer[state->buffer_pos] == '"'){
						state->reading = BODY_M_HEADERS;
						continue;
					}else{
						COPY_CURRENT_CHAR_TO(buf2, BUFFERS_SIZE);
					}
				};
				
						
				// searching for end of headers
				if(search( state->buffer[state->buffer_pos], "\r\n\r\n", &state->headers_end_match_pos) ){

					CONN_DROP_IF( 
						state->reading == BODY_M_HEADERS_NAME ||
						state->reading == BODY_M_HEADERS_FILENAME //||
					//	!state->buf_pos // Did some browsers may send form fields with empty name?
					); //malformed multipart headers
						
					//printf("\nEnd of fileheader matched\n");	
					
					
					if(state->buf2_pos){//filename defined 
						state->reading =  BODY_M_FILE;
						
						// printf("create tmp\n");
						SV* file = create_tmp(state);
						hv_store(state->file, state->buf , state->buf_pos , file , 0);
						push_to_hash(state->file_a, state->buf, state->buf_pos, file );
					}else{
						state->reading =  BODY_M_DATA;
					}
					
					
					CONN_DROP_IF(state->multipart_data_count > MAX_DATA);
					
					state->multipart_data_count++;
						
					continue;
				}
			}
			
			//end of stream
			if( state->total_readed >= state->content_length ){ 
				if( state->reading == BODY_M_HEADERS || state->reading == BODY_M_NOTHING ){
					// printf("call perl\n");
					call_perl(state);
					ev_io_stop(loop, w); 
					return;
				}
				return drop_conn(state, loop);
			};
		}
	}
	
	state->buffer_pos = 0;
}

static void listen_cb (struct ev_loop *loop, ev_io *w, int revents){	
		struct port_listener *listener = (struct port_listener *)w;
		
		int accepted_socket;
		struct sockaddr_in cliaddr;
		int addrlen = sizeof(cliaddr);
		
		if( ( accepted_socket = accept( w->fd , (struct sockaddr *) &cliaddr, &addrlen ) ) == -1 )
		{ 
			// printf("error %d %d\n", errno, EAGAIN);
			if(errno == EAGAIN){ // event received by another child process
				return;
			}
			warn("HTTP::Server::EV ERROR: Can`t accept connection. Run out of open file descriptors! Listening stopped until one of the server connection will be closed!");
			
			ev_io_stop(EV_DEFAULT, &(listener->io)); 
			return;
		};
		
		struct req_state *state = alloc_state();
		
		if(!state){
			warn("HTTP::Server::EV ERROR: Can`t allocate memory for connection state. Connection dropped!");
			close(accepted_socket);
			return;
		}
		
		state->parent_listener = listener;
		state->timeout = listener->timeout;
		
		hv_store(state->headers, "REMOTE_ADDR" , 11 , newSVpv(inet_ntoa( cliaddr.sin_addr ), 0 ) , 0);
		hv_store(state->rethash, "fd", 2, newSViv(accepted_socket), 0);
		
		
		ev_io_init (&state->io, handler_cb, accepted_socket , EV_READ);
		ev_io_start ( loop, &state->io);
		
		
		if (state->timeout != 0) {
			ev_timer_init(&state->timer, timer_cb, 0., listener->timeout);
			state->timer.data = (void *) state;
			
			ev_timer_again(loop, &(state->timer));
		}
}





MODULE = HTTP::Server::EV	PACKAGE = HTTP::Server::EV	

PROTOTYPES: DISABLE

BOOT:
{
	I_EV_API ("HTTP::Server::EV");
#ifdef WIN32
	_setmaxstdio(2048); 
#endif
}


SV*
listen_socket ( sock ,callback, pre_callback, error_callback, timeout)
	int sock
	SV* callback
	SV* pre_callback
	SV* error_callback
	float timeout
	CODE:
		SvREFCNT_inc(callback);
		SvREFCNT_inc(pre_callback);
		SvREFCNT_inc(error_callback);
		
		
		
		
		struct port_listener* listener = (struct port_listener *) malloc(sizeof(struct port_listener));
		
		listener->callback = callback;
		listener->pre_callback = pre_callback;
		listener->error_callback = error_callback;
		listener->timeout = timeout;
		
		ev_io_init(&(listener->io), listen_cb, sock, EV_READ);
		ev_io_start(EV_DEFAULT, &(listener->io));
		
		SV* magic_sv = newSViv( (int) &(listener->io));
		sv_magicext (magic_sv , 0, PERL_MAGIC_ext, NULL, (const char *) &(listener->io), 0);
		RETVAL = magic_sv;
	OUTPUT:
		RETVAL
	
void
stop_listen (self)	
	SV* self
	CODE:
		MAGIC *mg ;
		for (mg = SvMAGIC (self); mg; mg = mg->mg_moremagic) {
			if (mg->mg_type == PERL_MAGIC_ext && mg->mg_virtual == NULL){
				ev_io_stop(EV_DEFAULT, (ev_io *) mg->mg_ptr); 
				break;
			}	
		}
		

void
start_listen ( self )	
		SV* self
	CODE:
		MAGIC *mg ;
		for (mg = SvMAGIC (self); mg; mg = mg->mg_moremagic) {
			if (mg->mg_type == PERL_MAGIC_ext && mg->mg_virtual == NULL){
				ev_io_start(EV_DEFAULT, (ev_io *) mg->mg_ptr); 	
				break;
			}	
		}
		

void
stop_req( saved_to )	
	int saved_to
	CODE:
		struct req_state *state = accepted[saved_to];
		state->reading |= 1 << 7; // 7 bit set - suspended
		
		if (state->timeout != 0.) ev_timer_stop(EV_DEFAULT, &state->timer);
		ev_io_stop(EV_DEFAULT, &(state->io)); 
		

SV*
start_req( saved_to )	
	int saved_to
	CODE:
		struct req_state *state = accepted[saved_to];
		
		state->reading &= ~(1 << 7); // 7 bit null - working
		ev_io_start(EV_DEFAULT, &(state->io)); 
		if (state->timeout != 0.) ev_timer_again(EV_DEFAULT, &state->timer);
		
		// if(state->buffer_pos)
		// ev_feed_fd_event(EV_DEFAULT, &(state->io), 0);
		// No ev_feed_fd_event in EV XS API :(
		// Pass fd and do it from perl
		
		RETVAL = state->buffer_pos ? newSViv(state->io.fd) : newSV(0);
		
		
	OUTPUT:
        RETVAL
		
void
drop_req( saved_to )	
	int saved_to
	CODE:
		accepted[saved_to]->reading = REQ_DROPED_BY_PERL;
		ev_io_start(EV_DEFAULT, &(accepted[saved_to]->io)); 
	
	
	
#define URLDECODE_READ_CHAR 2
#define URLDECODE_READ_FIRST_PART 3
#define URLDECODE_READ_SECOND_PART 4

void
url_decode( encoded )	
	SV* encoded
	PPCODE:
		SV* output = newSV( 100 );
		
		STRLEN len;
			
		char *input = SvPV(encoded, len);
		
		char state = URLDECODE_READ_CHAR;
		
		char byte = (char)NULL;
		int pos = 0;
		for(; pos < len ; pos++){
			if( input[pos] == '%' ){
				state = URLDECODE_READ_FIRST_PART;
				byte = (char)NULL;
			}else
			if(state == URLDECODE_READ_CHAR){
				sv_catpvn(output, input+pos, 1);
			}else{
				if(state == URLDECODE_READ_FIRST_PART){
					byte = (isdigit(input[pos]) ? input[pos] - '0' : tolower(input[pos]) - 'a' + 10) << 4;
					state = URLDECODE_READ_SECOND_PART;
				}else{ // state == URLDECODE_READ_SECOND_PART
					byte |= (isdigit(input[pos]) ? input[pos] - '0' : tolower(input[pos]) - 'a' + 10);
					sv_catpvn(output, &byte, 1);
					byte = (char)NULL;
					state = URLDECODE_READ_CHAR;
				}
			}
		};
		
		STRLEN out_len;
		char *out_ptr = SvPV(output, out_len);
		
		XPUSHs(sv_2mortal(output));
		XPUSHs(sv_2mortal(newSViv( is_utf8_string( out_ptr , out_len) )));

		
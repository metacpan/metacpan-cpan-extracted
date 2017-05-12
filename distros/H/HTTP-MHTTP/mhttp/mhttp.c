/*
 * copied and amended from a simple http socket program:
 * "Simple Internet client program - by Dan Drown <abob@linux.com>"
 * available (last I looked) at: 
 *      http://linux.omnipotent.net/article.php?article_id=5424
 */

#include "mhttp.h"


#ifdef DOHERROR
void herror(char *str){
  fprintf(stderr, "herror: %s\n", str);
}
#endif

bool mhttp_lets_debug;        /* global debugging flag           */
bool mhttp_body_set_flag;     /* global body set flag            */
bool mhttp_host_hdr;          /* I got a Host header             */
int mhttp_protocol = 0;
bool mhttp_first_init = false;

int  mhttp_hcnt,
     mhttp_rcode,
     mhttp_response_length;

char *mhttp_body,
     *mhttp_response,
     *mhttp_reason,
     mhttp_resp_headers[MAX_HDR_STR],
     *mhttp_headers[MAX_HEADERS],
     *mhttp_buffers[MAX_BUFFERS];

mhttp_conn_t mhttp_connection = NULL;

mhttp_conn_t mhttp_last_connection = NULL;

  

int mhttp_call(char *paction, char *purl)
{
    bool found_hdrs;        /* found the end of headers flag   */
    bool rcode_flag;        /* found return code flag          */
    bool newcon_flag;       /* new connection flag             */
    bool chunked;           /* transfer encoding is chunked    */
    char *action, *url, *host, *ptr, *eomsg, *clptr;
    char *req;
    char *surl;
    char *cert_str;
    int  port,
         returnval,
	 len,
	 curr_len,
	 buffer_size,
	 this_chunk,
	 i,
	 rem,
	 pos;
    char str[MAX_STR];


    newcon_flag = false;
    if (!mhttp_first_init)
        mhttp_init();
    memset(mhttp_resp_headers, 0, MAX_HDR_STR);

    mhttp_connection = mhttp_new_conn();

    if ((returnval = check_action(paction, &action)) < 0)
        return returnval;

    if ((returnval = check_url(purl, &url, &host)) < 0)
        return returnval;

    if ((port = get_port_and_uri(purl, host, &surl)) < 0)
        return port;
    mhttp_connection->host = strdup(host);
    mhttp_connection->port = port;

    mhttp_debug("action: %s host: %s port: %d url: %s", action, host, port, url);
    mhttp_debug("purl is: #%s#", purl);
    if (strncmp(purl, "https", 5) == 0)
           mhttp_connection->is_ssl = true;

    mhttp_debug("This connection: %s / %d / %d",
       mhttp_connection->host,
       mhttp_connection->port,
       mhttp_connection->is_ssl);

    if (mhttp_protocol == 1 && ! mhttp_host_hdr){
        mhttp_debug("This is HTTP/1.1 and we don't have a Host header");
        return -19;
    }

    if (mhttp_last_connection != NULL){
    mhttp_debug("OLD connection: %s / %d / %d",
       mhttp_last_connection->host,
       mhttp_last_connection->port,
       mhttp_last_connection->is_ssl);
     }
#ifdef GOTSSL
    if (mhttp_last_connection != NULL &&
       strcmp(mhttp_connection->host, mhttp_last_connection->host) == 0 &&
       mhttp_last_connection->port == mhttp_connection->port &&
       mhttp_last_connection->is_ssl == mhttp_connection->is_ssl){
       mhttp_connection->fd = mhttp_last_connection->fd;
       mhttp_connection->ctx = mhttp_last_connection->ctx;
       mhttp_connection->ssl = mhttp_last_connection->ssl;
       mhttp_connection->meth = mhttp_last_connection->meth;
       mhttp_connection->server_cert = mhttp_last_connection->server_cert;
#else
    if (mhttp_last_connection != NULL &&
       strcmp(mhttp_connection->host, mhttp_last_connection->host) == 0 &&
       mhttp_last_connection->port == mhttp_connection->port){
       mhttp_connection->fd = mhttp_last_connection->fd;
#endif
       mhttp_debug("using the cached connection");
    } else {
      if (mhttp_last_connection != NULL){
#ifdef GOTSSL
        if (mhttp_last_connection->is_ssl)
            SSL_shutdown (mhttp_last_connection->ssl);  /* send SSL/TLS close_notify */
#endif
        close(mhttp_last_connection->fd);
#ifdef GOTSSL
        if (mhttp_last_connection->is_ssl){
            mhttp_debug("shuting down the ssl engine");
            SSL_free (mhttp_last_connection->ssl);
            SSL_CTX_free (mhttp_last_connection->ctx);
        }
#endif
        mhttp_end_conn(mhttp_last_connection);
	mhttp_last_connection = NULL;
        mhttp_debug("Closed the last connection");
      }
      newcon_flag = true;
      mhttp_connection->fd = -1;
      mhttp_debug("didnt find connection - creating a new one: %s/%d - %d ", mhttp_connection->host, mhttp_connection->port, mhttp_connection->fd);
#ifdef GOTSSL
       if (mhttp_connection->is_ssl){
	   mhttp_debug("creating an SSL connection");
           //SSLeay_add_ssl_algorithms();
	   OpenSSL_add_ssl_algorithms();
           //mhttp_connection->meth = SSLv2_client_method();
	   mhttp_connection->meth = SSLv3_client_method();
           SSL_load_error_strings();
           mhttp_connection->ctx = SSL_CTX_new (mhttp_connection->meth);
	   if (mhttp_connection->ctx == NULL){
	       mhttp_debug("SSL_CTX_new failed - abort everything");
	       return -11;
	   }
          if( (mhttp_connection->fd = mhttp_connect_inet_addr(mhttp_connection->host, mhttp_connection->port)) < 0) {
               mhttp_debug("could not create a new socket: %d", mhttp_connection->fd);
               return mhttp_connection->fd;
           }
           // XXX set SSL here

           /* ----------------------------------------------- */
           /* Now we have TCP conncetion. Start SSL negotiation. */

           mhttp_debug("SSL craeting the ctx");
           mhttp_connection->ssl = SSL_new (mhttp_connection->ctx);
	   if (mhttp_connection->ssl == NULL){
	       mhttp_debug("SSL_new failed - abort everything");
	       return -12;
	   }
	   mhttp_debug("SSL set_verify");
	   SSL_CTX_set_default_verify_paths(mhttp_connection->ctx);
	   //SSL_CTX_load_verify_locations(mhttp_connection->ctx, "/etc/httpd/conf/ssl.crt/ca-bundle.crt",
	   //                                   NULL);
	   SSL_CTX_set_verify(mhttp_connection->ctx, SSL_VERIFY_PEER|SSL_VERIFY_CLIENT_ONCE, mhttp_verify_callback);
	   //SSL_CTX_set_verify(mhttp_connection->ctx, SSL_VERIFY_PEER|SSL_VERIFY_CLIENT_ONCE, NULL);
	   mhttp_debug("SSL set_fd");
           SSL_set_fd (mhttp_connection->ssl, mhttp_connection->fd);
           returnval = SSL_connect (mhttp_connection->ssl);
	   if (returnval == -1){
	       mhttp_debug("SSL_connect failed - abort everything");
	       ERR_print_errors_fp(stderr);
	       return -13;
	   }
    
           /* Get the cipher - opt */
           mhttp_debug ("SSL connection using %s\n", SSL_get_cipher (mhttp_connection->ssl));
  
           /* Get server's certificate (note: beware of dynamic allocation) - opt */
           mhttp_connection->server_cert = SSL_get_peer_certificate (mhttp_connection->ssl);
	   if (mhttp_connection->server_cert == NULL){
	       mhttp_debug("SSL_get_peer_certificate failed - abort everything");
	       return -14;
	   }
  
           cert_str = X509_NAME_oneline (X509_get_subject_name (mhttp_connection->server_cert),0,0);
	   if (cert_str == NULL){
	       mhttp_debug("X509_get_subject_name failed - abort everything");
	       return -15;
	   }
           mhttp_debug ("Certificate subject: %s\n", cert_str);
           free (cert_str);

           cert_str = X509_NAME_oneline (X509_get_issuer_name  (mhttp_connection->server_cert),0,0);
	   if (cert_str == NULL){
	       mhttp_debug("X509_get_issuer_name failed - abort everything");
	       return -16;
	   }
           mhttp_debug ("Certificate issuer: %s\n", cert_str);
           free (cert_str);

           /* We could do all sorts of certificate verification stuff here before
              deallocating the certificate. */

           if (SSL_get_verify_result(mhttp_connection->ssl) == X509_V_OK){
           /* The client sent a certificate which verified OK */
	       mhttp_debug("certificate OK");
           } else {
	       mhttp_debug("Certificate error: %s", X509_verify_cert_error_string(SSL_get_verify_result(mhttp_connection->ssl)));
	   }

           X509_free (mhttp_connection->server_cert);

      } else {
          if( (mhttp_connection->fd = mhttp_connect_inet_addr(mhttp_connection->host, mhttp_connection->port)) < 0) {
               mhttp_debug("could not create a new socket: %d", mhttp_connection->fd);
               return mhttp_connection->fd;
           }
      }
#else
      if( (mhttp_connection->fd = mhttp_connect_inet_addr(mhttp_connection->host, mhttp_connection->port)) < 0) {
           mhttp_debug("could not create a new socket: %d", mhttp_connection->fd);
           return mhttp_connection->fd;
       }
#endif
  }

  mhttp_debug("socket descriptor is: %d ", mhttp_connection->fd);

  len = 0;

  // construct the query string
  memset(str, 0, sizeof(str));

  if ((req = construct_request(action, surl)) == NULL)
  	return -2;

  returnval = write_socket(mhttp_connection, req, strlen(req));
  if(returnval < 0)
  {
    /* write returns -1 on error */
    perror("write(query string) error");
    return -5;
  }

  if(returnval < strlen(req))
  {
    /* I'm not dealing with this error, regular programs should. */
    perror("the query string write was short\n");
    return -6;
  }
  free(req);
  free(surl);
  free(url);
  free(host);

  // if this is a PUT or POST - write the body
  if (mhttp_body_set_flag)
  {
      // XXX we probably have a problem where 1024 is exceeded and need to rewrite
      mhttp_debug("this is a %s.... writing the body...", action);
      mhttp_debug("writing data: %s", mhttp_body);
      returnval = write_socket(mhttp_connection, mhttp_body, strlen(mhttp_body));
      if(returnval < strlen(mhttp_body))
      {
          /* I'm not dealing with this error, regular programs should. */
          fprintf(stderr, "the write of %s data was short\n", action);
          return -6;
      }
      returnval = write_socket(mhttp_connection, "\r\n", 2);
      if(returnval < 2)
      {
          /* I'm not dealing with this error, regular programs should. */
          fprintf(stderr, "the write of %s data - last line failed\n", action);
          return -7;
      }
  }
  free(action);


  /* read off the response and split out headers and content */
  mhttp_debug("starting output:");
  found_hdrs = false;
  rcode_flag = false;
  len = 0;
  curr_len = 0;
  chunked = false;

  if ((len = read_headers(mhttp_connection, str)) < 0){
    // we have no headers
    mhttp_debug("we have no headers ");
    exit(1);
  }
  if (mhttp_response_length > 0){
      buffer_size = mhttp_response_length;
  } else {
      buffer_size = MAX_STR;
  }


  mhttp_debug("initial len is: %d", len);
  while((returnval = read_socket(mhttp_connection, str)) > 0)
  {
       *(str+returnval) = '\0';
       // we have the headers - this is the body
       if (mhttp_response_length > 0){
	      // we dont know how big it should be so compensate
	      if (mhttp_connection->is_chunked){
	          if (len + returnval >= buffer_size - 2){
                     memcpy(mhttp_response+len, str, (buffer_size - 2) - len);
		     pos = (buffer_size - 2) - len;
		     len += pos;
		     mhttp_debug("len at end of chunk is: %d", len);

		     // find the next chunk
		     mhttp_debug("looking for the next chunk");
		     ptr = str+pos;
		     rem = returnval - pos;

	             if ((this_chunk = find_chunk(mhttp_connection, &ptr, &rem)) > 0){
			 // resize and paste on remainder
			 mhttp_debug("resize and paste on remainder for next chunk processing");
	                 mhttp_response = realloc(mhttp_response, buffer_size + this_chunk);
		         buffer_size += this_chunk;
                         memcpy(mhttp_response+len, ptr, rem);
			 returnval = rem;
	             } else if (this_chunk == 0){
	               // no more to come
		       mhttp_debug("we found the final chunk");
		       break;
	             }
	          } else {
		    // not end of chunk yet
                    memcpy(mhttp_response+len, str, returnval);
		  }
	     } else {
               // make sure that it does not overflow the buffer
               if (mhttp_response_length >= (len + returnval)){
                   memcpy(mhttp_response+len, str, returnval);
               }
           }
       } else {
           // we dont know how big it should be so compensate
           // else this is not a chunked read - so realloc when necessary
           if (len + returnval > buffer_size){
               mhttp_response = realloc(mhttp_response, buffer_size + MAX_STR);
               buffer_size += MAX_STR;
           }
           memcpy(mhttp_response+len, str, returnval);
       }
       len += returnval;


      // lets get out of here if we have read enough
      if (mhttp_response_length > 0 && len >= mhttp_response_length )
          break;
  }
  mhttp_debug("content length actually copied: %d (may include \\r\\n)", len);
  mhttp_response_length = len;

  /* it will be closed anyway when we exit */
  if (mhttp_protocol == 0 ||
      (clptr = strstr(mhttp_resp_headers, "Connection: close")) ||
      (clptr = strstr(mhttp_resp_headers, "Connection: Close")) ){
#ifdef GOTSSL
      if (mhttp_connection->is_ssl)
          SSL_shutdown (mhttp_connection->ssl);  /* send SSL/TLS close_notify */
#endif
      /* Clean up. */
      close(mhttp_connection->fd);
#ifdef GOTSSL
      if (mhttp_connection->is_ssl){
          mhttp_debug("shuting down the ssl engine");
          SSL_free (mhttp_connection->ssl);
          SSL_CTX_free (mhttp_connection->ctx);
      }
#endif
      if (mhttp_last_connection != NULL){
          mhttp_end_conn(mhttp_last_connection);
	  mhttp_last_connection = NULL;
          mhttp_debug("removed socket name");
      }
      mhttp_debug("Closed the connection");
  } else {
      if (newcon_flag){
          if (mhttp_last_connection != NULL){
              mhttp_end_conn(mhttp_last_connection);
	      mhttp_last_connection = NULL;
	  }
	  mhttp_last_connection = mhttp_new_conn();
          mhttp_last_connection->host = strdup(mhttp_connection->host);
          mhttp_last_connection->port = mhttp_connection->port;
          mhttp_last_connection->fd = mhttp_connection->fd;
#ifdef GOTSSL
          if (mhttp_connection->is_ssl){
	      mhttp_debug("saving SSL stuff");
              mhttp_last_connection->is_ssl = mhttp_connection->is_ssl;
              mhttp_last_connection->ssl = mhttp_connection->ssl;
              mhttp_last_connection->ctx = mhttp_connection->ctx;
	  }
#endif
          mhttp_debug("Caching the connection");
      } else {
          mhttp_debug("connection allready cached");
      }
  }
  mhttp_end_conn(mhttp_connection);
  mhttp_connection = NULL;
  mhttp_debug("all done");
  return 1;
}


int find_content_length(void){
    char *ptr;
    int rem = 0;

    // determine the Content-Length header
    if ((ptr = strstr(mhttp_resp_headers, "Content-Length:")) ||
        (ptr = strstr(mhttp_resp_headers, "Content-length:"))){
        mhttp_debug("found content-length");
        ptr += 16;
        mhttp_response_length = atoi(ptr);
        mhttp_debug("content length: %d", mhttp_response_length);
        mhttp_response = malloc(mhttp_response_length + 2);
	return mhttp_response_length;
    }
    return 0;

}


bool find_transfer_encoding(void){
    char *clptr;
    int this_chunk;

    /* look for Transfer-Encoding: chunked */
    // clptr the chunk pointer
    // ptr the beginning of the body
    if ((clptr = strstr(mhttp_resp_headers, "Transfer-Encoding:")) ||
        (clptr = strstr(mhttp_resp_headers, "Transfer-encoding:"))){
        clptr += 19;
        if (strncmp(clptr, "chunked",7) == 0){
            mhttp_debug("found Transfer-Encoding: chunked");
	    return true;
	 }
    }
    return false;

}


int find_chunk(mhttp_conn_t conn, char **ptr, int *rem){
    char *clptr;
    char *myptr;
    int myrem;
    int diff;
    int this_chunk;
    int returnval;

    /* look for Transfer-Encoding: chunked */
    // clptr the chunk pointer
    // ptr the beginning of the body

    myptr = *ptr;
    myrem = *rem;

    // make sure that there is enuf of ptr left
    mhttp_debug("remainder is: %d", myrem);
    if (myrem <= 2 || !(clptr = strstr(myptr, "\r\n"))){
        mhttp_debug("getting another line");
        if ((returnval = read_socket(conn, myptr+myrem)) > 0){
            myrem += returnval;
            *(myptr+myrem) = '\0';
	    mhttp_debug("got another line: %d - #%s#", returnval, myptr);
	} else {
            mhttp_debug("cant get another line - aborting");
	    return -17;
	}
    }

    // must find the end of the chunked length line 
    // in the remainding buffer
    if (clptr = strstr(myptr, "\r\n")){
        mhttp_debug("looking for chunk in: %s#", myptr);
        if (sscanf(myptr, "%x\r\n", &this_chunk) != 1){
             mhttp_debug("count not the chunked amount - something ify");
            if ((returnval = read_socket(conn, myptr+myrem)) > 0){
                myrem += returnval;
                *(myptr+myrem) = '\0';
	        mhttp_debug("got another line: %d - #%s#", returnval, myptr);
		if (strncmp(myptr, "\r\n", 2) == 0){
		   myptr+=2;
		   myrem-=2;
		}
                mhttp_debug("looking for chunk in: #%s#", myptr);
                if (sscanf(myptr, "%x\r\n", &this_chunk) != 1){
                     mhttp_debug("count not the chunked amount - something broken");
	             return -17;
                }
	     }
             return -17;
	 }
	 // shift past the chunk size
	 *clptr = '\0';
	 myrem -= strlen(myptr) + 2;
	 clptr += 2;
         mhttp_debug("Transfer-Encoding: chunked buffer is %d - %d bytes left: %s", this_chunk, myrem, clptr+myrem);

	 *ptr = clptr;
	 *rem = myrem;
         return this_chunk;
    }
    return -17;

}



int read_headers(mhttp_conn_t conn, char *str){
  int returnval;
  int curr_len;
  int rem;
  int this_chunk;
  char *ptr, *eomsg;
  bool rcode_flag;


  rcode_flag = false;
  curr_len = 0;
  while((returnval = read_socket(conn, str)) > 0)
  {
       *(str+returnval) = '\0';
       mhttp_debug("Header line %d: %s", returnval, str);

       if (strlen(mhttp_resp_headers) + returnval > MAX_HDR_STR){
           mhttp_debug("have not found the headers within MAX_HDR_STR: %d", MAX_HDR_STR);
           return -18;
       }

       /* detect the end of the headers */
       sprintf(mhttp_resp_headers+strlen(mhttp_resp_headers), "%s", str);

       /* find the return code        */
       if (!rcode_flag &&
           strncmp(str, "HTTP/",5) == 0 && 
           (strncmp(str+5, "0.9 ",4) == 0 ||
 	    strncmp(str+5, "1.0 ",4) == 0 ||
 	    strncmp(str+5, "1.1 ",4) == 0 ) ){
           ptr = str+9;
	   *(ptr+3) = '\0';
           mhttp_rcode = atoi(ptr);
	   rcode_flag = true;
	   ptr+=4;
	   /* find the status reason */
           if ((eomsg = strstr(ptr, "\r\n")) || (eomsg = strstr(ptr, "\n"))){
	       *eomsg = '\0';
	       mhttp_reason = strdup(ptr);
	   }
           mhttp_debug("detected return code: %d - %s", mhttp_rcode, mhttp_reason);
       }

       if ((ptr = strstr(mhttp_resp_headers, "\r\n\r\n")) ||
           (ptr = strstr(mhttp_resp_headers, "\n\n"))){
          *ptr = '\0';
          mhttp_debug("found end of headers at: %d", strlen(mhttp_resp_headers));
          mhttp_debug("headers are: %s", mhttp_resp_headers);
          if (strncmp(ptr,"\0\n\r\n",4) == 0){
              /* how far along the current buffer is the eoh marker */
              curr_len = (strlen(mhttp_resp_headers) + 4) - curr_len;
              ptr+=4;
          } else {
              curr_len = (strlen(mhttp_resp_headers) + 2) - curr_len;
              ptr+=2;
          }

          /* tidy up the first bit of the body XXX */
	  mhttp_debug("returnval: %d - curr_len: %d", returnval, curr_len);
	  rem = returnval - curr_len;
	  mhttp_debug("the remainder is: %d", rem);

          // find the Content-Length header
          if ( find_content_length() > 0 ){
              if (mhttp_response_length >= rem){
                  mhttp_debug("copying the initial part of the body: %s", ptr);
                  memcpy(mhttp_response, ptr, rem);
                  return rem;
              } else {
                  // serious error - cant determine length properly
                  mhttp_debug("serious error - cant determine length properly");
                  return -8;
              }
           // or find the Tranfer-Enconding: chunked header
           } else if (find_transfer_encoding()){
	       // find the chunk value
	       conn->is_chunked = true;
	       if ((this_chunk = find_chunk(conn, &ptr, &rem)) > 0){
                   mhttp_response = malloc(this_chunk + 2);
                   memcpy(mhttp_response, ptr, rem);
                   mhttp_response_length = this_chunk + 2;
		   return rem;
	       } else if (this_chunk == 0){
	         // an empty body 
		 return 0;
	       } else {
	          // failed to find the next chunk value
		  mhttp_debug("cannot find \\r\\n after first chunked marker - time to give up");
		  return -17;
	       }
           } else {
	      mhttp_debug("didnt find content-length - must use realloc: %d", rem);
              mhttp_response_length = 0;
              mhttp_response = malloc(MAX_STR);
              memcpy(mhttp_response, ptr, rem);
	      return rem;
	   }
           // or determine that it is HTTP/1.0
           // or find the Connection: close
          return curr_len;
      }
      curr_len += returnval;
  }

  /* must have hit an error */
  return returnval;

}


int check_url(char *purl, char **url, char **host){

    char *ptrhost;

    if(strlen(purl) == 0)
    {
        mhttp_debug("must supply a url");
        return -3;
    }

    if (strncmp(purl, "http://", 7) == 0){
        ptrhost = purl+7;
#ifdef GOTSSL
    } else if (strncmp(purl, "https://", 8) == 0){
        ptrhost = purl+8;
	mhttp_debug("setting the ssl flag");
	mhttp_connection->is_ssl = true;
#endif
    } else {
        mhttp_debug("url must start with http:// - and yep we dont support https\n");
        return -4;
    }
    *url = strdup(purl);
    *host = strdup(ptrhost);
    mhttp_debug("begin of host is: %s", *host);
    return 0;
}



int get_port_and_uri(char *url, char *host, char **surl){
  char *ptr;
  int port;

  // hunt for the beginning of the uri
  mhttp_debug("begin looking for host at: %s", host);
  *surl = malloc(MAX_STR);
  ptr = strstr(host, "/");
  if (ptr != NULL){
      *ptr = '\0';
      ptr++;
      sprintf(*surl, "/%s", ptr);
  } else {
      sprintf(*surl, "/");
  }
  // hunt for the beginning of the port
  ptr = strstr(host, ":");
  if (ptr != NULL){
      *ptr = '\0';
      ptr++;
      port = atoi(ptr);
  } else {
#ifdef GOTSSL
      if (strncmp(url ,"https", 5) == 0){
          port = 443;
      } else {
          port = 80;
      }
#else
      port = 80;
#endif

  }
  return port;

}
 

#ifdef GOTSSL
static int mhttp_verify_callback(int ok, X509_STORE_CTX* ctx)
{
    return 1;
}
#endif

mhttp_conn_t mhttp_new_conn(void){
    mhttp_conn_t new_conn;

    new_conn = (mhttp_conn_t) malloc(sizeof(struct mhttp_conn_st));
    memset(new_conn, 0, sizeof(struct mhttp_conn_st));

    new_conn->host = NULL;
    new_conn->port = 0;
    new_conn->is_ssl = false;
    new_conn->is_chunked = false;
    return new_conn;
}


void mhttp_end_conn(mhttp_conn_t conn){

    mhttp_debug("resetting conn");
    free(conn->host);
    free(conn);

}


char *construct_request(char *action, char *url){
  char *str;
  int i;

  str = malloc(MAX_HDR_STR);

  strcpy(str, action);
  strcpy(str+strlen(str), " ");
  strcpy(str+strlen(str), url);
  sprintf(str+strlen(str), " HTTP/1.%d\r\n", mhttp_protocol);
  mhttp_debug("adding on the headers: %d", mhttp_hcnt);
  for(i = 0; i < mhttp_hcnt; i++)
  {
      // make sure that we dont exceed the buffer
      if ((strlen(str) + strlen(mhttp_headers[i])) > MAX_BUFFERS - 1)
          break;
      mhttp_debug("adding header: %s", mhttp_headers[i]);
      sprintf(str+strlen(str), "%s\r\n", mhttp_headers[i]);
  }
  // if this is a post - add the Content-Length header
  if (mhttp_body_set_flag)
  {
      sprintf(str+strlen(str), 
              "Content-Length: %d\r\n\r\n", strlen(mhttp_body));
  } else {
      strcpy(str+strlen(str), "\r\n\r\n");
  }
  mhttp_debug("query string + headers are: %s", str);

  return str;

}


int check_action(char *paction, char **action){
    if(strlen(paction) == 0)
    {
        mhttp_debug("must supply an action");
        return -2;
    }

    if (strcmp(paction, "GET") != 0 && 
        strcmp(paction, "POST") != 0 && 
        strcmp(paction, "PUT") != 0 &&
        strcmp(paction, "DELETE") != 0 &&
        strcmp(paction, "HEAD") != 0)
    {
        mhttp_debug("must supply an action of GET, PUT, POST, DELETE, or HEAD");
        return -1;
    }
    *action = strdup(paction);
    mhttp_debug("The action is: %s", *action);
    return 0;
}


void mhttp_switch_debug(int set)
{
    if (!mhttp_first_init)
        mhttp_init();
     
    if (set > 0)
    {
        mhttp_lets_debug = true;
#ifdef GOTSSL
        mhttp_debug("%s", "switched on debugging(SSL Support running)...");
#else
        mhttp_debug("%s", "switched on debugging...");
#endif
    } else {
        mhttp_lets_debug = false;
    }

}


void mhttp_set_protocol(int proto)
{

    if (!mhttp_first_init)
        mhttp_init();
     mhttp_protocol = proto;

}


int mhttp_get_status_code(void)
{

    return mhttp_rcode;

}


int mhttp_get_response_length(void)
{

    return mhttp_response_length;

}


char *mhttp_get_reason(void)
{

  if (mhttp_reason != NULL){
    mhttp_debug("the reason is: %s", mhttp_reason);
    return strdup(mhttp_reason);
  } else {
    return NULL;
  }

}


char *mhttp_get_response(void)
{

    return mhttp_response;

}


char *mhttp_get_response_headers(void)
{

    return strdup(mhttp_resp_headers);

}


void mhttp_reset(void)
{

  int i;

    if (!mhttp_first_init)
        mhttp_init();
    if (mhttp_response != NULL){
        free(mhttp_response);
        mhttp_response = NULL;
        mhttp_debug("reset the response");
    }
    mhttp_response_length = 0;
    if (mhttp_reason != NULL){
        free(mhttp_reason);
        mhttp_reason = NULL;
        mhttp_debug("reset the reason");
    }
    if (mhttp_body_set_flag)
        free(mhttp_body);
    mhttp_body_set_flag = false;
    mhttp_rcode = 0;
  
    mhttp_debug("finished reset");

}


void mhttp_init(void)
{

  int i;

  mhttp_first_init = true;
  for (i = 0; i < mhttp_hcnt; i++)
  {
      free(mhttp_headers[i]);
      mhttp_debug("freeing header");
      mhttp_headers[i] = NULL;
  }
  mhttp_hcnt = 0;
  mhttp_lets_debug = false;
  mhttp_protocol = 0;
  mhttp_host_hdr = false;
  mhttp_reset();
  mhttp_debug("finished init");
}


void mhttp_add_header(char *hdr)
{

    if (!mhttp_first_init)
        mhttp_init();

    /* Do we have a Host Header?                          */
    if (! mhttp_host_hdr && strncmp("Host:", hdr, 5) == 0)
        mhttp_host_hdr = true;

    mhttp_headers[mhttp_hcnt++] = strdup(hdr);
    mhttp_debug("request header %s", mhttp_headers[mhttp_hcnt - 1]);
    mhttp_headers[mhttp_hcnt] = NULL;

}


void mhttp_set_body(char *bdy)
{

    // assumes body is a string XXX
    if (!mhttp_first_init)
        mhttp_init();
    mhttp_body = strdup(bdy);
    mhttp_debug("setting body: %s", mhttp_body);
    mhttp_body_set_flag = true;

}


int read_socket(mhttp_conn_t conn, void *buf){
  int returnval;

#ifdef GOTSSL
  if (conn->is_ssl){
      returnval = SSL_read (conn->ssl, buf, READ_BUF);
      if (returnval == -1){
          mhttp_debug("SSL_read failed - abort everything");
          ERR_print_errors_fp(stderr);
          return -16;
      }
  } else {
      returnval = read(conn->fd, buf, READ_BUF);
  }
#else
  returnval = read(conn->fd, buf, READ_BUF);
#endif
  return returnval;

}



int write_socket(mhttp_conn_t conn, const void *buf, size_t count){
  int returnval;

#ifdef GOTSSL
  if (conn->is_ssl){
      //mhttp_debug("writing to ssl connection");
      returnval = SSL_write (conn->ssl, buf, count);
      if (returnval == -1){
          mhttp_debug("SSL_write failed - abort everything");
          ERR_print_errors_fp(stderr);
          return -17;
      }
  } else {
      returnval = write(conn->fd, buf, count);
  }
#else
  returnval = write(conn->fd, buf, count);
#endif
  return returnval;

}


int mhttp_connect_inet_addr(const char *hostname, unsigned short int port)
{
  int inet_socket; /* socket descriptor */
  struct sockaddr_in inet_address; /* IP/port of the remote host to connect to */

  if ( mhttp_build_inet_addr(&inet_address, hostname, port) < 0 )
      return -1;

  /* socket(domain, type, protocol) */
  inet_socket = socket(PF_INET, SOCK_STREAM, 0);

  mhttp_debug("socket no: %d", inet_socket);
  /* domain is PF_INET(internet/IPv4 domain) *
   * type is SOCK_STREAM(tcp) *
   * protocol is 0(only one SOCK_STREAM type in the PF_INET domain
   */

  if (inet_socket < 0)
  {
    /* socket returns -1 on error */
    perror("socket(PF_INET, SOCK_STREAM, 0) error");
    mhttp_debug("socket(PF_INET, SOCK_STREAM, 0) error");
    return -2;
  }

  /* connect(sockfd, serv_addr, addrlen) */
  if(connect(inet_socket, (struct sockaddr *)&inet_address, sizeof(struct sockaddr_in)) < 0)
  {
    /* connect returns -1 on error */
    perror("connect(...) error");
    mhttp_debug("connect(...) error");
    return -3;
  }

  return inet_socket;
}


int mhttp_build_inet_addr(struct sockaddr_in *addr, const char *hostname, unsigned short int port)
{
  struct hostent *host_entry;

  /* gethostbyname(name) */
  host_entry = gethostbyname(hostname);

  if(host_entry == NULL)
  {
    /* gethostbyname returns NULL on error */
    herror("gethostbyname failed");
    mhttp_debug("gethostbyname failed");
    return -1;
  }

  /* memcpy(dest, src, length) */
  memcpy(&addr->sin_addr.s_addr, host_entry->h_addr_list[0], host_entry->h_length);
  /* copy the address to the sockaddr_in struct. */

  /* set the family type (PF_INET) */
  addr->sin_family = host_entry->h_addrtype;

  /* addr->sin_port = port won't work because they are different byte
   * orders
   */
  addr->sin_port = htons(port);

  /* just to be pedantic... */
  return 1;
}

/* debug logging */
void mhttp_debug(const char *msgfmt, ...)
{
    va_list ap;
    char *pos, message[MAX_STR];
    int sz;
    time_t t;

    if (!mhttp_lets_debug)
        return;

    /* timestamp */
    t = time(NULL);
    pos = ctime(&t);
    sz = strlen(pos);
    /* chop off the \n */
    pos[sz-1]='\0';

    /* insert the header */

    snprintf(message, MAX_STR, "mhttp debug:%s: ", pos);
        
    /* find the end and attach the rest of the msg */
    for (pos = message; *pos != '\0'; pos++); //empty statement
    sz = pos - message;
    va_start(ap, msgfmt);
    vsnprintf(pos, MAX_STR - sz, msgfmt, ap);
    fprintf(stderr,"%s", message);
    fprintf(stderr, "\n");
    fflush(stderr);
}


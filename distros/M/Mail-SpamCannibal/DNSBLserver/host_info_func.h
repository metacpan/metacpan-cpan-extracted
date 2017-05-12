/* host_info.h
 *
 *
	Externals
  char hostbuf[MAXns * MAXDNAME];		buffer space for real names
  u_int32_t A_records[MAXns * MAXipbuf];	A records
  char local_name_buf[MAXDNAME];		local host name for SOA
  char * local_name = local_name_buf;
  int gh_error;					get hostent error

  int h_name_ctr = 0;				name record count

 */

/*	Set hostbuf to ZERO, 
	Set A_records to ZERO, 
	return a pointer to beginning of buffer

	Called internally, don't know why it would be called from outside

 */

void init_names();

/*	get a pointer to the current name
	based on the input name number
	Returns NULL if attempt to overrun buffer
 */

char * current_name(int n);

/*	Insert a name into hostbuf
	Enter with current name record pointer
	Returns next buffer pointer or
	Return NULL on buffer full
 */
 
char * insert_name(char * Hptr, char * src);

/* 	Insert an A record, IP address
	into the an A_records array.
	Enter with current A_record pointer,
	return next A_record pointer or
	NULL if the buffer is full.

	Astart points to the beginning
	of the local buffer for this name
 */
 
u_int32_t * insert_A_record(u_int32_t * Astart, u_int32_t * Aptr, u_int32_t ipaddr);

/*	get the next IP address pointer
	from A_record. Return NULL if
	there is no next record.

	Astart points to the beginning
	of the local buffer for this name
 */

u_int32_t * next_A_record(u_int32_t * Astart, u_int32_t * Aptr);

/*	get pointer to beginning of 
	A_records for current hostname
 */
 
u_int32_t * current_Astart(int n);

/*	get hostent record

	if hostname is NULL, then
	lookup the local host and
	extern local_name will be 
	used as scratch space.

	if Aptr is NULL, lookup
	the IP addresses for 'hostname'

	official hostname ends up in
	'hostbuf' and the IP addrs
	end up in 'A_records'
	
	Astart points to the beginning of
	the local IP buffer for this name

	return pointer to hostent on success
    else
    	the error is stored in
    	extern int gh_error
    	-3	memory full
	-1	gethostname failed
	1	HOST_NOT_FOUND
	2	TRY_AGAIN
	3	NO_RECOVERY
	4	NO_ADDRESS or NO_DATA

 */
 
struct hostent * get_hostent(char * hostname);

/*      get the host name + domain for this host        */
   
int set_local_name();

/*	Insert a NS name and A records

	if hostname is NULL, then
	lookup the local host and
	extern local_name will be 
	used as scratch space.
    BUT.... this should never happen

	returns 0 on success
    else
	-3	storage full
	-1	gethostname failed
	1	HOST_NOT_FOUND
	2	TRY_AGAIN
	3	NO_RECOVERY
	4	NO_ADDRESS or NO_DATA

 */
 
int add_ns_info(char * hostname, int needArecords);

/*	print contents of ns cache to stdout	*/

void report_ns();

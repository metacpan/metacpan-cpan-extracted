// parser state.
enum {
	REQ_DROPED_BY_PERL = -1,

	REQ_METHOD = 1,
	URL_STRING = 2,

	HEADERS_NOTHING = 3,

	HEADER_NAME = 4,
	HEADER_VALUE = 5,

	BODY_URLENCODED = 6,

	BODY_M_NOTHING = 7,
	BODY_M_FILE = 8,
	BODY_M_DATA = 9,

	BODY_M_HEADERS = 10,
	BODY_M_HEADERS_NAME = 11,
	BODY_M_HEADERS_FILENAME = 12
};



struct port_listener {
	ev_io io;
	
	SV* callback; 
	SV* pre_callback;
	SV* error_callback;
	
	float timeout;
};

struct req_state {
	ev_io io;
	struct port_listener *parent_listener;
	
	ev_tstamp timeout;
	ev_timer timer;
	
	
	int saved_to;
	
	char reading;
	
	int content_length;
	int total_readed;
	
	
	int headers_end_match_pos;
	int headers_sep_match_pos;
	
	int multipart_name_match_pos;
	int multipart_filename_match_pos;
	
	int multipart_data_count;
	
	// Socketread buffer
	char *buffer;
	int readed;
	int buffer_pos;
	
	// Two bufers for http headers name and value, for request addres and multipart forminput name, filename
	char *buf;
	int buf_pos;
	
	char *buf2;
	int buf2_pos;
	
	
	
	char *boundary;
	int match_pos;
	
	//buffer for text input data and file chunks
	char *body_chunk;
	int body_chunk_pos;
	
	
	SV* tmpfile_obj;
	
	
	HV* headers;
	
	HV* post;
	HV* post_a;
	
	HV* file;
	HV* file_a;
	
	HV* rethash;
	SV* req_obj; //ref to rethash
};


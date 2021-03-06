#borrowed and modified from Apache::FakeRequest
#will be require'd by Apache::Constants and Apache::Const
#not complete

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
	OK DECLINED DONE NOT_FOUND FORBIDDEN AUTH_REQUIRED SERVER_ERROR
	DOCUMENT_FOLLOWS MOVED REDIRECT USE_LOCAL_COPY BAD_REQUEST BAD_GATEWAY NOT_IMPLEMENTED CONTINUE NOT_AUTHORITATIVE
	M_CONNECT M_DELETE M_GET M_INVALID M_OPTIONS M_POST M_PUT M_TRACE
	OPT_NONE OPT_INDEXES OPT_INCLUDES  OPT_SYM_LINKS OPT_EXECCGI OPT_UNSET OPT_INCNOEXEC OPT_SYM_OWNER OPT_MULTI OPT_ALL
	SATISFY_ALL SATISFY_ANY SATISFY_NOSPEC
	REMOTE_HOST REMOTE_NAME REMOTE_NOLOOKUP REMOTE_DOUBLE_REV
	HTTP_OK HTTP_METHOD_NOT_ALLOWED  HTTP_NOT_MODIFIED HTTP_FORBIDDEN HTTP_NOT_FOUND HTTP_INTERNAL_SERVER_ERROR HTTP_NOT_ACCEPTABLE  HTTP_NO_CONTENT HTTP_PRECONDITION_FAILED HTTP_SERVICE_UNAVAILABLE HTTP_VARIANT_ALSO_VARIES
	MODULE_MAGIC_NUMBER SERVER_VERSION SERVER_BUILT
);# symbols to export on request
%EXPORT_TAGS = (
	common     => [qw(OK DECLINED DONE NOT_FOUND FORBIDDEN AUTH_REQUIRED SERVER_ERROR)],
	response   => [qw(DOCUMENT_FOLLOWS MOVED REDIRECT USE_LOCAL_COPY BAD_REQUEST BAD_GATEWAY NOT_IMPLEMENTED CONTINUE NOT_AUTHORITATIVE)],
	              #+ RESPONSE_CODES
	methods    => [qw(M_CONNECT M_DELETE M_GET M_INVALID M_OPTIONS M_POST M_PUT M_TRACE)],
	              #+ M_PATCH M_PROPFIND M_PROPPATCH M_MKCOL M_COPY M_MOVE M_LOCK M_UNLOCK
	options    => [qw(OPT_NONE OPT_INDEXES OPT_INCLUDES  OPT_SYM_LINKS OPT_EXECCGI OPT_UNSET OPT_INCNOEXEC OPT_SYM_OWNER OPT_MULTI OPT_ALL)],
	satisfy    => [qw(SATISFY_ALL SATISFY_ANY SATISFY_NOSPEC)],
	remotehost => [qw(REMOTE_HOST REMOTE_NAME REMOTE_NOLOOKUP REMOTE_DOUBLE_REV)],
	http       => [qw(HTTP_OK HTTP_METHOD_NOT_ALLOWED  HTTP_NOT_MODIFIED HTTP_FORBIDDEN HTTP_NOT_FOUND HTTP_INTERNAL_SERVER_ERROR HTTP_NOT_ACCEPTABLE  HTTP_NO_CONTENT HTTP_PRECONDITION_FAILED HTTP_SERVICE_UNAVAILABLE HTTP_VARIANT_ALSO_VARIES)],
	              #+ HTTP_MOVED_TEMPORARILY HTTP_MOVED_PERMANENTLY HTTP_UNAUTHORIZED HTTP_BAD_REQUEST
	server     => [qw(MODULE_MAGIC_NUMBER SERVER_VERSION SERVER_BUILT)],
	#+ config
	#+ types
	#+ override
	#+ args_how
);

#common
sub OK          		           {  0 }
sub DECLINED    		           { -1 }
sub DONE        	              { -2 }
sub NOT_FOUND                   { 404 }
sub FORBIDDEN                   { 403 }
sub SERVER_ERROR                { 500 }
sub AUTH_REQUIRED               { 401 }

#response
sub DOCUMENT_FOLLOWS            { 200 }
sub MOVED                       { 301 }
sub REDIRECT                    { 302 }
sub USE_LOCAL_COPY              { 304 }
sub BAD_REQUEST                 { 400 }
sub BAD_GATEWAY                 { 502 }
#RESPONSE_CODES
sub NOT_IMPLEMENTED             { 501 }
sub CONTINUE                    { 100 }
sub NOT_AUTHORITATIVE           { 203 }

# methods
sub M_CONNECT   { 4 }
sub M_DELETE    { 3 }
sub M_GET       { 0 }
sub M_INVALID   { 7 }
sub M_OPTIONS   { 5 }
sub M_POST      { 2 }
sub M_PUT       { 1 }
sub M_TRACE     { 6 }

# options
sub OPT_NONE      {   0 }
sub OPT_INDEXES   {   1 }
sub OPT_INCLUDES  {   2 }
sub OPT_SYM_LINKS {   4 }
sub OPT_EXECCGI   {   8 }
sub OPT_UNSET     {  16 }
sub OPT_INCNOEXEC {  32 }
sub OPT_SYM_OWNER {  64 }
sub OPT_MULTI     { 128 }
sub OPT_ALL       {  15 }

# satisfy
sub SATISFY_ALL    { 0 }
sub SATISFY_ANY    { 1 }
sub SATISFY_NOSPEC { 2 }

# remotehost
sub REMOTE_HOST       { 0 }
sub REMOTE_NAME       { 1 }
sub REMOTE_NOLOOKUP   { 2 }
sub REMOTE_DOUBLE_REV { 3 }

#http
sub HTTP_OK                     { 200 }
sub HTTP_METHOD_NOT_ALLOWED     { 405 }
sub HTTP_NOT_MODIFIED           { 304 }
sub HTTP_FORBIDDEN              { 403 }
sub HTTP_NOTFOUND               { 404 }
sub HTTP_INTERNAL_SERVER_ERROR  { 500 }
sub HTTP_NOT_ACCEPTABLE         { 406 }
sub HTTP_NO_CONTENT             { 204 }
sub HTTP_PRECONDITION_FAILED    { 412 }
sub HTTP_SERVICE_UNAVAILABLE    { 503 }
sub HTTP_VARIANT_ALSO_VARIES    { 506 }
#+ sub HTTP_LENGTH_REQUIRED        { 411 }

#misc
sub MODULE_MAGIC_NUMBER { "The answer is 42" }
sub SERVER_VERSION      { "1.x" }
sub SERVER_BUILT        { "199908" }

1;
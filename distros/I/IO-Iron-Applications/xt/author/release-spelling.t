use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);

if ( not $ENV{RELEASE_TESTING} ) {
	my $msg = 'Author test. Set $ENV{RELEASE_TESTING} to a true value to run.';
	plan( skip_all => $msg );
}

eval { require Test::Spelling; Test::Spelling->import() };
if ( $EVAL_ERROR ) {
	my $msg = 'Test::Spelling required for testing the Changes file!';
	plan( skip_all => $msg );
}

#set_spell_cmd('aspell -l');
add_stopwords(<DATA>);
all_pod_files_spelling_ok();

__DATA__
wildcard
CGI
CPAN
GPL
Dolan
STDIN
STDOUT
Mikko
Koivunalho
AnnoCPAN
HTTPS
IronHTTPCallException
IronWorker
ironworker
JSON
json
Params
params
subparam
tradename
AWS
aws
IronMQ
ironmq
JSONized
OAuth
RESTful
Rackspace
TODO
YAML
dir
https
http
semafores
successfull
unreserves
url
Cas
IronCache
Online
SaaS
cas
online
IronIO
IronCache
ironcache
webhooks
io
msg
Timestamp
timestamp

Github
MERCHANTABILITY
Subdirectory
filename
licensable
lv
startup
IronPolicyException
multi
runtime
scalability
Storable
filename
succcessful
subitem
ABCDEFGHIJKLMNOPQRSTUVWXYZ
abcdefghijklmnopqrstuvwxyz
alnum
CLI
IronCaches
webservices

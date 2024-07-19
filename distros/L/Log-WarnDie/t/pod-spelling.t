#!perl

use strict;
use warnings;

use Test::Most;

unless($ENV{RELEASE_TESTING}) {
    plan( skip_all => "Author tests not required for installation" );
}

eval 'use Test::Spelling';
if($@) {
	plan skip_all => 'Test::Spelling required for testing POD spelling';
} else {
	add_stopwords(<DATA>);
	all_pod_files_spelling_ok();
}

__END__
AnnoCPAN
CGI
CPAN
FCGI
GPL
Init
ISPs
POSTing
RT
cgi
http
https
params
param
stdin
tmpdir
Tmpdir
www
xml
iPad

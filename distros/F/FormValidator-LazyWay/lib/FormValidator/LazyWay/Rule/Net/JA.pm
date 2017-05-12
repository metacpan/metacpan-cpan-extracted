package FormValidator::LazyWay::Rule::Net::JA;

use strict;
use warnings;
use utf8;

sub uri { 'http:// ftp://などのURI' }
sub url { 'http://又は、https://から始まるURL' }
sub http { 'http://からはじまるURL' }
sub https { 'https://からはじまるURL' }
sub url_loose { 'http://又は、https://から始まるURL' }
sub http_loose { 'http://からはじまるURL' }
sub https_loose { 'https://からはじまるURL' }

1;

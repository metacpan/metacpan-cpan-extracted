package FormValidator::LazyWay::Rule::Net::EN;

use strict;
use warnings;
use utf8;

sub uri { 'URI' }
sub url { 'http:// or https://' }
sub http { 'http URL' }
sub https { 'https URL' }
sub url_loose { 'http:// or https://L' }
sub http_loose { 'http:// URL' }
sub https_loose { 'https:// URL' }

1;

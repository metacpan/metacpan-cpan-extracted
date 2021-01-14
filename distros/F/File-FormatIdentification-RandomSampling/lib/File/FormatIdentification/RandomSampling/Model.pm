package File::FormatIdentification::RandomSampling::Model;
# ABSTRACT: methods to identify files using random sampling
our $VERSION = '0.005'; # VERSION:
# (c) 2020 by Andreas Romeyke
# licensed via GPL v3.0 or later
use strict;
use warnings;
use feature qw(say);
use Moose;
use List::Util qw( any );


sub calc_mimetype {
    my $self = shift;
    my $histogram = shift;
    my @bigrams = @{$histogram->{bigram}};
    my @onegrams = @{$histogram->{onegram}};

    if ((any {$_ == 25906 } @bigrams) ) { return 'unknown' ; }
    if ((any {$_ == 3586 } @bigrams) ) { return 'application/vnd.ms-excel' ; }
    if ((any {$_ == 3360 } @bigrams) ) { return 'application/pdf' ; }
    if ((any {$_ == 39168 } @bigrams) ) { return 'unknown' ; }
    if ((any {$_ == 13621 } @bigrams) ) { return 'application/pdf' ; }
    if ((any {$_ == 40571 } @bigrams) ) { return 'image/jpeg' ; }
    if ((any {$_ == 42136 } @bigrams) ) { return 'application/vnd.oasis.opendocument.text' ; }
    if ((any {$_ == 8224 } @bigrams) and (any {$_ == 55 } @onegrams) ) { return 'application/pdf' ; }
    if ((any {$_ == 8224 } @bigrams) and (any {$_ == 97 } @onegrams) ) { return 'text/java' ; }
    if ((any {$_ == 8224 } @bigrams) and (any {$_ == 101 } @onegrams) ) { return 'application/pdf' ; }
    if ((any {$_ == 8224 } @bigrams) and (any {$_ == 114 } @onegrams) ) { return 'text/java' ; }
    if ((any {$_ == 8224 } @bigrams) and (any {$_ == 108 } @onegrams) ) { return 'text/html' ; }
    if ((any {$_ == 3328 } @bigrams) ) { return 'application/123' ; }
    if ((any {$_ == 8240 } @bigrams) ) { return 'application/pdf' ; }
    if ((any {$_ == 101 } @bigrams) ) { return 'application/msword' ; }
    if ((any {$_ == 18064 } @bigrams) ) { return 'video/quicktime' ; }
    if ((any {$_ == 12336 } @bigrams) and (any {$_ == 16 } @onegrams) ) { return 'unknown' ; }
    if ((any {$_ == 12336 } @bigrams) and (any {$_ == 97 } @onegrams) ) { return 'application/xml' ; }
    if ((any {$_ == 12336 } @bigrams) and (any {$_ == 128 } @onegrams) ) { return 'application/vnd.amazon.mobi8-ebook' ; }
    if ((any {$_ == 12336 } @bigrams) and (any {$_ == 110 } @onegrams) ) { return 'application/pdf' ; }
    if ((any {$_ == 14887 } @bigrams) ) { return 'unknown' ; }
    if ((any {$_ == 10762 } @bigrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 2622 } @bigrams) and (any {$_ == 12092 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 2622 } @bigrams) and (any {$_ == 24941 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 2622 } @bigrams) and (any {$_ == 27753 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 2622 } @bigrams) and (any {$_ == 25956 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 2622 } @bigrams) and (any {$_ == 28261 } @bigrams) ) { return 'text/html' ; }
    if ((any {$_ == 2622 } @bigrams) and (any {$_ == 8302 } @bigrams) ) { return 'text/html' ; }
    if ((any {$_ == 2622 } @bigrams) and (any {$_ == 25972 } @bigrams) ) { return 'text/html' ; }
    if ((any {$_ == 2622 } @bigrams) and (any {$_ == 25960 } @bigrams) ) { return 'application/pdf' ; }
    if ((any {$_ == 2622 } @bigrams) and (any {$_ == 26996 } @bigrams) ) { return 'text/html' ; }
    if ((any {$_ == 2622 } @bigrams) and (any {$_ == 25968 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 2622 } @bigrams) and (any {$_ == 29806 } @bigrams) ) { return 'application/oebps-package+xml' ; }
    if ((any {$_ == 600 } @bigrams) ) { return 'application/msword' ; }
    if ((any {$_ == 13600 } @bigrams) ) { return 'application/pdf' ; }
    if ((any {$_ == 10551 } @bigrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 8236 } @bigrams) ) { return 'application/python' ; }
    if ((any {$_ == 18834 } @bigrams) ) { return 'application/pdf' ; }
    if ((any {$_ == 28526 } @bigrams) ) { return 'application/pdf' ; }
    if ((any {$_ == 31599 } @bigrams) ) { return 'application/msword' ; }
    if ((any {$_ == 28261 } @bigrams) and (any {$_ == 27234 } @bigrams) ) { return 'application/pdf' ; }
    if ((any {$_ == 28261 } @bigrams) and (any {$_ == 26988 } @bigrams) ) { return 'text/plain' ; }
    if ((any {$_ == 28261 } @bigrams) and (any {$_ == 29797 } @bigrams) ) { return 'application/javascript' ; }
    if ((any {$_ == 28261 } @bigrams) and (any {$_ == 25956 } @bigrams) ) { return 'application/python' ; }
    if ((any {$_ == 28261 } @bigrams) and (any {$_ == 29806 } @bigrams) ) { return 'unknown' ; }
    if ((any {$_ == 27760 } @bigrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 25449 } @bigrams) and (any {$_ == 25971 } @bigrams) ) { return 'text/html' ; }
    if ((any {$_ == 25449 } @bigrams) and (any {$_ == 25970 } @bigrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 25449 } @bigrams) and (any {$_ == 26740 } @bigrams) ) { return 'text/java' ; }
    if ((any {$_ == 25449 } @bigrams) and (any {$_ == 8293 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 25449 } @bigrams) and (any {$_ == 26996 } @bigrams) ) { return 'text/csv' ; }
    if ((any {$_ == 25449 } @bigrams) and (any {$_ == 25960 } @bigrams) ) { return 'text/html' ; }
    if ((any {$_ == 25449 } @bigrams) and (any {$_ == 25964 } @bigrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 25449 } @bigrams) and (any {$_ == 28271 } @bigrams) ) { return 'text/java' ; }
    if ((any {$_ == 20756 } @bigrams) ) { return 'application/pdf' ; }
    if ((any {$_ == 54130 } @bigrams) ) { return 'unknown' ; }
    if ((any {$_ == 49968 } @bigrams) ) { return 'video/quicktime' ; }
    if ((any {$_ == 8202 } @bigrams) and (any {$_ == 25970 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 8202 } @bigrams) and (any {$_ == 13180 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 8202 } @bigrams) and (any {$_ == 28018 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 8202 } @bigrams) and (any {$_ == 28271 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 8202 } @bigrams) and (any {$_ == 25955 } @bigrams) ) { return 'text/plain' ; }
    if ((any {$_ == 8202 } @bigrams) and (any {$_ == 29285 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 8202 } @bigrams) and (any {$_ == 31092 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 8202 } @bigrams) and (any {$_ == 11565 } @bigrams) ) { return 'unknown' ; }
    if ((any {$_ == 8202 } @bigrams) and (any {$_ == 25971 } @bigrams) ) { return 'text/plain' ; }
    if ((any {$_ == 8202 } @bigrams) and (any {$_ == 12092 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 8202 } @bigrams) and (any {$_ == 2622 } @bigrams) ) { return 'application/pdf' ; }
    if ((any {$_ == 8202 } @bigrams) and (any {$_ == 29295 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 8202 } @bigrams) and (any {$_ == 25441 } @bigrams) ) { return 'text/java' ; }
    if ((any {$_ == 8202 } @bigrams) and (any {$_ == 8250 } @bigrams) ) { return 'text/css' ; }
    if ((any {$_ == 8202 } @bigrams) and (any {$_ == 25972 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 8202 } @bigrams) and (any {$_ == 24942 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 8202 } @bigrams) and (any {$_ == 28261 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 8202 } @bigrams) and (any {$_ == 29793 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 8202 } @bigrams) and (any {$_ == 2573 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 8202 } @bigrams) and (any {$_ == 25968 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 8202 } @bigrams) and (any {$_ == 29798 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 8202 } @bigrams) and (any {$_ == 29728 } @bigrams) ) { return 'text/css' ; }
    if ((any {$_ == 8202 } @bigrams) and (any {$_ == 25956 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 8202 } @bigrams) and (any {$_ == 28265 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 26144 } @bigrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 37 } @bigrams) ) { return 'application/vnd.lotus-1-2-3' ; }
    if ((any {$_ == 20 } @bigrams) and (any {$_ == 48 } @onegrams) ) { return 'application/zip' ; }
    if ((any {$_ == 20 } @bigrams) and (any {$_ == 248 } @onegrams) ) { return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' ; }
    if ((any {$_ == 20 } @bigrams) and (any {$_ == 60 } @onegrams) ) { return 'unknown' ; }
    if ((any {$_ == 20 } @bigrams) and (any {$_ == 158 } @onegrams) ) { return 'application/epub+zip' ; }
    if ((any {$_ == 8308 } @bigrams) and (any {$_ == 47 } @onegrams) ) { return 'application/sh' ; }
    if ((any {$_ == 8308 } @bigrams) and (any {$_ == 116 } @onegrams) ) { return 'unknown' ; }
    if ((any {$_ == 8736 } @bigrams) ) { return 'unknown' ; }
    if ((any {$_ == 28018 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 25888 } @bigrams) and (any {$_ == 101 } @onegrams) ) { return 'unknown' ; }
    if ((any {$_ == 25888 } @bigrams) and (any {$_ == 105 } @onegrams) ) { return 'application/fictionbook+xml' ; }
    if ((any {$_ == 12045 } @bigrams) ) { return 'application/pdf' ; }
    if ((any {$_ == 14957 } @bigrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 24940 } @bigrams) and (any {$_ == 97 } @onegrams) ) { return 'application/rtf' ; }
    if ((any {$_ == 24940 } @bigrams) and (any {$_ == 105 } @onegrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 65281 } @bigrams) ) { return 'application/navimap' ; }
    if ((any {$_ == 29295 } @bigrams) and (any {$_ == 25956 } @bigrams) ) { return 'application/javascript' ; }
    if ((any {$_ == 29295 } @bigrams) and (any {$_ == 2313 } @bigrams) ) { return 'text/java' ; }
    if ((any {$_ == 29295 } @bigrams) and (any {$_ == 28265 } @bigrams) ) { return 'text/css' ; }
    if ((any {$_ == 29295 } @bigrams) and (any {$_ == 3390 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 29295 } @bigrams) and (any {$_ == 28021 } @bigrams) ) { return 'application/sh' ; }
    if ((any {$_ == 29295 } @bigrams) and (any {$_ == 28018 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 29295 } @bigrams) and (any {$_ == 2573 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 29295 } @bigrams) and (any {$_ == 24941 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 29295 } @bigrams) and (any {$_ == 29793 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 29295 } @bigrams) and (any {$_ == 25970 } @bigrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 29295 } @bigrams) and (any {$_ == 26144 } @bigrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 26676 } @bigrams) ) { return 'video/quicktime' ; }
    if ((any {$_ == 0 } @bigrams) and (any {$_ == 128 } @onegrams) ) { return 'video/quicktime' ; }
    if ((any {$_ == 0 } @bigrams) and (any {$_ == 36 } @onegrams) ) { return 'application/arj' ; }
    if ((any {$_ == 0 } @bigrams) and (any {$_ == 216 } @onegrams) ) { return 'video/quicktime' ; }
    if ((any {$_ == 25971 } @bigrams) and (any {$_ == 114 } @onegrams) ) { return 'application/httpd-php' ; }
    if ((any {$_ == 25971 } @bigrams) and (any {$_ == 116 } @onegrams) ) { return 'application/python' ; }
    if ((any {$_ == 25971 } @bigrams) and (any {$_ == 105 } @onegrams) ) { return 'unknown' ; }
    if ((any {$_ == 29806 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 3390 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 528 } @bigrams) ) { return 'image/png' ; }
    if ((any {$_ == 8714 } @bigrams) ) { return 'text/csv' ; }
    if ((any {$_ == 17060 } @bigrams) ) { return 'application/navimap' ; }
    if ((any {$_ == 41937 } @bigrams) ) { return 'video/quicktime' ; }
    if ((any {$_ == 65389 } @bigrams) ) { return 'video/quicktime' ; }
    if ((any {$_ == 2560 } @bigrams) ) { return 'application/msaccess' ; }
    if ((any {$_ == 29793 } @bigrams) and (any {$_ == 8292 } @bigrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 29793 } @bigrams) and (any {$_ == 24944 } @bigrams) ) { return 'unknown' ; }
    if ((any {$_ == 29793 } @bigrams) and (any {$_ == 8202 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 29793 } @bigrams) and (any {$_ == 8293 } @bigrams) ) { return 'application/javascript' ; }
    if ((any {$_ == 29793 } @bigrams) and (any {$_ == 16691 } @bigrams) ) { return 'application/vnd.oasis.opendocument.text' ; }
    if ((any {$_ == 29793 } @bigrams) and (any {$_ == 8234 } @bigrams) ) { return 'text/java' ; }
    if ((any {$_ == 29793 } @bigrams) and (any {$_ == 3390 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 29793 } @bigrams) and (any {$_ == 15466 } @bigrams) ) { return 'application/vnd.oasis.opendocument.text' ; }
    if ((any {$_ == 56026 } @bigrams) ) { return 'application/vnd.oasis.opendocument.text' ; }
    if ((any {$_ == 61537 } @bigrams) ) { return 'video/quicktime' ; }
    if ((any {$_ == 65471 } @bigrams) ) { return 'image/png' ; }
    if ((any {$_ == 32768 } @bigrams) ) { return 'application/123' ; }
    if ((any {$_ == 28265 } @bigrams) and (any {$_ == 24933 } @bigrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 28265 } @bigrams) and (any {$_ == 8250 } @bigrams) ) { return 'text/css' ; }
    if ((any {$_ == 28265 } @bigrams) and (any {$_ == 28257 } @bigrams) ) { return 'text/css' ; }
    if ((any {$_ == 28265 } @bigrams) and (any {$_ == 29295 } @bigrams) ) { return 'text/java' ; }
    if ((any {$_ == 28265 } @bigrams) and (any {$_ == 2619 } @bigrams) ) { return 'text/java' ; }
    if ((any {$_ == 28265 } @bigrams) and (any {$_ == 24941 } @bigrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 28265 } @bigrams) and (any {$_ == 25970 } @bigrams) ) { return 'text/java' ; }
    if ((any {$_ == 28265 } @bigrams) and (any {$_ == 25972 } @bigrams) ) { return 'text/opml' ; }
    if ((any {$_ == 8226 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 27745 } @bigrams) ) { return 'text/html' ; }
    if ((any {$_ == 25964 } @bigrams) and (any {$_ == 95 } @onegrams) ) { return 'application/zip' ; }
    if ((any {$_ == 25964 } @bigrams) and (any {$_ == 110 } @onegrams) ) { return 'application/javascript' ; }
    if ((any {$_ == 25964 } @bigrams) and (any {$_ == 108 } @onegrams) ) { return 'application/xml' ; }
    if ((any {$_ == 5952 } @bigrams) ) { return 'application/vnd.lotus-1-2-3' ; }
    if ((any {$_ == 36166 } @bigrams) ) { return 'video/quicktime' ; }
    if ((any {$_ == 12341 } @bigrams) ) { return 'application/pdf' ; }
    if ((any {$_ == 25938 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 21024 } @bigrams) ) { return 'application/pdf' ; }
    if ((any {$_ == 34832 } @bigrams) ) { return 'video/quicktime' ; }
    if ((any {$_ == 32511 } @bigrams) ) { return 'image/jpm' ; }
    if ((any {$_ == 32767 } @bigrams) ) { return 'image/jpx' ; }
    if ((any {$_ == 2570 } @bigrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 25955 } @bigrams) and (any {$_ == 111 } @onegrams) ) { return 'application/xml' ; }
    if ((any {$_ == 25955 } @bigrams) and (any {$_ == 97 } @onegrams) ) { return 'text/java' ; }
    if ((any {$_ == 25955 } @bigrams) and (any {$_ == 99 } @onegrams) ) { return 'text/csv' ; }
    if ((any {$_ == 2313 } @bigrams) ) { return 'text/java' ; }
    if ((any {$_ == 19280 } @bigrams) and (any {$_ == 101 } @onegrams) ) { return 'application/vnd.oasis.opendocument.text' ; }
    if ((any {$_ == 19280 } @bigrams) and (any {$_ == 114 } @onegrams) ) { return 'application/vnd.oasis.opendocument.text' ; }
    if ((any {$_ == 19280 } @bigrams) and (any {$_ == 116 } @onegrams) ) { return 'application/epub+zip' ; }
    if ((any {$_ == 19280 } @bigrams) and (any {$_ == 47 } @onegrams) ) { return 'application/zip' ; }
    if ((any {$_ == 2833 } @bigrams) ) { return 'unknown' ; }
    if ((any {$_ == 1792 } @bigrams) ) { return 'unknown' ; }
    if ((any {$_ == 24948 } @bigrams) ) { return 'text/html' ; }
    if ((any {$_ == 26634 } @bigrams) ) { return 'text/css' ; }
    if ((any {$_ == 12148 } @bigrams) ) { return 'unknown' ; }
    if ((any {$_ == 1 } @bigrams) and (any {$_ == 12 } @bigrams) ) { return 'application/quattropro' ; }
    if ((any {$_ == 1 } @bigrams) and (any {$_ == 512 } @bigrams) ) { return 'unknown' ; }
    if ((any {$_ == 1 } @bigrams) and (any {$_ == 8 } @bigrams) ) { return 'application/silverlight' ; }
    if ((any {$_ == 1 } @bigrams) and (any {$_ == 16448 } @bigrams) ) { return 'application/msword' ; }
    if ((any {$_ == 1 } @bigrams) and (any {$_ == 128 } @bigrams) ) { return 'image/gif' ; }
    if ((any {$_ == 27753 } @bigrams) ) { return 'text/java' ; }
    if ((any {$_ == 25714 } @bigrams) ) { return 'text/csv' ; }
    if ((any {$_ == 37375 } @bigrams) ) { return 'image/jp2' ; }
    if ((any {$_ == 12320 } @bigrams) ) { return 'application/pdf' ; }
    if ((any {$_ == 8765 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 26740 } @bigrams) and (any {$_ == 29285 } @bigrams) ) { return 'text/plain' ; }
    if ((any {$_ == 26740 } @bigrams) and (any {$_ == 25965 } @bigrams) ) { return 'text/java' ; }
    if ((any {$_ == 26740 } @bigrams) and (any {$_ == 25970 } @bigrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 26740 } @bigrams) and (any {$_ == 29728 } @bigrams) ) { return 'text/java' ; }
    if ((any {$_ == 26740 } @bigrams) and (any {$_ == 26996 } @bigrams) ) { return 'application/javascript' ; }
    if ((any {$_ == 26740 } @bigrams) and (any {$_ == 28257 } @bigrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 15933 } @bigrams) ) { return 'unknown' ; }
    if ((any {$_ == 25712 } @bigrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 15392 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 8234 } @bigrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 5140 } @bigrams) ) { return 'application/pdf' ; }
    if ((any {$_ == 65279 } @bigrams) ) { return 'unknown' ; }
    if ((any {$_ == 2619 } @bigrams) and (any {$_ == 114 } @onegrams) ) { return 'unknown' ; }
    if ((any {$_ == 2619 } @bigrams) and (any {$_ == 9 } @onegrams) ) { return 'text/java' ; }
    if ((any {$_ == 2592 } @bigrams) ) { return 'application/pdf' ; }
    if ((any {$_ == 8293 } @bigrams) and (any {$_ == 28265 } @bigrams) ) { return 'text/java' ; }
    if ((any {$_ == 8293 } @bigrams) and (any {$_ == 29811 } @bigrams) ) { return 'text/java' ; }
    if ((any {$_ == 8293 } @bigrams) and (any {$_ == 28005 } @bigrams) ) { return 'unknown' ; }
    if ((any {$_ == 8293 } @bigrams) and (any {$_ == 29295 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 8293 } @bigrams) and (any {$_ == 8307 } @bigrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 8293 } @bigrams) and (any {$_ == 24941 } @bigrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 8293 } @bigrams) and (any {$_ == 29550 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 8293 } @bigrams) and (any {$_ == 24944 } @bigrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 8293 } @bigrams) and (any {$_ == 29728 } @bigrams) ) { return 'unknown' ; }
    if ((any {$_ == 8293 } @bigrams) and (any {$_ == 15392 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 8293 } @bigrams) and (any {$_ == 2619 } @bigrams) ) { return 'text/java' ; }
    if ((any {$_ == 8293 } @bigrams) and (any {$_ == 25970 } @bigrams) ) { return 'text/java' ; }
    if ((any {$_ == 8293 } @bigrams) and (any {$_ == 29793 } @bigrams) ) { return 'text/java' ; }
    if ((any {$_ == 8293 } @bigrams) and (any {$_ == 8302 } @bigrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 3376 } @bigrams) ) { return 'application/amipro' ; }
    if ((any {$_ == 28530 } @bigrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 65280 } @bigrams) and (any {$_ == 246 } @onegrams) ) { return 'application/vnd.ms-powerpoint' ; }
    if ((any {$_ == 65280 } @bigrams) and (any {$_ == 1 } @onegrams) ) { return 'image/vnd.microsoft.icon' ; }
    if ((any {$_ == 65280 } @bigrams) and (any {$_ == 255 } @onegrams) ) { return 'application/vnd.lotus-1-2-3' ; }
    if ((any {$_ == 65280 } @bigrams) and (any {$_ == 254 } @onegrams) ) { return 'unknown' ; }
    if ((any {$_ == 12298 } @bigrams) ) { return 'application/pdf' ; }
    if ((any {$_ == 4 } @bigrams) and (any {$_ == 1 } @onegrams) ) { return 'unknown' ; }
    if ((any {$_ == 4 } @bigrams) and (any {$_ == 2 } @onegrams) ) { return 'application/vnd.ms-excel' ; }
    if ((any {$_ == 4 } @bigrams) and (any {$_ == 3 } @onegrams) ) { return 'application/navimap' ; }
    if ((any {$_ == 21548 } @bigrams) ) { return 'text/csv' ; }
    if ((any {$_ == 5570 } @bigrams) ) { return 'image/png' ; }
    if ((any {$_ == 28015 } @bigrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 25970 } @bigrams) and (any {$_ == 105 } @onegrams) ) { return 'application/rtf' ; }
    if ((any {$_ == 25970 } @bigrams) and (any {$_ == 110 } @onegrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 25970 } @bigrams) and (any {$_ == 115 } @onegrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 25970 } @bigrams) and (any {$_ == 114 } @onegrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 25970 } @bigrams) and (any {$_ == 116 } @onegrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 25970 } @bigrams) and (any {$_ == 97 } @onegrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 32834 } @bigrams) ) { return 'image/png' ; }
    if ((any {$_ == 47802 } @bigrams) ) { return 'image/png' ; }
    if ((any {$_ == 16473 } @bigrams) ) { return 'unknown' ; }
    if ((any {$_ == 46592 } @bigrams) ) { return 'unknown' ; }
    if ((any {$_ == 8307 } @bigrams) and (any {$_ == 25701 } @bigrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 8307 } @bigrams) and (any {$_ == 11565 } @bigrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 8307 } @bigrams) and (any {$_ == 25449 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 8307 } @bigrams) and (any {$_ == 25970 } @bigrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 24941 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 13968 } @bigrams) ) { return 'video/quicktime' ; }
    if ((any {$_ == 13856 } @bigrams) ) { return 'application/pdf' ; }
    if ((any {$_ == 11891 } @bigrams) ) { return 'text/java' ; }
    if ((any {$_ == 30309 } @bigrams) ) { return 'unknown' ; }
    if ((any {$_ == 28527 } @bigrams) and (any {$_ == 101 } @onegrams) ) { return 'unknown' ; }
    if ((any {$_ == 28527 } @bigrams) and (any {$_ == 111 } @onegrams) ) { return 'application/yaml' ; }
    if ((any {$_ == 3387 } @bigrams) ) { return 'application/javascript' ; }
    if ((any {$_ == 13824 } @bigrams) ) { return 'video/quicktime' ; }
    if ((any {$_ == 25965 } @bigrams) and (any {$_ == 97 } @onegrams) ) { return 'unknown' ; }
    if ((any {$_ == 25965 } @bigrams) and (any {$_ == 101 } @onegrams) ) { return 'application/vnd.oasis.opendocument.text' ; }
    if ((any {$_ == 256 } @bigrams) and (any {$_ == 20 } @onegrams) ) { return 'application/zip' ; }
    if ((any {$_ == 256 } @bigrams) and (any {$_ == 1 } @onegrams) ) { return 'unknown' ; }
    if ((any {$_ == 8251 } @bigrams) ) { return 'application/vnd.pwg-xhtml-print+xml' ; }
    if ((any {$_ == 53608 } @bigrams) ) { return 'video/quicktime' ; }
    if ((any {$_ == 26988 } @bigrams) ) { return 'application/rtf' ; }
    if ((any {$_ == 2056 } @bigrams) ) { return 'application/zip' ; }
    if ((any {$_ == 128 } @bigrams) ) { return 'image/gif' ; }
    if ((any {$_ == 62721 } @bigrams) ) { return 'application/octet-stream' ; }
    if ((any {$_ == 3583 } @bigrams) ) { return 'unknown' ; }
    if ((any {$_ == 29548 } @bigrams) ) { return 'application/rtf' ; }
    if ((any {$_ == 27763 } @bigrams) and (any {$_ == 32 } @onegrams) ) { return 'application/msword' ; }
    if ((any {$_ == 27763 } @bigrams) and (any {$_ == 101 } @onegrams) ) { return 'application/rtf' ; }
    if ((any {$_ == 26996 } @bigrams) ) { return 'text/csv' ; }
    if ((any {$_ == 4369 } @bigrams) ) { return 'application/pdf' ; }
    if ((any {$_ == 5 } @bigrams) ) { return 'application/navimap' ; }
    if ((any {$_ == 26723 } @bigrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 18512 } @bigrams) ) { return 'video/mj2' ; }
    if ((any {$_ == 29797 } @bigrams) ) { return 'application/javascript' ; }
    if ((any {$_ == 512 } @bigrams) and (any {$_ == 12 } @onegrams) ) { return 'application/quattropro' ; }
    if ((any {$_ == 512 } @bigrams) and (any {$_ == 32 } @onegrams) ) { return 'application/qpro' ; }
    if ((any {$_ == 61451 } @bigrams) ) { return 'video/quicktime' ; }
    if ((any {$_ == 2314 } @bigrams) and (any {$_ == 26740 } @bigrams) ) { return 'application/javascript' ; }
    if ((any {$_ == 2314 } @bigrams) and (any {$_ == 8293 } @bigrams) ) { return 'text/java' ; }
    if ((any {$_ == 2314 } @bigrams) and (any {$_ == 25960 } @bigrams) ) { return 'text/html' ; }
    if ((any {$_ == 8227 } @bigrams) ) { return 'unknown' ; }
    if ((any {$_ == 29285 } @bigrams) and (any {$_ == 111 } @onegrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 29285 } @bigrams) and (any {$_ == 105 } @onegrams) ) { return 'application/xml' ; }
    if ((any {$_ == 29285 } @bigrams) and (any {$_ == 32 } @onegrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 29285 } @bigrams) and (any {$_ == 101 } @onegrams) ) { return 'text/csv' ; }
    if ((any {$_ == 11565 } @bigrams) ) { return 'text/css' ; }
    if ((any {$_ == 6278 } @bigrams) ) { return 'video/quicktime' ; }
    if ((any {$_ == 13870 } @bigrams) ) { return 'application/pdf' ; }
    if ((any {$_ == 29728 } @bigrams) and (any {$_ == 105 } @onegrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 29728 } @bigrams) and (any {$_ == 111 } @onegrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 29728 } @bigrams) and (any {$_ == 115 } @onegrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 29728 } @bigrams) and (any {$_ == 114 } @onegrams) ) { return 'unknown' ; }
    if ((any {$_ == 64768 } @bigrams) ) { return 'application/vnd.ms-excel' ; }
    if ((any {$_ == 63418 } @bigrams) ) { return 'application/pdf' ; }
    if ((any {$_ == 15677 } @bigrams) ) { return 'application/javascript' ; }
    if ((any {$_ == 17745 } @bigrams) ) { return 'image/tiff' ; }
    if ((any {$_ == 25960 } @bigrams) and (any {$_ == 97 } @onegrams) ) { return 'unknown' ; }
    if ((any {$_ == 25960 } @bigrams) and (any {$_ == 45 } @onegrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 25960 } @bigrams) and (any {$_ == 109 } @onegrams) ) { return 'unknown' ; }
    if ((any {$_ == 11821 } @bigrams) ) { return 'application/silverlight' ; }
    if ((any {$_ == 2573 } @bigrams) and (any {$_ == 105 } @onegrams) ) { return 'application/xml' ; }
    if ((any {$_ == 2573 } @bigrams) and (any {$_ == 110 } @onegrams) ) { return 'application/xml' ; }
    if ((any {$_ == 2573 } @bigrams) and (any {$_ == 111 } @onegrams) ) { return 'application/xml' ; }
    if ((any {$_ == 2573 } @bigrams) and (any {$_ == 116 } @onegrams) ) { return 'application/pdf' ; }
    if ((any {$_ == 2573 } @bigrams) and (any {$_ == 114 } @onegrams) ) { return 'application/xml' ; }
    if ((any {$_ == 2573 } @bigrams) and (any {$_ == 97 } @onegrams) ) { return 'application/xml' ; }
    if ((any {$_ == 11520 } @bigrams) ) { return 'application/vnd.wordperfect' ; }
    if ((any {$_ == 2048 } @bigrams) and (any {$_ == 116 } @onegrams) ) { return 'unknown' ; }
    if ((any {$_ == 2048 } @bigrams) and (any {$_ == 255 } @onegrams) ) { return 'unknown' ; }
    if ((any {$_ == 2048 } @bigrams) and (any {$_ == 111 } @onegrams) ) { return 'application/vnd.oasis.opendocument.text' ; }
    if ((any {$_ == 2048 } @bigrams) and (any {$_ == 105 } @onegrams) ) { return 'unknown' ; }
    if ((any {$_ == 2048 } @bigrams) and (any {$_ == 103 } @onegrams) ) { return 'unknown' ; }
    if ((any {$_ == 29541 } @bigrams) and (any {$_ == 116 } @onegrams) ) { return 'text/java' ; }
    if ((any {$_ == 29541 } @bigrams) and (any {$_ == 105 } @onegrams) ) { return 'text/java' ; }
    if ((any {$_ == 29541 } @bigrams) and (any {$_ == 111 } @onegrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 27759 } @bigrams) ) { return 'text/css' ; }
    if ((any {$_ == 8245 } @bigrams) ) { return 'application/pdf' ; }
    if ((any {$_ == 26994 } @bigrams) ) { return 'text/java' ; }
    if ((any {$_ == 25972 } @bigrams) and (any {$_ == 116 } @onegrams) ) { return 'application/xml' ; }
    if ((any {$_ == 25972 } @bigrams) and (any {$_ == 45 } @onegrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 25972 } @bigrams) and (any {$_ == 105 } @onegrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 25972 } @bigrams) and (any {$_ == 32 } @onegrams) ) { return 'unknown' ; }
    if ((any {$_ == 3 } @bigrams) ) { return 'unknown' ; }
    if ((any {$_ == 25956 } @bigrams) ) { return 'application/ruby' ; }
    if ((any {$_ == 25705 } @bigrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 1024 } @bigrams) ) { return 'unknown' ; }
    if ((any {$_ == 5623 } @bigrams) ) { return 'application/pdf' ; }
    if ((any {$_ == 12576 } @bigrams) and (any {$_ == 101 } @onegrams) ) { return 'application/msword' ; }
    if ((any {$_ == 12576 } @bigrams) and (any {$_ == 105 } @onegrams) ) { return 'text/plain' ; }
    if ((any {$_ == 12576 } @bigrams) and (any {$_ == 49 } @onegrams) ) { return 'text/plain' ; }
    if ((any {$_ == 2605 } @bigrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 8306 } @bigrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 25710 } @bigrams) ) { return 'application/pdf' ; }
    if ((any {$_ == 2 } @bigrams) and (any {$_ == 212 } @onegrams) ) { return 'application/vnd.wordperfect' ; }
    if ((any {$_ == 2 } @bigrams) and (any {$_ == 3 } @onegrams) ) { return 'application/vnd.lotus-1-2-3' ; }
    if ((any {$_ == 27746 } @bigrams) ) { return 'text/css' ; }
    if ((any {$_ == 49347 } @bigrams) ) { return 'unknown' ; }
    if ((any {$_ == 27234 } @bigrams) ) { return 'application/pdf' ; }
    if ((any {$_ == 30060 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 8302 } @bigrams) and (any {$_ == 32 } @onegrams) ) { return 'unknown' ; }
    if ((any {$_ == 8302 } @bigrams) and (any {$_ == 111 } @onegrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 8238 } @bigrams) ) { return 'text/plain' ; }
    if ((any {$_ == 8250 } @bigrams) and (any {$_ == 101 } @onegrams) ) { return 'text/plain' ; }
    if ((any {$_ == 8250 } @bigrams) and (any {$_ == 114 } @onegrams) ) { return 'text/css' ; }
    if ((any {$_ == 12595 } @bigrams) ) { return 'unknown' ; }
    if ((any {$_ == 8772 } @bigrams) ) { return 'message/rfc822' ; }
    if ((any {$_ == 49539 } @bigrams) ) { return 'image/png' ; }
    if ((any {$_ == 11634 } @bigrams) ) { return 'text/plain' ; }
    if ((any {$_ == 12092 } @bigrams) ) { return 'text/html' ; }
    if ((any {$_ == 2674 } @bigrams) ) { return 'unknown' ; }
    if ((any {$_ == 12064 } @bigrams) ) { return 'application/pdf' ; }
    if ((any {$_ == 10784 } @bigrams) ) { return 'text/java' ; }
    if ((any {$_ == 448 } @bigrams) ) { return 'video/quicktime' ; }
    if ((any {$_ == 28532 } @bigrams) ) { return 'unknown' ; }
    if ((any {$_ == 33275 } @bigrams) ) { return 'application/vnd.ms-powerpoint' ; }
    if ((any {$_ == 28518 } @bigrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 18083 } @bigrams) ) { return 'video/quicktime' ; }
    if ((any {$_ == 12042 } @bigrams) ) { return 'application/pdf' ; }
    if ((any {$_ == 25968 } @bigrams) ) { return 'text/java' ; }
    if ((any {$_ == 29795 } @bigrams) ) { return 'unknown' ; }
    if ((any {$_ == 9289 } @bigrams) ) { return 'image/jpeg' ; }
    if ((any {$_ == 50115 } @bigrams) ) { return 'image/jpeg' ; }
    if ((any {$_ == 15420 } @bigrams) ) { return 'image/jpeg' ; }
    if ((any {$_ == 28769 } @bigrams) and (any {$_ == 34 } @onegrams) ) { return 'application/xml' ; }
    if ((any {$_ == 28769 } @bigrams) and (any {$_ == 97 } @onegrams) ) { return 'unknown' ; }
    if ((any {$_ == 21328 } @bigrams) ) { return 'unknown' ; }
    if ((any {$_ == 65535 } @bigrams) and (any {$_ == 16 } @onegrams) ) { return 'unknown' ; }
    if ((any {$_ == 65535 } @bigrams) and (any {$_ == 101 } @onegrams) ) { return 'application/mswrite' ; }
    if ((any {$_ == 65535 } @bigrams) and (any {$_ == 32 } @onegrams) ) { return 'application/msword' ; }
    if ((any {$_ == 53547 } @bigrams) ) { return 'unknown' ; }
    if ((any {$_ == 15369 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 29801 } @bigrams) and (any {$_ == 105 } @onegrams) ) { return 'unknown' ; }
    if ((any {$_ == 29801 } @bigrams) and (any {$_ == 111 } @onegrams) ) { return 'application/sh' ; }
    if ((any {$_ == 14 } @bigrams) and (any {$_ == 2 } @onegrams) ) { return 'application/lotus' ; }
    if ((any {$_ == 14 } @bigrams) and (any {$_ == 7 } @onegrams) ) { return 'application/123' ; }
    if ((any {$_ == 14004 } @bigrams) ) { return 'video/quicktime' ; }
    if ((any {$_ == 16672 } @bigrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 24944 } @bigrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 24579 } @bigrams) ) { return 'video/quicktime' ; }
    if ((any {$_ == 8192 } @bigrams) ) { return 'application/octet-stream' ; }
    if ((any {$_ == 28024 } @bigrams) ) { return 'application/httpd-php' ; }
    if ((any {$_ == 255 } @bigrams) and (any {$_ == 254 } @onegrams) ) { return 'unknown' ; }
    if ((any {$_ == 255 } @bigrams) and (any {$_ == 1 } @onegrams) ) { return 'application/vnd.ms-powerpoint' ; }
    if ((any {$_ == 1285 } @bigrams) ) { return 'application/msaccess' ; }
    if ((any {$_ == 8 } @bigrams) and (any {$_ == 185 } @onegrams) ) { return 'unknown' ; }
    if ((any {$_ == 8 } @bigrams) and (any {$_ == 237 } @onegrams) ) { return 'unknown' ; }
    if ((any {$_ == 8 } @bigrams) and (any {$_ == 3 } @onegrams) ) { return 'unknown' ; }
    if ((any {$_ == 8 } @bigrams) and (any {$_ == 1 } @onegrams) ) { return 'video/quicktime' ; }
    if ((any {$_ == 24942 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 57219 } @bigrams) ) { return 'application/vnd.amazon.mobi8-ebook' ; }
    if ((any {$_ == 10536 } @bigrams) ) { return 'text/java' ; }
    if ((any {$_ == 29811 } @bigrams) ) { return 'text/java' ; }
    if ((any {$_ == 2336 } @bigrams) ) { return 'text/java' ; }
    if ((any {$_ == 24946 } @bigrams) and (any {$_ == 44 } @onegrams) ) { return 'text/csv' ; }
    if ((any {$_ == 24946 } @bigrams) and (any {$_ == 97 } @onegrams) ) { return 'application/vnd.palm' ; }
    if ((any {$_ == 425 } @bigrams) ) { return 'image/gif' ; }
    if ((any {$_ == 25708 } @bigrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 11808 } @bigrams) ) { return 'text/css' ; }
    if ((any {$_ == 2666 } @bigrams) ) { return 'application/pdf' ; }
    if ((any {$_ == 15546 } @bigrams) ) { return 'application/epub+zip' ; }
    if ((any {$_ == 24864 } @bigrams) ) { return 'unknown' ; }
    if ((any {$_ == 8448 } @bigrams) ) { return 'application/xml' ; }
    if ((any {$_ == 3072 } @bigrams) ) { return 'application/mobipocket-ebook' ; }
    if ((any {$_ == 28271 } @bigrams) and (any {$_ == 11891 } @bigrams) ) { return 'application/javascript' ; }
    if ((any {$_ == 28271 } @bigrams) and (any {$_ == 15392 } @bigrams) ) { return 'application/vnd.google-earth.kml+xml' ; }
    if ((any {$_ == 28271 } @bigrams) and (any {$_ == 2314 } @bigrams) ) { return 'text/java' ; }
    if ((any {$_ == 28271 } @bigrams) and (any {$_ == 28521 } @bigrams) ) { return 'text/java' ; }
    if ((any {$_ == 28271 } @bigrams) and (any {$_ == 8202 } @bigrams) ) { return 'text/java' ; }
    if ((any {$_ == 28271 } @bigrams) and (any {$_ == 28784 } @bigrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 28271 } @bigrams) and (any {$_ == 8 } @bigrams) ) { return 'application/vnd.oasis.opendocument.text' ; }
    if ((any {$_ == 28271 } @bigrams) and (any {$_ == 29800 } @bigrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 37888 } @bigrams) ) { return 'video/quicktime' ; }
    if ((any {$_ == 16424 } @bigrams) ) { return 'application/navimap' ; }
    if ((any {$_ == 2676 } @bigrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 8292 } @bigrams) ) { return 'text/markdown' ; }
    if ((any {$_ == 30946 } @bigrams) ) { return 'unknown' ; }
    if ((any {$_ == 32770 } @bigrams) ) { return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' ; }
    if ((any {$_ == 3855 } @bigrams) ) { return 'image/tiff' ; }
    return 'unknown';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::FormatIdentification::RandomSampling::Model - methods to identify files using random sampling

=head1 VERSION

version 0.005

=head1 SYNOPSIS

This module is an extension of L<File::FormatIdentification::RandomSampling> to get a good estimation about the mimetype of media (or files). It uses random sampling of sectors to obtain heuristics about the content types.

To check the mimetype of a given binary string:

  my $ff = File::FormatIdentification::RandomSampling->new(); # basic instantiation
  my $type = $ff->calc_mimetype($buffer); # calc type of given binary string

The model was learned and uses a decision tree. The module is in very early state.
You should check the files F<cfi_create_training_data.pl> and F<cfi_learn_model.pl> to create own models.

=head1 NAME

File::FormatIdentification::RandomSampling::Model

=head1 SOURCE

The actual development version is available at L<https://art1pirat.spdns.org/art1/crazy-fast-image-scan>

=head1 METHODS

=head2 calc_mimetype

returns string indicating mimetype of a given buffer.

=head1 AUTHOR

Andreas Romeyke <pause@andreas-romeyke.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Andreas Romeyke.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

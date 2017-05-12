#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use CPAN::Changes::Markdown;

my $changes = CPAN::Changes::Markdown->load_utf8('./Changes');

binmode *STDOUT, ':utf8';

*STDOUT->print( $changes->serialize );

#!/usr/bin/perl
use lib qw (../lib lib);
use Test::More 'no_plan';
use strict;
use warnings;
use MKDoc::XML::Decode;

my $decode = new MKDoc::XML::Decode (qw /xml xhtml numeric/);
is ($decode->process ('Hello, &lt;'), 'Hello, <');
is ($decode->process ('Hello, &gt;'), 'Hello, >');
is ($decode->process ('Hello, &amp;'), 'Hello, &');
is ($decode->process ('Hello, &quot;'), 'Hello, "');
is ($decode->process ('Hello, &apos;'), 'Hello, \'');

1;


__END__

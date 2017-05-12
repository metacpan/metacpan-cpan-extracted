#!/usr/bin/perl
use lib qw (../lib lib);
use Test::More 'no_plan';
use strict;
use warnings;
use MKDoc::XML::Encode;

is (MKDoc::XML::Encode->process ('Hello, <'),  'Hello, &lt;');
is (MKDoc::XML::Encode->process ('Hello, >'),  'Hello, &gt;');
is (MKDoc::XML::Encode->process ('Hello, &'),  'Hello, &amp;');
is (MKDoc::XML::Encode->process ('Hello, "'),  'Hello, &quot;');
is (MKDoc::XML::Encode->process ('Hello, \''), 'Hello, &apos;');
is (MKDoc::XML::Encode->process ('ABCDEF'),    'ABCDEF');


1;


__END__

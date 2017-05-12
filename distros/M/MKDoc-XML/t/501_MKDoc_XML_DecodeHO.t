#!/usr/bin/perl
use lib qw (../lib lib);
use Test::More 'no_plan';
use strict;
use warnings;
use MKDoc::XML::Decode;
$SIG{__WARN__} = sub {};

# those should be unchanged
my $decode = new MKDoc::XML::Decode 'xhtml';
is ($decode->process ('Hello, &lt;'), 'Hello, &lt;');
is ($decode->process ('Hello, &gt;'), 'Hello, &gt;');
is ($decode->process ('Hello, &amp;'), 'Hello, &amp;');
is ($decode->process ('Hello, &quot;'), 'Hello, &quot;');
is ($decode->process ('Hello, &apos;'), 'Hello, &apos;');

# but these should be
isnt ($decode->process ('&nbsp;'), '&nbsp;');

# add your own here :)


1;


__END__

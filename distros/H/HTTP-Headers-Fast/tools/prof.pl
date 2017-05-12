use strict;
use warnings;
use HTTP::Headers::Fast;

my $f = HTTP::Headers::Fast->new(
    'Connection'     => 'close',
    'Date'           => 'Tue, 11 Nov 2008 01:16:37 GMT',
    'Content-Length' => 3744,
    'Content-Type'   => 'text/html',
    'Status'         => 200,
);

for (0..100) { $f->push_header('X-Foo', 3) }

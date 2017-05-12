#!perl -w
use strict;
use Test::More tests => 3;
use MIME::Detect;
use Data::Dumper;

my $mime = MIME::Detect->new(
    database => ['t/freedesktop.org.xml'],
);

my @type = $mime->mime_types($0);

if( !ok 0+@type, "We identify $0 with at least one type" ) {
    SKIP: { skip "Didn't identify $0", 1 };
} else {
    my $type = $type[0];
    is $type->mime_type, "application/x-perl", "It's a Perl program as the highest priority";
    
    my @t = map { $_->mime_type } @type;
    is_deeply \@t, [
    'application/x-perl',
    'text/plain',
    ], "We find all kinds of types for $0"
        or diag Dumper \@t;
};

done_testing;
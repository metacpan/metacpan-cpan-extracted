#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf;

my $body;
my $type;
get+post "/" => sub {
    return { -content => $body, -type => $type };
};

my ($status, $head, $content);

$body = "some garbage";
($status, $head, $content) = do_run();
is ($head->{'Content-Type'},   'text/plain; charset=utf-8', "text detected");

$body = "some garbage " . chr(255);
($status, $head, $content) = do_run();
is ($head->{'Content-Type'},   'application/octet-stream', "binary detected");

$type = "text/foobared";
($status, $head, $content) = do_run();
is ($head->{'Content-Type'},   'text/foobared; charset=utf-8'
    , "Utf appended");

done_testing;

# This is begging to use run_test instead, but MAYBE it'd be wise
#     to keep some plain old PSGI just in case
sub do_run {
    my $raw = neaf->run->( {} );
    my ($status, $head, $content) = @$raw;
    my %head_hash = @$head;
    $content = join "", @$content;

    is ($head_hash{'Content-Length'}, length $content, "binary length");

    return ($status, \%head_hash, $content);
};

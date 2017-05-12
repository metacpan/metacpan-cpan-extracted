#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use IO::Handle;

use MVC::Neaf::Request::PSGI;

my $fake_data = "FOOD BARD BAZOOKA";
open (my $fd, "<", \$fake_data);
my $io = IO::Handle->new_from_fd( $fd, "<" );

my %env = (
    REQUEST_METHOD => 'POST',
    CONTENT_TYPE   => 'text/plain',
    CONTENT_LENGTH => length $fake_data,
    'psgi.input'   => $io,
);

my $req = MVC::Neaf::Request::PSGI->new( env => \%env );

is ($req->body, $fake_data, "Data round trip");

done_testing;

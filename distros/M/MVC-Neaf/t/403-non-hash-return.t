#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Warn;
use MVC::Neaf::Util qw(JSON encode_json decode_json);

use MVC::Neaf;

my $file = __FILE__;
get '/garbled' => sub {"Hello world!"}; my $line = __LINE__;


my $content;
warnings_like {
    $content = neaf->run_test('/garbled');
} [qr/Controller must return hash.*\b$file\b.*\b$line\.?\n?$/], "Warning correct";

my $ref = eval {
    decode_json( $content );
};
ok $ref, "Json returned"
    or diag "FAIL: $@";

is $ref->{error}, 500, "Error 500";

done_testing;

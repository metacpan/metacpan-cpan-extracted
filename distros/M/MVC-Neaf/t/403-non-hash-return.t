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

like $content, qr/Error 500/, "Error returned to the user";

done_testing;

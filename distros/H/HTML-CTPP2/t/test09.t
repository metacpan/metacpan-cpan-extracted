# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl HTML-CTPP2.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;
BEGIN { use_ok('HTML::CTPP2') };

use strict;
use MIME::Base64;
use IO::Scalar;

my $T = new HTML::CTPP2();
ok( ref $T eq "HTML::CTPP2", "Create object.");

my $Bytecode = $T -> parse_text("From here: Hello, <TMPL_var world.name>!\nFrom file `hello.tmpl`: <TMPL_include hello.tmpl>");
ok( ref $Bytecode eq "HTML::CTPP2::Bytecode", "Create object.");

my %H = ("world.name" => "World");
ok( $T -> param(\%H) == 0);

my $Result = encode_base64($T -> output($Bytecode));
ok( $Result eq "RnJvbSBoZXJlOiBIZWxsbywgV29ybGQhCkZyb20gZmlsZSBgaGVsbG8udG1wbGA6IEhlbGxvLCBX\nb3JsZCEKCg==\n");

$T -> reset();

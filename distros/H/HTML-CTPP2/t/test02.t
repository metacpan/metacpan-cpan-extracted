# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl HTML-CTPP2.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 15;
BEGIN { use_ok('HTML::CTPP2') };

use strict;
use MIME::Base64;

my $T = new HTML::CTPP2();
ok( ref $T eq "HTML::CTPP2", "Create object.");

my @IncludeDirs = ("./", "examples");
ok( $T -> include_dirs(\@IncludeDirs) == 0);

my $Bytecode = $T -> parse_template("hello.tmpl");
ok( ref $Bytecode eq "HTML::CTPP2::Bytecode", "Create object.");

# Test base methods
my @methods = qw/save/;
can_ok($Bytecode, @methods);

my $Code = $Bytecode -> save("hello.ct2");
ok($Code == 0);

undef $Bytecode;
$Bytecode = $T -> load_bytecode("hello.ct2");
ok( ref $Bytecode eq "HTML::CTPP2::Bytecode", "Create object.");

my %H = ("world" => { name => "beautiful World" });
ok( $T -> param(\%H) == 0);

my $Result = $T -> output($Bytecode);
ok( $Result eq "Hello, beautiful World!\n\n");

$T -> reset();
ok( encode_base64($T -> dump_params()) eq "eyB9\n");

$Result = $T -> output($Bytecode);
ok( $Result eq "Hello, !\n\n");

my %HH = ("world" => { name => "awfull World"});
ok( $T -> param(\%HH) == 0);

ok( encode_base64($T -> dump_params()) eq "ewogICJ3b3JsZCIgPT4gMSwKICAid29ybGQubmFtZSIgPT4gImF3ZnVsbCBXb3JsZCIKfQ==\n");

$Result = $T -> output($Bytecode);
ok( $Result eq "Hello, awfull World!\n\n");

%HH = ("world.name" => "World");
$T -> param(\%HH);
$Result = $T -> output($Bytecode);
ok( $Result eq "Hello, World!\n\n");


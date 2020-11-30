# Test the behaviour with a string/number variable.

use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use JSON::Create 'create_json';
use JSON::Parse 'valid_json';
use Scalar::Util 'dualvar';

# Unicode::UCD simulation

my $script = dualvar (100, 'Common');
my $obj = {script => $script};
my $json = create_json ($obj);
ok (valid_json ($json));

done_testing ();

# Test the indentation feature.

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
use JSON::Create;
use JSON::Parse 'valid_json';
# Get up offa that thing
my %thing = ("it's your thing" => [qw! do what you wanna do!],
	     "I can't tell you" => [qw! who to sock it to !]);
my $jc = JSON::Create->new ();
$jc->indent (1);
my $out = $jc->run (\%thing);
#print "$out\n";
like ($out, qr!^\t"I!sm, "indentation of object key");
like ($out, qr!^\t\t"sock!sm, "indentation of array element");
like ($out, qr!\n$!, "final newline");
ok (valid_json ($out), "JSON is valid");
done_testing ();

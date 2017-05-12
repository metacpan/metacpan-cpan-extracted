# This tests the boolean round-trip behaviour of JSON::Parse and
# JSON::Create.

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
use B;
#if (!$JSON::Create::xsok) {
#    plan skip_all => "Not running XS version, cannot do these tests";
#}
use JSON::Parse '0.38', 'parse_json';
use Data::Dumper;
my $jsonin = '{"hocus":true,"pocus":false,"focus":null}';
my $p = parse_json ($jsonin);
#delete $p->{focus};
#$p->{focus} = 'monkey';
#print Dumper ($p);
my $jc = JSON::Create->new ();
my $out = $jc->run ($p);
#printf ("%d\n", $p->{pocus});
like ($out, qr/"hocus":true/);
like ($out, qr/"pocus":false/);
like ($out, qr/"focus":null/);
my $json_array = '[true,false,null]';
my $q = parse_json ($json_array);
#delete $q->[1];
#$q->[1] = "Magical Mystery Tour";
my $outq = $jc->run ($q);

is ($outq, $json_array, "in = out");
done_testing ();

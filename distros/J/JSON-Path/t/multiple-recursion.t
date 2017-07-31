use Test2::V0 '-target' => 'JSON::Path';

use JSON::MaybeXS;

# Test for RT #122529

my $to_find = '$..foo..value';
my $doc     = '{"foo":{"value":3}}';

my $jpath = $CLASS->new($to_find);

my @found = $jpath->paths($doc);

is( \@found, [q{$['foo']['value']}], 'Path correct' );

my $hash = decode_json($doc);
$jpath->value($hash) = 4;
is $hash->{foo}{value}, 4, 'value correct';
done_testing();


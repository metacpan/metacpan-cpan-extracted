use 5.016;
use Test2::V0 '-target' => 'JSON::Path';

my $json = '{
   "path.two" : "value.two",
   "path.one" : "value.one"
}';

my $jpath = $CLASS->new('$.path\.one');
is $jpath->value($json), 'value.one';
done_testing;

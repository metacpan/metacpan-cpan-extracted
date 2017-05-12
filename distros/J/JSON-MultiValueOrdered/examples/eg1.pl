use 5.010;
use JSON::MultiValueOrdered;

my $json = JSON::MultiValueOrdered->new;
my $data = $json->decode(q( {"a":1,"b":2,"b":3} ))
	or die $json->error;

say $json->encode($data);

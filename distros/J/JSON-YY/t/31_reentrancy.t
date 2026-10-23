use strict;
use warnings;
use Test::More;
use JSON::YY ':doc';

{
    package YY::Growing;
    our $size = 1000;
    sub count { scalar @_ }
    sub TO_JSON {
        $size *= 2;
        count(1 .. $size);
        return { converted => 7 };
    }
}

my $obj = bless {}, 'YY::Growing';
for my $pretty (0, 1) {
    my $coder = JSON::YY->new(convert_blessed => 1, pretty => $pretty);
    is_deeply $coder->decode($coder->encode($obj)), { converted => 7 },
        "OO encode survives a TO_JSON that grows the stack (pretty=$pretty)";
}

my @results = ('left', (jfrom $obj), 'right');
is scalar(@results), 3, 'jfrom preserves surrounding list operands';
is "$results[1]", '{"converted":7}', 'jfrom returns the converted document';

my $doc = jdoc '{}';
my $result = jset $doc, "/value", $obj;
is "$doc", '{"value":{"converted":7}}', 'jset survives TO_JSON stack growth';
is "$result", "$doc", 'jset returns its document after the callback';

done_testing;

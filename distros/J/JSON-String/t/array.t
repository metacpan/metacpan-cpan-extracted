use strict;
use warnings;

use Test::More tests => 2;
use Test::Exception;

use JSON::String;
use JSON;

my $codec = JSON->new->canonical;

subtest 'encode array' => sub {
    plan tests => 7;

    my $orig = [ 1, 2, 3, 4 ];
    my $string = $codec->encode($orig);

    my $obj = JSON::String->tie($string);
    isa_ok($obj, 'ARRAY');
    is_deeply([ @$obj ],
              $orig,
              'object arrayifies');
    is(scalar(@$obj), scalar(@$orig), 'array as scalar');
    for(my $i = 0; $i < @$orig; $i++) {
        is($obj->[$i], $orig->[$i], "index $i");
    }
};

subtest 'change array' => sub {
        plan tests => 6;

    my $expected = [ "1", "2", "3", "4" ];
    my $string = $codec->encode($expected);
    my $obj = JSON::String->tie($string);

    $obj->[0] = $expected->[0] = 'hi';
    is($string,
       $codec->encode($expected),
       'change 0th element');

    push(@$obj, 'pushed');
    push(@$expected, 'pushed');
    is($string,
       $codec->encode($expected),
       'push new element');

    pop(@$obj);
    pop(@$expected);
    is($string,
       $codec->encode($expected),
       'pop element');

    unshift(@$obj, 'unshifted');
    unshift(@$expected, 'unshifted');
    is($string,
       $codec->encode($expected),
       'unshift element');

    shift(@$obj);
    shift(@$expected);
    is($string,
       $codec->encode($expected),
       'shift element');

    @$obj = @$expected = ();
    is($string,
        $codec->encode($expected),
        'clear');
};

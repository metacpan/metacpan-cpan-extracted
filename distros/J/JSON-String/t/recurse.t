use strict;
use warnings;

use Test::More tests => 4;

use JSON::PP;
use JSON::String;
use Test::Exception;

my $codec = JSON->new->canonical;

subtest 'hash of arrays' => sub {
    plan tests => 10;

    my $orig = { a => "1", b => ['1', '2'], c => ['a', 'b'] };
    my $string = $codec->encode($orig);

    my $obj = JSON::String->tie($string);
    is_deeply($obj,
              $orig,
              'object hashifies');
    is(scalar(%$obj), scalar(%$orig), 'hash as scalar');
    foreach my $key ( qw( a b c )) {
        is_deeply($obj->{$key}, $orig->{$key}, "key $key");
    }

    $obj->{a} = $orig->{a} = 'hi';
    is($string,
        $codec->encode($orig),
        'changed string value');

    $obj->{b}->[0] = $orig->{b}->[0] = 'there';
    is($string,
        $codec->encode($orig),
        'changed sub-array value');

    $obj->{b} = $orig->{b} = ['3', '4'];
    is($string,
        $codec->encode($orig),
        'changed whole sub-array');

    $obj->{b}->[0] = $orig->{b}->[0] = 'changed';
    is($string,
        $codec->encode($orig),
        'changed a newly added array value');

    $obj->{b}->[2] = $orig->{b}->[2] = { key => 'value' };
    is($string,
        $codec->encode($orig),
        'add new hashref to array');
};

subtest 'array of hashes' => sub {
    plan tests => my $count = 10;
    for (my $i = 0; $i < $count; $i++) {
        # Try several times to try and trip a hash randomization bug
        my $picker = make_key_picker();

        subtest "iteration $i" => sub {
            plan tests => 4;

            my($key1, $key2) = map { $picker->() } qw(1 2);
            my $orig = [ 0, 1, { $key1 => 1, $key2 => 2 } ];
            my $string = $codec->encode($orig);

            my $obj = JSON::String->tie($string);
            is_deeply($obj,
                        $orig,
                        'object arrayifies');

            $obj->[2]->{a} = $orig->[2]->{a} = 'changed';
            is_deeply($codec->decode($string),
                      $orig,
                      'change nested hash value');

            $obj->[0] = $orig->[0] = { new => 'hash' };
            is_deeply($codec->decode($string),
                      $orig,
                      'change string value in array to hashref');

            my $key3 = $picker->();
            $obj->[0]->{$key3} = $orig->[0]->{$key3} = 'changed hash value';
            is_deeply($codec->decode($string),
                      $orig,
                      'change newly added hash value')
                or diag("Hash keys were $key1, $key2, $key3. Codec canonical is: ".JSON::String->codec->get_canonical);
        };
    }
};

subtest 'add multi-level' => sub {
    plan tests => 2;

    my $orig = [ 1 ];
    my $string = $codec->encode($orig);
    my $obj = JSON::String->tie($string);

    $obj->[1] = $orig->[1] = { key => { child => { grandchild => [ 99 ] } } };
    is($string,
        $codec->encode($orig),
        'Add multi-level data structure to existing object');

    $obj->[1]->{key}->{child}->{grandchild}->[0]
        = $orig->[1]->{key}->{child}->{grandchild}->[0] = 'changed';
    is($string,
        $codec->encode($orig),
        'Change newly added data');
};

subtest 'recursive' => sub {
    plan tests => 2;

    my $string = '{ "key": "value" }';
    my $obj = JSON::String->tie($string);
    ok($obj, 'initial data');

    local $SIG{ALRM} = sub { die 'alarm' };
    alarm(1);

    throws_ok { $obj->{recurse} = $obj }
        qr(^Error encoding data structure),
        'Recursive data throws an exception';

    alarm(0);
};

sub make_key_picker {
    my @letters = ('a' .. 'z');
    return sub {
        return splice(@letters, int(rand(scalar(@letters))), 1);
    }
}

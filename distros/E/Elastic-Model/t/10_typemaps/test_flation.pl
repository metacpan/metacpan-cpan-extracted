#!/usr/bin/perl

use strict;
use warnings;
use Test::More 0.96;
use Test::Moose;
use Test::Exception;

use lib 't/lib';

BEGIN {
    use_ok 'TypeTest' || print 'Bail out';
}

our ( $test_class, @fields );

my $model = new_ok 'TypeTest';
isa_ok my $tm = $model->typemap, 'Elastic::Model::TypeMap::Base';

note '';
note "Flation for $test_class";

does_ok my $class = $model->class_for($test_class),
    'Elastic::Model::Role::Doc';

my $meta = $class->meta;

while (@fields) {
    test_flation( $meta, splice @fields, 0, 2 );
}

note '';
done_testing;

#===================================
sub test_flation {
#===================================
    my ( $meta, $name, $tests ) = @_;
    $name .= '_attr';

    note '';
    note "Flation: $name";

    ok my $attr = $meta->find_attribute_by_name($name), "Has attr: $name";
    return unless $attr;

    if ( ref $tests eq 'ARRAY' ) {
        ok my $de = $tm->find_deflator($attr), "Deflator: $name";
        ok my $in = $tm->find_inflator($attr), "Inflator: $name";
        next unless $de && $in;
        while (@$tests) {
            my ( $test, $one, $two ) = splice @$tests, 0, 3;
            is_deeply $de->($one), $two, "Deflate $name: $test";
            is_deeply $in->($two), $one, "Inflate $name: $test";
        }
    }
    else {
        throws_ok sub { $tm->find_deflator($attr) }, $tests,
            "No deflator: $name";
        throws_ok sub { $tm->find_inflator($attr) }, $tests,
            "No inflator: $name";
    }
    note '';
}

1;

use Test::Most;
use strict;
use warnings;
use ElasticSearchX::Model::Document::Types qw(:all);
use Moose::Util::TypeConstraints;

is_deeply( Location->coerce('12,13'), [ 13, 12 ] );
is_deeply( Location->coerce( { lat => 12, lon => 13 } ), [ 13, 12 ] );
is_deeply( Location->coerce( { latitude => 12, longitude => 13 } ),
    [ 13, 12 ] );

my $dt = find_type_constraint('DateTime');
is( $dt->coerce(10000)->iso8601,                 '1970-01-01T00:00:10' );
is( $dt->coerce('1970-01-01T00:00:20')->iso8601, '1970-01-01T00:00:20' );
is( $dt->coerce('1970-01-01')->iso8601,          '1970-01-01T00:00:00' );

ok( find_type_constraint(TTLField)->check( { enabled => 1, foo => 'bar' } ),
    'test TTLField' );

{

    package MyModel::User;
    use Moose;
    use ElasticSearchX::Model::Document;

    package MyModel::Tweet;
    use Moose;
    use ElasticSearchX::Model::Document;

    package main;
    my $tc = find_type_constraint(Types);

    my $types
        = { user => MyModel::User->meta, tweet => MyModel::Tweet->meta };
    is_deeply( $tc->coerce( [qw(MyModel::User MyModel::Tweet)] ), $types );
    is_deeply(
        $tc->coerce( { user => 'MyModel::User', tweet => 'MyModel::Tweet' } ),
        $types
    );
}

done_testing;

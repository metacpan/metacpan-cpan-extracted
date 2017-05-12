use strict;
use warnings;
use Test::Most;
use Test::MockObject::Extends;
use lib qw(t/lib);
use MyModel;

my $es = Test::MockObject::Extends->new( Search::Elasticsearch->new );

my $model = MyModel->new( es => $es );

my $tests = {
    "0.20.0.RC1" => 0.020000001,
    "0.19.11"    => 0.019011,
    "0.18.1"     => 0.018001,
    "1.1.1"      => 1.001001,
};

while ( my ( $string, $number ) = each %$tests ) {
    $es->mock( info => sub { { version => { number => $string } } } );
    is( $model->es_version, $number, "parse $string as $number" );
}

done_testing;

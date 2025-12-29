use Test::More 0.98;

use strict;
use warnings;

use_ok('Geo::GeoNames');

use utf8;

ok ! eval { Geo::GeoNames->new( ua => undef, username => 'fakename' ); }, 'Bad user-agent should croak: ' . $@;
ok ! eval { Geo::GeoNames->new( ua => {}, username => 'fakename' ); }, 'Bad user-agent should croak: ' . $@;
ok ! eval { Geo::GeoNames->new( ua => IO::Handle->new, username => 'fakename' ); }, 'Bad user-agent should croak: ' . $@;

subtest 'Mojo::UserAgent' => sub {
    SKIP: {
        skip 'Skip tests if Mojo::UserAgent is not installed', 5 unless eval { require Mojo::UserAgent; };
        my $mua = new_ok('Mojo::UserAgent');
        ok Geo::GeoNames->new( ua => $mua, username => 'fakename' ), 'Instantiates fine with proper object';

        skip 'Need $ENV{GEONAMES_USER} to test actual results work with provided Mojo::UserAgent', 3  unless $ENV{GEONAMES_USER};
        my $geo = Geo::GeoNames->new( ua => $mua, username => $ENV{GEONAMES_USER} );
        my $result = $geo->search( 'q' => "Oslo", maxRows => 3, style => "FULL" );
        ok( defined $result              , 'q => Oslo' );
        ok( ref $result eq ref []        , 'result is array ref' );
        ok( exists($result->[0]->{name}) , 'name exists in result' );
    };
};

subtest 'LWP::UserAgent' => sub {
    SKIP: {
        skip 'Skip tests if LWP::UserAgent is not installed', 5 unless eval { require LWP::UserAgent };

        my $lwp = new_ok('LWP::UserAgent');
        ok Geo::GeoNames->new( ua => $lwp, username => 'fakename' ), 'Instantiates fine with proper object';

        skip 'Need $ENV{GEONAMES_USER} to test actual results work with provided LWP::UserAgent', 3 unless $ENV{GEONAMES_USER};
        my $geo = Geo::GeoNames->new( ua => $lwp, username => $ENV{GEONAMES_USER} );

        my $result = $geo->search( 'q' => "Ørebro", maxRows => 3, style => "FULL" );
        ok( defined $result               , 'q => Ørebro' );
        ok( ref $result eq ref []         , 'result is array ref (xml)' );
        is( $result->[0]->{name}, 'Örebro', 'name exists in result (xml)' );

        my $result2 = $geo->search( 'q' => "Ørebro", maxRows => 3, style => "FULL", type => 'json' );
        ok( defined $result2               , 'q => Ørebro' );
        ok( ref $result2 eq ref {}         , 'result is array ref (json)' );
        is( $result2->{geonames}->[0]->{name}, 'Örebro', 'name exists in result (json)' );
    };
};

done_testing;

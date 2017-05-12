#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;


BEGIN { 
    use_ok( 'Geo::Hash::Grid' ) || print "Bail out!\n";
}

diag( "Testing Geo::Hash::Grid $Geo::Hash::Grid::VERSION, Perl $], $^X" );


my $grid = Geo::Hash::Grid->new(
	sw_lat    => 41.956825,
	sw_lon    => -88.088303,
	ne_lat    => 41.962178,
	ne_lon    => -88.077478,
	precision => 7,
);


is( $grid->count, 32, "got correct hash count" );


is_deeply(
	$grid->hashes,
	[
          'dp3qew0',
          'dp3qew1',
          'dp3qew4',
          'dp3qew5',
          'dp3qewh',
          'dp3qewj',
          'dp3qewn',
          'dp3qewp',
          'dp3qew2',
          'dp3qew3',
          'dp3qew6',
          'dp3qew7',
          'dp3qewk',
          'dp3qewm',
          'dp3qewq',
          'dp3qewr',
          'dp3qew8',
          'dp3qew9',
          'dp3qewd',
          'dp3qewe',
          'dp3qews',
          'dp3qewt',
          'dp3qeww',
          'dp3qewx',
          'dp3qewb',
          'dp3qewc',
          'dp3qewf',
          'dp3qewg',
          'dp3qewu',
          'dp3qewv',
          'dp3qewy',
          'dp3qewz'
	], "got correct hash list" );


#  we need to find shortest fraction length
my $shortest_length = 13;
my $origins_got      = $grid->origins;

foreach my $pair ( @$origins_got ) {

    my ( undef, $digits ) = split /\./, $pair->{'lat'};
    $shortest_length = length $digits if length $digits < $shortest_length;
    
    ( undef, $digits ) = split /\./, $pair->{'lon'};
    $shortest_length = length $digits if length $digits < $shortest_length;
    
}

my $origins_expected = [
    {
        'lat' =>  '41.9574737548828',
        'lon' => '-88.0876922607422'
    },
    {
        'lon' => '-88.0863189697266',
        'lat' =>  '41.9574737548828'
    },
    {
        'lat' => '41.9574737548828',
        'lon' => '-88.0849456787109'
    },
    {
        'lon' => '-88.0835723876953',
        'lat' =>  '41.9574737548828'
    },
    {
        'lat' =>  '41.9574737548828',
        'lon' => '-88.0821990966797'
    },
    {
        'lat' =>  '41.9574737548828',
        'lon' => '-88.0808258056641'
    },
    {
        'lon' => '-88.0794525146484',
        'lat' =>  '41.9574737548828'
    },
    {
        'lon' => '-88.0780792236328',
        'lat' =>  '41.9574737548828'
    },
    {
        'lon' => '-88.0876922607422',
        'lat' =>  '41.9588470458984'
    },
    {
        'lon' => '-88.0863189697266',
        'lat' =>  '41.9588470458984'
    },
    {
        'lon' => '-88.0849456787109',
        'lat' =>  '41.9588470458984'
    },
    {
        'lat' =>  '41.9588470458984',
        'lon' => '-88.0835723876953'
    },
    {
        'lat' =>  '41.9588470458984',
        'lon' => '-88.0821990966797'
    },
    {
        'lon' => '-88.0808258056641',
        'lat' =>  '41.9588470458984'
    },
    {
        'lon' => '-88.0794525146484',
        'lat' =>  '41.9588470458984'
    },
    {
        'lat' =>  '41.9588470458984',
        'lon' => '-88.0780792236328'
    },
    {
        'lon' => '-88.0876922607422',
        'lat' =>  '41.9602203369141'
    },
    {
        'lon' => '-88.0863189697266',
        'lat' =>  '41.9602203369141'
    },
    {
        'lon' => '-88.0849456787109',
        'lat' =>  '41.9602203369141'
    },
    {
        'lat' =>  '41.9602203369141',
        'lon' => '-88.0835723876953'
    },
    {
        'lon' => '-88.0821990966797',
        'lat' =>  '41.9602203369141'
    },
    {
        'lon' => '-88.0808258056641',
        'lat' =>  '41.9602203369141'
    },
    {
        'lon' => '-88.0794525146484',
        'lat' =>  '41.9602203369141'
    },
    {
        'lat' =>  '41.9602203369141',
        'lon' => '-88.0780792236328'
    },
    {
        'lat' =>  '41.9615936279297',
        'lon' => '-88.0876922607422'
    },
    {
        'lon' => '-88.0863189697266',
        'lat' =>  '41.9615936279297'
    },
    {
        'lat' =>  '41.9615936279297',
        'lon' => '-88.0849456787109'
    },
    {
        'lon' => '-88.0835723876953',
        'lat' =>  '41.9615936279297'
    },
    {
        'lat' =>  '41.9615936279297',
        'lon' => '-88.0821990966797'
    },
    {
        'lon' => '-88.0808258056641',
        'lat' =>  '41.9615936279297'
    },
    {
        'lon' => '-88.0794525146484',
        'lat' =>  '41.9615936279297'
    },
    {
        'lat' =>  '41.9615936279297',
        'lon' => '-88.0780792236328'
    }
];

$origins_got        = truncate_digits_origins( $origins_got, $shortest_length );
$origins_expected   = truncate_digits_origins( $origins_expected, $shortest_length );



is_deeply(
	$origins_got, $origins_expected, "got correct origins"
);

my $bbox_got = $grid->bboxes->[0];
my $bbox_expected = {
    'ne' => {
        'lat' =>  '41.9581604003906',
        'lon' => '-88.0870056152344'
    },
    'sw' => {
        'lat' =>  '41.956787109375',
        'lon' => '-88.08837890625'
    },
};

$shortest_length = 11;

foreach my $corner ( keys %$bbox_got ) {
    foreach my $element ( keys %{$bbox_got->{$corner}} ) {
        my ( undef, $digits ) = split /\./, $bbox_got->{$corner}->{$element};
        $shortest_length = length $digits if length $digits < $shortest_length;
    }
}

truncate_digits_bbox( $bbox_got, $shortest_length );
truncate_digits_bbox( $bbox_expected, $shortest_length );


is_deeply( $bbox_got, $bbox_expected, "got correct bounding box");


#  test inheritance
ok( $grid->encode( '48.669', '-4.329', 5 ) eq 'gbsuv', "used inherited encode method");



done_testing();




sub truncate_digits_bbox {
    my $data   = shift;
    my $length = shift;
    
    foreach my $corner ( keys %$data ) {
        foreach my $element ( keys %{$data->{$corner}} ) {
            $data->{$corner}->{$element} = sprintf( "%." . $length . "f", $data->{$corner}->{$element} );
        }
    }
    
    return $data;
}

sub truncate_digits_origins {
    my $data   = shift;
    my $length = shift;
    
    foreach my $pair ( @$data ) {
        $pair->{'lat'} = sprintf( "%." . $length . "f", $pair->{'lat'} );
        $pair->{'lon'} = sprintf( "%." . $length . "f", $pair->{'lon'} );
    }
    
    return $data;
}


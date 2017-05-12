#!/usr/bin/env perl
use strict;
use warnings;
use Gearman::XS::Worker;
use Gearman::XS qw(:constants);
use Imager;

my $worker = Gearman::XS::Worker->new;
$worker->add_server( 'localhost', 4730 );

$worker->add_function( "convert_to_jpeg", 0, \&convert_to_jpeg, {} );
$worker->add_function( "convert_to_gif",  0, \&convert_to_gif,  {} );

while (1) {
    my $ret = $worker->work();
    if ( $ret != GEARMAN_SUCCESS ) {
        printf( STDERR "%s\n", $worker->error() );
    }
}

sub convert_to_jpeg {
    my ($job) = @_;
    return _convert( $job->workload, 'jpeg' );
}

sub convert_to_gif {
    my ($job) = @_;
    return _convert( $job->workload, 'gif' );
}

sub _convert {
    my ( $in_data, $format ) = @_;
    my $img = Imager->new();
    my $out_data;
    $img->read( data => $in_data ) or die;
    $img->write( data => \$out_data, type => $format ) or die;
    return $out_data;
}

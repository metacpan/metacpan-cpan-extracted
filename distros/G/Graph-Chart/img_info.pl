#!/usr/bin/perl

use Data::Dumper;
use Image::Info qw(image_info);
use Data::Serializer;

my $obj        = Data::Serializer->new();
my $file = shift;
my $info = image_info( $file );

#print Dumper( $info );

if ( my $error = $info->{ error } )
{
    die "Can't parse image info: $error\n";
}

if ( exists $info->{ data } )
{
    my $txt = $info->{ data };
    my $deser_data = $obj->deserialize( $txt );
    $Data::Dumper::Sortkeys = 1;
    print Dumper( $deser_data );
}
else
{
    print "No PNG tag\n";
}

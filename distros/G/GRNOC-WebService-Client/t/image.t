#!/usr/bin/perl

use Test::More tests => 5;

use strict;
use warnings;

use GRNOC::WebService::Client;
use Image::Magick;
use Data::Dumper;

my $FILENAME = 'image.jpg';

# use the image webservice and set it to use raw output
my $svc = GRNOC::WebService::Client->new( url => 'http://localhost:8529/image.cgi',
                                          raw_output => 1 );

# retrieve the raw image data
my $image = $svc->get_image();

# save it in a temporary file
open(SAVE, ">$FILENAME") or warn($!);
print SAVE $image;
close(SAVE) or warn($!);

# create imagemagick object used to validate image
my $imagick = Image::Magick->new();

# make sure it appears to be a valid jpeg
$imagick->Read($FILENAME);

my $rows = $imagick->Get( 'rows' );
my $columns = $imagick->Get( 'columns' );

ok( $rows == 329, "number of rows" );
ok( $columns == 420, "number of columns" );

# make sure the content type is image/jpeg
like($svc->get_content_type(), '/^image\/jpeg/', "image/jpeg content type");

# issue help and make sure its of type application/json
my $help = $svc->help();
like($svc->get_content_type(), '/^application\/json/', "application/json content type");



# now try to upload it as an attachment
$svc->{'raw_output'} = 0;
$svc->{'usePost'} = 1;
my $res = $svc->put_image(image => {type => 'file',
                                    path => $FILENAME});

ok(defined $res && $res->{'results'}[0]{'success'} eq 1, "upload successful");

#!/usr/bin/perl -w
use strict;

use File::Copy;
use File::Path;
use Labyrinth::DIUtils::ImageMagick;
use Test::More tests => 28;

eval {
    my $di = Labyrinth::DIUtils::ImageMagick->new();
};

like($@,qr/no image specified/,'no file passed');

eval {
    my $di = Labyrinth::DIUtils::ImageMagick->new( 'unknown.jpg' );
};

like($@,qr/no image file found/,'missing file passed');

eval {
    my $example    = 't/samples/testfile.jpg';
    my $sample     = 't/test/sample.jpg';
    my $thumbnail  = 't/test/thumbnail.png';
    my $thumbnail2 = 't/test/thumbnail2.png';
    my $thumbnail3 = 't/test/thumbnail3.png';

    mkdir('t/test');
    copy($example,$sample);

    my $di = Labyrinth::DIUtils::ImageMagick->new( $sample );
    isa_ok($di,'Labyrinth::DIUtils::ImageMagick');
    is($di->{image},$sample);

    is($di->rotate(),undef,'no rotation');
    is($di->rotate(45),1,'45 degrees rotation');
    is($di->rotate(90),1,'90 degrees rotation');
    is($di->rotate(180),1,'180 degrees rotation');
    is($di->rotate(270),1,'270 degrees rotation');

    #my ($width,$height) = $di->{object}->Get('columns', 'rows');
    #diag("$width x $height");

    is($di->reduce(300,300),undef,'no reduction');
    is($di->reduce(200,160),1,'width reduction');
    is($di->reduce(140,200),1,'height reduction');
    is($di->reduce(120,120,90),1,'height reduction with 90% quality');
    is($di->reduce(),1,'default reduction');

    is($di->thumb(),undef,'no thumbnail');
    is($di->thumb($thumbnail),1,'default thumbnail');
    ok(-f $thumbnail);
    is($di->thumb($thumbnail2,120),1,'set thumbnail');
    ok(-f $thumbnail2);

    $di->{object} = undef;
    is($di->rotate(90),undef,'must have an object');
    is($di->reduce(),undef,'must have an object');
    is($di->thumb($thumbnail),undef,'must have an object');
    is($di->_writeimage($thumbnail),undef,'must have an object');
    $di->{image} = undef;
    is($di->rotate(90),undef,'must have an image');
    is($di->reduce(),undef,'must have an image');

    copy($example,$sample);
    $di = Labyrinth::DIUtils::ImageMagick->new( $sample );
    is($di->rotate(90),1,'90 degrees rotation');
    is($di->thumb($thumbnail3,50),1,'set thumbnail');
    ok(-f $thumbnail3);

    rmtree('t/test');
};

diag($@) if($@);

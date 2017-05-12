use strict;
use lib qw( ../lib );
use Test::More;

BEGIN {
    plan (tests => 37);
    use_ok('File::Headerinfo');
}

my @fields = qw(filetype filesize datarate duration width height);
my $r = File::Headerinfo->new;
ok( $r, 'header object constructed' );


PNG: {
    print "\n*** .png tests\n";
    my $png = $r->read('./test/test.png');
    my $expected = {
        'filetype' => 'png',
        'width' => 20,
        'height' => 20,
    };
    
    for ( keys %$expected ) {
        is($png->{$_}, $expected->{$_}, "$_ = " . $png->{$_} || 'undef');
    }
}

JPG: {
    print "\n*** .jpg tests\n";
    my $jpg = File::Headerinfo->read('./test/test.jpg');
    my $expected = {
        'filetype' => 'jpg',
        'width' => 20,
        'height' => 20,
    };
    
    for ( keys %$expected ) {
        is($jpg->{$_}, $expected->{$_}, "$_ = " . $jpg->{$_} || 'undef');
    }
}

SWF: {
    print "\n*** .swf tests\n";
    my $swf = File::Headerinfo->read('./test/test.swf');
    my $expected = {
        'filetype' => 'swf',
        'filesize' => 11558,
        'width' => 468,
        'height' => 60,
        'fps' => 24,
        'duration' => 0.0416666666666667,
    };
    
    for ( keys %$expected ) {
        is($swf->{$_}, $expected->{$_}, "$_ = " . $swf->{$_} || 'undef');
    }
}

WAV: {
    print "\n*** .wav tests\n";
    my $wav = File::Headerinfo->read('./test/test.wav');
    my $expected = {
        'freq' => 8000,
        'duration' => '0.12',
        'filesize' => 1920,
        'datarate' => 16000,
        'filetype' => 'wav',
    };
    
    for ( keys %$expected ) {
        is($wav->{$_}, $expected->{$_}, "$_ = " . $wav->{$_} || 'undef');
    }
}

AVI: {
    print "\n*** .avi tests\n";
    my $avi = File::Headerinfo->read('./test/test.avi');
    my $expected = {
        'datarate' => 1000000,
        'filesize' => '39422',
        'width' => 240,
        'freq' => 22050,
        'height' => 180,
        'fps' => '7.50001875004688',
        'filetype' => 'riff',
        'duration' => '0.399999',
        'vcodec' => 'cvid'
    };
    
    for ( keys %$expected ) {
        is($avi->{$_}, $expected->{$_}, "$_ = " . $avi->{$_} || 'undef');
    }
}

MOV: {
    print "\n*** .mov tests\n";
    my $mov = File::Headerinfo->read('./test/test.mov');
    my $expected = {
        'duration' => '0.35',
        'height' => 120,
        'datarate' => 0,
        'freq' => 16,
        'filetype' => 'moov',
        'width' => 160,
        'vcodec' => 'mp4v',
        'fps' => '8.57142857142857',
        'filesize' => '6930'
    };
    
    for ( keys %$expected ) {
        is($mov->{$_}, $expected->{$_}, "$_ = " . $mov->{$_} || 'undef');
    }
}


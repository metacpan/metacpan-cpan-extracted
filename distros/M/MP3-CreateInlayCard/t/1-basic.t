# Tests for MP3::CreateInlayCard
#
# $Id: 1-basic.t 444 2008-09-04 18:55:10Z davidp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl MP3-CreateInlayCard.t'

# To test comprehensively, there's a set of test MP3 files supplied, so that
# we can check for correct behaviour across a range of sets of MP3s, some
# multi-artist, some multi-album, some multi-artist *and* multi-album.
# Perhaps overkill, but good to be thorough.


use Test::More tests => 17;

BEGIN { use_ok('MP3::CreateInlayCard') };

    

my $template = 'test.tmpl';

for my $tagtype (qw(id3v1 id3v2)) {
    
    diag("Testing with $tagtype tags");
    
    diag("Checking multi-artist, multi-album dir...");
    my $result;
    $result = MP3::CreateInlayCard::create_inlay({ 
        dir => "test-mp3-files/$tagtype/many-artists-many-albums",
        template => $template
    });
    
    
    like($result, qr/album:Compilation/, 
        'many albums interpretted as "Compilation"');
    like($result, qr/artist:Various/,
        'many artists interpretted as "Various"');
    
    diag("Checking multi-artist, single album dir");
    $result = MP3::CreateInlayCard::create_inlay({ 
        dir => "test-mp3-files/$tagtype/many-artists-one-album",
        template => $template
    });
    
    like($result, qr/album:Album1/, 
        'Many artists on one album - album name OK');
    
    diag("Checking one artist, multi-album dir");
    $result = MP3::CreateInlayCard::create_inlay({ 
        dir => "test-mp3-files/$tagtype/one-artist-different-albums",
        template => $template
    });
    
    like($result, qr/artist:Artist1/, 'single-artist dir, artist looks right');
    like($result, qr/album:Compilation/, 
        'single artist many albums, album looks right');
    
    diag("Checking one artist, one album dir");
    $result = MP3::CreateInlayCard::create_inlay({ 
        dir => "test-mp3-files/$tagtype/one-artist-one-album",
        template => $template
    });
    
    like($result, qr/artist:Artist1/, 'one-artist dir - artist looks right');
    like($result, qr/album:Album1/, 'one-album dir - album looks right');
    like($result, qr/Title1:Artist1/, 'Track details look OK');

}
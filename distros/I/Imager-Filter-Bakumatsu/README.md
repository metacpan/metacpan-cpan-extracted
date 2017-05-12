# NAME

Imager::Filter::Bakumatsu - Photo vintage filter

# SYNOPSIS
  

    use Imager;
    use Imager::Filter::Bakumatsu;
    

    my $img = Imager->new;
    $img->read(file => 'photo.jpg') or die $img->errstr;
    

    $img->filter(type => 'bakumatsu'); # photo is made old.
    

    $img->write(file => 'photo-bakumatsu.jpg')
        or die $img->errstr;

# DESCRIPTION

Bakumatsu (幕末) is a name of the 19th century middle in the history
of Japan. ([http://en.wikipedia.org/wiki/Bakumatsu](http://en.wikipedia.org/wiki/Bakumatsu))
This filter makes the photograph old likes taken in the Bakumatsu era.

# FILTER

## bakumatsu

    $img->filter(type => 'bakumatsu');

- overlay\_image

        $img->filter(type => 'bakumatsu', overlay_image => '/foo/image.png');

    Overlay image to cover (it should have alpha channel). 
    default is: dist/share/BakumatsuTexture.png

# AUTHOR

Naoki Tomita <tomita@cpan.org>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

Original idea: [http://labs.wanokoto.jp/olds](http://labs.wanokoto.jp/olds),
[http://d.hatena.ne.jp/nitoyon/20080407/bakumatsu\_hack](http://d.hatena.ne.jp/nitoyon/20080407/bakumatsu\_hack)

Test Page: [http://bakumatsu.koneta.org/](http://bakumatsu.koneta.org/)

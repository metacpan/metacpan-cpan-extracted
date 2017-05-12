package Imager::Filter::Bakumatsu;
use strict;
use warnings;
our $VERSION = '0.05';

use Imager;
use File::ShareDir 'dist_file';

my $texture = dist_file('Imager-Filter-Bakumatsu', 'BakumatsuTexture.png');

Imager->register_filter(
    type     => 'bakumatsu',
    callsub  => \&bakumatsu,
    callseq  => [],
    defaults => {
        overlay_image => $texture,
    },
);

sub bakumatsu {
    my %opt  = @_;
    my $self = delete $opt{imager};
    my $work = $self;
    
    $work = $work->convert(
        matrix => [
            [ 1.7,   0,   0, 0 ],
            [   0, 1.7,   0, 0 ],
            [   0,   0, 1.7, 0 ],
        ],
    );
    
    $work->filter(
        type      => 'contrast',
        intensity => 1.2,
    );
    
    $work->filter(
        type => 'autolevels',
        lsat => 0.3,
        usat => 0.3,
    );
    
    $work = $work->convert(
        matrix => [
            [ 1 / 4, 1 / 2, 1 / 8, 0 ],
            [ 1 / 4, 1 / 2, 1 / 8, 0 ],
            [ 1 / 4, 1 / 2, 1 / 8, 0 ],
        ],
    );
    
    $work->rubthrough(
        src => do {
            my $overlay = Imager->new;
               $overlay->read(file => $opt{overlay_image})
                or die $overlay->errstr;
            
            $overlay = $overlay->scale(
                xpixels => $work->getwidth,
                ypixels => $work->getheight,
                type    => 'nonprop'
            );
        },
    ) or die $work->errstr;
    
    $self->{IMG} = delete $work->{IMG};
}

1;
__END__

=encoding utf-8

=head1 NAME

Imager::Filter::Bakumatsu - Photo vintage filter

=head1 SYNOPSIS
  
  use Imager;
  use Imager::Filter::Bakumatsu;
  
  my $img = Imager->new;
  $img->read(file => 'photo.jpg') or die $img->errstr;
  
  $img->filter(type => 'bakumatsu'); # photo is made old.
  
  $img->write(file => 'photo-bakumatsu.jpg')
      or die $img->errstr;

=head1 DESCRIPTION

Bakumatsu (幕末) is a name of the 19th century middle in the history
of Japan. (L<http://en.wikipedia.org/wiki/Bakumatsu>)
This filter makes the photograph old likes taken in the Bakumatsu era.

=head1 FILTER

=head2 bakumatsu

  $img->filter(type => 'bakumatsu');

=over 4

=item overlay_image

  $img->filter(type => 'bakumatsu', overlay_image => '/foo/image.png');

Overlay image to cover (it should have alpha channel). 
default is: dist/share/BakumatsuTexture.png

=back

=head1 AUTHOR

Naoki Tomita E<lt>tomita@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

Original idea: L<http://labs.wanokoto.jp/olds>,
L<http://d.hatena.ne.jp/nitoyon/20080407/bakumatsu_hack>

Test Page: L<http://bakumatsu.koneta.org/>

=for stopwords 19th bakumatsu

=cut

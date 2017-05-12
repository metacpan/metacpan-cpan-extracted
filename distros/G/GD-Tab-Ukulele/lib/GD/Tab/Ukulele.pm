package GD::Tab::Ukulele;
use strict;
use warnings;
use Carp;
use GD;
use base qw(Class::Accessor::Fast);
use List::Util qw(max);

__PACKAGE__->mk_accessors(qw(bgcolor color interlaced));

our $VERSION = '0.01';
my @lines = (
    [1,15,41,15],
    [1,21,41,21],
    [1,27,41,27],
    [1,33,41,33],
    [0,15,0,33],
    [2,15,2,33],
    [10,15,10,33],
    [18,15,18,33],
    [26,15,26,33],
    [34,15,34,33],
);

my %chord_lists = (
    'C'            => [3, 0, 0, 0],
    'Cm'           => [3, 3, 3, 0],
    'C7'           => [1, 0, 0, 0],
    'CM7'          => [2, 0, 0, 0],
    'Cm7'          => [3, 3, 3, 3],
    'Cdim'         => [3, 2, 3, 2],
    'Cm7(b5)'      => [3, 2, 3, 3],
    'Caug'         => [3, 0, 0, 1],
    'Csus4'        => [3, 3, 5, 5],
    'C6'           => [0, 0, 0, 0],
    'C7(9)'        => [1, 0, 2, 0],
    'CM7(9)'       => [2, 0, 2, 0],
    'CmM7'         => [3, 3, 3, 4],
    'Cadd9'        => [3, 0, 2, 0],
    'C#'           => [4, 1, 1, 1],
    'C#m'          => [4, 4, 4, 1],
    'C#7'          => [2, 1, 1, 1],
    'C#M7'         => [3, 1, 1, 1],
    'C#m7'         => [2, 0, 1, 1],
    'C#dim'        => [1, 0, 1, 0],
    'C#m7(b5)'     => [3, 2, 3, 3],
    'C#aug'        => [0, 1, 1, 2],
    'C#sus4'       => [2, 2, 1, 1],
    'C#6'          => [1, 1, 1, 1],
    'C#7(9)'       => [2, 1, 3, 1],
    'C#M7(9)'      => [3, 1, 3, 1],
    'C#mM7'        => [3, 0, 1, 1],
    'C#add9'       => [4, 1, 3, 1],
    'Db'           => [4, 1, 1, 1],
    'Dbm'          => [4, 4, 4, 1],
    'Db7'          => [2, 1, 1, 1],
    'DbM7'         => [3, 1, 1, 1],
    'Dbm7'         => [2, 0, 1, 1],
    'Dbdim'        => [1, 0, 1, 0],
    'Dbm7(b5)'     => [3, 2, 3, 3],
    'Dbaug'        => [0, 1, 1, 2],
    'Dbsus4'       => [2, 2, 1, 1],
    'Db6'          => [1, 1, 1, 1],
    'Db7(9)'       => [2, 1, 3, 1],
    'DbM7(9)'      => [3, 1, 3, 1],
    'DbmM7'        => [3, 0, 1, 1],
    'Dbadd9'       => [4, 1, 3, 1],
    'D'            => [0, 2, 2, 2],
    'Dm'           => [0, 1, 2, 2],
    'D7'           => [3, 2, 2, 2],
    'DM7'          => [4, 2, 2, 2],
    'Dm7'          => [3, 1, 2, 2],
    'Ddim'         => [2, 1, 2, 1],
    'Dm7(b5)'      => [3, 1, 2, 1],
    'Daug'         => [1, 2, 2, 3],
    'Dsus4'        => [0, 3, 2, 2],
    'D6'           => [2, 2, 2, 2],
    'D7(9)'        => [3, 2, 4, 2],
    'DM7(9)'       => [4, 2, 4, 2],
    'DmM7'         => [4, 1, 2, 2],
    'Dadd9'        => [5, 2, 4, 2],
    'D#'           => [1, 3, 3, 0],
    'D#m'          => [1, 2, 3, 3],
    'D#7'          => [4, 3, 3, 3],
    'D#M7'         => [5, 3, 3, 3],
    'D#m7'         => [4, 2, 3, 3],
    'D#dim'        => [3, 2, 3, 2],
    'D#m7(b5)'     => [4, 2, 3, 2],
    'D#aug'        => [2, 3, 3, 0],
    'D#sus4'       => [1, 4, 3, 3],
    'D#6'          => [4, 4, 4, 4],
    'D#7(9)'       => [1, 1, 1, 0],
    'D#M7(9)'      => [1, 1, 2, 0],
    'D#mM7'        => [5, 2, 3, 3],
    'D#add9'       => [1, 1, 3, 0],
    'Eb'           => [1, 3, 3, 0],
    'Ebm'          => [1, 2, 3, 3],
    'Eb7'          => [4, 3, 3, 3],
    'EbM7'         => [5, 3, 3, 3],
    'Ebm7'         => [4, 2, 3, 3],
    'Ebdim'        => [3, 2, 3, 2],
    'Ebm7(b5)'     => [4, 2, 3, 2],
    'Ebaug'        => [2, 3, 3, 0],
    'Ebsus4'       => [1, 4, 3, 3],
    'Eb6'          => [4, 4, 4, 4],
    'Eb7(9)'       => [1, 1, 1, 0],
    'EbM7(9)'      => [1, 1, 2, 0],
    'EbmM7'        => [5, 2, 3, 3],
    'Ebadd9'       => [1, 1, 3, 0],
    'E'            => [2, 4, 4, 4],
    'Em'           => [2, 3, 4, 0],
    'E7'           => [2, 0, 2, 1],
    'EM7'          => [2, 0, 3, 1],
    'Em7'          => [2, 0, 2, 0],
    'Edim'         => [1, 0, 1, 0],
    'Em7(b5)'      => [1, 0, 2, 0],
    'Eaug'         => [3, 0, 0, 1],
    'Esus4'        => [2, 5, 4, 4],
    'E6'           => [2, 0, 1, 1],
    'E7(9)'        => [2, 2, 2, 1],
    'EM7(9)'       => [2, 2, 3, 1],
    'EmM7'         => [2, 0, 3, 0],
    'Eadd9'        => [2, 2, 4, 1],
    'F'            => [0, 1, 0, 2],
    'Fm'           => [3, 1, 0, 1],
    'F7'           => [3, 1, 3, 2],
    'FM7'          => [0, 0, 5, 5],
    'Fm7'          => [3, 1, 3, 1],
    'Fdim'         => [2, 1, 2, 1],
    'Fm7(b5)'      => [2, 1, 3, 1],
    'Faug'         => [0, 1, 1, 2],
    'Fsus4'        => [1, 1, 0, 3],
    'F6'           => [3, 1, 2, 2],
    'F7(9)'        => [3, 3, 3, 2],
    'FM7(9)'       => [0, 0, 0, 0],
    'FmM7'         => [3, 1, 4, 1],
    'Fadd9'        => [0, 1, 0, 0],
    'F#'           => [1, 2, 1, 3],
    'F#m'          => [0, 2, 1, 2],
    'F#7'          => [4, 2, 4, 3],
    'F#M7'         => [4, 2, 5, 3],
    'F#m7'         => [4, 2, 4, 2],
    'F#dim'        => [3, 2, 3, 2],
    'F#m7(b5)'     => [3, 2, 4, 2],
    'F#aug'        => [1, 2, 2, 3],
    'F#sus4'       => [4, 2, 4, 4],
    'F#6'          => [4, 2, 3, 3],
    'F#7(9)'       => [4, 4, 4, 3],
    'F#M7(9)'      => [1, 1, 1, 1],
    'F#mM7'        => [4, 2, 5, 2],
    'F#add9'       => [1, 2, 1, 1],
    'Gb'           => [1, 2, 1, 3],
    'Gbm'          => [0, 2, 1, 2],
    'Gb7'          => [4, 2, 4, 3],
    'GbM7'         => [4, 2, 5, 3],
    'Gbm7'         => [4, 2, 4, 2],
    'Gbdim'        => [3, 2, 3, 2],
    'Gbm7(b5)'     => [3, 2, 4, 2],
    'Gbaug'        => [1, 2, 2, 3],
    'Gbsus4'       => [4, 2, 4, 4],
    'Gb6'          => [4, 2, 3, 3],
    'Gb7(9)'       => [4, 4, 4, 3],
    'GbM7(9)'      => [1, 1, 1, 1],
    'GbmM7'        => [4, 2, 5, 2],
    'Gbadd9'       => [1, 2, 1, 1],
    'G'            => [2, 3, 2, 0],
    'Gm'           => [1, 3, 2, 0],
    'G7'           => [2, 1, 2, 0],
    'GM7'          => [2, 2, 2, 0],
    'Gm7'          => [1, 1, 2, 0],
    'Gdim'         => [1, 0, 1, 0],
    'Gm7(b5)'      => [1, 1, 1, 0],
    'Gaug'         => [2, 3, 3, 0],
    'Gsus4'        => [3, 3, 2, 0],
    'G6'           => [2, 0, 2, 0],
    'G7(9)'        => [2, 1, 2, 2],
    'GM7(9)'       => [2, 2, 2, 2],
    'GmM7'         => [5, 3, 6, 3],
    'Gadd9'        => [2, 3, 2, 2],
    'G#'           => [3, 4, 3, 5],
    'G#m'          => [2, 4, 3, 1],
    'G#7'          => [3, 2, 3, 1],
    'G#M7'         => [3, 3, 3, 1],
    'G#m7'         => [2, 2, 3, 1],
    'G#dim'        => [2, 1, 2, 1],
    'G#m7(b5)'     => [2, 2, 2, 1],
    'G#aug'        => [3, 0, 0, 1],
    'G#sus4'       => [4, 4, 3, 1],
    'G#6'          => [3, 1, 3, 1],
    'G#7(9)'       => [3, 2, 3, 3],
    'G#M7(9)'      => [3, 3, 3, 3],
    'G#mM7'        => [6, 4, 7, 4],
    'G#add9'       => [3, 4, 3, 3],
    'Ab'           => [3, 4, 3, 5],
    'Abm'          => [2, 4, 3, 1],
    'Ab7'          => [3, 2, 3, 1],
    'AbM7'         => [3, 3, 3, 1],
    'Abm7'         => [2, 2, 3, 1],
    'Abdim'        => [2, 1, 2, 1],
    'Abm7(b5)'     => [2, 2, 2, 1],
    'Abaug'        => [3, 0, 0, 1],
    'Absus4'       => [4, 4, 3, 1],
    'Ab6'          => [3, 1, 3, 1],
    'Ab7(9)'       => [3, 2, 3, 3],
    'AbM7(9)'      => [3, 3, 3, 3],
    'AbmM7'        => [6, 4, 7, 4],
    'Abadd9'       => [3, 4, 3, 3],
    'A'            => [0, 0, 1, 2],
    'Am'           => [0, 0, 0, 2],
    'A7'           => [0, 0, 1, 0],
    'AM7'          => [0, 0, 1, 1],
    'Am7'          => [0, 0, 0, 0],
    'Adim'         => [3, 2, 3, 2],
    'Am7(b5)'      => [3, 3, 3, 2],
    'Aaug'         => [0, 1, 1, 2],
    'Asus4'        => [0, 0, 2, 2],
    'A6'           => [4, 2, 4, 2],
    'A7(9)'        => [2, 3, 1, 2],
    'AM7(9)'       => [2, 4, 1, 2],
    'AmM7'         => [0, 0, 0, 1],
    'Aadd9'        => [2, 0, 1, 2],
    'A#'           => [1, 1, 2, 3],
    'A#m'          => [1, 1, 1, 3],
    'A#7'          => [1, 1, 2, 1],
    'A#M7'         => [0, 1, 2, 3],
    'A#m7'         => [1, 1, 1, 1],
    'A#dim'        => [1, 0, 1, 0],
    'A#m7(b5)'     => [1, 0, 1, 1],
    'A#aug'        => [1, 2, 2, 3],
    'A#sus4'       => [1, 1, 3, 3],
    'A#6'          => [1, 1, 2, 0],
    'A#7(9)'       => [3, 4, 2, 3],
    'A#M7(9)'      => [5, 5, 5, 5],
    'A#mM7'        => [1, 1, 1, 2],
    'A#add9'       => [3, 1, 2, 3],
    'Bb'           => [1, 1, 2, 3],
    'Bbm'          => [1, 1, 1, 3],
    'Bb7'          => [1, 1, 2, 1],
    'BbM7'         => [0, 1, 2, 3],
    'Bbm7'         => [1, 1, 1, 1],
    'Bbdim'        => [1, 0, 1, 0],
    'Bbm7(b5)'     => [1, 0, 1, 1],
    'Bbaug'        => [1, 2, 2, 3],
    'Bbsus4'       => [1, 1, 3, 3],
    'Bb6'          => [1, 1, 2, 0],
    'Bb7(9)'       => [3, 4, 2, 3],
    'BbM7(9)'      => [5, 5, 5, 5],
    'BbmM7'        => [1, 1, 1, 2],
    'Bbadd9'       => [3, 1, 2, 3],
    'B'            => [2, 2, 3, 4],
    'Bm'           => [2, 2, 2, 4],
    'B7'           => [2, 2, 3, 2],
    'BM7'          => [1, 2, 3, 4],
    'Bm7'          => [2, 2, 2, 2],
    'Bdim'         => [2, 1, 2, 1],
    'Bm7(b5)'      => [2, 1, 2, 2],
    'Baug'         => [2, 3, 3, 4],
    'Bsus4'        => [2, 2, 4, 4],
    'B6'           => [2, 2, 3, 1],
    'B7(9)'        => [4, 2, 3, 2],
    'BM7(9)'       => [4, 1, 3, 3],
    'BmM7'         => [2, 2, 2, 3],
    'Badd9'        => [4, 2, 3, 4],
);

sub new {
    my $class = shift;
    bless {
        bgcolor => [255, 255, 255],
        color => [0, 0, 0],
        interlaced => 'true',
    }, $class;
}

sub chord {
    my ($self, $chord) = @_;
    return $self->generate($chord, $self->get_flets($chord));
}

sub get_flets {
    my ($self, $chord) = @_;
    return ($chord_lists{$chord} or croak("undefined chord $chord"));
}

sub generate {
    my ($self, $chord, $flets) = @_;
    my @flets = @$flets;

    my $im = GD::Image->new(48, 44);
    my $bgcolor = $im->colorAllocate(@{$self->bgcolor});
    my $color = $im->colorAllocate(@{$self->color});

    if ($self->interlaced) {
        $im->transparent($bgcolor);
        $im->interlaced('true');
    }

    $self->_draw_line($im, $color);

    my $flet_max = max(@flets);

    if ($flet_max > 5) {
        $im->filledRectangle(0, 15, 2, 33, $bgcolor);
        my $flet_num = $flet_max - 5;

        $_ = $_ - $flet_num for @flets;

        for my $n (0..4) {
            $im->string(GD::Font->Tiny, 9 * $n, 35, $flet_num + 1, $color);
            $flet_num++;
        }
    }

    my $i = 0;
    for my $flet (@flets) {
      $im->filledRectangle(
          5  + 8 * ($flet - 1),
          14 + 6 * $i,
          7  + 8 * ($flet - 1),
          16 + 6 * $i, $color
      ) if ( $flet > 0 );
      $i++;
    }

    $im->string(GD::Font->Small, 0, 0, $chord, $color);

    return $im;
}

sub all_chords {
    return [keys(%chord_lists)];
}

sub _draw_line {
    my ($self, $im, $color) = @_;
    for my $line (@lines) {
        $im->line(@$line, $color);
    }
    return $im;
}

1;


__END__

=head1 NAME

GD::Tab::Ukulele - Ukulele tab image generator.


=head1 VERSION

This document describes GD::Tab::Ukulele version 0.0.1


=head1 SYNOPSIS

    use GD::Tab::Ukulele;
    my $uk = GD::Tab::Ukulele->new;
 
    # print png image
    print $uk->chord('D#sus4')->png;

    # get GD::Image instance
    my $im = $uk->chord('C');
    print $im->png;

    # other tab generate
    $uk->generate('D7',[0,2,0,2])->png;

    # set color
    $uk->color(255, 0, 0);

    # set background-color and no interlace
    $uk->bgcolor(200, 200, 200);
    $uk->interlaced(0);

    # all tabs image save to file.
    use IO::File;
    for my $chord (@{$uk->all_chords}) {
        (my $filename = $chord) =~ s/M/Maj/; # for case-insensitive filesystem
        my $file = IO::File->new("images/$filename.png", 'w');
        $file->print($uk->chord($chord)->png);
    }


=head1 DESCRIPTION

This modules is generate ukulele tab.

=head1 AUTHOR

Yuichi Tateno  C<< <hotchpotch@gmail.com> >>

=head1 SEE ALSO

L<GD>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Yuichi Tateno C<< <hotchpotch@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


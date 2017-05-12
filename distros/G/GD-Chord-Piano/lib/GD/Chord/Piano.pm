package GD::Chord::Piano;

use warnings;
use strict;
use Carp qw( croak );

use GD;

use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(
    qw(bgcolor color pcolor tcolor interlaced)
);

our $VERSION = '0.061';

my $base_chord_list = {
    'base'     => '0,4,7',
    '-5'       => '0,4,6',
    '6'        => '0,4,7,9',
    '6(9)'     => '0,4,7,9,14',         '69'       => '0,4,7,9,14',
    'M7'       => '0,4,7,11',
    'M7(9)'    => '0,4,7,11,14',        'M79'       => '0,4,7,11,14',
    'M9'       => '0,4,7,11,14',
    'M11'      => '0,4,7,11,14,17',
    'M13'      => '0,4,7,11,14,17,21',
    '7'        => '0,4,7,10',
    '7(b5)'    => '0,4,6,10',           '7b5'      => '0,4,6,10',
    '7(-5)'    => '0,4,6,10',           '7-5'      => '0,4,6,10',
    '7(b9)'    => '0,4,7,10,13',        '7b9'      => '0,4,7,10,13',
    '7(-9)'    => '0,4,7,10,13',        '7-9'      => '0,4,7,10,13',
    '-9'       => '0,4,7,10,13',
    '-9(#5)'   => '0,4,8,10,13',        '-9#5'     => '0,4,8,10,13',
    '7(b9,13)' => '0,4,7,10,13,21',     '7(-9,13)' => '0,4,7,10,13,21',
    '7(9,13)'  => '0,4,7,10,14,21',
    '7(#9)'    => '0,4,7,10,15',        '7#9'      => '0,4,7,10,15',
    '7(#11)'   => '0,4,7,10,15,18',     '7#11'     => '0,4,7,10,15,18',
    '7(#13)'   => '0,4,10,21',          '7#13'     => '0,4,10,21',
    '9'        => '0,4,7,10,14',
    '9(b5)'    => '0,4,6,10,14',        '9b5'      => '0,4,6,10,14',
    '9(-5)'    => '0,4,6,10,14',        '9-5'      => '0,4,6,10,14',
    '11'       => '0,4,7,10,14,17',
    '13'       => '0,4,7,10,14,17,21',
    'm'        => '0,3,7',
    'm6'       => '0,3,7,9',
    'm6(9)'    => '0,3,7,9,14',          'm69'     => '0,3,7,9,14',
    'mM7'      => '0,3,7,11',
    'm7'       => '0,3,7,10',
    'm7(b5)'   => '0,3,6,10',            'm7b5'    => '0,3,6,10',
    'm7(-5)'   => '0,3,6,10',            'm7-5'    => '0,3,6,10',
    'm7(9)'    => '0,3,7,10,14',         'm79'     => '0,3,7,10,14',
    'm9'       => '0,3,7,10,14',
    'm7(9,11)' => '0,3,7,10,14,17',
    'm11'      => '0,3,7,10,14,17',
    'm13'      => '0,3,7,10,14,17,21',
    'dim'      => '0,3,6',
    'dim7'     => '0,3,6,9',
    'aug'      => '0,4,8',
    'aug7'     => '0,4,8,10',
    'augM7'    => '0,4,8,11',
    'aug9'     => '0,4,8,10,14',
    'sus4'     => '0,5,7',
    '7sus4'    => '0,5,7,10',
    'add2'     => '0,2,4,7',
    'add4'     => '0,4,5,7',
    'add9'     => '0,4,7,14',
};

my $scalic_value = {
    'C'  => 0,
    'C#' => 1, 'Db' => 1,
    'D'  => 2,
    'D#' => 3, 'Eb' => 3,
    'E'  => 4,
    'E#' => 5, 'Fb' => 4, # joke!
    'F'  => 5,
    'F#' => 6, 'Gb' => 6,
    'G'  => 7,
    'G#' => 8, 'Ab' => 8,
    'A'  => 9,
    'A#' => 10, 'Bb' => 10,
    'B'  => 11,
    'Cb' => 11, 'B#' => 0, # joke!
};

my $black_keys;
for my $black_key (qw(1 3 6 8 10 13 15 18 20 22)){
    $black_keys->{$black_key} = 1;
}

sub new {
    my $class = shift;
    bless {
        bgcolor    => [255,255,255],
        color      => [0,0,0],
        pcolor     => [255,0,0],
        tcolor     => [0,0,0],
        interlaced => 'true',
    }, $class;
}

sub chord {
    my ($self, $chord_name) = @_;
    return $self->generate($chord_name, $self->_get_keys($chord_name));
}

sub gen {
    my ($self, $chord_name, @keys) = @_;
    return $self->generate($chord_name, @keys);
}
sub generate {
    my ($self, $chord_name, @keys) = @_;
    my $im = $self->_draw_keyboard;
    my $pcolor  = $im->colorAllocate(@{$self->pcolor});
    my $tcolor   = $im->colorAllocate(@{$self->color});
    my $x = 3;
    for my $key (0..23){
        my $play = 0;
        for my $i (@keys){
            $play = 1 if $i == $key;
        }
        if($play){
            my ($color, $y);
            $y = $black_keys->{$key} || 0;
            $im->filledRectangle(@{[$x, 24-$y*12, $x+3, 27-$y*12]}, $pcolor);
        }
        if($black_keys->{$key} and !$black_keys->{$key+1}){
            $x += 4;
        }elsif(!$black_keys->{$key} and $black_keys->{$key+1}){
            $x += 5;
        }else{
            $x += 9;
        }
    }
    $im->string(GD::Font->Small, 3, 31, $chord_name, $tcolor);
    return $im;
}

sub all_chords {
    my $self = shift;
    return [keys %{$base_chord_list}];
}

sub _get_keys {
    my ($self, $chord_name) = @_;
    croak "no chord" unless $chord_name;
    my ($tonic, $kind) = ($chord_name =~ /([A-G][b#]?)(.+)?/);
    $kind = 'base' unless $kind;
    croak "undefined chord $chord_name" unless defined $tonic;
	my $scalic = $scalic_value->{$tonic};
    croak "undefined kind of chord $chord_name ($kind)" unless defined $base_chord_list->{$kind};
    my @keys;
    for my $scale ( split /\,/, $base_chord_list->{$kind} ){
        my $tone = $scale + $scalic;
        $tone = int($tone % 24) + 12 if $tone > 23;
        push @keys, $tone;
    }
    return @keys;
}

sub _draw_keyboard {
    my $self = shift;

    my $im = GD::Image->new(127,43);
    my $bgcolor = $im->colorAllocate(@{$self->bgcolor});
    my $color   = $im->colorAllocate(@{$self->color});

    if($self->interlaced){
        $im->transparent($bgcolor);
        $im->interlaced('true');
    }
    for my $k (0..13){
        $im->rectangle(@{[$k*9, 0, 9+$k*9, 30]}, $color);
    }
    for my $k (0..12){
        next if $k == 2 or $k == 6 or $k == 9;
        $im->filledRectangle(@{[7+$k*9, 0, 12+$k*9, 17]}, $color);
    }
    return $im;
}

1;

__END__

=head1 NAME

GD::Chord::Piano - Generate Chord Table of Piano


=head1 SYNOPSIS

    use GD::Chord::Piano;

    my $im = GD::Chord::Piano->new;

    print $im->chord('Csus4')->png;

    print $im->generate('Bb/A', (9,14,17,22) )->png;


=head1 METHOD

=over

=item new(I<$arg>)

constructor

=item chord(I<$chord_name>)

put chord table of $chord_name

=item generate(I<$chord_name>, I<@keys>)

generate chord table of $chord_name by @keys

=item gen(I<$chord_name>, I<@keys>)

alias method of generate

=item all_chords

list all kind of chord

=back


=head1 SEE ALSO

GD::Tab::Uklele GD::Tab::Guitar Text::Chord::Piano


=head1 AUTHOR

Copyright (c) 2008, Dai Okabayashi C<< <bayashi@cpan.org> >>

Thanks to Yuichi Tateno, Koichi Taniguchi.


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

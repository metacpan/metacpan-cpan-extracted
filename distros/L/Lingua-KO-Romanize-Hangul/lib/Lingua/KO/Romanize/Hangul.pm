=head1 NAME

Lingua::KO::Romanize::Hangul - Romanization of Korean language

=head1 SYNOPSIS

    use Lingua::KO::Romanize::Hangul;

    my $conv = Lingua::KO::Romanize::Hangul->new();
    my $roman = $conv->char( $hangul );
    printf( "<ruby><rb>%s</rb><rt>%s</rt></ruby>", $hangul, $roman );

    my @array = $conv->string( $string );
    foreach my $pair ( @array ) {
        my( $raw, $ruby ) = @$pair;
        if ( defined $ruby ) {
            printf( "<ruby><rb>%s</rb><rt>%s</rt></ruby>", $raw, $ruby );
        } else {
            print $raw;
        }
    }

=head1 DESCRIPTION

Hangul is phonemic characters of the Korean language.
This module follows the C<Revised Romanization of Korean>
which was released on July 7, 2000
as the official romanization system in South Korea.

=head2 $conv = Lingua::KO::Romanize::Hangul->new();

This constructer methods returns a new object.

=head2 $roman = $conv->char( $hangul );

This method returns romanized letters of a Hangul character.
It returns undef when $hanji is not a valid Hangul character.
The argument's encoding must be UTF-8.

=head2 $roman = $conv->chars( $string );

This method returns romanized letters of Hangul characters.

=head2 @array = $conv->string( $string );

This method returns a array of referenced arrays
which are pairs of a Hangul chacater and its romanized letters.

    $array[0]           # first Korean character's pair (array)
    $array[1][0]        # secound Korean character itself
    $array[1][1]        # its romanized letters

=head1 UTF-8 FLAG

This module treats utf8 flag transparently.

=head1 SEE ALSO

L<Lingua::JA::Romanize::Japanese> for Japanese

L<Lingua::ZH::Romanize::Pinyin> for Chinese

http://www.korean.go.kr/06_new/rule/rule06.jsp

http://www.kawa.net/works/perl/romanize/romanize-e.html

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1998-2008 Yusuke Kawasaki. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
# ----------------------------------------------------------------
package Lingua::KO::Romanize::Hangul;
use strict;
use vars qw( $VERSION );
$VERSION = "0.20";
my $PERL581 = 1 if ( $] >= 5.008001 );

my $INITIAL_LETTER = [map {$_ eq '-' ? '' : $_} qw(
    g   kk  n   d   tt  r   m   b   pp  s   ss  -   j   jj
    ch  k   t   p   h
)];
my $PEAK_LETTER = [map {$_ eq '-' ? '' : $_} qw(
    a   ae  ya  yae eo  e   yeo ye  o   wa  wae oe  yo  u
    wo  we  wi  yu  eu  ui  i
)];
my $FINAL_LETTER = [map {$_ eq '-' ? '' : $_} qw(
    -   g   kk  ks  n   nj  nh  d   r   lg  lm  lb  ls  lt
    lp  lh  m   b   ps  s   ss  ng  j   c   k   t   p   h
)];
# my $FINAL_LETTER = [map {$_ eq '-' ? '' : $_} qw(
#     -   g   kk  ks  n   nj  nh  d   r   rg  rm  rb  rs  rt
#     rp  rh  m   b   bs  s   ss  ng  j   c   k   t   p   h
# )];

# ----------------------------------------------------------------
sub new {
    my $package = shift;
    my $self = {@_};
    bless $self, $package;
    $self;
}

sub char {
    my $self = shift;
    return $self->_char(@_) unless $PERL581;
    my $char = shift;
    my $utf8 = utf8::is_utf8( $char );
    utf8::encode( $char ) if $utf8;
    $char = $self->_char( $char );
    utf8::decode( $char ) if $utf8;
    $char;
}

sub _char {
    my $self = shift;
    my $char = shift;
    my( $c1, $c2, $c3, $c4 ) = unpack("C*",$char);
    return if ( ! defined $c3 || defined $c4 );
    my $ucs2 = (($c1 & 0x0F)<<12) | (($c2 & 0x3F)<<6) | ($c3 & 0x3F);
    return if ( $ucs2 < 0xAC00 );
    return if ( $ucs2 > 0xD7A3 );
    my $han = $ucs2 - 0xAC00;
    my $init = int( $han / 21 / 28 );
    my $peak = int( $han / 28 ) % 21;
    my $fin  = $han % 28;
    join( "", $INITIAL_LETTER->[$init], $PEAK_LETTER->[$peak], $FINAL_LETTER->[$fin] );
}

sub chars {
    my $self = shift;
    my @array = $self->string( shift );
    join( " ", map {$#$_>0 ? $_->[1] : $_->[0]} @array );
}

sub string {
    my $self = shift;
    return $self->_string(@_) unless $PERL581;
    my $char = shift;
    my $flag = utf8::is_utf8( $char );
    utf8::encode( $char ) if $flag;
    my @array = $self->_string( $char );
    if ( $flag ) {
        foreach my $pair ( @array ) {
            utf8::decode( $pair->[0] ) if defined $pair->[0];
            utf8::decode( $pair->[1] ) if defined $pair->[1];
        }
    }
    @array;
}

#   [UCS-2] AC00-D7A3
#   [UTF-8] EAB080-ED9EA3
#   EA-ED are appeared only as Hangul's first character.

sub _string {
    my $self = shift;
    my $src = shift;
    my $array = [];
    while ( $src =~ /([\xEA-\xED][\x80-\xBF]{2})|([^\xEA-\xED]+)/sg ) {
        if ( defined $1 ) {
            my $pair = [ $1 ];
            my $roman = $self->char( $1 );
            $pair->[1] = $roman if defined $roman;
            push( @$array, $pair );
        } else {
            push( @$array, [ $2 ] );
        }
    }

    for ( my $i = 0 ; $i < $#$array ; $i++ ) {
        next if ( scalar @{ $array->[$i] } < 2 );
        next if ( scalar @{ $array->[ $i + 1 ] } < 2 );
        my $this = $array->[$i]->[1];
        my $next = $array->[ $i + 1 ]->[1];
        my $novowel = 1 unless ( $next =~ /^[aeouiwy]/ );

        if ( $this =~ /(tt|pp|jj)$/ && $novowel ) {
            $array->[$i]->[1] =~ s/(tt|pp|jj)$//;
        }
        elsif ( $this =~ /([^n]g|kk)$/ && $novowel ) {
            $array->[$i]->[1] =~ s/(g|kk)$/k/;
        }
        elsif ( $this =~ /(d|j|ch|s?s)$/ && $novowel ) {
            $array->[$i]->[1] =~ s/(d|j|ch|s?s)$/t/;
        }
        elsif ( $this =~ /(b)$/ && $novowel ) {
            $array->[$i]->[1] =~ s/(b)$/p/;
        }
        elsif ( $this =~ /(r)$/ && $novowel ) {
            $array->[$i]->[1] =~ s/(r)$/l/;
            $array->[$i+1]->[1] =~ s/^r/l/;
        }
    }

    if ( scalar @$array ) {
        my $last = $array->[$#$array];
        my $this = $last->[1];
        if ( $this =~ /(tt|pp|jj)$/ ) {
            $last->[1] =~ s/(tt|pp|jj)$//;
        }
        elsif ( $this =~ /([^n]g|kk)$/ ) {
            $last->[1] =~ s/(g|kk)$/k/;
        }
        elsif ( $this =~ /(d|j|ch|s?s)$/ ) {
            $last->[1] =~ s/(d|j|ch|s?s)$/t/;
        }
        elsif ( $this =~ /(b)$/ ) {
            $last->[1] =~ s/(b)$/p/;
        }
        elsif ( $this =~ /(r)$/ ) {
            $last->[1] =~ s/(r)$/l/;
        }
    }

    @$array;
}

# ----------------------------------------------------------------
;1;

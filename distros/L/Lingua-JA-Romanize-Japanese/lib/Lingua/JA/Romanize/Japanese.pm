=head1 NAME

Lingua::JA::Romanize::Japanese - Romanization of Japanese language

=head1 SYNOPSIS

    use Lingua::JA::Romanize::Japanese;

    my $conv = Lingua::JA::Romanize::Japanese->new();
    my $roman = $conv->char( $kanji );
    printf( "<ruby><rb>%s</rb><rt>%s</rt></ruby>", $kanji, $roman );

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

Japanese language is written with a mix of Kanji and Kana characters.
Most of Kanji characters used in Japan were imported from China.
Two types of Kana characters, called Katakana and Hiragana, were created in Japan.
Kana characters are general terms for the syllabic Japanese scripts.

=head1 METHODS

=head2 $conv = Lingua::JA::Romanize::Japanese->new();

This constructer methods returns a new object with its dictionary cached.

=head2 $roman = $conv->char( $kanji );

This method returns romanized letters from a Japanese character.
It returns undef when $Kana is not a valid Japanese character.
The argument's encoding must be UTF-8.
Both of Kanji and Kana characters are allowed.

=head2 $roman = $conv->chars( $string );

This method returns romanized letters from multiple Japanese characters.

=head2 @array = $conv->string( $string );

This method returns a array of referenced arrays
which are pairs of Japanese chacater(s) and its romanized letters.

    $array[0]           # first Japanese character(s)'s pair (array)
    $array[1][0]        # secound Japanese character(s) itself
    $array[1][1]        # its romanized letters

=head1 DICTIONARY

This module's Japanese to roman mapping table is based on
the dictionary of SKK which is a Japanese input method on Emacs.
It was designed by Dr. Masahiko Sato and created in 1987.
SKK is an abbreviation of 'Simple Kana to Kanji conversion program'.

=head1 UTF-8 FLAG

This treats utf8 flag transparently.

=head1 MODULE DEPENDENCIES

L<DB_File> module is required.

=head1 SEE ALSO

L<Lingua::ZH::Romanize::Pinyin> for romanization of Standard Chinese

L<Lingua::KO::Romanize::Hangul> for romanization of Korean

http://www.kawa.net/works/perl/romanize/romanize-e.html

http://linuga-romanize.googlecode.com/svn/trunk/Lingua-JA-Romanize-Japanese/

http://openlab.jp/skk/

=head1 AUTHOR

Yusuke Kawasaki http://www.kawa.net/

=head1 COPYRIGHT

Copyright (c) 2006-2008 Yusuke Kawasaki. All rights reserved.

=head1 LICENSE

This dictionary is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either versions 2, or (at your option)
any later version.

=cut
# ----------------------------------------------------------------
package Lingua::JA::Romanize::Japanese;
use strict;
use Carp;
use DB_File;
use Fcntl;
use base qw( Lingua::JA::Romanize::Base );
use vars qw( $VERSION );
$VERSION = "0.23";

my $LINE_MAP = [
    qw(
      a   a   i   i   u   u   e   e   o   o   k   g   k   g   k
      g   k   g   k   g   s   z   s   z   s   z   s   z   s   z   t
      d   t   d   t   t   z   t   d   t   d   n   n   n   n   n   h
      b   p   h   b   p   h   b   p   h   b   p   h   b   p   m   m
      m   m   m   y   y   y   y   y   y   r   r   r   r   r   w   w
      w   w   w   n   b   k   k
      )
];
my $DICT_DB = 'Japanese.bdb';
my $PERL581 = 1 if ( $] >= 5.008001 );

# ----------------------------------------------------------------
sub new {
    my $package = shift;
    my $self = {};
    bless $self, $package;
    $self->{dict} = $self->_open_dict(@_);
    $self;
}

sub char {
    my $self = shift;
    return $self->_char(@_) unless $PERL581;
    my $src = shift;
    my $utf8 = utf8::is_utf8( $src );
    utf8::encode( $src ) if $utf8;
    my $out = $self->_char( $src );
    return unless defined $out;
    utf8::decode( $out ) if $utf8;
    $out;
}

sub _char {
    my $self = shift;
    my $char = shift;
    return $self->{dict}->{$char} if ( exists $self->{dict}->{$char} && $self->{dict}->{$char} ne "" );
    $self->kana()->char($char);
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

sub _string {
    my $self  = shift;
    my $src   = shift;
    my $array = [];

    while ( $src =~ /((?:[\xE0-\xEF][\x80-\xBF]{2})+)|([^\xE0-\xEF]+)/sg ) {
        ### roman
        if ( defined $2 ) {
            push( @$array, [$2] );
            next;
        }
        my $str = $1;
        my $split = [ $str =~ /([\xE0-\xEF][\x80-\xBF]{2})/g ];
        while ( scalar @$split ) {
            ### kana
            if ( $split->[0] =~ /^\xE3/ ) {
                my $kana  = shift @$split;
                my $pair  = [$kana];
                my $roman = $self->kana()->char($kana);
                $pair->[1] = $roman if defined $roman;
                push( @$array, $pair );
                next;
            }
            ### kanji
            my $word    = shift @$split;
            my $roman   = $self->char($word);
            my $tryword = $word;
            my $trylist = [];
            while ( scalar @$split ) {
                my $next = $split->[0];

                ### okuri-ari
                if ( $next =~ /^\xE3/ ) {
                    my $okuri = $self->_kana_line($next);
                    if ( exists $self->{dict}->{ $tryword . $okuri } ) {
                        $roman     = $self->{dict}->{ $tryword . $okuri };
                        $word      = $tryword;
                        $#$trylist = -1;                             # empty
                    }
                }

                last unless exists $self->{dict}->{ $tryword . $next };
                $tryword .= $next;
                push( @$trylist, shift @$split );
                if ( $self->{dict}->{$tryword} ne "" ) {
                    $roman     = $self->{dict}->{$tryword};
                    $word      = $tryword;
                    $#$trylist = -1;                  # empty
                }
            }

            unshift( @$split, @$trylist ) if scalar @$trylist;
            my $pair = defined $roman ? [ $word, $roman ] : [$word];
            push( @$array, $pair );
        }
    }

    $self->kana()->normalize($array);
}

sub _kana_line {
    my $self = shift;
    my $char = shift;
    my ( $c1, $c2, $c3 ) = unpack( "C3", $char );
    my $ucs2 =
      ( ( $c1 & 0x0F ) << 12 ) | ( ( $c2 & 0x3F ) << 6 ) | ( $c3 & 0x3F );
    return if ( $ucs2 < 0x3041 );
    return if ( $ucs2 > 0x3093 && $ucs2 < 0x30A1 );
    return if ( $ucs2 > 0x30F6 );
    my $offset = ( $ucs2 - 0x3041 ) % 96;
    $LINE_MAP->[$offset];
}

sub _open_dict {
    my $self = shift;
    my $file = shift || $self->_detect_dict();
    Carp::croak "$! - $file\n" unless ( -r $file );
    my $dict  = {};
    my $flags = Fcntl::O_RDONLY();
    my $mode  = 0644;
    my $btree = DB_File::BTREEINFO->new();
    tie( %$dict, 'DB_File', $file, $flags, $mode, $btree )
      or Carp::croak "$! - $file\n";
    $dict;
}

sub _detect_dict {
    my $package = __PACKAGE__;
    my $dbfile = $INC{ join( "/", split( "::", "$package.pm" ) ) };
    $dbfile =~ s#[^/]+$#$DICT_DB#
      or Carp::croak "Invalid module name: $package\n";
    $dbfile;
}

# ----------------------------------------------------------------
1;

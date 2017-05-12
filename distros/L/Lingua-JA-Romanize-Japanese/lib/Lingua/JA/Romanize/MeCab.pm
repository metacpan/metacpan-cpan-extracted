=head1 NAME

Lingua::JA::Romanize::MeCab - Romanization of Japanese language with MeCab

=head1 SYNOPSIS

    use Lingua::JA::Romanize::MeCab;

    my $conv = Lingua::JA::Romanize::MeCab->new();
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

This is a MeCab version of L<Lingua::JA::Romanize::Japanese> module.
This requires MeCab.pm module which is distributed in mecab-perl-0.xx.tar.gz package.

=head1 UTF-8 FLAG

This treats utf8 flag transparently.

=head1 SEE ALSO

L<Lingua::JA::Romanize::Japanese>

http://mecab.sourceforge.jp/ (Japanese)

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2008 Yusuke Kawasaki. All rights reserved.
This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

=cut
# ----------------------------------------------------------------
package Lingua::JA::Romanize::MeCab;
use strict;
use Carp;
use MeCab;
use base qw( Lingua::JA::Romanize::Base );
use vars qw( $VERSION );
$VERSION = "0.20";

# ----------------------------------------------------------------
sub new {
    my $package = shift;
    my $self    = {};
    bless $self, $package;
    $self->require_encode_or_jcode();
    $self->{mecab} = MeCab::Tagger->new(@_);
    $self;
}

sub char {
    my $self  = shift;
    my $src   = shift;
    my $roman = $self->kana()->char($src);
    return $roman if $roman;
    my $pair = ( $self->string($src) )[0];    # need loop for nodes which have surface
    return if ( scalar @$pair == 1 );
    return $pair->[1];
}

sub string {
    my $self = shift;
    my $src  = shift;
    my $utf8;
    ( $src, $utf8 ) = $self->from_utf8($src);
    my $array = [];

    my $node = $self->{mecab}->parseToNode($src);
    for ( ; $node ; $node = $node->{next} ) {
        my $surface = $node->{surface};
        next unless defined $surface;
        next unless length( $surface );
        my $midasi = $self->to_utf8( $surface, $utf8 );
        my $feature = $node->{feature};
        $feature = $self->to_utf8( $feature, $utf8 ) if defined $feature;
        my @feature = split( /,/, $feature ) if defined $feature;
        my $kana = $feature[$#feature-1] if ( $#feature > 5 );
        my @array = $self->kana()->string($kana) if defined $kana;
        my $roman = join( "", map { $_->[1] } grep { $#$_ > 0 } @array ) if scalar @array;
        my $pair = $roman ? [ $midasi, $roman ] : [$midasi];
        push( @$array, $pair );
    }

    $self->kana()->normalize($array);
}

sub dict_charset {
    my $ver = $MeCab::VERSION;
    $ver =~ s/[^\d\.].*$//;
    Carp::croak "MeCab 0.94 or above is required ($ver)\n" if ( $ver < 0.94 );
    my $mecab = MeCab::Tagger->new() or Carp::croak "MeCab::Tagger->new() failed\n";
    my $dinfo = $mecab->dictionary_info() or Carp::croak "dictionary_info() failed\n";
    $dinfo->{charset} or Carp::croak "dictionary_info->{charset} failed\n";
}

sub dict_jcode {
    my $self = shift;
    return $self->{dict_jcode} if $self->{dict_jcode};
    my $charset = &dict_charset();
    if ( $charset =~ /^euc/i ) {
        $self->{dict_jcode} = 'euc';
    }
    elsif ( $charset =~ /^s(hift)?[\_\-]?jis/i ) {
        $self->{dict_jcode} = 'sjis';
    }
    elsif ( $charset =~ /^utf-?8/i ) {
        $self->{dict_jcode} = 'utf8';
    }
    $self->{dict_jcode};
}

sub dict_encode {
    my $self = shift;
    return $self->{dict_encode} if $self->{dict_encode};
    my $charset = &dict_charset();
    if ( $charset =~ /^euc/i ) {
        $self->{dict_encode} = 'EUC-JP';
    }
    elsif ( $charset =~ /^s(hift)?[\_\-]?jis/i ) {
        $self->{dict_encode} = 'CP932';
    }
    elsif ( $charset =~ /^utf-?8/i ) {
        $self->{dict_encode} = 'utf8';
    }
    $self->{dict_encode};
}

# ----------------------------------------------------------------
package Lingua::JA::Romanize::MeCab::UTF8;
use strict;
use vars qw( @ISA );
@ISA = qw( Lingua::JA::Romanize::MeCab );

sub dict_jcode { 'utf8'; }
sub dict_encode { 'utf8'; }

# ----------------------------------------------------------------
package Lingua::JA::Romanize::MeCab::EUC;
use strict;
use vars qw( @ISA );
@ISA = qw( Lingua::JA::Romanize::MeCab );

sub dict_jcode { 'euc'; }
sub dict_encode { 'EUC-JP'; }

# ----------------------------------------------------------------
package Lingua::JA::Romanize::MeCab::SJIS;
use strict;
use vars qw( @ISA );
@ISA = qw( Lingua::JA::Romanize::MeCab );

sub dict_jcode { 'sjis'; }
sub dict_encode { 'CP932'; }

# ----------------------------------------------------------------
1;

=head1 NAME

Lingua::JA::Romanize::Juman - Romanization of Japanese language with JUMAN

=head1 SYNOPSIS

    use Lingua::JA::Romanize::Juman;

    my $conv = Lingua::JA::Romanize::Juman->new();
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

This is a JUMAN version of L<Lingua::JA::Romanize::Japanese> module.
This requires Juman.pm module which is distributed in juman-x.x.tar.gz package.

=head1 UTF-8 FLAG

This treats utf8 flag transparently.

=head1 SEE ALSO

http://nlp.kuee.kyoto-u.ac.jp/nl-resource/juman.html (Japanese)

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2008 Yusuke Kawasaki. All rights reserved.
This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

=cut
# ----------------------------------------------------------------
package Lingua::JA::Romanize::Juman;
use strict;
use Carp;
use Juman;
use base qw( Lingua::JA::Romanize::Base );
use vars qw( $VERSION );
$VERSION = "0.20";
my $JUMAN_ENCODE = 'EUC-JP';
my $JUMAN_JCODE  = 'euc';

# ----------------------------------------------------------------
sub new {
    my $package = shift;
    my $self    = {};
    bless $self, $package;
    $self->require_encode_or_jcode();
    $self->{juman} = Juman->new(@_);
    $self;
}

sub char {
    my $self  = shift;
    my $src   = shift;
    my $roman = $self->kana()->char($src);
    return $roman if $roman;
    my $utf8;
    ( $src, $utf8 ) = $self->from_utf8($src);
    my $result = $self->{juman}->analysis($src) or return;
    my $node   = $result->mrph(0)               or return;
    my $kana   = $node->yomi()                  or return;
    $kana = $self->to_utf8($kana,$utf8);
    my @array = grep { $#$_ > 0 } $self->kana()->string($kana);
    return unless scalar @array;
    join( "", map { $_->[1] } @array );
}

sub string {
    my $self = shift;
    my $src  = shift;
    my $utf8;
    ( $src, $utf8 ) = $self->from_utf8($src);
    my $result = $self->{juman}->analysis($src);
    my $array  = [];

    foreach my $node ( $result->mrph() ) {
        my $midasi = $node->midasi();
        $midasi =~ s/^\\//;
        my $hinsi = $node->hinsi_id();
        my $kana = $node->yomi() if ( $hinsi != 1 );
        $midasi = $self->to_utf8($midasi,$utf8) if defined $midasi;
        $kana   = $self->to_utf8($kana,$utf8)   if defined $kana;
        my @array = $self->kana()->string($kana) if $kana;
        my $roman = join( "", map { $_->[1] } grep { $#$_ > 0 } @array )
          if scalar @array;
        my $pair = $roman ? [ $midasi, $roman ] : [$midasi];
        push( @$array, $pair );
    }

    $self->kana()->normalize($array);
}

sub dict_jcode { 'euc'; }
sub dict_encode { 'EUC-JP'; }

# ----------------------------------------------------------------
1;

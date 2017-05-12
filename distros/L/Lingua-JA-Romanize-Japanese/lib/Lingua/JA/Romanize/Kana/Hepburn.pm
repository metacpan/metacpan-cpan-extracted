=head1 NAME

Lingua::JA::Romanize::Kana::Hepburn - Hepburn Romanization using Japanese passport rules

=head1 SYNOPSIS

    use Lingua::JA::Romanize::Kana::Hepburn;

    my $conv = Lingua::JA::Romanize::Kana::Hepburn->new();
    my $roman = $conv->char( $kana );
    printf( "<ruby><rb>%s</rb><rt>%s</rt></ruby>", $kana, $roman );

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

This is a Hepburn romanization version of L<Lingua::JA::Romanize::Kana> module.
This requires L<Lingua::JA::Hepburn::Passport>.

=head1 UTF-8 FLAG

This treats utf8 flag transparently.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2008 Yusuke Kawasaki. All rights reserved.
This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
# ----------------------------------------------------------------
package Lingua::JA::Romanize::Kana::Hepburn;
use strict;
require 5.008;
use base qw( Lingua::JA::Romanize::Kana );
use Lingua::JA::Hepburn::Passport;
use vars qw( $VERSION );
$VERSION = "0.20";

# ----------------------------------------------------------------

sub char {
    my $self = shift;
    my $char = shift;
    return undef unless ( $char =~ /[^\000-\177]/ );
    my $pass = $self->passport();
    my $flag = utf8::is_utf8( $char );
    utf8::decode( $char ) unless $flag;
    my $roma = $pass->romanize( $char );
    return undef if ( $char eq $roma );
    utf8::encode( $roma ) unless $flag;
    $roma =~ tr/A-Z/a-z/;
    $roma;
}

sub string {
    my $self  = shift;
    my $src   = shift;
    my $array = [];
    foreach my $frag ( split( /([\000-\177]+)/, $src )) {
        my $pair  = [ $frag ];
        my $roman = $self->char( $frag );
        $pair->[1] = $roman if defined $roman;
        push( @$array, $pair );
    }
    @$array;
}

sub normalize {
    my $self  = shift;
    my $array = shift;
    $array = [ grep { ref $_ } @$array ];
    @$array;
}

sub passport {
    my $self = shift;
    $self->{passport} = shift if scalar @_;
    $self->{passport} ||= Lingua::JA::Hepburn::Passport->new();
}

# ----------------------------------------------------------------
1;

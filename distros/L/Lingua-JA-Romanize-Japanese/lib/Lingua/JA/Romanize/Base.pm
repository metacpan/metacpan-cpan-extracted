=head1 NAME

Lingua::JA::Romanize::Base - Baseclass for Lingua::JA::Romanize::* modules

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2008 Yusuke Kawasaki. All rights reserved.
This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

=cut
# ----------------------------------------------------------------
package Lingua::JA::Romanize::Base;
use strict;
use Carp;
use Lingua::JA::Romanize::Kana;
use vars qw( $VERSION );
$VERSION = "0.20";
my $PERL581 = 1 if ( $] >= 5.008001 );

# ----------------------------------------------------------------
sub new {
    my $package = shift;
    my $self    = {@_};
    bless $self, $package;
    $self;
}

sub chars {
    my $self  = shift;
    my @array = $self->string(shift);
    join( " ", map { $#$_ > 0 ? $_->[1] : $_->[0] } @array );
}

sub kana {
    my $self = shift;
    $self->{kana} = shift if scalar @_;
    $self->{kana} ||= Lingua::JA::Romanize::Kana->new();
}

sub require_encode_or_jcode {
    if ( $PERL581 ) {
        return if defined $Encode::VERSION;
        require Encode;
    }
    else {
        return if defined $Jcode::VERSION;
        local $@;
        eval { require Jcode; };
        Carp::croak "Jcode.pm is required on Perl $]\n" if $@;
    }
}

sub from_utf8 {
    my $self  = shift;
    my $src   = shift;
    my $flag;
    if ( $PERL581 ) {
        my $code = $self->dict_encode() or return $src;
        $flag = utf8::is_utf8( $src );
        if ( $flag ) {
            $src = Encode::encode( $code, $src );
        }
        else {
	        Encode::from_to( $src, 'utf8', $code );
	    }
    }
    else {
        my $code = $self->dict_jcode() || 'euc';
		Jcode::convert( \$src, $code, 'utf8' );
    }
    wantarray ? ( $src, $flag ) : $src;
}

sub to_utf8 {
    my $self = shift;
    my $src  = shift;
    my $flag = shift;
    if ( $PERL581 ) {
        my $code = $self->dict_encode() or return $src;
        if ( $flag ) {
            $src = Encode::decode( $code, $src );
        }
        else {
	        Encode::from_to( $src, $code, 'utf8' );
	    }
    }
    else {
        my $code = $self->dict_jcode() || 'euc';
		Jcode::convert( \$src, 'utf8', $code );
    }
    $src;
}

# ----------------------------------------------------------------
1;

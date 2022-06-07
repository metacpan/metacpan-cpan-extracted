package Lab::Moose::Instrument::NanonisTremea;
$Lab::Moose::Instrument::NanonisTremea::VERSION = '3.820';
#ABSTRACT: Nanonis Tramea

use v5.20;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Params::Validate;
use Carp;
use namespace::autoclean;

use Lab::Moose::Instrument qw/
    validated_getter validated_setter setter_params /;

extends 'Lab::Moose::Instrument';


sub nt_hstring {
    my $s = shift;
    $s = substr $s, 0, 32;
    return $s . ( \0 x ( 32 - length $s ) );
}

sub nt_string {
    my $s = shift;
    return ( pack "N", length($s) ) . $s;
}

sub nt_int {
    my $i = shift;
    return pack "N!", $i;
}

sub nt_uint16 {
    my $i = shift;
    return pack "n", $i;
}

sub nt_uint32 {
    my $i = shift;
    return pack "N", $i;
}

sub nt_float32 {
    my $f = shift;
    return pack "f>", $f;
}

sub nt_float64 {
    my $f = shift;
    return pack "d>", $f;
}

sub nt_header {
    my ( $self, $command, $b_size, $response ) = @_;

    $command = lc($command);

    my ($pad_len) = 32 - length($command);

    my ($template) = "A" . length($command);

    for ( 1 .. $pad_len ) {

        $template = $template . "x";
    }
    my $cmd      = pack( $template, $command );
    my $bodysize = nt_int($b_size);
    my $rsp      = nt_uint16($response);
    return $cmd . $bodysize . $rsp . nt_uint16(0);

    #$self->write(command=>$cmd.$bodysize.$rsp.nt_uint16(0));

}

sub swp1d_AcqChsSet {
    my $self = shift;
    my @channels;
    foreach (@_) {
        push @channels, $_;
    }
    my $command_name = "1dswp.acqchsset";
    my $bodysize     = ( 2 + $#channels ) * 4;
    my $head         = $self->nt_header( $command_name, $bodysize, 1 );

    #Create body
    my $body = nt_int( $#channels + 1 );
    foreach (@channels) {
        $body = $body . nt_int($_);
    }

    $self->write( command => $head . $body );

    #printf("Number of selected channels %d\n",$channels);

}

__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::NanonisTremea - Nanonis Tramea

=head1 VERSION

version 3.820

=head1 SYNOPSIS

 my $tramea = instrument(
     type => 'NanonisTramea',
 );

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by the Lab::Measurement team; in detail:

  Copyright 2022       Erik Fabrizzi, Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

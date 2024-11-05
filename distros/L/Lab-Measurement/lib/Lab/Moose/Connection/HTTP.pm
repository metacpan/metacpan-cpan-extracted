package Lab::Moose::Connection::HTTP;
$Lab::Moose::Connection::HTTP::VERSION = '3.920';
#ABSTRACT: Connection with Http requests

use v5.20;

use Moose;
use MooseX::Params::Validate;
use Moose::Util::TypeConstraints qw(enum);
use Carp;

use Lab::Moose::Instrument qw/timeout_param read_length_param/;

use LWP::UserAgent;
use HTTP::Request;

use namespace::autoclean;


has ip => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    reader => 'get_ip',
);

has port => (
    is       => 'ro',
    isa      => 'Lab::Moose::PosNum',
    required => 1,
    reader => 'get_port',
);

has ua => (
    is  => 'ro',
    isa => 'Any',
    builder => '_build_ua',
);

sub _build_ua {
    return LWP::UserAgent->new();
}

sub Read {
    my ( $self, %args ) = validated_hash(
        \@_,
        endpoint => { isa => 'Str' },
    );
    my $endpoint = $args{'endpoint'};

    my $url = "http://". $self->get_ip(). ":" . $self->get_port() . $endpoint;
    my $req = HTTP::Request->new( 'GET', $url );

    return $self->ua->request( $req );
}

sub Write {
    my ( $self, %args ) = validated_hash(
        \@_,
        endpoint => { isa => 'Str' },
        body => { isa => 'Str' },
    );
    my $endpoint = $args{'endpoint'};
    my $body = $args{'body'};

    my $url = "http://". $self->get_ip(). ":" . $self->get_port() . $endpoint;
    my $req = HTTP::Request->new( 'POST', $url);
       $req->header( 'Content-Type' => 'application/json' );
       $req->content( $body );

    return $self->ua->request( $req );
}

sub Clear {

}

with 'Lab::Moose::Connection';

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Connection::HTTP - Connection with Http requests

=head1 VERSION

version 3.920

=head1 SYNOPSIS

 use Lab::Moose
 
 my $instrument = instrument(
     type => 'random_instrument',
     connection_type => 'HTTP',
     connection_options => {ip => 172.22.11.2, port => 8002},
 );

=head1 DESCRIPTION

This module provides a connection for devices with an integrated web
server.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by the Lab::Measurement team; in detail:

  Copyright 2023       Andreas K. Huettel, Mia Schambeck


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Lab::Bus::DEBUG;
#ABSTRACT: Interactive debug bus
$Lab::Bus::DEBUG::VERSION = '3.899';
use v5.20;

use warnings;
use strict;

use Scalar::Util qw(weaken);
use Time::HiRes qw (usleep sleep);
use Lab::Bus;
use Data::Dumper;
use Carp;

use Lab::Exception;

use parent 'Lab::Bus';

our %fields = (
    brutal            => 0,         # brutal as default?
    type              => 'DEBUG',
    wait_status       => 10e-6,     # sec;
    wait_query        => 10e-6,     # sec;
    query_length      => 300,       # bytes
    query_long_length => 10240,     #bytes
    read_length       => 1000,      # bytesx
    instrument_index  => 0,
);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $twin  = undef;
    my $self  = $class->SUPER::new(@_)
        ;    # getting fields and _permitted from parent class
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    # no twin search - just register
    if ( $class eq __PACKAGE__ )
    {        # careful - do only if this is not a parent class constructor
        my $i = 0;
        while ( defined $Lab::Bus::BusList{ $self->type() }->{$i} ) { $i++; }
        $Lab::Bus::BusList{ $self->type() }->{$i} = $self;
        weaken( $Lab::Bus::BusList{ $self->type() }->{$i} );
    }

    return $self;
}

sub connection_new {    # @_ = ({ resource_name => $resource_name })
    my $self              = shift;
    my $args              = undef;
    my $status            = undef;
    my $connection_handle = undef;
    if ( ref $_[0] eq 'HASH' ) {
        $args = shift;
    }                   # try to be flexible about options as hash/hashref
    else { $args = {@_} }

    $connection_handle = { debug_instr_index => $self->instrument_index() };

    $self->instrument_index( $self->instrument_index() + 1 );

    return $connection_handle;
}

sub connection_read
{    # @_ = ( $connection_handle, $args = { read_length, brutal }
    my $self              = shift;
    my $connection_handle = shift;
    my $args              = undef;
    if ( ref $_[0] eq 'HASH' ) {
        $args = shift;
    }    # try to be flexible about options as hash/hashref
    else { $args = {@_} }

    my $command     = $args->{'command'}     || undef;
    my $brutal      = $args->{'brutal'}      || $self->brutal();
    my $read_length = $args->{'read_length'} || $self->read_length();

    my $result      = undef;
    my $user_status = undef;
    my $message     = "";

    my $brutal_txt = 'false';
    $brutal_txt = 'true' if $brutal;

    ( $message = <<ENDMSG ) =~ s/^\t+//gm;


		  DEBUG bus
		  connection_read called on Instrument No. $connection_handle->{'debug_instr_index'}
		  Brutal:      $brutal_txt
		  Read length: $read_length

		  Enter device response (one line). Timeout prefix: 'T!', Error: 'E!'
ENDMSG

    print $message;

    $result = <STDIN>;
    chomp($result);

    if ( $result =~ /^(T!).*/ ) {
        $result = substr( $result, 2 );
        Lab::Exception::Timeout->throw(
            error => "Timeout in " . __PACKAGE__ . "::connection_read().\n",
            data  => $result,
        );
    }
    elsif ( $result =~ /^(E!).*/ ) {
        $result = substr( $result, 2 );
        Lab::Exception::Error->throw(
            error => "Error in " . __PACKAGE__ . "::connection_read().\n", );
    }

    print "\n";
    return $result;
}

sub connection_write
{    # @_ = ( $connection_handle, $args = { command, wait_status }
    my $self              = shift;
    my $connection_handle = shift;
    my $args              = undef;
    if ( ref $_[0] eq 'HASH' ) {
        $args = shift;
    }    # try to be flexible about options as hash/hashref
    else { $args = {@_} }

    my $command = $args->{'command'} || undef;
    if ( !defined $command ) {
        Lab::Exception::CorruptParameter->throw(
                  error => "No command given to "
                . __PACKAGE__
                . "::connection_write\n" );
    }
    my $brutal      = $args->{'brutal'}      || $self->brutal();
    my $read_length = $args->{'read_length'} || $self->read_length();
    my $wait_status = $args->{'wait_status'} || $self->wait_status();

    my $message     = "";
    my $user_return = "";

    my $brutal_txt = 'false';
    $brutal_txt = 'true' if $brutal;

    ( $message = <<ENDMSG ) =~ s/^\t+//gm;


		  DEBUG bus
		  connection_write called on Instrument No. $connection_handle->{'debug_instr_index'}
		  Command:     $command
		  Brutal:      $brutal_txt
		  Read length: $read_length
		  Wait status: $wait_status

		  Enter return state: (E)rror, just Return for success
ENDMSG
    print $message;

    $user_return = <STDIN>;
    chomp($user_return);

    if ( !defined $command ) {
        Lab::Exception::CorruptParameter->throw(
                  error => "No command given to "
                . __PACKAGE__
                . "::connection_write().\n", );
    }
    else {

        if ( $user_return eq 'E' ) {
            Lab::Exception::Error->throw( error => "Error in "
                    . __PACKAGE__
                    . "::connection_write() while executing $command.", );
        }

        print "\n";
        return 1;
    }
}

sub timeout {
    my $self              = shift;
    my $connection_handle = shift;
    my $timo              = shift;

    say "DEBUG Bus: setting timeout to '$timo'";
}

sub connection_query
{ # @_ = ( $connection_handle, $args = { command, read_length, wait_status, wait_query, brutal }
    my $self              = shift;
    my $connection_handle = shift;
    my $args              = undef;
    if ( ref $_[0] eq 'HASH' ) {
        $args = shift;
    }    # try to be flexible about options as hash/hashref
    else { $args = {@_} }

    my $command     = $args->{'command'}     || undef;
    my $brutal      = $args->{'brutal'}      || $self->brutal();
    my $read_length = $args->{'read_length'} || $self->read_length();
    my $wait_status = $args->{'wait_status'} || $self->wait_status();
    my $wait_query  = $args->{'wait_query'}  || $self->wait_query();

    my $result    = undef;
    my $status    = undef;
    my $write_cnt = 0;
    my $read_cnt  = undef;

    $write_cnt = $self->connection_write($args);

    print "\nwait_query: $wait_query usec\n";

    $result = $self->connection_read($args);
    return $result;
}

sub _search_twin {
    my $self = shift;

    return undef;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Lab::Bus::DEBUG - Interactive debug bus (deprecated)

=head1 VERSION

version 3.899

=head1 DESCRIPTION

This module belongs to a deprecated legacy module stack, frozen and not under development anymore. Please port your code to the new API; its documentation can be found on the Lab::Measurement homepage, L<https://www.labmeasurement.de/>.

This will be an interactive debug bus, which prints out the commands sent by the 
measurement script, and lets you manually enter the instrument responses.

Unfinished, needs testing. 

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2011-2012  Andreas K. Huettel, Florian Olbrich
            2013       Andreas K. Huettel
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

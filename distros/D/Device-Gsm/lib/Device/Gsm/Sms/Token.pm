# Device::Gsm::Sms::Token - SMS PDU message parser token
# Copyright (C) 2002-2015 Cosimo Streppone, cosimo@cpan.org
#
# This program is free software; you can redistribute it and/or modify
# it only under the terms of Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# Perl licensing terms for details.
#
# Commercial support is available. Write me if you are
# interested in new features or software support.

package Sms::Token;

use strict;
use integer;
use Carp 'croak';

# Token possible states
use constant ERROR   => 0;
use constant ENCODED => 1;
use constant DECODED => 2;

#
# new token ( @data )
#
sub new {
    my ($proto, $name, $options) = @_;

    #	my $class = ref $proto || $proto;
    $options->{'data'} ||= [];

    # Cannot load a token without its name
    if (!defined $name || $name eq '') {
        return undef;
    }

    # Create basic structure for a token
    my %token = (

        # Name of token, see ->name()
        __name => $name,

        # Data that token contains
        __data => $options->{'data'},

        # Decoded? or error?
        __state => '',

        # This is used to access other tokens in the "message"
        __messageTokens => $options->{'messageTokens'}
    );

    # Dynamically load required token module
    eval { require "Device/Gsm/Sms/Token/$name.pm" };
    if ($@) {
        warn(     'cannot load Device::Gsm::Sms::Token::' 
                . $name
                . ' plug-in for decoding. Error: '
                . $@);
        return undef;
    }

    # Try "static blessing" =:-o and see if it works
    bless \%token, 'Sms::Token::' . $name;
}

#
# Get/set internal token data
#
sub data {
    my $self = shift;
    if (@_) {
        if (!defined $_[0]) {
            $self->{'__data'} = [];
        }
        else {
            $self->{'__data'} = [@_];
        }
    }
    $self->{'__data'};
}

# Must be implemented in real token
sub decode {
    croak('decode() not implemented in token base class');
    return 0;
}

# Must be implemented in real token
sub encode {
    croak('encode() not implemented in token base class');
    return 0;
}

sub get {
    my ($self, $info) = @_;
    return undef unless $info;

    return $self->{"_$info"};
}

# XXX This must be filled by the higher level object that
# treats the entire message in tokens
#
# [token]->messageTokens( [name] )
#
sub messageTokens {

    # Usually this is a hash of token objects, accessible by key (token name)
    my $self = shift;
    my $name;
    if (@_) {
        $name = shift;
    }
    if (defined $name) {
        return $self->{'__messageTokens'}->{$name};
    }
    else {
        return $self->{'__messageTokens'};
    }
}

sub name {
    my $self = shift;
    return $self->{'__name'};
}

sub set {
    my ($self, $info, $newval) = @_;
    return undef unless $info;
    $newval = undef unless defined $newval;
    $self->{"_$info"} = $newval;
}

sub state {
    my $self = shift;
    return $self->{'__state'};
}

sub toString {
    my $self = shift;
    my $string;
    if (ref $self->{'__data'} eq 'ARRAY') {
        $string = join '', @{ $self->{'__data'} };
    }
    return $string;
}

1;


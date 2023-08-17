package Lab::Connection::Socket;
#ABSTRACT: IP socket connection
$Lab::Connection::Socket::VERSION = '3.881';
use v5.20;

use Lab::Bus::Socket;
use Lab::Connection;
use Lab::Exception;

our @ISA = ("Lab::Connection");

our %fields = (
    bus_class   => 'Lab::Bus::Socket',
    wait_status => 0,                    # usec;
    wait_query  => 10e-6,                # sec;
    read_length => 1000,                 # bytes
);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $twin  = undef;
    my $self  = $class->SUPER::new(@_)
        ;    # getting fields and _permitted from parent class
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    return $self;
}

#---For compatibility with Instruments written for GPIB----
sub EnableTermChar {    # 0/1 off/on
    my $self   = shift;
    my $enable = shift;
    print "EnableTermChar Ignored: Only for GPIB not for SOCKET?\n";

    #$self->{'TermChar'}=$enable;#bus()->connection_enabletermchar($self->connection_handle(), $enable);}
    return 1;
}

sub SetTermChar {       # the character as string
    my $self     = shift;
    my $termchar = shift;
    print "SetTermChar Ignored: Only for GPIB not for SOCKET?\n";

    #my $result=$self->bus()->connection_settermchar($self->connection_handle(), $termchar);
    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Connection::Socket - IP socket connection

=head1 VERSION

version 3.881

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2012       David Kalok
            2013       Andreas K. Huettel
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

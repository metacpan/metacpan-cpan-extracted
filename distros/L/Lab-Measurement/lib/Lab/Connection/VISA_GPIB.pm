package Lab::Connection::VISA_GPIB;
#ABSTRACT: GPIB-type connection class which uses NI VISA (L<Lab::VISA>) as backend
$Lab::Connection::VISA_GPIB::VERSION = '3.881';
use v5.20;

use strict;
use Lab::VISA;
use Lab::Bus::VISA;
use Lab::Connection::GPIB;
use Lab::Exception;

our @ISA = ("Lab::Connection::GPIB");

our %fields = (
    bus_class     => 'Lab::Bus::VISA',
    resource_name => undef,
    wait_status   => 0,                  # sec;
    wait_query    => 10e-6,              # sec;
    read_length   => 1000,               # bytes
    gpib_board    => 0,
    gpib_address  => 1,
    timeout       => 2,
);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $twin  = undef;
    my $self  = $class->SUPER::new(@_)
        ;  # getting fields and _permitted from parent class, parameter checks
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    return $self;
}

#
# Translating from plain GPIB-driverish to VISAslang
#

#
# adapting bus setup to VISA
#
sub _setbus {
    my $self      = shift;
    my $bus_class = $self->bus_class();

    no strict 'refs';
    $self->bus( $bus_class->new( $self->config() ) )
        || Lab::Exception::Error->throw(
              error => "Failed to create bus $bus_class in "
            . __PACKAGE__
            . "::_setbus.\n" );
    use strict;

    #
    # build VISA resource name
    #
    my $resource_name
        = 'GPIB' . $self->gpib_board() . '::' . $self->gpib_address();
    $resource_name .= '::' . $self->gpib_saddress()
        if defined $self->gpib_saddress();
    $resource_name .= '::INSTR';
    $self->resource_name($resource_name);
    $self->config()->{'resource_name'} = $resource_name;

    # again, pass it all.
    $self->connection_handle(
        $self->bus()->connection_new( $self->config() ) );

    return $self->bus();
}

sub _configurebus {
    my $self = shift;

    #
    # set VISA Attributes:
    #

    # termination character
    if ( defined $self->config()->{termchar} ) {
        if ( $self->config()->{termchar} =~ m/^[0-9]+$/ ) {
            $self->config()->{termchar} = chr( $self->config()->{termchar} );
        }
        $self->bus()->set_visa_attribute(
            $self->connection_handle(),
            $Lab::VISA::VI_ATTR_TERMCHAR_EN,
            $Lab::VISA::VI_TRUE
        );
        $self->bus()->set_visa_attribute(
            $self->connection_handle(),
            $Lab::VISA::VI_ATTR_TERMCHAR, ord( $self->config()->{termchar} )
        );
    }
    else {
        $self->bus()->set_visa_attribute(
            $self->connection_handle(),
            $Lab::VISA::VI_ATTR_TERMCHAR_EN,
            $Lab::VISA::VI_FALSE
        );
    }

    # read timeout
    $self->bus()->set_visa_attribute(
        $self->connection_handle(),
        $Lab::VISA::VI_ATTR_TMO_VALUE, $self->config()->{timeout} * 1e3
    );

}

1;

#
# Read,Write,Query are OK in the version from Lab::Connection
#

# $self->connection_handle() is the VISA resource handle

sub EnableTermChar {    # 0/1 off/on
    my $self   = shift;
    my $enable = shift;
    my $result;

    #  print "e/d\n";
    if ( $enable == 1 ) {

        #     print "enable ";
        $result = Lab::VISA::viSetAttribute(
            $self->connection_handle(),
            $Lab::VISA::VI_ATTR_TERMCHAR_EN,
            $Lab::VISA::VI_TRUE
        );
    }
    else {
        #     print "disable ";
        $result = Lab::VISA::viSetAttribute(
            $self->connection_handle(),
            $Lab::VISA::VI_ATTR_TERMCHAR_EN,
            $Lab::VISA::VI_FALSE
        );
    }

    #  print "result: $result\n";
    return $result;
}

sub SetTermChar {    # the character as string
    my $self     = shift;
    my $termchar = shift;

    #  print "char\n";
    my $result = Lab::VISA::viSetAttribute(
        $self->connection_handle(),
        $Lab::VISA::VI_ATTR_TERMCHAR, ord($termchar)
    );

    #  print "result: $result\n";
    return $result;
}


1;

__END__

=pod

=encoding utf-8

=head1 NAME

Lab::Connection::VISA_GPIB - GPIB-type connection class which uses NI VISA (L<Lab::VISA>) as backend

=head1 VERSION

version 3.881

=head1 SYNOPSIS

This GPIB Connection class for Lab::Bus::VISA implements a GPIB-Standard 
connection on top of VISA (translates GPIB parameters to VISA resource names, 
mostly, to be exchangeable with other GPIB connections.

This class is not called directly. To make a GPIB suppporting instrument use 
Lab::Connection::VISA_GPIB, set the connection_type parameter accordingly:

 $instrument = new HP34401A(
    connection_type => 'VISA_GPIB',
    gpib_board => 0,
    gpib_address => 14
 )

=head1 DESCRIPTION

C<Lab::Connection::VISA_GPIB> provides a GPIB-type connection with L<Lab::Bus::VISA> using
NI VISA (L<Lab::VISA>) as backend.

It inherits from L<Lab::Connection::GPIB> and subsequently from L<Lab::Connection>.

The main feature is to assemble the standard gpib connection options
  gpib_board
  gpib_address
  gpib_saddress
into a valid NI VISA resource name (see L<Lab::Connection::VISA> for more details).

=head1 CONSTRUCTOR

=head2 new

 my $connection = new Lab::Connection::VISA_GPIB(
    gpib_board => 0,
    gpib_address => $address,
    gpib_saddress => $secondary_address
 }

=head1 METHODS

This just falls back on the methods inherited from L<Lab::Connection>.

=head2 config

Provides unified access to the fields in initial @_ to all the child classes.
E.g.

 $GPIB_Address=$instrument->Config(gpib_address);

Without arguments, returns a reference to the complete $self->Config aka @_ of the constructor.

 $Config = $connection->Config();
 $GPIB_Address = $connection->Config()->{'gpib_address'};

=head1 TO DO

Access to GPIB VISA attributes, device clear, ...

=head1 CAVEATS/BUGS

Probably few. Mostly because there's not a lot to be done here. Please report.

=head1 SEE ALSO

=over 4

=item * L<Lab::Connection>

=item * L<Lab::Connection::GPIB>

=item * L<Lab::Connection::VISA>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2011       Andreas K. Huettel, David Kalok, Florian Olbrich
            2012       Florian Olbrich, Stefan Geissler
            2013       Andreas K. Huettel
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

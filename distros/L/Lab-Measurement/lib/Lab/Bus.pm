package Lab::Bus;
$Lab::Bus::VERSION = '3.881';
#ABSTRACT: Bus base class

use v5.20;

use strict;

use Lab::Generic;
use Lab::Exception;
use Time::HiRes qw (usleep sleep);

#use POSIX; # added for int() function
use Scalar::Util qw(weaken);
use Carp qw(croak cluck);
use Data::Dumper;
our $AUTOLOAD;

our @ISA = ('Lab::Generic');

# this holds a list of references to all the bus objects that are floating around in memory,
# to enable transparent bus reuse, so the user doesn't have to handle (or even know about,
# to that end) bus objects. weaken() is used so the reference in this list does not prevent destruction
# of the object when the last "real" reference is gone.
our %BusList = (

    # BusType => $BusReference,
);

our %fields = (
    config       => undef,
    type         => undef,    # e.g. 'GPIB'
    ignore_twins => 0,        #
    ins_debug    => 0,        # do we need additional output?
);

sub new {
    my $proto  = shift;
    my $class  = ref($proto) || $proto;
    my $config = undef;
    if ( ref $_[0] eq 'HASH' ) {
        $config = shift;
    }    # try to be flexible about options as hash/hashref
    else { $config = {@_} }
    my $self = $class->SUPER::new(@_);
    bless( $self, $class );
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    $self->config($config);

    # Object data setup
    $self->ignore_twins( $self->config('ignore_twins') );

    return $self;
}

#
# Call this in inheriting class's constructors to conveniently initialize the %fields object data
#
sub _construct {    # _construct(__PACKAGE__);
    ( my $self, my $package ) = ( shift, shift );
    my $class  = ref($self);
    my $fields = undef;
    {
        no strict 'refs';
        $fields = *${ \( $package . '::fields' ) }{HASH};
    }
    my $twin = undef;

    foreach my $element ( keys %{$fields} ) {
        $self->{_permitted}->{$element} = $fields->{$element};
    }
    @{$self}{ keys %{$fields} } = values %{$fields};
}

#
# these are stubs to be overwritten in child classes
#

#
# In child classes, this should search %Lab::Bus::BusList for a reusable
# instance (and be called in the constructor).
# e.g.
# return $self->_search_twin() || $self;
#
sub _search_twin {
    return 0;
}

sub connection_read {    # @_ = ( $connection_handle, \%args )
    return 0;
}

sub connection_write {    # @_ = ( $connection_handle, \%args )
    return 0;
}

#
# generates and returns a connection handle;
#
sub connection_new {
    return 0;
}

#
# config gets it's own accessor - convenient access like $self->config('GPIB_Paddress') instead of $self->config()->{'GPIB_Paddress'}
# with a hashref as argument, set $self->{'config'} to the given hashref.
# without an argument it returns a reference to $self->config (just like AUTOLOAD would)
#
sub config {    # $value = self->config($key);
    ( my $self, my $key ) = ( shift, shift );

    if ( !defined $key ) {
        return $self->{'config'};
    }
    elsif ( ref($key) =~ /HASH/ ) {
        return $self->{'config'} = $key;
    }
    else {
        return $self->{'config'}->{$key};
    }
}

sub AUTOLOAD {

    my $self = shift;
    my $type = ref($self) or croak "$self is not an object";

    my $name = $AUTOLOAD;
    $name =~ s/.*://;    # strip fully qualified portion

    unless ( exists $self->{_permitted}->{$name} ) {
        cluck(    "AUTOLOAD in "
                . __PACKAGE__
                . " couldn't access field '${name}'.\n" );
        Lab::Exception::Error->throw( error => "AUTOLOAD in "
                . __PACKAGE__
                . " couldn't access field '${name}'.\n" );
    }

    if (@_) {
        return $self->{$name} = shift;
    }
    else {
        return $self->{$name};
    }
}

# needed so AUTOLOAD doesn't try to call DESTROY on cleanup and prevent the inherited DESTROY
sub DESTROY {
    my $self = shift;
    $self->SUPER::DESTROY if $self->can("SUPER::DESTROY");
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Lab::Bus - Bus base class

=head1 VERSION

version 3.881

=head1 SYNOPSIS

This is a base class for inheriting bus types.

=head1 DESCRIPTION

C<Lab::Bus> is a base class for individual buses. It does not do anything on its
own. For more detailed information on the use of bus objects, take a look on a
child class, e.g. L<Lab::Bus::LinuxGPIB>.

C<Lab::Bus::BusList> contains a hash with references to all the active buses in
your program. They are put there by the constructor of the individual bus
C<Lab::Bus::new()> and have two levels: Package name and a unique bus ID (GPIB
board index offers itself for GPIB). This is to transparently (to the use
interface) reuse bus objects, as there may only be one bus object for every
(hardware) bus. weaken() is used on every reference stored in this hash, so
it doesn't prevent object destruction when the last "real" reference is lost.
Yes, this breaks object orientation a little, but it comes so handy!

  our %Lab::Bus::BusList = [
	$Package => {
		$UniqueID => $Object,
	}
	'Lab::Bus::GPIB' => {
		'0' => $Object,		"0" is the gpib board index
	}

Place your twin searching code in C<$self->_search_twin()>. Make sure it
evaluates C<$self->IgnoreTwin()>. Look at L<Lab::Bus::LinuxGPIB>.

=head1 CONSTRUCTOR

=head2 new

Generally called in child class constructor:

 my $self = $class->SUPER::new(@_);

Return blessed $self, with @_ accessible through $self->Config().

=head1 METHODS

=head2 config

Provides unified access to the fields in initial @_ to all the child classes.

=head2 connection_new

Empty stub function for overloading

=head2 connection_read

Empty stub function for overloading

=head2 connection_write

Empty stub function for overloading

=head1 CAVEATS/BUGS

Probably few. Mostly because there's not so much done here.

=head1 SEE ALSO

=over 4

=item

L<Lab::Bus::GPIB>

=item

L<Lab::Bus::MODBUS>

=item

and many more...

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2011-2012  Andreas K. Huettel, Florian Olbrich
            2014       Alexei Iankilevitch
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2019       Simon Reinhardt
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

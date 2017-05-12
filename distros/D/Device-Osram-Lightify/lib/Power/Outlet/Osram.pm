package Power::Outlet::Osram;

use strict;
use warnings;

use Device::Osram::Lightify::Hub;

BEGIN
{

    my $base = "use base qw{Power::Outlet::Common::IP};";
    eval($base);
    if ($@)
    {
        warn "Base-class Power::Outlet::Common::IP not found.\n";
    }
}

our $VERSION = '0.6';

=head1 NAME

Power::Outlet::Osram - Control and query an Osram Lightify light

=head1 SYNOPSIS

Using power-outlet shell script from Power::Outlet distribution

  power-outlet Osram ON host 192.168.1.10 name hall

Using Power::Outlet API

  my $outlet=Power::Outlet->new(type=>"Osram", host => "192.168.1.10", name=>"hall");
  print $outlet->on, "\n";

Using Power::Outlet::Osram  directly

  my $outlet=Power::Outlet::Osram->new(host => "192.168.1.10", name=>"hall");
  print $outlet->query, "\n";
  print $outlet->on, "\n";
  print $outlet->off, "\n";

=head1 DESCRIPTION

Power::Outlet::Osram is a package for controlling and querying a light on an Osram Lightify network attached bridge.

=head1 USAGE

  use Power::Outlet::Osram;
  my $lamp=Power::Outlet::Osram->new(host=>"mybridge", name=>"hall");
  print $lamp->on, "\n";

=head1 CONSTRUCTOR

=head2 new

  my $outlet=Power::Outlet->new(type=>"Osram", host=>"192.168.10.136", name => "Hall" );
  my $outlet=Power::Outlet::Osram->new(host=>"mybridge", name="kitchen");

=head1 PROPERTIES

=head2 name

Name for the particular light as configured on the Osram Lightify bridge.

=cut

sub name
{
    my $self = shift;
    $self->{ "name" } = shift if @_;
    return $self->{ "name" };
}


=head1 METHODS

=head2 query

Return the current state of the specified device, as a string.

=cut

sub query
{
    my $self = shift;

    my $x = Device::Osram::Lightify::Hub->new( host => $self->host() );
    foreach my $device ( $x->lights() )
    {
        if ( $device->name() eq $self->name() )
        {
            return ( $device->stringify() );
        }
    }

}

=head2 on

Sends a message to the device to Turn Power ON

=cut

sub on
{
    my $self = shift;
    return $self->_call("on");
}

=head2 off

Sends a message to the device to Turn Power OFF

=cut

sub off
{
    my $self = shift;
    return $self->_call("off");
}


=head2 _call

Implementation method to send an on/off message to the given device.

=cut

sub _call
{
    my $self  = shift;
    my $state = shift;

    my $x = Device::Osram::Lightify::Hub->new( host => $self->host() );
    foreach my $device ( $x->lights() )
    {
        if ( $device->name() eq $self->name() )
        {
            if ( $state =~ /on/i )
            {
                $device->set_on();
                return 1;
            }
            if ( $state =~ /off/i )
            {
                $device->set_off();
                return 1;
            }
        }
    }
    return 0;
}

=head2 switch

Queries the device for the current status and then requests the opposite.

=cut

#see Power::Outlet::Common->switch

=head2 cycle

Sends messages to the device to Cycle Power (ON-OFF-ON or OFF-ON-OFF).

=cut

#see Power::Outlet::Common->cycle

=head1 AUTHOR

Steve Kemp <steve@steve.org.uk>

=cut

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 Steve Kemp <steve@steve.org.uk>.

This library is free software. You can modify and or distribute it under
the same terms as Perl itself.

=cut

1;

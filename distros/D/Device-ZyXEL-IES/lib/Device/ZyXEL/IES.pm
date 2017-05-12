package Device::ZyXEL::IES;
use Moose;
use Net::SNMP::Util qw/snmpwalk snmpget/;
use Device::ZyXEL::IES::Slot;
use Device::ZyXEL::IES::OID;

# ABSTRACT: SNMP with a ZyXEL IES device

=pod

=head1 NAME

Device::ZyXEL::IES - A module for getting and setting values on a ZyXEL IES5xxx device
using SNMP.

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';

=head1 SYNOPSIS

Quick summary of what the module does.

    use Device::ZyXEL::IES;

    my $device = Device::ZyXEL::IES->new( {
      hostname => 'some_ies.example.com', 
      get_community => 'public', 
      set_community => 'something', 
    });

    # retrieve slot inventory (slot number and firmwares)
    # for an ies
    my $result = $device->slotInventory;
		
    # Data for the slots are now in the slots attribute
    # returning a list of Device::ZyXEL::IES::Slot objects
    my $slotlist = $device->slots;

=cut

has 'slots' => (
	traits => ['Hash'],
    isa => 'HashRef[Device::ZyXEL::IES::Slot]', 
	is => 'ro', 
	default => sub { {} }, 
	required => 0, 
	handles => {
    slot_exists => 'exists',
	  get_slot => 'get', 
	  add_slot => 'set', 
	  delete_slot => 'delete',
	  num_slots => 'count'
	}, 
	writer => '_set_slots'
);

our $oid_tr;
sub BUILD {
	my ( $self, $params ) = @_;
	my $slots = $self->slots;
	foreach my $slot ( keys %{$slots} ) {
		$slots->{$slot}->ies( $self )
  }
  $oid_tr = Device::ZyXEL::IES::OID->new;
}

after 'slots' => sub {
  my ( $self, $slots ) = @_;
	return unless $slots;
	foreach my $slot ( keys %{$slots} ) {
		$slots->{$slot}->ies( $self )
  }
};

has 'uptime' => (
	isa => 'Str', 
	is => 'ro', 
	default => sub { 'unknown' }, 
	writer => '_set_uptime'
);

has 'sysdescr' => (
	isa => 'Str', 
	is => 'ro', 
	writer => '_set_sysdescr'
);

has 'get_community' => (
	isa => 'Str', 
	is => 'ro', 
	required => 1
);

has 'set_community' => (
	isa => 'Str', 
	is => 'ro', 
);

# The hostname to connect to
has 'hostname' => (
	isa => 'Str', 
	is => 'ro', 
	required => 1
);

=head1 FUNCTIONS

=head2 read_oid

Uses Net::SNMP::Util to read the value of an oid

The oid passed here is a real one, not a name.
 
=cut
sub read_oid {
  my ($self,  $oid,  $translate) = @_;

  $translate = {} unless defined $translate;
  $translate->{'-timeticks'} = 0x0;  # Turn off so sysUpTime is numeric
  my @translatelist = ();
  for my $k ( keys %{$translate} ) {
    push @translatelist,$k,$translate->{$k};
  }
  my %snmpparams = (
    -version   => 2, 
    -community => $self->get_community(), 
    -translate   => \@translatelist
  );
	
  my $r = snmpget(
    hosts => [ $self->hostname ], 
    oids  => {
      o => $oid
    }, 
	snmp => \%snmpparams
  );

  return "[ERROR] Nothing returned" unless defined $r->{$self->hostname};
									  
  my $vals = $r->{$self->hostname};
										
  return "[ERROR] Wrong key returned" unless defined( $vals->{o} );
										  
  return $vals->{o};
}

=head2 walk_oid

 Does a snmpwalk of the given oid, and returns the result.
 
 scalar containing "ERROR: <something>" is returned upon error.

=cut
sub walk_oid {
  my ($self, $oid, $translate) = @_;
  $translate = {} unless defined $translate;
  my @translatelist = ();
  for my $k ( keys %{$translate} ) {
    push @translatelist,$k,$translate->{$k};
  }
  
  my %snmpparams = (
    -version   => 1,
    -community => $self->get_community(),
    -translate => \@translatelist
  );
  
  # use Net::SNMP::Util to do the walk
  my ($result,  $error) = snmpwalk(
    hosts => [$self->hostname()],
    snmp  => \%snmpparams,
    oids => [$oid] );
  
  return "ERROR: $error" if defined $error && $error ne '';
  return $result->{$self->hostname()}->[0];
}

=head2 read_oids
 
Uses Net::SNMP::Util to read the value of a set of oids
 
The oids passed here is a real ones, not a name.

=cut
sub read_oids {
  my ($self,  $oids ) = @_;
  
  my %snmpparams = (
  -version   => 2,
  -community => $self->get_community(),
  -translate   => [ -timeticks => 0x0 ]
  );
	
  my $r = snmpget(
    hosts => [ $self->hostname ],
    oids  => $oids,
    snmp => \%snmpparams
  );
  
  return "[ERROR] Nothing returned" unless defined $r->{$self->hostname};
  
  my $vals = $r->{$self->hostname};
  
  return $vals;
}

=head2 has_slot

 Checks whether or not a specific slot id is present in the slot list.
 
=cut
sub has_slot {
  my ($self,$slotid) = @_;

	return ( defined $self->slots()->{$slotid} );
}


=head2 read_uptime

Reads the system uptime from the IES.

=cut
sub read_uptime {
  my ($self) = @_;
  my $oid = $oid_tr->translate('DISMAN-EVENT-MIB::sysUpTimeInstance');
  my $uptime = $self->read_oid($oid);
  if ( $uptime !~ /ERROR/ ) {
	$self->_set_uptime( $uptime );
  }
  return $uptime;
}

=head2 read_sysdescr

Reads the system description from the IES.

=cut
sub read_sysdescr {
  my ($self) = @_;
  my $oid =  $oid_tr->translate('SNMPv2-MIB::sysDescr.0');
  my $sysdescr = $self->read_oid($oid);
  if ( $sysdescr !~ /ERROR/ ) {
	$self->_set_sysdescr( $sysdescr );
  }
  return $sysdescr;
}

=head2 slotInventory

Sweeps slots on the IES, creating all the required
Device::ZyXEL::IES::Slot objects along the way.

It only performs one walk for the firmware version
to get the Slot objects started. Further Slot info
will require interaction with the Slot objects 
themselves.

=cut

sub slotInventory {
  my $self = shift;

  # Start by clearing the slotlist.
  $self->_set_slots({});

  my %snmpparams = (
    -version   => 1, 
    -community => $self->get_community() 
  );

  my $oid = $oid_tr->translate('ZYXEL-IES5000-MIB::slotModuleDescr.0');
  # use Net::SNMP::Util to do the walk
  my ($result,  $error) = snmpwalk(
      hosts => [$self->hostname()], 
      snmp  => \%snmpparams, 
      oids => [$oid] );

  return "[ERROR] $error" unless defined $result;

  # we have some slot cardtype.
  if ( defined $result->{$self->hostname()}->[0] ) {
    foreach my $o ( keys %{$result->{$self->hostname()}->[0]} ) {
      if ( $result->{$self->hostname()}->[0]->{$o} ne '' ) {
        my $s = Device::ZyXEL::IES::Slot->new(
          id => $o, 
          cardtype => $result->{$self->hostname()}->[0]->{$o}, 
          ies => $self
        );
        $self->add_slot( $o, $s );
      }
    }
  }
  else {
    return "[ERROR] Nothing returned";
  }

  return 'OK';
}

=head2 fetchDetails

Uses Net::SNMP::Util to fetch enough items from the ies to fill in the
attributes of the object.

Fetches uptime, sysdescr, ...
=cut

sub fetchDetails {
  my $self = shift;
  my $meta = $self->meta();

  foreach my $method ( $meta->get_method_list ) {
    if ( $method =~ /^read_/ && $method !~ /^read_oid.*$/ ) {
       my $res = $self->$method;
       return $res if $res =~ /ERROR/i;
    }
  }
  return 'OK';
}

=head1 AUTHOR

Jesper Dalberg, C<< <jdalberg at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-device-zyxel-ies at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Device-ZyXEL-IES>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

:w


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Device::ZyXEL::IES


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Device-ZyXEL-IES>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Device-ZyXEL-IES>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Device-ZyXEL-IES>

=item * Search CPAN

L<http://search.cpan.org/dist/Device-ZyXEL-IES/>

=back


=head1 ACKNOWLEDGEMENTS

Fullrate (http://www.fullrate.dk) 
  Thanks for allowing me to be introduced to the "wonderful" device ;)
  And thanks for donating some of my work time to create this module and 
  sharing it with the world.
			
=head1 COPYRIGHT & LICENSE

Copyright 2012 Jesper Dalberg, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

__PACKAGE__->meta->make_immutable;

1;


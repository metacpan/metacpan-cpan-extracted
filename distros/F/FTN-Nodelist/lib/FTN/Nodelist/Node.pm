# FTN/Nodelist/Node.pm
#
# Copyright (c) 2005 Serguei Trouchelle. All rights reserved.
# Copyright (c) 2013 Robert James Clay. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# History:
#  1.08  2013/05/09 Move 'pm' files to the more standard locations under the
#                   lib/ directory. Add Author & Copyright information for
#                   Robert James Clay <jame@rocasa.us>. Match version number
#                   to that of main FTN::Nodelist module.
#  1.02  2005/02/22 Documentation improved
#  1.01  2005/02/16 Initial revision

=head1 NAME

FTN::Nodelist::Node - Manipulate node information in FTN nodelist

=head1 SYNOPSIS

 my $ndl = new FTN::Nodelist(-file => '/fido/var/ndl/nodelist.*');
 if (my $node = $ndl->getNode('2:550/4077')) {
   print $node->sysop();
 } else {
   warn 'Cannot find node';
 }

=head1 DESCRIPTION

C<FTN::Nodelist::Node> contains functions that can be used to get information
about node entry in Fidonet Technology Network nodelist.

=head1 METHODS

=head2 new

This method creates C<FTN::Nodelist::Node> object.

You should not use it anyway, since it is used from C<FTN::Nodelist>.
See L<FTN::Nodelist> for details. 

=cut 

package FTN::Nodelist::Node;

require Exporter;
use Config;

use strict;
use warnings;

our @EXPORT_OK = qw//;
our %EXPORT_TAGS = ();
our @ISA = qw/Exporter/;

$FTN::Nodelist::Node::VERSION = "1.08";

sub new {
  my $self = shift;
  my $addr = shift; # FTN::Address hash {z/n/f/p}
  my $line = shift; # Nodelist line

  $line =~ s/_/ /g; # change underline to spaces

  $self = $addr;
  $self->{'__addr'} = $addr->{'z'} . ':' . $addr->{'n'} . '/' .
                      $addr->{'f'} . '.' . $addr->{'p'};

  (
   $self->{'__keyword'}, # Pvt/Hold/Down/Zone/Region/Host/Hub
   undef,                # Node Number
   $self->{'__name'},    # Node Name
   $self->{'__loc'},     # Location
   $self->{'__sysop'},   # Sysop Name
   $self->{'__phone'},   # Phone Number
   $self->{'__speed'},   # DCE Speed
   @{$self->{'__flags'}}
  ) = split ',', $line;

  bless $self; 
  return $self;
}

=head2 address

Returns FTN node address in 4D format.

=cut

sub address {
  my $self = shift;
  return $self->{'__addr'};
}

=head2 keyword

Returns FTN node keyword (Pvt/Hold/Down/Zone/Region/Host/Hub). 
Empty string is used for regular node.

=cut

sub keyword {
  my $self = shift;
  return $self->{'__keyword'};
}

=head2 name

Returns FTN node station name.

This field may also be used by IP nodes for a domain name, static IP
address or E-Mail address for email tunnelling programs.

=cut

sub name {
  my $self = shift;
  return $self->{'__name'};
}

=head2 location

Returns FTN node location

=cut

sub location {
  my $self = shift;
  return $self->{'__loc'};
}

=head2 sysop

Returns FTN node sysop name

=cut

sub sysop {
  my $self = shift;
  return $self->{'__sysop'};
}

=head2 phone

Returns FTN node phone number (PSTN/ISDN)

Can also contains C<'-Unpublished-'> value or 000-IP address.

=cut

sub phone {
  my $self = shift;
  return $self->{'__phone'};
}

=head2 speed

Returns FTN node DCE speed

=cut

sub speed {
  my $self = shift;
  return $self->{'__speed'};
}

=head2 flags

Returns arrayref with FTN node flags

=cut

sub flags {
  my $self = shift;
  return $self->{'__flags'};
}

1;

=head1 AUTHORS

Serguei Trouchelle E<lt>F<stro@railways.dp.ua>E<gt>
Robert James Clay E<lt>F<jame@rocasa.us>E<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 COPYRIGHT

Copyright (c) 2005 Serguei Trouchelle. All rights reserved.
Copyright (c) 2013 Robert James Clay. All rights reserved.

=cut


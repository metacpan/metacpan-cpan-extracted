package Iterator::File::State::Interface;

## $Id: Interface.pm,v 1.5 2008/06/17 06:00:28 wdr1 Exp $

use 5.006;
use strict;
use warnings;

use Iterator::File::Utility;

our @ISA = qw(Iterator::File::Utility);
our $VERSION = substr(q$Revision: 1.5 $, 10);

our %default_config =
  (
   'update_frequency' => 1,
  );



sub new {
  my ($class, %config) = @_;

  %config = (%default_config, %config);
  my $self = $class->SUPER::new( %config );
  bless($self, $class);

  return $self;
}



sub initialize {
  my ($self) = @_;

  $self->{'marker'} = 0;
}



sub advance_marker {
  my ($self) = @_;

  return $self->set_marker( $self->marker() + 1 );
}



sub marker {
  my $self = shift;

  return $self->{'marker'};
}



sub set_marker {
  my $self = shift;
  my $num  = shift;

  $self->{'marker'} = $num;
}



sub finish {}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!


=head1 NAME

Iterator::File::State::Interface -- Interface for Iterator::File state classes

=head1 DESCRIPTION

All data sources should subclass Iterator::File::State::Interface, overriding
methods as appropriate.

Iterator::File::State::Interface inherits from Iterator::File::Utility.

=over 4

=item B<new(%config)>

Each subclass can take a %config hash.  Keys/meaning will be specific to
each subclass.

=cut

=item B<initialize()>

Initilizes any requirements for class.  (E.g., prepping temp files.)  The
iterator is not available until after initialize is invoked.

=item B<advance_marker()>

Increments the marker by one.

=cut

=item B<marker()>

Return the current value of the marker.

=cut

=item B<set_marker( $num )>

Sets the value of the marker to $num.  Note this update is independent
of any changes to the source file.

=cut

=item B<finish()>

Perform any required clean up once we're done.

=cut

=back

=head1 SEE ALSO

Iterator::File

=head1 AUTHOR

William Reardon, E<lt>wdr1@pobox.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by William Reardon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut  

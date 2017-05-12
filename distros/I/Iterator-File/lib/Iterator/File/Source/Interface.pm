package Iterator::File::Source::Interface;

## $Id: Interface.pm,v 1.5 2008/06/11 05:20:07 wdr1 Exp $

use 5.006;
use strict;
use warnings;

use Iterator::File::Utility;

our @ISA = qw(Iterator::File::Utility);
our $VERSION = substr(q$Revision: 1.5 $, 10);

our %default_config = ();

sub new {
  my ($class, %config) = @_;

  %config = (%default_config, %config);
  my $self = $class->SUPER::new( %config );
  bless($self, $class);

  return $self;
}


sub initialize {}


sub next {}


sub value {}


sub advance_to {}


sub finish {}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Iterator::File::Source::Interface -- Interface for Iterator::File data sources

=head1 DESCRIPTION

All data sources should subclass Iterator::File::Source::Interface & implement the methods defined here.

Iterator::File::Source::Interface inherits from Iterator::File::Utility.

=over 4

=item B<new(%config)>

Construct the object.  Argument validation.  Default assignment.

=cut

=item B<initialize()>

Any heavy lifting should occur here.  E.g., opening a file or shared memory segment.

=cut

=item B<next()>

Advance the iterator & return the new value.

=cut

=item B<value()>

Return the current value, without advancing.

=cut

=item B<advance_to( $location )>

Advance the iterator to $location.  If $location is B<behind> the current location, behavior
is undefined.  (I.e., don't do that.)

=cut

=item B<finish()>

Invoked when all is complete so that cleanup may occur.

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

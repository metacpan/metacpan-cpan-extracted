#!/usr/bin/perl
package Lingua::TreeTagger::Filter::Result::Hit;

use Moose;
use Carp;

#===============================================================================
#attributes
#===============================================================================

has 'begin_index' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
    reader   => 'get_begin_index',
);

has 'sequence_length' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
    reader   => 'get_sequence_length',
);

#===============================================================================
# Public methods
#===============================================================================

#-----------------------------------------------------------------------------
# function
#-----------------------------------------------------------------------------
# Synopsis:
# attributes:        -
# Return values:     -
#-----------------------------------------------------------------------------

#===============================================================================
# Standard Moose cleanup.
#===============================================================================

no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Lingua::TreeTagger::Filter::Result::Hit - storing a matching sequence

=head1 VERSION

Version 0.01

=cut


=head1 SYNOPSIS
  
  use Lingua::TreeTagger::Filter;
  
  my $hit = Lingua::TreeTagger::Filter::Result::Hit->new(
    begin_index     => 1,
    sequence_length => 1,
  );



=head1 Description

This module is part of the Lingua::TreeTagger::Filter distribution. It
 defines a class to store a matching sequence.  
See also L<Lingua::TreeTagger::Filter>, 
L<Lingua::TreeTagger::Filter::Result> and
L<Lingua::TreeTagger::Filter::Result::Hit>

=head1 METHODS

=over 4

=item C<new()>

This constructor is normally called by the method apply_filter of the 
module Lingua::TreeTagger::Filter and not directly by the user
The constructor has two required parameters.

=over 4

=item C<begin_index>

an Int corresponding to the index of the beginning from the matching 
sequence in the taggedtext sequence (an array, attribute 'sequence' 
from the taggedtext object)


=item C<sequence_length>

an Int corresponding to the number of tokens composing the matching 
sequence

=back

=back

=head1 ACCESSORS

=over 4

=item C<get_begin_index()>

Read-only accessor for the 'begin_index' attribute

=item C<get_sequence_length()>

Read-only accessor for the 'sequence_length' attribute

=back

=head1 DIAGNOSTICS

=over 4


=back

=head1 DEPENDENCIES

This is part of the Lingua::TreeTagger::Filter 
distribution. It is not intended to be used as an independent module.

This module requires module Moose and was developed using version 
1.09.Please report incompatibilities with earlier versions to the 
author.


=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Benjamin Gay (Benjamin.Gay@unil.ch)

Patches are welcome.


=head1 AUTHOR

Benjamin Gay, C<< <Benjamin.Gay at unil.ch> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Benjamin Gay.

This program is free software; you can redistribute it and/or modify 
it under the terms of either: the GNU General Public License as 
published by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Lingua::TreeTagger::Filter
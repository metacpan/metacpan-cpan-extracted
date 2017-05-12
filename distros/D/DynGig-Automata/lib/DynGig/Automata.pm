=head1 NAME

DynGig::Automata - A collection of automation frameworks

=cut
package DynGig::Automata;

=head1 VERSION

Version 1.01

=cut

our $VERSION = '1.01';

=head1 MODULES

=head2 DynGig::Automata::MapReduce 

Sequential map/reduce automation framework.

=head2 DynGig::Automata::Sequence 

Sequential automation framework.

=head2 DynGig::Automata::Serial 

Process targets in serial batches.

=head2 DynGig::Automata::Thread 

Extends DynGig::Automata::Serial.

=head2 DynGig::Automata::EZDB::Alert 

Extends DynGig::Util::EZDB.

=head2 DynGig::Automata::EZDB::Exclude 

Extends DynGig::Util::EZDB.

=head1 AUTHOR

Kan Liu

=head1 COPYRIGHT and LICENSE

Copyright (c) 2010. Kan Liu

This program is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

__END__

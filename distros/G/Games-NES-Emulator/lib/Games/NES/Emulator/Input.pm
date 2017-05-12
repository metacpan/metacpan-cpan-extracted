package Games::NES::Emulator::Input;

use strict;
use warnings;

use base qw( Class::Accessor::Fast );

__PACKAGE__->mk_accessors( qw( number ) );

=head1 NAME

Games::NES::Emulator::Input - NES Controller

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 poll( )

=cut

sub poll {
}

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

=over 4 

=item * L<Games::NES::Emulator>

=back

=cut

1;

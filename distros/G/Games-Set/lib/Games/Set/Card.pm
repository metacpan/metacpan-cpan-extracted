use strict;
package Games::Set::Card;
use base 'Class::Accessor::Fast';
our %properties = ( count   => [ qw( one      two       three   ) ],
                    colour  => [ qw( red      green     purple  ) ],
                    shape   => [ qw( oval     squiggle  diamond ) ],
                    pattern => [ qw( solid    open      striped ) ],
                   );
__PACKAGE__->mk_accessors( keys %properties );

1;
__END__

=head1 NAME

Games::Set::Card - representation of a Set card

=head1 SYNOPSIS

 my $card = Games::Set::Card->new;

=head1 DESCRIPTION

This is a utility class for Games::Set.

=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net>

=head1 COPYRIGHT

Copyright (C) 2003 Richard Clamp.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

Games::Set

=cut

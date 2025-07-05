package File::Stubb::SubstTie;
use 5.016;
our $VERSION = '0.03';
use strict;
use warnings;

use Tie::Hash;
use parent -norequire, 'Tie::StdHash';

sub TIEHASH {

    my ($class, %hash) = @_;

    return bless \%hash, $class;

}

# Return desired value or an empty string if not present.
sub FETCH {

    return $_[0]->{ $_[1] } // '';

}

1;

=head1 NAME

File::Stubb::SubstTie - Class for tying hashes in %_ for Perl targets

=head1 USAGE

  use File::Stubb::SubstTie;

  tie my %tie, 'File::Stubb::SubstTie', one => 1, two => 2;

  # Returns empty string instead of undef.
  $tie{ phony };

=head1 DESCRIPTION

B<File::Stubb::SubstTie> is a class module that, when tied to hashes, will
return empty strings for non-existent or undefined keys rather than C<undef>.
This is a private module for L<stubb>. For user documentation, consult the
L<stubb> manual.

=head1 AUTHOR

Written by Samuel Young, E<lt>samyoung12788@gmail.comE<gt>.

This project's source can be found on its
L<Codeberg page|https://codeberg.org/1-1sam/stubb.git>. Comments and pull
requests are welcome!

=head1 COPYRIGHT

Copyright (C) 2025 Samuel Young

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

=head1 SEE ALSO

L<stubb>

=cut

# vim: expandtab shiftwidth=4

package Earth::USA::Washington::Cascadia;

use warnings;
use strict;

=head1 NAME

Earth::USA::Washington::Cascadia - Jurisdictional definitions

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    use Earth::USA::Washington::Cascadia;

    my $cascadia = Earth::USA::Washington::Cascadia->new();

    my $marriage_definition = $cascadia->marriage();

=head1 SUBROUTINES/METHODS

=head2 marriage

This is the current definition in this jurisdiction.

=cut

sub marriage {
	return 'nunya';
}

=head1 AUTHOR

C.J. Adams-Collier, C<< <cjac at colliertech.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-earth-usa-washington-cascadia at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Earth-USA-Washington-Cascadia>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Earth::USA::Washington::Cascadia


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Earth-USA-Washington-Cascadia>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Earth-USA-Washington-Cascadia>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Earth-USA-Washington-Cascadia>

=item * Search CPAN

L<http://search.cpan.org/dist/Earth-USA-Washington-Cascadia/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 C.J. Adams-Collier.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Earth::USA::Washington::Cascadia

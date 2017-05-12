# FTN::JAM::Errnum

package FTN::JAM::Errnum;

use warnings;
use strict;


=head1 NAME

FTN::JAM::Errnum - A Perl extension for handling JAM messagebase Error Number references.

=head1 VERSION

Version 0.30

=cut

our $VERSION = '0.30';

=head1 DESCRIPTION

This module contains the read only constants used for referenceing Error Numbers when accessing
JAM messagebases.

=cut

use Readonly;

Readonly our $IO_ERROR           => 1;
Readonly our $BASE_EXISTS        => 2;
Readonly our $BASEHEADER_CORRUPT => 3;
Readonly our $MSGHEADER_CORRUPT  => 4;
Readonly our $MSGHEADER_UNKNOWN  => 5;
Readonly our $MSG_DELETED        => 6;
Readonly our $BASE_NOT_LOCKED    => 7;
Readonly our $USER_NOT_FOUND     => 8;


=head1 AUTHOR

Robert James Clay, C<< <jame at rocasa.us> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ftn-jam at rt.cpan.org>, or through the web
interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ftn-jam>.  I will be notified, and
then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FTN::JAM::Errnum

You can also look for information at:

=over 4

=item * FTN::JAM Home Page

L<http://ftnpl.sourceforge.net/ftnpljam.html>

=item * Browse the FTN::JAM GIT repository at SourceForge

L<http://sourceforge.net/p/ftnpl/ftn-jam/code>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ftn-jam>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ftn-jam>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ftn-jam>

=item * Search CPAN

L<http://search.cpan.org/dist/ftn-jam>

=back

=head1 ACKNOWLEDGEMENTS

Originally based on the public domain Perl::JAM module by Johan Billing, which
can be found at L<https://bitbucket.org/johanbilling/jampm/overview>.

=head1 SEE ALSO

 L<FTN::JAM>, L<FTN::JAM::Examples>

=head1 COPYRIGHT & LICENSE

Copyright 2010-2012 Robert James Clay, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of FTN::JAM::Errnum

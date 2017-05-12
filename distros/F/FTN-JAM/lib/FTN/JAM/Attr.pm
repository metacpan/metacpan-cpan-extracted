# FTN::JAM::Attr

package FTN::JAM::Attr;

use warnings;
use strict;

=head1 NAME

FTN::JAM::Attr - A Perl extension for handling JAM messagebase Attribute references.

=head1 VERSION

Version 0.30

=cut

our $VERSION = '0.30';

=head1 DESCRIPTION

This module contains the read only constants used for referenceing attributes when accessing
JAM messagebases.

=cut

use Readonly;

Readonly our $LOCAL       => 0x00000001;
Readonly our $INTRANSIT   => 0x00000002;
Readonly our $PRIVATE     => 0x00000004;
Readonly our $READ        => 0x00000008;
Readonly our $SENT        => 0x00000010;
Readonly our $KILLSENT    => 0x00000020;
Readonly our $ARCHIVESENT => 0x00000040;
Readonly our $HOLD        => 0x00000080;
Readonly our $CRASH       => 0x00000100;
Readonly our $IMMEDIATE   => 0x00000200;
Readonly our $DIRECT      => 0x00000400;
Readonly our $GATE        => 0x00000800;
Readonly our $FILEREQUEST => 0x00001000;
Readonly our $FILEATTACH  => 0x00002000;
Readonly our $TRUNCFILE   => 0x00004000;
Readonly our $KILLFILE    => 0x00008000;
Readonly our $RECEIPTREQ  => 0x00010000;
Readonly our $CONFIRMREQ  => 0x00020000;
Readonly our $ORPHAN      => 0x00040000;
Readonly our $ENCRYPT     => 0x00080000;
Readonly our $COMPRESS    => 0x00100000;
Readonly our $ESCAPED     => 0x00200000;
Readonly our $FPU         => 0x00400000;
Readonly our $TYPELOCAL   => 0x00800000;
Readonly our $TYPEECHO    => 0x01000000;
Readonly our $TYPENET     => 0x02000000;
Readonly our $NODISP      => 0x20000000;
Readonly our $LOCKED      => 0x40000000;
Readonly our $DELETED     => 0x80000000;

=head1 AUTHOR

Robert James Clay, C<< <jame at rocasa.us> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ftn-jam at rt.cpan.org>, or through the web
interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ftn-jam>.  I will be notified, and
then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FTN::JAM::Attr

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

1;    # End of FTN::JAM::Attr

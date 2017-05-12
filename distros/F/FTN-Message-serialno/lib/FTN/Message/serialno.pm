package FTN::Message::serialno;

use strict;
use warnings FATAL => 'all';

use Carp ();

=encoding utf8

=head1 NAME

FTN::Message::serialno - base class for dealing with FTN message serialno.

=head1 VERSION

Version 20141121

=cut

our $VERSION = '20141121';

=head1 SYNOPSIS

  use parent 'FTN::Message::serialno';

  # define real methods here

=head1 DESCRIPTION

This is a base class for handling serialno value for new FTN messages.  Defines two virtual methods which should be defined in subclasses that use different approaches to manage required uniqueness (file on the disk, auto_increment field in table in database for example).

=over

=item * new

Class constructor.

=cut

sub new {
  ref( my $class = shift ) and Carp::croak 'I am only a class method!';

  bless {}, $class;
}

=item * get_serialno

Returns serialno field value for new FTN message.

=back

=cut

sub get_serialno {
  ref( my $self = shift ) or Carp::croak 'I am only an object method!';

  undef;                        # virtual method!
}

=head1 AUTHOR

Valery Kalesnik, C<< <valkoles at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ftn-message-serialno at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FTN-Message-serialno>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FTN::Message::serialno


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=FTN-Message-serialno>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/FTN-Message-serialno>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/FTN-Message-serialno>

=item * Search CPAN

L<http://search.cpan.org/dist/FTN-Message-serialno/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Valery Kalesnik.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1;

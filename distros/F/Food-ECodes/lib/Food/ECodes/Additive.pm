package Food::ECodes::Additive;

$Food::ECodes::Additive::VERSION   = '0.18';
$Food::ECodes::Additive::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Food::ECodes::Additive - Placeholder for Food Additive.

=head1 VERSION

Version 0.18

=cut

use 5.006;
use Data::Dumper;

use Moo;
use namespace::clean;

has 'id'          => (is => 'ro');
has 'name'        => (is => 'ro');
has 'status'      => (is => 'ro');
has 'purpose'     => (is => 'ro');
has 'eu_approved' => (is => 'ro');
has 'us_approved' => (is => 'ro');
has 'vegetarian'  => (is => 'ro');

=head1 SYNOPSIS

    use strict; use warnings;
    use Food::ECodes;

    my $ecode    = Food::ECodes->new;
    my $additive = $ecode->search('E100');

    print "Id         : ", $additive->id,          "\n";
    print "Name       : ", $additive->name,        "\n";
    print "Status     : ", $additive->status,      "\n";
    print "Purpose    : ", $additive->purpose,     "\n";
    print "EU Approved: ", $additive->eu_approved, "\n";
    print "US Approved: ", $additive->us_approved, "\n";
    print "Vegetarian : ", $additive->vegetarian,  "\n";

=head1 METHODS

=head2 id()

=head2 name()

=head2 status()

=head2 purpose()

=head2 eu_approved()

=head2 us_approved()

=head2 vegetarian()

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Food-ECodes>

=head1 BUGS

Please report any bugs or feature requests  to  C<bug-food-ecodes at rt.cpan.org>
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Food-ECodes>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Food::ECodes::Additive

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Food-ECodes>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Food-ECodes>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Food-ECodes>

=item * Search CPAN

L<http://search.cpan.org/dist/Food-ECodes/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 - 2016 Mohammad S Anwar.

This  program  is  free software; you can redistribute it and/or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Food::ECodes::Additive

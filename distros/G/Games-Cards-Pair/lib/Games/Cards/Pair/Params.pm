package Games::Cards::Pair::Params;

$Games::Cards::Pair::Params::VERSION   = '0.20';
$Games::Cards::Pair::Params::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Games::Cards::Pair::Params - Placeholder for parameters for Games::Cards::Pair.

=head1 VERSION

Version 0.20

=cut

use 5.006;
use strict; use warnings;
use Data::Dumper;

use Type::Library -base, -declare => qw(ZeroOrOne Suit Value Card Cards);
use Types::Standard qw(Str InstanceOf ArrayRef);
use Type::Utils;

my $SUITS  = { 'C' => 1, 'D' => 1, 'H' => 1, 'S' => 1 };
my $VALUES = { '2' => 1, '3' => 1, '4' => 1, '5' => 1,
               '6' => 1, '7' => 1, '8' => 1, '9' => 1,
               '10'=> 1, 'A' => 1, 'J' => 1, 'Q' => 1,
               'K' => 1, 'Joker' => 1 };

declare 'ZeroOrOne',
    as Str,
    where   { /^[0|1]$/ },
    message { "ERROR: Only 0 or 1 allowed." };

declare 'Suit',
    as Str,
    where   { exists $SUITS->{ucfirst(lc($_[0]))} },
    message { "isa check for 'suit' failed." };

declare 'Value',
    as Str,
    where   { exists $VALUES->{ucfirst(lc($_[0]))} },
    message { "isa check for 'value' failed." };

declare 'Card',
    as InstanceOf['Games::Cards::Pair::Card'];

declare 'Cards',
    as ArrayRef[Card],
    message { "isa check for 'cards' failed." };

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Games-Cards-Pair>

=head1 BUGS

Please report any bugs or feature requests to C<bug-games-cards-pair at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-Cards-Pair>.
I will be notified and then you'll automatically be notified of  progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::Cards::Pair::Params

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-Cards-Pair>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Games-Cards-Pair>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-Cards-Pair>

=item * Search CPAN

L<http://search.cpan.org/dist/Games-Cards-Pair/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012 - 2016 Mohammad S Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a  copy of the full
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

1; # End of Games::Cards::Pair::Params

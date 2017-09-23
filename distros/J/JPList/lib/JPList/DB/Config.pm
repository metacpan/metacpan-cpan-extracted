# ========================================================================== #
# lib/JPList::DB::Config.pm  - JPList DB Config
# Copyright (C) 2017 Exceleron Software, LLC
# ========================================================================== #

package JPList::DB::Config;

use Moose::Role;
use strict;
use warnings;
use namespace::autoclean;

# ========================================================================== #

=head1 NAME

JPList::DB::Config - JPList DB Config

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

  with 'JPList::DB::Config';

=head1 DESCRIPTION

The JPList::DB::Config module allows you store the DB Config

=head2 ATTRIBUTES

=over 4

=cut

# ========================================================================== #

=item C<dbh>

Params : $dbh

Desc   : Database Handle

=item C<db_table_name>

Params : $table_name

Desc   : Table name to query the result

=item C<fields>

Params : String
        '"Column1", "Column2"'

Desc   : Fields can be column list

=item C<where_fields>

Params : HASHREF
    {
        Column1 => ''
    }

Desc   : Table name to query the result

=cut

has 'dbh' => (
    is      => 'rw',
    required => 1,
);


has 'db_table_name' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has 'fields' => (
    is => 'rw',
    documentation =>
'fields as per SQL::Abstract it can be array of fields (which will be joined and quoted) or plain scalar (literal SQL, not quoted)'
);

has 'where_fields' => (
    is      => 'rw',
    default => sub {
        return {};
    },
    documentation => 'Custom Where fields like UtilityId etc..'
);

has 'group_fields' => (
    is            => 'rw',
    documentation => 'Custom group by fields like UtilityId, AccountId etc..'
);

has 'order_index' => (
    is => 'rw',
    documentation =>
      'Custom order index to sort by order index instad of column name to support quries with custom fields'
);

# ========================================================================== #

1;

__END__

=back
   
=head1 AUTHORS

Sheeju Alex, <sheeju@exceleron.com>

=head1 BUGS

https://github.com/sheeju/JPList/issues

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc JPList


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=JPList>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/JPList>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/JPList>

=item * Search CPAN

L<http://search.cpan.org/dist/JPList/>

=back

=head1 ACKNOWLEDGEMENTS

Development time supported by Exceleron L<www.exceleron.com|http://www.exceleron.com>.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2017 Exceleron Software, LLC

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

# vim: ts=4
# vim600: fdm=marker fdl=0 fdc=3

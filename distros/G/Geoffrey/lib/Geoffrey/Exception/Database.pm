package Geoffrey::Exception::Database;

use utf8;
use 5.016;
use strict;
use warnings;
use Carp qw/longmess/;

$Geoffrey::Exception::Database::VERSION = '0.000102';

use Exception::Class 1.23 (
    'Geoffrey::Exception::Database' => { description => 'Unidentified exception', },
    'Geoffrey::Exception::Database::NoDbh' =>
      { description => 'No default value set for column in table!', },
    'Geoffrey::Exception::Database::NotDbh' =>
      { description => 'Given dbh is in a non valid type!', },
    'Geoffrey::Exception::Database::SqlHandle' =>
      { description => 'No default value set for column in table!', },
    'Geoffrey::Exception::Database::CorruptChangeset' =>
      { description => 'No default value set for column in table!', },
);

sub throw_no_dbh {
    return Geoffrey::Exception::Database::NoDbh->throw(
        "No default dbh value is set\n" . longmess );
}

sub throw_not_dbh {
    return Geoffrey::Exception::Database::NotDbh->throw(
        "Given dbh is in a non valid type\n" . longmess );
}

sub throw_sql_handle {
    my ( $s_throw_message, $s_sql ) = @_;
    return Geoffrey::Exception::Database::SqlHandle->throw(
        "Can't handle sql: $s_sql $s_throw_message\n" . longmess );
}

sub throw_changeset_corrupt {
    my ( $id, $value, $resp ) = @_;
    return Geoffrey::Exception::Database::CorruptChangeset->throw(
        "MD5 hash changed for changeset: $id expect $value got $resp\n" . longmess );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Geoffrey::Exception::Database - # Exception classes for database handling

=head1 VERSION

version 0.000100

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 SUBROUTINES/METHODS

=head2 throw_sql_handle

=head2 throw_no_dbh

=head2 throw_changeset_corrupt

=head2 throw_not_dbh

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Mario Zieschang, C<< <mziescha at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Mario Zieschang.

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
mark, trade name, or logo of the Copyright Holder.

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
THE IMPLIED WARRANTIES OF MERCHANT ABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

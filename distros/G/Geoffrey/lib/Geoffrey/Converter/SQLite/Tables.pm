package Geoffrey::Converter::SQLite::Tables;

use utf8;
use 5.016;
use strict;
use Readonly;
use warnings;

$Geoffrey::Converter::SQLite::Tables::VERSION = '0.000101';

use parent 'Geoffrey::Role::ConverterType';

sub add { return q~CREATE TABLE {0} ( {1} )~; }

sub drop { return q~DROP TABLE {0}~; }

sub alter { return q~ALTER TABLE {0}~; }

sub add_column { return $_[0]->alter . q~ ADD COLUMN {1}~; }

sub list {
    my ( $self, $schema ) = @_;
    require Geoffrey::Utils;
    return
        q~SELECT name FROM ~
      . Geoffrey::Utils::add_schema($schema)
      . q~sqlite_master WHERE type='table'~;
}

sub s_list_columns {
    my ( $self, $schema ) = @_;
    require Geoffrey::Utils;
    return
        q~SELECT sql FROM ~
      . Geoffrey::Utils::add_schema($schema)
      . q~sqlite_master WHERE type='table' AND name=?~;
}

1;    # End of Geoffrey::Converter::SQLite::Tables

__END__

=pod

=head1 NAME

Geoffrey::Converter::SQLite::Tables - SQLite converter type for Tables!

=head1 VERSION

Version 0.000101

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 SUBROUTINES/METHODS

=head2 add

=head2 drop

=head2 alter

=head2 add_column

=head2 list

=head2 s_list_columns

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-Geoffrey at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geoffrey>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Geoffrey::Converter::SQLite::Tables

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Geoffrey>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Geoffrey>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Geoffrey>

=item * Search CPAN

L<http://search.cpan.org/dist/Geoffrey/>

=back

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

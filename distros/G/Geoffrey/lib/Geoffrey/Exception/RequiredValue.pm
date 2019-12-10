package Geoffrey::Exception::RequiredValue;

use utf8;
use 5.016;
use strict;
use warnings;
use Carp qw/longmess/;

$Geoffrey::Exception::RequiredValue::VERSION = '0.000205';

use Exception::Class 1.23 (
    'Geoffrey::Exception::RequiredValue'              => {description => q~Unidentified exception~,},
    'Geoffrey::Exception::RequiredValue::TableName'   => {description => q~No table name is given!~,},
    'Geoffrey::Exception::RequiredValue::TriggerName' => {description => q~No trigger name is given!~,},
    'Geoffrey::Exception::RequiredValue::TableColumn' =>
        {description => q~No default value set for column in table!~,},
    'Geoffrey::Exception::RequiredValue::ForeignkeyReftable' =>
        {description => q~No reftable name is given for foreign key in table!~,},
    'Geoffrey::Exception::RequiredValue::ForeignkeyRefcolumn' =>
        {description => q~No refcolumn name is given for foreign key in table!~,},
    'Geoffrey::Exception::RequiredValue::RefTable' =>
        {description => 'No reftable name is given for foreign key in table'},
    'Geoffrey::Exception::RequiredValue::RefColumn' =>
        {description => q~No refcolumn name is given for foreign key in table!~},
    'Geoffrey::Exception::RequiredValue::ColumnType'  => {description => q~Add column needs is given type name!~},
    'Geoffrey::Exception::RequiredValue::IndexName'   => {description => q~To drop index it needs a name!~},
    'Geoffrey::Exception::RequiredValue::WhereClause' => {description => q~No where clause is given!~},
    'Geoffrey::Exception::RequiredValue::Values'      => {description => q~No values are given!~},
    'Geoffrey::Exception::RequiredValue::Converter'   => {description => q~No changeset converter is given!~},
    'Geoffrey::Exception::RequiredValue::ChangesetId' => {description => q~No changeset id is given!~},
    'Geoffrey::Exception::RequiredValue::ActionSub'   => {description => q~Sub couldn't be found in action!~},
    'Geoffrey::Exception::RequiredValue::PackageName' => {description => q~Package name not given!~},
);

sub throw_common {
    my $s_value_name = shift // q//;
    return Geoffrey::Exception::RequiredValue->throw("$s_value_name is missing!\n" . longmess);
}

sub throw_column_type {
    my $s_column_name = shift // q//;
    return Geoffrey::Exception::RequiredValue::ColumnType->throw(
        "The column $s_column_name needs is given type!\n" . longmess);
}

sub throw_column_default {
    my ($s_value_name, $s_package) = @_;
    return Geoffrey::Exception::RequiredValue::TableColumn->throw(
        "No default value set for column $s_value_name in table! $s_package\n" . longmess);
}

sub throw_table_name {
    my $s_error_value = shift // q//;
    return Geoffrey::Exception::RequiredValue::TableName->throw("No table name is given $s_error_value\n" . longmess);
}

sub throw_index_name {
    my $s_error_value = shift // q//;
    return Geoffrey::Exception::RequiredValue::IndexName->throw(
        "To drop index it needs a name in $s_error_value\n" . longmess);
}

sub throw_trigger_name {
    my $s_error_value = shift // q//;
    return Geoffrey::Exception::RequiredValue::TriggerName->throw(
        "No trigger name is given $s_error_value\n" . longmess);
}

sub throw_reftable_missing {
    my $s_error_value = shift // q//;
    return Geoffrey::Exception::RequiredValue::RefTable->throw(
        "No reftable name is given for foreign key in table $s_error_value\n" . longmess);
}

sub throw_refcolumn_missing {
    my $s_error_value = shift // q//;
    return Geoffrey::Exception::RequiredValue::RefColumn->throw(
        "No refcolumn name is given for foreign key in table $s_error_value\n" . longmess);
}

sub throw_table_column {
    my ($s_value_name, $s_package) = @_;
    $s_package    //= q//;
    $s_value_name //= q//;
    return Geoffrey::Exception::RequiredValue::TableColumn->throw(
        "No table column is given $s_value_name!  $s_package\n" . longmess);
}

sub throw_where_clause {
    my $s_error_value = shift // q//;
    return Geoffrey::Exception::RequiredValue::WhereClause->throw(
        "No where clause is given $s_error_value\n" . longmess);
}

sub throw_values {
    my ($s_package) = @_;
    return Geoffrey::Exception::RequiredValue::Values->throw("Values are missing in $s_package !\n" . longmess);
}

sub throw_converter {
    my ($s_package) = @_;
    return Geoffrey::Exception::RequiredValue::Converter->throw(
        "No changeset converter is given! $s_package !\n" . longmess);
}

sub throw_id {
    my ($s_file) = @_;
    if ($s_file) {
        return Geoffrey::Exception::RequiredValue::ChangesetId->throw(
            "No changeset id is given in file: $s_file!\n" . longmess);
    }
    return Geoffrey::Exception::RequiredValue::ChangesetId->throw("No changeset id is given!\n" . longmess);
}

sub throw_action_sub {
    my ($s_action) = @_;
    return Geoffrey::Exception::RequiredValue::ActionSub->throw(
        qq~No sub name is given for action "$s_action" !\n~ . longmess);
}

sub throw_package_name {
    my ($s_action) = @_;
    return Geoffrey::Exception::RequiredValue::PackageName->throw(
        qq~No package name is given for action "$s_action" !\n~ . longmess);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Geoffrey::Exception::RequiredValue - # Exception classes for required values

=head1 VERSION

version 0.000100

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 SUBROUTINES/METHODS

=head2 throw_common

=head2 throw_column_type

=head2 throw_column_default

=head2 throw_table_name

=head2 throw_index_name

=head2 throw_trigger_name

=head2 throw_reftable_missing

=head2 throw_refcolumn_missing

=head2 throw_table_column

=head2 throw_where_clause

=head2 throw_values

=head2 throw_converter

=head2 throw_id

=head2 throw_action_sub

=head2 throw_package_name

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-Geoffrey at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geoffrey>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Geoffrey::Converter::SQLite

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

package Geoffrey::Exception::NotSupportedException;

use utf8;
use 5.016;
use strict;
use warnings;
use Carp qw/longmess/;

$Geoffrey::Exception::NotSupportedException::VERSION = '0.000201';

use Exception::Class 1.23 (
    'Geoffrey::Exception::NotSupportedException'           => { description => 'Unidentified exception', },
    'Geoffrey::Exception::NotSupportedException::Index'    => { description => 'Add index is not supported!', },
    'Geoffrey::Exception::NotSupportedException::Column'   => { description => 'Any column is not supported!', },
    'Geoffrey::Exception::NotSupportedException::Sequence' => { description => 'Add sequence is not supported!', },
    'Geoffrey::Exception::NotSupportedException::Primarykey' =>
      { description => 'Primarykey handle is not supported!', },
    'Geoffrey::Exception::NotSupportedException::Function' => { description => 'Function is not supported!' },
    'Geoffrey::Exception::NotSupportedException::ForeignKey' =>
      { description => 'Foreignkey action is not supported!' },
    'Geoffrey::Exception::NotSupportedException::Uniquekey' => { description => 'Uniquekey handle is not supported!', },
    'Geoffrey::Exception::NotSupportedException::EmptyTable' =>
      { description => 'Create a table without columns is not supported!', },
    'Geoffrey::Exception::NotSupportedException::Version' => { description => 'Any version is not supportet!', },
    'Geoffrey::Exception::NotSupportedException::ColumnType' =>
      { description => 'Any type not supported in some converter!', },
    'Geoffrey::Exception::NotSupportedException::Converter' => { description => 'Converter does not support!', },
    'Geoffrey::Exception::NotSupportedException::ConverterType' =>
      { description => 'Any subroutine in any converter type is not supported!', },
    'Geoffrey::Exception::NotSupportedException::Action' =>
      { description => 'Any subroutine in any action is not supported!', },
    'Geoffrey::Exception::NotSupportedException::ListInformation' =>
      { description => 'Any list information in converter is not supported!', },
    'Geoffrey::Exception::NotSupportedException::File' =>
      { description => 'Any subroutine information in file is not supported!', },

);

sub throw_empty_table {
    my $s_throw_message = shift // q~~;
    my $hr_params       = shift;
    if ($hr_params) {
        require Data::Dumper;
        my $s_params = Data::Dumper->new( [$hr_params] )->Terse(1)->Deparse(1)->Sortkeys(1)->Dump;
        return Geoffrey::Exception::NotSupportedException::EmptyTable->throw(
            "Create a table without columns is not supported!\n$s_params\n" . longmess );
    }
    return Geoffrey::Exception::NotSupportedException::EmptyTable->throw(
        "Create a table without columns is not supported! $s_throw_message\n" . longmess );
}

sub throw_index {
    my ( $s_type, $s_converter ) = @_;
    return Geoffrey::Exception::NotSupportedException::Index->throw(
        qq~Index type "$s_type" is not supported! $s_converter\n~ . longmess );
}

sub throw_column {
    my ( $s_type, $s_converter, $hr_params ) = @_;
    if ($hr_params) {
        require Data::Dumper;
        my $s_params = Data::Dumper->new( [$hr_params] )->Terse(1)->Deparse(1)->Sortkeys(1)->Dump;
        return Geoffrey::Exception::NotSupportedException::Column->throw(
        qq~Column type "$s_type" is not supported!\n$s_params\n$s_converter\n~ . longmess );
    }
    return Geoffrey::Exception::NotSupportedException::Column->throw(
        qq~Column type "$s_type" is not supported! $s_converter\n~ . longmess );
}

sub throw_sequence {
    my ( $s_type, $s_converter ) = @_;
    return Geoffrey::Exception::NotSupportedException::Sequence->throw(
        qq~Sequence type "$s_type" is not supported! $s_converter\n~ . longmess );
}

sub throw_primarykey {
    my ( $s_type, $s_converter ) = @_;
    return Geoffrey::Exception::NotSupportedException::Primarykey->throw(
        qq~Primarykey type "$s_type" is not supported! $s_converter\n~ . longmess );
}

sub throw_unique {
    my ( $s_type, $s_converter ) = @_;
    return Geoffrey::Exception::NotSupportedException::Uniquekey->throw(
        qq~Uniquekey type "$s_type" is not supported! $s_converter\n~ . longmess );
}

sub throw_foreignkey {
    my ( $s_type, $s_converter ) = @_;
    return Geoffrey::Exception::NotSupportedException::ForeignKey->throw(
        qq~ForeignKey type "$s_type" is not supported! $s_converter\n~ . longmess );
}

sub throw_version {
    my ( $s_type, $s_min_version, $s_version, $s_max_version ) = @_;
    return Geoffrey::Exception::NotSupportedException::Version->throw(
        qq~Type $s_type with unsupported version: $s_min_version <= $s_version\n~ . longmess )
      if !$s_max_version;

    return Geoffrey::Exception::NotSupportedException::Version->throw(
        qq~Type $s_type with unsupported version: $s_min_version <= $s_version <= $s_max_version\n~ . longmess );
}

sub throw_column_type {
    my ( $s_type, $s_converter ) = @_;
    return Geoffrey::Exception::NotSupportedException::ColumnType->throw(
        qq~Type: $s_type not supported in converter $s_converter.\n~ . longmess );
}

sub throw_converter_type {
    my ( $s_subroutine, $s_converter_type ) = @_;
    return Geoffrey::Exception::NotSupportedException::ConverterType->throw(
        qq~Subroutine "$s_subroutine" in converter type "$s_converter_type" is not supported!\n~ . longmess );
}

sub throw_converter {
    return Geoffrey::Exception::NotSupportedException::ConverterType->throw(
        qq~Converter does not support!\n~ . longmess );
}

sub throw_action {
    return Geoffrey::Exception::NotSupportedException::Action->throw(
        qq~Subroutine in action is not supported!\n~ . longmess );
}

sub throw_list_information {
    my ( $s_subroutine, $s_converter ) = @_;
    return Geoffrey::Exception::NotSupportedException::ListInformation->throw(
        qq~Subroutine "$s_subroutine" in "$s_converter" is not supported!\n~ . longmess );
}

sub throw_file {
    my ( $s_subroutine, $s_file ) = @_;
    return Geoffrey::Exception::NotSupportedException::File->throw(
        qq~Subroutine "$s_subroutine" in "$s_file" is not supported!\n~ . longmess );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Geoffrey::Exception::NotSupportedException - # Exception classes for not 
supported actions by converter

=head1 VERSION

version 0.000100

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 SUBROUTINES/METHODS

=head2 throw_empty_table

=head2 throw_index

=head2 throw_column

=head2 throw_sequence

=head2 throw_primarykey

=head2 throw_unique

=head2 throw_foreignkey

=head2 throw_version

=head2 throw_column_type

=head2 throw_converter_type

=head2 throw_action

=head2 throw_list_information

=head2 throw_file

=head2 throw_converter

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

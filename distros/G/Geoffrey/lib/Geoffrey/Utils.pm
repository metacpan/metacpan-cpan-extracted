package Geoffrey::Utils;

use utf8;
use 5.016;
use strict;
use Readonly;
use warnings;

$Geoffrey::Utils::VERSION = '0.000101';

Readonly::Scalar our $INT_64BIT_SIGNED => 9_223_372_036_854_775_807;

sub replace_spare {
    my ( $string, $options ) = @_;
    if ( !$string ) {
        require Geoffrey::Exception::RequiredValue;
        Geoffrey::Exception::RequiredValue::throw_common( 'String to replace',
            __PACKAGE__ . '::replace_spare' );
    }
    eval { $string =~ s/\{(\d+)\}/$options->[$1]/g; } or do { };
    return $string;
}

sub add_schema {
    my ($s_string) = @_;
    return q// unless $s_string;
    return qq~$s_string.~;
}

sub add_name {
    my ($hr_params) = @_;
    return $hr_params->{name} if $hr_params->{name};
    my @name_values = ( $hr_params->{prefix} );
    push @name_values, $hr_params->{context} if $hr_params->{context};
    push @name_values, time;
    return join q/_/, @name_values;
}

sub obj_from_name {
    my $s_module_name = shift;
    if ( !$s_module_name ) {
        require Geoffrey::Exception::RequiredValue;
        Geoffrey::Exception::RequiredValue::throw_package_name('obj_from_name');
    }
    my $return_eval = eval qq~require $s_module_name~;
    if ( !$return_eval ) {
        require Geoffrey::Exception::General;
        Geoffrey::Exception::General::throw_eval($@);
    }
    return $s_module_name->new(@_);
}

sub converter_obj_from_name {
    my $s_converter_name = shift;
    return obj_from_name( 'Geoffrey::Converter::' . $s_converter_name );
}

sub action_obj_from_name {
    my $s_action_name = shift;
    return obj_from_name( 'Geoffrey::Action::' . $s_action_name, @_ );
}

sub changelog_io_from_name {
    my $s_file_name = shift;
    return obj_from_name( 'Geoffrey::Changelog::' . $s_file_name );
}

sub parse_package_sub {
    my ($s_action) = @_;
    my @a_action = split /\./, lc $s_action;
    my $s_sub = pop @a_action;
    return (
        $s_sub, join q//,
        map { ucfirst } split /_/,
        ( join q/::/, map { ucfirst } @a_action )
    );
}

1;    # End of Geoffrey::Utils

__END__

=head1 NAME

Geoffrey::Utils - Helper snippets

=head1 VERSION

Version 0.000101

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 SUBROUTINES/METHODS

=head2 replace_spare

Replace spares which comes from Geoffrey::converter module.

=head2 add_name

Generates a name by given context and currente unixtimestamp

=head2 add_schema

=head2 obj_from_name

=head2 converter_obj_from_name

=head2 changelog_io_from_name

=head2 action_obj_from_name

=head2 parse_package_sub

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

package Geoffrey::Exception::General;

use utf8;
use 5.016;
use strict;
use warnings;
use Carp qw/longmess/;

$Geoffrey::Exception::General::VERSION = '0.000204';

use Exception::Class 1.23 (
    'Geoffrey::Exception::General'                   => { description => 'Unidentified exception', },
    'Geoffrey::Exception::General::TableNameMissing' => { description => 'No default value set for column in table!', },
    'Geoffrey::Exception::General::UnknownAction'    => { description => 'No default value set for column in table!', },
    'Geoffrey::Exception::General::ParamsMissing'    => { description => 'The sub needs some params!', },
    'Geoffrey::Exception::General::WrongRef'         => { description => 'The sub needs a ref!', },
    'Geoffrey::Exception::General::Eval'             => { description => 'Eval exception!', },

);

sub throw_wrong_ref {
    my ( $s_sub, $s_type ) = @_;
    return Geoffrey::Exception::General::WrongRef->throw( "$s_sub needs a $s_type\n" . longmess );
}

sub throw_no_table_name {
    my ($s_throw_message) = @_;
    return Geoffrey::Exception::General::TableNameMissing->throw(
        "I can't guess the table $s_throw_message\n" . longmess );
}

sub throw_unknown_action {
    my $s_throw_message = shift // q//;
    return Geoffrey::Exception::General::UnknownAction->throw(
        "Key for action $s_throw_message not found or implemented.\n Probaply misspelled.\n" . longmess );
}

sub throw_no_params {
    my $s_throw_message = shift // q//;
    my $s_param         = shift;
    my $hr_params       = shift;
    if ($s_param) {
        return Geoffrey::Exception::General::ParamsMissing->throw(
            qq~The sub "$s_throw_message" needs param: '$s_param'\n~ . longmess );
    }
    if ($hr_params) {
        require Data::Dumper;
        my $s_params = Data::Dumper->new( [$hr_params] )->Terse(1)->Deparse(1)->Sortkeys(1)->Dump;
        return Geoffrey::Exception::General::ParamsMissing->throw(
            qq~The sub "$s_throw_message" needs param: '$s_param'!\n$s_params\n~ . longmess );
    }
    return Geoffrey::Exception::General::ParamsMissing->throw(
        qq~The sub "$s_throw_message" needs some params.\n~ . longmess );
}

sub throw_eval {
    my $s_throw_message = shift // q//;
    return Geoffrey::Exception::General::Eval->throw( qq~Eval exception with $s_throw_message.\n~ . longmess );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Geoffrey::Exception::General - # General exception class

=head1 VERSION

version 0.000100

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 SUBROUTINES/METHODS

=head2 throw_no_table_name

=head2 throw_unknown_action

=head2 throw_no_params

=head2 throw_wrong_ref

=head2 throw_eval

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

package JIP::Mock;

use strict;
use warnings;

use Exporter qw(import);
use English qw(-no_match_vars);

use JIP::Mock::Control;

our $VERSION = 'v0.0.4';

our @EXPORT_OK = qw(take_control);

sub take_control {
    my ( $package, %args ) = @ARG;

    return JIP::Mock::Control->new(
        package => $package,
        %args,
    );
}

1;

__END__

=head1 NAME

JIP::Mock - Override subroutines in a module

=head1 VERSION

This document describes L<JIP::Mock> version C<v0.0.4>.

=head1 SYNOPSIS

Testing module:

    use JIP::Mock qw(take_control);

    # 42
    $sut->tratata();

    my $control = take_control('TestMe');

    $control->override(
        tratata => sub {
            return 24;
        },
    );

    # 24
    $sut->tratata();

=head1 EXPORTABLE FUNCTIONS

These functions are exported only by request.

=head2 take_control

Build new L<JIP::Mock::Control> object.

    use JIP::Mock;

    $control = JIP::Mock::take_control( package => 'TestMe' );

or exported on demand via

    use JIP::Mock qw(take_control);

    $control = take_control( package => 'TestMe' );

=head1 DIAGNOSTICS

None.

=head1 DEPENDENCIES

Perl 5.10.1 or later.

=head1 CONFIGURATION AND ENVIRONMENT

L<JIP::Mock> requires no configuration files or environment variables.

=head1 SEE ALSO

L<Mock::Quick>, L<Test::MockModule>, L<Test::MockClass>, L<Test::MockObject>

=head1 AUTHOR

Volodymyr Zhavoronkov, C<< <flyweight at yandex dot ru> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2023 Volodymyr Zhavoronkov.

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



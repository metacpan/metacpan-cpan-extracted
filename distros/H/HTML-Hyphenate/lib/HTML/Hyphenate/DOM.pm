# -*- cperl; cperl-indent-level: 4 -*-
# Copyright (C) 2009-2021, Roland van Ipenburg
package HTML::Hyphenate::DOM v1.1.8;
use Moose;
use utf8;
use 5.016000;
## no critic qw(ProhibitCallsToUndeclaredSubs)
extends q{Mojo::DOM};

## no critic qw(ProhibitCallsToUndeclaredSubs)
override 'replace' => sub {
## use critic
    my ( $self, $string ) = @_;
    if ( $string ne $self->to_string ) {
## no critic qw(ProhibitCallsToUndeclaredSubs)
        super();
## use critic
    }
};

1;

__END__

=encoding utf8

=for stopwords Bitbucket Ipenburg merchantability Mojolicious DOM

=head1 NAME

HTML::Hyphenate::DOM - DOM helper for HTML::Hyphenate

=head1 VERSION

This document describes HTML::Hyphenate::DOM version C<v1.1.8>.

=head1 SYNOPSIS

    use HTML::Hyphenate::DOM;

    $dom = new HTML::Hyphenate::DOM();

=head1 DESCRIPTION

Extends L<Mojo::DOM|Mojo::DOM>.

=head1 SUBROUTINES/METHODS

Inherits everything from Mojo::DOM but changes a few methods:

=over 4

=item $dom-E<gt>replace()

Because we sometimes end up replacing 90% of the nodes with the value it
already had - the case when no hyphens were added because all words were
shorter than the minimum length - we have added a check so the expensive super
method is only called when the given value differs from the current value.
This speeds up the process enormously.

=back

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over 4

=item * Perl 5.16 

=item * L<Moose|Moose>

=item * L<Mojolicious|Mojolicious> for L<Mojo::Dom|Mojo::Dom>

=back

=head1 INCOMPATIBILITIES

This module has the same limits as Mojo::DOM.

=head1 DIAGNOSTICS

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests at
L<Bitbucket|https://bitbucket.org/rolandvanipenburg/html-hyphenate/issues>.

=head1 AUTHOR

Roland van Ipenburg, E<lt>roland@rolandvanipenburg.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2009-2021, Roland van Ipenburg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

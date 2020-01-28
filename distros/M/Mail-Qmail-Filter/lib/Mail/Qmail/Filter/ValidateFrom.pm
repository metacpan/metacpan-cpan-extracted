use 5.014;
use warnings;

package Mail::Qmail::Filter::ValidateFrom;

our $VERSION = '1.21';

use Mo qw(coerce default);
extends 'Mail::Qmail::Filter';

has params      => {};
has reject_text => sub {
    sub { "Invalid e-mail address <$_[0]> in From header line" }
};

sub filter {
    my $self                = shift;
    my $header_from         = $self->message->header_from or return;
    my $header_from_address = $header_from->address;

    require Email::Valid;
    $self->reject( $self->reject_text, $header_from_address )
      unless Email::Valid->new( %{ $self->params } )
      ->address($header_from_address);
}

1;

__END__

=head1 NAME

Mail::Qmail::Filter::ValidateFrom -
check syntax of RFC5322.From address

=head1 SYNOPSIS

    use Mail::Qmail::Filter;

    Mail::Qmail::Filter->new->add_filters(
        '::ValidateFrom' => {
            skip_for_rcpt => [ 'postmaster', 'postmaster@' . $mydomain ],
            params        => { '-mxcheck' => 1 },
        },
        '::Queue',
    )->run;

=head1 DESCRIPTION

This L<Mail::Qmail::Filter> plugin checks if the C<From> header line of the
message contains a valid e-mail address (as far as L<Email::Valid> can tell).

=head1 OPTIONAL PARAMETERS

=head2 params

reference to a hash of parameters to pass to L<Email::Valid>

=head2 reject_text

Text to use when rejecting the message because it has an invalid address
in its C<From> header line.

May be a string or a subroutine which returns the text.
The subroutine may access the problematic address as its first argument.

Default:
  
    sub { "Invalid e-mail address <$_[0]> in From header line" };

=head1 SEE ALSO

L<Mail::Qmail::Filter/COMMON PARAMETERS FOR ALL FILTERS>, L<Email::Valid>

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Martin Sluka.

This module is free software; you can redistribute it and/or modify it
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

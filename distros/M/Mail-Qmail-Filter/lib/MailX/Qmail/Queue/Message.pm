use 5.014;
use warnings;

package MailX::Qmail::Queue::Message;

our $VERSION = '1.41';

use base 'Mail::Qmail::Queue::Message';

use Mail::Address;
use Mail::Header;

# Use inside-out attributes to avoid interference with base class:
my ( %header, %body );

sub add_header {
    my $self = shift;
    ${ $self->body_ref } = join "\n", @_, $self->body;
    delete $header{$self};
    $self;
}

sub header {
    my $self = shift;
    return $header{$self} if exists $header{$self};
    open my $fh, '<', $self->body_ref or die 'Cannot read message';
    $header{$self} = Mail::Header->new($fh);
    local $/;
    $body{$self} = <$fh>;
    $header{$self};
}

sub header_from {
    my $self = shift;
    my $from = $self->header->get('From') or return;
    ($from) = Mail::Address->parse($from);
    $from;
}

sub helo {
    my $header   = shift->header;
    my $received = $header->get('Received') or return;
    $received =~ /^from .*? \(HELO (.*?)\) /
      or $received =~ /^from (\S+) \(/
      or return;
    $1;
}

sub identity {
    my $self = shift;
    require Digest::SHA1;
    my $digest = Digest::SHA1->new;
    $digest->add( map "$_\n", $self->from, sort $self->to );
    {
        # We only take some header lines for the hash, because tests showed
        # that others (e.g. Received, DKIM-Signatures etc.) _do_ change
        # between several delivery attempts of the same message.
        my $header = $self->header;

        # I observed cases in the wild where the Date header line changed
        # between delivery attempts; therefore we do not include it in the
        # hash. And e.g. for AOL.com, even the Message-ID might change.
        for my $name (qw(From To Subject)) {
            $digest->add( map "$name: $_", $header->get($name) );
        }
    }
    $digest->add( "\n", $body{$self} );
    $digest->hexdigest;
}

sub remote_host {
    $ENV{TCPREMOTEHOST};
}

sub remote_ip {
    $ENV{TCPREMOTEIP};
}

sub replace_header {
    my ( $self, $header ) = @_;
    $self->header unless exists $body{$self};    # force parsing
    $header = $header->as_string if ref $header && $header->can('as_string');
    ${ $self->body_ref } = join "\n", $header, $body{$self};
    delete $header{$self};
    $self;
}

sub DESTROY {
    my $self = shift;
    delete $header{$self};
    delete $body{$self};
}

1;

__END__

=head1 NAME

MailX::Qmail::Queue::Message - extensions to Mail::Qmail::Queue::Message

=head1 DESCRIPTION

This class extends L<Mail::Qmail::Queue::Message>.

=head1 METHODS

=head2 ->add_header

Add header fields to the message.
Expects C<Field: Value> as argument, without newlines at the end.

=head2 ->header

get the header of the incoming message as L<Mail::Header> object

=head2 ->header_from

get the C<From:> header field of the incoming message as L<Mail::Address> object

=head2 ->helo

get the C<HELO>/C<EHLO> string used by the client

=head2 ->identity

Gives back a string that tries to uniquely identify this e-mail message,
that is:

=over 4

=item *

It is supposed to remain constant over several delivery attempts
of the same message, e.g. after deferrals.

=item *

But it should be different for other messages.

=item *

It can be safely used as (part of) a filename.

=back

=head2 ->remote_host

get the name of the host the message comes from (from its reverse lookup)

=head2 ->remote_ip

get the IP address the message comes from

=head2 ->replace_header($header)

Replace the whole header of the message.
C<$header> should either be a properly formatted e-mail header
or an object with an C<as_string> method which produces such a string,
e.g. a L<Mail::Header> object.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-mail-qmail-filter at rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mail-Qmail-Filter>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mail::Qmail::Filter

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Mail-Qmail-Filter>

=item * AnnoCPAN: Annotated CPAN documentation

L<https://annocpan.org/dist/Mail-Qmail-Filter>

=item * CPAN Ratings

L<https://cpanratings.perl.org/dist/Mail-Qmail-Filter>

=item * Search CPAN

L<https://metacpan.org/release/Mail-Qmail-Filter>

=back

=head1 ACKNOWLEDGEMENTS
=head1 LICENSE AND COPYRIGHT

Copyright 2019 Martin Sluka.

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

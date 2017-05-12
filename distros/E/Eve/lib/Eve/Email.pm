package Eve::Email;

use parent qw(Eve::Class);

use strict;
use warnings;

use Email::Sender::Simple qw(sendmail);
use Email::Simple;
use Email::Simple::Creator;

=head1 NAME

B<Eve::Email> - a wrapper for the C<Email::Sender::Simple> library.

=head1 SYNOPSIS

    use Eve::Email;

    my $mailer = Eve::Email->new();

    $mailer->send(to => $address, subject => $subject, body => $body);

=head2 Constructor arguments

=over 4

=item C<from>

The from address line that will be added to each sent email.

=back

=head1 METHODS

=head2 B<init()>

=cut

sub init {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my ($from));

    $self->{'_from'} = $from;

    return;
}

=head2 B<send()>

Send an email body with a certain subject to a certain recipient.

=head3 Arguments

=over 4

=item C<to>

=item C<subject>

=item C<body>

=back

=cut

sub send {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my ($to, $subject, $body));

    my $email = Email::Simple->create(
        header => [
            To      => $to,
            From    => $self->_from,
            Subject => $subject,
        ],
        body => $body);

    sendmail($email);
}

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Igor Zinovyev.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=head1 AUTHOR

=over 4

=item L<Igor Zinovyev|mailto:zinigor@gmail.com>

=back

=cut

1;

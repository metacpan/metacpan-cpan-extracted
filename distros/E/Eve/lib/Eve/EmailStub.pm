package Eve::EmailStub;

use strict;
use warnings;

use vars qw(%ENV);

BEGIN { $ENV{EMAIL_SENDER_TRANSPORT} = 'Test'; }

use Eve::Email;

=head1 NAME

B<Eve::EmailStub> - a helper stub class that replaces the mailer class.

=head1 SYNOPSIS

    package SomeTestCase;

    use Eve::EmailStub;
    use Eve::Email;

    my $already_mocked_email = Eve::Email->new(from => $from_string);

    $already_mocked_email->send(
        to => $address,
        subject => $subject,
        body => $body);

    my $delivery = $already_mocked_email->get_delivery();

    is(
        $delivery->{'envelope'}->{'to'}->[0],
        $address);

=head1 DESCRIPTION

B<Eve::EmailStub> is the class that uses the B<Email::Simple> class'
internal testing feature to replace the sender's engine with a test engine.

=head1 METHODS

=head2 B<get_delivery()>

Returns testing information about a last sent message.

=cut

sub get_delivery {
    my @deliveries = Email::Sender::Simple->default_transport->deliveries();

    return $deliveries[$#deliveries];
}

=head1 SEE ALSO

=over 4

=item L<Eve::Test>

=item L<Email::Simple>

=item L<Test::Class>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2013 Sergey Konoplev, Igor Zinovyev.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 AUTHOR

=over 4

=item L<Sergey Konoplev|mailto:gray.ru@gmail.com>

=item L<Igor Zinovyev|mailto:zinigor@gmail.com>

=back

=cut

1;

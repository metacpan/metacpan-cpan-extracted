package Log::Dispatch::Email::Sendmail;

use warnings;
use strict;

use base 'Log::Dispatch::Email';

=head1 NAME

Log::Dispatch::Email::Sendmail - Subclass of Log::Dispatch::Email that sends e-mail using Sendmail

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

L<Log::Dispatch::Email::MailSendmail> is no longer suitable for all
situations because it doesn't use Sendmail to send mail (despite the
name of the module) instead it uses SMTP and doesn't support AUTH.

This module sends mail using Sendmail. It has the overhead of a
fork/exec so it should only be used where really needed.

    use Log::Dispatch;

    my $log = Log::Dispatch->new(
      outputs => [
          [
              'Email::Sendmail',
              min_level => 'emerg',
              to        => [qw( foo@example.com bar@example.org )],
              subject   => 'Big error!'
          ]
      ],
    );

    $log->emerg("Something bad is happening");

=head1 SUBROUTINES/METHODS

=head2 send_email

Send a message

=cut

sub send_email {
	my $self = shift;
	my %p = @_;

	my $to = join(' ', @{$self->{to}});

	unless($to) {
		warn 'To whom should I be sending this e-mail?';
		return;
	}

	my $subject = $self->{subject};
	my $message = $p{message};

	if(open(my $mail, '|-', '/usr/sbin/sendmail -t')) {
		print $mail "To: $to\n";
		if($self->{from}) {
			my $from = $self->{from};
			print $mail "From: $from\n";
		}
		print $mail "Subject: $subject\n\n";

		print $mail $message;

		close $mail;
	} else {
		warn "/usr/sbin/sendmail: $?";
	}
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

No known bugs.

=head1 SEE ALSO

L<Log::Dispatch::Email::MailSendmail>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Log::Dispatch::Email::Sendmail

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log::Dispatch::Log::Sendmail>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Log-Dispatch-Log-Sendmail>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Log-Dispatch-Log-Sendmail>

=item * Search CPAN

L<http://search.cpan.org/dist/Log-Dispatch-Log-Sendmail/>

=back

=head1 ACKNOWLEDGEMENTS

Kudos to Dave Rolksy for the entire Log::Dispatch framework.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Nigel Horne.

This program is released under the following licence: GPL

=cut

1; # End of Log-Dispatch-Log-Sendmail

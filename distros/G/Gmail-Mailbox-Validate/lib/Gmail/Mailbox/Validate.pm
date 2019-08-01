package Gmail::Mailbox::Validate;

use 5.006;
use strict;
use warnings;
use Net::SMTP;

=head1 NAME

Gmail::Mailbox::Validate - Find out if the username has a valid gmail mailbox

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

It's quite simple to use:

    use Gmail::Mailbox::Validate;

    my $v = Gmail::Mailbox::Validate->new();
    print "mailbox exists" if $v->validate($username);
    
Or run via command line:

    $ perl -MGmail::Mailbox::Validate -le 'print "mailbox exists" if Gmail::Mailbox::Validate->new()->validate("mytest")'


=head1 SUBROUTINES/METHODS

=head2 new

Initialize the object.

=cut

sub new {
	my $class = shift;
	bless {},$class;
}

=head2 validate

Validate the mailbox for username provided.

=cut

sub validate {
	my $self = shift;
	my $username = shift;
	
	my $smtp = Net::SMTP->new('gmail-smtp-in.l.google.com') or die $@;
        $smtp->mail('foo@bar.net') or die $@;

	my $status = $smtp->to($username . '@gmail.com') ? 1 : 0;
	$smtp->quit;

	return $status;
}

=head1 AUTHOR

Yonghua Peng, C<< <pyh at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-gmail-mailbox-validate at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Gmail-Mailbox-Validate>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Gmail::Mailbox::Validate


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Gmail-Mailbox-Validate>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Gmail-Mailbox-Validate>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Gmail-Mailbox-Validate>

=item * Search CPAN

L<https://metacpan.org/release/Gmail-Mailbox-Validate>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2019 by Yonghua Peng.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Gmail::Mailbox::Validate

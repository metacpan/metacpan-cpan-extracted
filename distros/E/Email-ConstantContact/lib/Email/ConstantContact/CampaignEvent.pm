package Email::ConstantContact::CampaignEvent;

use warnings;
use strict;

use Email::ConstantContact::Contact;
use Email::ConstantContact::Campaign;

=head1 NAME

Email::ConstantContact::CampaignEvent - Internal class to interact with ConstantContact CampaignEvent Objects.

=head1 VERSION

Version 0.05

=cut

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw( );

$VERSION = '0.05';


=head1 SYNOPSIS
This module is not typically used directly, but internally by the main
Email::ConstantContact object for processing requests.

=cut

my @fields = qw (
	id EventTime Code Description BounceMessage
);

sub new {
	my $class	= shift;
	my $ccobj	= shift;
	my $data	= shift;
	my $self  = {'_cc' => $ccobj};

	if (defined($data->{'content'}) && defined($data->{'content'}->{'BounceEvent'})) {
		foreach my $field (@fields) {
			$self->{$field} = $data->{'content'}->{'BounceEvent'}->{$field};
		}

		$self->{Contact} = new Email::ConstantContact::Contact($ccobj, { content => { 'Contact' => $data->{'content'}->{'BounceEvent'}->{'Contact'}}});
		$self->{Campaign} = new Email::ConstantContact::Campaign($ccobj, { content => { 'Campaign' => $data->{'content'}->{'BounceEvent'}->{'Campaign'}}});
	}


	bless ($self, $class);
	return $self;
}

=head1 AUTHOR

Adam Rich, C<< <arich at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-email-constantcontact at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Email-ConstantContact>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Email::ConstantContact::CampaignEvent


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Email-ConstantContact>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Email-ConstantContact>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Email-ConstantContact>

=item * Search CPAN

L<http://search.cpan.org/dist/Email-ConstantContact/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009-2011 Adam Rich, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Email::ConstantContact::CampaignEvent

package Email::ConstantContact::Activity;

use warnings;
use strict;
use Carp;
use LWP::UserAgent;
use HTTP::Request::Common qw(POST GET);
use XML::Simple;
use XML::Writer;
use POSIX qw( strftime );

=head1 NAME

Email::ConstantContact::Activity - Internal class to interact with ConstantContact Activity Objects.

=head1 VERSION

Version 0.05

=cut

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw( );

$VERSION = '0.05';


=head1 SYNOPSIS

Activities are asynchronous requests used when the dataset is too large
to be handled gracefully in realtime.  For example, bulk uploads or
downloads of contact data.

This module is not typically used directly, but internally by the main
Email::ConstantContact object for processing requests.

    use Email::ConstantContact;

	my $apikey = 'ABCDEFG1234567';
    my $username = 'mycompany';
	my $password = 'topsecret';

    my $cc = new Email::ConstantContact($apikey, $username, $password);
    my @recent_activities = $cc->activities();

    foreach my $activity (@recent_activities) {
        print "Found recent activity, Type= ", $activity->{Type}, "\n";
	}

=cut

my @fields = qw (
	id Type Status FileName TransactionCount Error RunStartTime RunFinishTime InsertTime
);

sub new {
	my $class	= shift;
	my $ccobj	= shift;
	my $data	= shift;

	my $self  = {
		'_cc'		=> $ccobj,
		'Errors'	=> []
	};

	foreach my $field (@fields) {
		$self->{$field} = $data->{'content'}->{'Activity'}->{$field};
	}

	if (exists($data->{'link'}) && ref($data->{'link'})) {
		foreach my $link (@{$data->{'link'}}) {
			if ($link->{'rel'} eq 'edit') {
				$self->{'link'} = $link->{'href'};
			}
		}
	}

	if (exists($data->{'content'}->{'Activity'}->{'Errors'}) 
		&& ref($data->{'content'}->{'Activity'}->{'Errors'})) {
		$self->Errors = $data->{'content'}->{'Activity'}->{'Errors'};
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

    perldoc Email::ConstantContact::Activity


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

1; # End of Email::ConstantContact::Activity

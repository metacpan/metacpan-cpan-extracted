package Email::ConstantContact::List;

use warnings;
use strict;
use Carp;
use LWP::UserAgent;
use HTTP::Request::Common qw(POST GET);
use XML::Simple;
use XML::Writer;
use POSIX qw( strftime );

=head1 NAME

Email::ConstantContact::List - Internal class to interact with ConstantContact ContactList Objects.

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
	id OptInDefault DisplayOnSignup Name ShortName SortOrder
);

sub new {
	my $class	= shift;
	my $ccobj	= shift;
	my $data	= shift;
	my $self  = {'_cc' => $ccobj};

	foreach my $field (@fields) {
		$self->{$field} = $data->{'content'}->{'ContactList'}->{$field};
	}

	if (exists($data->{'link'}) && ref($data->{'link'})) {
		foreach my $link (@{$data->{'link'}}) {
			if ($link->{'rel'} eq 'edit') {
				$self->{'link'} = $link->{'href'};
			}
		}
	}

	bless ($self, $class);
	return $self;
}

sub remove {
	my $self = shift;

	my $ua = new LWP::UserAgent;
	my $url = lc($self->id);
	$url =~ s/^http:/https:/;

	my $req = new HTTP::Request('DELETE', $url);
	$req->authorization_basic($self->{'_cc'}->{apikey} . '%' . $self->{'_cc'}->{username}, $self->{'_cc'}->{password});
	$req->content_type('application/atom+xml');

	my $res = $ua->request($req);

	if ($res->code == 204) {
		# Delete is successful
		return 1;
	}
	else {
		carp "Contact List removal request returned code " . $res->status_line;
	}
}

sub save {
	my $self = shift;

	my $xmlcontent; 
	my $writer = new XML::Writer(OUTPUT => \$xmlcontent, DATA_MODE => 1, DATA_INDENT => 1);

	$writer->startTag('entry', 'xmlns' => 'http://www.w3.org/2005/Atom');
		$writer->dataElement('id', $self->{'id'});
		$writer->dataElement('title', $self->{'title'}, type => 'text');
		$writer->dataElement('author', '');
		$writer->dataElement('updated', strftime('%Y-%m-%dT%H:%M:%SZ', gmtime()));
		$writer->dataElement('summary', 'ContactList', type => 'text');
		$writer->startTag('content', 'type' => 'application/vnd.ctct+xml');
			$writer->startTag('ContactList', 'xmlns' => 'http://ws.constantcontact.com/ns/1.0/',
				'id' => $self->{'id'});

				foreach my $field (@fields) {
					$writer->dataElement($field, $self->{$field})
						if ($self->{$field});
				}

			$writer->endTag('ContactList');
		$writer->endTag('content');
	$writer->endTag('entry');
	$writer->end();

	my $ua = new LWP::UserAgent;
	my $url = lc($self->{'id'});
	$url =~ s/^http:/https:/;

	my $req = new HTTP::Request('PUT', $url);
	$req->authorization_basic($self->{'_cc'}->{apikey} . '%' . $self->{'_cc'}->{username}, $self->{'_cc'}->{password});
	$req->content_type('application/atom+xml');
	$req->content($xmlcontent);

	my $res = $ua->request($req);

	if ($res->is_success) {
		return 1;
	}
	else {
		carp "ContactList update request returned code " . $res->status_line;
	}

}

sub create {
	my $self = shift;

	my $xmlcontent; 
	my $writer = new XML::Writer(OUTPUT => \$xmlcontent, DATA_MODE => 1, DATA_INDENT => 1);

	$writer->startTag('entry', 'xmlns' => 'http://www.w3.org/2005/Atom');
		$writer->dataElement('id', 'data:,none');
		$writer->dataElement('title', '', type => 'text');
		$writer->dataElement('author', '');
		$writer->dataElement('updated', strftime('%Y-%m-%dT%H:%M:%SZ', gmtime()));
		$writer->dataElement('summary', 'ContactList', type => 'text');
		$writer->startTag('content', 'type' => 'application/vnd.ctct+xml');
			$writer->startTag('ContactList', 'xmlns' => 'http://ws.constantcontact.com/ns/1.0/');

				foreach my $field (@fields) {
					$writer->dataElement($field, $self->{$field})
						if ($self->{$field});
				}

			$writer->endTag('ContactList');
		$writer->endTag('content');
	$writer->endTag('entry');
	$writer->end();

	my $ua = new LWP::UserAgent;
	my $url = lc($self->{'_cc'}->{rooturl} . '/lists');
	my $req = new HTTP::Request('POST', $url);
	$req->authorization_basic($self->{'_cc'}->{apikey} . '%' . $self->{'_cc'}->{username}, $self->{'_cc'}->{password});
	$req->content_type('application/atom+xml');
	$req->content($xmlcontent);

	my $res = $ua->request($req);

	if ($res->code == 201) {
		# Create is successful
		my $xs = XML::Simple->new(KeyAttr => [], ForceArray => ['link','entry']);
		my $xmlobj = $xs->XMLin($res->content);
		my $newlist = new Email::ConstantContact::List($self->{'_cc'}, $xmlobj);
	
		$self = $newlist;
		return $newlist;
	}
	else {
		carp "Contact List creation request returned code " . $res->status_line;
		return wantarray? (): undef;
	}
}


=head1 AUTHOR

Adam Rich, C<< <arich at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-email-constantcontact at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Email-ConstantContact>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Email::ConstantContact::List


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

1; # End of Email::ConstantContact::List

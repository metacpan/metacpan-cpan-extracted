package Email::ConstantContact;

use warnings;
use strict;
use Carp;
use LWP::UserAgent;
use Email::ConstantContact::Resource;
use Email::ConstantContact::List;
use Email::ConstantContact::Contact;
use Email::ConstantContact::Activity;
use Email::ConstantContact::Campaign;
use HTTP::Request::Common qw(POST GET);
use URI::Escape;
use XML::Simple;

=head1 NAME

Email::ConstantContact - Perl interface to the ConstantContact API

=head1 VERSION

Version 0.05

=cut

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw( );

our $VERSION = '0.05';

=head1 SYNOPSIS

This module allows you to interact with the ConstantContact mass email 
marketing service from perl, such as creating and mainting contacts and
contact lists.

Before using this module, you must register your application with the
ConstantContact company, agree to their terms & conditions, and apply 
for an API access key.  You will use this key, in combination with a
ConstantContact username and password to interact with the service.

    use Email::ConstantContact;

    my $apikey = 'ABCDEFG1234567';
    my $username = 'mycompany';
    my $password = 'topsecret';

    my $cc = new Email::ConstantContact($apikey, $username, $password);

    # How to enumerate existing Contact Lists:
    my @all_lists = $cc->lists();
    foreach my $list (@all_lists) {
        print "Found list: ", $list->{Name}, "\n";
    }

    # How to create a new Contact List:
    my $new_list = $cc->newList('JAPH Newsletter', {
        SortOrder		=> '70',
        DisplayOnSignup		=> 'false',
        OptInDefault		=> 'false',
    });

    # How to add a new contact:
    my $new_contact = $cc->newContact('jdoe@example.com', {
        FirstName	=> 'John',
        LastName	=> 'Doe',
        CompanyName	=> 'JD Industries',
        ContactLists	=> [ $new_list ],
    });

    # How to modify existing contact:
    my $old_contact = $cc->getContact('yogi@example.com');
    print "Yogi no longer works for ", $old_contact->{CompanyName}, "\n";
    $old_contact->{CompanyName} = 'Acme Corp';

    # Enumerate List Membership
    print "Member of Lists: \n";
    foreach my $listid (@{ $old_contact->{ContactLists} }) {
        my $listobj = $cc->getList($listid);
        print $listobj->{Name}, "\n";
    }

    # Manage List Membership
    $old_contact->removeFromList($some_list_id);
    $old_contact->clearAllLists();
    $old_contact->addToList($new_list);
    $old_contact->save();

    # Opt-Out of all future emails
    $old_contact->optOut();
    $old_contact->save();

    # Display recent activities
    my @recent_activities = $cc->activities();

    foreach my $activity (@recent_activities) {
        print "Found recent activity, Type= ", $activity->{Type}, 
            "Status= ", $activity->{Status}, "\n";
    }

	# Obtain bounced email addresses.
	foreach my $camp ($cc->campaigns('SENT')) {
		foreach my $event ($camp->events('bounces')) {
			if ($event->{Code} eq 'B') {
				print "Bounced: ", $event->{Contact}->{EmailAddress}, "\n";
			}
		}
	}


=cut

sub new {
	my $class = shift;
	my $self  = {
		apikey		=> shift,
		username	=> shift,
		password	=> shift,
	};

	bless ($self, $class);

	$self->{cchome} = 'https://api.constantcontact.com';
	$self->{rooturl} = $self->{cchome} . '/ws/customers/' . uri_escape($self->{username});

	return $self;
}

sub getActivity {
	my $self = shift;
	my $activityname = shift;
	my $url = '';

	if ($activityname =~ /^http/) {
		#they passed in the actual REST link, so we can use it directly.
		$url = lc($activityname);
		$url =~ s/^http:/https:/;
	}
	else {
		#they passed in the list's ID string, we must construct the url.
		$url = lc($self->{rooturl} . '/activities/' . $activityname);
	}

	my $req = GET($url);
	$req->authorization_basic($self->{apikey} . '%' . $self->{username}, $self->{password});

	my $ua = new LWP::UserAgent;
	my $res = $ua->request($req);

	if ($res->code == 200) {
		my $xs = XML::Simple->new(KeyAttr => [], SuppressEmpty => 'undef',
			GroupTags => { Errors => 'Error' }, ForceArray => ['link','entry','Error']);
		my $xmlobj = $xs->XMLin($res->content);

		return new Email::ConstantContact::Activity($self, $xmlobj);
	}
	else {
		carp "Activity individual request returned code " . $res->status_line;
		return wantarray? (): undef;
	}
}

sub activities {
	my $self = shift;

	my $url = lc($self->{rooturl} . '/activities');
	my $req = GET($url);
	$req->authorization_basic($self->{apikey} . '%' . $self->{username}, $self->{password});

	my $ua = new LWP::UserAgent;
	my $res = $ua->request($req);
	my @activities;

	if ($res->code == 200) {
		my $xs = XML::Simple->new(KeyAttr => [], SuppressEmpty => 'undef',
			GroupTags => { Errors => 'Error' }, ForceArray => ['link','entry','Error']);
		my $xmlobj = $xs->XMLin($res->content);

		if (defined($xmlobj->{'entry'}) && ref($xmlobj->{'entry'})) {
			foreach my $subobj (@{$xmlobj->{'entry'}}) {
				push (@activities, new Email::ConstantContact::Activity($self, $subobj));
			}
		}
		return @activities;
	}
	else {
		carp "Activities request returned code " . $res->status_line;
		return wantarray? (): undef;
	}
}

sub newList {
	my $self = shift;
	my $list_name = shift;
	my $data = shift;

	my $new_list = new Email::ConstantContact::List($self);
	$new_list->{Name} = $list_name;
	$new_list->{SortOrder} = ($data && $data->{SortOrder}) ? $data->{SortOrder} : 1;
	$new_list->{DisplayOnSignup} = ($data && $data->{DisplayOnSignup}) ? $data->{DisplayOnSignup} : 'false';
	$new_list->{OptInDefault} = ($data && $data->{OptInDefault}) ? $data->{OptInDefault} : 'false';
	my $updated = $new_list->create();

	if ($updated->{id}) {
		return $updated;
	}
}

sub lists {
	my $self = shift;

	my $ua = new LWP::UserAgent;
	my @URLS = (lc($self->{rooturl} . '/lists'));
	my @lists;

	while (my $url = shift(@URLS)) {
		my $req = GET($url);
		$req->authorization_basic($self->{apikey} . '%' . $self->{username}, $self->{password});
		my $res = $ua->request($req);

		if ($res->code == 200) {
			my $xs = XML::Simple->new(SuppressEmpty => 'undef', KeyAttr => [], ForceArray => ['link','entry']);
			my $xmlobj = $xs->XMLin($res->content);

			if (defined($xmlobj->{'entry'}) && ref($xmlobj->{'entry'})) {
				foreach my $subobj (@{$xmlobj->{'entry'}}) {
					push (@lists, new Email::ConstantContact::List($self, $subobj));
				}
				if (defined($xmlobj->{'link'}) && ref($xmlobj->{'link'})) {
					foreach my $subobj (@{$xmlobj->{'link'}}) {
						if ($subobj->{'rel'} && ($subobj->{'rel'} eq "next")) {
							push (@URLS, $self->{cchome} . $subobj->{'href'});
						}
					}
				}
			}
		}
		else {
			carp "Contact Lists request returned code " . $res->status_line;
			return wantarray? (): undef;
		}
	}
	return @lists;
}

sub newContact {
	my $self = shift;
	my $email = shift;
	my $data = shift;

	my $new_contact = new Email::ConstantContact::Contact($self);
	$new_contact->{EmailAddress} = $email;
	$new_contact->{OptInSource} = ($data && $data->{OptInSource}) ? $data->{OptInSource} : 'ACTION_BY_CUSTOMER';

	if (exists($data->{'ContactLists'}) && ref($data->{'ContactLists'})) {
		foreach my $cl (@{$data->{'ContactLists'}}) {
			$new_contact->addToList($cl);
		}
	}
	delete $data->{'ContactLists'};

	foreach my $key (keys %$data) {
		$new_contact->{$key} = $data->{$key};
	}

	my $updated = $new_contact->create();

	if ($updated && $updated->{id}) {
		return $updated;
	}
}

sub contacts {
	my $self = shift;

	my $url = lc($self->{rooturl} . '/contacts');
	my $req = GET($url);
	$req->authorization_basic($self->{apikey} . '%' . $self->{username}, $self->{password});

	my $ua = new LWP::UserAgent;
	my $res = $ua->request($req);
	my @contacts;

	if ($res->code == 200) {
		my $xs = XML::Simple->new(KeyAttr => [], SuppressEmpty => 'undef',
			GroupTags => { ContactLists => 'ContactList' }, ForceArray => ['link','entry','ContactList']);
		my $xmlobj = $xs->XMLin($res->content);

		if (defined($xmlobj->{'entry'}) && ref($xmlobj->{'entry'})) {
			foreach my $subobj (@{$xmlobj->{'entry'}}) {
				push (@contacts, new Email::ConstantContact::Contact($self, $subobj));
			}
		}
		return @contacts;
	}
	else {
		carp "Contacts request returned code " . $res->status_line;
		return wantarray? (): undef;
	}
}

sub getContact {
	my $self = shift;
	my $contactname = shift;
	my $url = '';

	my $ua = new LWP::UserAgent;

	if ($contactname =~ /^http/) {
		#they passed in the actual REST link, so we can use it directly.
		$url = lc($contactname);
		$url =~ s/^http:/https:/;
	}
	elsif ($contactname =~ /@/) {
		#they passed in an email address, we must query for it.
		my $url1 = lc($self->{rooturl} . '/contacts?email=' . uri_escape($contactname));
		my $req1 = GET($url1);
		$req1->authorization_basic($self->{apikey} . '%' . $self->{username}, $self->{password});
		my $res1 = $ua->request($req1);

		unless ($res1->code == 200) {
			return wantarray? (): undef;
		}

		my $xs1 = XML::Simple->new(KeyAttr => [], SuppressEmpty => 'undef',
			GroupTags => { ContactLists => 'ContactList' }, ForceArray => ['link','entry','ContactList']);
		my $xmlobj1 = $xs1->XMLin($res1->content);

		unless (defined($xmlobj1->{'entry'}) && ref($xmlobj1->{'entry'})) {
			return wantarray? (): undef;
		}

		my $subobj1 = $xmlobj1->{'entry'}->[0];
		my $contact1 = new Email::ConstantContact::Contact($self, $subobj1);

		unless ($contact1 && $contact1->{'id'}) {
			return wantarray? (): undef;
		}

		$url = lc($contact1->{'id'});
		$url =~ s/^http:/https:/;
	}
	else {
		#they passed in the contact's ID number, we must construct the url.
		$url = lc($self->{rooturl} . '/contacts/' . $contactname);
	}

	my $req = GET($url);
	$req->authorization_basic($self->{apikey} . '%' . $self->{username}, $self->{password});

	my $res = $ua->request($req);

	if ($res->code == 200) {
		my $xs = XML::Simple->new(KeyAttr => [], SuppressEmpty => 'undef',
			GroupTags => { ContactLists => 'ContactList' }, ForceArray => ['link','entry','ContactList']);
		my $xmlobj = $xs->XMLin($res->content);

		return new Email::ConstantContact::Contact($self, $xmlobj);
	}
	else {
		carp "Contact individual request returned code " . $res->status_line;
		return wantarray? (): undef;
	}
}

sub getList {
	my $self = shift;
	my $listname = shift;
	my $url = '';

	if ($listname =~ /^http/) {
		#they passed in the actual REST link, so we can use it directly.
		$url = lc($listname);
		$url =~ s/^http:/https:/;
	}
	else {
		#they passed in the list's ID number, we must construct the url.
		$url = lc($self->{rooturl} . '/lists/' . $listname);
	}

	my $req = GET($url);
	$req->authorization_basic($self->{apikey} . '%' . $self->{username}, $self->{password});

	my $ua = new LWP::UserAgent;
	my $res = $ua->request($req);

	if ($res->code == 200) {
		my $xs = XML::Simple->new(SuppressEmpty => 'undef', KeyAttr => [], ForceArray => ['link','entry']);
		my $xmlobj = $xs->XMLin($res->content);

		return new Email::ConstantContact::List($self, $xmlobj);
	}
	else {
		carp "Contact List individual request returned code " . $res->status_line;
		return wantarray? (): undef;
	}
}

sub resources {
	my $self = shift;

	my $url = lc($self->{rooturl} . "/");
	my $req = GET($url);
	$req->authorization_basic($self->{apikey} . '%' . $self->{username}, $self->{password});

	my $ua = new LWP::UserAgent;
	my $res = $ua->request($req);
	my @resources;

	if ($res->code == 200) {
		my $xs = XML::Simple->new(SuppressEmpty => 'undef', KeyAttr => [], ForceArray => ['collection']);
		my $xmlobj = $xs->XMLin($res->content);

		if (defined($xmlobj->{'workspace'}->{'collection'}) && 
			ref($xmlobj->{'workspace'}->{'collection'})) {

			foreach my $subobj (@{$xmlobj->{'workspace'}->{'collection'}}) {
				push (@resources, new Email::ConstantContact::Resource($self, $subobj));
			}
		}
		return @resources;
	}
	else {
		carp "Service Document request returned code " . $res->status_line;
		return wantarray? (): undef;
	}

}

sub campaigns {
	my $self = shift;
	my $status = shift;

	my $url = lc($self->{rooturl} . '/campaigns' . ($status ? ('?status=' . $status) : ''));
	my $req = GET($url);
	$req->authorization_basic($self->{apikey} . '%' . $self->{username}, $self->{password});

	my $ua = new LWP::UserAgent;
	my $res = $ua->request($req);
	my @lists;

	if ($res->code == 200) {
		my $xs = XML::Simple->new(SuppressEmpty => 'undef', KeyAttr => [], ForceArray => ['link','entry']);
		my $xmlobj = $xs->XMLin($res->content);

		if (defined($xmlobj->{'entry'}) && ref($xmlobj->{'entry'})) {
			foreach my $subobj (@{$xmlobj->{'entry'}}) {
				push (@lists, new Email::ConstantContact::Campaign($self, $subobj));
			}
		}
		return @lists;
	}
	else {
		carp "Campaigns request returned code " . $res->status_line;
		return wantarray? (): undef;
	}
}

sub getCampaign {
	my $self = shift;
	my $campaignname = shift;
	my $url = '';

	if ($campaignname =~ /^http/) {
		#they passed in the actual REST link, so we can use it directly.
		$url = lc($campaignname);
		$url =~ s/^http:/https:/;
	}
	else {
		#they passed in the list's ID string, we must construct the url.
		$url = lc($self->{rooturl} . '/campaigns/' . $campaignname);
	}

	my $req = GET($url);
	$req->authorization_basic($self->{apikey} . '%' . $self->{username}, $self->{password});

	my $ua = new LWP::UserAgent;
	my $res = $ua->request($req);

	if ($res->code == 200) {
		my $xs = XML::Simple->new(KeyAttr => [], SuppressEmpty => 'undef',
			GroupTags => { Errors => 'Error' }, ForceArray => ['link','entry','Error']);
		my $xmlobj = $xs->XMLin($res->content);

		return new Email::ConstantContact::Campaign($self, $xmlobj);
	}
	else {
		carp "Campaign individual request returned code " . $res->status_line;
		return wantarray? (): undef;
	}
}

=head1 TODO

=over 4

=item * Implement method for enumerating members of a specified list.

=item * Implement method for enumerating contacts

=item * Implement method for enumerating campaign events per contact

=item * Implement method for enumerating campaign contacts per event

=item * Implement methods for bulk operations (import/export)

=back

=head1 AUTHOR

Adam Rich, C<< <arich at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-email-constantcontact at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Email-ConstantContact>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Email::ConstantContact


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


=head1 COPYRIGHT & LICENSE

Copyright 2009-2011 Adam Rich, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Email::ConstantContact

# $Id: easybank.pm,v 1.7 2004/05/02 11:39:52 florian Exp $

package Finance::Bank::easybank;

require 5.005_62;
use strict;
use warnings;

use Carp;
use WWW::Mechanize;
use HTML::TokeParser;
use constant {
	LOGIN_URL => 'https://ebanking.easybank.at//InternetBanking/InternetBanking?d=login&svc=EASYBANK&lang=de&ui=html',
};
use Class::MethodMaker
	new_hash_init => 'new',
	get_set       => [ qw/user pass _agent/ ],
	boolean       => [ qw/return_floats _connected/ ],
	list          => [ qw/accounts entries/ ];

our $VERSION = '1.05';


# login into the online banking system.
# fail if either user or password isn't defined.
#
# XXX: catch login errors.
sub _connect {
	my $self = shift;
	my $content;

	croak "Need user to connect.\n" unless $self->user;
	croak "Need password to connect.\n" unless $self->pass;

	$self->_agent(WWW::Mechanize->new);
	$self->_agent->agent_alias('Mac Safari');
	$self->_agent->get(LOGIN_URL);
	$self->_agent->form_number(1);
	$self->_agent->field('tn', $self->user);
	$self->_agent->field('pin', $self->pass);
	$self->_agent->click('Bsenden1');

	$content = $self->_agent->content;
	croak "The online banking system told me, that the user was not found.\n"
		if $content =~ /Der Verf&#252;ger ist nicht vorhanden/;
	croak "The online banking system told me, that the user or the password was invalid.\n"
		if $content =~ /Das Format der Verf&#252;gernummer oder des Passworts ist ung&#252;ltig/;
	croak "The online banking system told me, that the password was invalid.\n"
		if $content =~ /Ihre PIN ist falsch/;
    croak "There was a system error - please consult the hotline.\n"
        if $content =~ /Es ist ein Systemfehler aufgetreten/;
}


# fetches and parses the summary page for all given accounts.
# if no accounts have been defined, fetches and parses the summary
# displayed right after the login.
#
# returns a reference to a list of summary hashes.
sub check_balance {
	my $self = shift;
	my @accounts;

	# XXX: yeah, I'm lazy, but thats the easy way for a reset.
	$self->_connect;

	if($self->accounts_count > 0) {
		foreach my $account ($self->accounts) {
			$self->_select_account($account);
			push @accounts, $self->_parse_summary($self->_agent->content);
		}
	} else {
		push @accounts, $self->_parse_summary($self->_agent->content);
	}

	# return either a list with the accounts or a hashref
	# with the accountno. as key.
	return wantarray
		? @accounts
		: { map { $_->{account} => $_ } @accounts };
}


# fetches and parses the first entries page for all given accounts.
# if no accounts have been defined, fetches and parses the first
# entries page of the account displayed right after the login.
#
# returns a reference to a list of entry hashes.
sub get_entries {
	my $self = shift;
	my %accounts;
	my $accountno;
	my $entries;

	# XXX: yeah, I'm lazy, but thats the easy way for a reset.
	$self->_connect;

	# go to the entries page.
	$self->_agent->form_number(2);
	$self->_agent->click;

	if($self->entries_count > 0) {
		foreach my $account ($self->entries) {
			$self->_select_account($account);

			($accountno, $entries) = $self->_parse_entries($self->_agent->content);
			$accounts{$accountno} = $entries;
		}
	} else {
		($accountno, $entries) = $self->_parse_entries($self->_agent->content);
		$accounts{$accountno} = $entries;
	}

	\%accounts;
}


# selects given account ($account).
sub _select_account {
	my($self, $account) = @_;

	$self->_agent->form_number(1);
	$self->_agent->field('selected-account', $account);
	$self->_agent->click;
}


# parses given html ($content) containing the last 0 - 20 entries of an
# account and returns a hashref containing the single entries.
sub _parse_entries {
	my ($self, $content) = @_;
	my $stream           = HTML::TokeParser->new(\$content);
	my $accountno;
	my @data;

	$stream->get_tag('table') for 1 .. 3;
	$stream->get_tag('tr') for 1 .. 3;
	$stream->get_tag('td') for 1 .. 2;

	$accountno = $stream->get_trimmed_text('/td');

	$stream->get_tag('table') for 1 .. 2;
	$stream->get_tag('tr');

	# ugh...
	while(1) {
		my $nr;
		my %entry;

		$stream->get_tag('tr');
		$stream->get_tag('td');

		$nr = $stream->get_trimmed_text('/td');
		# end the loop if we find the first cell in a row which isn't a
		# numeric value (should be the first after the entries-table).
		last unless $nr =~ /^\d+$/;
		$entry{nr} = $nr;

		for(qw/date text/) {
			$stream->get_tag('td');
			$entry{$_} = $stream->get_trimmed_text('/td');
		}

		$stream->get_tag('td');

		for(qw/value currency amount/) {
			$stream->get_tag('td');
			$entry{$_} = $stream->get_trimmed_text('/td');
		}

		$entry{amount} = $self->_scalar2float($entry{amount})
			if $self->return_floats;

		push @data, \%entry;
	}

	($accountno, \@data);
}


# parses given html ($content) containing the summary of an account and
# returns a hashref containing the isolated data.
sub _parse_summary {
	my ($self, $content) = @_;
	my $stream           = HTML::TokeParser->new(\$content);
	my %data;

	$stream->get_tag('table') for 1 .. 2;
	$stream->get_tag('td');

	for(qw/bc account currency name date/) {
		$stream->get_tag('td');
		$data{$_} = $stream->get_trimmed_text('/td');
	}

	$stream->get_tag('table') for 1 .. 2;
	$stream->get_tag('b');
	$data{balance} = $stream->get_trimmed_text('/b');
	$stream->get_tag('b') for 1 .. 2;
	$data{final} = $stream->get_trimmed_text('/b');

	if($self->return_floats) {
		$data{$_} = $self->_scalar2float($data{$_}) for qw/balance final/;
	}

	\%data;
}


# converts given scalar ($scalar) into a float and returns it.
sub _scalar2float {
	my($self, $scalar) = @_;

	$scalar =~ s/\.//g;
	$scalar =~ s/,/\./g;

	return $scalar;
}


1;

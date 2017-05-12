# $Id: Bundesschatz.pm,v 1.3 2003/10/12 12:03:43 florian Exp $

package Finance::Bank::Bundesschatz;

require 5.005_62;
use strict;
use warnings;

use Carp;
use WWW::Mechanize;
use HTML::TokeParser;
use constant {
	LOGIN_URL => 'https://www.bundesschatz.at/ebss/kunde/pages/Logon.jsp',
};
use Class::MethodMaker
	new_hash_init => 'new',
	get_set       => [ qw/account pass coowner _agent/ ],
	boolean       => [ qw/return_floats _connected/ ];

our $VERSION = '1.01';


# login into the online banking system.
# fail if either account or password isn't defined.
#
# XXX: catch login errors.
sub _connect {
	my $self = shift;
	my $content;

	croak "Need account to connect.\n" unless $self->account;
	croak "Need password to connect.\n" unless $self->pass;

	$self->_agent(WWW::Mechanize->new);
	$self->_agent->agent_alias('Mac Safari');
	$self->_agent->get(LOGIN_URL);
	$self->_agent->form_number(1);
	$self->_agent->field('logon_user', $self->account);
	$self->_agent->field('logon_bnr', $self->coowner);
	$self->_agent->field('logon_passwd', $self->pass);
	$self->_agent->click('button_ok');

	$content = $self->_agent->content;

	croak "The online banking system told me, that the account or the password was invalid.\n"
		if $content =~ /Fehler: Bitte &uuml;berpr&uuml;fen Sie Ihre Kontonummer und Ihr Passwort/;

	# fail on everything which doesn't look like the Kontostand page.
	croak "It seems as if the online banking system want's your attention.\n" .
	      "Please login manually and take a look.\n"
		if $content !~ /Kontostand von:/;
}


# fetches and parses the summary page.
#
# returns a hashref containing the isolated data.
sub check_balance {
	my $self = shift;
	my $stream;
	my %data;

	defined $self->_agent or $self->_connect;

	$self->_agent->follow_link(url_regex => qr/Kontostand/);
	$stream = HTML::TokeParser->new(\($self->_agent->content));

	$stream->get_tag('form');
	$stream->get_tag('tr') for 1 .. 5;
	$stream->get_tag('td') for 1 .. 5;
	$data{balance} = $stream->get_trimmed_text('/td');

	$stream->get_tag('tr') for 1 .. 2;
	$stream->get_tag('td') for 1 .. 5;
	$data{interest} = $stream->get_trimmed_text('/td');

	if($self->return_floats) {
		$data{$_} = $self->_scalar2float($data{$_})
			for qw/balance interest/;
	}

	\%data;
}


# fetches and parses the detail page.
#
# returns a arrayref containing all entries.
sub get_details {
	my $self = shift;
	my $stream;
	my @entries;
	my $content;

	defined $self->_agent or $self->_connect;

	$self->_agent->follow_link(url_regex => qr/Kontodetails/);
	$content = $self->_agent->content;
	$content =~ /<!-- Data Rows -->(.*)<!-- Summen -->/s;
	$stream = HTML::TokeParser->new(\$1);

	while ($stream->get_tag('tr')) {
		my %data;

		$stream->get_tag('td') for 1 .. 5;
		$data{product} = $stream->get_trimmed_text('/td');

		$stream->get_tag('td') for 1 .. 2;
		($data{from}, $data{to}) =
			split / - /, $stream->get_trimmed_text('/td');

		for(qw/currency amount interest interest_amount
		       tax amount_after_tax/) {
			$stream->get_tag('td') for 1 .. 2;
			$data{$_} = $stream->get_trimmed_text('/td');
		}

		if($self->return_floats) {
			$data{$_} = $self->_scalar2float($data{$_})
				for qw/amount interest interest_amount
				       tax amount_after_tax/;
		}

		$stream->get_tag('/tr') for 1 .. 2;

		push @entries, \%data;
	}

	\@entries;
}


sub check_interest {
	my $self = shift;
	my @entries;
	my $stream;

	defined $self->_agent or $self->_connect;

	$self->_agent->follow_link(url_regex => qr/Zinschart/);
	$self->_agent->follow_link(url_regex => qr/Zinsentwicklung/);

	$stream = HTML::TokeParser->new(\($self->_agent->content));

	$stream->get_tag('/form');
	$stream->get_tag('table') for 1 .. 2;
	$stream->get_tag('tr') for 1 .. 3;

	while (1) {
		my %data;

		last unless $stream->get_tag('tr');

		$stream->get_tag('td') for 1 .. 3;
		$data{published} = $stream->get_trimmed_text('/td');
		$stream->get_tag('td') for 1 .. 4;
		$data{valid_on} = $stream->get_trimmed_text('/td');
		$stream->get_tag('td') for 1 .. 4;
		$data{interest_bs1} = $stream->get_trimmed_text('/td');
		$stream->get_tag('td') for 1 .. 4;
		$data{interest_bs2} = $stream->get_trimmed_text('/td');
		$stream->get_tag('td') for 1 .. 4;
		$data{interest_bs3} = $stream->get_trimmed_text('/td');

		if($self->return_floats) {
			$data{$_} = $self->_scalar2float($data{$_})
				for qw/interest_bs1 interest_bs2 interest_bs3/;
		}

		push @entries, \%data;
	}

	# remove the last element of the entries list because it's always
	# empty. well, kind of ugly, but i couldn't find another way.
	pop @entries;

	\@entries;
}


# converts given scalar ($scalar) into a float and returns it.
sub _scalar2float {
	my($self, $scalar) = @_;

	defined $scalar or return undef;

	$scalar =~ s/[\.%]//g;
	$scalar =~ s/,/\./g;

	$scalar;
}


1;

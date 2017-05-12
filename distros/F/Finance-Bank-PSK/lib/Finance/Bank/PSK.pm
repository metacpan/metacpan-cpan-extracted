# $Id: PSK.pm,v 1.8 2004/05/02 12:00:18 florian Exp $

package Finance::Bank::PSK;

require 5.005_62;
use strict;
use warnings;

use Carp;
use WWW::Mechanize;
use HTML::TokeParser;
use constant {
	LOGIN_URL  => 'https://wwwtb.psk.at/InternetBanking/sofabanking.html',
	DETAIL_URL => 'https://wwwtb.psk.at/InternetBanking/InternetBanking/?d=eus&kord=k%011d',
};
use Class::MethodMaker
	new_hash_init => 'new',
	get_set       => [ qw/ account user pass newline _agent / ],
	boolean       => 'return_floats';

our $VERSION = '1.04';


sub check_balance {
	my $self  = shift;

	$self->_connect;
	$self->_parse_summary($self->_agent->content);
}


sub get_entries {
	my $self  = shift;

	$self->_connect;
	$self->_agent->get(sprintf(DETAIL_URL, $self->account));
	$self->_agent->submit_form(form_number => 1);
	$self->_parse_entries($self->_agent->content);
}


sub _connect {
	my $self = shift;

	croak "Need account number to connect.\n" unless $self->account;
	croak "Need user to connect.\n" unless $self->user;
	croak "Need password to connect.\n" unless $self->pass;

	return if ref $self->_agent eq 'WWW::Mechanize';

	# XXX write tests using the demo account!
	#$self->_agent->follow('Demo');

	$self->_agent(WWW::Mechanize->new);
	$self->_agent->agent_alias('Mac Safari');
	$self->_agent->get(LOGIN_URL);
	$self->_agent->follow_link(n => 0);
	$self->_agent->form_number(1);
	$self->_agent->field('tn', $self->account);
	$self->_agent->field('vf', $self->user);
	$self->_agent->field('pin', $self->pass);
	$self->_agent->click('Submit');
}


sub _parse_entries {
	my($self, $content) = @_;
	my $newline         = $self->newline || '; ';
	my $stream;
	my @result;

	$content =~ s/<[Bb][Rr]>/$newline/go;
	$stream = HTML::TokeParser->new(\$content);

	# find and skip the table heading of the detail listing.
	for(my $i = 0; $i < 4;) {
		my $class = ($stream->get_tag('td'))->[1]{class};

		$i++ if defined $class and $class eq 'theader';
	}

	# now process the lines...
	while(my $row = $stream->get_tag('td')) {
		my $entry;

		last unless 
			exists $row->[1]{class} and
			$row->[1]{class} eq 'tdata';

		# get nr
		$entry->{nr} = $stream->get_text('/td');

		# get text
		$stream->get_tag('td');
		$entry->{text} = $stream->get_text('/td');
		$entry->{text} =~ s/($newline)$//;

		# get value date
		$stream->get_tag('td');
		$entry->{value} = $stream->get_text('/td');

		# get amount
		$stream->get_tag('td');
		$entry->{amount} = $stream->get_text('/td');
		$entry->{amount} = $self->_scalar2float($entry->{amount})
			if $self->return_floats;

		push @result, $entry;
	}

	@result;
}


sub _parse_summary {
	my($self, $content) = @_;
	my $stream = HTML::TokeParser->new(\$content);
	my %result;

	# get every interesting 'subtitle'.
	while($stream->get_tag('span')) {
		my %data;
		my $type = $stream->get_trimmed_text('/span');

		# catch girokontos.
		if($type eq 'Girokonto') {
			my $tmp;

			# get name, number and currency of the account.
			$stream->get_tag('a');
			$tmp = $stream->get_text('/a');
			(undef, $data{name}, undef, $tmp) = split(/\n/, $tmp);
			($data{account}, $data{currency}) = split(/\//, $tmp);

			$data{account} = $self->_cleanup($data{account});
			$data{name} = $self->_cleanup($data{name});

			# get the balance and the final balance of the account.
			for(qw/balance final/) {
				$stream->get_tag('table');
				$stream->get_tag('td') for 1 .. 2;

				$data{$_} = $stream->get_trimmed_text('/td');
				$data{$_} = $self->_scalar2float($data{$_}) if $self->return_floats;
			}

			push @{$result{accounts}}, \%data;
		# catch wertpapierdepots
		} elsif($type eq 'Wertpapierdepot') {
			# get name and number of the fund.
			$stream->get_tag('a');
			(undef, $data{name}, undef, $data{fund}) = split(/\n/, $stream->get_text('/a'));

			$data{fund} = $self->_cleanup($data{fund});
			$data{name} = $self->_cleanup($data{name});

			# get the balance of the fund.
			$stream->get_tag('table');
			$stream->get_tag('td');
			$data{currency} = $stream->get_trimmed_text('/td');

			$stream->get_tag('td');
			$data{balance} = $stream->get_trimmed_text('/td');
			$data{balance} = $self->_scalar2float($data{balance}) if $self->return_floats;

			push @{$result{funds}}, \%data;
		}

	}

	\%result;
}


sub _scalar2float {
	my($self, $scalar) = @_;

	$scalar =~ s/\.//g;
	$scalar =~ s/,/\./g;

	return $scalar;
}


sub _cleanup {
	my($self, $string) = @_;

	$string =~ s/^\s+//g;
	$string;
}


1;

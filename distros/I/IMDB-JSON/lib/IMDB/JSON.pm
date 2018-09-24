=head1 PACKAGE

IMDB::JSON

=head1 DESCRIPTION

Search IMDB for a specific title, process the result and extract the JSON script within. Process the JSON script and return a hash reference.

=cut

package IMDB::JSON;

$IMDB::JSON::VERSION = "0.01";

use strict;
use HTML::TokeParser;
use LWP::Simple qw($ua get);
use IO::Socket::SSL;
use JSON::XS;

=head1 SYNOPSIS

 use IMDB::JSON;
 use Data::Dumper;

 my $IMDB = IMDB::JSON->new;

 print Dumper($IMDB->search("The Thing", "1982));

 exit;


=head1 METHODS

=head2 new(opt => value);

Create a new IMDB::JSON object, options can be passed to the object by specifying them

=head3 OPTIONS

=over

=item base_url

The base URL to start from. This is usually https://www.imdb.com

=item raw_json

If true, returns only raw JSON text, it's not processed into an hash reference

=item user_agent

Set the User-Agent you want to send with the request

=item debug

If true, print debug messages to STDERR

=back

=cut

sub new {
	my ($CLASS, %o) = @_;
	return bless {
		base_url	=> ($o{base_url} ? $o{base_url} : 'https://www.imdb.com'),
		raw_json	=> ($o{raw_json} ? 1 : 0),
		user_agent	=> $o{user_agent},
		debug		=> $o{debug}
	};
}


sub _get { 
	my ($self, $URL) = @_; 
 
	$ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;  
	my $ua = LWP::UserAgent->new(
		ssl_opts => {
			verify_hostname => 0, 
			SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE, 
		}
	); 
 
	# Set the user agent to something
	$ua->agent($self->{user_agent}) if $self->{user_agent};
 
	print STDERR "DEBUG: fetch URL: $URL\n" if $self->{debug};

	my $req = HTTP::Request->new( GET => $URL); 
 
	my $response = $ua->request($req);

	return $response->content; 
}

#URI encoding
sub _enc {
	my ($self, $data) = @_;

	$data =~ s/([^a-zA-Z0-9_.-])/uc sprintf("%%%02x",ord($1))/eg;
	return $data;
}

# Process IMDB search results
sub _result {
	my ($self, $title, $year) = @_;

	my $data = $self->_get($self->{base_url} . '/search/title?title=' . $self->_enc($title) . '&release_date=' . $year . '-01-01,' . $year . '-12-31&view=simple');

	print STDERR "DEBUG: " . length($data) . " bytes of data received\n" if $self->{debug};

	return if !$data;

	my $url;

	# Process the results data (must be reference scalar!)
	my $p = HTML::TokeParser->new(\$data);

	# Walk down to the results section
	while(my $t = $p->get_tag('div')){
		last if($t->[1]->{class} eq 'lister-item mode-simple');
	}

	# Walk through the results and match the correct one
	while(my $t = $p->get_tag('span')){
		# Found a results chunk
		if($t->[1]->{class} eq "lister-item-header"){

			# Grab the href and text
			my $t = $p->get_tag('a');
			$url = $t->[1]->{href};

			# Grab the title and year
			my $txt = $p->get_trimmed_text;

			my $t = $p->get_tag('span');
			my $yr = $p->get_trimmed_text;

			# Check and see if they match
			if($title eq $txt && "($year)" eq $yr){
				return $url;
			} elsif($self->{debug}){
				print STDERR "DEBUG: result miss: $txt / $yr\n";
			}
		}
	}

	return;
}


sub search {
	my ($self, $title, $year) = @_;

	my $url = $self->_result($title, $year);

	return if !$url;

	my $data = $self->_get($url =~ /^https?:\/\// ? $url : $self->{base_url} . ($url =~ /^\// ? $url : '/' . $url));

	print STDERR "DEBUG: " . length($data) . " bytes of data received\n" if $self->{debug};

	return if !$data;

	my $p = HTML::TokeParser->new(\$data);

	while(my $t = $p->get_tag('script')){
		last if($t->[1]->{type} eq "application/ld+json");
	}

	my $json = $p->get_text;

	if(!$json){
		$@ = "JSON script not found!";
		print STDERR "DEBUG: $@\n" if $self->{debug};

		return;
	} else {
		return ($self->{raw_json} ? $json : decode_json($json));
	}
}

1;

=head1 AUTHOR

Colin Faber <cfaber@fpsn.net>

=head1 BUGS

Report all bugs on https://rt.cpan.org OR email me directly

=head1 COPYRIGHT

IMDB::JSON is Copyright (C) 2018, by Colin Faber.

It is free software; you can redistribute it and/or modify it under the terms of either:

a) the GNU General Public License as published by the Free Software Foundation; either version 1, or (at your option) any later version, or

b) the "Perl Artistic License". 

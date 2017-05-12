package Finance::Bank::Kraken;

#
# $Id: Kraken.pm 72 2014-06-02 11:25:16Z phil $
#
# Kraken API connector
# author, (c): Philippe Kueck <projects at unixadm dot org>
#

use strict;
use warnings;

use HTTP::Request;
use LWP::UserAgent;
use MIME::Base64;
use Digest::SHA qw(hmac_sha512_base64 sha256);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(Private Public);
our $VERSION = "0.3";
use constant Private => 1;
use constant Public => 0;

sub new {bless {'uri' => 'https://api.kraken.com', 'nonce' => time}, $_[0]}

sub key {
	return $_[0]->{'key'} unless $_[1];
	$_[0]->{'key'} = $_[1]
}

sub secret {
	return $_[0]->{'secret'} unless $_[1];
	$_[0]->{'secret'} = decode_base64($_[1])
}

sub call {
	my $self = shift;
	my $uripath = sprintf "/0/%s/%s", $_[0]?"private":"public", $_[1];
	my $req = new HTTP::Request($_[0]?'POST':'GET');
	my $ua = new LWP::UserAgent('agent' => "perl(Finance::Bank::Kraken) api client/".$VERSION);
	my $qry = defined $_[2]?(join "&", @{$_[2]}):undef;
	if ($_[0]) {
		$req->uri($self->{'uri'} . $uripath);
		$req->content(sprintf "nonce=%d%s", $self->{'nonce'}, defined $qry?"&$qry":"");
		$req->header("API-Key" => $self->{'key'});
		$req->header("API-Sign" => hmac_sha512_base64(
			$uripath . sha256($self->{'nonce'} . $req->content),
			$self->{'secret'})
		);  
		$self->{'nonce'}++
	} else {
		$req->uri(sprintf "%s%s%s", $self->{'uri'}, $uripath, defined $qry?"?$qry":"")
	}
	my $res = $ua->request($req);
	$res->is_success?$res->content:$res->status_line
}

1;

__END__

=head1 NAME

Finance::Bank::Kraken - api.kraken.com connector

=head1 VERSION

0.3

=head1 SYNOPSIS

 require Finance::Bank::Kraken;
 $api = new Finance::Bank::Kraken;
 $api->key($mykrakenkey);
 $api->secret($mykrakensecret);
 $result = $api->call(Private, $method, [$arg1, $arg2, ..]);

=head1 DESCRIPTION

This module allows to connect to the api of the bitcoin market Kraken.

Please see L<the Kraken API documentation|https://www.kraken.com/help/api> for a catalog of api methods.

=head1 METHODS

=over 4

=item $api = new Finance::Bank::Kraken

The constructor. Returns a C<Finance::Bank::Kraken> object.

=item $api->key($key)

Sets or gets the API key.

=item $api->secret($secret)

Sets the API secret to C<$secret> or returns the API secret base64 decoded.

=item $result = $api->call(Public, $method)

=item $result = $api->call(Private, $method)

=item $result = $api->call(Private, $method, [$param1, $param2, ..])

Calls the C<Public> or C<Private> API method C<$method> (with the given C<$params>, where applicable) and returns either the JSON encoded result string or an error message (C<code> C<message>).

=back

=head1 DEPENDENCIES

=over 8

=item L<HTTP::Request>

=item L<LWP::UserAgent>

=item L<MIME::Base64>

=item L<Digest::SHA>

=back

=head1 EXAMPLES

=head2 get current XLTC market price in EUR

 use Finance::Bank::Kraken;
 use JSON;
 
 my $kraken = new Finance::Bank::Kraken;
 my $res = $kraken->call(Public, 'Ticker', ['pair=XLTCZEUR,XXBTZEUR']);
 printf "1 XLTC is %f EUR\n",
         from_json($res)->{'result'}->{'XLTCZEUR'}->{'c'}[0]
         unless $res =~ /^5/;

=head2 get XLTC account balance

 use Finance::Bank::Kraken;
 use JSON;
 
 my $kraken = new Finance::Bank::Kraken;
 $kraken->key("mysupersecretkey");
 $kraken->secret("mysupersecretsecret");
 my $res = $kraken->call(Private, 'Balance');
 printf "balance: %f XLTC\n",
	from_json($res)->{'result'}->{'XLTC'} unless $res =~ /^5/;

=head1 Q&A

=over 8

=item Why does C<call> return a 404?

Probably you misspelled the method. Please check the API documentation and keep in mind the methods are case sensitive.

=item Why does C<call> return a 500?

Maybe there's a problem with the ssl chain of trust. Either install L<Mozilla::CA> or set (one of) the following environment variables C<PERL_LWP_SSL_CA_FILE>, C<HTTPS_CA_FILE>, C<PERL_LWP_SSL_CA_PATH>, C<HTTPS_CA_DIR>. See L<LWP::UserAgent> for details.

=back

=head1 AUTHOR and COPYRIGHT

Copyright Philippe Kueck <projects at unixadm dot org>

=cut


package Finance::btce;

use 5.012004;
use strict;
use warnings;
use JSON;
use LWP::UserAgent;
use Carp qw(croak);
use Digest::SHA qw( hmac_sha512_hex);
use WWW::Mechanize;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Finance::btce ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(BtceConversion BTCtoUSD LTCtoBTC LTCtoUSD getInfo) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(new);

our $VERSION = '0.1';

our $json = JSON->new->allow_nonref;

sub BTCtoUSD
{
	return BtceConversion('btc_usd');
}

sub LTCtoBTC
{
	return BtceConversion('ltc_btc');
}

sub LTCtoUSD
{
	return BtceConversion('ltc_usd');
}

sub BtceConversion
{
	my ($exchange) = @_;
	return _apiprice('Mozilla/4.76 [en] (Win98; U)', $exchange);
}
	

### Authenticated API calls

sub new
{
	my ($class, $args) = @_;
	if($args->{'apikey'} && $args->{'secret'})
	{
		#check for existence of keys
	}
	else
	{
		croak "You must provide an apikey and secret";
	}
	return bless $args, $class;
}

sub getInfo
{
	my ($self) = @_;
	my $mech = WWW::Mechanize->new();
	$mech->stack_depth(0);
	$mech->agent_alias('Windows IE 6');
	my $url = "https://btc-e.com/tapi";
	my $nonce = $self->_createnonce;
	my $data = "method=getInfo&nonce=".$nonce;
	my $hash = $self->_signdata($data);
	$mech->add_header('Key' => $self->_apikey);
	$mech->add_header('Sign' => $hash);
	$mech->post($url, ['method' => 'getInfo', 'nonce' => $nonce]);
	my %apireturn = %{$json->decode($mech->content())};

	return \%apireturn;
}

sub TransHistory
{
	my ($self, $args) = @_;
	my $data = "method=TransHistory&";
	my %arguments = %{$args};
	my $mech = WWW::Mechanize->new();
	$mech->stack_depth(0);
	$mech->agent_alias('Windows IE 6');
	my $url = "https://btc-e.com/tapi";
	my $nonce = $self->_createnonce;

	foreach my $key(keys %arguments)
	{
		$data += "$key=$arguments{$key}&";
	}
	$data += "nonce=".$nonce;
	my $hash = $self->_signdata($data);
	$mech->add_header('Key' => $self->_apikey);
	$mech->add_header('Sign' => $hash);
	$mech->post($url, ['method' => 'TransHistory', 'nonce' => $nonce]);
	my %apireturn = %{$json->decode($mech->content())};

	return \%apireturn;
}

#private methods

sub _apikey
{
	my ($self) = @_;
	return $self->{'apikey'};
}

sub _apiprice
{
	my ($version, $exchange) = @_;

	my $browser = Finance::btce::_newagent($version);
	my $resp = $browser->get("https://btc-e.com/api/2/".$exchange."/ticker");
	my $apiresponse = $resp->content;
	my %ticker;
	eval {
		%ticker = %{$json->decode($apiresponse)};
	};
	if ($@) {
		printf STDERR "ApiPirce(%s, %s): %s\n", $version, $exchange, $@;
		my %price;
		return \%price;
	}
	my %prices = %{$ticker{'ticker'}};
	my %price = (
		'updated' => $prices{'updated'},
		'last' => $prices{'last'},
		'high' => $prices{'high'},
		'low' => $prices{'low'},
		'avg' => $prices{'avg'},
		'buy' => $prices{'buy'},
		'sell' => $prices{'sell'},
	);

	return \%price;
}

sub _createnonce
{
	return time;
}

sub _secretkey
{
	my ($self) = @_;
	return $self->{'secret'};
}

sub _signdata
{
	my ($self, $params) = @_;
	return hmac_sha512_hex($params,$self->_secretkey);
}

sub _newagent
{
	my ($version) = @_;
	my $agent = LWP::UserAgent->new(ssl_opts => {verify_hostname => 1}, env_proxy => 1);
	if (defined($version)) {
		$agent->agent($version);
	}
	return $agent;
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Finance::btce - Perl extension for interfacing with the BTC-e bitcoin exchange

=head1 Version

Version 0.01

=head1 SYNOPSIS

  use Finance::btce;

  my $btce = Finance::btce->new({key => 'key', secret => 'secret',});

  #public API calls
  
  #Prices for Bitcoin to USD
  my %price = %{BTCtoUSD()};

  #Prices for Litecoin to Bitcoin
  my %price = %{LTCtoBTC()};
  
  #Prices for Litecoin to USD
  my %price = %{LTCtoUSD()};

  #Authenticated API Calls

  my %accountinfo = %{$btce->getInfo()};

=head2 EXPORT

None by default.

=head1 BUGS

Please report all bug and feature requests through github
at L<https://github.com/benmeyer50/Finance-btce/issues>

=head1 AUTHOR

Benjamin Meyer, E<lt>bmeyer@benjamindmeyer.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Benjamin Meyer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.


=cut

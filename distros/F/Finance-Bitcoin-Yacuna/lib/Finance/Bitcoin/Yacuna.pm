package Finance::Bitcoin::Yacuna;

#
# $Id: Yacuna.pm 2 2014-07-01 11:07:37Z martchouk $
#
# Yacuna API connector
# author, (c): Andrei Martchouk <andrei at yacuna dot com>
#

use strict;
no strict 'subs';
use warnings;

use WWW::Mechanize;
use HTTP::Request;
use MIME::Base64;
use Digest::SHA qw(sha512_hex);
use Data::Dump qw(dump);

require Exporter;
our @ISA = qw(Exporter);
our $VERSION = "0.1";

my $conf = {
	prod => {
		host => 'https://yacuna.com',
		basePath => '/api/',
		apiVersion => '1'
	},
	sandbox => {
		host => 'https://sandbox.yacuna.com',
		basePath => '/api/',
		apiVersion => '1'
	},
    debug => 0
};


sub new{
	my $type = shift;
	my %params = @_;
	my $httpClient = new WWW::Mechanize;
	if($params{'skipSSL'} && (int$params{'skipSSL'})>0){
		$httpClient->{'ssl_opts'} = {
			SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE,
			verify_hostname => 0, # this key is likely going to be removed in future LWP >6.04
		};
	} 

	my $config = {};

	$config = $params{'sandbox'} && (int$params{'sandbox'})>0 ? $conf->{'sandbox'} : $conf->{'prod'};

	$config->{debug} = $params{'debug'} && (int$params{'debug'})>0 ? $params{'debug'} : 0;

	bless{
		'uri' => $config->{'host'}, 
		'basePath' => $config->{'basePath'}, 
		'apiVersion' => $params{'apiVersion'} || $config->{'apiVersion'},
		'tokenId' => $params{'tokenId'}, 
		'secret'=> $params{'secret'}, 
		'SKIP_SSL'=>$params{'skipSSL'},
		'httpClient'=> $httpClient,
		'debug' => $config->{debug}
	}, 
	$type;
}

sub uri {
	return $_[0]->{'uri'} unless $_[1];
	$_[0]->{'uri'} = $_[1]
}

sub basePath {
	return $_[0]->{'basePath'} unless $_[1];
	$_[0]->{'basePath'} = $_[1]
}

sub apiVersion {
	return $_[0]->{'apiVersion'} unless $_[1];
	$_[0]->{'apiVersion'} = $_[1]
}

sub tokenId {
	return $_[0]->{'tokenId'} unless $_[1];
	$_[0]->{'tokenId'} = $_[1]
}

sub secret {
	return $_[0]->{'secret'} unless $_[1];
	$_[0]->{'secret'} = $_[1]
}

sub debug {
	return $_[0]->{'debug'} unless $_[1];
	$_[0]->{'debug'} = $_[1]
}

sub SKIP_SSL {
	return $_[0]->{'SKIP_SSL'} unless $_[1];
	$_[0]->{'SKIP_SSL'} = $_[1]
}

sub call {
	my $self = shift;
	my $httpMethod = $_[0];
	my $restPath = $_[1];

	eval{
		my $qry = defined $_[2] && scalar @{$_[2]}>0 ? (join "&", sort @{$_[2]}):undef;
		my $body = '';
		if('GET' eq $httpMethod){
			$restPath .= "?$qry" if defined $qry && '' ne $qry;
			print "\n$httpMethod ". $self->{'uri'}.$self->{'basePath'}.$self->{'apiVersion'}.'/'.$restPath if $self->{'debug'} > 0;
		}
		elsif('POST' eq $httpMethod){
			$body = $qry;
			print "\n$httpMethod ". $self->{'uri'}.$self->{'basePath'}.$self->{'apiVersion'}.'/'.$restPath."\n".$body if $self->{'debug'} > 0;
		}
		
		# authentication not needed for some public calls
		if(defined $self->{'secret'} && defined $self->{'tokenId'}){
			my $apiToken = &prepareAuth($self->{'basePath'}.$self->{'apiVersion'}.'/'.$restPath, $body, $httpMethod, $self->{'secret'}, $self->{'debug'});
			$self->{'httpClient'}->add_header( 'Api-Token-Id' => $self->{'tokenId'}, 'Api-Token' => $apiToken, 'Api-Token-OTP'=>'');
		}

		if('GET' eq $httpMethod){
			$self->{'httpClient'}->get($self->{'uri'} . $self->{'basePath'} . $self->{'apiVersion'}.'/'. $restPath);
		}
		elsif('POST' eq $httpMethod){
			my $req = new HTTP::Request('POST', $self->{'uri'} . $self->{'basePath'} . $self->{'apiVersion'}.'/'.$restPath);
			$req->content_type('application/x-www-form-urlencoded');
			$req->content($body);
			my $res = $self->{'httpClient'}->request($req);
			return $res->decoded_content;
		}

	};
	return $self->{'httpClient'}->response->decoded_content if $self->{'httpClient'}->response;
}

sub prepareAuth(){
	my ($path, $body, $httpMethod, $apiSecret, $debug) = @_;
	my $tokenSalt = ''.time*1000;
	my $hashInput = $tokenSalt.'@'.$apiSecret.'@'.$httpMethod.'@'.$path;
	$hashInput .= '@'.$body if '' ne $body;
	my $apiToken = $tokenSalt.'T'.(sha512_hex($hashInput));
    
    if(defined $debug && $debug > 0){
        print "\nhashInput => $hashInput \n";
        print "apiToken => $apiToken \n";
    }

	return $apiToken;
}

1;

__END__

=head1 NAME

Finance::Bitcoin::Yacuna - yacuna.com API connector

=head1 VERSION

0.1

=head1 SYNOPSIS

 use Finance::Bitcoin::Yacuna;

 my $yacuna = Finance::Bitcoin::Yacuna->new(
	tokenId => $apiTokenId, 
	secret => $apiSecret, 
	apiVersion => 1, # optional, default:1
	debug => 0, # optional, default:0
	skipSSL => 0, # optional, default:0
	sandbox => 0 # optional, default:0
 );

 $result = $yacuna->call($httpMethod, $restPath, ["param1=$param1", "param2=$param2", ..]);

 use Data::Dump qw(dump);
 use JSON;
 my $json = new JSON;
 dump $json->decode($result);

=head1 DESCRIPTION

The module to connect to the api of the bitcoin exchange Yacuna.

Please see L<Yacuna API documentation|http://docs.yacuna.com/api> for a catalog of api methods.

=head1 METHODS

=over 4

=item $yacuna = Finance::Bitcoin::Yacuna->new(
	tokenId => $apiTokenId, 
	secret => $apiSecret, 
	apiVersion => 1, # optional, default:1
	debug => 0, # optional, default:0
	skipSSL => 0, # optional, default:0
	sandbox => 0 # optional, default:0
 );

The constructor. Returns a C<Finance::Bitcoin::Yacuna> object.

=item $result = $yacuna->call($httpMethod, $restPath, ["param1=$param1", "param2=$param2", ..]);

Calls the API method C<$restPath> (with the given C<$params>, where applicable) and returns either undef or a JSON string.

=back

=head1 DEPENDENCIES

=over 8

=item L<WWW::Mechanize>

=item L<HTTP::Request>

=item L<MIME::Base64>

=item L<Digest::SHA>

=item L<Data::Dump>

=back

=head1 AUTHOR and COPYRIGHT

Copyright Andrei Martchouk <andrei at yacuna dot com>

=cut


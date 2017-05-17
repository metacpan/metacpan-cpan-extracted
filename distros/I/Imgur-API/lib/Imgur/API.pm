package Imgur::API;

use strict;
our $VERSION = "0.1.2";
our $ABSTRACT = "Perl Interface to Imgur API";
use feature qw(say);

use Imgur::API::Endpoint;
use Imgur::API::Exception;
use Imgur::API::Content;
use Imgur::API::Response;
use Imgur::API::Stats;
use Data::Dumper;
use LWP::UserAgent;
use HTTP::Message;
use HTTP::Request;
use JSON::XS;
use URI::Escape;

use Moo;

has client_secret=>(is=>'ro');
has client_id=>(is=>'ro',required=>1);
has access_token=>(is=>'rw');
has ua=>(is=>'ro',default=>sub { LWP::UserAgent->new(); });
has stats=>(is=>'rw',default=>sub { Imgur::API::Stats->new();});

sub request {
	my ($this,$path,$method,$params) = @_;

	$params->{_format}="json";

	$this->ua->agent("Imgur::API/0.0,1");

	my $auth;
	if ($this->access_token) {
		$auth="Bearer ".$this->access_token;
	} else {	
		$auth="Client-ID ".$this->client_id;
	}

	say STDERR $auth;

	my $response;
	if ($method=~/(?:post|put)/) {	
		$response = $this->ua->$method($path,$params,'Authorization'=>$auth);
	} else {
		$response = $this->ua->$method($path,'Authorization'=>$auth);
	}
	say Dumper($response);
	if ($response->content_type eq "application/json") {
		$this->stats->update($response);
		my $json = JSON::XS::decode_json($response->decoded_content);
		if  (!$json->{success}) {
			my $e =  Imgur::API::Exception->new(code=>$json->{status},message=>$json->{data}->{error});
			say Dumper($json);
		}
		
		return Imgur::API::Response->new($json);
	} else {
		return Imgur::API::Exception->new(code=>$response->code,message=>$response->status_line);
	}
}

sub content {
	my ($this,$what) = @_;

	if ($what=~/^http/i) {
		return $what;
	} elsif (-f $what) {
		return Imgur::API::Content->encode($what);
	}
}

sub account {
	my ($this) = shift;

	return Imgur::API::Endpoint::Account->new(dispatcher=>$this);
}
sub album {
	my ($this) = shift;

	return Imgur::API::Endpoint::Album->new(dispatcher=>$this);
}
sub comment {
	my ($this) = shift;

	return Imgur::API::Endpoint::Comment->new(dispatcher=>$this);
}
sub conversation {
	my ($this) = shift;

	return Imgur::API::Endpoint::Conversation->new(dispatcher=>$this);
}
sub custom_gallery {
	my ($this) = shift;

	return Imgur::API::Endpoint::Custom_gallery->new(dispatcher=>$this);
}
sub gallery {
	my ($this) = shift;

	return Imgur::API::Endpoint::Gallery->new(dispatcher=>$this);
}
sub image {
	my ($this) = shift;

	return Imgur::API::Endpoint::Image->new(dispatcher=>$this);
}
sub memegen {
	my ($this) = shift;

	return Imgur::API::Endpoint::Memegen->new(dispatcher=>$this);
}
sub notification {
	my ($this) = shift;

	return Imgur::API::Endpoint::Notification->new(dispatcher=>$this);
}
sub topic {
	my ($this) = shift;

	return Imgur::API::Endpoint::Topic->new(dispatcher=>$this);
}
sub misc {
    my ($this) = shift;

    return Imgur::API::Endpoint::Misc->new(dispatcher=>$this);
}
sub oauth {
	my ($this) = shift;

	return Imgur::API::Endpoint::OAuth->new(dispatcher=>$this);
}



1;

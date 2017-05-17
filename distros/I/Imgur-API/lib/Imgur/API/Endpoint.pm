package Imgur::API::Endpoint;

use strict;

use Imgur::API::Endpoint::Account;
use Imgur::API::Endpoint::Album;
use Imgur::API::Endpoint::Comment;
use Imgur::API::Endpoint::Conversation;
use Imgur::API::Endpoint::Custom_gallery;
use Imgur::API::Endpoint::Gallery;
use Imgur::API::Endpoint::Image;
use Imgur::API::Endpoint::Memegen;
use Imgur::API::Endpoint::Notification;
use Imgur::API::Endpoint::Topic;
use Imgur::API::Endpoint::Misc;
use Imgur::API::Endpoint::OAuth;

use Mouse;
use Data::Dumper;
use feature qw(say);

has dispatcher=>(is=>'ro');

sub dump {
	my ($this,$obj) = @_;

	say Dumper($obj);
}

sub path {
	my ($this,$base,$required,$optional,$params) = @_;
	
	my $main = sprintf($base,map {$params->{$_}} @$required);
	foreach (@$required) { delete $params->{$_}; }
	my @parts;
	foreach my $opt (@$optional) {
		if ($params->{$opt}) {
			push(@parts,$params->{$opt});
			delete $params->{$opt};
		} else {
			last OPTIONALS;
		}
	}
	if (scalar(@parts)) {
		return "https://api.imgur.com/".join("/",$main,join("/",@parts));
	} else {
		return "https://api.imgur.com/$main";
	}
}

1;
__PACKAGE__->meta->make_immutable;

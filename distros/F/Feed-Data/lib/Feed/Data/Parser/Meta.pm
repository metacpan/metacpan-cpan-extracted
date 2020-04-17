package Feed::Data::Parser::Meta;

use Moo;
extends 'Feed::Data::Parser::Base';
use XML::RSS::LibXML;
use Ref::Util ':all';
use Compiled::Params::OO qw/cpo/;
use Types::Standard qw/Object HashRef Str/;

our $validate;
BEGIN {
	$validate = cpo(
		get_value => [Object, HashRef, Str],
	);
}

has '+parser' => (
	default => sub {
		my $self = shift;
		my $content = $self->content_ref;
		my %match;
		while ($$content =~ s/\<meta(.*)\/\>//) {
			my $match = $1;
			$match =~ m/(name|property)\=\"([^"]+)/xms;
			my $name = [split ":", $2]->[1];
			$match =~ m/content\=\"([^"]+)/xms;
			my $value = $1;
			$match{$name} = $value unless $match{$name};
		}
		$match{link} = $match{url};
		$match{author} = $match{site_name} || $match{site};	
		return { items => [\%match] };
	},
);

sub get_value {
	my ($self, $item, $action) = $validate->get_value->(@_);
	my $value = $item->{$action};
	return $value // '';
}

1; # End of Feed::Data

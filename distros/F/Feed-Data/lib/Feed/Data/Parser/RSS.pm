package Feed::Data::Parser::RSS;

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
		return XML::RSS::LibXML->new->parse($self->content_ref);
	},
);

sub get_value {
	my ($self, $item, $action) = $validate->get_value->(@_);
   
	my $value = $item->{$action};

	if ( is_scalarref(\$value) || is_arrayref($value) ){
		return $value;
	}
	elsif ( is_hashref($value) ){
		return $value->{encoded};
	}
   
	return '';
}

1; # End of Feed::Data

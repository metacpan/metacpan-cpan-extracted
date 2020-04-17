package Feed::Data::Parser::Atom;

use Moo;
extends 'Feed::Data::Parser::Base';
use XML::Atom::Feed;
use Compiled::Params::OO qw/cpo/;
use Types::Standard qw/Object Str/;

our $validate;
BEGIN {
	$validate = cpo(
		get_value => [Object, Object, Str],
	);
}

has '+parser' => (
	default => sub {
		my $self = shift;
		return XML::Atom::Feed->new($self->content_ref);
	}
);

sub get_value {
	my ($self, $item, $action) = $validate->get_value->(@_);
	
	return $item->$action ? $item->$action : '';
}

1; # End of Feed::Data

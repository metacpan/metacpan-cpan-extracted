package Feed::Data::Parser::Table;

use Moo;
extends 'Feed::Data::Parser::Base';
use Compiled::Params::OO qw/cpo/;
use Types::Standard qw/Object HashRef Str/;
use HTML::TableContent;

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
		my $t = HTML::TableContent->new();
		$t->parse($$content);	
		return { items => $t->get_first_table->aoh };
	},
);

sub get_value {
	my ($self, $item, $action) = $validate->get_value->(@_);
	my $value = $item->{$action};
	return $value // '';
}

1; # End of Feed::Data

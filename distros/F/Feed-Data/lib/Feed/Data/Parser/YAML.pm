package Feed::Data::Parser::YAML;

use Moo;
extends 'Feed::Data::Parser::Base';
use Compiled::Params::OO qw/cpo/;
use Types::Standard qw/Object HashRef Str/;
use YAML::XS;

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
		my $matches = YAML::XS::Load $$content;
		return { items => $matches };
	},
);

has '+potential_fields' => (
	default => sub { 
		return {
			title => 'title',
			description => 'description',
			date => 'date',
			author => 'author',
			category => 'category',
			permalink => 'permalink',  
			comment => 'comment',
			link => 'link',
			content => 'content',
			image => 'image',
		};
	},
);

sub get_value {
	my ($self, $item, $action) = $validate->get_value->(@_);
	my $value = $item->{$action};
	return $value // '';
}

1; # End of Data::Feed

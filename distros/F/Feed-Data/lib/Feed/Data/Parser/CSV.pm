package Feed::Data::Parser::CSV;

use Moo;
extends 'Feed::Data::Parser::Base';
use Compiled::Params::OO qw/cpo/;
use Types::Standard qw/Object HashRef Str/;
use JSON;
use Text::CSV_XS qw/csv/;

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
		return { items => csv(in => $content, headers => "auto") };
	}
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

package Feed::Data::Parser::Text;

use Moo;
extends 'Feed::Data::Parser::Base';
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
		my (@matches, %match);
		while ($$content =~ s/([A-Za-z]+)\s*\:(.*)//) {
			if (defined $match{$1}) {
				push @matches, {%match};
				%match = ();
			}
			$match{$1} = $2;
		}
		push @matches, {%match};
		return { items => \@matches };
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

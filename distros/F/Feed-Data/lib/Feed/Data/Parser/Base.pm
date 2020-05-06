package Feed::Data::Parser::Base;

use Moo;
use Feed::Data::Object;
use Compiled::Params::OO qw/cpo/;
use HTML::LinkExtor;

use Types::Standard qw/Object ScalarRef Str HashRef ArrayRef/;

our $validate;
BEGIN {
	$validate = cpo(
		parse => [Object],
		first_image_tag => [Object, Str]
	);
}

has 'content_ref' => (
	is => 'rw',
	lazy => 1,
	isa => ScalarRef
	default => q{},
);

has 'parser' => (
	is => 'rw',
	isa => Object|HashRef,
	lazy => 1,
);

has 'potential_fields' => (
	is => 'rw',
	isa => HashRef,
	lazy => 1,
	default => sub { 
		return {
			title => 'title',
			description => 'description',
			date => 'pubDate',
			author => 'author',
			category => 'category',
			permalink => 'permaLink',  
			comment => 'comments',
			link => 'link',
			content => 'content',
			image => 'image',
		};
	},
);

has 'feed' => (
	is => 'rw',
	isa => ArrayRef,
	lazy => 1,
	default => sub { 
		my $self = shift;	
		my @feed;
		foreach my $item ( @{ $self->parser->{items} } ) {
			my %args;
			my $potential = $self->potential_fields;
			while (my ($field, $action) = each %{ $potential }) {
				my $value;
				if ($value = $self->get_value($item, $action)){
					$args{$field} = $value;
				}
				elsif ($action eq 'image') {
					my $content = $self->get_value($item, 'content');
					if ( $content ) {
						$value = $self->first_image_tag($content);
						$args{$field} = $value;
					}
					else {
						next;
					}
				}
			}
			my $object = Feed::Data::Object->new(object => \%args);
			push @feed, $object;
		}
		return \@feed;
	},
);

sub parse {
	my ($self) = $validate->parse->(@_);
	return $self->feed;
}

sub first_image_tag {
	my ($self, $content) = $validate->first_image_tag->(@_);
	my $p = HTML::LinkExtor->new;
	$p->parse($content);
	my @links = $p->links;
	for (@links) {
		my ($img, %attr) = @$_ if $_->[0] eq 'img';
		if ($img) {
			next if $attr{src} =~ m{twitter|facebook|google|pinterest|tumblr|linkedin};
			return $attr{src};
		}
	}
}

1; # End of Feed::Data

__END__

package Feed::Data::Parser;

use Moo;
use Carp qw/croak/;
use Feed::Data::Parser::RSS;
use Feed::Data::Parser::Atom;
use Feed::Data::Parser::Meta;
use Feed::Data::Parser::Text;
use Feed::Data::Parser::JSON;
use Feed::Data::Parser::CSV;

use Types::Standard qw/Object ScalarRef Str/;


our $VERSION = '0.01';

has 'stream' => (
	is  => 'ro',
	isa => ScalarRef,
	lazy => 1,
);

has 'parse_tag' => (
	is  => 'ro',
	isa => Str,
	lazy => 1,
	default => sub {
		my $self = shift;
		my $content = $self->stream;
		my $tag;
		if ($$content =~ m/^([A-Za-z]+)\s*\:/) {
			$tag = 'text';
		} elsif ($$content =~ m/^\s*\[/) {
			$tag = 'json';
		} elsif ($$content =~ m/^([A-Za-z]+,)/) {
			$tag = 'csv';
		} else {
			while ( $$content =~ /<(\S+)/sg) {
				(my $t = $1) =~ tr/a-zA-Z0-9:\-\?!//cd;
				my $first = substr $t, 0, 1;
				$tag = $t, last unless $first eq '?' || $first eq '!';
			}
		}
		croak 'Could not find the first XML element' unless $tag;
		$tag =~ s/^,*://;
		return $tag;
	}
);

has 'parser_type' => (
	is => 'ro',
	isa => Str,
	lazy => 1,
	default => sub {
		my $self = shift;
		my $tag = $self->parse_tag;
		return 'RSS' if $tag =~ /^(?:rss|rdf)$/i;
		return 'Atom' if $tag =~ /^feed/i;
		return 'Meta' if $tag =~ /^html/i;
		return 'Text' if $tag =~ /^text/;
		return 'JSON' if $tag =~ /^json/;
		return 'CSV' if $tag =~ /^csv/;
		return croak "Could not find a parser";
	}
);

has 'parse' => (
	is => 'ro',
	isa => Object,
	lazy => 1,
	default => sub {
		my $self = shift;
		my $type = $self->parser_type;
		my $class = "Feed::Data::Parser::" . $type;
		return $class->new(content_ref => $self->stream);
	}
);

1; # End of Feed::Data

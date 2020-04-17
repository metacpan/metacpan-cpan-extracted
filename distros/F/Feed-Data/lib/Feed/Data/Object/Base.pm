package Feed::Data::Object::Base;

use Moo;
use Feed::Data::Object;
use HTML::Strip;
use Encode qw(encode_utf8);
use Types::Standard qw/Undef Str/;

has 'raw' => (
	is => 'rw',
	lazy => 1,
	isa => Str|Undef
);

has 'text' => (
	is => 'rw',
	lazy => 1,
	isa => Str,
	default => sub {
		my $hs = HTML::Strip->new();
		my $string = $hs->parse(shift->raw);
		return encode_utf8($string);
	},
);

has 'json' => ( 
	is => 'rw',
	lazy => 1,
	isa => Str,
	default => sub { 
		return shift->text;
	},
);

1;

package Feed::Data::Object::Category;

use Moo;
extends 'Feed::Data::Object::Base';
use HTML::Strip;

our $VERSION = '0.01';

has '+raw' => (
    default => sub { [ ] },
);

has '+text' => ( 
    default => sub {
        my $hs = HTML::Strip->new();
        my $content = shift->raw;
        my $string = ref $content ? join ', ',  grep { $hs->parse($_) } @{ $content } : $content;
        return $string;
    } 
);

has 'json' => (
    is => 'rw',
    lazy => 1,
    default => sub {
        return shift->raw;
    },
);

1; # End of Feed::Data

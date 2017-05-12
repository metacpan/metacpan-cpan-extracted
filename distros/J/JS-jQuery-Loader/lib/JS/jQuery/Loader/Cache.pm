package JS::jQuery::Loader::Cache;

use Moose;
use JS::jQuery::Loader::Carp;

has template => qw/is ro required 1 lazy 1 isa JS::jQuery::Loader::Template/, default => sub {
    return shift->source->template
};
has source => qw/is ro required 1 isa JS::jQuery::Loader::Source/;

1;

package JS::YUI::Loader::Cache;

use Moose;
use JS::YUI::Loader::Carp;
has catalog => qw/is ro required 1 isa JS::YUI::Loader::Catalog lazy 1/, default => sub { shift->source->catalog };
has source => qw/is ro required 1 isa JS::YUI::Loader::Source/;

sub uri {
    return;
}

sub file {
    return;
}

1;


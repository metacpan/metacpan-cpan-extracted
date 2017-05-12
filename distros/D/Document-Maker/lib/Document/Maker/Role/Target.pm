package Document::Maker::Role::Target;

use strict;
use warnings;

use Moose::Role;

#requires qw/should_make freshness fresh make/;
#{ no strict 'refs'; *$_ = sub { confess "Abstract?" } for qw/should_make fresh freshness make/; }

1;

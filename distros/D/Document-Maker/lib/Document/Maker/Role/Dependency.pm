package Document::Maker::Role::Dependency;

use Moose::Role;
use Carp;

#requires qw/fresh freshness make/;
#{ no strict 'refs'; *$_ = sub { confess "Abstract?" } for qw/fresh freshness make/; }

1;

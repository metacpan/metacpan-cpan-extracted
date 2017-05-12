package Document::Maker::Role::Component;

use Moose::Role;

with qw/Document::Maker::Role::Logging/;

has maker => qw/is ro required 1 weak_ref 1/;

1;

package Doc::Simply::Document;

use Any::Moose;
use Doc::Simply::Carp;

use Doc::Simply::Parser;

has root => qw/is ro required 1 isa Doc::Simply::Parser::Node/;

has appendix => qw/is ro required 1 isa HashRef/, default => sub { {} };

1;

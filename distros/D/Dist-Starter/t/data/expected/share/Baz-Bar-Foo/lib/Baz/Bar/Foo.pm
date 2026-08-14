# Prefer numeric version for backwards compatibility
BEGIN { require 5.010000 }; ## no critic ( RequireUseStrict, RequireUseWarnings )
use strict;
use warnings;

#<<<
package Baz::Bar::Foo;
BEGIN {
our $VERSION = 'v0.1.0';
}
#>>>

no warnings 'void'; ## no critic ( ProhibitNoWarnings )
__PACKAGE__

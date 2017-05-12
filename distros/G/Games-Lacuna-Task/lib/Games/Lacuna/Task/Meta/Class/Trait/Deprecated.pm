# ============================================================================
package Games::Lacuna::Task::Meta::Class::Trait::Deprecated;
# ============================================================================

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose::Role;

sub deprecated { 1 }

no Moose::Role;

{
    package Moose::Meta::Class::Custom::Trait::Deprecated;
    use strict;
    use warnings;
    sub register_implementation { 'Games::Lacuna::Task::Meta::Class::Trait::Deprecated' }
}

1;
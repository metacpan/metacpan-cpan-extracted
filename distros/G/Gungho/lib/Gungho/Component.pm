# $Id: /mirror/gungho/lib/Gungho/Component.pm 8910 2007-11-12T01:05:01.438419Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Component;
use strict;
use warnings;
use base qw(Gungho::Base::Class);

sub feature_name
{
    my $class = shift;
    my $name = ref $class || $class;
    $name =~ s/^Gungho::Component:://;
    $name;
}

1;

__END__

=head1 NAME

Gungho::Component - Component Base Class For Gungho

=head1 SYNOPSIS

  package MyComponent;
  use base qw(Gungho::Component);

  # in your conf
  ---
  components:
    - +MyComponent
    - Authentication::Basic

=head1 DESCRIPTION

Gungho::Component is yet another way to modify Gungho's behavior. It differs
from plugins in that it adds directly to Gungho's internals via subclassing.
Plugins are called from various hooks, but components can directly interfere
and/or add functionality to Gungho.

To add a new component, just create a Gungho::Component subclass, and add
it in your config. Gungho will ensure that it is loaded and setup.

=head1 METHODS

=head2 feature_name()

Returns the name of the feature that this component provides. By default
it's the package name with "Gungho::Component::" stripped out.

=cut




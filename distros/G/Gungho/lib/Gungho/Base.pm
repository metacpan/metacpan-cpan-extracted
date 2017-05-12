# $Id: /mirror/gungho/lib/Gungho/Base.pm 31143 2007-11-27T06:57:15.188797Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Base;
use strict;
use warnings;
use base qw(Gungho::Base::Class Class::Accessor::Fast);

__PACKAGE__->mk_accessors($_) for qw(config);

sub new
{
    my $class  = shift;
    my $self = bless { @_ }, $class;
    return $self;
}

sub mk_virtual_methods
{
    my $class = shift;
    foreach my $method (@_) {
        my $slot = "${class}::${method}";
        {
            no strict 'refs';
            *{$slot} = sub { die(ref($_[0]) . "::${method} is not overridden") };
        }
    }
}

1;

__END__

=head1 NAME

Gungho::Base - Base Class For Various Gungho Objects

=head1 SYNOPSIS

  package Gungho::Something;
  use base qw(Gungho::Base);

=head1 MMETHODS

=head2 new(\%config)

Creates a new object instance. Takes a config hashref. 

=head2 setup()

Sets up the object. Use it like this in your object:

  sub setup
  {
     my $self = shift;
     # do custom setup
     $self->next::method(@_);
  }

=head2 mk_virtual_methods

Creates virtual methods (methods that must be overridden).
These methods will C<die()> unless you provide an implementation in your
subclass

=cut

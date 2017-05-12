# $Id: /mirror/gungho/lib/Gungho/Base/Class.pm 8892 2007-11-10T14:11:01.888849Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Base::Class;
use strict;
use base qw(Class::Data::Inheritable);
use Class::C3;

sub setup {}

1;

__END__

=head1 NAME

Gungho::Base::Class - Base For Classes That Won't Be Instantiated

=head1 SYNOPSIS

  package Gungho;
  use base qw(Gungho::Base::Class);

=head1 DESCRIPTION

This is a silly module, here only because Gungho used to be instance-based
and yet change to class-only after realizing you can't have multiple instances
of, for example, POE based Gungho objects and/or Danga::Socket based objects.

You usually don't need to know about this module.

=head1 METHODS

=head2 setup

=cut

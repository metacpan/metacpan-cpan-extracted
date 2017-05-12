#
#    timed.pm: Fwctl service module to handle the tftp protocol.
#
#    This file is part of Fwctl.
#
#    Author: Francis J. Lacoste <francis.lacoste@iNsu.COM>
#
#    Copyright (c) 1999,2000 iNsu Innovations Inc.
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
package Fwtcl::Services::tftp;

use strict;

use vars qw(@ISA);

BEGIN {
  require Exporter;

  @ISA = qw( Fwctl::Services::udp_service);

}

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = $class->SUPER::new(@_);
  $self->{port} = "tftp";
  bless $self,$class;
}

1;

=pod

=head1 NAME

Fwctl::Services::all - Fwctl module to handle tftp protocol.

=head1 SYNOPSIS

    deny   tftp 

=head1 DESCRIPTION

Service module to handle tftp protocol.

=head1 AUTHOR

Francis J. Lacoste <francis.lacoste@iNsu.COM>

=head1 COPYRIGHT

Copyright (c) 1999,2000 iNsu Innovations Inc.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

=head1 SEE ALSO

fwctl(8) Fwctl(3) Fwctl::RuleSet(3)

=cut


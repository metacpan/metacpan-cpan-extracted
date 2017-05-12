#
#    hylafax.pm: Fwctl service module to handle the hylafax protocol.
#
#    This file is part of Fwctl.
#
#    Author: Francis J. Lacoste <francis@iNsu.COM>
#
#    Copyright (c) 1999,2000 iNsu Innovations Inc.
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
package Fwctl::Services::hylafax;

use strict;

use vars qw( @ISA );

use Fwctl::RuleSet qw( :ports);
use Fwctl::Services::ftp;

use Carp;

BEGIN {
    @ISA = qw( Fwctl::Services::ftp );
}

sub new {
  my $proto = shift;
  my $class = ref $proto || $proto;
  my $ctrl = getservbyname( "hylafax", "tcp");
  $ctrl ||= 4559;
  my $data = $ctrl - 1 ;
  bless { pasv_ports	=> UNPRIVILEGED_PORTS,
	  pasv		=> 1,
	  port		=> 1,
	  data_port	=> $data,
	  ctrl_port	=> $ctrl,
	}, $class;
}

sub valid_options {
  my  $self = shift;
  ();
}

1;
=pod

=head1 NAME

Fwctl::Services::hylafax - Fwctl module to handle the HylaFax protocol.

=head1 SYNOPSIS

    accept   hylafax -src INTERNAL_NET -dst INT_IP

=head1 DESCRIPTION

The hylafax module is used to handle the HylaFAX protocol which is
a variant of the FTP protocol.

=head1 OPTIONS

No service specific options.

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


package IO::Socket::PortState::cPanel;

use strict;
use warnings;
use IO::Socket::PortState;

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = qw(check_ports check_inbound check_outbound $inbound $outbound);

our $VERSION = '0.02';

our $inbound = { 
   tcp => {
      20 => {
         name => 'FTP'
      },
      21 => {
         name => 'FTP'
      },
      22 => {
         name => 'SSH'
      },
      25 => {
         name => 'SMTP'
      },
      26 => {
         name => 'SMTP'
      },
      53 => {
         name => 'DNS'
      },
      80 => {
         name => 'HTTP'
      },
      110 => {
         name => 'POP3'
      },
      143 => {
         name => 'imap4'
      },
      443 => {
         name => 'HTTPS'
      },
      465 => {
         name => 'SMTP TLS/SSL'
      },
      993 => {
         name => 'imap4 SSL'
      },
      995 => {
         name => 'POP3 SSL'
      },
      2082 => {
         name => 'cPanel'
      },
      2083 => {
         name => 'cPanel SSL'
      },
      2086 => {
         name => 'WHM'
      },
      2087 => {
         name => 'WHM SSL'
      },
      2095 => {
         name => 'Webmail'
      },
      2096 => {
         name => 'Webmail SSL'
      },
      3306 => {
         name => 'MySQL'
      },
      6666 => {
         name => 'chat'
      }
   },
   udp => {
      21 => {
         name => 'FTP'
      },
      53 => {
         name => 'DNS'
      },
      465 => {
         name => 'SMTP TLS/SSL'
      },
      873 => {
         name => 'rsync'
      }
   }
};

our $outbound = {
   tcp => {
      21 => {
         name => 'FTP',
      },
      25 => {
         name => 'SMTP'
      },
      26 => {
         name => 'SMTP'
      },
      37 => {
         name => 'rdate'
      },
      43 => {
         name => 'whois'
      },
      53 => {
         name => 'DNS'
      },
      80 => {
         name => 'HTTP'
      },
      113 => {
         name => 'ident'
      },
      465 => {
         name => 'SMTP TLS/SSL'
      },
      873 => {
         name => 'rsync'
      },
      2089 => {
         name => 'cplisc'
      },
      3306 => {
         name => 'MySQL'
      }
   },
   udp => {
      20 => {
         name => 'FTP'
      },
      21 => {
         name => 'FTP'
      },
      53 => {
         name => 'DNS'
      },
      465 => {
         name => 'SMTP TLS/SSL'
      },
      873 => {
         name => 'rsync'
      }
   }
};

sub check_ports { IO::Socket::PortState::check_ports(@_) }

sub check_inbound { IO::Socket::PortState::check_ports(shift(), shift(), $inbound, @_) }

sub check_outbound { IO::Socket::PortState::check_ports(shift(), shift(), $outbound, @_) }

1;

__END__

=head1 NAME

IO::Socket::PortState::cPanel - Perl extension for checking if all the ports a cPanel server uses is open.

=head1 SYNOPSIS

  use IO::Socket::PortState::cPanel qw(check_inbound);
  my $hr = check_inbound($host,$timeout);

=head1 DESCRIPTION

Simplify IO::Socket::PortState use with cPanel servers. (L<http://cpanel.net/>)

=head2 $inbound

Hashref of inbound ports suitable for use with IO::Socket::PortState::check_ports()

=head2 $outbound

Hashref of outbound ports suitable for use with IO::Socket::PortState::check_ports()

This would only make sense if you were running this check on the server that you were 
checking outbound ports on and use a host that does have those ports open :)

=head2 check_ports()

Its IO::Socket::PortState::check_ports()

=head2 check_inbound()

Shortcut to check_ports() but uses the $inbound for the hashref.

These are identicle:

   my $hr = check_inbound($host, $timeout, [\&handler]);
   my $hr = check_ports($host, $timeout, $inbound, [\&handler]);

=head2 check_outbound()

Shortcut to check_ports() but uses the $outbound for the hashref.

These are identicle:

   my $hr = check_outbound($host, $timeout, [\&handler]);
   my $hr = check_ports($host, $timeout, $outbound, [\&handler]);

=head1 EXPORT

None by default. check_inbound check_outbound check_ports $inbound $outbound are all exportable.

=head1 SOURCE OF DATA

Directly from cPanel Inc Developers

=head1 ABOUT THIS MODULE

This module should be used as a paradigm for creating similar modules so that their use will be consistent.
Please use the source of this module as your template (changeing the hash contents, package, and POD to reflect your catagory)
If you do please mention that your module is based on this one in the POD, in the "ABOUT THIS MODULE" section like so:

   "This module is based on Daniel Muey's L<IO::Socket::PortState::cPanel> module."

The 5 exportable items in this module should be included in your module and any other 
hashref's you included should have a corresponding check_* function.

=head1 SEE ALSO

L<IO::Socket::PortState>

=head1 AUTHOR

Daniel Muey, L<http://drmuey.com/cpan_contact.pl>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Daniel Muey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

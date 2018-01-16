#
# $Id: Sqlmap.pm,v 6fa51436f298 2018/01/12 09:27:33 gomor $
#
# network::sqlmap Brik
#
package Metabrik::Network::Sqlmap;
use strict;
use warnings;

use base qw(Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision: 6fa51436f298 $',
      tags => [ qw(unstable security scan vulnerability vuln scanner sql injection blind) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         cookie => [ qw(string) ],
         parameter => [ qw(parameter_name) ],
         request_file => [ qw(file) ],
         args => [ qw(sqlmap_arguments) ],
         output => [ qw(file) ],
      },
      attributes_default => {
         request_file => 'sqlmap_request.txt',
         parameter => 'parameter',
         args => '--ignore-proxy -v 3 --level=5 --risk=3 --user-agent "Mozilla"',
      },
      commands => {
         install => [ ], # Inherited
         start => [ ],
      },
      need_packages => {
         ubuntu => [ qw(python python-pip) ],
         debian => [ qw(python python-pip) ],
      },
   };
}

# python /usr/share/sqlmap-dev/sqlmap.py -p PARAMETER -r /root/XXX/outil_sqlmap/request.raw --ignore-proxy -v 3 --level=5 --risk=3 --user-agent "Mozilla" 2>&1 | tee /root/XXX/outil_sqlmap/XXX.txt
sub start {
   my $self = shift;

   my $datadir = $self->datadir;
   my $args = $self->args;
   my $cookie = $self->cookie;
   my $parameter = $self->parameter;
   my $request_file = $datadir.'/'.$self->request_file;
   my $output = $datadir.'/'.$self->output;

   $self->brik_help_run_file_not_found('start', $request_file) or return;

   my $cmd = "sqlmap -p $parameter $args -r $request_file";
   if (defined($output)) {
      $cmd .= ' 2>&1 | tee '.$output;
   }

   system($cmd);

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Network::Sqlmap - network::sqlmap Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

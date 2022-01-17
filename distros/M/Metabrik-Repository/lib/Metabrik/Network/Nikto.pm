#
# $Id$
#
# network::nikto Brik
#
package Metabrik::Network::Nikto;
use strict;
use warnings;

use base qw(Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable security scanner vulnerability vuln scan) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         uri => [ qw(uri) ],
         args => [ qw(nikto_arguments) ],
         output => [ qw(output_file.html) ],
      },
      attributes_default => {
         uri => 'http://127.0.0.1/',
         args => '-Display V -Format html',
         output => 'last.html',
      },
      commands => {
         install => [ ], # Inherited
         start => [ qw(uri|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::String::Uri' => [ ],
      },
      require_binaries => {
         'nikto' => [ ],
      },
      need_packages => {
         ubuntu => [ qw(nikto) ],
         debian => [ qw(nikto) ],
         kali => [ qw(nikto) ],
      },
   };
}

sub _nikto_parse {
   my $self = shift;
   my ($cmd, $result) = @_;

   my $parsed = {};

   push @{$parsed->{raw}}, $cmd;

   for (split(/\n/, $result)) {
      push @{$parsed->{raw}}, $_;
   }

   return $parsed;
}

# nikto -host XXX.com -root /XXX -Display V -port 443 -ssl -Format html -output /root/XXX/outil_nikto/XXX_nikto_https.html 2>&1 | tee /root/XXX/outil_nikto/XXX_nikto_https.txt
# nikto -host 127.0.0.1 -port 80 -root /path -Display V -Format html -ssl -output /home/gomor/metabrik/nikto.html
sub start {
   my $self = shift;
   my ($uri, $output) = @_;

   $output ||= $self->output;
   $uri ||= $self->uri;
   $self->brik_help_run_undef_arg('start', $uri) or return;

   my $su = Metabrik::String::Uri->new_from_brik_init($self) or return;
   my $p = $su->parse($uri) or return;

   my $host = $p->{host};
   my $port = $p->{port};
   my $path = $p->{path};
   my $use_ssl = $su->is_https_scheme($p);

   my $args = $self->args;

   my $datadir = $self->datadir;
 
   my $cmd = "nikto -host $host -port $port -root $path $args";
   if ($use_ssl) {
      $cmd .= " -ssl";
   }

   $cmd .= " -output $datadir/$output 2>&1 | tee $datadir/$output.txt";

   my $result = `$cmd`; 

   my $parsed = $self->_nikto_parse($cmd, $result);

   return $parsed;
}

1;

__END__

=head1 NAME

Metabrik::Network::Nikto - network::nikto Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

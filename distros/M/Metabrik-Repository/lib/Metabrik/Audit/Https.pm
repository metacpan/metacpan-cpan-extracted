#
# $Id: Https.pm,v 6fa51436f298 2018/01/12 09:27:33 gomor $
#
# audit::https Brik
#
package Metabrik::Audit::Https;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision: 6fa51436f298 $',
      tags => [ qw(unstable ssl openssl) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         uri => [ qw(uri) ],
      },
      commands => {
         check_ssl3_support => [ qw(uri|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::String::Uri' => [ ],
      },
      require_binaries => {
         'printf' => [ ],
         'openssl' => [ ],
      },
   };
}

#
# Poodle: http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2014-3566
#
sub check_ssl3_support {
   my $self = shift;
   my ($uri) = @_;

   $uri ||= $self->uri;
   $self->brik_help_run_undef_arg('check_ssl3_support', $uri) or return;

   if ($uri !~ /^https:\/\//) {
      return $self->log->error("check_ssl3_support: uri [$uri] invalid format");
   }

   my $su = Metabrik::String::Uri->new_from_brik_init($self) or return;

   my $hash = $su->parse($uri) or return;

   my $host = $hash->{host};
   my $port = $hash->{port};

   my $cmd = "printf \"GET / HTTP/1.0\r\n\r\n\" | openssl s_client -host $host -port $port -ssl3";

   $self->as_array(1);
   $self->as_matrix(0);
   $self->capture_stderr(1);
   my $buf = $self->capture($cmd) or return;

   my $check = {
      ssl_version3_support => 1,
      cmd => $cmd,
      raw => $buf,
   };
   for (@$buf) {
      if (/sslv3 alert handshake failure/s) {
         $check->{ssl_version3_support} = 0;
         last;
      }
   }

   return $check;
}

1;

__END__

=head1 NAME

Metabrik::Audit::Https - audit::https Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

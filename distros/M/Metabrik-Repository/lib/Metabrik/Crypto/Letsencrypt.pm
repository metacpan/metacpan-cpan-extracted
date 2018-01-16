#
# $Id: Letsencrypt.pm,v 6fa51436f298 2018/01/12 09:27:33 gomor $
#
# crypto::letsencrypt Brik
#
package Metabrik::Crypto::Letsencrypt;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision: 6fa51436f298 $',
      tags => [ qw(experimental ssl certificate x509 tls cert) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
      },
      commands => {
         install => [ ], # Inherited
         certonly => [ qw(domain|$domain_list email|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::Devel::Git' => [ ],
      },
   };
}

sub install {
   my $self = shift;

   my $datadir = $self->datadir;
   my $directory = $datadir.'/letsencrypt';

   my $dg = Metabrik::Devel::Git->new_from_brik_init($self) or return;
   $dg->clone('https://github.com/letsencrypt/letsencrypt', $directory) or return;

   return $self->system("$directory/letsencrypt-auto --help");
}

#
# https://letsencrypt.readthedocs.org/en/latest/using.html
#
sub certonly {
   my $self = shift;
   my ($domains, $email) = @_;

   $self->brik_help_run_undef_arg('certonly', $domains) or return;
   my $ref = $self->brik_help_run_invalid_arg('certonly', $domains, 'ARRAY', 'SCALAR')
      or return;

   my $bin = $self->datadir.'/letsencrypt/letsencrypt-auto';

   my $cmd = "$bin certonly --manual --agree-tos";

   if (defined($email)) {
      $cmd .= " --email $email";
   }

   if ($ref eq 'ARRAY') {
      for (@$domains) {
         $cmd .= " -d $_";
      }
   }
   else {  # SCALAR
      $cmd .= " -d $domains";
   }

   $self->log->verbose("certonly: cmd[$cmd]");

   return $self->system($cmd);
}

1;

__END__

=head1 NAME

Metabrik::Crypto::Letsencrypt - crypto::letsencrypt Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

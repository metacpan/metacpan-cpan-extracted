#
# $Id$
#
# password::rockyou Brik
#
package Metabrik::Password::Rockyou;
use strict;
use warnings;

use base qw(Metabrik::Client::Www);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
      },
      attributes_default => {
      },
      commands => {
         update => [ ],
      },
      require_modules => {
         'Metabrik::File::Compress' => [ ],
      },
   };
}

#
# More password lists are available at: 
# http://downloads.skullsecurity.org/passwords/
#
sub update {
   my $self = shift;

   my @urls = qw(
      https://downloads.skullsecurity.org/passwords/rockyou.txt.bz2
      https://downloads.skullsecurity.org/passwords/rockyou-withcount.txt.bz2
   );

   my $datadir = $self->datadir;

   my $fc = Metabrik::File::Compress->new_from_brik_init($self) or return;
   $fc->datadir($datadir);

   my @updated = ();
   for my $u (@urls) {
      $self->log->info("update: trying to update [$u]...");
      my $files = $self->mirror($u) or next;
      for my $file (@$files) {
         (my $outfile = $file) =~ s/\.bz2$//;
         $self->log->verbose("update: uncompressing to [$outfile]");
         $fc->uncompress($file, $outfile) or next;
         push @updated, $outfile;
      }
   }

   return \@updated;
}

1;

__END__

=head1 NAME

Metabrik::Password::Rockyou - password::rockyou Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

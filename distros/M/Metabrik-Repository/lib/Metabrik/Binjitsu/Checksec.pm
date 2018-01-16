#
# $Id: Checksec.pm,v 6fa51436f298 2018/01/12 09:27:33 gomor $
#
# binjitsu::checksec Brik
#
package Metabrik::Binjitsu::Checksec;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision: 6fa51436f298 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         file => [ qw(input) ],
      },
      require_binaries => {
         checksec => [ ],
      },
   };
}

sub file {
   my $self = shift;
   my ($file) = @_;

   $self->brik_help_run_undef_arg('file', $file) or return;
   my $ref = $self->brik_help_run_invalid_arg('file', $file, 'ARRAY', 'SCALAR')
      or return;

   if ($ref eq 'ARRAY') {
      my @result = ();
      for my $this (@$file) {
         my $r = $self->file($this) or next;
         push @result, $r;
      }
      return \@result;
   }
   else {
      my $cmd = "checksec --file \"$file\"";
      my $buf = $self->capture($cmd) or return;
      my %r = ();
      for my $line (@$buf) {
         if ($line =~ /^\s+(\S+):\s+(.*)\s*$/) {
            $r{lc($1)} = $2;
         }
      }
      return \%r;
   }

   return;
}

1;

__END__

=head1 NAME

Metabrik::Binjitsu::Checksec - binjitsu::checksec Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

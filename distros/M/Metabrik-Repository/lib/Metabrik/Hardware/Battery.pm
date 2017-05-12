#
# $Id: Battery.pm,v f6ad8c136b19 2017/01/01 10:13:54 gomor $
#
# harware::battery Brik
#
package Metabrik::Hardware::Battery;
use strict;
use warnings;

use base qw(Metabrik::File::Text);

sub brik_properties {
   return {
      revision => '$Revision: f6ad8c136b19 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         capacity => [ ],
      },
   };
}

sub capacity {
   my $self = shift;

   my $base_file = '/sys/class/power_supply/BAT';
   $self->brik_help_run_file_not_found('capacity', $base_file) or return;

   my $battery_hash = {};
   my $count = 0;
   while (-f "$base_file$count/capacity") {
      my $data = $self->read("$base_file$count/capacity") or next;
      chomp($data);

      my $this = sprintf("battery_%02d", $count);
      $battery_hash->{$this} = {
         battery => $count,
         capacity => $data,
      };

      $count++;
   }

   return $battery_hash;
}

1;

__END__

=head1 NAME

Metabrik::Hardware::Battery - hardware::battery Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

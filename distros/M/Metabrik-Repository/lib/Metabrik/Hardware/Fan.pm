#
# $Id: Fan.pm,v 6fa51436f298 2018/01/12 09:27:33 gomor $
#
# harware::fan Brik
#
package Metabrik::Hardware::Fan;
use strict;
use warnings;

use base qw(Metabrik::File::Text);

sub brik_properties {
   return {
      revision => '$Revision: 6fa51436f298 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         info => [ ],
         #status => [ ],
         #speed => [ ],
         #level => [ ],
      },
   };
}

sub info {
   my $self = shift;

   my $base_file = '/proc/acpi/ibm/fan';
   $self->brik_help_run_file_not_found('info', $base_file) or return;

   my $data = $self->read($base_file) or return;
   chomp($data);

   my $info_hash = {};

   my @lines = split(/\n/, $data);
   for my $line (split(/\n/, $data)) {
      my ($name, $value) = $line =~ /^(\S+):\s+(.*)$/;

      if ($name eq 'commands') {
         push @{$info_hash->{$name}}, $value;
      }
      else {
         $info_hash->{$name} = $value;
      }
   }

   return $info_hash;
}

1;

__END__

=head1 NAME

Metabrik::Hardware::Fan - hardware::fan Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

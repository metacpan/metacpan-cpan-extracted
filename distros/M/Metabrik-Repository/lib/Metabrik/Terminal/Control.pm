#
# $Id: Control.pm,v 6fa51436f298 2018/01/12 09:27:33 gomor $
#
# terminal::control Brik
#
package Metabrik::Terminal::Control;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision: 6fa51436f298 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         output => [ qw(file) ],
      },
      commands => {
         install => [ ], # Inherited
         title => [ qw(string) ],
         record => [ qw(command|OPTIONAL) ],
         replay => [ qw(script_file timing_file|OPTIONAL) ],
      },
      require_binaries => {
         'script' => [ ],
         'scriptreplay' => [ ],
      },
      need_packages => {
         ubuntu => [ qw(bsdutils) ],
         debian => [ qw(bsdutils) ],
      },
   };
}

sub title {
   my $self = shift;
   my ($title) = @_;

   $self->brik_help_run_undef_arg('title', $title) or return;

   print "\c[];$title\a\e[0m";

   return $title;
}

sub record {
   my $self = shift;
   my ($output, $command) = @_;

   $self->brik_help_run_undef_arg('record', $output) or return;

   my $cmd = 'script';
   if (defined($command)) {
      $cmd .= " -c \"$command\"";
   }

   my $script_file = "$output.script";
   my $timing_file = "$output.timing";

   $cmd .= " -t\"$timing_file\" \"$script_file\"";

   $self->system($cmd) or return;

   return [ $script_file, $timing_file ];
}

sub replay {
   my $self = shift;
   my ($script, $timing) = @_;

   $self->brik_help_run_undef_arg('replay', $script) or return;

   my $cmd = 'scriptreplay';
   if (defined($timing)) {
      $cmd .= " -t $timing";
   }
   $cmd .= " $script";

   return $self->execute($cmd);
}

1;

__END__

=head1 NAME

Metabrik::Terminal::Control - terminal::control Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

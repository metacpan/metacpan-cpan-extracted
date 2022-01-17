#
# $Id$
#
# xorg::xrandr Brik
#
package Metabrik::Xorg::Xrandr;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         output => [ qw(output) ],
         resolution => [ qw(resolution) ],
      },
      commands => {
         install => [ ],  # Inherited
         list_outputs => [ ],
         list_connected_outputs => [ ],
         list_disconnected_outputs => [ ],
         list_output_resolutions => [ qw(output) ],
         list_first_output_resolutions => [ qw(output) ],
         list_secondary_output_resolutions => [ qw(output) ],
         get_first_output => [ ],
         get_secondary_output => [ ],
         get_common_resolution => [ ],
         get_first_output_resolution => [ ],
         get_first_output_max_resolution => [ ],
         get_secondary_output_resolution => [ ],
         get_secondary_output_max_resolution => [ ],
         get_output_max_resolution => [ ],            # Alias to get_first_output_max_resolution
         get_output_resolution => [ ],                # Alias to get_first_output_resolution
         set_first_output_resolution => [ qw(resolution) ],
         set_first_output_max_resolution => [ ],
         set_secondary_output_resolution => [ qw(resolution) ],
         set_secondary_output_max_resolution => [ ],
         set_output_max_resolution => [ ],            # Alias to set_first_output_max_resolution
         set_output_resolution => [ qw(resolution) ], # Alias to set_first_output_resolution
         clone_first_to => [ qw(secondary_output) ],
         dual_first_right_of => [ qw(secondary_output) ],
         clone => [ qw(resolution|OPTIONAL) ],
      },
      require_binaries => {
         xrandr => [ ],
      },
      need_packages => {
         ubuntu => [ qw(x11-xserver-utils) ],
         debian => [ qw(x11-xserver-utils) ],
         kali => [ qw(x11-xserver-utils) ],
      },
   };
}

sub list_outputs {
   my $self = shift;

   my $lines = $self->capture('xrandr') or return;

   my @list = ();
   for my $line (@$lines) {
      if ($line =~ m{^(\S+)\s+(connected|disconnected)}) {
         push @list, $1;
      }
   }

   return \@list;
}

sub list_connected_outputs {
   my $self = shift;

   my $lines = $self->capture('xrandr') or return;

   my @list = ();
   for my $line (@$lines) {
      if ($line =~ m{^(\S+)\s+connected}) {
         push @list, $1;
      }
   }

   return \@list;
}

sub list_disconnected_outputs {
   my $self = shift;

   my $lines = $self->capture('xrandr') or return;

   my @list = ();
   for my $line (@$lines) {
      if ($line =~ m{^(\S+)\s+disconnected}) {
         push @list, $1;
      }
   }

   return \@list;
}

#
# Return a HASHref of output names with their list of available resolutions
#
sub list_output_resolutions {
   my $self = shift;
   my ($output) = @_;

   $output ||= $self->output;
   my $lines = $self->capture('xrandr') or return;

   my $current_output = '';
   my %list = ();
   for my $line (@$lines) {
      if ($line =~ m{^(\S+)\s+(connected|disconnected)}) {
         $current_output = $1;
         next;
      }

      if (defined($output)) {
         if (length($current_output) && $current_output eq $output) {
            if ($line =~ m{^\s+(\d+x\d+)\s+}) {
               push @{$list{$current_output}}, $1;
            }
         }
      }
      else {
         if (length($current_output)) {
            if ($line =~ m{^\s+(\d+x\d+)\s+}) {
               push @{$list{$current_output}}, $1;
            }
         }
      }
   }

   # If output was specified, we return only this one.
   if (defined($output)) {
      return $list{$output};
   }

   return \%list;
}

#
# Return the list of available resolutions for first connected output
#
sub list_first_output_resolutions {
   my $self = shift;

   my $output = $self->get_first_output or return;
   return $self->list_output_resolutions($output);
}

#
# Return the list of available resolutions for secondary connected output
#
sub list_secondary_output_resolutions {
   my $self = shift;

   my $output = $self->get_secondary_output or return;
   return $self->list_output_resolutions($output);
}

#
# Return first connected output
#
sub get_first_output {
   my $self = shift;

   my $lines = $self->capture('xrandr') or return;

   my $first_output = '';
   for my $line (@$lines) {
      if ($line =~ m{^(\S+)\s+connected}) {
         $first_output = $1;
         last;
      }
   }

   return $first_output;
}

#
# Return second connected output
#
sub get_secondary_output {
   my $self = shift;

   my $lines = $self->capture('xrandr') or return;

   my $first = 1;
   my $secondary_output = '';
   for my $line (@$lines) {
      if ($line =~ m{^(\S+)\s+connected}) {
         if ($first) {
            $first--;
            next;
         }
         $secondary_output = $1;
         last;
      } 
   }

   return $secondary_output;
}

#
# Return first connected output resolution
#
sub get_first_output_resolution {
   my $self = shift;

   my $lines = $self->capture('xrandr') or return;

   my $current_output = '';
   my $current_resolution = 0;
   for my $line (@$lines) {
      if ($line =~ m{^(\S+)\s+connected}) {
         $current_output = $1;
         next;
      }

      if (length($current_output)) {
         if ($line =~ m{^\s+(\d+x\d+)\s+\S+\*}) {
            $current_resolution = $1;
         }
      }
   }

   return $current_resolution;
}

sub get_first_output_max_resolution {
   my $self = shift;

   my $list = $self->list_first_output_resolutions or return;

   if (@$list > 0) {
      return $list->[0];
   }

   return $self->log->error("get_first_output_max_resolution: resolution not possible?");
}

sub get_secondary_output_resolution {
   my $self = shift;

   my $second = $self->get_secondary_output or return;

   my $lines = $self->capture('xrandr') or return;

   my $current_output = '';
   my $current_resolution = 0;
   for my $line (@$lines) {
      if ($line =~ m{^(\S+)\s+connected}) {
         if ($1 eq $second) {
            $current_output = $1;
            next;
         }
         else {
            next;
         }
      }

      if (length($current_output)) {
         if ($line =~ m{^\s+(\d+x\d+)\s+\S+\*}) {
            $current_resolution = $1;
         }
      }
   }

   return $current_resolution;
}

sub get_secondary_output_max_resolution {
   my $self = shift;

   my $list = $self->list_secondary_output_resolutions or return;

   if (@$list > 0) {
      return $list->[0];
   }

   return $self->log->error("get_secondary_output_max_resolution: resolution not possible?");
}

#
# Alias to get_first_output_max_resolution
#
sub get_output_max_resolution {
   my $self = shift;

   return $self->get_first_output_max_resolution;
}

#
# Alias to get_first_output_resolution
#
sub get_output_resolution {
   my $self = shift;

   return $self->get_first_output_resolution;
}

#
# Set first connected output resolution
#
sub set_first_output_resolution {
   my $self = shift;
   my ($resolution) = @_;

   $self->brik_help_run_undef_arg('set_first_output_resolution', $resolution) or return;

   my $lines = $self->capture('xrandr') or return;
   my $output = $self->get_first_output or return;
   my $possible = $self->list_output_resolutions($output) or return;

   my $ok = 0;
   for my $this (@$possible) {
      if ($this eq $resolution) {
         $ok++;
         last;
      }
   }

   if (! $ok) {
      return $self->log->error("set_first_output_resolution: resolution [$resolution] ".
         "not available for output [$output]");
   }

   return $self->capture("xrandr --output $output --mode $resolution");
}

#
# Alias to set_first_output_resolution
#
sub set_output_resolution {
   my $self = shift;

   return $self->set_first_output_resolution(@_);
}


sub set_first_output_max_resolution {
   my $self = shift;

   my $max = $self->get_first_output_max_resolution or return;

   return $self->set_first_output_resolution($max);
}

#
# Set secondary connected output resolution
#
sub set_secondary_output_resolution {
   my $self = shift;
   my ($resolution) = @_;

   $self->brik_help_run_undef_arg('set_secondary_output_resolution', $resolution) or return;

   my $lines = $self->capture('xrandr') or return;
   my $output = $self->get_secondary_output or return;
   my $possible = $self->list_output_resolutions($output) or return;

   my $ok = 0;
   for my $this (@$possible) {
      if ($this eq $resolution) {
         $ok++;
         last;
      }
   }

   if (! $ok) {
      return $self->log->error("set_secondary_output_resolution: resolution [$resolution] ".
         "not available for output [$output]");
   }

   return $self->capture("xrandr --output $output --mode $resolution");
}

sub set_secondary_output_max_resolution {
   my $self = shift;

   my $max = $self->get_secondary_output_max_resolution or return;

   return $self->set_secondary_output_resolution($max);
}

#
# Alias to set_first_output_max_resolution
#
sub set_output_max_resolution {
   my $self = shift;

   return $self->set_first_output_max_resolution;
}

sub clone_first_to {
   my $self = shift;
   my ($second) = @_;

   $self->brik_help_run_undef_arg('clone_first_to', $second) or return;

   my $connected = $self->list_connected_outputs or return;
   my $found = 0;
   for my $this (@$connected) {
      if ($this eq $second) {
         $found++;
         last;
      }
   }

   if (! $found) {
      return $self->log->error("clone_first_to: output [$second] not connected");
   }

   my $current_output = $self->get_first_output or return;
   my $current_resolution = $self->get_first_output_resolution or return;

   my $cmd = "xrandr --output \"$second\" --mode $current_resolution ".
      "--same-as \"$current_output\"";

   $self->log->verbose("clone_first_to: [$cmd]");

   return $self->capture($cmd);
}

sub dual_first_right_of {
   my $self = shift;
   my ($second) = @_;

   $self->brik_help_run_undef_arg('dual_first_right_of', $second) or return;

   my $connected = $self->list_connected_outputs or return;
   my $found = 0;
   for my $this (@$connected) {
      if ($this eq $second) {
         $found++;
         last;
      }
   }

   if (! $found) {
      return $self->log->error("dual_first_right_of: output [$second] not connected");
   }

   my $current_output = $self->get_first_output or return;
   my $current_resolution = $self->get_first_output_resolution or return;

   my $cmd = "xrandr --output \"$second\" --auto --left-of \"$current_output\"";

   $self->log->verbose("dual_first_right_of: [$cmd]");

   return $self->capture($cmd);
}

sub get_common_resolution {
   my $self = shift;
   my ($first, $second) = @_;

   my $outputs = $self->list_output_resolutions or return;
   if ((! defined($first) && ! defined($second)) && (@$outputs < 2 || @$outputs > 2)) {
      return $self->log->error("get_common_resolution: less than or more than 2 screens");
   }

   $first = $outputs->{$first};
   $second = $outputs->{$second};

   my $resolution;
   for my $this_first (@$first) {
      for my $this_second (@$second) {
         if ($this_first eq $this_second) {
            $self->log->info("get_common_resolution: found common ".
               "resolution [$this_first]");
            $resolution = $this_first;
            last;
         }
      }
      last if defined($resolution);
   }

   return $resolution;
}

sub clone {
   my $self = shift;
   my ($resolution) = @_;

   # We try to find the best resolution for first and second outputs.
   if (! defined($resolution)) {
      my $first = $self->get_first_output or return;
      my $second = $self->get_secondary_output or return;
      $resolution = $self->get_common_resolution($first, $second) or return;
   }

   # If not found, user must give that information.
   $self->brik_help_run_undef_arg('clone', $resolution) or return;

   my $list1 = $self->list_first_output_resolutions or return;
   my $ok = 0;
   for (@$list1) {
      if ($_ eq $resolution) {
         $ok = 1;
         last;
      }
   }
   if (! $ok) {
      return $self->log->error("clone: first output does not support ".
         "resolution [$resolution]");
   }

   $self->set_first_output_resolution($resolution) or return;

   my $second = $self->get_secondary_output or return;
   my $list2 = $self->list_secondary_output_resolutions or return;
   $ok = 0;
   for (@$list2) {
      if ($_ eq $resolution) {
         $ok = 1;
         last;
      }
   }
   if (! $ok) {
      return $self->log->error("clone: secondary output does not support ".
         "resolution [$resolution]");
   }

   $self->set_secondary_output_resolution($resolution) or return;

   return $self->clone_first_to($second);
}

1;

__END__

=head1 NAME

Metabrik::Xorg::Xrandr - xorg::xrandr Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

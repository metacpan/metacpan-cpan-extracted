#
# $Id: Dump.pm,v 6fa51436f298 2018/01/12 09:27:33 gomor $
#
# file::dump Brik
#
package Metabrik::File::Dump;
use strict;
use warnings;

use base qw(Metabrik::File::Write);

sub brik_properties {
   return {
      revision => '$Revision: 6fa51436f298 $',
      tags => [ qw(unstable read write) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         input => [ qw(file) ],
         output => [ qw(file) ],
         append => [ qw(0|1) ],
      },
      attributes_default => {
         append => 1,
      },
      commands => {
         read => [ qw(file) ],
         write => [ qw($data|$data_ref|$data_list output|OPTIONAL) ],
      },
      require_modules => {
         'Data::Dump' => [ ],
         'Metabrik::File::Read' => [ ],
      },
   };
}

sub read {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->input;
   $self->brik_help_run_undef_arg('read', $input) or return;

   my $fr = Metabrik::File::Read->new_from_brik_init($self) or return;
   $fr->input($input);
   $fr->encoding($self->encoding);
   $fr->as_array(1);
   $fr->strip_crlf(1);

   $fr->open or return;
   my $data = $fr->read or return;
   $fr->close;

   my @vars = ();
   my $buf = '';
   for (@$data) {
      $buf .= $_;

      if (/^$/) {
         push @vars, $buf;
         $buf = '';
      }
   }

   # Gather last remaining line, if any
   if (length($buf)) {
      push @vars, $buf;
      $buf = '';
   }

   my @res = ();
   for (@vars) {
      my $h = eval($_);
      if ($@) {
         chomp($@);
         $self->log->warning("read: eval failed: $@");
         next;
      }
      push @res, $h;
   }

   return \@res;
}

sub write {
   my $self = shift;
   my ($data, $output) = @_;

   $output ||= $self->output;
   $self->brik_help_run_undef_arg('write', $data) or return;
   $self->brik_help_run_undef_arg('write', $output) or return;

   $self->log->debug("write: data[$data]");

   $self->open($output) or return;

   if (ref($data) eq 'ARRAY') {
      for (@$data) {
         my $r = $self->SUPER::write(Data::Dump::dump($_)."\n\n");
         if (! defined($r)) {
            return $self->log->error("write: write failed");
         }
      }
   }
   else {
      my $r = $self->SUPER::write(Data::Dump::dump($data)."\n\n");
      if (! defined($r)) {
         return $self->log->error("write: write failed");
      }
   }

   $self->close;

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::File::Dump - file::dump Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

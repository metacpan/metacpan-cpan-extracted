#
# $Id: Readelf.pm,v 6bd6acfc81d5 2019/03/13 09:56:26 gomor $
#
# file::readelf Brik
#
package Metabrik::File::Readelf;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision: 6bd6acfc81d5 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         input => [ qw(file) ],
      },
      attributes_default => {
      },
      commands => {
         install => [ ], # Inherited
         program_headers => [ qw(file|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::File::Type' => [ ],
      },
      require_binaries => {
         readelf => [ ],
      },
      need_packages => {
         ubuntu => [ qw(binutils) ],
         debian => [ qw(binutils) ],
         kali => [ qw(binutils) ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
      },
   };
}

sub program_headers {
   my $self = shift;
   my ($file) = @_;

   $file ||= $self->input;
   $self->brik_help_run_undef_arg('program_headers', $file) or return;

   my $ft = Metabrik::File::Type->new_from_brik_init($self) or return;
   my $magic = $ft->get_magic_type($file) or return;

   if ($magic !~ /^ELF /) {
      return $self->log->error("program_headers: file [$file] is not ELF: [$magic]");
   }

   my $cmd = "readelf --program-headers \"$file\"";
   my $r = $self->capture($cmd) or return;

   my $entry_point = 0;
   my $starting_offset = 0;
   my $start = 0;
   my $first = 1;
   my $section = {};
   my @sections = ();
   for my $line (@$r) {
      next if $line =~ /^\s*$/;
      next if $line =~ /^\s*Type\s+Offset/; # Skip header line
      next if $line =~ /^\s*FileSiz\s+MemSiz/; # Skip header line
      $line =~ s/^\s*//;
      $line =~ s/\s*$//;
      if ($line =~ /^\s*Entry point (\S+)/) {
         $entry_point = $1;
         next;
      }
      if ($line =~ /starting at offset (\d+)/) {
         $starting_offset = $1;
         next;
      }

      # Skip until we find program headers section
      if ($line =~ /^\s*Program Headers/) {
         $start++;
         next;
      }

      # Parse the section
      # LINE[  Type           Offset             VirtAddr           PhysAddr]
      # LINE[                 FileSiz            MemSiz              Flags  Align]
      # LINE[  NOTE           0x0000000000000318 0x0000000000000000 0x0000000000000000]
      # LINE[                 0x0000000000000480 0x0000000000000480  R      0]

      if ($start) {
         if ($first) { # First line out of two, they are wrapped
            my @toks = split(/\s+/, $line);
            $section->{type} = $toks[0];
            $section->{offset} = $toks[1];
            $section->{virtaddr} = $toks[2];
            $section->{physaddr} = $toks[3];
            $first = 0; # Prepare for next round
         }
         else {
            my @toks = split(/\s+/, $line);
            $section->{filesiz} = $toks[0];
            $section->{memsiz} = $toks[1];
            $section->{flags} = $toks[2];
            $section->{align} = $toks[3];
            push @sections, $section;
            $section = {};
            $first = 1; # Prepare for next round
         }
      }
   }

   my $headers = {
      entry_point => $entry_point,
      starting_offset => $starting_offset,
      sections => \@sections,
   };

   return $headers;
}

1;

__END__

=head1 NAME

Metabrik::File::Readelf - file::readelf Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2019, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

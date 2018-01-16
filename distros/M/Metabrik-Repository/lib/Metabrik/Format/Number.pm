#
# $Id: Number.pm,v 6fa51436f298 2018/01/12 09:27:33 gomor $
#
# format::number Brik
#
package Metabrik::Format::Number;
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
         kibi_suffix => [ qw(string) ],
         kilo_suffix => [ qw(string) ],
         mebi_suffix => [ qw(string) ],
         mega_suffix => [ qw(string) ],
         gibi_suffix => [ qw(string) ],
         giga_suffix => [ qw(string) ],
      },
      attributes_default => {
         kibi_suffix => 'Kb',
         kilo_suffix => 'KB',
         mebi_suffix => 'Mb',
         mega_suffix => 'MB',
         gibi_suffix => 'Gb',
         giga_suffix => 'GB',
      },
      commands => {
         from_number => [ qw(number) ],
         to_number => [ qw(string) ],
      },
      require_modules => {
         'Number::Format' => [ ],
      },
   };
}

sub _new {
   my $self = shift;

   my $x = Number::Format->new(
      -kibi_suffix => $self->kibi_suffix,
      -kilo_suffix => $self->kilo_suffix,
      -mebi_suffix => $self->mebi_suffix,
      -mega_suffix => $self->mega_suffix,
      -gibi_suffix => $self->gibi_suffix,
      -giga_suffix => $self->giga_suffix,
   );

   return $x;
}

sub from_number {
   my $self = shift;
   my ($number) = @_;

   $self->brik_help_run_undef_arg('from_number', $number) or return;

   if ($number !~ /^\d+/) {
      return $self->log->error("from_number: number [$number] is not valid");
   }

   my $x = $self->_new;

   return $x->format_bytes($number);
}

sub to_number {
   my $self = shift;
   my ($string) = @_;

   $self->brik_help_run_undef_arg('to_number', $string) or return;

   my $x = $self->_new;

   return $x->unformat_number($string);
}

1;

__END__

=head1 NAME

Metabrik::Format::Number - format::number Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

#
# $Id: Regex.pm,v f6ad8c136b19 2017/01/01 10:13:54 gomor $
#
# string::regex Brik
#
package Metabrik::String::Regex;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: f6ad8c136b19 $',
      tags => [ qw(unstable encode decode) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
      },
      attributes_default => {
      },
      commands => {
         encode => [ qw($regex|$regex_list) ],
      },
      require_modules => {
         'Regexp::Assemble' => [ ],
      },
   };
}

sub encode {
   my $self = shift;
   my ($regex) = @_;

   $self->brik_help_run_undef_arg('encode', $regex) or return;

   my $ra = Regexp::Assemble->new
      or return $self->log->error("encode: Regexp::Assemble new failed");

   if (ref($regex)) {
      for my $this (@$regex) {
         $ra->add($this);
      }
   }
   elsif (! ref($regex)) {
      $ra->add($regex);
   }

   my $encoded;
   eval {
      $encoded = $ra->as_string;
   };
   if ($@) {
      chomp($@);
      return $self->log->error("encode: assembling failed [$@]");
   }

   return $encoded;
}

1;

__END__

=head1 NAME

Metabrik::String::Regex - string::regex Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

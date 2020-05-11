#
# $Id$
#
# api::cvesearch Brik
#
package Metabrik::Api::Cvesearch;
use strict;
use warnings;

use base qw(Metabrik::Client::Rest);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         db_info => [ ],
         browse => [ ],
         browse_vendor => [ qw(vendor) ],
         search => [ qw(vendor product) ],
         cve => [ qw(cve) ],
         last => [ ],
      },
   };
}

#
# https://www.circl.lu/services/cve-search/
#

sub db_info {
   my $self = shift;

   my $url = 'http://cve.circl.lu/api/dbInfo';

   $self->get($url) or return;

   return $self->content;
}

sub browse {
   my $self = shift;

   my $url = 'http://cve.circl.lu/api/browse';

   $self->get($url) or return;

   return $self->content;
}

sub browse_vendor {
   my $self = shift;
   my ($vendor) = @_;

   $self->brik_help_run_undef_arg('browse_vendor', $vendor) or return;

   my $url = 'http://cve.circl.lu/api/browse/'.$vendor;

   $self->get($url) or return;

   return $self->content;
}

sub search {
   my $self = shift;
   my ($vendor, $product) = @_;

   $self->brik_help_run_undef_arg('search', $vendor) or return;
   $self->brik_help_run_undef_arg('search', $product) or return;

   my $url = 'http://cve.circl.lu/api/search/'.$vendor.'/'.$product;

   $self->get($url) or return;

   return $self->content;
}

sub cve {
   my $self = shift;
   my ($cve) = @_;

   $self->brik_help_run_undef_arg('cve', $cve) or return;

   my $url = 'http://cve.circl.lu/api/cve/'.$cve;

   $self->get($url) or return;

   return $self->content;
}

sub last {
   my $self = shift;

   my $url = 'http://cve.circl.lu/api/last';

   $self->get($url) or return;

   return $self->content;
}

1;

__END__

=head1 NAME

Metabrik::Api::Cvesearch - api::cvesearch Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

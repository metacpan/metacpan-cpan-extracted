#
# $Id$
#
# api::bluecoat Brik
#
package Metabrik::Api::Bluecoat;
use strict;
use warnings;

use base qw(Metabrik::Client::Rest);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable rest) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         output_mode => [ qw(json|xml) ],
      },
      attributes_default => {
         uri => 'https://localhost:8089',
         username => 'admin',
         ssl_verify => 0,
         output_mode => 'json',
      },
      commands => {
         category => [ qw(uri) ],
      },
      require_modules => {
         'Metabrik::String::Json' => [ ],
         'Metabrik::String::Xml' => [ ],
      },
   };
}

sub category {
   my $self = shift;
   my ($uri) = @_;

   $uri ||= $self->uri;
   $self->brik_help_run_undef_arg('category', $uri) or return;

   # If there is neither http:// nor ftp://, we add http://
   if ($uri !~ m{^(?:http|ftp)://}) {
      $uri =~ s{^}{http://};
   }

   $self->log->verbose("category: checking URI [$uri]");

   my $r = $self->post({ url => $uri }, 'http://sitereview.bluecoat.com/rest/categorization')
      or return;

   my $content = $r->{content};

   my $sj = Metabrik::String::Json->new_from_brik_init($self) or return;
   my $decode = $sj->decode($content) or return;

   # Example: <a href=\"javascript:showPopupWindow('catdesc.jsp?catnum=92')\">Suspicious</a>
   if (exists($decode->{categorization})) {
      my $category = $decode->{categorization};
      $category =~ s/^.*>(.+?)<.*?$/$1/;
      if (! $category) {
         $self->log->warning("category: categorization not found in string");
         $decode = $decode->{categorization};
      }
      else {
         $decode = $category;
      }
   }
   else {
      $self->log->warning("category: categorization key not found in hash");
   }

   return $decode;
}

1;

__END__

=head1 NAME

Metabrik::Api::Bluecoat - api::bluecoat Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

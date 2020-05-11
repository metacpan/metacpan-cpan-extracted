#
# $Id$
#
# www::shorten Brik
#
package Metabrik::Www::Shorten;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable shortener url uri) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         service => [ qw(default|tinyurl|linkz|shorl) ],
         ssl_verify => [ qw(0|1) ],
      },
      attributes_default => {
         service => 'default',
         ssl_verify => 0,
      },
      commands => {
         'shorten' => [ qw(uri) ],
         'shorten_default' => [ qw(uri) ],
         'shorten_tinyurl' => [ qw(uri) ],
         'unshorten' => [ qw(uri) ],
      },
      require_modules => {
         'WWW::Shorten' => [ ],
         'Metabrik::Client::Www' => [ ],
         'Metabrik::String::Uri' => [ ],
      },
   };
}

sub shorten_default {
   my $self = shift;
   my ($uri) = @_;

   $self->brik_help_run_undef_arg('shorten_default', $uri) or return;

   my $service = 'http://url.pm';

   my $cw = Metabrik::Client::Www->new_from_brik_init($self) or return;
   $cw->post({ _url => $uri }, $service) or return;

   my $shorten;
   my $content = $cw->content or return;
   if (length($content)) {
      ($shorten) = $content =~ m{(http://url\.pm/[^"]+)};
   }

   return $shorten;
}

sub shorten_tinyurl {
   my $self = shift;
   my ($uri) = @_;

   $self->brik_help_run_undef_arg('shorten_tinyurl', $uri) or return;

   eval("use WWW::Shorten 'TinyURL';");

   my $shorten;
   eval {
      $shorten = makeashorterlink($uri);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("shorten_tinyurl: failed with [$@]");
   }

   return $shorten;
}

sub shorten {
   my $self = shift;
   my ($uri) = @_;

   my $service = $self->service;
   $self->brik_help_run_undef_arg('shorten', $uri) or return;

   my $shorten = '';
   if ($service eq 'default') {
      $shorten = $self->shorten_default($uri) or return;
   }
   elsif ($service eq 'tinyurl') {
      $shorten = $self->shorten_tinyurl($uri) or return;
   }
   else {
      return $self->log->error("shorten: don't know how to shorten service with [$service]");
   }

   return $shorten;
}

sub unshorten {
   my $self = shift;
   my ($uri) = @_;

   $self->brik_help_run_undef_arg('unshorten', $uri) or return;

   my $cw = Metabrik::Client::Www->new_from_brik_init($self) or return;
   my $trace = $cw->trace_redirect($uri) or return;

   my $unshorten;
   if (@$trace > 0 && exists($trace->[-1]->{uri})) {
      $unshorten = $trace->[-1]->{uri};
   }

   return $unshorten || 'undef';
}

1;

__END__

=head1 NAME

Metabrik::Www::Shorten - www::shorten Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

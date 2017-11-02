#
# $Id: Rest.pm,v 5051a354bfa9 2017/10/28 08:17:02 gomor $
#
# client::rest Brik
#
package Metabrik::Client::Rest;
use strict;
use warnings;

use base qw(Metabrik::Client::Www);

sub brik_properties {
   return {
      revision => '$Revision: 5051a354bfa9 $',
      tags => [ qw(unstable http api) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         uri => [ qw(uri) ],  # Inherited
         username => [ qw(username) ],  # Inherited
         password => [ qw(password) ],  # Inherited
         ssl_verify => [ qw(0|1) ], # Inherited
         output_mode => [ qw(json|xml) ],
      },
      attributes_default => {
         output_mode => 'json',
      },
      commands => {
         reset_user_agent => [ ],
         get => [ qw(uri|OPTIONAL username|OPTIONAL password|OPTIONAL) ],
         post => [ qw(content_hash uri|OPTIONAL username|OPTIONAL password|OPTIONAL) ],
         patch => [ qw(content_hash uri|OPTIONAL username|OPTIONAL password|OPTIONAL) ],
         put => [ qw(content_hash uri|OPTIONAL username|OPTIONAL password|OPTIONAL) ],
         head => [ qw(uri|OPTIONAL username|OPTIONAL password|OPTIONAL) ],
         delete => [ qw(uri|OPTIONAL username|OPTIONAL password|OPTIONAL) ],
         options => [ qw(uri|OPTIONAL username|OPTIONAL password|OPTIONAL) ],
         code => [ ],
         content => [ qw(output_mode|OPTIONAL) ],
         get_content => [ qw(uri|OPTIONAL username|OPTIONAL password|OPTIONAL) ],
         post_content => [ qw(content_hash uri|OPTIONAL username|OPTIONAL password|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::String::Xml' => [ ],
         'Metabrik::String::Json' => [ ],
      },
   };
}

sub content {
   my $self = shift;
   my ($output_mode) = @_;

   my $last = $self->_last;
   if (! defined($last)) {
      return $self->log->error("content: no request has been made yet");
   }

   my $sm;
   $output_mode ||= $self->output_mode;
   if ($output_mode eq 'json') {
      $sm = Metabrik::String::Json->new_from_brik_init($self) or return;
   }
   elsif ($output_mode eq 'xml') {
      $sm = Metabrik::String::Xml->new_from_brik_init($self) or return;
   }
   else {
      return $self->log->error("content: output_mode not supported [$output_mode]");
   }

   # We must decode content cause it may be gzipped, for instance.
   return $sm->decode($last->decoded_content);
}

1;

__END__

=head1 NAME

Metabrik::Client::Rest - client::rest Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

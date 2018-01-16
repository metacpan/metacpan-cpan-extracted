#
# $Id: Uri.pm,v 6fa51436f298 2018/01/12 09:27:33 gomor $
#
# string::uri Brik
#
package Metabrik::String::Uri;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: 6fa51436f298 $',
      tags => [ qw(unstable encode decode escape) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         uri => [ qw(uri) ],
      },
      commands => {
         parse => [ qw(uri|OPTIONAL) ],
         scheme => [ ],
         host => [ ],
         port => [ ],
         tld => [ ],
         domain => [ ],
         hostname => [ ],
         path => [ ],
         opaque => [ ],
         fragment => [ ],
         query => [ ],
         path_query => [ ],
         authority => [ ],
         query_form => [ ],
         userinfo => [ ],
         is_http_scheme => [ ],
         is_https_scheme => [ ],
         is_imap_scheme => [ ],
         is_imaps_scheme => [ ],
         is_pop3_scheme => [ ],
         is_pop3s_scheme => [ ],
         encode => [ qw($data) ],
         decode => [ qw($data) ],
      },
      require_modules => {
         'URI' => [ ],
         'URI::Escape' => [ ],
      },
   };
}

sub parse {
   my $self = shift;
   my ($string) = @_;

   $string ||= $self->uri;
   $self->brik_help_run_undef_arg('parse', $string) or return;

   my $uri = URI->new($string);

   # Probably not a valid uri
   if (! $uri->can('host')) {
      return $self->log->error("parse: invalid URI [$string]");
   }

   my $h = {
      scheme => $uri->scheme || '',
      host => $uri->host || '',
      port => $uri->port || 80,
      path => $uri->path || '/',
      opaque => $uri->opaque || '',
      fragment => $uri->fragment || '',
      query => $uri->query || '',
      path_query => $uri->path_query || '',
      query_form => $uri->query_form || '',
      userinfo => $uri->userinfo || '',
      authority => $uri->authority || '',
   };

   if ($h->{userinfo}) {
      my ($user, $password) = $h->{userinfo} =~ m{^(.*):(.*)$};
      $h->{user} = $user || '';
      $h->{password} = $password || '';
   }

   return $h;
}

sub _is_scheme {
   my $self = shift;
   my ($parsed, $scheme) = @_;

   $self->brik_help_run_undef_arg("is_${scheme}_scheme", $parsed) or return;
   $self->brik_help_run_invalid_arg("is_${scheme}_scheme", $parsed, 'HASH') or return;

   if (exists($parsed->{scheme}) && $parsed->{scheme} eq $scheme) {
      return 1;
   }

   return 0;
}

sub is_http_scheme {
   my $self = shift;

   return $self->_is_scheme(@_, 'http');
}

sub is_https_scheme {
   my $self = shift;

   return $self->_is_scheme(@_, 'https');
}

sub is_imap_scheme {
   my $self = shift;

   return $self->_is_scheme(@_, 'imap');
}

sub is_imaps_scheme {
   my $self = shift;

   return $self->_is_scheme(@_, 'imaps');
}

sub is_pop3_scheme {
   my $self = shift;

   return $self->_is_scheme(@_, 'pop3');
}

sub is_pop3s_scheme {
   my $self = shift;

   return $self->_is_scheme(@_, 'pop3s');
}

sub _this {
   my $self = shift;
   my ($this) = @_;

   my $uri = $self->uri;
   $self->brik_help_run_undef_arg('parse', $uri) or return;

   return $uri->$this;
}

sub scheme { return shift->_this('scheme'); }
sub host { return shift->_this('host'); }
sub port { return shift->_this('port'); }
sub path { return shift->_this('path'); }
sub opaque { return shift->_this('opaque'); }
sub fragment { return shift->_this('fragment'); }
sub query { return shift->_this('query'); }
sub path_query { return shift->_this('path_query'); }
sub authority { return shift->_this('authority'); }
sub query_form { return shift->_this('query_form'); }
sub userinfo { return shift->_this('userinfo'); }

sub encode {
   my $self = shift;
   my ($data) = @_;

   $self->brik_help_run_undef_arg('encode', $data) or return;

   my $encoded = URI::Escape::uri_escape($data);

   return $encoded;
}

sub decode {
   my $self = shift;
   my ($data) = @_;

   $self->brik_help_run_undef_arg('decode', $data) or return;

   my $decoded = URI::Escape::uri_unescape($data);

   return $decoded;
}

1;

__END__

=head1 NAME

Metabrik::String::Uri - string::uri Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

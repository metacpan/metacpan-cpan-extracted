#
# $Id: Http.pm,v 6fa51436f298 2018/01/12 09:27:33 gomor $
#
# string::http Brik
#
package Metabrik::String::Http;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: 6fa51436f298 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
      },
      attributes_default => {
      },
      commands => {
         decode => [ qw(string) ],
         encode => [ qw(hash) ],
      },
      require_modules => {
         'HTTP::Headers' => [ ],
         'HTTP::Request' => [ ],
         'HTTP::Response' => [ ],
      },
   };
}

sub encode {
   my $self = shift;
   my ($hash) = @_;

   $self->brik_help_run_undef_arg('encode', $hash) or return;

   my $protocol = $hash->{protocol};
   my $headers = HTTP::Headers->new(%{$hash->{headers}})->as_string;
   my $content = $hash->{content};

   my @lines = ();

   # Probably a response
   if (exists($hash->{code})) {
      my $code = $hash->{code};
      my $message = $hash->{message};

      @lines = ( "$protocol $code $message" );
   }
   # Probably a request
   else {
      my $method = $hash->{method};
      my $uri = $hash->{uri};

      @lines = ( "$method $uri $protocol" );
   }

   push @lines, $headers;
   push @lines, $content;

   return join("\n", @lines);
}

sub decode {
   my $self = shift;
   my ($string) = @_;

   $self->brik_help_run_undef_arg('decode', $string) or return;

   my $r;
   my $h;
   # Probably a response
   if ($string =~ m{^HTTP/}) {
      $r = HTTP::Response->parse($string);
      $h = {
         code => $r->code,
         message => $r->message,
      };
   }
   # Probably a request
   else {
      $r = HTTP::Request->parse($string);
      $h = {
         method => $r->method,
         uri => $r->uri->as_string,
      };
   }

   my @list = $r->headers->flatten;

   $h->{headers} = { @list };
   $h->{protocol} = $r->protocol;
   $h->{content} = $r->content;
   $h->{decoded_content} = $r->decoded_content;

   return $h;
}

1;

__END__

=head1 NAME

Metabrik::String::Http - string::http Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

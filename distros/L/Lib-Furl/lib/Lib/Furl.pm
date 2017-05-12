#
# $Id: Furl.pm 4 2012-11-01 17:05:56Z gomor $
#
package Lib::Furl;
use strict;
use warnings;

use base qw(Exporter DynaLoader Class::Gomor::Array);
our @AS = qw(
   url
   url_len
   sep
   out
   _fh
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

our $VERSION = '1.00';

our %EXPORT_TAGS = (
   funcs => [qw(
      furl_init
      furl_get_version
      furl_decode
      furl_show
      furl_terminate
      furl_get_scheme_pos
      furl_get_scheme_size
      furl_get_credential_pos
      furl_get_credential_size
      furl_get_subdomain_pos
      furl_get_subdomain_size
      furl_get_domain_pos
      furl_get_domain_size
      furl_get_host_pos
      furl_get_host_size
      furl_get_tld_pos
      furl_get_tld_size
      furl_get_port_pos
      furl_get_port_size
      furl_get_resource_path_pos
      furl_get_resource_path_size
      furl_get_query_string_pos
      furl_get_query_string_size
      furl_get_fragment_pos
      furl_get_fragment_size
   )],
   consts => [qw(
      FURL_MAXLEN 
      FURL_LAST_SLASH_NOTFOUND
      FURL_LAST_SLASH_HIERARCHICAL
      FURL_LAST_SLASH_AFTER_DOMAIN
   )],
);
our @EXPORT = (
   @{$EXPORT_TAGS{funcs}},
   @{$EXPORT_TAGS{consts}},
);

__PACKAGE__->bootstrap($VERSION);

use constant FURL_MAXLEN => 8192;

use constant FURL_URL_EMPTY         => 1;
use constant FURL_URL_TOOLONG       => 2;
use constant FURL_URL_MEM_ERROR     => 3;
use constant FURL_URL_PARSER_ERROR  => 4;
use constant FURL_URL_UNKNOWN_ERROR => 5;

use constant FURL_OK             => 0;
use constant FURL_INVALID_STRONG => 100;
use constant FURL_INVALID_MEDIUM => 101;
use constant FURL_INVALID_WEAK   => 102;

use constant FURL_LAST_SLASH_NOTFOUND     => 0;
use constant FURL_LAST_SLASH_HIERARCHICAL => 1;
use constant FURL_LAST_SLASH_AFTER_DOMAIN => 2;

sub new {
   my $self = shift->SUPER::new(
      sep => ',',
      out => '*STDOUT',
      @_,
   );

   my $fh = furl_init();
   $self->_fh($fh);

   return $self;
}

sub decode {
   my $self = shift;
   my ($url) = @_;

   if (! $url || ! length($url)) {
      printf STDERR "[-] ".__PACKAGE__."::decode: please provide URL value\n";
      return;
   }

   my $fh     = $self->_fh;
   my $urlLen = length($url);

   $self->url($url);
   $self->url_len($urlLen);

   my $r = furl_decode($fh, $url, $urlLen);
   if ($r != 0) {
      printf STDERR "[-] ".__PACKAGE__."::decode: furl_decode error code: $r\n";
      return;
   }

   return $self;
}

sub get {
   my $self = shift;

   my $fh     = $self->_fh;
   my $url    = $self->url;
   my $urlLen = $self->url_len;

   my $h = {
      url     => $url,
      url_len => $urlLen,
   };
   for my $f (qw(
      furl_get_scheme
      furl_get_credential
      furl_get_subdomain
      furl_get_domain
      furl_get_host
      furl_get_tld
      furl_get_port
      furl_get_resource_path
      furl_get_query_string
      furl_get_fragment
   )) {
      my $pos  = $f.'_pos';
      my $size = $f.'_size';

      no strict 'refs';
      my $posV  = &$pos($fh);
      my $sizeV = &$size($fh);

      (my $k = $f) =~ s/^furl_get_//;

      # Unable to retrieve information
      if ($posV < 0 || $sizeV == 0) {
         $h->{$k} = '';
         next;
      }

      $h->{$k} = substr($url, $posV, $sizeV);
   }

   return $h;
}

sub show {
   my $self = shift;

   furl_show($self->_fh, $self->sep, $self->out);

   return $self;
}

sub DESTROY {
   my $self = shift;

   if ($self->_fh) {
      furl_terminate($self->_fh);
      $self->_fh(undef);
   }

   return 1;
}

1;

__END__

=head1 NAME

Lib::Furl - binding for stricaud faup library

=head1 SYNOPSIS

   #
   # Perl code
   #
   use Lib::Furl;

   my $url = 'https://user:pass@subdom.github.com:81/stricaud/faup/?test=1';

   my $furl = Lib::Furl->new;
   $furl->decode($url);

   my $h = $furl->get;
   print Dumper($h),"\n";

   #
   # Output
   #
   $VAR1 = {
      'fragment' => '',
      'query_string' => '?test=1',
      'url_len' => 60,
      'subdomain' => 'subdom',
      'scheme' => 'https',
      'port' => '81',
      'host' => 'subdom.github.com',
      'tld' => 'com',
      'domain' => 'github.com',
      'resource_path' => '/stricaud/faup/',
      'url' => 'https://user:pass@subdom.github.com:81/stricaud/faup/?test=1',
      'credential' => 'user:pass'
   };

=head1 OBJECT-ORIENTED API

=head1 ATTRIBUTES

=over 4

=item B<url>

The URL to decode.

=item B<sep>

Seperator to use when calling L<show>.

=item B<out>

Output file to use (default STDOUT) when calling L<show>.

=back

=head1 METHODS

=over 4

=item B<new> ()

Returns a new Furl object.

=item B<decode> ($url)

Decodes the URL, returns undef on error or $self object on success.

=item B<get> ()

Returns a hashref of decoded URL. Returns undef on error.

=item B<show> ()

Prints the decoded URL into

=back

=head1 C-ORIENTED API

=over 4

=item B<furl_init> ()

=item B<furl_get_version> ()

=item B<furl_decode> ()

=item B<furl_show> ()

=item B<furl_terminate> ()

=item B<furl_get_credential_pos> ()

=item B<furl_get_credential_size> ()

=item B<furl_get_domain_pos> ()

=item B<furl_get_domain_size> ()

=item B<furl_get_fragment_pos> ()

=item B<furl_get_fragment_size> ()

=item B<furl_get_host_pos> ()

=item B<furl_get_host_size> ()

=item B<furl_get_port_pos> ()

=item B<furl_get_port_size> ()

=item B<furl_get_query_string_pos> ()

=item B<furl_get_query_string_size> ()

=item B<furl_get_resource_path_pos> ()

=item B<furl_get_resource_path_size> ()

=item B<furl_get_scheme_pos> ()

=item B<furl_get_scheme_size> ()

=item B<furl_get_subdomain_pos> ()

=item B<furl_get_subdomain_size> ()

=item B<furl_get_tld_pos> ()

=item B<furl_get_tld_size> ()

=back

=head1 CONSTANTS

=over 4

=back

=head1 COPYRIGHT AND LICENSE

You may distribute this module under the terms of the BSD license. See LICENSE file in the source distribution archive.

Copyright (c) 2012, Patrice <GomoR> Auffret

=cut

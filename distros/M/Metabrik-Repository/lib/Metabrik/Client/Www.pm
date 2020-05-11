#
# $Id$
#
# client::www Brik
#
package Metabrik::Client::Www;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable browser http javascript screenshot) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         uri => [ qw(uri) ],
         username => [ qw(username) ],
         password => [ qw(password) ],
         ignore_content => [ qw(0|1) ],
         user_agent => [ qw(user_agent) ],
         ssl_verify => [ qw(0|1) ],
         datadir => [ qw(datadir) ],
         timeout => [ qw(0|1) ],
         rtimeout => [ qw(timeout) ],
         add_headers => [ qw(http_headers_hash) ],
         do_javascript => [ qw(0|1) ],
         do_redirects => [ qw(0|1) ],
         src_ip => [ qw(ip_address) ],
         max_redirects => [ qw(count) ],
         client => [ qw(object) ],
         _last => [ qw(object|INTERNAL) ],
         _last_code => [ qw(code|INTERNAL) ],
      },
      attributes_default => {
         ssl_verify => 0,
         ignore_content => 0,
         timeout => 0,
         rtimeout => 10,
         add_headers => {},
         do_javascript => 0,
         do_redirects => 1,
         max_redirects => 10,
      },
      commands => {
         install => [ ], # Inherited
         create_user_agent => [ ],
         reset_user_agent => [ ],
         get => [ qw(uri|OPTIONAL username|OPTIONAL password|OPTIONAL) ],
         cat => [ qw(uri|OPTIONAL username|OPTIONAL password|OPTIONAL) ],
         post => [ qw(content_hash uri|OPTIONAL username|OPTIONAL password|OPTIONAL) ],
         patch => [ qw(content_hash uri|OPTIONAL username|OPTIONAL password|OPTIONAL) ],
         put => [ qw(content_hash uri|OPTIONAL username|OPTIONAL password|OPTIONAL) ],
         head => [ qw(uri|OPTIONAL username|OPTIONAL password|OPTIONAL) ],
         delete => [ qw(uri|OPTIONAL username|OPTIONAL password|OPTIONAL) ],
         options => [ qw(uri|OPTIONAL username|OPTIONAL password|OPTIONAL) ],
         code => [ ],
         content => [ ],
         get_content => [ qw(uri|OPTIONAL username|OPTIONAL password|OPTIONAL) ],
         post_content => [ qw(content_hash uri|OPTIONAL username|OPTIONAL password|OPTIONAL) ],
         save_content => [ qw(output) ],
         headers => [ ],
         get_response_headers => [ ],
         delete_request_header => [ qw(header) ],
         get_response_header => [ qw(header) ],
         set_request_header => [ qw(header value|value_list) ],
         forms => [ ],
         links => [ ],
         trace_redirect => [ qw(uri|OPTIONAL) ],
         screenshot => [ qw(uri output) ],
         eval_javascript => [ qw(js) ],
         info => [ qw(uri|OPTIONAL) ],
         mirror => [ qw(url|$url_list output|OPTIONAL datadir|OPTIONAL) ],
         parse => [ qw(html) ],
         get_last => [ ],
         get_last_code => [ ],
      },
      require_modules => {
         'IO::Socket::SSL' => [ ],
         'Progress::Any::Output' => [ ],
         'Progress::Any::Output::TermProgressBarColor' => [ ],
         'Data::Dumper' => [ ],
         'HTML::TreeBuilder' => [ ],
         'LWP::UserAgent' => [ ],
         'LWP::UserAgent::ProgressAny' => [ ],
         'HTTP::Request' => [ ],
         'HTTP::Request::Common' => [ ],
         'WWW::Mechanize' => [ ],
         'Mozilla::CA' => [ ],
         'HTML::Form' => [ ],
         'Metabrik::File::Write' => [ ],
         'Metabrik::System::File' => [ ],
         'Metabrik::Network::Address' => [ ],
      },
      optional_modules => {
         'WWW::Mechanize::PhantomJS' => [ ],
      },
      optional_binaries => {
         phantomjs => [ ],
      },
   };
}

sub create_user_agent {
   my $self = shift;
   my ($uri, $username, $password) = @_;

   $self->log->debug("create_user_agent: creating agent");

   $uri ||= $self->uri;

   # Use IO::Socket::SSL which supports timeouts among other things.
   $ENV{PERL_NET_HTTPS_SSL_SOCKET_CLASS} = 'IO::Socket::SSL';

   my $ssl_verify = $self->ssl_verify
      ? IO::Socket::SSL::SSL_VERIFY_PEER()
      : IO::Socket::SSL::SSL_VERIFY_NONE();

   my %args = (
      stack_depth => 0,  # Default is infinite, and will eat-up whole memory.
                         # 0 means completely turn off the feature.
      autocheck => 0,  # Do not throw on error by checking HTTP code. Let us do it.
      timeout => $self->rtimeout,
      ssl_opts => {
         verify_hostname => $self->ssl_verify,
         SSL_verify_mode => $ssl_verify,
         SSL_ca_file => Mozilla::CA::SSL_ca_file(),
         # SNI support - defaults to PeerHost
         # SSL_hostname => 'hostname',
      },
   );

   my $mechanize = 'WWW::Mechanize';
   if ($self->do_javascript) {
      if ($self->brik_has_module('WWW::Mechanize::PhantomJS')
      &&  $self->brik_has_binary('phantomjs')) {
         $mechanize = 'WWW::Mechanize::PhantomJS';
      }
      else {
         return $self->log->error("create_user_agent: module [WWW::Mechanize::PhantomJS] not found, cannot do_javascript");
      }
   }
   if ((! $self->do_redirects) && $mechanize eq 'WWW::Mechanize::PhantomJS') {
      $self->log->warning("create_user_agent: module [WWW::Mechanize::PhantomJS] does ".
         "not support do_redirects, won't use it.");
   }
   elsif ($self->do_redirects) {
      $args{max_redirect} = $self->max_redirects;
   }
   else {  # Follow redirects not wanted
      $args{max_redirect} = 0;
   }

   my $src_ip = $self->src_ip;
   if (defined($src_ip)) {
      my $na = Metabrik::Network::Address->new_from_brik_init($self) or return;
      if (! $na->is_ip($src_ip)) {
         return $self->log->error("create_user_agent: src_ip [$src_ip] is invalid");
      }
      $args{local_address} = $src_ip;
   }

   my $mech = $mechanize->new(%args);
   if (! defined($mech)) {
      return $self->log->error("create_user_agent: unable to create WWW::Mechanize object");
   }

   if ($self->user_agent) {
      $mech->agent($self->user_agent);
   }
   else {
      # Some WWW::Mechanize::* modules can't do that
      if ($mech->can('agent_alias')) {
         $mech->agent_alias('Linux Mozilla');
      }
   }

   $username = defined($username) ? $username : $self->username;
   $password = defined($password) ? $password : $self->password;
   if (defined($username) && defined($password)) {
      $self->log->debug("create_user_agent: using Basic authentication");
      $mech->cookie_jar({});
      $mech->credentials($username, $password);
   }

   if ($self->log->level > 2) {
      $mech->add_handler("request_send",  sub { shift->dump; return });
      $mech->add_handler("response_done", sub { shift->dump; return });
   }

   return $mech;
}

sub reset_user_agent {
   my $self = shift;

   $self->client(undef);

   return 1;
}

sub _method {
   my $self = shift;
   my ($uri, $username, $password, $method, $data) = @_;

   $uri ||= $self->uri;
   $self->brik_help_run_undef_arg($method, $uri) or return;

   $self->timeout(0);

   $username = defined($username) ? $username : $self->username;
   $password = defined($password) ? $password : $self->password;
   my $client = $self->client;
   if (! defined($self->client)) {
      $client = $self->create_user_agent($uri, $username, $password) or return;
      $self->client($client);
   }

   my $add_headers = $self->add_headers;
   if (defined($add_headers)) {
      for my $k (keys %$add_headers) {
         my $v = $add_headers->{$k};
         if (ref($v) eq 'ARRAY') {
            my $this = join('; ', @$v);
            $client->add_header($k => $this);
         }
         else {
            $client->add_header($k => $v);
         }
      }
   }

   $self->log->verbose("$method: $uri");

   my $response;
   eval {
      if ($method ne 'get' && ref($client) eq 'WWW::Mechanize::PhantomJS') {
         return $self->log->error("$method: method not supported by WWW::Mechanize::PhantomJS");
      }
      if ($method eq 'post' || $method eq 'put') {
         $response = $client->$method($uri, Content => $data);
      }
      elsif ($method eq 'patch') {
         # https://stackoverflow.com/questions/23910962/how-to-send-a-http-patch-request-with-lwpuseragent
         my $req = HTTP::Request::Common::PATCH($uri, [ %$data ]);
         $response = $client->request($req);
      }
      elsif ($method eq 'options' || $method eq 'patch') {
         my $req = HTTP::Request->new($method, $uri, $add_headers);
         $response = $client->request($req);
      }
      else {
         $response = $client->$method($uri);
      }
   };
   if ($@) {
      chomp($@);
      if ($@ =~ /read timeout/i) {
         $self->timeout(1);
      }
      return $self->log->error("$method: unable to use method [$method] to uri [$uri]: $@");
   }

   $self->_last($response);

   my %r = ();
   $r{code} = $response->code;
   if (! $self->ignore_content) {
      if ($self->do_javascript) {
         # decoded_content method is available in WWW::Mechanize::PhantomJS
         # but is available in HTTP::Request response otherwise.
         $r{content} = $client->decoded_content;
      }
      else {
         $r{content} = $response->decoded_content;
      }
   }

   # Error messages seen from IO::Socket::SSL module.
   if ($r{content} =~ /^Can't connect to .+Connection timed out at /is) {
      $self->timeout(1);
      return $self->log->error("$method: $uri: connection timed out");
   }
   elsif ($r{content} =~ /^Can't connect to .+?\n\n(.+?) at /is) {
      return $self->log->error("$method: $uri: ".lcfirst($1));
   }
   elsif ($r{content} =~ /^Connect failed: connect: Interrupted system call/i) {
      return $self->log->error("$method: $uri: connection interrupted by syscall");
   }

   my $headers = $response->headers;
   $r{headers} = { map { $_ => $headers->{$_} } keys %$headers };
   delete $r{headers}->{'::std_case'};

   return \%r;
}

sub get {
   my $self = shift;
   my ($uri, $username, $password) = @_;

   return $self->_method($uri, $username, $password, 'get');
}

sub cat {
   my $self = shift;
   my ($uri, $username, $password) = @_;

   $self->_method($uri, $username, $password, 'get') or return;
   return $self->content;
}

sub post {
   my $self = shift;
   my ($href, $uri, $username, $password) = @_;

   $self->brik_help_run_undef_arg('post', $href) or return;

   return $self->_method($uri, $username, $password, 'post', $href);
}

sub put {
   my $self = shift;
   my ($href, $uri, $username, $password) = @_;

   $self->brik_help_run_undef_arg('put', $href) or return;

   return $self->_method($uri, $username, $password, 'put', $href);
}

sub patch {
   my $self = shift;
   my ($href, $uri, $username, $password) = @_;

   $self->brik_help_run_undef_arg('patch', $href) or return;

   return $self->_method($uri, $username, $password, 'patch', $href);
}

sub delete {
   my $self = shift;
   my ($uri, $username, $password) = @_;

   return $self->_method($uri, $username, $password, 'delete');
}

sub options {
   my $self = shift;
   my ($uri, $username, $password) = @_;

   return $self->_method($uri, $username, $password, 'options');
}

sub head {
   my $self = shift;
   my ($uri, $username, $password) = @_;

   return $self->_method($uri, $username, $password, 'head');
}

sub code {
   my $self = shift;

   my $last = $self->_last;
   if (! defined($last)) {
      return $self->log->error("code: you have to execute a request first");
   }

   return $last->code;
}

sub content {
   my $self = shift;

   my $last = $self->_last;
   if (! defined($last)) {
      return $self->log->error("content: you have to execute a request first");
   }

   if ($self->do_javascript) {
      # decoded_content method is available in WWW::Mechanize::PhantomJS
      # but is available in HTTP::Request response otherwise.
      my $client = $self->client;
      return $client->decoded_content;
   }

   return $last->decoded_content;
}

sub get_content {
   my $self = shift;
   my @args = @_;

   $self->get(@args) or return;
   return $self->content;
}

sub post_content {
   my $self = shift;
   my @args = @_;

   $self->post(@args) or return;
   return $self->content;
}

sub save_content {
   my $self = shift;
   my ($output) = @_;

   my $last = $self->_last;
   if (! defined($last)) {
      return $self->log->error("save_content: you have to execute a request first");
   }

   eval {
      $self->client->save_content($output);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("save_content: unable to save content: $@");
   }

   return 1;
}

sub headers {
   my $self = shift;

   my $last = $self->_last;
   if (! defined($last)) {
      return $self->log->error("headers: you have to execute a request first");
   }

   return $last->headers;
}

#
# Alias for headers Command
#
sub get_response_headers {
   my $self = shift;

   return $self->headers;
}

#
# Remove one header for next request.
#
sub delete_request_header {
   my $self = shift;
   my ($header) = @_;

   $self->brik_help_run_undef_arg('delete_header', $header) or return;

   my $headers = $self->add_headers;
   my $value = $headers->{$header} || 'undef';
   delete $headers->{$header};

   return $value;
}

#
# Return one header from last response.
#
sub get_response_header {
   my $self = shift;
   my ($header) = @_;

   $self->brik_help_run_undef_arg('get_header', $header) or return;

   my $headers = $self->headers or return;
   if (exists($headers->{$header})) {
      return $headers->{$header};
   }

   $self->log->verbose("get_header: header [$header] not found");

   return 0;
}

#
# Set header for next request.
#
sub set_request_header {
   my $self = shift;
   my ($header, $value) = @_;

   $self->brik_help_run_undef_arg('set_request_header', $header) or return;
   $self->brik_help_run_undef_arg('set_request_header', $value) or return;

   my $headers = $self->add_headers;
   $headers->{$header} = $value;

   return $value;
}

sub links {
   my $self = shift;

   my $last = $self->_last;
   if (! defined($last)) {
      return $self->log->error("links: you have to execute a request first");
   }

   my @links = ();
   for my $l ($self->client->links) {
      push @links, $l->url;
      $self->log->verbose("links: found link [".$l->url."]");
   }

   return \@links;
}

sub forms {
   my $self = shift;

   my $last = $self->_last;
   if (! defined($last)) {
      return $self->log->error("forms: you have to execute a request first");
   }

   my $client = $self->client;

   if ($self->log->level > 2) {
      print Data::Dumper::Dumper($last->headers)."\n";
   }

   # We use our own "manual" way to get access to content:
   # WWW::Mechanize::PhantomJS is clearly broken, and we have to support
   # WWW::Mechanize also. At some point, we should write a good WWW::Mechanize::PhantomJS
   # module.
   #my @forms = $client->forms;
   my $content = $self->content or return;
   my @forms = HTML::Form->parse($content, $client->base);

   my @result = ();
   for my $form (@forms) {
      my $name = $form->{attr}{name} || 'undef';
      my $action = $form->{action};
      my $method = $form->{method} || 'undef';

      my $h = {
         action => $action->as_string,
         method => $method,
      };

      for my $input (@{$form->{inputs}}) {
         my $type = $input->{type} || '';
         my $name = $input->{name} || '';
         my $value = $input->{value} || '';
         if ($type ne 'submit') {
            $h->{input}{$name} = $value;
         }
      }

      push @result, $h;
   }

   return \@result;
}

sub trace_redirect {
   my $self = shift;
   my ($uri, $username, $password) = @_;

   $uri ||= $self->uri;
   $self->brik_help_run_undef_arg('trace_redirect', $uri) or return;

   my $prev = $self->do_redirects;
   $self->do_redirects(0);

   my @results = ();

   my $location = $uri;
   # Max 20 redirects
   for (1..20) {
      $self->log->verbose("trace_redirect: $location");

      my $response;
      eval {
         $response = $self->get($location);
      };
      if ($@) {
         chomp($@);
         return $self->log->error("trace_redirect: unable to get uri [$uri]: $@");
      }

      my $this = {
         uri => $location,
         code => $self->code,
      };
      push @results, $this;

      if ($this->{code} != 302 && $this->{code} != 301) {
         last;
      }

      $location = $this->{location} = $self->headers->{location};
   }

   $self->do_redirects($prev);

   return \@results;
}

sub screenshot {
   my $self = shift;
   my ($uri, $output) = @_;

   $self->brik_help_run_undef_arg('screenshot', $uri) or return;
   $self->brik_help_run_undef_arg('screenshot', $output) or return;

   if ($self->brik_has_module('WWW::Mechanize::PhantomJS')
   &&  $self->brik_has_binary('phantomjs')) {
      my $mech = WWW::Mechanize::PhantomJS->new
         or return $self->log->error("screenshot: PhantomJS failed");

      my $get = $mech->get($uri)
         or return $self->log->error("screenshot: get uri [$uri] failed");

      my $data = $mech->content_as_png
         or return $self->log->error("screenshot: content_as_png failed");

      my $write = Metabrik::File::Write->new_from_brik_init($self) or return;
      $write->encoding('ascii');
      $write->overwrite(1);
      $write->append(0);

      $write->open($output) or return $self->log->error("screenshot: open failed");
      $write->write($data) or return $self->log->error("screenshot: write failed");
      $write->close;

      return $output;
   }

   return $self->log->error("screenshot: optional module [WWW::Mechanize::PhantomJS] and optional binary [phantomjs] are not available");
}

sub eval_javascript {
   my $self = shift;
   my ($js) = @_;

   $self->brik_help_run_undef_arg('eval_javascript', $js) or return;

   # Perl module Wight may also be an option.

   if ($self->brik_has_module('WWW::Mechanize::PhantomJS')
   &&  $self->brik_has_binary('phantomjs')) {
      my $mech = WWW::Mechanize::PhantomJS->new(launch_arg => ['ghostdriver/src/main.js'])
         or return $self->log->error("eval_javascript: PhantomJS failed");

      return $mech->eval_in_page($js);
   }

   return $self->log->error("eval_javascript: optional module [WWW::Mechanize::PhantomJS] ".
      "and optional binary [phantomjs] are not available");
}

sub info {
   my $self = shift;
   my ($uri) = @_;

   $uri ||= $self->uri;
   $self->brik_help_run_undef_arg('info', $uri) or return;

   my $r = $self->get($uri) or return;
   my $headers = $r->{headers};

   # Taken from apps.json from Wappalyzer
   my @headers = qw(
      IBM-Web2-Location
      X-Drupal-Cache
      X-Powered-By
      X-Drectory-Script
      Set-Cookie
      X-Powered-CMS
      X-KoobooCMS-Version
      X-ATG-Version
      User-Agent
      X-Varnish
      X-Compressed-By
      X-Firefox-Spdy
      X-ServedBy
      MicrosoftSharePointTeamServices
      Set-Cookie
      Generator
      X-CDN
      Server
      X-Tumblr-User
      X-XRDS-Location
      X-Content-Encoded-By
      X-Ghost-Cache-Status
      X-Umbraco-Version
      X-Rack-Cache
      Liferay-Portal
      X-Flow-Powered
      X-Swiftlet-Cache
      X-Lift-Version
      X-Spip-Cache
      X-Wix-Dispatcher-Cache-Hit
      COMMERCE-SERVER-SOFTWARE
      X-AMP-Version
      X-Powered-By-Plesk
      X-Akamai-Transformed
      X-Confluence-Request-Time
      X-Mod-Pagespeed
      Composed-By
      Via
   );

   if ($self->log->level > 2) {
      print Data::Dumper::Dumper($headers)."\n";
   }

   my %info = ();
   for my $hdr (@headers) {
      my $this = $headers->header(lc($hdr));
      $info{$hdr} = $this if defined($this);
   }

   my $title = $r->{title};
   if (defined($title)) {
      print "Title: $title\n";
   }

   for my $k (sort { $a cmp $b } keys %info) {
      print "$k: ".$info{$k}."\n";
   }

   return 1;
}

sub mirror {
   my $self = shift;
   my ($url, $output, $datadir) = @_;

   $datadir ||= $self->datadir;
   $self->brik_help_run_undef_arg('mirror', $url) or return;
   my $ref = $self->brik_help_run_invalid_arg('mirror', $url, 'SCALAR', 'ARRAY') or return;

   my @files = ();
   if ($ref eq 'ARRAY') {
      $self->brik_help_run_empty_array_arg('mirror', $url) or return;

      for my $this (@$url) {
         my $file = $self->mirror($this, $output) or next;
         push @files, @$file;
      }
   }
   else {
      if ($url !~ /^https?:\/\// && $url !~ /^ftp:\/\//) {
         return $self->log->error("mirror: invalid URL [$url]");
      }

      my $sf = Metabrik::System::File->new_from_brik_init($self) or return;
      if (! defined($output)) {
         my $filename = $sf->basefile($url) or return;
         $output = $datadir.'/'.$filename;
      }
      else { # $output is defined
         if (! $sf->is_absolute($output)) {  # We want default datadir for output file
            $output = $datadir.'/'.$output;
         }
      }

      $self->log->debug("mirror: url[$url] output[$output]");

      my $mech = $self->create_user_agent or return;
      LWP::UserAgent::ProgressAny::__add_handlers($mech);
      Progress::Any::Output->set("TermProgressBarColor");

      my $rc;
      eval {
         $rc = $mech->mirror($url, $output);
      };
      if ($@) {
         chomp($@);
         return $self->log->error("mirror: mirroring URL [$url] to local file [$output] failed: $@");
      }
      my $code = $rc->code;
      $self->_last_code($code);
      if ($code == 200) {
         push @files, $output;
         $self->log->verbose("mirror: downloading URL [$url] to local file [$output] done");
      }
      elsif ($code == 304) { # Not modified
         $self->log->verbose("mirror: file [$output] not modified since last check");
      }
      else {
         return $self->log->error("mirror: error while mirroring URL [$url] with code: [$code]");
      }
   }

   return \@files;
}

sub parse {
   my $self = shift;
   my ($html) = @_;

   $self->brik_help_run_undef_arg('parse', $html) or return;

   return HTML::TreeBuilder->new_from_content($html);
}

sub get_last {
   my $self = shift;

   return $self->_last;
}

sub get_last_code {
   my $self = shift;

   return $self->_last_code;
}

1;

__END__

=head1 NAME

Metabrik::Client::Www - client::www Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut

package Langertha::Skeid::SwaggerUI;
our $VERSION = '0.004';
# ABSTRACT: Swagger UI assets, fetched on first use and cached, never shipped
use Moo;
use strict;
use warnings;
use Carp qw(croak);
use Digest::SHA qw(sha256_hex);
use File::Spec ();
use Mojo::File ();
use Mojo::IOLoop;
use Mojo::UserAgent;
use Time::HiRes ();
use namespace::clean;


# swagger-ui-dist 5.17.14 (Apache-2.0). Digests taken from the files cdn.jsdelivr.net serves for
# that version; unpkg.com serves the same bytes.
my $VERSION_PINNED = '5.17.14';
my $SOURCE = 'https://cdn.jsdelivr.net/npm/swagger-ui-dist@' . $VERSION_PINNED . '/';
my %FILE = (
  'swagger-ui.css' => {
    sha256 => '40170f0ee859d17f92131ba707329a88a070e4f66874d11365e9a77d232f6117',
    max    => 524288,
  },
  'swagger-ui-bundle.js' => {
    sha256 => 'c2e4a9ef08144839ff47c14202063ecfe4e59e70a4e7154a26bd50d880c88ba1',
    max    => 4194304,
  },
);


has fetcher => (is => 'lazy');
has digests => (is => 'ro', default => sub { +{ map { $_ => $FILE{$_}{sha256} } keys %FILE } });
has retry_after => (is => 'ro', default => sub { 60 });
has timeout     => (is => 'ro', default => sub { 60 });

has _ua        => (is => 'lazy');
has _inflight  => (is => 'rw', default => sub { 0 });
has _waiters   => (is => 'ro', default => sub { [] });
has _failed_at => (is => 'rw');
has _failed    => (is => 'rw');

sub _build__ua {
  my $ua = Mojo::UserAgent->new;
  $ua->max_redirects(3);
  $ua->connect_timeout(10);
  $ua->request_timeout(60);
  $ua->inactivity_timeout(30);
  $ua->max_response_size(4194304 + 1024);
  return $ua;
}

sub _build_fetcher {
  my ($self) = @_;
  return sub {
    my ($url, $cb) = @_;
    $self->_ua->get($url => sub {
      my ($ua, $tx) = @_;
      my $err = $tx->error;
      return $cb->(undef, $err->{code} ? 'HTTP ' . $err->{code} : ($err->{message} // 'request failed'))
        if $err;
      return $cb->($tx->res->body, undef);
    });
  };
}


sub version    { $VERSION_PINNED }
sub source     { $SOURCE }
sub file_names { sort keys %FILE }


sub is_asset { defined $_[1] && exists $FILE{$_[1]} }


sub default_cache_dir {
  my ($self) = @_;
  my $leaf = 'swagger-ui-' . $VERSION_PINNED;
  my $xdg  = $ENV{XDG_CACHE_HOME};
  return "$xdg/skeid/$leaf" if defined($xdg) && $xdg =~ m{\A/};
  my $home = $ENV{HOME};
  return "$home/.cache/skeid/$leaf" if defined($home) && $home =~ m{\A/};
  return File::Spec->tmpdir . "/skeid-$</$leaf";
}


sub asset_path {
  my ($self, $dir, $name) = @_;
  return unless $self->is_asset($name);
  my $path = "$dir/$name";
  return -f $path ? $path : undef;
}


sub ready {
  my ($self, $dir) = @_;
  for my $name ($self->file_names) {
    return 0 unless defined $self->asset_path($dir, $name);
  }
  return 1;
}


sub ensure {
  my ($self, $dir, $cb) = @_;
  return $cb->(1) if $self->ready($dir);

  if (defined $self->_failed_at && Time::HiRes::time() - $self->_failed_at < $self->retry_after) {
    return $cb->(0, 'backoff', $self->_failed);
  }

  push @{$self->_waiters}, $cb;
  return if $self->_inflight;
  $self->_inflight(1);

  my %body;
  my @todo = $self->file_names;
  my $done = 0;
  my $finish;
  my $guard = Mojo::IOLoop->timer($self->timeout => sub {
    $finish->(0, 'swagger-ui fetch timed out') if $finish;
  });

  $finish = sub {
    my ($ok, $message) = @_;
    return if $done++;
    Mojo::IOLoop->remove($guard);
    if ($ok) {
      $ok = eval { $self->_store($dir, \%body); 1 };
      $message = 'swagger-ui cache directory is not writable' unless $ok;
    }
    if ($ok) {
      $self->_failed_at(undef);
      $self->_failed(undef);
    }
    else {
      $self->_failed_at(Time::HiRes::time());
      $self->_failed($message);
    }
    $self->_inflight(0);
    my @waiters = splice @{$self->_waiters};
    for my $w (@waiters) {
      eval { $w->($ok ? (1) : (0, 'fetch', $message)); 1 };
    }
    return;
  };

  for my $name (@todo) {
    my $url = $SOURCE . $name;
    my $called = 0;
    my $ok = eval {
      $self->fetcher->($url, sub {
        my ($content, $error) = @_;
        return if $called++ || $done;
        if (!defined $content) {
          return $finish->(0, "swagger-ui fetch failed: $url: " . ($error // 'no body'));
        }
        if (length($content) > $FILE{$name}{max}
          || sha256_hex($content) ne ($self->digests->{$name} // '')) {
          return $finish->(0, "swagger-ui fetch failed: $url: content does not match the pinned digest");
        }
        $body{$name} = $content;
        $finish->(1) if keys(%body) == @todo;
        return;
      });
      1;
    };
    $finish->(0, "swagger-ui fetch failed: $url: request could not be started") unless $ok;
  }
  return;
}

# Written under a temporary name and renamed, so a half-written file never answers a request.
# The directory is created private to the process's user.
sub _store {
  my ($self, $dir, $body) = @_;
  my $d = Mojo::File->new($dir);
  $d->make_path({mode => 0700});
  for my $name (sort keys %$body) {
    my $tmp = $d->child(".$name.$$.tmp");
    $tmp->spew($body->{$name});
    rename "$tmp", $d->child($name)->to_string or croak "rename failed: $!";
  }
  return;
}


sub index_html {
  return <<'HTML';
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Skeid API</title>
<link rel="stylesheet" href="/docs/swagger-ui.css">
</head>
<body>
<div id="swagger-ui"></div>
<script src="/docs/swagger-ui-bundle.js"></script>
<script src="/docs/init.js"></script>
</body>
</html>
HTML
}

sub init_js {
  return <<'JS';
(function () {
  var key = null;
  try { key = window.sessionStorage.getItem('skeid_key'); } catch (e) {}

  function load(attempt) {
    var headers = key ? { Authorization: 'Bearer ' + key } : {};
    return fetch('/openapi.json', { headers: headers }).then(function (res) {
      if (res.status === 401 && attempt < 2) {
        var given = window.prompt('Skeid API key');
        if (!given) { throw new Error('An API key is needed to read this API description'); }
        key = given;
        try { window.sessionStorage.setItem('skeid_key', key); } catch (e) {}
        return load(attempt + 1);
      }
      if (!res.ok) { throw new Error('GET /openapi.json answered ' + res.status); }
      return res.json();
    });
  }

  load(0).then(function (spec) {
    window.ui = window.SwaggerUIBundle({
      spec: spec,
      dom_id: '#swagger-ui',
      deepLinking: true,
      requestInterceptor: function (req) {
        if (key && !(req.headers && req.headers.Authorization)) {
          req.headers = req.headers || {};
          req.headers.Authorization = 'Bearer ' + key;
        }
        return req;
      }
    });
  }).catch(function (err) {
    document.getElementById('swagger-ui').textContent = String(err.message || err);
  });
})();
JS
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Skeid::SwaggerUI - Swagger UI assets, fetched on first use and cached, never shipped

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  my $ui = Langertha::Skeid::SwaggerUI->new;
  $ui->ensure($cache_dir, sub {
    my ($ok, $kind, $message) = @_;
    ...    # $ok: every asset is in $cache_dir
  });

=head1 DESCRIPTION

Skeid does not carry Swagger UI. When the config switches the UI on (C<openapi.swagger_ui>),
the first request for it fetches two files of the pinned C<swagger-ui-dist> release from
L</source>, checks each against the SHA-256 digest compiled in here, and writes them to the
cache directory; every later request is served from there. The fetch uses
L<Mojo::UserAgent> non-blocking (ADR 0005), at most one runs at a time, and requests that
arrive meanwhile wait for its result. A failed fetch is remembered for L</retry_after> seconds:
requests in that window are refused at once instead of starting another download (ADR 0025).

The release and the digests move together: raising L</version> without new digests makes every
fetch fail the check, which is the point.

=head2 fetcher

A coderef C<< ($url, $cb) >> that calls C<< $cb->($body, $error) >> -- the body of a C<200>,
else undef and a message. Default: a dedicated L<Mojo::UserAgent> with a response size limit
and timeouts. Tests inject their own, so no test reaches the network.

=head2 digests

File name to the SHA-256 hex digest a fetched file has to match (default: the pinned release's).
Only a test replaces it.

=head2 retry_after

Seconds a failed fetch is remembered (default 60).

=head2 timeout

Seconds after which a fetch that never answered counts as failed (default 60).

=head2 version

The pinned swagger-ui-dist version.

=head2 source

The base URL the assets are fetched from.

=head2 file_names

The asset file names, sorted.

=head2 is_asset

  $ui->is_asset('swagger-ui.css');

True for a name of a cached asset. The only names the file route serves, so a path never
reaches the file system from the request.

=head2 default_cache_dir

The cache directory used when the config names none:
C<$XDG_CACHE_HOME/skeid/swagger-ui-VERSION>, else C<$HOME/.cache/skeid/...>, else a per-uid
directory under the temp directory.

=head2 asset_path

  my $path = $ui->asset_path($dir, 'swagger-ui.css');

The cached file, or undef when it is not there.

=head2 ready

True when every asset is in the cache directory.

=head2 ensure

  $ui->ensure($dir, sub { my ($ok, $kind, $message) = @_; ... });

Calls back at once when the assets are cached; otherwise fetches them. C<$kind> is C<fetch>
for a fetch that just failed and C<backoff> for a request refused because one did. C<$message>
never carries more than the URL, a status and the check that failed -- nothing of the response.

=head2 index_html

The page served at C</docs>: a mount point and two script tags, no inline script.

=head2 init_js

The bootstrap script at C</docs/init.js>: loads C</openapi.json> -- asking for a key when the
config's C<client_auth> answers C<401>, keeping it in C<sessionStorage> only -- and hands it to
Swagger UI.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-skeid/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

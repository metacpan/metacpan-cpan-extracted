use v5.12.0;
use warnings;

use Test::More tests => 7;
use Email::Simple;

sub get_warning(&) {
  my $message;
  local $SIG{__WARN__} = sub { $message = $_[0] unless $message };
  $_[0]->();
  return $message;
}

like get_warning { Email::Simple->new("\N{U+100}: \N{U+100}") }, qr/^Message with wide characters at $0 /, 'Email::Simple->new warns with characters above 0xFF';

like get_warning { Email::Simple->create(body => "\N{U+100}") }, qr/^Body with wide characters at $0 /, 'Email::Simple->create warns with characters above 0xFF in body';

like get_warning { Email::Simple->create(header => [ "\N{U+100}" => "a" ]) }, qr/^Header name '\N{U+100}' with wide characters at $0 /, 'Email::Simple->create warns with characters above 0xFF in header name';

like get_warning { Email::Simple->create(header => [ a => "\N{U+100}" ]) }, qr/^Value '\N{U+100}' for 'a' header with wide characters at $0 /, 'Email::Simple->create warns with characters above 0xFF in header value';

my $m = Email::Simple->create();

like get_warning { $m->body_set("\N{U+100}") }, qr/^Body with wide characters at $0 /, 'Email::Simple->header_set warns with characters above 0xFF in body';

like get_warning { $m->header_set("\N{U+100}", "a") }, qr/^Header name '\N{U+100}' with wide characters at $0 /, 'Email::Simple->header_set warns with characters above 0xFF in header name';

like get_warning { $m->header_set("a", "\N{U+100}") }, qr/^Value for 'a' header with wide characters at $0 /, 'Email::Simple->header_set warns with characters above 0xFF in header value';

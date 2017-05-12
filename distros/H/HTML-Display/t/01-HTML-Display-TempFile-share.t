use strict;
use Test::More tests => 2;
use lib 'inc';
use IO::Catch;
use vars qw( $display $captured_html $_STDOUT_ $_STDERR_);

tie *STDOUT, 'IO::Catch', '_STDOUT_' or die $!;
tie *STDERR, 'IO::Catch', '_STDERR_' or die $!;
$SIG{__WARN__} = sub { $_STDERR_ .= join "", @_};

{ package HTML::Display::TempFile::Test;
  use parent 'HTML::Display::TempFile';

  sub browsercmd { qq{$^X -lne "" "%s" } };
};

SKIP: {
  use_ok("HTML::Display");

  $display = HTML::Display->new( class => 'HTML::Display::TempFile::Test' );
  $display->display("# Hello World");
  is($_STDERR_,undef,"Could launch tempfile program");
};

untie *STDOUT;
untie *STDERR;

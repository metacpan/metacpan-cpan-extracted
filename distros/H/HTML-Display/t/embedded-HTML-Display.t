#!/opt/perl/bin/perl -w

use Test::More 'no_plan';

package Catch;

sub TIEHANDLE {
	my($class, $var) = @_;
	return bless { var => $var }, $class;
}

sub PRINT  {
	my($self) = shift;
	${'main::'.$self->{var}} .= join '', @_;
}

sub OPEN  {}    # XXX Hackery in case the user redirects
sub CLOSE {}    # XXX STDERR/STDOUT.  This is not the behavior we want.

sub READ {}
sub READLINE {}
sub GETC {}
sub BINMODE {}

my $Original_File = 'lib/HTML/Display.pm';

package main;

# pre-5.8.0's warns aren't caught by a tied STDERR.
$SIG{__WARN__} = sub { $main::_STDERR_ .= join '', @_; };
tie *STDOUT, 'Catch', '_STDOUT_' or die $!;
tie *STDERR, 'Catch', '_STDERR_' or die $!;

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 15 lib/HTML/Display.pm
  my $html = "foo\n";
  %HTML::Display::os_default = ();
  delete $ENV{PERL_HTML_DISPLAY_CLASS};



  use strict;
  use HTML::Display;

  # guess the best value from $ENV{PERL_HTML_DISPLAY_CLASS}
  # or $ENV{PERL_HTML_DISPLAY_COMMAND}
  # or the operating system, in that order
  my $browser = HTML::Display->new();
  warn "# Displaying HTML using " . ref $browser;
  my $location = "http://www.google.com/";
  $browser->display(html => $html, location => $location);

  # Or, for a one-off job :
  display("<html><body><h1>Hello world!</h1></body></html>");




;

  }
};
is($@, '', "example from line 15");

{
    undef $main::_STDOUT_;
    undef $main::_STDERR_;
#line 15 lib/HTML/Display.pm
  my $html = "foo\n";
  %HTML::Display::os_default = ();
  delete $ENV{PERL_HTML_DISPLAY_CLASS};



  use strict;
  use HTML::Display;

  # guess the best value from $ENV{PERL_HTML_DISPLAY_CLASS}
  # or $ENV{PERL_HTML_DISPLAY_COMMAND}
  # or the operating system, in that order
  my $browser = HTML::Display->new();
  warn "# Displaying HTML using " . ref $browser;
  my $location = "http://www.google.com/";
  $browser->display(html => $html, location => $location);

  # Or, for a one-off job :
  display("<html><body><h1>Hello world!</h1></body></html>");




  is($::_STDOUT_,"foo\n<html><body><h1>Hello world!</h1></body></html>");

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
}

    undef $main::_STDOUT_;
    undef $main::_STDERR_;

    undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 81 lib/HTML/Display.pm

  # Install class for MagicOS
  $HTML::Display::os_default{"HTML::Display::MagicOS"}
    = sub { $^O =~ qr/magic/i };

;

  }
};
is($@, '', "example from line 81");

    undef $main::_STDOUT_;
    undef $main::_STDERR_;


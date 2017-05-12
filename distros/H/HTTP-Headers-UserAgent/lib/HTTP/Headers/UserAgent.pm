package HTTP::Headers::UserAgent;
# ABSTRACT: identify browser by parsing User-Agent string (deprecated)
$HTTP::Headers::UserAgent::VERSION = '3.09';
use 5.006;
use strict;
use warnings;

require Exporter;
our @ISA    = qw(Exporter);

use HTTP::BrowserDetect 1.77;

use vars qw($fh);

our @EXPORT_OK = qw( GetPlatform );

my %old = (
  irix    => 'UNIX',
  macos   => 'MAC',
  osf1    => 'UNIX',
  linux   => 'Linux',
  solaris => 'UNIX',
  sunos   => 'UNIX',
  bsdi    => 'UNIX',
  win16   => 'Win3x',
  win95   => 'Win95',
  win98   => 'Win98',
  winnt   => 'WinNT',
  winme   => 'WinME',
  win32   => undef,
  os2     => 'OS2',
  unknown => undef,
);

=head1 NAME

HTTP::Headers::UserAgent - identify browser by parsing User-Agent string (deprecated)

=head1 SYNOPSIS

  use HTTP::Headers::UserAgent;

  $user_agent = HTTP::Headers::UserAgent->new( $ENV{HTTP_USER_AGENT} );
  $browser = $user_agent->browser;
  $version = $user_agent->version;
  $os      = $user_agent->os;

  $platform = $user_agent->platform;

=head1 DESCRIPTION

This module, HTTP::Headers::UserAgent, is deprecated. I suggest you use one
of the other modules which provide the same functionality. Check the
SEE ALSO section for pointers. This module is being kept on CPAN for
the moment, in case someone is using it, but at some point in the future
it will probably be removed from CPAN.

This module is now just a wrapper around HTTP::BrowswerDetect, which is
still actively maintained. If you're still using this module, and have
a reason for not wanting to switch, please let me know, so I can either
help you migrate, or ensure the module continues to support your needs.

=head1 METHODS

=over 4

=cut

# was provided in previous versions, so now it's an undocumented
# backwards compatibility
sub DumpFile {
  shift;
}

=item new HTTP_USER_AGENT

Creates a new HTTP::Headers::UserAgent object.  Takes the HTTP_USER_AGENT
string as a parameter.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = { 'bd' => HTTP::BrowserDetect->new(shift) };
  bless( $self, $class);
}


=item string [ HTTP_USER_AGENT ]

If a parameter is given, sets the user-agent string.

Returns the user-agent as an unprocessed string.

=cut

sub string {
  my $self = shift;
  $self->{'bd'}->user_agent(@_);
}

=item platform

Tries to guess the platform.  Returns ia32, ppc, alpha, hppa, mips, sparc, or
unknown.

  ia32   Intel archetecure, 32-bit (x86)
  ppc    PowerPC
  alpha  DEC (now Compaq) Alpha
  hppa   HP
  mips   SGI MIPS
  sparc  Sun Sparc

This is the only function which is not yet implemented as a wrapper around
an equivalent function in HTTP::BrowserDetect.

=cut

sub platform {
  my $self = shift;
  for ( $self->{'bd'}{'user_agent'} ) {
    /Win/             && return "ia32";
    /Mac/             && return "ppc";
    /Linux.*86/       && return "ia32";
    /Linux.*alpha/    && return "alpha";
    /OSF/             && return "alpha";
    /HP-UX/           && return "hppa";
    /IRIX/            && return "mips";
    /(SunOS|Solaris)/ && return "sparc";
  }
  print $fh $self->string if $fh;
  "unknown";
}

=item os

Tries to guess the operating system.  Returns irix, win16, win95, win98, 
winnt, win32 (Windows 95/98/NT/?), macos, osf1, linux, solaris, sunos, bsdi,
os2, or unknown.

This is now a wrapper around HTTP::BrowserDetect methods.  Using
HTTP::BrowserDetect natively offers a better interface to OS detection and is
recommended.

=cut

sub os {
  my $self = shift;
  my $os = '';
  foreach my $possible ( qw(
    win31 win95 win98 winnt win2k winme win32 win3x win16 windows
    mac68k macppc mac
    os2
    sun4 sun5 suni86 sun irix
    linux
    dec bsd
  ) ) {
    $os ||= $possible if $self->{'bd'}->$possible();
  }
  $os = 'macos' if $os =~ /^mac/;
  $os = 'osf1' if $os =~ /^dec/;
  $os = 'solaris' if $os =~ /^sun(5$|i86$|$)/;
  $os = 'sunos' if $os eq 'sun4';
  $os = 'bsdi' if $os eq 'bsd';
  $os || 'unknown';
}

=item browser

Returns the name of the browser, or 'Unknown'.

This is now a wrapper around HTTP::BrowserDetect::browser_string

In previous versions of this module, the documentation said that this
method return a list with agent name and version. But it never did,
it jusr returned the browser name.

=cut

sub browser {
  my $self = shift;
  my $browser = $self->{'bd'}->browser_string();
  $browser = 'Unknown' unless defined $browser;
  $browser = 'IE' if $browser eq 'MSIE';
  $browser;
}

=item version

Returns the version of the browser, as a floating-point number.
Note: this means that version strings which aren't valid floating
point numbers won't be recognised.

This method is just a wrapper around the C<public_version()> method
in HTTP::BrowserDetect.

=cut

sub version
{
    my $self = shift;
    return $self->{'bd'}->public_version();
}

=back

=head1 BACKWARDS COMPATIBILITY

For backwards compatibility with HTTP::Headers::UserAgent 1.00, a GetPlatform
subroutine is provided.

=over 4

=item GetPlatform HTTP_USER_AGENT

Returns Win95, Win98, WinNT, UNIX, MAC, Win3x, OS2, Linux, or undef.

In some cases ( `Win32', `Windows CE' ) where HTTP::Headers::UserAgent 1.00
would have returned `Win95', will return undef instead.

Will return `UNIX' for some cases where HTTP::Headers::UserAgent would have
returned undef.

=cut

sub GetPlatform {
  my $string = shift;
  my $object = HTTP::Headers::UserAgent->new($string);
  $old{ $object->os };
}

=back

=head1 SEE ALSO

I have written a L<review|http://neilb.org/reviews/user-agent.html> of all CPAN modules for parsing the User-Agent string.
If you have a specific need, it may be worth reading the review, to find
the best match.

In brief though, I would recommend you start off with one of the following
modules:

=over

=item HTML::ParseBrowser

Has best overall coverage of different browsers and other user agents.

=item HTTP::UserAgentString::Parser

Also has good coverage, but is much faster than the other modules,
so if performance is important as well, you might prefer this module.

=item HTTP::BrowserDetect

Poorest coverage of the three modules listed here, and doesn't do well at
recognising version numbers. It's the best module for detecting whether
a given agent is a robot/crawler though.

=back

=head1 REPOSITORY

L<https://github.com/neilb/HTTP-Headers-UserAgent>

=head1 AUTHOR

This module is now maintained by Neil Bowers <neilb@cpan.org>.

The previous maintainer, who wrote this version, was Ivan Kohler.

Portions of this software were originally taken from the Bugzilla Bug
Tracking system <http://www.mozilla.org/bugs/>, and are reused here with
permission of the original author, Terry Weissman <terry@mozilla.org>.

=head1 COPYRIGHT

Copyright (c) 2001 Ivan Kohler.  All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;


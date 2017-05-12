package File::HomeDir::Win32;

use 5.006;
use strict;
use warnings;

my %Registry;

use Carp;
use Win32;
use Win32::Security::SID;
use Win32::TieRegistry ( TiedHash => \%Registry );

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw( home ) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( home );

our $VERSION = '0.04';

my %HomeDirs;

sub import {
  no strict 'refs';

  my $caller = caller(0);
  my $stash  = *{$caller."::"};

  sub _set_stash {
    my $value  = shift;
    my $caller = shift;
    my $stash  = *{$caller."::"};

    my @names  = split /::/, shift;

    # print STDERR join(" ", @names), "\n";

    while (my $level = shift @names) {
      $level .= "::",
	if (@names);
      return,
	unless (defined $stash->{$level});
      if (@names) {
	$stash = $stash->{$level};
      } else {
	no warnings 'redefine';
	$stash->{$level} = $value,
	  if ((defined &{$stash->{$level}}) && ((ref $value) eq "CODE"));
      }
    }
  }

  # print STDERR "caller = $caller\n";

  _find_homedirs(), unless (keys %HomeDirs);
  if ((keys %HomeDirs) && (defined &{$stash->{home}})) {
    if (@_ > 1) {
      carp "Exporter arguments ignored";
    }

    _set_stash(\&home, $caller, "home");

    _set_stash(\&home, $caller, "File::HomeDir::home");
    _set_stash(\&home, "main", "File::HomeDir::home"),
      if ($caller ne "main");

    return;
  }
  else {
    croak "Fatal error: cannot find profiles in Windows registry"
      unless (keys %HomeDirs);
    goto &Exporter::import;
  }
}

sub _find_homedirs {
  %HomeDirs    = ( );

  my $node_name   = Win32::NodeName;
  my $domain_name = Win32::DomainName;

  my $profiles = $Registry{'HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\ProfileList\\'};
  unless ($profiles) {
    # Windows 98
    $profiles = $Registry{'HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\ProfileList\\'};  
  }
  unless ($profiles) {
    return;
  }

  foreach my $p (keys %$profiles) {
    if ($p =~ /^(S(?:-\d+)+)\\$/) {
      my $sid_str = $1;
      my $sid = Win32::Security::SID::ConvertStringSidToSid($1);
      my $uid = Win32::Security::SID::ConvertSidToName($sid);
      my $domain = "";
      if ($uid =~ /^(.+)\\(.+)$/) {
	$domain = $1;
	$uid    = $2;
      }
      if ($domain eq $node_name || $domain eq $domain_name) {
	my $path = $profiles->{$p}->{ProfileImagePath};
	$path =~ s/\%(.+)\%/$ENV{$1}/eg;
	$HomeDirs{$uid} = $path;
      }
    }
  }
}

sub home(;$) {
  my $user = $ENV{USERNAME};
  $user = shift if (@_);
  croak "Can\'t use undef as a username" unless (defined $user);

  _find_homedirs(), unless (keys %HomeDirs);

  if (exists $HomeDirs{$user}) {
    return $HomeDirs{$user};
  }
  else {
    return;
  }
}

1;

__END__

=head1 NAME

File::HomeDir::Win32 - Find home directories on Win32 systems

=begin readme

=head1 REQUIREMENTS

This package requires Perl 5.6.0 and following modules (most of which
are not included with Perl):

  Win32::Security::SID
  Win32::TieRegistry

=head1 INSTALLATION

Installation can be done using the traditional Makefile.PL or the newer
Build.PL methods.

Using Makefile.PL:

  perl Makefile.PL
  make test
  make install

(On Windows platforms you should use C<nmake> instead.)

Using Build.PL on systems with L<Module::Build> installed:

  perl Build.PL
  perl Build test
  perl Build install

=end readme

=head1 SYNOPSIS

  use File::HomeDir::Win32;

  print "My dir is ",home()," and root's is ",home('Administrator'),"\n";

=head1 DESCRIPTION

This module provides routines for finding home directories on Win32 systems.
It was designed as a companion to L<File::HomeDir> that overrides the
existing C<home> function, which does not properly locate home directories
on Windows machines.

=for readme stop

To use both modules together:

  use File::HomeDir;

  BEGIN {
    if ($^O eq "MSWin32") {
      eval {
        require File::HomeDir::Win32;
        File::HomeDir::Win32->import();
      };
      die "$@" if ($@); 
    }
  }

or (if you have the L<if> module),

  use File::HomeDir;
  use if ($^O eq "MSWin32"), "File::HomeDir::Win32";

The C<home> function should work as normal.

On systems with no profiles, such as Windows 98, or in cases where it
cannot find profiles, it will not override L<File::HomeDir>. (In such
cases it will die if L<File::HomeDir> is not loaded.)

=begin readme

See the module documentation for more details.

=head1 REVISION HISTORY

The following changes have been made since the last release:

=for readme include file="Changes" start="^0.03" stop="^0.02" type="text"

See the F<Changes> file for a detailed history.

=end readme

=for readme continue

=head1 SEE ALSO

  File::HomeDir

=head1 AUTHOR

Robert Rothenberg <rrwo at cpan.org>

Current maintainer: Randy Kobes <r.kobes at uwinnipeg.ca>

=head2 Suggestions and Bug Reporting

Feedback is always welcome.  Please use the CPAN Request Tracker at
L<http://rt.cpan.org> to submit bug reports.

=head1 LICENSE

Copyright (c) 2005 Robert Rothenberg. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

package Devel::TrackSIG;
use strict;
use warnings;
use Carp;
eval "use Carp::Heavy;";
require Tie::Hash;
our @ISA = qw(Tie::ExtraHash);

our $VERSION = '0.04';

tie %main::SIG => __PACKAGE__;

our %opt = (
  track_source => 1,
  report_write_access => 0,
);

sub import {
  my $class = shift;
  my %args = @_;

  $opt{$_} = $args{$_} for keys %args;
}


sub DELETE {
  _report($_[0], $_[1], 'DELETE');
  return delete $_[0]->[0]->{$_[1]};
}

sub STORE {
  _report($_[0], $_[1], 'STORE');
  return $_[0]->[0]->{$_[1]} = $_[2];
}

sub CLEAR {
  _report($_[0], '', 'CLEAR');
  %{$_[0]->[0]} = ();
}


sub _report {
  my $obj = shift;
  my $key = shift;
  my $action = shift;

  
  push @$obj, {} if @$obj < 2;

  my $sources = $obj->[1];

  my $msg = do {
    my $i;
    my @stack;
    while ( my @caller = caller $i++ ) {
      push @stack, sprintf '    %s::%s called at %s line %s', @caller[0,3,1,2];
    }
    "${action}ing signal handler '$key' at\n" . join("\n", @stack );
  };

  if ($opt{track_source}) {
    $sources->{$key} = $msg;
  }
  if ($opt{report_write_access}) {
    print STDERR $msg . "\n";
  }
}

sub get_source {
  my $self = shift;
  my $key = shift;
  print STDERR "Source tracking not enabled. Pass the track_source => 1 option when loading TrackSIG to enable\n"
    if not $opt{track_source};
  return '' if not @{$self} > 1;
  return $self->[1]->{$key};
}

sub dump_all_sources {
  my $self = shift;
  print STDERR "Source tracking not enabled. Pass the track_source => 1 option when loading TrackSIG to enable\n"
    if not $opt{track_source};
  return if not @{$self} > 1;
  my $sources = $self->[1];
  foreach my $key (keys %$sources) {
    print STDERR "\$SIG{$key} was last set at:\n" . $sources->{$key} . "\n\n";
  }
}

1;

__END__


=head1 NAME

Devel::TrackSIG - Track those pesky signal handlers

=head1 SYNOPSIS

At the VERY start of your script:

  use Devel::TrackSIG;

Then, somewhen deep inside the codebase:

  warn "Foo\n"; # WHY DOESN'T THIS GO TO MY SCREEN?

So you add a debugging line like this:

  print STDERR tied(%SIG)->get_source('__WARN__');
  warn "Foo\n"; # WHY DOESN'T THIS GO TO MY SCREEN?

Or more comprehensively like this:

  tied(%SIG)->dump_all_sources;
  warn "Foo\n"; # WHY DOESN'T THIS GO TO MY SCREEN?

=head1 DESCRIPTION

Let's face it, signal handlers are a mess.
Sometimes, output simply disappears into a maze of twisty little
handlers all alike and B<YOU CANNOT FIND OUT WHY!>

Well, now you can. Maybe. This module tells you where
each and every signal handler in effect was set.

Doing this requires some ugly hacks, so don't leave this in production
code!

=head2 Import Options

When loading the module, you can pass any of two named options:

=over 2

=item track_source (default: 1)

When enabled, all writing C<%SIG> accesses are tracked for
later reporting.

=item report_write_access (default: 0)

Always shows a stack trace on writing C<%SIG> access.

=back

=head2 get_source

Given the name of the signal handler you care about,
returns the backtrace from its origin.

=head2 dump_all_sources

Dumps all signal handlers origin backtraces to STDERR.
Includes those signal handlers for which the last access was
actually deletion. (Except for falling out of scope due to a
C<local>. In this case, we revert to the previous backtrace.)

=head1 AUTHOR

Steffen Mueller, C<smueller@cpan.org>

=head1 ACKNOWLEDGMENT

This module was originally developed for booking.com.
With approval from booking.com, this module was generalized
and put on CPAN, for which the author would like to express
his gratitude.

=head1 COPYRIGHT AND LICENSE

 (C) 2010-2012 Steffen Mueller. All rights reserved.
 
 This code is available under the same license as Perl version
 5.8.1 or higher.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut


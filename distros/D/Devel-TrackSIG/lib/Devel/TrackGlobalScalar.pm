package Devel::TrackGlobalScalar;
use strict;
use warnings;
use Carp;
eval "use Carp::Heavy;";
require Tie::Scalar;
our @ISA = qw(Tie::StdScalar);

our $VERSION = '0.03';

our %opt = (
  track_source => 1,
  report_write_access => 0,
);

our %globals;

sub import {
  my $class = shift;
  my $globals = shift;
  die if not defined $globals;
  $globals = [$globals] if not ref $globals;

  my %args = @_;
  $opt{$_} = $args{$_} for keys %args;

  foreach my $global (@$globals) {
    my $global_esc = $global;
    $global_esc =~ s/\\/\\\\/g;
    $global_esc =~ s/'/\\'/g;

    my $rv;
    my $code = "\$rv = tie($global, __PACKAGE__, \\$global, '$global_esc'); 1";
    eval $code or die "Failed to tie global '$global': $@";
  }
}



sub TIESCALAR {
  my $class = shift;
  my $instance = shift || undef;
  my $name = shift;

  my $o = bless [\$instance, $name] => $class;
  $globals{$name} = $o;
  return $o;
}

sub FETCH {
  #_report($_[0], 'FETCH');
  return ${$_[0][0]};
}

sub STORE {
  _report($_[0], 'STORE');
  ${$_[0][0]} = $_[1];
}

sub DESTROY {
  _report($_[0], 'DESTROY');
  undef ${$_[0][0]};
}

sub _report {
  my $obj = shift;
  my $action = shift;

  my $global_name = $obj->[1];

  my $msg = Carp::longmess("${action}ing global '$global_name' at");
  if ($opt{track_source}) {
    $obj->[2] = $msg;
  }
  if ($opt{report_write_access}) {
    print STDERR $msg . "\n";
  }
}

sub get_source {
  my $self = shift;
  my $key = shift;
  print STDERR "Source tracking not enabled. Pass the track_source => 1 option when loading TrackGlobalScalar to enable\n"
    if not $opt{track_source};
  return '' if not @{$self} > 2;
  return $self->[2];
}

sub dump_all_sources {
  my $class = shift;
  print STDERR "Source tracking not enabled. Pass the track_source => 1 option when loading TrackGlobalScalar to enable\n"
    if not $opt{track_source};

  my $sources = \%globals;
  foreach my $key (keys %$sources) {
    if (defined ($sources->{$key}->[2])) {
      print STDERR "$key was last set at:\n" . $sources->{$key}->[2] . "\n\n";
    }
  }
}

1;

__END__


=head1 NAME

Devel::TrackGlobalScalar - Track those pesky global variables

=head1 SYNOPSIS

At the VERY start of your script:

  use Devel::TrackGlobalScalar [qw($/ $|)], track_source => 1;

Then, somewhen deep inside the codebase:

  $/ = \32768;

and back in your code base, all readline()s suddenly read
exactly 32768 bytes and you do not know where $/ was mucked with.

So to a place where you know the readline() call behaves different
than expected, you add a debugging line like this:

  print STDERR tied($/)->get_source();

Or more comprehensively like this:

  Devel::TrackGlobalScalar->dump_all_sources;

=head1 DESCRIPTION

Nobody likes global variables. They incur action at a distance.
It can be horrible to find out where they were modified when all
you have is the action. Particularly in the millions of lines of
Perl we work with at booking.com.

This module tries to mitigate the problem by providing a mechanism to
track all accesses to global scalars.

Doing this requires some ugly hacks, so don't leave this in production
code!

=head2 Import Options

When loading the module, the first parameter must be
a string indicating the global you want to track or an array reference
containing multiple such strings. Thereafter, you can pass any of
two named options:

=over 2

=item track_source (default: 1)

When enabled, all writing accesses to the chosen globals
are tracked for
later reporting.

=item report_write_access (default: 0)

Always shows a stack trace on writing access to the globals.

=back

=head2 get_source

Given the name of the signal handler you care about,
returns the backtrace from its origin.

=head2 dump_all_sources

Dumps all tracked globals' origin backtraces to STDERR.
Includes those variables for which the last access was
actually undef(). (Except for falling out of scope due to a
C<local>. In this case, we revert to the previous backtrace.)

=head1 AUTHOR

Steffen Mueller, C<smueller@cpan.org>

=head1 ACKNOWLEDGMENT

This module was originally developed for booking.com.
With approval from booking.com, this module was generalized
and put on CPAN, for which the author would like to express
his gratitude.

=head1 COPYRIGHT AND LICENSE

 (C) 2012 Steffen Mueller. All rights reserved.
 
 This code is available under the same license as Perl version
 5.8.1 or higher.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut


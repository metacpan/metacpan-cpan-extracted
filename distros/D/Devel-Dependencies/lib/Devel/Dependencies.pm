package Devel::Dependencies;

use 5.006001;

package Devel::Dependencies;

# We don't actually
#   use strict;
#   use warnings;
# Because if we did, then we wouldn't be able to tell whether the
# target code used those pragmata. Thanks/blame TOBYINK for this :-)
my $cpants = q/
use strict;
use warnings;
#/;

our $VERSION = '1.04';

my %opt;

my %known;
@known{qw( origin distance time )} = ();

sub import {
  shift if @_;
  while (@_) {
    my $opt = shift;
    if (exists $known{$opt}) {
      $opt{$opt} = 1;
    } else {
      die 'invalid ', __PACKAGE__, " option '$opt'";
    }
  }
}

my %init_inc;

BEGIN {
  %init_inc = %INC;
}

CHECK {

  my @inc = grep { !exists $init_inc{$_} } sort keys %INC;

  my ($start, $bias);

  if ($opt{time}) {
    $bias = !exists $INC{'Time/HiRes.pm'};
    require Time::HiRes;
    $start = [ Time::HiRes::gettimeofday() ];
  }

  print __PACKAGE__, ' finds ', scalar(@inc), " dependencies:\n";

  my $total_distance = 0;

  for (@inc) {
    print '  ',  $_;
    my $distance = 0;
    for my $lib (@INC) {
      ++$distance;
      last if "$lib/$_" eq $INC{$_};
    }
    $total_distance += $distance;
    print " $INC{$_}" if $opt{origin};
    print " ($distance)" if $opt{distance};
    print "\n";
  }

  print "Consolidated module distance: $total_distance\n" if $opt{distance};

  if ($opt{time}) {
    print "Time spent loading modules ";
    print "(including the time I spent loading Time::HiRes)" if $bias;
    print ': ', Time::HiRes::tv_interval($start), "\n";
  }
}

1;
__END__

=head1 NAME

Devel::Dependencies - Perl extension for examining dependencies on modules

=head1 SYNOPSIS

  perl -MDevel::Dependencies <perl_file>
  perl -MDevel::Dependencies=<opts> <perl_file>

=head1 DESCRIPTION

This module lists all the modules loaded by a program or a
module at compilation time.

More accurately, Devel::Dependencies uses a C<BEGIN> and a C<CHECK>
block to find the changes in %INC.

Devel::Dependencies accepts any combination of the following options.
For more information on passing options from the command line, see L<perlrun>.

=over 4

=item origin

Display the path to the file the module was loaded from.

=item distance

Display the distance of each module, i.e. the posotion of the
path in @INC from which the module was loaded. Also display the
sum of the distances of all the modules.

=item time

Display how much time was spend loading modules (i.e. between its
C<BEGIN> and C<CHECK> blocks were executed). To do that it may need
to load Time::HiRes if your program hasn't loaded it already, and
the time it takes will add up to the total time; in that case it will
warn about it.

=back

=head1 SEE ALSO

L<http://neilb.org/reviews/dependencies.html> - a review of CPAN
modules for getting dependency information.

L<perlrun>, L<perlvar>.

=head1 REPOSITORY

https://github.com/neilb/Devel-Dependencies

=head1 AUTHOR

Jean-Louis Leroy, Europerl, E<lt>jll@europerl.beE<gt>

Now maintained by Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Jean-Louis Leroy and Sound Object Logic

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

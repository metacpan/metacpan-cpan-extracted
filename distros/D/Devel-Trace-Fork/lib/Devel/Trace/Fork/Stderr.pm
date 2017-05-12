# -* - perl -*-

package Devel::Trace::Fork;
use Devel::Trace;
use Time::HiRes qw(gettimeofday);
use IO::Handle;
use Carp;
use strict qw(vars subs);
use warnings;
our $VERSION = '0.11';
our $STDERR;
our $_PID2 = $$;
our $_PID = $$;
our $SORT_NEEDED = 0;
our %IGNORE_PACKAGES = ('Devel::Trace::Fork' => 1);
$| = 1;

BEGIN {
  local $! = undef;
  open $STDERR, '>&STDERR';
  $STDERR->autoflush(1);
  print $STDERR ">  $^X $0 @ARGV\n";
  print $STDERR "> $^T ",scalar gettimeofday(),"\n";
}

no warnings 'redefine';
sub DB::DB {
  return unless $Devel::Trace::TRACE;
  my ($p, $f, $l) = caller;
  my $t;
  if ($_PID2 != $$) { 
    $t = sprintf '%11.6f', gettimeofday()-$^T;
    print $STDERR ">> $t:$$: ----------------- NEW PROCESS -----------------\n";
    $_PID2 = $$;
  }
  if (!defined $IGNORE_PACKAGES{$p}) {
    $t ||= sprintf '%11.6f', gettimeofday()-$^T;

    my $code = \@{"::_<$f"};
    my $cde = $code->[$l] || "--- code not available ---\n";
    if (!defined $f) {
      print $STDERR "$0 \$f not defined, $p, $f, $l\n";
    }
    if (!defined $l) {
      print $STDERR "$0 \$l not defined $p, $f, $l\n";
    }
    if (!defined $code) {
      print $STDERR "$0 \$code not defined $p, $f, $l\n";
    } elsif (!defined $cde) {
      print $STDERR "$0 \$cde, \$code->[\$l] not defined $p, $f, $l\n";
    }


    print $STDERR ">> $t:$$:$?:$f:$l: $cde";
  }
  return;
}

END {
  $Devel::Trace::TRACE = 0;
  my $t = sprintf '%11.6f', gettimeofday()-$^T;
  print $STDERR ">> $t:$$: -------------- END OF PROCESS ------------------\n";
}

1;

__END__

=head1 NAME

Devel::Trace::Fork::Stderr 
- Variant of Devel::Trace::Fork that outputs to standard error

=head1 VERSION

0.11

=head1 SYNOPSIS

    perl -d:Trace::Fork::Stderr program

=head1 DESCRIPTION

Like Mark Jason Dominus's L<Devel::Trace> module, 
but debugging output includes additional information like

=over 4

=item *

a high-resolution timestamp for the time each statement
was executed

=item *

the process id of the process that executes each statement

=item * 

the current value of the L<$CHILD_ERROR|perlvar/"$CHILD_ERROR">
variable (C<$?>)

=back

This additional information
can be helpful for debugging programs that make use of the
L<< fork|perlfunc/fork >> system call to run. For example,
the C<Trace::Fork> output of this program:

    if (fork() == 0) {
        print "This is the child.\n";
        exit 0;
    }
    print "This is the parent.\n";

will be a file that looks something like:

    /usr/bin/perl test
    1268025451 1268025451.815
    >>    0.816214:7996:0:test:1: if (fork() == 0) {
    >>    0.826566:7996:0:test:5: print "This is the parent.\n";
    >>    0.826684:9572:0:test:2:     print "This is the child.\n";
    >>    0.826941:9572:0:test:3:     exit 0;

=head1 DETAILS

Like L<Devel::Trace>, debugging output is printed to
C<STDERR>. To redirect debugging output to a separate file,
see L<Devel::Trace::Fork>.

See L<Devel::Trace>. Use the C<$Devel::Trace::TRACE> variable
or the C<Devel::Trace::trace> function exactly the way you
would use them with the pure C<Devel::Trace> module. To import
the C<Devel::Trace::trace> function into your program's
namespace, include the line:

    use Devel::Trace 'trace';

somewhere in your program.

=head1 SUBROUTINES/METHODS

None

=head1 DEPENDENCIES

    Devel::Trace

=head1 BUGS AND LIMITATIONS

If there are child processes that exit later than the
parent process, then the final output will not be sorted.

There is almost enough information in the trace output
to use it for profiling. Almost.

=head1 SEE ALSO

L<Devel::Trace>, L<Devel::Trace::More>, L<Devel::Trace::Fork>

=head1 AUTHOR

Marty O'Brien, E<lt>mob@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, Marty O'Brien

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

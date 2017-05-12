package Devel::Trace::Cwd;
BEGIN {
  $Devel::Trace::Cwd::VERSION = '0.02';
}

#ABSTRACT: Print out each line before it is executed and track cwd changes

use strict;
use warnings;
use Cwd ();

our $TRACE = 1;
our $CWD;

# This is the important part.  The rest is just fluff.
sub DB::DB {
  return unless $TRACE;
  my ($p, $f, $l) = caller;
  my $code = \@{"::_<$f"};
  print STDERR ">> $f:$l: $code->[$l]";
  my $ctmp = Cwd::getcwd();
  if ( !$CWD or $CWD ne $ctmp ) {
    $CWD = $ctmp;
    print STDERR "CWD: '$CWD'\n";
  }
}


sub import {
  my $package = shift;
  foreach (@_) {
    if ($_ eq 'trace') {
      my $caller = caller;
      *{$caller . '::trace'} = \&{$package . '::trace'};
    } else {
      use Carp;
      croak "Package $package does not export `$_'; aborting";
    }
  }
}

my %tracearg = ('on' => 1, 'off' => 0);
sub trace {
  my $arg = shift;
  $arg = $tracearg{$arg} while exists $tracearg{$arg};
  $TRACE = $arg;
}

1;



__END__
=pod

=head1 NAME

Devel::Trace::Cwd - Print out each line before it is executed and track cwd changes

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  perl -d:Trace::Cwd program

=head1 DESCRIPTION

If you run your program with C<perl -d:Trace::Cwd program>, this module
will print a message to standard error just before each line is executed.  
For example, if your program looks like this:

        #!/usr/bin/perl
        
        
        print "Statement 1 at line 4\n";
        print "Statement 2 at line 5\n";
        print "Call to sub x returns ", &x(), " at line 6.\n";
        
        exit 0;
        
        
        sub x {
          print "In sub x at line 12.\n";
          return 13;
        }

Then  the C<Trace> output will look like this:

        >> ./test:4: print "Statement 1 at line 4\n";
        >> ./test:5: print "Statement 2 at line 5\n";
        >> ./test:6: print "Call to sub x returns ", &x(), " at line 6.\n";
        >> ./test:12:   print "In sub x at line 12.\n";
        >> ./test:13:   return 13;
        >> ./test:8: exit 0;

This is something like the shell's C<-x> option.

If the current working directory changes during execution that will be printed to standard error
with a C<CWD:> prefix.

=head1 DETAILS

Inside your program, you can enable and disable tracing by doing

    $Devel::Trace::Cwd::TRACE = 1;   # Enable
    $Devel::Trace::Cwd::TRACE = 0;   # Disable

or

    Devel::Trace::Cwd::trace('on');  # Enable
    Devel::Trace::Cwd::trace('off'); # Disable

=over

=item C<trace>

C<Devel::Trace> exports the C<trace> function if you ask it to:

    import Devel::Trace::Cwd 'trace';

Then if you want you just say

    trace 'on';                 # Enable
    trace 'off';                # Disable

=back

=head1 TODO

=over 4

=item *

You should be able to  send the trace output to the filehandle of your choice.

=item *

You should be able to specify the format of the output.

=item *

You should be able to get the output into a string.

=back

We'll see.

=head1 BASED ON Devel::Trace

Mark-Jason Dominus (C<mjd-perl-trace@plover.com>), Plover Systems co.

See the C<Devel::Trace.pm> Page at http://www.plover.com/~mjd/perl/Trace
for news and upgrades.  

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Chris Williams and Mark-Jason Dominus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


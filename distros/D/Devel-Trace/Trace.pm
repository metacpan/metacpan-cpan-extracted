# -*- perl -*-

package Devel::Trace;
$VERSION = '0.12';
$TRACE = 1;

# This is the important part.  The rest is just fluff.
sub DB::DB {
  return unless $TRACE;
  my ($p, $f, $l) = caller;
  my $code = \@{"::_<$f"};
  print STDERR ">> $f:$l: $code->[$l]";
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


=head1 NAME

Devel::Trace - Print out each line before it is executed (like C<sh -x>)

=head1 SYNOPSIS

  perl -d:Trace program

=head1 DESCRIPTION

If you run your program with C<perl -d:Trace program>, this module
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

=head1 DETAILS

Inside your program, you can enable and disable tracing by doing

    $Devel::Trace::TRACE = 1;   # Enable
    $Devel::Trace::TRACE = 0;   # Disable

or

    Devel::Trace::trace('on');  # Enable
    Devel::Trace::trace('off'); # Disable


C<Devel::Trace> exports the C<trace> function if you ask it to:

    import Devel::Trace 'trace';

Then if you want you just say

    trace 'on';                 # Enable
    trace 'off';                # Disable


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

=head1 LICENSE

Devel::Trace 0.11 and its source code are hereby placed in the public domain.

=head1 Author

=begin text

Mark-Jason Dominus (C<mjd-perl-trace@plover.com>), Plover Systems co.

See the C<Devel::Trace.pm> Page at http://www.plover.com/~mjd/perl/Trace
for news and upgrades.  

=end text

=begin man

Mark-Jason Dominus (C<mjd-perl-trace@plover.com>), Plover Systems co.

See the C<Devel::Trace.pm> Page at http://www.plover.com/~mjd/perl/Trace
for news and upgrades.  

=end man

=begin html
<p>Mark-Jason Dominus (<a href="mailto:mjd-perl-trace@plover.com"><tt>mjd-perl-trace@plover.com</tt></a>), Plover Systems co.</p>
<p>See <a href="http://www.plover.com/~mjd/perl/Trace/">The <tt>Devel::Trace.pm</tt> Page</a> for news and upgrades.</p>

=end html


=cut


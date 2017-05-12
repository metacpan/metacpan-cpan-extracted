package IO::Capture::Extended::Overview;
use strict;

########## DOCUMENTATION ##########

=head1 NAME

IO::Capture::Extended - Extend functionality of IO::Capture

=head1 SYNOPSIS

The programmer interface consists of two classes:

=head2 IO::Capture::Stdout::Extended

    use IO::Capture::Stdout::Extended;

    $capture = IO::Capture::Stdout::Extended->new();
    $capture->start();
    # some code that prints to STDOUT
    $capture->stop();

    # scalar context:  return number of print statements with 'fox'
    $matches = $capture->grep_print_statements('fox');

    # list context:  return list of print statements with 'fox'
    @matches = $capture->grep_print_statements('fox');

    # return number of print statements
    $matches = $capture->statements;

    # scalar context:  return number of pattern matches
    $regex = qr/some regular expression/;
    $matches = $capture->matches($regex);

    # list context:  return list of pattern matches
    @matches = $capture->matches($regex);

    # return reference to array holding list of pattern matches
    $matchesref = $capture->matches_ref($regex);

    # scalar context:  return number of 'screen' lines printed
    $screen_lines = $capture->all_screen_lines();

    # list context:  return list of 'screen' lines printed
    @all_screen_lines = $capture->all_screen_lines();

=head2 IO::Capture::Stderr::Extended

    $capture = IO::Capture::Stderr::Extended->new();
    $capture->start();
    # some code that prints to STDERR
    $capture->stop();

... and then use all the methods defined above for
F<IO::Capture::Stdout::Extended>.

=head1 DESCRIPTION

IO::Capture::Extended is a distribution consisting of two classes, each
of which is a collection of subroutines which are useful in extending 
the functionality of CPAN modules IO::Capture::Stdout and 
IO::Capture::Stderr, particularly when used in a testing context 
such as that provided by Test::Simple, Test::More or other modules 
built on Test::Builder.

=head1 USAGE

=head2 Requirements

IO::Capture distribution, available from CPAN 
L<http://search.cpan.org/~reynolds/IO-Capture-0.05/>.  Use version 0.05
or later to take advantage of important bug fixes.  The IO::Capture 
distribution includes base class IO::Capture,  IO::Capture::Stdout, 
IO::Capture::Stderr  and other packages.  It also includes useful 
documentation in IO::Capture::Overview.

=head2 General Comments

The IO::Capture::Stdout::Extended and IO::Capture::Stdout::Extended 
methods are designed to provide 
return values which work nicely as arguments to Test::More functions 
such as C<ok()>, C<is()> and C<like()>.  The examples below illustrate
that objective.  Suggestions are welcome for additional methods 
which would fulfill that objective.

=head2 Individual Methods

B<Note:>  Since IO::Capture::Extended is structured so as to make
exactly the same methods available for IO::Capture::Stdout::Extended
I<and> IO::Capture::Stderr::Extended, whenver there appears below a
reference to, I<e.g.,>
C<IO::Capture::Stdout::Extended::grep_print_statements()>, you should
assume that the remarks apply equally to
C<IO::Capture::Stderr::Extended::grep_print_statements()>.  Wherever
reference is made to STDOUT, the remarks apply to STDERR as well.

=head3 C<grep_print_statements()>

=over 4

=item * Scalar Context

I<Problem:>  You wish to test a function that prints to STDOUT.  
You can
predict the I<number> of C<print> statements that match a pattern and wish
to test that prediction.  (The example below is adapted from
IO::Capture::Overview.)

    sub print_fox {
        print "The quick brown fox jumped over ...";
        print "garden wall";
        print "The quick red fox jumped over ...";
        print "garden wall";
    }

    $capture->start;
    print_fox();
    $capture->stop;
    $matches = $capture->grep_print_statements('fox');
    is($capture->grep_print_statements('fox'), 2, 
        "correct no. of print statements grepped");

I<Solution:>  Precede the function call with a call to the
IO::Capture::Stdout::Extended 
C<start()> method and follow it with a call to the C<stop()> method.
Call C<grep_print_statements>.  Use its
return value as one of two arguments to C<Test::More::is()>.  Use your
prediction as the other argument.  Add a useful comment to C<is()>.

I<Potential Pitfall:>  The number of print statements captured between
C<IO::Capture::Stdout::Extended::start()> and C<stop()> is I<not> 
necessarily the number of lines that would
appear to be printed to standard output by a given block of code.  If
your subroutine or other code block prints partial lines -- I<i.e.,>
lines lacking C<\n> newline characters -- the number of print statements
will be greater than the number of ''screen lines.''  This is
illustrated by the following:

    sub print_fox_long {
        print "The quick brown fox jumped over ...";
        print "a less adept fox\n";
        print "The quick red fox jumped over ...";
        print "the garden wall\n";
    }

    $capture->start;
    print_fox_long();
    $capture->stop;
    $matches = $capture->grep_print_statements("fox");
    is($capture->grep_print_statements("fox"), 3, 
        "correct no. of print statements grepped");

The number of C<print> statements matching C<fox> is three -- even though
the number of lines on the screen which appear on STDOUT containing
C<fox> is only two.

=item * List Context

I<Problem:>  As above, you wish to test a function that prints to STDOUT.  
This time, you can predict the I<content> of C<print> statements that 
match a pattern and wish to test that prediction.

    %matches = map { $_, 1 } $capture->grep_print_statements('fox');
    is(keys %matches, 2, "correct no. of print statements grepped");
    ok($matches{'The quick brown fox jumped over ...'}, 
        'print statement correctly grepped');
    ok($matches{'The quick red fox jumped over ...'}, 
        'print statement correctly grepped');

I<Solution:>  As above, call C<grep_print_statements>, but map its
output to a 'seen-hash'.  You can then use the number of keys in that
seen-hash as an argument to C<Test::More::is()>.  You can use C<ok()> to
test whether the keys of that hash are as predicted.

=back

=head3  C<statements()>

I<Problem:>  You've written a function which prints to STDOUT.  You can make a 
prediction as to the number of screen lines which should be printed.  
You want to test that prediction with C<Test::More::is()>.

    sub print_greek {
        local $_;
        print "$_\n" for (qw| alpha beta gamma delta |);
    }

    $capture->start();
    print_greek();
    $capture->stop();
    is($capture->statements, 4, 
        "number of print statements is correct");

I<Solution:>  Precede the function call with a call to the IO::Capture::Stdout 
C<start()> method and follow it with a call to the C<stop()> method.
Call C<IO::Capture::Stdout::Extended::statements()> and use its return
value as the first argument to C<is()>.  Use your prediction as 
the second argument to C<is()>.  Be sure to write a useful comment for your 
test.

I<Potential Pitfall:>  The number of print statements returned by
C<statements> is I<not> necessarily the number of lines that would
appear to be printed to standard output by a given block of code.  If
your subroutine or other code block prints partial lines -- I<i.e.,>
lines lacking C<\n> newline characters -- the number of print statements
will be greater than the number of ''screen lines.''  This is
illustrated by the following:

    sub print_greek_long {
        local $_;
        for (qw| alpha beta gamma delta |) {
            print $_;
            print "\n";
        }
    }

    $capture->start();
    print_greek_long();
    $capture->stop();
    is($capture->statements, 8, 
        "number of print statements is correct");

This pitfall can be avoided by using C<all_screen_lines()> below.

=head3 C<all_screen_lines()>

=over 4

=item * Scalar Context

Returns the number of lines which would normally be counted by eye on 
STDOUT.  This number is not necessarily equal to the number of C<print()> 
statements found in the captured output.  This method avoids the 'pitfall' 
found when using C<statements()> above.

    $capture->start();
    print_greek_long();
    $capture->stop();
    $screen_lines = $capture->all_screen_lines;
    is($screen_lines, 4, "correct no. of lines printed to screen");

=item * List Context

Returns an array holding lines as normally viewed on STDOUT.  The size
of this array is not necessarily equal to the number of C<print()>
statements found in the captured output.  This method avoids the 
'pitfall' found when using C<statements()> above.

    $capture->start();
    print_greek_long();
    $capture->stop();
    @all_screen_lines = $capture->all_screen_lines;
    is($all_screen_lines[0], 
        "alpha", 
        "line correctly printed to screen");
    is($all_screen_lines[1], 
        "beta", 
        "line correctly printed to screen");

Any newline (C<\n>) appearing at the end of a screen line is I<not> included
in the list of lines returned by this method, I<i.e.,> the lines are
chomped.

=back

=head3 C<matches()>

=over 4

=item * Scalar Context

I<Problem:>  You've written a function which, much like the ''mail merge'' 
function in word processing programs, extracts data from some data source, 
merges the data with text in a standard form, and prints the result to 
STDOUT.  You make a prediction as to the number of forms which are 
printed to STDOUT and wish to confirm that prediction.

    my @week = (
        [ qw| Monday     Lundi    Lunes     | ],
        [ qw| Tuesday    Mardi    Martes    | ],
        [ qw| Wednesday  Mercredi Miercoles | ],
        [ qw| Thursday   Jeudi    Jueves    | ],
        [ qw| Friday     Vendredi Viernes   | ],
        [ qw| Saturday   Samedi   Sabado    | ],
        [ qw| Sunday     Dimanche Domingo   | ],
    );

    sub print_week {
        my $weekref = shift;
        my @week = @{$weekref}; 
        for (my $day=0; $day<=$#week; $day++) {
            print "English:  $week[$day][0]\n";
            print "French:   $week[$day][1]\n";
            print "Spanish:  $week[$day][2]\n";
            print "\n";
        }
    }

    $capture->start();
    print_week(\@week);
    $capture->stop();
    $regex = qr/English:.*?French:.*?Spanish:/s;

    is($capture->matches($regex), 7,
        "correct number of forms printed to screen");

I<Solution:>  Precede the function call with a call to the IO::Capture::Stdout 
C<start()> method and follow it with a call to the C<stop()> method.
Write a Perl regular expression and assign it to a variable using 
the C<qr//> notation.  (Remember to use the C</s> modifier 
if the text you are testing crosses screen lines.)  Pass the 
regex variable to C<IO::Capture::Stdout::Extended::matches()> 
and use the return value of that method call as one argument to 
C<Test::More::is()>.  Use your prediction as the second argument to C<is()>.  
Be sure to write a useful comment for your test.

=item * List Context

I<Problem:>  As above, you've written a function which, much like the 
''mail merge'' function in word processing programs, extracts data 
from some data source, merges the data with text in a standard form, 
and prints the result to STDOUT.  This time, however, you wish to do 
a quick test on the results by examining a sample form.

    $capture->start();
    print_week(\@week); # as defined above
    $capture->stop();

    @matches = $capture->matches($regex);
    $predicted = "English:  Monday\nFrench:   Lundi\nSpanish:";
    is($matches[0], $predicted, "first form matches test portion");

I<Solution:>  Same as above, but capture the output of C<matches()> in 
a list or array.  Write a string which predicts typical contents of one 
instance of your merged form. Use the contents of one form (one element 
in the list output) and the prediction string as arguments to C<is()>.  
Be sure to write a useful comment for your test.

I<Problem:> As above, but now you wish to make sure that a form was 
generated for each required field in the data source.

    $regex = qr/French:\s+(.*?)\n/s;
    @predicted = qw| Lundi Mardi Mercredi Jeudi 
        Vendredi Samedi Dimanche |;
    ok(eq_array( [ $capture->matches($regex) ], \@predicted ), 
        "all predicted matches found");

I<Solution:>  Similar to above, but this time you predict which data
points are going to be present in the output.  Store that prediction in
a list or array.  Take references to (a) the array holding that
prediction; and (b) the result of C<$capture->matches($regex)>.  Pass 
those two references to Test::More's utility function C<eq_array>, which
will return a true value if the underlying arrays are identical
element-by-element.  Pass that value in turn to <ok()>.  As always, 
be sure to write a useful comment for your test.

=back

=head3 C<matches_ref()>

I<Problem:>  Same as the first ''List Context'' example above, but now 
you would prefer to work with a method that returns an array reference 
rather than all the elements in a list.

    $matchesref = $capture->matches_ref($regex);
    is(${$matchesref}[0], $predicted, "first form matches test portion");

I<Solution:> Call C<IO::Capture::Stdout::Extended::matches_ref()>
instead of C<matches>.  You will have to rephrase your test in terms of
an element of a dereferenced array.

=head1 BUGS

As Paul Johnson says, ''Did I mention that this is alpha code?''.

=head1 SUPPORT

Contact the author or post to the perl-qa mailing list.

=head1 ACKNOWLEDGEMENTS

Thanks go first and foremost to the two authors of the IO::Capture
distribution, Mark Reynolds and Jon Morgan.  Mark Reynolds was
responsive to this module's author's suggestions for bug fixes and
additional tests.  The documentation found in
IO::Capture::Overview was particularly helpful in showing me how to
extend IO::Capture's functionality.  This distribution is maintained 
independently but will be updated as needed if and when IO::Capture 
is revised.

The methods in IO::Capture::Extended are 
offered to the Perl community in gratitude for being turned on to 
IO::Capture by David Cantrell on the perl.qa mailing list in 
February 2005 (L<http://www.nntp.perl.org/group/perl.qa/3567>).

Other contributors to that discussion thread whose suggestions are
reflected in this module were David H. Adler, David Golden, Michael G.
Schwern and Tels.  Fergal Daly also made suggestions in separate
communications.

The structure for this module was created with my own hacked-up version
of R. Geoffrey Avery's F<modulemaker> utility, based on his CPAN module
ExtUtils::ModuleMaker.

=head1 AUTHOR

James E Keenan.  CPAN ID: JKEENAN.  jkeenan [at] cpan [dot] org.

=head1 COPYRIGHT

Copyright 2005-15 James E Keenan.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1).  IO::Capture; IO::Capture::Stdout; IO::Capture::Overview.  
Test::Simple; Test::More.

=cut

1;


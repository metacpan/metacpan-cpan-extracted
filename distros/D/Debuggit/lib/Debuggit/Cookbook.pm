package Debuggit::Cookbook;

# ABSTRACT: Debuggit example recipes



=pod



=head1 NAME

Debuggit::Cookbook - Debuggit example recipes



=head1 DESCRIPTION

Herein are provided a number of (mostly) short examples on how to use Debuggit to do clever things.
More examples from users are welcomed.



=head1 Wrapping the debugging output

You can take advantage of the fact that the default formatter is stored as
C<Debuggit::default_formatter> to do some clever things.


=head2 Show timestamp

For instance, it's pretty trivial to add a timestamp to debugging output:

    # add timestamp to debugging (at least for this function/module/whatever)
    local $Debuggit::formatter = sub
    {
        return scalar(localtime) . ': ' . Debuggit::default_formatter(@_);
    };

Note how the C<local> restricts the change in C<debuggit>'s behavior to the current scope.


=head2 Show caller info

Similar to the last recipe.  This is only trickier because you have to figure out the right argument
to C<caller>.

    # all debugging statements in the current scope will show function name
    local $Debuggit::formatter = sub
    {
        # note that caller(0) would be this formatter sub, and
        # caller(1) would be debuggit(), so caller(2) is what we want
        # element 3 is the subroutine name (which includes the package name)
        return (caller(2))[3] . ': ' . Debuggit::default_formatter(@_);
    };

Note that this example only handles the simple cases--if your debuggit() calls get stuck inside
eval's or coderef's or anything like that, this breaks down.  But often the simple case is close
enough.



=head1 Controlling where debugging goes


=head2 Output to a log file

Perhaps you want a log file:

    my $log = '/tmp/debug.log';
    $Debuggit::output = sub
    {
        open(LOG, ">>$log") or return;
        print LOG @_;
        close(LOG);
    };

Notice how you have to append to the file, else multiple C<debuggit> calls will just overwrite each
other.


=head2 Debug to a string

Instead of printing debugging immediately, perhaps you want to save them up and print them out at
the end.  This could be useful e.g. when debugging web pages.

    our $log_msg;
    local $Debuggit::output = sub { $log_msg .= join('', @_) };

Again, we're appending.  We join all the args together (although most formatters will return only
one value, probably best not to assume), but use no separator.  This example uses C<our> instead of
C<my> for the string; this way, the variable is accessible from outside the current scope, which
might be necessary for later printing (depending on where the current scope is).



=head1 Interesting debugging functions


=head2 A separator function

Remember that functions don't have to take any arguments, or return any.  For instance, you could
replace this:

    debuggit('=' x 40);
    debuggit("new code section starts here");

with this:

    debuggit(SEPARATOR => "new code section starts here");

by defining your function thus:

    Debuggit::add_func(SEPARATOR => 0, sub
    {
        $Debuggit::output->('=' x 40);
        return ();
    });

Since we're replacing two calls with one, we use a call to C<$Debuggit::output> to make sure that
the separator line goes where it should, even if someone wants to change where that is.  To make
sure we don't insert an C<undef> into the debugging output stream, we return an empty list.



=head1 Fun with policy modules


=head2 Test suite debugging

Although a policy module will typically pass a debug value through to L<Debuggit>, it doesn't have
to.  For instance, if you're writing a module for all your test scripts to include, you might wish
to force C<DEBUG> to 1.  That's easy:

    package MyTestDebuggit;

    use Debuggit ();
    use Test::More;

    $Debuggit::output = sub { diag @_ };        # nicer with TAP

    sub import
    {
        Debuggit->import(PolicyModule => 1, DEBUG => 1);
    }


=head2 Using Data::Printer instead of Data::Dumper

If you prefer L<Data::Printer> over L<Data::Dumper>, you almost certainly prefer it everywhere.
This is the perfect sort of thing to put in a policy module:

    package MyPrettyDebuggit;

    use Debuggit ();

    sub import
    {
        Debuggit->import(PolicyModule => 1, DataPrinter => 1);
    }

If you'd like to fiddle with the default parameters to Data::Printer, do it this way instead:

    package MyPrettyDebuggit;

    use Debuggit ();

    sub import
    {
        Debuggit->import(PolicyModule => 1);

        Debuggit::add_func(DUMP => 1, sub
        {
            require Data::Printer;
            shift;
            return Data::Printer::p(shift, colored => 1, quote_keys => 1);
        });
    }

Note the following things about the latter example:

=over

=item *

You B<must> put the call to C<add_func()> inside the C<import>.  That's because
C<Debuggit::add_func> doesn't even exist until after C<Debuggit::import> has been called.  Which is,
in turn, so that it won't hang around taking up memory when debugging is turned off.  Also, don't
forget you have to qualify C<add_func> with the full package name, as it isn't exported (and we
aren't importing anyway).

=item *

We didn't bother passing C<DataPrinter> to Debuggit this time.  All that does is set up the initial
definition of the C<DUMP> function, and we're just going to override that anyway, so why bother?

=item *

Since we're completely replacing Debuggit's idea of what Data::Printer should output, anything that
would normally be set by passing C<DataPrinter> but isn't mentioned by our replacement function will
have normal Data::Printer default values.  For instance, in the example above, C<hash_separator>
would go back to being spaces.

=item *

Remember that Debuggit is dealing only with strings until the very end, and then it uses its own
output function.  Thus, setting Data::Printer's C<output> parameter wouldn't have any effect.

=back



=head1 Putting it all together

This section contains slightly longer recipes showcasing multiple features of L<Debuggit>.


=head2 Debugging when STDERR is redirected

Recently, I was trying to debug some CPAN modules that were failing in some of my test files.  The
CPAN modules were being called from a script, and the script was being called with its STDERR (and
STDOUT, for that matter) redirected so it could be captured by the test script.  This can make it
pretty tough to debug, but I came up with a pretty quick solution based on Debuggit.  I've extended
it and tweaked it a bit since I originally wrote it; here's what it looks like today:

    package Debuggit::TermDirect;

    use Carp;
    use IO::Handle;
    use Method::Signatures;

    use Debuggit ();


    our $count = 0;

    open_direct();


    $Debuggit::formatter = sub { return '#>>> ' . ++$count . '. ' . Debuggit::default_formatter(@_) };
    $Debuggit::output = sub { open_direct(); DIRECT->printflush(@_); };

    sub import
    {
        my $class = shift;
        Debuggit->import(PolicyModule => 1, DEBUG => 1);

        Debuggit::add_func(CMD => 1, method ($cmd)
        {
            my @lines = `$cmd`;
            chomp @lines;
            return @lines;
        });

        Debuggit::add_func(ENV => 1, method ($varname)
        {
            return ("\$$varname =", $ENV{$varname});
        });
    }


    sub open_direct
    {
        if (tell(DIRECT) == -1)
        {
            open(DIRECT, '>/dev/tty') or croak("couldn't open channel to terminal");
        }
    }

Let's look at a few of the features:

=over

=item *

The overall structure is basically that shown in L<Debuggit::Manual/"Policy Modules">.

=item *

However, I'm setting C<DEBUG> to 1 directly instead of requiring the value to be passed in in the
C<use> statement.  Since I'm debugging other people's code, there's no chance of leaving the
C<debuggit> calls in permanently, so I may as well make this a debug-mode-only package.

=item *

C<$Debuggit::output> is set to print to C</dev/tty>.  (This only works on Linux, of course ... maybe
on a Mac if it's using OSX).  In this way, it doesn't matter if STDERR is redirected; my debugging
still gets to the screen.  The C<open_direct> function opens the file if the handle is not already
opened: C<tell()> returning -1 is one easy way to check for that (thanks, PerlMonks!).  I'm using
C<printflush> (from L<IO::Handle>) to make sure my output isn't buffered.

=item *

I was putting a lot of different calls into a lot of different modules, and, in some cases, I wasn't
sure what happened first.  I thought it might be nice to have a running counter for the debugging
output.  I also decided to make the debugging distinct: since it was getting intermingled with TAP,
I started it with the C<#>, but added some C<E<gt>>'s to make it stand out a little.  Then I call
the default formatter.

=item *

Note how I'm using L<Method::Signatures> to give me the C<method> keyword, which I use for my
debugging functions.  That gives me C<$self> automatically, and I can put any remaining arguments in
my signature, making my deugging function code more concise.

=item *

My first debugging function is one which calls an external command for me.  I was trying to figure
out what was going on in a temporary directory, which was getting cleaned up at the end of the test.
This function allowed me to do things like:

    debuggit("temp dir contents now:", CMD => "ls $tempdir");

(Again, this only works on Linux or OSX.)  Note that it takes multiple lines and jams them together
into a single line, but that was okay for what I was doing.

=item *

My second debugging function is just a quick shortcut for debugging environment variables.  So this:

    debuggit("after bmoogling the frobnitz", ENV => 'PERL5LIB');

would produce something like:

    #>>> 4. after bmoogling the frobnitz $PERL5LIB = blib/lib:/home/me/common/perl


=cut

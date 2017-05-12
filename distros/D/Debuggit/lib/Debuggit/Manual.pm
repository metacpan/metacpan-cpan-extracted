package Debuggit::Manual;

# ABSTRACT: Details for using Debuggit to the fullest



=pod



=head1 NAME

Debuggit::Manual - Details for using Debuggit to the fullest



=head1 General Stuff


=head2 A Note on Documentation

You know, documentation is a double-edged sword.  Put too little, and no one will use your module
because it's poorly documented.  Put too much, and no one will use your module because it I<must> be
too complex ... I mean, just look at how much documentation it takes to describe it!

Well, it so happens that I actually I<like> writing documentation, so there's a healthy chunk of it
here.  But let me assure you that this is just because I'm being thorough, not because this module
is complex.  It's actually almost ridiculously simple at its core--in fact there's about 4 to 5
times more POD than code in this distro.

You should read this documentation in 3 stages:

=over 4

=item *

Start with the L</Quick Start> in the main L<Debuggit> POD.  After you get bored with how simple
Debuggit is to use like that, you may want to explore more options.

=item *

If you want some examples of cool things you can do with C<Debuggit>, take a look at
L<Debuggit::Cookbook>.

=item *

When you want more details on the nitty gritty of how C<Debuggit> actually works, come to this POD
(C<Debuggit::Manual>).  Think of this as a sort of a reference manual.

=back


=head2 A Note on Version Numbers

I know it's very fashionable to mark any module you put on CPAN for the first time as version
0.000000001, and then take about eight years before daring to release a 1.0.  However, this module
(in earlier incarnations) has been used in production code for over 10 years now, so I don't really
think it makes much sense to call it 0.01.  I've chosen to start its CPAN life at 2.01, as this is
its 3rd major rewrite.  If it makes you feel better, just subtract 2 from the version number and
you'll get a fairly accurate idea of its "true" CPAN version.  Just be aware that it has had a
pretty full life outside CPAN as well.

The Changes file details this life fairly accurately.  The version numbers are assigned using 20/20
hindsight, and I've filled in a few gaps in historical notes, but all the dates and most of the
commit messages are fully accurate, thanks to the wonders of version control.



=head1 The DEBUG Constant

C<DEBUG> is a constant (similar to those defined with C<use constant>) which holds your current
debugging level.  Because it's implemented using constant folding, any conditional based on it will
actually be removed during compile-time if the debugging level isn't high enough (or turned off
completely).  For instance, this code:

    calculate_complex_stuff(1..10_000) if DEBUG >= 2;

would disappear entirely if C<DEBUG> is set to 0, or to 1.  Of course, being a constant has its own
foibles: you can't interpolate it into double-quoted strings, and you can't put it in front of a fat
comma.  See L<constant> for full details.


=head2 Setting DEBUG

You "set" C<DEBUG> when you use Debuggit:

    use Debuggit DEBUG => 2;

Once it's set, you can't change it.  You also can't set it from outside the code (like, from an
environment variable), but that's a feature I'd consider adding if people thought it was useful.

If you want your debugging turned off altogether, you can do this:

    use Debuggit DEBUG => 0;

Or you can do this:

    use Debuggit;

But there's a subtle difference between those last two.  In your top-level script, there's actually
no difference at all.  But in a module, not setting C<DEBUG> doesn't mean C<DEBUG> should be zero;
rather it means it should "inherit" the value of C<DEBUG> from the top-level script; or, to look at
it another way, the value of C<DEBUG> from the top-level script "falls through" to whatever modules
are included by it.


=head2 The top-level script

The definition of "top-level script" (to Debuggit, anyway) is "first 'use Debuggit' statement that
is executed by the Perl compiler."  Which means you should always put C<use Debuggit> before the
C<use> statements for other modules (or at least other modules of yours).

So typically what you would do is just put C<use Debuggit> at the top of all your code until you're
ready to debug.  When you hit a problem, change to C<use Debuggit DEBUG =E<gt> 3> (or whatever level
you feel is appropriate), but I<only> in the top-level script.  Then you get debugging info from all
your modules with one simple change.  Or, if you just I<know> the problem is in module X, you can
enable debugging in that module only (see below).  Convenient, right?

This may not work as well as you'd like if you can't figure out I<where> your top-level script
actually is (one great example of that is a mod_perl environment).  But you can still enable the
debugging in each module, so it isn't tragic.  Just not as convenient.


=head2 Overriding DEBUG in a specific module

So, I said that once you set the value, you can't change it.  To be more specific, you can't change
it I<for that package>.  Each package, however, gets its own value of DEBUG and they could
(theoretically) all be different.  Although that's a recipe for disastrous confusion.  Or confusing
disaster.  Or something ... don't do it, in any event.

But it could easily make sense to turn on debugging only for one particular module, if you just
I<know> the problem is in that module.  This is fine; the "master value" (i.e. the value from the
top-level script) will fall through, but it won't override a specific value you pass in.

As far as C<debuggit> is concerned, the value of C<DEBUG> is whatever the value of C<DEBUG> is in
the package that called it.  It's entirely possible for C<debuggit> to be an empty function to one
package and a function which checks that package's version of C<DEBUG> in another.  For the most
part, this will just DTRT (Do The Right Thing) and you won't have to worry about the details.



=head1 The debuggit function

This is the main event; the raison d'etre of the module.  C<debuggit> is very simple to use, but a
lot of flexibility has been built into it as well.  Read on to see how to adjust the various aspects
of C<debuggit>.


=head2 The basics

=head4 debuggit([level =>] arg[, ...])

C<debuggit> is the only exported function of Debuggit (except for the DEBUG constant, which is
technically a function, but you know what I mean).  When DEBUG is set to 0, you are guaranteed that
C<debuggit> is an empty function.  When DEBUG is non-zero, you are guaranteed that C<debuggit> will
do the equivalent of this:

    sub debuggit
    {
        my $level = $_[0] =~ /^\d+$/ ? shift : 1;
        if (DEBUG >= $level)
        {
            @_ = process_funcs(@_);
            my $msg = $formatter->(@_);
            $output->($msg);
        }
    }

meaning that you can override both $formatter and $output, and you can add to or subtract from the
functions handled by C<process_funcs>.


=head2 Changing output format

=head4 [local] $Debuggit::formatter = coderef

The $formatter variable allows you to override Debuggit's internal format function (see above).  For
instance, something like this:

    $Debuggit::formatter = sub { shift . "\n" . join('', map { "\t$_\n" } @_) };

    my @list = qw< fred sue joe charlie >;
    debuggit("Names:", @list);

outputs something like this:

    Names:
        fred
        sue
        joe
        charlie

although that seems less useful than the default formatter, in general. Or maybe you don't like how
Debuggit provides spaces and newlines for you:

    $Debuggit::formatter = sub { join('', @_) };

But don't forget that now you've also lost the special handling of C<undef> and strings with leading
or trailing spaces.

Happily, since C<$formatter> is a variable, you can use C<local> to restore the previous value at
the end of the enclosing block.

Functions are handled before the formatter is called (see L</Debugging Functions>), so any
replacement formatter you create doesn't have to worry about those.

The C<default_formatter> looks I<mostly> like this:

    $default_formatter = sub
    {
        return join(' ', map { defined $_ ? $_ : '<<undef>>' } @_) . "\n";
    };

but see below for full details.

Before you try to get too terribly fancy with the formatter, you may wish to investigate
C<add_func>.  A good rule of thumb when trying to decide whether you want a new function or a new
formatter is this:  Imagine that C<debuggit> takes a bunch of chunks of text and produces a line
(which is pretty much what it does).  If you want to fiddle with how one of those chunks looks, you
want a function.  If you need to change the look of the whole line, though, you need a new
formatter.

If you're more interested in where the formatted output gets sent to, look at L</"Changing where
output goes">.


=head2 The default formatter

=head4 Debuggit::default_formatter(@_)

This function is what C<$formatter> (see above) is set to unless (and until) you change it.  It can
also be called from your own formatter function (see L<Debuggit::Cookbook/"Wrapping the debugging
output">).  Its purpose is to turn the arguments you pass to C<debuggit> into a formatted line.
This line is then sent to the function stored in C<$output>.

The default formatter provides the following conveniences:

=over

=item *

A single space is put between separate arguments.

=item *

An undefined argument is replaced with the string '<<undef>>' (distinguishes undef from an empty
string, and avoids unsightly "uninitialized variable" warnings).

=item *

Any value which has leading or trailing spaces (that is, / +/, not /\s+/) has '<<' prepended to it
and '>>' appended to it.  This allows you to easily see (and hopefully accurately count) any such
extra spaces.

=item *

A newline is appended to the formatted line.

=back


=head2 Changing where output goes

=head4 [local] $Debuggit::output = coderef

The $output variable allows you to override Debuggit's internal output function.  For instance,
something like this:

    local $Debuggit::output = sub { print @_ };

allows you to print debugging messages to STDOUT rather than STDERR (although I'm not sure why you'd
want to).  Like with C<$formatter>, the use of C<local> allows you to change the output function
temporarily (i.e.  until the end of the enclosing block).

Note that you don't have to append a newline ($formatter does that).  And finally note that I<not>
using C<local> sometimes has its advantages: in this case, you might put such code in a common
header file that all your Perl modules call, and the output will be adjusted for all parts of your
program, regardless of scope.  (See L</Policy Modules> for the best way to accomplish that.)

The default output function is merely:

    sub { print STDERR @_ };

Note that this is subtly different from:

    sub { warn @_ };

in the presence of C<$SIG{__WARN__}> handlers and/or mod_perl.



=head1 Debugging Functions

When writing debugging statements, you may find yourself doing the same operations over and over
again.  For instance, imagine that you have a set of objects that can belong to one of several
subclasses.  Internally, these are stored as hashes (as many objects in Perl are), and each hash
contains a '_data' key whose value is a hashref, which itself contains all the interesting bits of
data for the object.  For debugging purposes, you often need to print out the exact type of a given
object along with a particular data value.  You may find yourself writing something like this over
and over again:

    debuggit("after bmoogling", ref($obj) . '->foo =', $obj->{'_data'}->{'foo'});

By the time you've typed that exact template 20 or 30 times, you may be getting tired of it.  What if
you could do something like this instead?

    debuggit("after bmoogling", OBJDATA => ($obj, 'foo'));

(Note that the fat comma is not required (see L</"Style Considerations">), nor are the extra parends around $obj and
'foo'.  But they make it more obvious what's going on here, in your author's humble opinion.)

If you could do that, that would be much nicer, yes?  Well, you can:

    Debuggit::add_func(OBJDATA => 2, sub
    {
        my ($self, $obj, $data_name) = @_;

        return (ref($obj) . "->$data_name =", $obj->{'_data'}->{$data_name});
    });

What that's saying is this:  Any time C<C<debuggit>> comes across an argument consisting of the
string 'OBJDATA', it should remove it, plus the next 2 arguments, from its argument list; call the
coderef given, passing it the arguments that were removed; and replace the args it removed with the
return value of the coderef.  This is called a "debugging function", or just "function" for short.

Note that this function returns a two-element list, rather than just concatenating it all into one
big string.  This is so that, if the data value happens to be undefined, it will be handled
correctly by the formatter (see L</The default formatter>, above).

A function doesn't have to take any arguments, nor does it have to return any.  See
L<Debuggit::Cookbook/"Interesting debugging functions"> for some examples.

Many clever things can be done.  Remember the difference between functions and formatters, which is
covered above.


=head2 Default functions

At present, there is only one debugging function that Debuggit provides for you by default:

    debuggit("my hash:", DUMP => \%my_hash);

This is basically the same as:

    use Data::Dumper;
    debuggit("my hash:", Dumper(\%my_hash));

with one important exception: instead of loading L<Data::Dumper> via a use statement, the DUMP
debugging function loads it via a require statement, with the happy side-effect that, if debugging
is not enabled, C<Data::Dumper> is never loaded.  Which undoubtedly you don't want it to be in your
production code (as it can add anywhere from 300Kb to nearly 3Mb to your memory footprint, depending
on the version of Perl and the version of C<Data::Dumper>).


=head2 Using Data::Printer instead

Of course, maybe you don't like Data::Dumper.  Maybe you prefer the shiny new L<Data::Printer>.
"Get with the times, silly Debuggit man!" you cry.  Never fear:

    use Debuggit DataPrinter => 1, DEBUG => 1;
    debuggit("my hash:", DUMP => \%my_hash);

When you do this, it will send the single next argument (which means you have to use references as
opposed to relying on Data::Printer's C<p()> prototype) to Data::Printer::p() instead of
Data::Dumper::Dumper().  When it does so, it will use the following parameters:

    colored => 1, hash_separator => ' => ', print_escapes => 1

because those are the parameters I like.  If you like different parameters, feel free to make your own version of C<DUMP> using C<add_func> (see below).

This is the perfect sort of thing to add to a L<policy module|/"Policy Modules">.  There are some
examples of just that in the
L<cookbook|Debuggit::Cookbook/"Using Data::Printer instead of Data::Dumper">.


=head2 Adding new functions

=head4 Debuggit::add_func(FUNC_NAME => #, sub { ... });

This adds a new debugging function to the table that Debuggit keeps.  The first argument is the name
of the function; if you pass the name of an existing function, it is replaced silently.  The second
argument is the number of arguments that the function takes.  The final argument is the coderef for
the function itself.

Any time C<debuggit> finds an argument which exactly matches a function name, it removes that
argument, and a number of following arguments matching the number passed to C<add_func>.  If that
number of args exceeds the number remaining in C<debuggit>'s argument list, it will happily fill any
gaps with undef values without notifying you (or even noticing, for that matter). It then passes the
total list of arguments removed (I<including> the function name!) to the coderef passed to
C<add_func>, calling it in list context.  Finally, it takes the list returned from the coderef and
inserts it back into C<debuggit>'s argument list at the point at which the arguments were removed.
Basically, inside C<debuggit>, it does the equivalent of this:

    $n = $func_name_being_checked_for;
    $i = $point_at_which_func_name_found;
    splice @_, $i, $funcs{$n}->{'num_args'} + 1, $funcs{$n}->{'coderef'}->(@_[$i..$i+$funcs{$n}->{'num_args'}]);

except hopefully more efficiently.

The name of the function is passed in so that you can do excessively clever things such as:

    my $print_config = sub
    {
        my ($self, $value) = @_;
        return ("Config ${self}->$value is", $CONFIG->{$self}->{$value});
    };
    Debuggit::add_func($_ => 1, $print_config) foreach qw< FOO BAR BAZ BMOOGLE >;

But do remember that excessive cleverness often leads to nightmarish maintenance, so caveat codor.


=head2 Removing functions

=head4 Debuggit::remove_func('FUNC_NAME');

This just removes the given debugging function.  Default functions are not special in any way, so
those can be removed just as others can:

    Debuggit::remove_func('DUMP');


=head2 IMPORTANT CAVEAT!

Since C<debuggit> is just doing a simple string comparison on its arguments to find functions, this
means that you can't actually print out that string unless you embed it within another argument.
So, assuming the default functions are still in place:

    use Debuggit DEBUG => 2;
    my $test = {};
    debuggit(2 => "test is", DUMP => $test);        # calls function, as expected
    debuggit(2 => "i like to", 'DUMP', "stuff");    # calls function (possibly not expected)
    debuggit(2 => "i like to", 'DUMP ', "stuff");   # doesn't call function, but prints "<<DUMP >>"
    debuggit(2 => "i like to DUMP stuff");          # no issues here
    my $value = 'DUMP';
    debuggit(2 => "value is", $value, "in foo()");  # calls function(!!!)

That last one is particularly worrisome, but there's not much to be done about it, except to try to
choose names for functions that you feel confident aren't going to show up as arguments to
C<debuggit>, or else don't use debugging functions at all.  Personally I find that as long as I use
all caps for function names, and implement only the most necessary functions, it really isn't a
problem.



=head1 Policy Modules

So, let's say you've started using some of Debuggit's more advanced features, such as setting
formatters, or adding debugging functions, except that now you're putting the same lines of code at
the top of every one of your Perl modules:

    use Debuggit;
    $Debuggit::formatter = sub { return scalar(localtime) . ': ' . Debuggit::default_formatter(@_) };
    $Debuggit::output = sub { warn @_ };        # because I use $SIG{__WARN__}
    Debuggit::add_func(CONFIG => 1,
            sub { my ($self, $var) = $_; return (lc($self), 'var', $var, 'is', $Config->{$var}) });

Whew!  A bit verbose, eh?  Would be nice if we could centralize that somehow.

Okay, try this:

    package MyDebuggit;

    use Debuggit ();                            # no need to let Debuggit import here

    $Debuggit::formatter = sub { return scalar(localtime) . ': ' . Debuggit::default_formatter(@_) };
    $Debuggit::output = sub { warn @_ };        # because I use $SIG{__WARN__}

    sub import
    {
        my $class = shift;
        Debuggit->import(PolicyModule => 1, @_);

        # add_func has to be called after Debuggit->import()
        Debuggit::add_func(CONFIG => 1,
                sub { my ($self, $var) = $_; return (lc($self), 'var', $var, 'is', $Config->{$var}) });
    }

The 'PolicyModule' argument to C<Debuggit::import> just tells it to install DEBUG and C<debuggit> one
level higher than usual, so that your caller (not you) gets all that debuggity goodness.  Now you
can just:

    use MyDebuggit;

or, similarly:

    use MyDebuggit DEBUG => 2;

and you're all set.

Note how the import passes C<@_> on to C<Debuggit::import>.  This is what makes that second C<use
MyDebuggit> example work.  For a counter-example, see L<Debuggit::Cookbook/"Fun with policy modules">.



=head1 Style Considerations

This is a pretty simple module, but there are still a couple of different ways to do things.  Here
are my personal thoughts as to the pluses and minuses of the following alternative styles.  You, of
course, may feel free to disagree: that's what keeps the world a wonderful place.

First, there's the difference between these two:

    debuggit("here I am!") if DEBUG >= 2;
    debuggit(2 => "here I am!");

Personally I prefer #2, but please see important information below under L</"Performance
Considerations">.  Functionally, they are the same ... when debugging is on.  However, here's an
interesting thing that tripped me up once:

    debuggit(4 => "row is", join(':', @$row));

As you might guess from the names, this was in a tight loop that processed each row coming back from
a database.  What I hadn't considered was that, even when debugging was totally off, it was still
doing that C<join> call for every row of data, then passing the results to an empty function.  In
this case, the equivalent:

    debuggit("row is", join(':', @$row)) if DEBUG >= 4;

really was significantly better (again, see L</"Performance Considerations"> for why).

Assuming you went with #2 above, you then have to decide between these two:

    debuggit(2 => "here I am!");
    debuggit(2, "here I am!");

I strongly recommend the first one.  To me, #2 just looks like it will print "2 here I am!", which
it won't.  #1 is using the fat comma to offset the debugging level from the debugging arguments, and
that seems to me to be a Good Thing(tm).

How about a similar choice for functions?

    debuggit("here's my big structure", DUMP => $struct);
    debuggit("here's my big structure", 'DUMP', $struct);

My objections to #2 are the same: it looks like "DUMP" is part of the debugging output, and it
isn't.  For me, the fat comma in a C<debuggit> arg list is basically an indication that whatever
precedes it is not something to be printed, but rather some message to C<debuggit> itself to do
something special.

On the other hand, don't fall into the trap of thinking that every time you use a fat comma
C<debuggit> is going to know that you don't want to print the thing that precedes it.  For instance:

    debuggit("this is not a func", hey => "even though it looks like one");
    # unless you defined a func named 'hey', of course
    # but don't do that; you should use all caps for func names

Remember, the fat comma is still just a comma; C<debuggit> has no way to tell from its argument list
whether you used a fat comma or not.  Use => as a sign to your I<readers> that you're using a
debugging level or a debugging function, not as a sign to C<debuggit> itself.

The last thing you have to decide is how to define your "levels" of debugging.  You don't have to,
of course.  You can just have one level, effectively, and have your debugging be either on or off.
But you will probably find that it's convenient to gradually crank up the debugging level when
you're trying to find that elusive problem.  The lower level that you can set it to, the less
debugging crap you have to wade through to find what you're looking for.

So it makes sense to have various levels of debugging, and it makes sense to have them make sense.
Decide on what's best for your project (which may just be what's best for you, or might involve
coming to a concensus with your coworkers) and publish that in a comment somewhere so everyone has
the same expectations.  And then be consistent.

How many levels should you use?  Well, the quite excellent Log::Log4perl has 6, and they're named
instead of numbered, so that you know what to use each level for.  It also contains this very
curious statement:

    Neither does anyone need more logging levels than these predefined ones.
    If you think you do, I would suggest you look into steering your logging
    behaviour via the category mechanism.

No offense to Log4perl's author, but I always found this statement to be a bit ... well, snooty, to
put it mildly.  My personal view is, who am I to say how many levels you need? or what you want to
use them for?  Consequently, I have given you the range of positive integers to play with, and you
can assign whatever meanings you like to them.  But with great power comes great responsibility, and
if you don't define what your levels are I<somewhere> in your code, those who come after you will
inevitably curse your name.

One last caution:  You may want to define constants for your debugging levels, like so:

    use constant QUIET => 1;
    use constant SOFTER => 2;
    use constant LOUDER => 3;
    use constant LITTLE_BIT_LOUDER_NOW => 4;
    # and so forth

And then you may think you're going to use them like so:

    debuggit(LOUDER => "this is not going to print what you think");

(Unless you think it's going to print "LOUDER this is not going to print what you think", in which
case you'd be absolutely right.)  Remember that the fat comma autoquotes whatever comes before it,
which deconstantifies your identifier there.  You'll have to settle on one of these:

    debuggit(LOUDER, "this works fine");
    debuggit(LOUDER() => "as does this");

Or, alternatively, don't use C<constant> and use something like L<Const::Fast> instead:

    const our $QUIET => 1;
    const our $SOFTER => 2;
    const our $LOUDER => 3;
    const our $LITTLE_BIT_LOUDER_NOW => 4;
    # and so forth

    debuggit($LOUDER => "this one works fine too");

Personally your humble author, while preferring to use constants most of the time, doesn't actually
use them for debugging levels.  Possibly because the levels are already abstract representations as
opposed to actual numbers.



=head1 Performance Considerations

So is calling debuggit completely free?  Well, yes and no.

If you use this style:

    debuggit("here I am!") if DEBUG >= 2;

then, assuming DEBUG is set to 0 (or 1, even), it is indeed 100% free.  In fact, the test suite
actually uses L<B::Deparse> to insure that the above statement produces no actual code when C<DEBUG
== 0>, and if you happen to have L<Memory::Usage> installed, the test suite will also verify that
C<use Debuggit> does not add anything to your program's memory footprint (again, when C<DEBUG ==
0>).

This style, however:

    debuggit(2 => "here I am!");

is slightly more problematic.  Unfortunately, without using a source filter (which is a possibility
for a future version, although it would be strictly optional), there just isn't any way that I can
see to eliminate that call.  (Unless maybe it could be done with something like C<Devel::Declare> or
C<optimizer>, but I fear that may be beyond my meager Perl hacking ability ... patches welcome!)

So if you prefer that second style (as does your humble author), then what you end up with is a
guarantee that your C<debuggit> calls will resolve to calls to empty functions, which take a very
small (but positive) amount of time.  Probably you will never notice them, as whatever actual work
you are doing will certainly overwhelm any time spent on calling empty functions, but I definitely
can't state with confidence that it will never have B<any> impact on your application.  And don't
forget that Perl still has to process your arguments in order to call the empty function: if one of
your args to debuggit is a function call, it gets called even when debugging is off.  So, if any of
that worries you, don't do that.  Use the first style and then you're covered.

So the short answer is, the second style is more compact and potentially more legible.  But the
first style is safer in terms of minimizing performance impact.  However, I do hope that one day I
can update this module with further options which can make the second style just as efficient.
Hopefully this gives you the information you need to choose what's right for you.



=head1 Comparison Matrix

How does B<Debuggit> compare with similar modules?

Probably its most well-known competitor would be L<Log::Log4perl>.  However, Log4perl is really a
full-featured logger, which handles errors, warnings, and much much more ... debugging is only a
small part of what Log4perl does.  If you I<need> Log4perl, you may well want to stick with that and
ignore L<Debuggit>.  Debuggit is mainly for when you need much less than what Log4perl provides.
That having been said, one advantage of Debuggit over Log4perl is that Log4perl provides only 2
levels of debugging (debug and trace), while Debuggit provides as many as you like.  Of course, some
may consider that a I<dis>advantage, but I mention it for completeness.

Log4perl is also designed to actually I<run> in your code even in production mode, whereas Debuggit
is designed to disappear after debugging is over.  For that reason, you may actually find a use for
both alongside each other.  Go for it, you crazy kids.

More similar to L<Debuggit> are L<debug> (by the author of the quite excellent L<Moose>), L<Debug>,
L<Debug::Message>, and L<Debug::EchoMessage>.  All these have similar features to Debuggit, but none
have as many.  To be fair, some have features that Debuggit doesn't.  I've put together a comparison
matrix for you, but please remember that this is based on my reading of the documentation for these
modules.  I have neither used any of them nor looked at their source code extensively, so my
comparison could be incomplete.

I've included a few other debugging modules that I ran across as well.  Several of these latter
modules are designed to be used as part of a larger distribution, but I<could> be used separately,
and offer similar functionality to L<Debuggit>, so I threw them in there.  What the heck.

    d   == debug
    D   == Debug
    DM  == Debug::Message
    DEM == Debug::EchoMessage
    LCD == LEOCHARRE::DEBUG
    PTD == PTools::Debug
    KD  == Konstrukt::Debug
    BD  == Blosxom::Debug
    NXD == Net::XMPP::Debug

    Feature                                    | Debuggit | d | D | DM | DEM | LCD | PTD | BD | KD | NXD |
    -------------------------------------------|----------|---|---|----|-----|-----|-----|----|----|-----|
    DEBUG constant                             |     X    | X |   |    |     |  X  |     |    |    |     |
    output function                            |     X    | X | X | X  |  X  |  X  |  X  | X  | X  |  X  |
      override formatting                      |     X    | X |   |    |     |     |     |    |    |     |
      override where output goes               |     X    | X |   | X  |     |     |     |    |    |     |
      override them separately                 |     X    |   |   |    |     |     |     |    |    |     |
      handles undefined values                 |     X    |   |   |    |     |     |     |    |    |     |
      handles vars w/ leading/trailing spaces  |     X    |   |   |    |     |     |     |    |    |     |
      can print color messages                 |          |   |   | X  |     |  X  |     |    |    |     |
      can specify indent level                 |          |   |   | X  |  X  |     |  X  |    |    |     |
      custom formatting functions              |     X    |   |   |    |     |     |     |    |    |     |
    multiple debugging levels                  |     X    |   |   | X  |  X  |  X  |  X  | X  | X  |  X  |
      levels are effectively unlimited         |     X    |   |   | X  |  X  |  X  |  X  | X  |    |  X  |
      can specify levels as arbitrary strings  |          |   |   |    |     |  X  |     |    |    |     |
    has OO interface                           |          | X | X | X  |  X  |     |  X  |    | X  |  X  |
      OO interface is optional                 |          | X |   |    |     |     |     |    |    |     |
    is self-contained (no dependencies)        |     X    | X | X |    |  X  |  X  |     | X  |    |     |
      doesn't come bundled with other modules  |     X    | X | X | X  |  X  |  X  |     | X  |    |     |
    control from outside module to be debugged |     X    | X |   |    |     |  X  |     |    |    |     |
      fallthrough from top level script        |     X    |   |   |    |     |     |     |    |    |     |
      arbitrary control by module name         |          | X |   |    |     |     |     |    |    |     |
      arbitrary control by package variable    |          |   |   |    |     |  X  |     |    |    |     |
    -------------------------------------------+----------+---+---+----+-----+-----+-----+----+----+-----+

There are, of course, additional considerations in terms of coding style, which may or may not be
important to you.  Also, at least one (L<Blosxom::Debug>) uses source filtering, which you may or
may not object to.




=cut

package Graphics::Asymptote;

# An implementation of a pipe to the Asymptote interpreter.
# Inspired by asymptote.py, which was, in turn, based on gnuplot.py.

use strict;
use warnings;
use Time::HiRes qw( usleep );	# for brief pause after each sent command
use IO::Handle;
use Carp;

use version; our $VERSION = qv('0.0.3');

# constructor functions
sub new {
	# The following six lines of code are taken from 
	# http://www.jasonporritt.com/understanding-object-oriented-perl/
	my $proto = shift;
	my $class = ref $proto || $proto;

	# make sure they sent a hash, i.e. key-value pairs
	scalar(@_) % 2 == 0  or
		croak("Creating an Asymptote pipe requires an even number of arguments.  Usage:\n " . '  new(option => value, ...)');
	my $self = {@_};
	$self = {} unless(defined($self));
	bless($self, $class);
	$self->_init();
	return $self;
}

sub _init {
	# open the pipe and set it to autoflush
	my $self = shift;
	my $pipe;
	$self->{CLoptions} = "-quiet "						# don't show intro banner
						. ($self->{CLoptions} or '')	# add user command-line options
						. ' -exitonEOF';				# force exit on EOF
	open($pipe, '|-', 'asy', split(/\s+/, $self->{CLoptions}));
	$pipe->autoflush(1);
	$self->{pipeHandle} = $pipe;
	$self->{sleepTime} //= 0;
	$self->{verbose} //= 0;								# set and check the verbosity
	unless ($self->{verbose} =~ /^\d+$/) {
		$self->{verbose} = 0;
		croak("Can't set asymptote verbosity to anything but a non-negative integer");
	}
}

# Checks for comments at the end of lines and removes them, then sends the
# contents to _send.
sub send {
	my $self = shift;
	my $toSend = join('', @_);
	
	# remove Perlish comments
	$toSend =~ s/\s+#\s+.*//g;

	$self->_send($toSend);
}

sub _send {
	my $self = shift;
	my @toSend = @_;
	
	# append a newline to the last item if not given
	$toSend[$#toSend] .= "\n" unless($toSend[$#toSend] =~ /\n$/);
	print '*' x 10, ' To Asymptote ', '*' x 10, "\n", @toSend, '*' x 34, "\n\n" if $self->{verbose};
	print {$self->{pipeHandle}} @toSend;
	Time::HiRes::usleep($self->{sleepTime});

	# weird memory hack
	# I know that Perl has automatic garbage collection, but it seems like it's
	# not reclaimed as quickly as it could be?  As a result, when I send
	# consecutive large strings, the memory grows and grows.  This helps avoid
	# that problem.
	undef @toSend;
}

sub _incVerbosity {
	my $self = shift;
	$self->{verbose}++;
}
sub _decVerbosity {
	my $self = shift;
	$self->{verbose}-- if ($self->{verbose} > 0);
}
sub set_verbosity {
	my ($self, $verbosity) = @_;
	$verbosity = $verbosity // 0;	# set_verbosity defaults to zero
	$verbosity =~ /^\d+$/ or croak("Can't set asymptote verbosity to anything but a non-negative integer");
	$self->{verbose} = $verbosity;
}
sub get_verbosity {
	my $self = shift;
	return $self->{verbose};
}

# use inrement and decrement operators to increase or decrease verbosity
use overload
	'++' => \&_incVerbosity,
	'--' => \&_decVerbosity;
	

sub AUTOLOAD {
	# This is a magical function that allows me to respond to undefined
	# methods on the fly.  It also means that in order to use functions from
	# other modules, you need to use their fully qualified names, like usleep
	# does in the send command.
	my $self = shift;
	our $AUTOLOAD;
	my $func = $AUTOLOAD;
	$func =~ s/.*://;			# Strip out the fully qualified portion:

	return if ($func =~ /usleep/);
	
	my $toRun = "$func(" . join(',', @_) . ");\n";
	$self->send($toRun);
}

sub DESTROY {
	my $self = shift;
	# send this diagnostic message so people can catch if the interpreter closed
	# when they didn't expect it to close.
	$self->send("//Quitting Asymptote");
	close($self->{pipeHandle});
}

=pod

=head1 NAME

Graphics::Asymptote - Perl interface to the Asymptote interpreter

=head1 VERSION

This documentation refers to Graphics::Asymptote version 0.0.2.

=head1 SYNOPSIS

   use Graphics::Asymptote;
   
   # Start a new interpreter
   my $asy = Graphics::Asymptote->new;
   
   ## Send a bunch of commands ##
   
   $asy->send(<<ASYCODE);
   size(200);
   real [] x = uniform(0, 10, 100);
   real [] y = sin(x);
   ASYCODE
   
   my $var = 2.4;
   $asy->send( qq{
       write("Hello, world!");
       real i = $var;               // interpolate Perl vars into your code
       real j = i * 5;              # Perlish comments are also allowed
                                    # but must have spaces on both sides so they
                                    # don't intefere with something like this:
       write(format('j has the value %#g', j));
       
       import graph;
   });
   
   ## Using commands not explicitly defined in Graphics::Asymptote ##
   $asy->draw('graph(x, y)');
   $asy->yaxis('L = "$sin\left(x\right)$", ticks = Ticks');
   $asy->xaxis('L = "$x$"', 'ticks = Ticks');
   
   ## Changing the verbosity of the pipe ##
   $asy++;                                   # increase verbosity
   $asy->shipout('prefix = "myGraph"');      # send a command
   $asy->set_verbosity();                    # no argument sets back to zero.
                                             #   could also just decrement

=head1 DESCRIPTION

Using this module, you can create and access instances of the Asymptote
interpreter, allowing you to make beautiful postscript figures with all the
scripting power of Perl.  The Asymptote project describes itself thus (copied
verbatim from C<http://asymptote.sourceforge.net/>, 10-1-2009):

Asymptote is a powerful descriptive vector graphics language that provides a
natural coordinate-based framework for technical drawing. Labels and equations
are typeset with LaTeX, for high-quality PostScript output.

A major advantage of Asymptote over other graphics packages is that it is a
programming language, as opposed to just a graphics program.

Features of Asymptote:

=over

=item *
provides a portable standard for typesetting mathematical figures, just as
TeX/LaTeX has become the standard for typesetting equations;

=item *
generates and embeds 3D vector PRC graphics within PDF files;

=item *
inspired by MetaPost, with a much cleaner, powerful C++-like programming
syntax and floating-point numerics;

=item *
runs on all major platforms (UNIX, MacOS, Microsoft Windows);

=item *
mathematically oriented (e.g. rotation of vectors by complex multiplication);

=item *
LaTeX typesetting of labels (for document consistency);

=item *
uses simplex method and deferred drawing to solve overall size constraint
issues between fixed-sized objects (labels and arrowheads) and objects that
should scale with figure size;

=item *
fully generalizes MetaPost path construction algorithms to three dimensions;

=item *
compiles commands into virtual machine code for speed without sacrificing
portability;

=item *
high-level graphics commands are implemented in the Asymptote language itself,
allowing them to be easily tailored to specific applications. 

=back

=head1 FULL DOCUMENTATION

This documentation covers only how to use this Asymptote wrapper for Perl, not
how to use Asymptote for creating images and figures generally.  However,
Asymptote has excellent documentation.  Check out
C<http://asymptote.sourceforge.net/>.

=head1 SUBROUTINES/METHODS

=over 4

=item C<new(%options)>

Creates a new background instance of the Asymptote interpreter and returns the
object that will allow you to communicate with it.
You can set a couple of options, including:

=over 4

=item C<verbose>

 $asy = Graphics::Asymptote->new(verbose => 1);

Set the pipe's initial verbosity level.  Nonzero verbosity is very useful for
debugging what you actually send to Asymptote.  For details, see the section on
L<DEBUGGING>.  The different settings mean this:

 Verbosity  Meaning
     0      Only prints what Asymptote outputs
     1      Tells you what the pipe is sending to Asymptote before it sends it

With a verbosity setting of 0, you will only be
given the output of Asymptote itself, whenever it feels the need to send a
printed message.  For example, if one of the functions you call contains a 
C<write> statement, that will show up with a verbosity setting of 0.  Under
the default (batch) mode of operation, this means very little since Asymptote
won't do anything until you've closed the pipe anyway.

A verbosity setting of 1 will tell you what the Asymptote pipe is sending
to the interpreter as soon as you send it, which should help you when you are
debugging what you send to Asymptote.  For example,

 $asy = Graphics::Asymptote->new(verbose => 1);
 $asy->write(1);

will generate

 ********** To Asymptote **********
 write(1);
 **********************************
 
 1

You can also set the verbosity level higher if you wish, though presently only
a setting of 2 has any meaning, and then only when you're using
L<PDL::Graphics::Asymptote>.

=item C<CLoptions>

You can specify command-line options to be used when invoking the interpreter,
and your options come last, so they can override previous options.  For
information about the available command line options, type

 asy -h

at your prompt.  The default option is

 -quiet        -- prevent displaying the opening message from Asymptote

Each of these options can be overridden by user settings.  Although it's not
required, I suggest keeping multiline sends since working without that will
cramp your style.  Other options that may be useful include

 -V            -- show the output as it's being created
 -noV          -- don't show the output
 -globalwrite  -- allow Asymptote to write to other directories
 -f            -- change default output format
 -o            -- change default output filename
 -interactive  -- run the interpreter in interactive mode; normally it is run in
                  batch mode, in which case you will not get any response from
                  Asymptote until after you've close the interpreter (at which
                  point it will process all of your commands at once)

If you decide to run it in interactive mode, I recommend using the following
options:

 -multiline    -- allow mutliline sends, important for multi-line for loops,
                  for example
 -prompt ''    -- don't display the prompt
 -prompt2 ''   -- don't display the continuaton prompt, either

Note that C<Graphics::Asymptote> does not check its input for cleanliness, so
passing 

 CLoptions => '; rm * -rf;'

will result in all your files being deleted once the interpreter closes!  If
you let users set this flag, be sure to be clean it!

=item C<sleepTime>

 $asy = Graphics::Asymptote->new(sleepTime => 100_000);

Set the sleep time in microseconds (uses Time::HiRes).  This really only makes
sense when used in interactive mode.

Whenever you send a command to the Asymptote interpreter, it has to parse
the command before it can execute it.  Under the current implementation, the
pipe sends commands to the interpreter and immediately returns control to
your perl script.  This can lead to weird results.  For a demonstration,
consider:

 $asy = Graphics::Asymptote->new(CLoptions => '-interactive');
 $asy->write(1);
 print "2\n";

for which you should alwasy get the output

 2
 1

Why does this happen? In a nutshell, Perl executes its print statement more
quickly than C<asy> can interpret and print your C<write> statement.
Presently, the only solution to this problem is to set a higher C<sleepTime>,
which tells the pipe to wait a certain amount of time before returning
control to your perl script.  So on my machine, when I set the sleep time to
600,000:

 $asy = Graphics::Asymptote->new(CLoptions => '-interactive', sleepTime => 600_000);
 $asy->write(1);
 print "2\n";

I get as output

 1
 2

That's right, it took my machine over half-a-second to parse and process the
write command.  (While I suspect that Perl might be faster than Asymptote, this
is not a fair comparison between the two because the Perl C<print> statement
was precompiled but Asymptote must interpret and compile the C<write> statement
on-the-fly.)

=over 

Developer's note:

The ultimate solution to this is to set up a different IPC arrangement and have
two send commands, one that sends the command to Asymptote and returns
control immediately, and another that sends the command and actually
monitors C<asy>, waiting for it to tell us it's completed the command.
Maybe that will be version 0.1.0... until that solution is implemented, this
will have to do.

=back

=back

=item C<send($asyCode)>

 $asy->send( qq{
     write("Hello!");                // my block of Asymptote code.
     int asy_var = $interpolate_me;  # Perlish comments are allowed, too, but
	                             #    the '#' must be surrounded by spaces.
 });

This command sends the given text to the Asymptote interpreter, removing Perlish
comments, and appending it with a newline so the interpreter knows to start
analyzing what you sent.  The string ought to be a complete Asymptote statement; 
otherwise the interpreter will just wait for you to send another command that
finishes the statement.  More likely than not this will lead to confusion, so
be sure to finish all the statements you send over the pipe.

By using the C<qq> or C<q> quoting operators, the C<send> command can be easily
formatted to send long batches of code to the interpreter.  Here's an example
from the Asymptote manual's tutorial (Chapter 3):

 $asy->send(qq{
     size(0,100);
     path unitcircle=E..N..W..S..cycle;
     path g=scale(2)*unitcircle;
     filldraw(unitcircle^^g,evenodd+yellow,black);
 });

You can use a heredoc instead of quoting with C<qq>.  I prefer to use 
the C<qq> operator and use braces, which allows for indentation
that resembles standard code blocks.  A silly example would look like this:

 $asy->send('int accumulator;');
 while($filename = glob('*.dat')) {
     open $fh $filename;
     while($data = <$fh>) {
         $asy->send(qq{
             for(int i = 0; i < $data; $i++) {
                 write(i);
                 accumultaor += i;
             }
         });
     }
 }
 $asy->write('accumulator');	# prints the current value of the accumulator

Notice that $data is interpolated into the Asymptote code.

=over

=item Comments

To improve code consistency, the C<send> command checks all your lines for
Perlish comments.  This is not trivial because C<#> is used in
Asymptote for other purposes.  Therefore, C<send> assumes that what you enter
is a comment only if it matches this regex:

 /\s+#\s+/

Of course, you can also use standard C<//> comments. These comments will be
passed on to Asymptote, which knows how to handle such things.

=item Using the Right Tool

This raises an important point.  Asymptote is a programming language, with
looping constructs and all.  When should you loop or process data in Perl, and
when should you loop and process data in Asymptote?  The answer, of course, is
to use the stronger of the two languages for whatever you're doing.  In
particular, Perl's ability to handle string and file operations vastly exceeds
Asymptote's.

The quintessential mixed example is that you want to process all the C<*.dat>
files in your current directory; the files that you are using change regularly
(so you want the program to operate on a list of actual files in the directory)
and the filenames themselves contain important information that must be
extracted.  To handle this, use Perl to loop over the files (using C<glob>)
and extract the useful information from the filenames, and then tell Asymptote
how to do the crunching and plotting, as in the following example.

For this problem, let's say you want to draw concentric circles with dots at
various locations on each circle.  To do this, you have a number of data files
in your current directory, named something like C<dots,1.25.dat>.  Each file
contains the radius of interest, (in this case, 1.25) and each file is filled
with angles at which you want to place your dots.  This would be a pain to
handle in Asymptote, but you can easily combine the two like so:

 # Initialize the Asymptote canvas and declare some variables ahead of time
 $asy->send(q{
     size(0,100);
     path unitcircle=E..N..W..S..cycle;
     file fin;
     real[] angles;
 });
 my $radius;
 while(glob "*.dat") {
     next unless(/(\d+\.\d+)/);           # only consider files with decimals 
     $radius = $1;                        # extract the radius from the filename
	 
     $asy->send( qq{
         draw(scale($radius) * unitcircle);      # draw underlying circle
         fin = input("$_");                      # open the file
         angles = fin;                           # read in all the angles
         for(real angle : angles) {              # loop over the angles and
             dot($radius * expi(angle));         #   draw a dot at each angle
         }
     });
 }

Note: If you want to do serious number crunching, consider using PDL, the
Perl Data Language.  You can find a related Asymptote package under
C<PDL::Graphics::Asymptote>, which allows you to do everything mentioned here
and easily send piddles to Asymptote for plotting.

=back

=item set_verbosity, get_verbosity

Accessors for verbosity.  C<set_verbosity> takes at most a single non-negative
integer argument and sets the pipe's verbosity to it.  If you don't supply any
argument to C<set_verbosity>, it resets the verbosity to zero.  You can also
modify the verbosity using the increment and decrement operators:

                                # Verbosity initially at 0
 $asy->set_verbosity(5);        #  now at 5
 $asy--;                        #  now at 4
 $asy->set_verbosity();         #  now at 0
 $asy++;                        #  now at 1
 print $asy->get_verbosity();   # prints 1

This is particularly useful when you're trying to debug your code.  See
the L<section on debugging|DEBUGGING>, below.

=back

=head1 AUTOLOAD

Using Perl's C<AUTOLOAD> capabilities, C<Graphics::Asymptote> will take any
unrecognized command and pass the function name straight to Asymptote by name.
For example,

 $asy->size(0, 100);                # set's canvas size
 $asy->send("size(0, 100);");       # equivalent send command
 
 $asy->write("my_asy_var");         # writes contents of my_asy_var
 $asy->send('write(my_asy_var);');  # equivalent send command
 
 $asy->write('"Hello!"');           # write's Hello!
 $asy->send('write("Hello!");');    # equivalent send command

This can be handy if you have a single command you want to pass to the
interpreter, in which case a C<send> command can get somewhat noisy.  It is
particularly clean if the function you need to call only needs numeric
arguments, such as the C<size> command above.  The second and third examples
show the quoting and double-quoting needed for C<AUTOLOAD>ed commands; the
double quoting is annoying, but as you can see it's better than keeping track
of all your semicolons and quotes (which each of the equivalent C<send>
commands demonstrate).

Note that you cannot use C<AUTOLOAD> for the Asymptote C<import> command.
First, asymptote's command is just that - a command, not a function.  The
C<AUTOLOAD> command would try to wrap its arguments in parentheses, which
Asymptote wouldn't like.  Second, Perl objects have an C<import> function
defined, so C<AUTOLOAD> would never actually be called, anyway.

=head1 DEBUGGING

Life being what it is, you will have bugs in your code, which inclues the code
you send to Asymptote!  One way to root them out is to increase the verbosity,
to actually see what is being sent down the pipe to Asymptote.

=head2 Changing the verbosity setting

You can set the verbosity setting at any time.  For example, if you know that
a particular set of commands is giving you trouble, you can increase the
verbosity in the vicinity of that command:

 # ... good code (verbosity is 0)
 
 # Not sure about the asy code that follows:
 $asy++;
 # ... troublesome code here
 
 # OK, what follows should be fine
 $asy--;

An important example of changing the verbosity on
the fly is to have the pipe NOT tell us when it is closing when we
expect it to close.  Here's what I mean:

 #!/usr/bin/perl
 use Graphics::Asymptote;
 $asy = Graphics::Asymptote->new(verbose => 1);
 undef $asy;

This (complete) script simply creates and destroys the pipe.  On my machine,
the output of this looks like:

 david@davids-desktop:~$ ./asytest.pl 
 ********** To Asymptote **********
 //Quitting Asymptote
 **********************************
 
 david@davids-desktop:~$ 

The business about quitting is useful, especially if you find your interpreter
quits unexpectedly, but suppose you know when your pipe is going away and want
to remove the extra line noise.  To avoid that, set the verbosity to 0
before C<undef>ing your pipe or letting it go out of scope, like this:

 #!/usr/bin/perl
 use Graphics::Asymptote;
 $asy = Graphics::Asymptote->new(verbose => 1);
 
 # asymptote code will eventaully go here.
 
 $asy->set_verbosity();

=head2 Using verbosity for debugging

Consider this snippet, which should print 'Hello!' using Asymptote's write
command:

 $asy->write('Hello!');

This doesn't do what I expect:

 -: 1.12: syntax error
 error: could not load module '-'

Let's go through this message bit by bit.  First, C<-:> means, "I (Asymptote)
am reading from the standard input (not a file)."  In other words, the problem
is with what we sent to the Asymptote pipe.  If the problem was in a script we
told C<asy> to import, the "-" would be replaced with the file name.  This is
echoed in the second line, stating it C<could not load module '-'>, which means
it couldn't parse the standard input.

OK, next we have C<1.12: syntax error>, which means that on the
first line, 12th character, we have a problem.  What could it be?
To help find out, set the verbosity higher and
see what we're actually sending to the Asymptote interpreter:

 $asy++;
 $asy->write('Hello!');
 $asy--;

The resulting message looks like this:

 ********** To Asymptote **********
 write(Hello!);
 **********************************
 
 -: 1.12: syntax error
 error: could not load module '-'

Now you can easily see the problem: we forgot to put quotes around our string,
and Asymptote really doesn't like that exclamation point! Correcting our code to:

 $asy++;
 $asy->write('"Hello!"');
 $asy--;

yeilds

 ********** To Asymptote **********
 write("Hello!");
 **********************************
 
 Hello!

which is exactly what we wanted.  And that's how you debug.

=head1 DIAGNOSTICS

Most errors you get out of using this module will probably come from syntax
errors in your Asymptote code.  However, you might get a couple of error
messages specific to this module:

=over

=item Can't set asymptote verbosity to anything but a non-negative integer

You'll get this if you try to set your pipe's verbosity to a negative number
or a string.  You should never get this if you use the increment and decrement
operators, only if you call C<set_verbosity> directly or if you set the verbosity
when you create the pipe.

=item Creating an Asymptote pipe requires an even number of arguments.

This message will arrise if you pass options to the constructor, but don't send
an even number of arguments.  Each options should have a key/value arrangement,
such as

 $asy = Graphics::Asymptote->new(verbose => 1);

=back

=head1 DEPENDENCIES

This module depends on having a working version of C<asy>, the Asymptote interpreter.

=head1 BUGS AND LIMITATIONS

This module does a rather shoddy job of actually communicating in a meaningful way
with the interpreter, since at present it doesn't allow you to programatically
analyze what the interpreter says back to you.  This could be fixed by using
C<IPC::Run> rather than a simple pipe.

There are no known bugs in this module.

Please report any bugs or feature requests to
C<bug-graphics-asymptote@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

David Mertens  C<< <dcmertens.perl+Asymptote@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, David Mertens C<< <dcmertens.perl+Asymptote@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=head1 SEE ALSO

L<Graphics::GnuplotIF>, C<asy(1)>, http://asymptote.sourceforge.net/

=cut

1;

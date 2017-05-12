
require 5;
package Getopt::Janus;
use strict;

require Exporter;
# TODO: progress meters?

BEGIN {
  if(defined &DEBUG) {
    # no-op
  } elsif( ($ENV{'JANUSDEBUG'} || '') =~ m/^(-?\d+)$/s) {
    eval "sub DEBUG () {$1}";
    die "INSANE! $@" if $@;
  } else {
    *DEBUG = sub () {0};
  }
}

use vars qw(@ISA %EXPORT_TAGS @EXPORT $VERSION
  @New_files $Facade_class $facade_obj
);
@ISA = ('Exporter');
%EXPORT_TAGS = ('ALL' => \@EXPORT);
$VERSION = '1.03';
@EXPORT = qw{
 yes_no string file new_file choose
 license_artistic license_gnu license_either
 licence_artistic licence_gnu licence_either
 run
 note_new_files note_new_file
};
$Facade_class ||= __PACKAGE__ . '::Facade';
DEBUG and print "Facade class: $Facade_class\n";

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
sub run      ($@)   { _self()->     run(@_) }

sub string   (\$$@) { _self()->  string(@_) }
sub new_file (\$$@) { _self()->new_file(@_) }
sub file     (\$$@) { _self()->    file(@_) }
sub yes_no   (\$$@) { _self()->  yes_no(@_) }
sub choose   (\$$@) { _self()->  choose(@_) }

sub license_artistic () { _self()->license_artistic(@_) }
sub license_gnu      () { _self()->license_gnu(@_) }
sub license_either   () { _self()->license_either(@_) }
# variant spelling:
sub licence_artistic () { _self()->license_artistic(@_) }
sub licence_gnu      () { _self()->license_gnu(@_) }
sub licence_either   () { _self()->license_either(@_) }

sub note_new_file     { push @New_files, @_; }
sub note_new_files    { goto &note_new_file; } # alias

# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

sub _self {   # This is the only place where we construct
  return $facade_obj ||=
    ( _require($Facade_class) || die "Can't load $Facade_class: $@"
    )->new()
}

sub _require {  # returns classname if loadable, or nil if not
  my $class = $_[0];
  unless( defined $class and length $class ) {
    require Carp;
    Carp::confess( "What class?" );
  }
  
  {
    no strict 'refs';
    unless( # unless it's already loaded...
      defined( ${"$class\::VERSION"} )
      or @{"$class\::ISA"}
      or defined &{"$class\::new"}
    ) {
      eval "require $class";
      return if $@;
      DEBUG and print "Loaded $class fine.\n";
    }
  }
  return $class;
}


# ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

1;
__END__

=head1 NAME

Getopt::Janus -- get program options via command-line or via a GUI

=head1 SYNOPSIS

  use strict;
  use Getopt::Janus;
  
  string my $title, '-t', \'Document title';
  $title = "Stuff";
  
  yes_no my $errata, "-e", "--errata", \"Append errata section";
  
  file my $in, "-i", "--in", \"Input data file";
  $in = "thing.dat";
  
  new_file my $out, "-o", "--out", \"Output data file";
  $out = "out\e.txt";
  
  new_file my $out2, "-l", "--lex", \"Other output data file";
  $out2 = "lex\e.dat";
  
  choose my $mode, '-m', '--mode', \"What processing mode",
    from => ["Normal", 'Special', "Funky mode"];
  
  yes_no my $crunchy, "-c", "--crunchy", \"Whether to do it crunchily";
  
  license_either;
  
  run \&main,
    "Example program", # title
    "This example just shows off all the widgets", # description
  ;
  
  sub main {
    # Code that deals with $title, $mode, etc...
    ##  This is where all the main work  ##
    ##   of your program should happen.  ##
    return;
  }

=head1 DESCRIPTION

This module is for rapid development of programs that can equally well
present a simple GUI interface or present a command-line interface.  It
is the 80/20 attempt (i.e., 80% of the solution, gotten with just 20% of
complexity that a full solution would entail) at finding a middle-ground
between Getopt::* and Tk.  Wherever possible, it generates help screens
on its own.

This module is intended for programs that get their options (as from
the command line), run (reading from or writing to files, and
maybe C<print>ing a few things to STDOUT along the way), and exit.
You wouldn't use this to rewrite C<emacs> or C<cron> -- think more
of the interfaces of C<touch> or C<cal> or maybe even C<scp>.

Here's how to write a program using Getopt::Janus:

=over

=item *

Define your program's options with any of the functions
C<string / new_file / file / yes_no / choose>.

=item *

Optionally call one of the C<license_*> functions, to declare
what license your program can be distributed under.

=item *

Call C<run \&procedure>, where C<procedure> is a sub where you have the
main work of the program (or, in turn, call routines that do the main
work of the program, etc.).

=back

Then if you call the program with no options, it will try to start up
a Tk window to elicit the option values from the user.  But if you
specify any options at the command line (even if just the
null-option "--"), then those options are used, and no Tk window is
produced.  Running it with the option "-h" or "--help" will return
a help screen.

Consider this trivial program:

  use strict;
  use Getopt::Janus;
  string my $n, "-n", \"Number of days from now",
    \"The number of days from now whose date you want";
  $n = 5;
  run \&main, \"What's the date in N days?";
  sub main {
    die "-n has to be a number" unless $n =~ m/^\d+$/s;
    my $then = time() + $n * 24 * 60 * 60;
    print "In $n days, it will be ",
      scalar(localtime $then), "\n";
  }

With this named as F<ndays>, you can run it any of these ways:

  ndays -n=15      (report the date of 15 days from now)
  ndays -n 15      (same as -n=15)
  ndays            (bring up a GUI window to ask what number of days)

  ndays --         (no GUI window: run with defaults, i.e. n=5)

  ndays -h         (give a help screen instead of running)
  ndays --help     (slightly more verbose than -h)

=head1 COMMON FUNCTION ARGUMENTS

The module Getopt::Janus defines and exports the functions listed in the
next section. In discussing the syntax of the functions, I use the
abbreviation I<*decl*>, which stands for this set of possible argument
syntaxes:

=over

=item C<$variable,>

This declares which variable you want the option's value to end up
in.  Note that under recent-enough versions of Perl, you can C<my>
the variable at the same time, as in C<yes_no my $flag, ...>

(Note that C<$variable> can actually be any kind of scalar slot, like
C<$foo{'bar'}> -- but usually you'll want just a plain variable).

=item C<"-f",> and/or C<"--foo",>

This expresses what command-line option is associated with this
variable.  This part can't be blank.

That is, any of these are good switch-name declarations:

  "-f",
  "--foo",
  "-f", "--foo",
  "--foo", "-f",

=item optional C<\"Option title",> or optional
C<\"Option title", \"Description of this option's meaning">

Here you declare the (optional) title and (optional) longer
description of this option.  You I<should> provide at least a title,
but you don't I<have> to -- if you don't, then Getopt::Janus will
try to make do with the long switchname ("C<--foo>") or, failing that,
with the more cryptic short switchname ("C<-f>").

=back

So here, for example (and as illustrated further elsewhere in this
document), are several valid syntaxes:

  yes_no $s, '-s', \"Be strange";
  
  yes_no $o{'strangely'}, '-s', \"Be strange",
   \"Whether to do things all weird";

  yes_no my $strange_flag, "--strangely";


=head1 FUNCTIONS

The module Getopt::Janus defines and exports the functions listed in
this section.  See the previous section for an explanation of
I<*decl*>.

=over

=item C<yes_no I<*decl*>;>

This declares an option whose value will be either true or false.
In GUI terms, this is usually expressed as a checkbox.  In
command-line terms, this usually means that the option is false unless
there's an "-I<x>" to turn it on (although it can be turned off with
"-I<x>=0", which should be necessary only if the default is to be
on).

=item C<string I<*decl*>;>

This declares an option whose value is an arbitrary string.
In GUI terms, this is usually expressed as just an Entry blank
widget.  In command-line terms, this in an option whose value
you provide with "-I<x> 123" or "-I<x>=123".  (To explicitly
force it to an empty-string, use "-I<x>=".)


=item C<file I<*decl*>;>

This declares an option whose value is an existing file. In command-line
terms, this works the same as a C<string> declaration would (i.e.,
"C<-I<x> filename>" or "C<-I<x>=filename>"). But in GUI terms, this
means that the system should give you a window for browsing through
directories to select an existing file, and should complain if you try
to specify a nonexistent file.

Note that the Getopt::Janus system doesn't actually ensure that this
value is a valid input filespec (although the GUI widget system
I<might> try to enforce that).


=item C<new_file I<*decl*>;>

This declares an option whose value is a new file.  In command-line
terms, this works the same as a C<string> declaration would (i.e.,
"C<-I<x> filename>" or "C<-I<x>=filename>").  But in GUI terms, this
means that the system should give you a window for browsing through
directories to select where to put the file, allow you to type in
a new filename, and prompt you for confirmation if you use the
name of an already-existing file.

Note that the Getopt::Janus system doesn't actually ensure that this
value is a valid output filespec (although the GUI widget system
I<might> try to enforce that).

There is an extra feature unique to C<new_file> default values -- if you
declare a variable whose value (either before or after the declaration
-- before C<run> is called, anyway) has the escape character in it
(C<\e>), then this is taken as a placeholder.  Getopt::Janus will then
scan for files that are named like that but which have digits where
your filename has an C<\e>, and replace your C<\e> with 1 greater than
the highest value found (or with "100" if no such files were found).
So if you have this:

  new_file my $out, "-o", "--output", \"Where to write the data";
  $out = "output\e.dat";

If there are already files F<output234.dat>, F<output236.dat>, and
F<output123.dat>, then C<$out> will be set to F<output237.dat>, since
that's one higher than the highest number found (236). 


=item C<< choose I<*decl*>, from => ['First', 'Second',...] >>

This declares an option whose value must be one of the options.
In GUI terms, this is expressed as a dropdown menu.
In command line terms, this works the same as a C<string> declaration
would (i.e., "C<-I<x> First>" or "C<-I<x>=First>"), except that it
is a fatal error if the user tries to set this to anything but the
allowed values.

Note that if you set the default value of the variable, it must be
to one of the possible values -- and if you want empty-string to be a 
default value, you have to explicitly allow for that.  If you don't
set a default value, the first choice in the list will be used
as the default value.

For example:

  use strict;
  use Getopt::Janus;
  choose my $ice_cream, '-i', \"What kind of ice cream",
   'from' => [ 'Lemon sorbet', 'Vanilla ice cream', 'Mango zabaglione' ];
  run \&main;
  sub main {
    print "Ice cream is $ice_cream.\n";
    return;
  }

In the above example, the default value of C<$ice_cream> is the first
element, C<'Lemon sorbet'>, simply because it is the first element in the
list.  If you wanted it to be another of the options, you could express
that like this:

  use strict;
  use Getopt::Janus;
  choose my $ice_cream, '-i', \"What kind of ice cream",
   'from' => [ 'Lemon sorbet', 'Vanilla ice cream', 'Mango zabaglione' ];
  $ice_cream = 'Mango zabaglione';
  run \&main;
  sub main {
    print "Ice cream is $ice_cream.\n";
    return;
  }

But a fatal error would result if you did this:

  use strict;
  use Getopt::Janus;
  choose my $ice_cream, '-i', \"What kind of ice cream",
   'from' => [ 'Lemon sorbet', 'Vanilla ice cream', 'Mango zabaglione' ];
  $ice_cream = 'Rainbow sherbet';
  run \&main;
  sub main {
    print "Ice cream is $ice_cream.\n";
    return;
  }

(At time of writing, the error message looks like C<Rainbow sherbet
isn't any of the allowed values {Lemon sorbet Vanilla ice cream Mango
zabaglione} at...>.)

To repeat what I said earlier,
if you want empty-string to be a 
default value, you have to explicitly allow for that.  Here's an example
of that:

  use strict;
  use Getopt::Janus;
  
  choose my $ice_cream, '-i', \"What kind of ice cream",
   'from' => [ '', 'Lemon sorbet', 'Vanilla ice cream', 'Mango zabaglione' ];
  
  run \&main;
  
  sub main {
    print "Ice cream is $ice_cream.\n";
    return;
  }

(In fact, not only is it a permitted value there, but it also just
happens to get made the default, because it's the first permitted value.)

Note that "the default" for C<choose> in GUI terms means that it's the
value that the widget has when it first appears, as you'd expect.
In command-line terms, it means the value that the widget has unless
the user provides a different value in a "C<-I<x=Newvalidvalue>>" option.


=item C<license_artistic()> or C<license_gnu()> or C<license_either()>

These functions (which currently take no parameters) declare this
program as being distributable under the Perl Artistic License; or under
the GNU Public License; or under either. Use only one of these commands
per program. If you don't want to use any of these licenses, then don't
call any of these functions at all -- their use is optional.

You can also spell these as 
C<licence_artistic()> or C<licence_gnu()> or C<licence_either()>,
which are synonymous with the "-ense" functions.


=item C<run \&main;>

=item C<run \&main, \"Program Title";>

=item C<run \&main, \"Program Title", \"A description of the program";>

This starts the program by running the C<main> routine (or whatever
you call the routine).  The optional C<\"Program Title"> is for declaring
the title of the program.  The optional C<\"A description of the program">
is for declaring a (longer) description of what the program does.

Before you call C<main>, call all the option-declaration functions you
need, and optionally set the declared variables to their initial values;
and then call C<run> to call the routine that does all the program's work
(and end that routine with C<return>, not C<exit>!).  I haven't yet seen
any need to have any statements that execute I<after> the call to C<run>.


=item C<note_new_files( I<files>... );>

This function tells the program interface that about files that you're
creating, so that the interface I<may> prompt the user to open these
files and/or their directories, once the program has run. You don't need
to call this for values you get from C<new_file> variables -- that's
done automatically. (Currently this prompt-to-open step is happens only
under Tk under MSWindows.)

C<note_new_file> is an alias to C<note_new_files>, provided in case
calling C<note_new_files> on a single file seems counter-intuitive
to you.

To avoid having the prompt-to-open step run at all, call it with
this magic value:

  note_new_files '.NO.';

=back



=head1 COMMAND-LINE PARSING

Getopt::Janus recognizes several syntaxes for specifying values
on the command line -- but your favorite value might not be among
them, so look out.  Here are the supported syntaxes, given C<-f>
and C<--foo> as switches:

  -f          set a yes_no option "-f" to a true value
  --foo       set a yes_no option "--foo" to a true value
  -f=abc      set an option "-f" to the value "abc"
  --foo=123   set an option "--foo" to the value "foo"
  
And, assuming -f and -f aren't declared as yes_no options:

  -f abc      set an option "-f" to the value "abc"
  --foo 123   set an option "--foo" to the value "foo"

And finally:

  --          end the list of switches

If Getopt::Janus can't cleanly parse the command line as either empty,
or "--", or consisting entirely of a list of switches (ending in an
optional "--"), then it will abort, and will emit a help message
explaining the correct syntax.

Note Getopt::Janus differentiates between this:

  progname

and this:

  progname --

With the first one (no argument list at all), Getopt::Janus sees an empty
argument list, and so tries starting up a GUI interface.  In the second
one (an argument list consisting of just "C<-->"), Getopt::Janus sees a
non empty argument list, and so uses the command-line interface, regardless
of the fact that the list happens to just be the thing that means "here
ends the list of switches".

Note that unlike most/all other switch-parsing libraries Getopt::Janus
I<does not> allow there to be anything on the command line (after the
program name) except for switches! That is, you I<cannot> use
Getopt::Janus to write a program that takes this syntax:

  progname -x=123 thingy anotherthingy

That's forbidden because I<thingy> and I<anotherthingy> aren't switches,
nor are they switch values.

So you'd have to do it like this:

  progname -x 123 -i thingy -o anotherthingy

Or, synonymously,

  progname -x=123 -i=thingy -o=anotherthingy

Or even a mix of I<key=val> and I<key val> syntax:

  progname -x 123 -i=thingy -o anotherthingy

Note also that Getopt::Janus I<does not> support switch clustering. That
is, you cannot abbreviate "C<-x -y -z>" as "C<-xyz>".  But note that
Getopt::Janus does tolerate "C<-xyz>" as a variant of "C<--xyz>".

And finally, note that the way Getopt::Janus parses "-x -y" depends
on whether C<-x> is declared as a C<yes_no> option.  If so,
then "C<-x -y>" is parsed as an C<-x> option (set to a true value), and
then a C<-y> option.  But if C<-x> isn't declared as a C<yes_no> option,
then "C<-x -y>" is parsed as "C<-x=-y>", i.e., setting the C<-x> value to the
two-character string "C<-y>".



=head1 SEE ALSO

L<Tk>, which forms the basis of Janus's currently only GUI class.

Other modules that process the command line (only):
L<Getopt::Std>, L<Getopt::Long>, L<Getopt::constant>

=head1 CAVEAT

In order to work around some odd behavior in Tk (specifically
in Tk::Pane), the Getopt::Janus interface to Tk has to sort of
guess the size to make the main window.  Sometimes it's
a bit larger than it needs to be, but every now and then it
might be a bit smaller, at which point you can either just use
the scrollbars to move around, or just make the window big enough
to not need the scrollbars.


=head1 NOTES

"Janus" is the name of the Roman god of beginnings (and therefore
of doors, the first day of months, boundaries, and so on).  He is
typically shown as having two faces -- one on the front of his
head and one on the back of his head.

You can pronounce "Janus" like the English name "Janice".

While this module (Getopt::Janus) is currently the only publicly
documented part of this distribution, there are several 
Getopt::Janus::* classes whose source might interest the morbidly
curious (but probably no-one else).

I wrote this module because sometimes you feel like a nut,
sometimes you don't.  That is, I have been writing lots of
little programs to which sometimes I wanted a simple
command-line interface (CLI) but sometimes a simple graphical
user interface (GUI).

Thanks to lots of different people who hand-held me thru writing
all the Tk code that this module uses, especially to
Daniel Berger for his very patient help with the geometry code.


=head1 COPYRIGHT AND DISCLAIMER

Copyright (c) 2003 Sean M. Burke.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=head1 AUTHOR

Sean M. Burke, sburke@cpan.org

=cut



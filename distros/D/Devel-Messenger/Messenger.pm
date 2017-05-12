package Devel::Messenger;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK @trap);

require Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw(note);
@EXPORT = ();
$VERSION = '0.02';
local @trap = ();

sub note {
    return _initialize({}, shift, "Using Devel::Messenger version $VERSION\n", @_) if (ref($_[0]) eq 'HASH');
    return '';
}

sub _initialize {
    my $prev  = shift; # HASH ref
    my $opts = shift; # HASH ref
    # inherit from previous opts
    foreach my $key (keys %$prev) {
        $opts->{$key} = $prev->{$key} unless exists($opts->{$key});
    }
    # suppress version announcement
    my $quiet = defined($opts->{quiet}) ? $opts->{quiet} : 0;
    shift if ($quiet and @_ and substr($_[0], 0, 31) eq 'Using Devel::Messenger version ');
    # output function to use
    my $output = '_' . ($opts->{output} || 'none');
    # filename or filehandle
    my $file = '';
    if (defined($opts->{output}) and ref($opts->{output})) {
        $output = '_handle';
        $file = $opts->{output};
    } elsif (!defined(&{"Devel::Messenger::$output"})) {
        $output = '_file';
        $file = $opts->{output};
    }
    # level of debugging (0 for unlimited)
    my $level = (defined($opts->{level}) and ($opts->{level} =~ m/^\d$/)) ? $opts->{level} : 1;
    # prefix function for each line
    my $prefix  = '';
    my $pkgname = $opts->{pkgname} || 0;
    my $linenum = $opts->{linenumber} || 0;
    if ($pkgname) {
        if ($linenum) {
            $prefix = '_prefix';
        } else {
            $prefix = '_prefix_name';
        }
    } elsif ($linenum) {
        $prefix = '_prefix_line';
    }
    # text to wrap around each note
    my ($begin, $end) = _wrapper($opts->{wrap} || '');
    # globalize new subroutine definition?
    my $global = $opts->{global} || 0;
    # set up CODE ref to return
    my $note = sub {
        return _initialize($opts, @_) if (ref($_[0]) eq 'HASH');
        my $debug = (ref($_[0]) eq 'SCALAR' ? ${shift()} : 1);
        return '' if ($output eq '_none');
        return '' if ($debug > $level and $level);
        no strict 'refs';
        &$output($file, splice @trap) if (@trap and $output ne '_trap');
        my $pre = $prefix;
        my @message = grep { defined($_) } @_;
        if (@message and $message[0] eq 'continue') {
            shift @message;
            $pre = '';
        }
        return '' unless @message;
        chomp($message[$#message]) if (substr($end, -1, 1) eq "\n");
        &$output($file, $begin, ($pre ? &$pre(caller) : ''), @message, $end);
    };
    # export subroutine
    if ($global) {
        #my $caller = (caller)[0];
        foreach my $pkg (sort grep { $_ ne 'Devel/Messenger.pm' } 'main', keys %INC) {
            (my $module = $pkg) =~ s/\.pm$//;
            $module =~ s/\//::/g;
            if (defined(&{"$module\::note"})) {
                no strict 'refs';
                #undef &{"$module\::note"} unless ($module eq $caller);
                *{"$module\::note"} = $note;
            }
        }
    }
    # note anything needful
    &$note(@_) if (@_ or (@trap and $output ne '_trap'));
    return $note;
}

# --------------------------- N O T E - M A R K U P -------------------------- #

sub _prefix {
    my ($package, $filename, $line) = @_;
    my ($pkgname) = _prefix_name($package, $filename, $line);
    my ($linenum) = _prefix_line($package, $filename, $line);
    return ($pkgname, ' '.$linenum, ': ');
}

sub _prefix_name {
    my ($package, $filename, $line) = @_;
    return (($package eq 'main' ? $filename : $package), ': ');
}

sub _prefix_line {
    my ($package, $filename, $line) = @_;
    return ("($line)", ': ');
}

sub _wrapper {
    if (ref($_[0]) eq 'ARRAY') {
        return @{shift()};
    } else {
        my $wrapping = shift;
        return ($wrapping, $wrapping); 
    }
}

# ---------------------- O U T P U T - F U N C T I O N S --------------------- #

sub _file {
    my $file = shift;
    if (open NOTE, ">>$file") {
        print NOTE @_;
        close NOTE;
    } else {
        warn "Cannot append to file $file: $!\n";
    }
}

sub _handle {
    my $file = shift;
    print $file @_;
}

sub _print  { local $| = 1; shift; print @_; }

sub _warn   { shift; warn @_; }

sub _return { shift; return @_ if wantarray; join('', @_); }

sub _trap   { shift; push @trap, @_; return ''; }

sub _none   {}

1;

__END__

=head1 NAME

Devel::Messenger - Let Your Code Talk to You

=head1 SYNOPSIS

  use Devel::Messenger qw{note};

  # set up localized subroutine
  local *note = Devel::Messenger::note {
      output     => 'print',
      level      => 2,
      pkgname    => 1,
      linenumber => 1,
      wrap       => ["<!--", "-->\n"],
  };

  # print a note
  note "This is a sample note\n";

  # print a multipart note
  note "This is line two. ";
  note "continue", "This is still line two.\n";

  # print if 'level' is high enough
  note \2, "This is debug level two\n";

=head1 DESCRIPTION

Do you want your program to tell you what it is doing? Send this messenger
into the abyss of your code to bring back to you all the pertinent information
you want.

First, set notes in your code, in-line comments that start with C<note>
instead of C<#>.

    # this is an in-line comment (it is boring)
    note "this is a note (things start getting exciting now)\n";

To keep your program from giving you terrible errors about C<note> not
being defined, give it something to do.

  use subs qw{note};
  sub note {}

Or you could import the slightly more powerful C<note> subroutine defined
in Devel::Messenger.

  use Devel::Messenger qw{note};

By itself, C<note> does not do anything. Right now, all it is doing is 
making sure Perl doesn't give you an error message and die.

So how do you make Devel::Messenger go and activate these notes?

=head2 Specify What You Want Your Messenger to Do

Devel::Messenger wants to help you and your code talk to each other. It
will act as a messenger between you both.

First, you tell Devel::Messenger which notes to talk to, and how you want
it to return messages to you. Then, it goes off and starts negotiating with
your code.

Use Devel::Messenger's own C<note> subroutine to specify your instructions.

  local *note = Devel::Messenger::note \%instructions;

Your instructions must be in the form of a HASH reference for Devel::Messenger
to understand you. You may wish to use an anonymous HASH reference.

  local *note = Devel::Messenger::note {
      output => 'print',
      level  => 2,
  };

Here, we have told our messenger to C<print> any notes which are specified
as level one or level two, which appear in the current package. When you
run your code, Devel::Messenger will look for notes that match your 
instructions. Any notes that match those criteria will be printed via the 
Perl function C<print>.

You may also request Devel::Messenger to look for notes in other packages.

  local *Other::Module::note = Devel::Messenger::note {
      output => 'print',
      level  => 2,
  };

If you are going to search for notes in multiple packages, it might be
easier to capture the instructions in a SCALAR, then use the SCALAR in
several places.

  my $note = Devel::Messenger::note {
      output => 'print',
      level  => 2,
  };

  local *note = $note;
  local *Other::Module::note = $note;

You may have noticed that I have been using the Perl function C<local> in
all my GLOB assignments. This is not necessary. In fact, it can be downright
annoying at times. Do it anyway.

If you are using the Perl module C<warnings>, or are running Perl with
the C<-w> switch, every time you redefine a subroutine, a warning is
generated. Using C<local> avoids these errors.

If you are running any of your code under C<mod_perl>, having a globally
assigned subroutine for debugging can cause other C<mod_perl> copies of
your code to also be sending you debugging information. That gets nasty.
Using C<local> avoids this problem.

However, when you use C<local>, you must be careful that your C<note>
definition stays in scope for as long as you wish it to. Otherwise,
Devel::Messenger will forget what it is doing and go back to sleep. In
object-oriented programming, you may wish to store your instructions in
your object.

  my $self = bless {};
  $self->{note} = Devel::Messenger::note {
      output => 'print',
      level  => 2,
  };
  $self->{note}->("This is my note\n");
  local *note = $self->{note};
  note "This is also my note\n";

=head2 Nitty-Gritty

Your instructions to C<Devel::Messenger::note> must be in a HASH reference.
The keys of that HASH instruct Devel::Messenger to do different things.

=over 4

=item global

If you want notes from all the modules you are using, and you are not
worried about global subroutine definitions or "subroutine redefined"
warnings, you may wish to specify that you want to search for all notes.

  note { global => 1 };

This will search %INC and replace any defined C<note> subroutine with the
new definition. If you have other subroutines named C<note>, they will be
overridden.

=item level

Set how much debugging you want. The bigger the number, the more verbose
(except zero, which is unlimited).

A note can specify what level it is.

  note "This is level one\n";
  note \1, "This is also level one\n";
  note \2, "This is level two\n";
  note \3, "This is level three\n";

By setting the C<level> you want, Devel::Messenger will know to ignore
notes with a higher level than you specified.

=item linenumber

Sometimes it is useful to know where a note came from. This setting will
prepend the linenumber to the messages Devel::Messenger finds for you.

See also C<pkgname>.

=item output

If you do not tell Devel::Messenger what to do with your messages, it will
just ignore them. You can specify where to send them by setting this
instruction.

There are several ways Devel::Messenger can try to send you messages. These
are described below:

=over 8

=item file

Internal use only.

=item handle

Internal use only.

=item none

Abandons your note.

=item print

Sends your note to the perl subroutine 'print'.

=item return

Returns your note to you (you will have to grab it).

  local *note = Devel::Messenger::note { output =>'return' };
  $text = note "This is my note\n";

=item trap

Traps your notes until you set your output to something else, at which
time the trapped notes are sent to the newly designated output. Sending
to C<return> will abandon any trapped notes.

  local *note = Devel::Messenger::note { output => 'trap' };
  note "This note is trapped for a while\n";
  local *note = note { output => 'print' };

Notice that I did not send instructions to Devel::Messenger when I was
finished trapping notes. Any C<note> subroutine created by Devel::Messenger
knows how to take new instructions. In this case, the trapped notes will
be forgotten unless you give new instructions to the same subroutine that
trapped the notes originally.

=item warn

Sends your note to the perl subroutine 'warn'.

=item a FILEHANDLE

Prints your note to a filehandle.

  open FILE, '>file.txt' or die $!;
  local *note = Devel::Messenger::note { output => \*FILE };
  note "This is my note\n";
  close FILE;

=item a file name

Appends each note to a file.

  local *note = Devel::Messenger::note {output =>'file.txt'};
  note "This is my note\n";

Any string specified as a value for C<output>, which is not listed above,
is interpretted as a file name. A warning is issued if the file cannot
be opened for appending.

=back

=item pkgname

If you want to know from which package a note is coming, you can have
Devel::Messenger prepend the package name to each message. If the note is
coming from package "main" (the default package), the filename shall be
prepended instead.

If this is not enough information, you may also want to ask for a C<linenumber>
to be provided.

=item quiet

When you instruct C<Devel::Messenger::note>, it tries to send you a message
telling you which version of Devel::Messenger you are using. You may not
wish to fill up your error log, or other files, with this version information.
In this case, you should tell Devel::Messenger to keep quiet about what
version it is.

  note { quiet => 1 };

=item wrap

Devel::Messenger likes to give you messages how you like them. With this
option, you can specify markup you wish to have wrapped around each note.
Accepts an ARRAY reference or a string.

  local *note = Devel::Messenger::note { wrap => ["<!--", "-->\n"] };
  note "This is an HTML comment\n";
  # <!--This is an HTML comment-->\n

  local *note = Devel::Messenger::note { wrap => '###' };
  note "help!";
  # ###help!###

If the second part of the wrapping text ends in a newline (\n), the note
is chomped before being wrapped.

=back

=head2 Common Debug Levels

As explained above, notes can specify what level they are. The level could
theoretically be from one all the way up to your integer limit.

However, levels could become almost meaningless if we allowed so many
different levels.

My standard levels are:

=over 4

=item 1

Minimal information about what the program is doing.

=item 2

Database interaction: connections, queries, number of records returned, 
et cetera.

=item 3

In depth information about what the program is doing.

=item 4

In depth information about database interaction.

=item 5

In depth information about formatting.

=item 6

In depth information about conversions.

=item 7

In depth information about everything else.

=back

=head1 AUTHOR

Nathan Gray - kolibrie@southernvirginia.edu

=head1 COPYRIGHT

Devel::Messenger is Copyright (c) 2001 Nathan Gray.
All rights reserved.

You may distribute under the terms of either the GNU General
Public License, or the Perl Artistic License.

=cut

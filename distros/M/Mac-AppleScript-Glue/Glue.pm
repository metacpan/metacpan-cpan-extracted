package Mac::AppleScript::Glue;

=head1 NAME

Mac::AppleScript::Glue - allows AppleScript to be written in Perl

=head1 SYNOPSIS

    use Mac::AppleScript::Glue;

    my $finder = new Mac::AppleScript::Glue::Application('Finder');

    $finder->insertion_location->open;


=head1 DESCRIPTION

This module allows you to write Perl code in object-oriented syntax to
control Mac applications.  The module does not actually execute Apple
Events, but actually translates Perl code to AppleScript code and
causes it to be executed.


=head2 Quick start

The following AppleScript opens the "current" folder in the Finder:

    tell application "Finder"
        open insertion location
    end tell

To do this in Perl, you first include the module:

    use Mac::AppleScript::Glue;

Then you create an object you'll use to talk to the Finder application:

    my $finder = new Mac::AppleScript::Glue::Application('Finder');

And finally you issue the compound statement:

    # open the Finder's "insertion location" in a new window
    $finder->insertion_location->open;

You can save the result of a statement:

    # get the Finder's "insertion location"
    my $loc = $finder->insertion_location;

And if that result is not a scalar, list, or hash (more on this
later), you can use that result as an object to do further work:

    # now open that in a new window
    $loc->open;

You can set attributes:

    my $folder = $finder->make_new_folder;

    $folder->set(name => 'My folder');

If you need to get a particular element of an object, put the
identifier as an argument to the thing that names the element list:

    my $window = $finder->windows(1);

If you need to specify parameters of a command, use a hash for the
parameters, where each key/value pair corresponds to a parameter name
and value:

    my $epson_files = $finder->files(whose_name_contains => 'epson');

You can specify both identifiers and parameters:

    my $epson_files = $finder->files(1, whose_name_contains => 'epson');

Finally, there are cases where you need to create an object reference,
rather than obtaining one from an application.  To do this, you can
use an application object to create a
Mac::AppleScript::Glue::Object(3pm) that refers to both the object
reference and the application to which that reference should belong:

    my $folder = $finder->objref('folder "Applications"');

Then, you can use that as you normally would:

    # open the "Applications" folder
    $folder->open;

If you don't need a full-fledged object, you can simply specify a
parameter of a I<reference> to a scalar containing a string:

    # open the "Applications" folder
    $finder->open(\'folder "Applications"');

This is also what you should use if you need to pass an AppleScript
"constant" along:

    $folder->duplicate(replacing => \'true');

But an easier way is to enclose the name of the constant in
angle-brackets; the module will know to use it verbatim rather than
trying to quote it:

    $folder->duplicate(replacing => '<true>');


=head2 Return values

If you issue a statement that will return a value, like C<insertion
location>, the result of that statement is always a scalar.  The
actual contents of this scalar depends on the sort of statement.  It
will be one of:

=over 4

=item regular scalar

A number or a string.  This is what you'd expect in Perl -- like 1, or
"foo".

=item object reference

An object reference is a textual string that AppleScript uses to
describe both the class and context of a "thing".  For example, the
C<insertion location> statement might return an object reference of:

    folder "Desktop" of folder "johnl" of folder "Users" of startup
    disk of application "Finder"

When Mac::AppleScript::Glue(3pm) sees this sort of reference, it puts the
whole object reference string into an object of type
Mac::AppleScript::Glue::Object(3pm) (see
L<Mac::AppleScript::Glue::Object>).  It also stores in this object the
application object that created the object.  By doing this, the
Mac::Application::Glue::Object(3pm) can be used by itself to access or
modify other data.

=item array or hash reference

If the statement returned an AppleScript "list" or "record", the
result will be a Perl array- or hash-reference, respectively.  This
could contain simple scalars, or a combination of any of the result
types; it can also be nested.

Note that you'll have to dereference the references to use the
elements:

    for my $window (@{ $finder->windows }) {
        ...
    }

or:

    my $props = $finder->properties;

    while (my ($key, $val) = each %{$props}) {
        ...
    }

=back


=head2 Notes

For multi-word AppleScript terms like C<insertion location>, use the
underscore character (_) in place of each space character.

You generally need to reverse the parts of a statement when
translating AppleScript to Perl.  In AppleScript, C<open insertion
location> really sends the "open" message to the object represented by
"insertion location".  This maps to the Perl syntax
C<< insertion_location->open() >>.

Unlike Perl, AppleScript makes a distinction between booleans and
numbers -- you can't intermix them.  So if an AppleScript method wants
a boolean as a parameter, you I<must> use the AppleScript constants
B<true> or B<false>.  You can do this by enclosing the string with
angle-brackets (C<< <true> >>) or passing a reference to a string
containing the constant (C<\'true'>).


=head1 HOW IT WORKS

Contrary to what it might seem, this module knows nothing of Apple
Events, and only knows a sprinkling of AppleScript syntax.

Instead, it actually employs a variety of magic dust to accomplish its
tasks:

=over 4

=item *

The Mac::AppleScript::Glue module translates Perl-style object/method
calls to actual AppleScript.

=item *

The resulting AppleScript is executed by the Mac::AppleScript(3pm)
module (by Dan Sugalski); any results are returned as text.

=item *

The AppleScript-format result data is translated into into Perl data
structures as appropriate.

=item *

Perl's C<$AUTOLOAD> feature (L<perlobj>) is used to translate
statements like C<< $finder->insertion_location >> to AppleScript.
Method calls that aren't defined in the module itself and don't refer
to a part of the object's data structure are delegated to a translater
function that tries to write the method as if it was AppleScript.

=item *

AppleScript's concept of the "object reference" is essential to the 
idea of having Perl objects for things other than applications.

=item *

The AppleScript interpreter seems somewhat lenient on the exact syntax
of the language.  This makes it possible to write AppleScript
statements that work even though they look weird.

=back

=cut

use strict;
use warnings;

require 5.6.0;

######################################################################

use base qw(Exporter);

our ($VERSION, $AUTOLOAD, @EXPORT, @EXPORT_OK);

$VERSION = '0.03';

BEGIN {
    @EXPORT = qw();

    @EXPORT_OK = qw(
        %Debug
        @DebugAll
        dump
        dump_pretty
        is_number
        to_string
        from_string
    );
}

our (%Debug, @DebugAll);

%Debug = ();

#
# NOTE: remember to update the "Debugging" section below if these are
# added or changed
#

@DebugAll = qw(
    INIT
    AUTOLOAD
    SCRIPT
    RESULT
    EXEC
    PARSE
);

######################################################################

use Carp;
use Data::Dumper;
    $Data::Dumper::Indent =
    $Data::Dumper::Useqq = 1;
use IO::File;
use Text::ParseWords qw();
use Mac::AppleScript 0.03;

use Mac::AppleScript::Glue::Application;
use Mac::AppleScript::Glue::Object;

######################################################################
######################################################################
# beginning of methods

=head1 METHODS

There aren't any useful public methods in Mac::Application::Glue
itself.  Instead, see L<Mac::AppleScript::Glue::Application> and
L<Mac::AppleScript::Glue::Object>.

=cut

######################################################################

#
# Constructor for object.  Once initialized, each key/value pair of
# the argument list is treated as a separate method call, where the
# method corresponds to the key.
#

sub new {
    my ($type, @args) = @_;

    my $self = bless {}, $type;

    $self->_init(\@args)
        or return undef;

    my %args = @args;

    while (my ($method, $val) = each %args) {
        warn "init: calling method \"$method\" with $val\n"
            if $Debug{INIT};

        $self->$method($val);
    }

    $self->dump('initialized')
        if $Debug{INIT};

    return $self;
}

######################################################################

#
# Default method for initializing a new object.  Does nothing except
# return itself.
#

sub _init {
    my ($self, $args) = @_;

    return $self;
}

######################################################################

#
# An AUTOLOADer that handles all function/method calls not otherwise
# defined.  It works by looking in the hashref $self to see if there's
# a key that starts with an underscore that corresponds to the
# attempted method (eg, "_foo" for a call of C<< $self->obj >>).
#
# Handles a simple "set" semantic with one argument.
#
# Calls the _unknown_method method for attempted methods that don't
# correspond to the $self's data structure.
#

sub AUTOLOAD {
    my ($self, @args) = @_;

    my $type = ref $self;

    $AUTOLOAD =~ s/^.*:://;

    my $method = $AUTOLOAD;

    return if $method eq 'DESTROY';

    if ($Debug{AUTOLOAD}) {
        warn "\n[" . ref(${self}) . "::AUTOLOAD->$method]\n", 
            Data::Dumper->Dump(
                [$self, \@args, join(':', (caller(0))[1..2])], 
                [qw(self args caller)]
            );
    }

    if (exists $self->{"_$method"}) {
        warn "[AUTOLOAD: calling local method \"$method\"]\n" 
            if $Debug{AUTOLOAD};

        if (@args) {
            $self->{"_$method"} = $args[0];
        }

        return $self->{"_$method"};
    }

    warn "[AUTOLOAD: handling unknown method \"$method\"]\n" 
        if $Debug{AUTOLOAD};

    return $self->_unknown_method($method, @args);
}

######################################################################

#
# A default handler for AUTOLOAD'ed function calls.
#

sub _unknown_method {
    my ($self, $method, @args) = @_;

    confess "no method called \"$method\" in object $self";
}

# end of methods
######################################################################

######################################################################
# beginning of functions


=head1 FUNCTIONS

Note that no functions are exported by default.  You can use them by
specifying the full package name:

    Mac::AppleScript::Glue::run('something');

or by specifying them on the C<use> statement at the top of your
program:

    use Mac::AppleScript::Glue qw(run);

    run('something');

=over 4

=cut

######################################################################

=item run([$app, ] @script)

Runs an AppleScript whose lines are in C<@script>.  If C<$app> is
specified, it should be a previously created
Mac::AppleScript::Application(3pm) object to which any object
references will "belong to."

=cut

sub run {
    my $app;

    if (@_ && ref $_[0]) {
        $app = shift;
    }

    my $script = join("\n", @_);

    if ($Debug{SCRIPT}) {
        warn "\n-- script --\n", $script, "\n";
    }

    my $result_str = Mac::AppleScript::RunAppleScript($script);

    unless (defined $result_str) {
        chomp $@;

        if ($Debug{SCRIPT}) {
            warn "-- error --\n",
                "$@\n",
                "-- done\n";
        }

        die "Mac::AppleScript returned error ($@)\n";
    }

    #
    # work around Mac::AppleScript returning garbage in cases where it
    # should return emptiness
    #

    $result_str =~ s/^\001.*//;

    if ($Debug{SCRIPT}) {
        warn "-- result --\n",
            "$result_str\n",
            "-- done --\n";
    }

    my $result = from_string($app, $result_str);

    if ($Debug{RESULT}) {
        dump_pretty($result, 'result');
    }

    return $result;
}

######################################################################

=item from_string([$app,] $str)

Parses a string containing an AppleScript result, and returns the Perl
data structures corresponding to that result.  If C<$app> is specifed
as a Mac::AppleScript::Glue::Application(3pm) object, any object
references will be "owned" by that application.

=cut

sub from_string {
    my $app;
    my $str;

    if (@_ == 2) {
        ($app, $str) = @_;
    } else {
        ($str) = @_;
    }

    return undef unless $str;

    chomp $str;

    my @tokens = grep($_,
        map {
            # remove leading/trailing space

            if ($_) {
                s/^\s+//;
                s/\s+$//;
            }

            $_;

        } Text::ParseWords::parse_line(
            '[,{}:]', 
            'delimiters', 
            $str
        )
    );

    warn Data::Dumper->Dump([\@tokens], [qw(tokens)])
        if $Debug{PARSE};

    my $result = _parse_word(\@tokens, $app);

    warn Data::Dumper->Dump([$result], [qw(result)])
        if $Debug{PARSE};

    return $result;
}

######################################################################

#
# internal function to parse a AppleScript list or record
#

sub _parse_list {
    my ($tokens, $app) = @_;

    my @list;
    my $is_hash;

    while (@$tokens) {
        my $token = shift @$tokens;

        # if the token after the next one is a colon, then this is
        # a record, not a list, and this token is the key

        if ($tokens->[0] && $tokens->[0] eq ':') {
            $token =~ s/ /_/g;
            push @list, $token;
            shift @$tokens;
            $is_hash = 1;
            next;
        }

        # right-brace: list or record terminator
        if ($token eq '}') {
            last;

        # comma: list or record separator
        } elsif ($token eq ',') {
            if ($is_hash && @list % 2 != 0) {
                push @list, undef;
            }

            # ignore

        # something else
        } else {
            unshift @$tokens, $token;
            push @list, _parse_word($tokens, $app);
        }
    }

    if ($is_hash) {
        return { @list };
    } else {
        return \@list;
    }
}

######################################################################

#
# internal function parse an AppleScript word (which could be the
# start of a list or record; see _parse_list above)
#

sub _parse_word {
    my ($tokens, $app) = @_;

    my $token = shift @$tokens;

    # left-brace? -- it's a start of list or record
    if ($token eq '{') {
        return _parse_list($tokens, $app);

    # number? -- leave as is
    } elsif (is_number($token)) {
        return $token;

    # quoted-string? -- remove quotes
    } elsif ($token =~ s/^"(.*?)"$/$1/) {
        return $token;

    # otherwise it's a reference of some sort
    } else {
        if ($app) {
            my $appref = $app->ref;

            $token =~ s/ of $appref$//;
        }

        return new Mac::AppleScript::Glue::Object(
            app => $app,
            ref => $token,
        );
    }
}

######################################################################

=item to_string($value)

Converts a Perl data structure into an AppleScript string.  It will
correctly interpret Mac::AppleScript::Glue::Object(3pm) objects.

=cut

sub to_string {
    my ($value) = @_;

    #
    # arrays are converted to AS lists (recursively)
    #

    if (ref($value) eq 'ARRAY') {
        return '{' 
            . join(', ', 
                map { 
                    to_string($_) 
                } @{$value}) 
            . '}';

    #
    # hashes are converted to AS records (recursively)
    #

    } elsif (ref($value) eq 'HASH') {
        my @list;

        for my $key (keys %{$value}) {
            my $val = $value->{$key};

            $key =~ s/_/ /g;

            push @list, "$key:" . to_string($val)
        }

        return '{' . join(', ', @list) . '}';

    #
    # scalar-refs are let through verbatim
    #

    } elsif (ref($value) eq 'SCALAR') {
        return $$value;

    #
    # object references are let through verbatim
    #

    } elsif (ref $value && $value->isa('Mac::AppleScript::Glue::Object')) {
        return $value->ref;

    #
    # otherwise it's something we don't know how to handle
    #

    } elsif (ref $value) { 
        confess "bad reference found in data";

    #
    # numbers are let through as is
    #

    } elsif (is_number($value)) {
        return $value;

    #
    # strings enclosed in <> are treated like object-references
    #

    } elsif ($value =~ /^<(.*)>$/) {
        return $1;
            
    #
    # anything else is a string, and is quoted
    #

    } else {
        $value =~ s/^\\</</g;   # allow "\<..." for quoting brackets
        $value =~ s/\\/\\\\/g;  # quote backslashes
        $value =~ s/"/\\"/g;    # quote double-quotes

        return "\"$value\"";    # enclosee in double-quotes
    }
}

######################################################################

=item dump($obj [, $label])

Provides a simple dumping facility for any sort of data.  All this
does is call Data::Dumper(3pm)'s C<Dump()> method.

=cut

sub dump {
    my ($obj, $label) = @_;
    
    warn Data::Dumper->Dump([$obj], [$label || 'obj']);
}

######################################################################

=item dump_pretty($object, $label [, $fh])

Provides a nicely-formatted view of any object.  The object can be as
simple as a regular scalar, or a deeply-nested tree of references.  If
the object is a Mac::AppleScript::Glue::Object, angle-brackets (E<lt>,
E<gt>) are placed around its value.

If a string is supplied as C<$label>, the output will be labeled suchly.

Output is to B<STDERR> by default; you can provide an alternate
filehandle in C<$fh> if you like.

=cut

sub dump_pretty {
    my ($obj, $label, $fh, $level) = @_;

    $fh ||= \*STDERR;
    $level ||= 0;

    my $indent = "\t" x $level;

    $fh->print($indent);

    if ($label) {
        $fh->print("$label: ");
    }

    if (!defined $obj) {
        $fh->print("undef\n");

    } elsif (ref $obj) {
        if (ref($obj) eq 'ARRAY') {
            $fh->print("[\n");

            for (@{$obj}) {
                dump_pretty($_, undef, $fh, $level + 1);
            }

            $fh->print($indent, "]\n");

        } elsif (ref($obj) eq 'HASH') {
            $fh->print("{\n");

            for (sort keys %{$obj}) {
                dump_pretty($obj->{$_}, $_, $fh, $level + 1);
            }

            $fh->print($indent, "}\n");

        } elsif ($obj->isa('Mac::AppleScript::Glue::Object')) {
            $fh->print('<' . $obj->ref . ">\n");

        } else {
            $fh->print("<$obj>\n");
        }

    } elsif (is_number($obj)) {
        $fh->print("$obj\n");

    } else {
        $fh->print("\"$obj\"\n");
    }
}

######################################################################

=item is_number($str)

Returns true if the given string is really a number.

=cut

sub is_number {
    my ($str) = @_;

    # this line borrowed from the perl FAQs

    $str =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/;
}

######################################################################
######################################################################
# end of functions

=back

=head1 DEBUGGING

Various amounts of debugging can be enabled by manipulating the 
C<%Mac::AppleScript::Glue::Debug> hash.  Debugging usually involves
printing messages to the B<STDERR> file handle.

To turn on a certain type of debugging, specify the key that names the
debug option, and a value of non-zero.  For example, the following
enables debugging of generated AppleScripts:

    $Mac::AppleScript::Glue::Debug{SCRIPT} = 1;

You can get a list of all the debugging keywords by examining
C<@Mac::AppleScript::Glue::DebugAll>.


=head2 Debugging keywords

=over 4

=item SCRIPT

Show each generated AppleScript before it's sent off to the script
interpreter, as well as the AppleScript-formatted result string.  This
is useful when writing programs using Mac::AppleScript::Glue, as
looking at the generated AppleScript is often the best way to figure
out why a statement is failing.

=item RESULT

Show the parsed return value from the AppleScript result.  This is the
data you will be working with when you examine a return value from a
statement.

=item PARSE

Show the process of parsing the AppleScript result.  You probably
don't want to be setting this.

=item INIT

Show the values of Mac::AppleScript::Glue objects after all
initialization has been completed.  You probably don't want to be
setting this.

=item AUTOLOAD

Show attempted calls to non-existent functions and methods.  You
probably don't want to be setting this.

=back


=head1 HINTS

Unfortunately this package doesn't mean that you don't have to know
AppleScript, or the class/event hierarchy of the operating system.
Both of those can be quite inscrutable.

I recommend having the Script Editor program open while writing Perl
code.  Use the dictionary browser (File menu > Open Dictionary) to
browse the dictionaries for the applications you're trying to control.
If you're having trouble getting the right Perl code written, try
writing it in AppleScript first, then translate to Perl, then let this
module translate it back to AppleScript. ;)

If you're trying to navigate through inscrutable AppleScript results,
try using the C<dump_pretty()> function (see above).

Finally, turn on the B<SCRIPT> and B<RESULT> debugging keywords for
the most useful yet not-too-overwhelming debug output.


=head1 BUGS AND ISSUES

=over 4

=item *

It's fairly slow.  This is mostly because a compound statement (C<<
$finder->insertion_location->name >>) requires several separate
AppleScript executions, generally one per element besides the
application object.  It's also slow because under the hood, the Perl
calls are translated to AppleScript, then compiled, and finally
executed.

=item *

Error-handling is nearly non-existant.  If the resulting AppleScript
is bad, or the target applications don't understand the resulting
AppleScript, this module will force a C<die()>, and you will see
errors on B<STDERR>.  If you want to trap this, use C<eval>.

=item *

AppleScript generation is not quite right.  However, it works most of
the time.

=back


=head1 SEE ALSO

L<Mac::AppleScript>

L<Mac::AppleScript::Glue::Application>

L<Mac::AppleScript::Glue::Object>

the application dictionaries, accessible through the B<Script Editor>
application (in the C</Applications/AppleScript> folder)


=head1 AUTHOR

John Labovitz E<lt>johnl@johnlabovitz.comE<gt>

New versions of this package are available at
B<http://www.johnlabovitz.com/hacks/>


=head1 ACKNOWLEDGEMENTS

Thanks to David Bonn for the use of his mountain retreat, where most
of this module was written over three days of peace, quiet, and light.


=head1 COPYRIGHT

Copyright (c) 2002 John Labovitz. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself. 

=cut

1;

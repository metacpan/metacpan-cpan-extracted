package Java::Build::JVM;
use strict; use warnings;

=head1 NAME

Java::Build::JVM - starts one JVM for compiling

=head1 SYNOPSIS

    use Java::Build::JVM;

    my $compiler = Java::Build::JVM->getCompiler();
    $compiler->destination("some/path");

    $compiler->classpath("some/pathto/jar.jar:some/other/path/javas");
    $compiler->append_to_classpath("something/to/add/to/previous/path");

    $compiler->compile([ qw(list.java of.java programs.java) ]);

=head1 DESCRIPTION

This class starts a single JVM which it then helps you contact for compiling
tasks.  This is the most important feature of the popular Ant build tool.
Using this class, you can effectively replace Ant, and its notoriously
unmaintainable build.xml files, with Perl scripts.  Most Ant tasks are already
built in to Perl with far more flexibility than Ant provides.

To obtain a compiler, use this module, then call getCompiler.  It has that
name to prevent conflicts with the Java new keyword.

Once you have a compiler, you may change the destination of subsequent compiles
from the location of the source files to a directory of your choice using
the destination method.  You can create or append to a classpath with
the classpath or append_to_classpath methods.  Note that your CLASSPATH
environment variable still works in its usual way.

Finally, once you have the destination and classpath set, you can compile
a list of files by passing them to the compile method.  Note that they need
to be in an array reference (if you don't know what that means, put the list
in square brackets).

Note that you must have tools.jar in your CLASSPATH when you run your script.
Without that, JVM.pm will not be able use Inline::Java.  The classpath
you use inside the script may be the same or different than your environment
variable, depending on how you use the classpath and append_to_classpath
methods.

Since Sun has, in its finite wisdom, chosen to deprecate the compiling
methods that javac uses, there will be one warning for each time you
call compile.  It will say something like this:

    Note: sun.tools.javac.Main has been deprecated.
    1 warning

This warning is not a problem in Java 1.4.

=head1 METHODS

=cut

our $VERSION = '0.04';

use Carp;
use Inline Java      => 'DATA',
#          DIRECTORY => '/etc/Inline',
           PORT      => 7890;

=head1 getCompiler

This serves as the constructor for this class.  It might be called new, but
that is a reserved word in Java which Inline::Java translates into a method
name.  To avoid confusion, I changed the name.  This also leaves open the
possibility of turning this into a generic compiler factory which could
give you a javac, jikes, or other compiler at your option.  For now, only
javac is supported.

There are no arguments to this method (except the class name, but Perl
does that for you).

The object you receive provides indirect access to javac.  Only one
JVM is ever started.

=cut

sub getCompiler {
    my $class    = shift;
    my $compiler = { COMPILER => Java::Build::JVM::PerlJavac->new() };
    return bless $compiler, $class;
}

=head1 classpath

This is a dual use accessor.  It always returns the classpath, but
if called with an argument, it changes the classpath first.  The argument
can be anything, including "".  This allows you to remove the classpath's
value and its effect.

See also append_to_classpath below.

=cut

sub classpath {
    my $self     = shift;
    my $new_path = shift;

    if (defined $new_path) {
        $self->{CLASSPATH} = $new_path;
    }
    return $self->{CLASSPATH};
}

=head1 append_to_classpath

Pass a single jar or directory or a colon separated list of jars and/or
directories.  These will be appended to the end of the classpath.  The
full classpath is returned.

=cut
sub append_to_classpath {
    my $self             = shift;
    my $new_path_element = shift;

    $self->{CLASSPATH} .= ":$new_path_element";
    return $self->{CLASSPATH};
}

=head1 destination

This is a dual use accessor.  It always returns the destination, but
if called with an argument, it changes the destination first.
The destination (if defined) is used during compile as if you invoked
javac at the command line as:

    javac -d destination ...

=cut

sub destination {
    my $self     = shift;
    my $new_dest = shift;

    if ($new_dest) {
        $self->{DESTINATION} = $new_dest;
    }
    return $self->{DESTINATION};
}

=head1 sourcepath

Dual use accessor for -sourcepath command line option to compiler.

=cut

sub sourcepath {
    my $self           = shift;
    my $new_sourcepath = shift;

    if ($new_sourcepath) {
        $self->{SOURCEPATH} = $new_sourcepath;
    }
    return $self->{SOURCEPATH}
}

=head1 debug

Dual accessor for things which go after -g:.  If you never call this,
-g is left out.  If you do call it, you must supply a valid value.
No checking is done here.

=cut

sub debug {
    my $self           = shift;
    my $new_debug_type = shift;

    if ($new_debug_type) {
        $self->{DEBUG} = $new_debug_type;
    }
    return $self->{DEBUG};
}

=head1 compile

This is the operative method.  Give it a list of source files to compile
(probably with path names attached).  It will ask the single
JVM to compile the files.  The compiler uses the same classes as javac.
Any classpath or destination are passed to it.

Path names need to be either absolute, or relative the directory from which
the script launched.  I have found no way to change the directory used by
the JVM housing the compiler after it starts.

Returns true if the compile worked wihtout errors and dies setting
the $@ to the javac error message otherwise.

=cut

sub compile {
    my $self        = shift;
    my $list        = shift;

    if (not defined $list or ref($list) !~ /ARRAY/) {
        carp "Nothing to compile";
        return;
    }

    if ($self->{DEBUG}) {
        unshift @$list, "-g:$self->{DEBUG}";
    }
    if ($self->{SOURCEPATH}) {
        unshift @$list, "-sourcepath", $self->{SOURCEPATH};
    }
    if ($self->{CLASSPATH}) {
        unshift @$list, "-classpath", $self->{CLASSPATH};
    }
    if ($self->{DESTINATION}) {
        unshift @$list, "-d", $self->{DESTINATION};
    }
#    {
#        local $" = "\n";
#        print "compiling with @$list\n";
#    }
    local $" = " ";  # In case caller has changed this.
    # Bad things happen if $" has newline(s), files are issued as commands.
    my $success = $self->{COMPILER}->compile($list);
    if ($success) { return $success;                         }
    else          { croak $self->{COMPILER}->dumpMessages(); }
}

1;

=head1 REQUIRES

Inline::Java

=head1 BUGS

The JVM will not be moved.  Once it starts, I cannot get it to change
directories.  This affects what source files you can give it.  In general,
full paths work, but you must supply a proper classpath.  You can also supply
paths which are relative to the directory from which the script started.
In that case, a classpath is probably required.  If you know how to fix this,
please let me know.

Sun has deprecated this approach to compiling, so you will see deprecation
warnings.  Since this approach is the one used in Ant, Sun can't very well
turn it off, so the warning is that much more annoying.  See the DESCRIPTION
section for the text of the warning on Red Hat Linux 8.0 with SDK 1.4.1_02.

=cut

__DATA__
__Java__
// The approach to single JVM compiling below is lifted almost wholesale from
// org.apache.tools.ant.taskdefs.compilers.Javac13.java
// Thanks to the Ant project for providing this code as open source.
//
// I tried a non-reflection approach, but it did not always compile
// all of the needed inner classes.  In one test it produced only 166
// of 168 files.  The missing ones were anonymous inner classes of
// classes which had named inner classes.  The named inner classes were
// there, but the anonymous ones were not.

import java.io.PrintStream;
import java.io.ByteArrayOutputStream;
import java.lang.reflect.Method;

// In order to capture the error output from the compile, I must reset
// System.out and System.err to someother PrintStream.  My PrintStream
// is in the private class StringStream below.  I only need
// ByteArrayOutputStream so that I have something to pass to
// the PrintStream constructor.  It wants an OutputStream, the advantage
// of ByteArrayOutputStream is that it never uses the disk, this saves
// clutter and a proliferation of try blocks.

public class PerlJavac {
    Object compiler;
    Method compile;
    StringStream messages;

    public PerlJavac() {
        messages = new StringStream();
        System.setOut(messages);
        System.setErr(messages);
        try {
            Class  c = Class.forName("com.sun.tools.javac.Main");
            compiler = c.newInstance();
            compile  = c.getMethod (
                "compile", new Class[] {(new String [] {}).getClass ()}
            );
        }
        catch (Exception e) {
            e.printStackTrace();
            System.exit(1);
        }
    }
    public boolean compile(String[] args) {
        try {
            int result = (
                (Integer) compile.invoke (compiler, new Object[] {args})
            ).intValue();
            return (result == 0);
        }
        catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }
    public String dumpMessages() {
        return messages.dump();
    }

    private class StringStream extends PrintStream {
        StringBuffer output;
        public StringStream() {
            super(new ByteArrayOutputStream());
            output = new StringBuffer();
        }
        public void print(String s) {
            output.append(s);
        }
        public void println(String s) {
            output.append(s);
            output.append("\n");
        }
        public void write(int b) {
            output.append( (char)b );
        }
        public void write(byte[] buffer, int off, int len) {
            char[] chars = new char[buffer.length];
            for (int i = 0; i < buffer.length; i++) {
                chars[i] = (char)buffer[i];
            }
            output.append(chars, off, len);
        }
        public String dump() {
            String retval = output.toString();
            output        = new StringBuffer();
            return retval;
        }

    }
}

package Env::Modify;
use strict;
use warnings;
use base 'Exporter';
use Shell::GetEnv '0.09';
#use String::ShellQuote;   # nah, just borrow from String::ShellQuote
use File::Spec::Functions 'catfile';
use File::Temp;

*DEBUG = *DEVNULL; open DEVNULL,'>/dev/null';
our $DEBUG && (*DEBUG = *STDERR);
our $SHELL = 'sh';
our $CHDIR = 0;

our $VERSION = '0.02';
our @EXPORT_OK = qw(system readpipe qx backticks source
                    readpipe_list qx_list backticks_list);
my @readpipe_exp = qw(readpipe readpipe_list qx_list backticks_list);
our %EXPORT_TAGS = ('system' => ['system'],
                    'readpipe' => [@readpipe_exp],
                    'qx' => ['qx','backticks', @readpipe_exp],
                    'backticks' => ['qx','backticks', @readpipe_exp],
                    'all' => [ 'system', 'qx','backticks', 'source',
                               @readpipe_exp],
                    'chdir' => [],
                    'sh' => [], 'bash' => [], 'csh' => [], 'dash' => [],
                    'ksh' => [], 'tcsh' => [], 'zsh' => [] );


# default attributes that go to all Shell::GetEnv constructors
our %CMDOPT = (
    startup => 0,
    login => 0,
    interactive => 0,
    verbose => 0,
    );

our %ENVSOPT = (
    ZapDeleted => 1
    );

our $TEMPDIR = File::Temp::tempdir( CLEANUP => 1 );

my $calls = 0;

# RT115330 describes a bug with overloaded readpipe function.
# It was fixed in Perl v5.20.0
our $_RT115330 = $] < 5.020000;

sub import {
    # Handle the CORE::GLOBAL::readpipe bug (RT#115330) differently depending
    # on whether the caller primarily uses qx(), `backticks`,  or readpipe.
    # The bug was fixed in Perl v5.20.0
    my %tags = map {; $_ => 1 } grep /^:/, @_;
    my $cgreadpipe = 0;
    if ($tags{":qx"} || $tags{":backticks"} || $tags{":all"}) {
        *CORE::GLOBAL::readpipe = sub {
            local $_RT115330 = $] < 5.020000;
            return _readpipe_mod_env(@_);
        };
        $cgreadpipe = 1;
    } elsif ($tags{":readpipe"}) {
        # NB: CORE::GLOBAL::readpipe will not be respected for Perl <=v5.8.9
        *CORE::GLOBAL::readpipe = sub {
            local $_RT115330 = 0;
            return _readpipe_mod_env(@_);
        };
        $cgreadpipe = 1;
    }

    if ($tags{":system"} || $tags{":all"}) {
        no warnings 'once';    
        *CORE::GLOBAL::system = \&Env::Modify::system;
    }
    if ($tags{":chdir"}) {
        $CHDIR = 1;
    }
    for my $shell ('zsh','tcsh','ksh','dash','csh','bash','sh') {
        if ($tags{":$shell"}) {
            $SHELL = $shell;
        }
    }
    if ($cgreadpipe) {
        __PACKAGE__->export_to_level(1, __PACKAGE__, @_[1..$#_]);
        my $callpkg = caller;
        no strict 'refs';
        no warnings 'redefine';
        *{$callpkg . "::readpipe"} = \&CORE::GLOBAL::readpipe;
    } else {
        goto &Exporter::import;
    }
}

sub backticks {goto &readpipe }
sub qx { goto &readpipe }

sub backticks_list { goto &readpipe_list }
sub qx_list { goto &readpipe_list }

sub readpipe {
    local $_RT115330 = 0;
    return _readpipe_mod_env(@_);
}

sub readpipe_list {
    local $_RT115330 = 0;
    my $cmd = @_ > 1 ? _sh_quote(@_) : $_[0];
    return _readpipe_mod_env($cmd);
}

sub system {
    my @cmd = @_;
    my $cmd = @cmd > 1 ? _sh_quote(@cmd) : $cmd[0];
    $calls++;
    my $stub = "$calls.$$";
    my $stdout = catfile( $TEMPDIR, $stub . "-stdout");
    my $stderr = catfile( $TEMPDIR, $stub . "-stderr");
    my $getenv = Shell::GetEnv->new( $SHELL, $cmd,
                    { %CMDOPT, echo => 0,
                      stdout => $stdout, stderr => $stderr } );
    $getenv->import_envs( %ENVSOPT );

    if (-s $stderr) {
        open my $err, '>&2'; # or warn "print to unopened filehandle?"
        open my $fh, '<', $stderr;
        print {$err} <$fh>;
        close $fh;
        close $err;
    }
    if (-s $stdout) {
        open my $out, '>&1'; # or warn "print to unopened filehandle?"
        open my $fh, '<', $stdout;
        print {$out} <$fh>;
        close $fh;
        close $out;
    }
    unlink $stdout, $stderr;
    my $status = _status($getenv->status);
    $CHDIR && chdir $ENV{PWD};
    return $? = $status;
}

sub source {
    my ($file,@args) = @_;
    if ($SHELL eq 'tcsh') {
        $file = _sh_quote($file,@args);
        return Env::Modify::system( "source $file" );
    } elsif ($SHELL eq 'csh') {
        $file = _sh_quote($file,@args);
        return Env::Modify::system("source $file");
    } elsif ($SHELL eq 'ksh') {
        #  . $file  is supposed to work, but it doesn't
        $file = _sh_quote($file,@args);
        return Env::Modify::system("eval \$(cat $file)");
    } else {
        return Env::Modify::system( ". " . _sh_quote($file,@args) );
    }
}

sub _readpipe_mod_env {
    my ($cmd) = @_;

    if ($_RT115330) {
        if ($cmd !~ /"/) {
            $cmd = eval qq["$cmd"];
        } else {
            for my $delim ('#',',', qw(! ' ; " @ $ % ^ & * - = +
                              : . / ? ~ ` 00)) {
                if ($cmd eq '00') {
                    warn __PACKAGE__,"::_readpipe_mod_env: ",
                         "reinterpolation of $cmd neglected";
                } elsif ($cmd !~ /\Q$delim/) {
                    $cmd = eval qq[qq$delim$cmd$delim];
                    last;
                }
            }
        }
    }
    $calls++;
    my $stub = "$calls.$$";
    my $stdout = catfile( $TEMPDIR, $stub . "-stdout");
    my $stderr = catfile( $TEMPDIR, $stub . "-stderr");
    my $getenv = Shell::GetEnv->new( $SHELL, $cmd,
                    { %CMDOPT, echo => 0,
                      stdout => $stdout, stderr => $stderr } );
    $getenv->import_envs( %ENVSOPT );
    my @out;
    {
        local $/ = wantarray ? $/ : undef;
        no warnings 'io';  # in case open $fh touches fd 1 or 2
        open my $fh, '<', $stdout;
        @out = <$fh>;
        close $fh;
        if (-s $stderr) {
            open my $err, '>&=2'; # or warn "print to unopened filehandle?"
            open my $fh, '<', $stderr;
            my @err = <$fh>;
            print {$err} @err;
            close $err;
            close $fh;
        }
    }
    unlink $stdout, $stderr;
    $CHDIR && chdir $ENV{PWD};
    $? = _status($getenv->status);
    return wantarray ? @out : $out[0];
}

sub _status {
    my $ge_status = shift;

    # http://tldp.org/LDP/abs/html/exitcodes.html
    # treat exit code 128+n as command terminated by signal <n> ?
    # may not be portable to non-POSIX OS or other shells
    my $status = $ge_status;
    if ($status > 128) {
        $status = $status - 128;
    } else {
        $status = $status << 8;
    }
}

sub _sh_quote { # borrowed heavily from String::ShellQuote 1.04
    my @in = @_;
    return '' unless @in;
    my ($ret, $saw_non_equal, @err) = ('', 0);
    foreach (@in) {
	if (!defined $_ or $_ eq '') {
	    $_ = "''";
	    next;
	}
        s/\x00//g && 
            push @err, "No way to quote string containing null (\\000) bytes";
    	my $escape = 0;
	if (/=/) {
            $escape = 1 if !$saw_non_equal;
	} else {
	    $saw_non_equal = 1;
	}
	$escape = 1 if m|[^\w!%+,\-./:=@^]|;
	if ($escape || (!$saw_non_equal && /=/)) {
    	    s/'/'\\''/g;	# ' -> '\''

	    # make multiple ' in a row look simpler
	    # '\'''\'''\'' -> '"'''"'
    	    s|((?:'\\''){2,})|q{'"} . (q{'} x (length($1) / 4)) . q{"'}|ge;
	    $_ = "'$_'";
	    s/^''//;
	    s/''$//;
	}
    } continue {
	$ret .= "$_ ";
    }
    chop $ret;
    if (@err) {
        warn __PACKAGE__ . "::sh_quote: @err";
    }
    return $ret;
}

1;

=head1 NAME

Env::Modify - affect Perl %ENV from subshell

=head1 VERSION

0.02

=head1 SYNOPSIS

    use Env::Modify 'system', ':readpipe';

    $ENV{FOO}="bar";
    system('echo $FOO');   #  "bar"
    system('FOO=baz');
    print $ENV{FOO};       #  "baz"

    # on Perl <=v5.8.8, say "Env::Modify::readpipe" instead
    $out = qx(BAR=123; export BAR; echo hello);
    print $ENV{BAR};       #  "123"
    print $out;            #  "hello";

    ###

    use Env::Modify 'source', ':bash', ':chdir';
    open ENV, '>my_env.sh';
    print ENV "export MEANING_OF_LIFE=42\n";
    print ENV "cd \$HOME\n";
    print ENV "cd .cpan\n";
    close ENV;
    my $status = source("my_env.sh");
    print $ENV{MEANING_OF_LIFE};               # "42"
    print "Current dir: ",Cwd::getcwd(),"\n";  # "/home/mob/.cpan"


=head1 DESCRIPTION

New Perl programmers are often confused about how the C<system> call
interacts with the environment, and they wonder why this code:

    system('export foo=bar');
    system('echo $foo');

behaves differently from

    system('export foo=bar; echo $foo');

or why when they run this code

    system("chdir \$HOME/scripts");
    system("source my.env");
    system("./my_script.sh");

all the environment variables that they carefully set in C<my.env> 
are ignored by C<./my_script.sh>.

The reason these codes do not meet the new user's expectations
is that subshells, such as those launched by C<system>, receive
their own copy of the operating system environment and can only
make changes to that local environment.

This module seeks to overcome that limitation, allowing 
C<system> calls (and C<qx()>/C<readpipe>/backticks) calls
to affect the local environment. It uses the clever mechanism
in Diab Jerius's L<Shell::GetEnv|Shell::GetEnv> module to copy
the environment of the subshell back to the calling environment.

=head1 FUNCTIONS

=head2 system

=head2 EXIT_CODE = system LIST

Acts like the builtin L<perlfunc/"system"> command,
but any changes made to the subshell environment are preserved
and copied to the calling environment.

Like the builtin call, the return value is the exit status of
the command as returned by the L<perlfunc/"wait"> call.

When you import the C<system> command into your calling
package (with C<use Env::Modify ':system'>),
 C<Env::Modify> installs the C<Env::Modify::system>
function to the C<CORE::GLOBAL> namespace (see
L<perlsub/"Overriding Build-in Functions">), making it
available anywhere that your program makes a call to C<system>.

=head2 readpipe

=head2 readpipe(EXPR)

=head2 Env::Modify::qx(EXPR), &qx(EXPR)

=head2 backticks(EXPR)

Executes a system command and returns the standard output of
the command. In scalar context, the output comes back as a single
(potentially multi-line) string. In list context, returns a list
of lines (however lines are defined with L<perlvar/"$/"> or
L<perlvar/"$INPUT_RECORD_SEPARATOR">).

Unlike the builtin C<readpipe> command, any changes made by the
system command to the subshell environment are preserved and
copied back to the calling environment.

When any of the functions C<readpipe>, C<qx>, or C<backticks>
or any of the tags C<:readpipe>, C<:qx>, C<:backticks>, or
C<:all> are imported into the calling namespace, 
this module installs the C<Env::Modify::readpipe> function to
the C<CORE::GLOBAL> namespace. As described in
L<perlsub/"Overriding Built-in Functions">, an override
for the C<readpipe> function also overrides the operators
C<``> and C<qx{}>. Note that C<readpipe> was not supported
as an overridable function for the C<CORE::GLOBAL> package
until Perl v5.8.9. If your version of perl is older than that,
you will need to use function names and not C<qx[]> or
backticks notation to get this module to modify your
environment.

See the L<"RT115330"> section for another important caveat
about the C<readpipe> set of functions, and how to structure
your C<use Env::Modify ...> statement to make best use of
this module.

=head2 readpipe_list LIST

=head2 backticks_list LIST

=head2 qx_list LIST

Convenience functions to accommodate external commands with
shell metacharacters. Like the L<"readpipe"> function, 
but may take a list of arguments the way that Perl's 
C<system LIST> function does. Compare:

    $output = readpipe("ls -l \"My Documents\" Videos*");
    $output = readpipe_list("ls","-l","My Documents","Videos*");

(See also:
L<https://metacpan.org/pod/distribution/perl/Porting/todo.pod#readpipe-LIST>.)

=head2 source FILE LIST

Like the shell built-in command of the same name (also called
C<.> in some shells), executes the shell
commands in a file and incorporates any modifications to the
subshell's environment into the calling environment.

That is, if C<my_env.sh> contains

    FOO=123
    NUM_HOME_FILES=$(ls $HOME | wc -l)
    export FOO NUM_HOME_FILES

then you could run

    use Env::Modify 'source';
    source("my_env.sh");
    print "FOO is $ENV{FOO}\n";  # expect: "123"
    print "There are $ENV{NUM_HOME_FILES} in the home dir\n";

=head1 RT115330

L<"perlbug RT#115330"|https://rt.perl.org/Ticket/Display.html?id=115330>
described an issue with Perl code that sets the C<*CORE::GLOBAL::readpipe>
function, like this module does.
This bug was fixed in Perl v5.20.0
and if you are not using an older version of Perl than that, you
are not affected by this bug and you may stop reading.

The short version is that the arguments received by the
C<CORE::GLOBAL::readpipe> function are correct when you
use the keyword C<readpipe> to call the function, and they
need to be interpolated an extra time when you use backticks
or the C<qx//> construction.

The form of the C<use> statement should resemble the way
that you I<usually> invoke the C<readpipe> command. If your
code literally calls the C<readpipe> function, then you 
should load this module with

    use Env::Modify ':readpipe';

If your code usually uses the C<qx!!> construct or backticks
to invoke C<readpipe>, then you should load the module with
either

    use Env::Modify ':qx';
    use Env::Modify ':backticks';

(these two calls are equivalent). This will have the effect
of interpolating the input one last time before the input
is passed to the shell.

If your code uses both C<readpipe> and C<qx{}>/backticks,
you can always workaround this bug using fully-qualified function
names like C<Env::Modify::readpipe()>,
C<Env::Modify::qx()>, or
C<Env::Modify::backticks()>. All of these function calls
will receive correctly interpolated input.

=head1 MODULE VARIABLES

=head2 $SHELL

The shell that the L<Shell::GetEnv> module will use to run
an external command. This must be a value supported by
L<Shell::GetEnv>, namely one of C<bash>, C<csh>, C<dash>,
C<ksh>, C<sh>, C<tcsh>, or C<zsh>. 
Defaults to C<sh>.

The value of C<$SHELL> can also be set by specifing a tag
with the shell name when this module is imported. For
example, to specify C<bash> as the shell for this module
to use, load this module like

    use Env::Modify ':bash';

=head2 $CHDIR

If C<$Env::Modify::CHDIR> is set to a true value, then any
change of the current working directory in a subshell will
also affect the working directory in the calling (Perl)
environment. That is, you can say

    chdir "/some/path";
    $f = -f "bar";   # -f  /some/path/bar
    system("cd foo");
    $g = -f "bar";   # -f  /some/path/foo/bar

You can also enable this feature at import time with the
C<:chdir> tag.

=head2 %CMDOPT

A set of options that are passed to the L<Shell::GetEnv> 
constructor. See the C<new> method in L<Shell::GetEnv/"METHODS">.

    # don't load startup files (.profile, .bashrc, etc.)
    # when system() runs below
    local $Env::Modify::CMDOPT{startup} = 0;
    Env::Modify::system("FOO=bar; export FOO");


=head2 %ENVSOPT

A set of options that are passed to the C<import_envs>
method of L<Shell::GetEnv>. See the C<import_envs> method
in L<Shell::GetEnv/"METHODS">.

    # don't remove entries from Perl environment
    local $Env::Modify::ENVSOPT{ZapDeleted} = 0;
    source("./script_that_erases_PATH_var.sh");
    print "PATH is still $ENV{PATH}";  # not erased

=head1 EXPORT

This module has four functions that can be exported into the
calling namespace: C<system>, C<readpipe>, C<qx>, and C<backticks>.
As C<qx> is a Perl language construction and not just a keyword,
if you import the C<qx> function you would either have to use
a fully qualified function name or a sigil to use it:

    package My::Pkg;
    use Env::Modify 'qx';
    ...
    $out1 = qx($cmd1);          # calls Perl built-in, not Env::Modify::qx !
    $out2 = &qx($cmd2);         # calls Env::Modify::qx
    $out3 = My::Pkg::qx($cmd3); # calls Env::Modify::qx

The tag C<:system> exports the C<system> function into the calling
namespace and also sets the C<CORE::GLOBAL::system> function, so that
all C<system> calls in any package in any part of your script will
use the C<Env::Modify::system> function.

The tags C<:readpipe>, C<:qx>, or C<:backticks> export the
C<readpipe>, C<qx>, and C<backticks> functions into the calling
namespace, and also set the C<CORE::GLOBAL::readpipe> function,
so that all C<readpipe> calls, C<qx//> constructions, or
backticks expressions in any package and in any part of your script
will use the C<Env::Modify::readpipe> function. If you are 
vulnerable to L<"RT115330"> (see above), then you should use
C<:readpipe> if your script generally uses C<readpipe()> to
capture output from external programs and use C<:qx> or C<:backticks>
if your script generally uses C<qx!!> or backticks.

The C<:all> tag behaves like C<:system> + C<:backticks>.

You may also specify the C<:chdir> tag to enable the "chdir"
feature (see C<$CHDIR> under L<"MODULE VARIABLES">), or a tag
with the name of a shell like C<:sh>, C<:bash>, etc.
to specify the default shell for this module to run external
commands (see C<$SHELL> under L<"MODULE VARIABLES">).

=head1 LIMITATIONS

=over 4

=item Portability

C<Env::Modify> can only work on systems where L<Shell::GetEnv>
will work, namely systems where POSIX-y type shells are
installed.

=item Buffering

With a regular C<system> or C<readpipe>/C<qx>/backticks call,
lines from the standard error stream of the external command
(and from the standard output stream in the case of C<system>)
are written to the terminal as the external program produces
them. Because of the nature of how this module recovers and
transfers the environment of the subshell, C<Env::Modify>
functions will hold onto external program output, and not
publish it to your Perl script's terminal until the command
has completed. This may cause
L<suffering from buffering|http://perl.plover.com/FAQs/Buffering.html>,
and for that, the author of this module apologizes.

=item Interlaced standard output and standard error

In a regular C<system> call that writes to both standard
output and standard error, lines from the output stream
and error stream will often be interleaved on your terminal.
Because of the nature of how this module recovers and
transfers the environment of the subshell, C<Env::Modify::system>
calls will not interleave error and output this way. All
of the standard error output, if any, will be written to
the terminal (file descriptor 2, which is usually but not
necessarily STDERR), followed by all standard output being
written to the terminal (file descriptor 1).

=back

=head1 DEPENDENCIES

L<Shell::GetEnv> provides the mechanism for copying a subshell's
environment back into the calling environment.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Env::Modify

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Env-Modify>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Env-Modify>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Env-Modify>

=item * Search CPAN

L<http://search.cpan.org/dist/Env-Modify/>

=back

=head1 AUTHOR

Marty O'Brien, C<< <mob at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2016, Marty O'Brien

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

See http://dev.perl.org/licenses/ for more information.

=cut

# TODO:  open2, open3  that modifies environment
#        test on openbsd, Cygwin, other systems

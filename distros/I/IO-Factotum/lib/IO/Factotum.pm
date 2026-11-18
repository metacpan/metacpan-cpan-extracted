package IO::Factotum;

use v5.16;
use warnings;

our $VERSION = "0.05";

use Carp;
use Scalar::Util ();
use IO::File;
use IO::Handle;
use File::Spec;
use POSIX ();
use Command::Run::Tmpfile;

my @converter;

sub register {
    my %arg = @_;
    my $match   = delete $arg{match};
    my $command = delete $arg{command};
    my $with    = delete $arg{with};
    croak "register: unknown parameter: @{[ sort keys %arg ]}" if %arg;
    if (defined $with) {
	# An object which gives the content of a file by its method
	# file.  It tells by itself which files are its own, so match
	# is not required.
	croak "register: with and command can not be given together"
	    if defined $command;
	Scalar::Util::blessed($with) && $with->can('file')
	    or croak "register: with must be an object which has the method file";
    } else {
	$match   // croak "register: match is required";
	$command // croak "register: command is required";
	ref $command eq 'ARRAY' && @$command
	    or croak "register: command must be an array reference";
    }
    !defined $match or ref $match eq 'Regexp' or ref $match eq 'CODE'
	or croak "register: match must be a regex or a code reference";
    push @converter, {
	match => $match,
	defined $with ? (with => $with) : (command => [ @$command ]),
    };
    return;
}

sub clear {
    @converter = ();
    return;
}

# The converters which take the file, in the order they were registered
sub converter {
    my $file = shift;
    grep {
	my $match = $_->{match};
	!defined $match or ref $match eq 'CODE' ? $match->($file) : $file =~ $match;
    } @converter;
}

sub open_input {
    my $file = shift;

    # The standard input is read as it is, by STDIN itself: another
    # handle on it would not see what STDIN has read ahead
    return *STDIN{IO} if $file eq '-';

    # The file is opened first: a file which can not be read is an
    # error of the caller with $! set, whatever the converter does
    my $fh = IO::File->new($file, '<') // return undef;
    binmode $fh, ':raw';

    for my $c (converter($file)) {
	if (my $with = $c->{with}) {
	    # an object which gives nothing passes the file to the next
	    my $converted = content($with, $file) // next;
	    return $converted;
	}
	# a command which fails leaves the file as it is
	return convert($c->{command}, $file) // $fh;
    }
    $fh;
}

# Ask the object for the content of the file, and return the handle of
# a temporary file which has it, or undef when the object gives
# nothing, or dies.  Characters are written as UTF-8.
sub content {
    my($with, $file) = @_;
    my $content = eval { $with->file($file) } // return undef;
    utf8::encode($content) if utf8::is_utf8($content);
    my $tmp = Command::Run::Tmpfile->new(raw => 1);
    my $fh = $tmp->fh;
    print $fh $content or return undef;
    $fh->flush;
    $fh->seek(0, 0) or return undef;
    $fh;
}

# Run the command with the file name, in a process of its own, and
# return the handle of a temporary file which has what it wrote to the
# standard output, or undef when it fails.  The output goes to the file
# as it is, byte for byte.  The standard error is thrown away.
sub convert {
    my($command, $file) = @_;
    my @command = (@$command, $file);
    my $tmp = Command::Run::Tmpfile->new(raw => 1);

    # $? and $! of the caller are kept, and the child is waited for
    # even when the caller ignores SIGCHLD
    local($?, $!);
    local $SIG{CHLD} = 'DEFAULT';
    # what is in the buffers is not to be written twice
    STDOUT->flush;
    STDERR->flush;

    my $pid = fork // return undef;
    if ($pid == 0) {
	# The child never returns to the program: it ends by _exit, so
	# that the END blocks and the destructors of the program do not
	# run here, even when open_input is called inside eval.
	my $status = eval {
	    open STDIN,  '<', File::Spec->devnull or die;
	    open STDOUT, '>&', $tmp->fh           or die;
	    open STDERR, '>', File::Spec->devnull or die;
	    binmode STDOUT, ':raw';
	    if (ref $command[0] eq 'CODE') {
		my $code = shift @command;
		$code->(@command);
		STDOUT->flush;
		0;
	    } else {
		# "or" keeps old perls from warning about a statement
		# after exec
		no warnings 'exec';
		exec { $command[0] } @command
		    or POSIX::_exit(127);
	    }
	} // 1;
	POSIX::_exit($status);
    }
    waitpid $pid, 0;
    return undef if $? != 0;

    my $converted = $tmp->fh;
    $converted->seek(0, 0) or return undef;
    $converted;
}

# Register the converters of IO::Factotum::NAME by their names
sub load {
    for my $name (@_) {
	$name =~ /\A\w+(?:::\w+)*\z/
	    or croak "IO::Factotum: $name: invalid converter name";
	my $module = __PACKAGE__ . "::$name";
	eval "require $module; 1"
	    or die "IO::Factotum: $name: no such converter\n$@";
	my $setup = $module->can('setup')
	    or die "IO::Factotum: $module has no setup function\n";
	$setup->();
    }
    return;
}

sub tie_argv {
    return if tied *ARGV;
    require IO::Factotum::ARGV;
    tie *ARGV, 'IO::Factotum::ARGV';
    return;
}

1;

__END__

=encoding utf-8

=head1 NAME

IO::Factotum - read files through a converter chosen by their names

=head1 SYNOPSIS

    use IO::Factotum;

    IO::Factotum::register(
        match   => qr/\.gz$/,
        command => [ 'gzip', '-dc' ],
    );

    my $fh = IO::Factotum::open_input($file) or die "$file: $!";
    while (<$fh>) {
        ...
    }

    # an object which gives the content of a file
    use Text::ANSI::Highlight;
    IO::Factotum::register(with => Text::ANSI::Highlight->new);

=head1 VERSION

Version 0.05

=head1 DESCRIPTION

A factotum is a person who does all kinds of work for someone.  This
module is one for the files a program reads: tell it what to do with
which files, and it gives them to the program ready to read.  A file
is opened through a converter chosen by its name, and the handle gives
the output of the converter instead of the content of the file.  The
file itself is not changed, and the program keeps its name.

Converters are registered with a condition on the file name.  A file
which no converter takes, and a file whose converter fails, is read
as it is.

=head1 FUNCTIONS

Nothing is exported.

=over 4

=item B<register>(B<match> => I<condition>, B<command> => I<command>)

Register a converter.  Converters are tried in the order they were
registered, and the first one that matches is used.

I<condition> is a regex which the file name is matched against, or a
code reference which is called with the file name and returns true
for the file to convert.

I<command> is an array reference in the form of L<Command::Run>: an
external command with its arguments, or a code reference with its
arguments.  The file name is added as the last argument, and what the
command writes to the standard output is the converted content, taken
byte for byte.  The command is not given to the shell.

    register(match => qr/\.gz$/, command => [ 'gzip', '-dc' ]);

    register(match   => sub { -B $_[0] },
             command => [ \&to_text, '--plain' ]);

The command runs in a process of its own, with the standard error
thrown away.  It fails by an exit status other than 0; a code
reference fails by C<die>.  A code reference prints bytes, and the
C<END> blocks of the program do not run in its process.

=item B<register>(B<with> => I<object>)

Register an object as a converter.  Its method C<file> is called with
the name of a file, and returns the content to be read in place of
the file, or C<undef> for a file it has nothing to do with: the file
then goes to the next converter, or is read as it is.  So does it
when the method dies.  The content is taken byte for byte, and
characters are written as UTF-8.

    use Text::ANSI::Highlight;
    register(with => Text::ANSI::Highlight->new);

The object tells by itself which files are its own, so C<match> is
not required; when it is given, the object is asked only for the
files which match.  The method is called in the process of the
program.

=item B<clear>()

Remove all the converters.

=item B<open_input>(I<file>)

Open the I<file> for reading and return the handle, an L<IO::File>
object.  When a converter matches the name and exits with status 0,
the handle reads its output, which is kept in a temporary file
without a name.  Otherwise the handle reads the file itself.

It returns C<undef> with C<$!> set when the file can not be opened.

The handle has the C<:raw> layer.  Set the encoding by C<binmode>:

    my $fh = IO::Factotum::open_input($file) or die "$file: $!";
    binmode $fh, ':encoding(utf8)';

The name C<-> is the standard input, which is not converted: the
handle is that of C<STDIN> itself, with the layers it has.

=item B<load>(I<name>, ...)

Register the converters of the modules C<IO::Factotum::>I<name>, by
calling their C<setup> function.  It dies when there is no such
module.

    IO::Factotum::load('Gunzip');     # IO::Factotum::Gunzip::setup()

=item B<tie_argv>()

Tie C<ARGV>, so that C<E<lt>E<gt>> reads the files of C<@ARGV> by
C<open_input>.  A program which reads by C<E<lt>E<gt>> gets the
converted content with no change in it:

    IO::Factotum::tie_argv();
    while (<>) {
        print "$ARGV: $_";
    }

C<@ARGV> is looked at when the first line is read, so the options can
be taken from it before.  As with the plain C<E<lt>E<gt>>, C<$ARGV>
is the name of the file, C<$.> counts the lines of all the files,
C<eof()> is true at the end of the last file, C<close ARGV> starts
the line numbers again, and the standard input is read when there is
no file.  C<E<lt>E<lt>E<gt>E<gt>> and the C<-i> option of perl are
not supported.

=back

=head1 CONVERTERS

A module C<IO::Factotum::I<NAME>> which has a function C<setup> is a
converter by the name: C<load('I<NAME>')> calls the function, which
registers what it has.  None comes with this module.

For syntax highlight, register an object of L<Text::ANSI::Highlight>:
it colors source files by a highlighter, and gives nothing for a file
whose language it does not know.

    IO::Factotum::register(with => Text::ANSI::Highlight->new('pandoc'));

=head1 SEE ALSO

L<Text::ANSI::Highlight>, L<Getopt::EX::Factotum>

L<Command::Run>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright © 2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

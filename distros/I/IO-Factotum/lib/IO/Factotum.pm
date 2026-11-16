package IO::Factotum;

use v5.16;
use warnings;

our $VERSION = "0.03";

use Carp;
use IO::File;
use IO::Handle;
use File::Spec;
use POSIX ();
use Command::Run::Tmpfile;

my @converter;

sub register {
    my %arg = @_;
    my $match   = delete $arg{match}   // croak "register: match is required";
    my $command = delete $arg{command} // croak "register: command is required";
    croak "register: unknown parameter: @{[ sort keys %arg ]}" if %arg;
    ref $match eq 'Regexp' or ref $match eq 'CODE'
	or croak "register: match must be a regex or a code reference";
    ref $command eq 'ARRAY' && @$command
	or croak "register: command must be an array reference";
    push @converter, { match => $match, command => [ @$command ] };
    return;
}

sub clear {
    @converter = ();
    return;
}

sub converter {
    my $file = shift;
    for my $c (@converter) {
	my $match = $c->{match};
	if (ref $match eq 'CODE' ? $match->($file) : $file =~ $match) {
	    return $c;
	}
    }
    undef;
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

    my $c = converter($file) // return $fh;
    # a converter which fails leaves the file as it is
    convert($c->{command}, $file) // $fh;
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

=head1 VERSION

Version 0.03

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

    IO::Factotum::load('skylighting');

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

=head1 SEE ALSO

L<IO::Factotum::skylighting>, L<IO::Factotum::sourcehighlight>,
L<Getopt::EX::Factotum>

L<Command::Run>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

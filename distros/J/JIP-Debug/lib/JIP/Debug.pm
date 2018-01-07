package JIP::Debug;

use base qw(Exporter);

use 5.006;
use strict;
use warnings;
use Term::ANSIColor 3.00 ();
use Devel::StackTrace;
use Carp qw(croak);
use Data::Dumper qw(Dumper);
use Fcntl qw(LOCK_EX LOCK_UN);
use English qw(-no_match_vars);

our $VERSION = '0.021';

our @EXPORT_OK = qw(
    to_debug
    to_debug_raw
    to_debug_empty
    to_debug_count
    to_debug_trace
);

our $HANDLE = \*STDERR;

our $MSG_FORMAT      = qq{%s\n%s\n\n};
our $MSG_DELIMITER   = q{-} x 80;
our $MSG_EMPTY_LINES = qq{\n} x 18;

our $DUMPER_INDENT   = 1;
our $DUMPER_DEEPCOPY = 1;
our $DUMPER_SORTKEYS = 1;

our %TRACE_PARAMS = (
    skip_frames => 1, # skip to_debug_trace
);
our %TRACE_AS_STRING_PARAMS;

our $COLOR = 'bright_green';

our $MAYBE_COLORED = sub {
    my $text = shift;

    return defined $text && defined $COLOR
        ? Term::ANSIColor::colored($text, $COLOR) : $text;
};

our $MAKE_MSG_HEADER = sub {
    # $MAKE_MSG_HEADER=0, to_debug=1
    my ($package, undef, $line) = caller 1;

    # $MAKE_MSG_HEADER=0, to_debug=1, subroutine=2
    my $subroutine = (caller 2)[3];

    $subroutine = resolve_subroutine_name($subroutine);

    my $text = join q{, }, (
        sprintf('package=%s', $package),
        (defined $subroutine ? sprintf('subroutine=%s', $subroutine) : ()),
        sprintf('line=%d', $line),
    );
    $text = qq{[$text]:};

    {
        my $msg_delimiter = defined $MSG_DELIMITER ? $MSG_DELIMITER : q{};
        $text = sprintf qq{%s\n%s\n%s}, $msg_delimiter, $text, $msg_delimiter;
    }

    return $MAYBE_COLORED->($text);
};

our $NO_LABEL_KEY   = '<no label>';
our %COUNT_OF_LABEL = ($NO_LABEL_KEY => 0);

# Supported on Perl 5.22+
eval {
    require Sub::Util;

    if (my $set_subname = Sub::Util->can('set_subname')) {
        $set_subname->('MAYBE_COLORED',   $MAYBE_COLORED);
        $set_subname->('MAKE_MSG_HEADER', $MAKE_MSG_HEADER);
    }
};

sub to_debug {
    my $msg_body = do {
        local $Data::Dumper::Indent   = $DUMPER_INDENT;
        local $Data::Dumper::Deepcopy = $DUMPER_DEEPCOPY;
        local $Data::Dumper::Sortkeys = $DUMPER_SORTKEYS;

        Dumper(\@ARG);
    };

    my $msg = sprintf $MSG_FORMAT, $MAKE_MSG_HEADER->(), $msg_body;

    return send_to_output($msg);
}

sub to_debug_raw {
    my $msg_text = shift;

    my $msg = sprintf $MSG_FORMAT, $MAKE_MSG_HEADER->(), $msg_text;

    return send_to_output($msg);
}

sub to_debug_empty {
    my $msg = sprintf $MSG_FORMAT, $MAKE_MSG_HEADER->(), $MSG_EMPTY_LINES;

    return send_to_output($msg);
}

sub to_debug_count {
    my ($label, $cb);
    if (@ARG == 2 && ref $ARG[1] eq 'CODE') {
        ($label, $cb) = @ARG;
    }
    elsif (@ARG == 1 && ref $ARG[0] eq 'CODE') {
        $cb = $ARG[0];
    }
    elsif (@ARG == 1) {
        $label = $ARG[0];
    }

    $label = defined $label && length $label ? $label : $NO_LABEL_KEY;

    my $count = $COUNT_OF_LABEL{$label} || 0;
    $count++;
    $COUNT_OF_LABEL{$label} = $count;

    my $msg_body = sprintf '%s: %d', $label, $count;

    my $msg = sprintf $MSG_FORMAT, $MAKE_MSG_HEADER->(), $msg_body;

    $cb->($label, $count) if defined $cb;

    return send_to_output($msg);
}

sub to_debug_trace {
    my $cb = shift;

    my $trace = Devel::StackTrace->new(%TRACE_PARAMS);

    my $msg_body = $trace->as_string(%TRACE_AS_STRING_PARAMS);
    $msg_body =~ s{\n+$}{}x;

    my $msg = sprintf $MSG_FORMAT, $MAKE_MSG_HEADER->(), $msg_body;

    $cb->($trace) if defined $cb;

    return send_to_output($msg);
}

sub send_to_output {
    my $msg = shift;

    return unless $HANDLE;

    flock $HANDLE, LOCK_EX;
    $HANDLE->print($msg) or croak(sprintf q{Can't write to output: %s}, $OS_ERROR);
    flock $HANDLE, LOCK_UN;

    return 1;
}

sub resolve_subroutine_name {
    my $subroutine = shift;

    return unless defined $subroutine;

    my ($subroutine_name) = $subroutine =~ m{::(\w+)$}x;

    return $subroutine_name;
}

1;

__END__

=head1 NAME

JIP::Debug - provides a convenient way to attach debug print statements anywhere in a program.

=head1 VERSION

This document describes C<JIP::Debug> version C<0.021>.

=head1 SYNOPSIS

For complex data structures (references, arrays and hashes) you can use the

    use JIP::Debug qw(to_debug);

    to_debug(
        an_array    => [],
        a_hash      => {},
        a_reference => \42,
    );

C<to_debug({a =E<gt> 1, b =E<gt> 1})> will produce the output:

    --------------------------------------------------------------------------------
    [package=main, subroutine=tratata, line=1]:
    --------------------------------------------------------------------------------
    $VAR1 = [
      {
        'a' => 1,
        'b' => 1
      }
    ];

Prints a string

    use JIP::Debug qw(to_debug_raw);

    to_debug_raw('Hello');

C<to_debug_raw('Hello')> will produce the output:

    --------------------------------------------------------------------------------
    [package=main, subroutine=tratata, line=1]:
    --------------------------------------------------------------------------------
    Hello

Prints empty lines

    use JIP::Debug qw(to_debug_empty);

    to_debug_empty();

Prints the number of times that this particular call to to_debug_count() has been called

    use JIP::Debug qw(to_debug_count);

    to_debug_count('tratata label');

C<to_debug_count('tratata label')> will produce the output:

    --------------------------------------------------------------------------------
    [package=main, subroutine=tratata, line=1]:
    --------------------------------------------------------------------------------
    tratata label: 1

Prints a stack trace

    use JIP::Debug qw(to_debug_trace);

    to_debug_trace();

C<to_debug_trace()> will produce the output:

    --------------------------------------------------------------------------------
    [package=main, subroutine=tratata, line=1]:
    --------------------------------------------------------------------------------
    Trace begun at -e line 1
    main::tratata at -e line 1

=head1 DESCRIPTION

Each debug message is added a header with useful data during debugging, such as a C<package> (package name), a C<subroutine> (function name/method), a C<line> (line number).

All debug messages are output via a file descriptor. Default is C<STDERR>. Value can be changed by editing the variable C<$JIP::Debug::HANDLE>.

The list of exporting functions by default is empty, all functions of this module are exported explicitly.

=head1 SUBROUTINES/METHODS

=head2 to_debug(I<LIST>)

A wrapper for C<Dumper> method of the C<Data::Dumper> module. The list of parameters passed to C<to_debug>, without any changes, is passed to C<Dumper>.

Parameters for C<Data::Dumper> can be changed, here are their analogues (and default values) in this module:

=over 4

=item *

$JIP::Debug::DUMPER_INDENT = 1 I<or> $Data::Dumper::Indent = 1

Mild pretty print.

=item *

$JIP::Debug::DUMPER_DEEPCOPY = 1 I<or> $Data::Dumper::Deepcopy = 1

Avoid cross-refs.

=item *

$JIP::Debug::DUMPER_SORTKEYS = 1 I<or> $Data::Dumper::Sortkeys = 1

Hash keys are dumped in sorted order.

=back

=head2 to_debug_raw(I<[STRING]>)

Logs a string without any changes.

=head2 to_debug_empty()

Logs 18 empty lines. The content can be changed, there is a parameter for this C<$JIP::Debug::MSG_EMPTY_LINES>.

=head2 to_debug_count(I<[LABEL, CODE]>)

Logs the number of times that this particular call to C<to_debug_count()> has been called.

This function takes an optional argument C<label>. If C<label> is supplied, this function
logs the number of times C<to_debug_count()> has been called with that particular C<label>.

C<label> - a string. If this is supplied, C<to_debug_count()> outputs the number of times
it has been called at this line and with that label.

    to_debug_count('label');

If C<label> is omitted, the function logs the number of times C<to_debug_count()> has been
called at this particular line.

    to_debug_count();

This function takes an optional argument C<callback>:

    to_debug_count('label', sub {
        my ($label, $count) = @_;
    });

or

    to_debug_count(sub {
        my ($label, $count) = @_;
    });

=head2 to_debug_trace(I<[CODE]>)

Logs a stack trace from the point where the method was called.

This function takes an optional argument C<callback>:

    to_debug_trace(sub {
        my ($trace) = @_;
    });

=head1 CODE SNIPPET

    use JIP::Debug qw(to_debug to_debug_raw to_debug_empty to_debug_count to_debug_trace);
    BEGIN { $JIP::Debug::HANDLE = IO::File->new('/home/my_dir/debug.log', '>>'); }

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

C<JIP::Debug> requires no configuration files or environment variables.

=head1 SEE ALSO

L<Debuggit>, L<Debug::Simple>, L<Debug::Easy>

=head1 AUTHOR

Vladimir Zhavoronkov, C<< <flyweight at yandex.ru> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Vladimir Zhavoronkov.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut



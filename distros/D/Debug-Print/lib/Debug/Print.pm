package Debug::Print;

our $DATE = '2019-09-17'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

our $caller_depth_offset = 4;

our $time_start = time();
our $time_now   = $time_start;
our $time_last  = $time_start;

my @per_message_data;

our %format_for = (
    'd' => sub {
        my @t = localtime($time_now);
        sprintf(
            "%04d-%02d-%02dT%02d:%02d:%02d",
            $t[5]+1900, $t[4]+1, $t[3],
            $t[2], $t[1], $t[0],
        );
    },
    'D' => sub {
        my @t = gmtime($time_now);
        sprintf(
            "%04d-%02d-%02dT%02d:%02d:%02d",
            $t[5]+1900, $t[4]+1, $t[3],
            $t[2], $t[1], $t[0],
        );
    },
    'F' => sub {
        $per_message_data[0] //= [caller($caller_depth_offset)];
        $per_message_data[1] //= [caller($caller_depth_offset-1)];
        $per_message_data[0][1] // $per_message_data[1][1];
    },
    'H' => sub {
        require Sys::Hostname;
        Sys::Hostname::hostname();
    },
    'l' => sub {
        $per_message_data[0] ||= [caller($caller_depth_offset)];
        $per_message_data[1] ||= [caller($caller_depth_offset-1)];
        sprintf(
            "%s (%s:%d)",
            $per_message_data[0][3] // $per_message_data[1][3],
            $per_message_data[1][1],
            $per_message_data[1][2],
        );
    },
    'L' => sub {
        $per_message_data[1] ||= [caller($caller_depth_offset-1)];
        $per_message_data[1][2];
    },
    'm' => sub { $_[0] },
    'M' => sub {
        $per_message_data[0] ||= [caller($caller_depth_offset)];
        $per_message_data[1] ||= [caller($caller_depth_offset-1)];
        my $sub = $per_message_data[0][3] // $per_message_data[1][3];
        $sub =~ s/.+:://;
        $sub;
    },
    'n' => sub { "\n" },
    'p' => sub { $_[3] },
    'P' => sub { $$ },
    'r' => sub { sprintf("%.3f", $time_now - $time_start) },
    'R' => sub { sprintf("%.3f", $time_now - $time_last ) },
    'T' => sub {
        $per_message_data[2] //= do {
            my @st;
            my $i = $caller_depth_offset-1;
            while (my @c = caller($i++)) {
                push @st, \@c;
            }
            \@st;
        };
        my $st = '';
        for my $frame (@{ $per_message_data[2] }) {
            $st .= "$frame->[3] ($frame->[1]:$frame->[2])\n";
        }
        $st;
    },
    '%' => sub { '%' },
);

sub import {
    my $class = shift;
    my %args = @_;

    my $filter   = defined $args{filter} ?
        eval "sub { ".delete($args{filter})." }" : undef;
    my $template = delete($args{template}) || '%m';
    my $color    = delete $args{color};
    die "Unknown import argument(s) to Debug::Print: ".join(", ", keys %args)
        if keys %args;

    my $do_color = do {
        if (!defined $color) {
            0;
        } elsif (exists $ENV{NO_COLOR}) {
            0;
        } elsif (defined $ENV{COLOR}) {
            $ENV{COLOR};
        } else {
            -t STDOUT;
        }
    };

    require Tie::STDOUT;
    Tie::STDOUT->import(
        print => sub {
            my $msg = join "", @_;
            return if $filter && !do { local $_ = $msg; $filter->($msg) };
            ($time_last, $time_now) = ($time_now, time());
            @per_message_data = ();
            my $fmsg = $template;
            $fmsg =~ s/%(.)/
                exists $format_for{$1} ? $format_for{$1}->($msg) :
                die("Unknown conversion '%$1'")/eg;
            if ($do_color) {
                require Term::ANSIColor;
                print Term::ANSIColor::colored([$color], $fmsg);
            } else {
                print $fmsg;
            }
        },
        # XXX printf => ...
        # XXX syswrite => ...
    );
}

1;
# ABSTRACT: Make debugging with print() more awesome

__END__

=pod

=encoding UTF-8

=head1 NAME

Debug::Print - Make debugging with print() more awesome

=head1 VERSION

This document describes version 0.003 of Debug::Print (from Perl distribution Debug-Print), released on 2019-09-17.

=head1 SYNOPSIS

Example script F<myscript.pl>:

 #!/usr/bin/env perl

 sub f1 {
     print "Doing stuffs in f1\n";
     for (1..2) { f2(); sleep 1 }
 }

 sub f2 {
     print "DEBUG: Doing sumtin' in f2\n";
 }

 f1;

=head2 Add more information to your print()

On the command-line:

 % perl -MDebug::Print=template,'%d (%F:%L)> %m' myscript.pl

Sample output:

 2018-12-20T20:55:00 (script.pl:4)> Doing stuffs in f1
 2018-12-20T20:55:00 (script.pl:9)> DEBUG: Doing sumtin' in f2
 2018-12-20T20:56:00 (script.pl:9)> DEBUG: Doing sumtin' in f2

=head2 Add color

 % perl -MDebug::Print=template,'%d (%F:%L)> %m',color,green myscript.pl

=head2 Filter

Only show messages that start with "DEBUG:"

 % perl -MDebug::Print=template,'%d (%F:%L)> %m',filter,'/\ADEBUG:/' myscript.pl

Sample output:

 2018-12-20T20:55:00 (script.pl:9)> DEBUG: Doing sumtin' in f2
 2018-12-20T20:56:00 (script.pl:9)> DEBUG: Doing sumtin' in f2

Don't show messages that start with "DEBUG:"

 % perl -MDebug::Print=template,'%d (%F:%L)> %m',filter,'!/\ADEBUG:/' myscript.pl

Sample output:

 2018-12-20T20:55:00 (script.pl:4)> Doing stuffs in f1

=head1 DESCRIPTION

One of the simplest (and oldest) debugging technique is adding C<print>
statements to your code. Although not very flexible, it forever remains as one
of programmers' favorites.

This module allows you to:

=over

=item * Add more information to your print()

For example: filename and line, timestamp.

=item * Add color

=item * Filtering

For example: don't output if string matches qr/\ADEBUG:/.

=back

so debugging using C<print()> can be more useful. (Although I still recommend
you to use a proper logging framework.)

This module works by intercepting output to STDOUT using L<Tie::STDOUT>, then
filter and/or post-process the output.

Caveat: This module is still in its early development. API might change. Current
limitations:

=over

=item * Only print() to STDOUT is captured

Output to STDERR or other filehandles are currently not captured.

C<printf()> is currently not captured.

=back

=head1 IMPORTS

Usage:

 use Debug::Print %opts;

The following are known import options:

=head2 template

A C<sprintf()>-like layout string to print the L<print()> arguments itself as
well as additional information. The following are the known conversions (which
are modelled after L<Log::ger::Layout::Pattern>):

 %C Fully qualified package (or class) name of the caller
 %d Current date in ISO8601 format (YYYY-MM-DD<T>hh:mm:ss) (localtime)
 %D Current date in ISO8601 format (YYYY-MM-DD<T>hh:mm:ss) (GMT)
 %F File where the print occurred
 %H Hostname (if Sys::Hostname is available)
 %l Fully qualified name of the calling method followed by the
    callers source the file name and line number between
    parentheses.
 %L Line number within the file where the print statement was issued
 %m The message to be printed (the actual print() arguments, joined)
 %M Method or function where the print was issued
 %n Newline (OS-independent)
 %P pid of the current process
 %r Number of seconds elapsed from program start to logging event
 %R Number of seconds elapsed from last logging event to current
    logging event
 %T A stack trace of functions called
 %% A literal percent (%) sign

If unspecified, the default template is C<"%m"> (just the print() arguments,
without additional information).

=head2 color

A color name recognized by L<Term::ANSIColor>.

=head2 filter

A coderef that will be passed the string to be printed. Should return true if
this message should be printed, or false otherwise. As a convenience, the topic
variable (C<$_>) is also locally set to the string to be printed.

=head1 ENVIRONMENT

=head2 NO_COLOR

Force disabling color. Will be consulted before L</COLOR>. See
L<https://no-color.org>.

=head2 COLOR

Force enabling/disabling color. If unset, will enable color when output is
interactive, disable otherwise.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Debug-Print>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Debug-Print>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Debug-Print>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Consider using logging framework instead. Some logging frameworks I recommend:
L<Log::ger>, L<Log::Any>. To switch from C<print> to doing logging, you
typically just need to add an extra C<use> statement and replace your C<print()>
with C<log_debug()> or some other routine. After that, you will get: easy
turning on/off of logging by level, customizable output, and more. No need to
modify your source code every time!

L<Devel::Confess> can add call stack information to your C<warn()>'s and
C<die()>'s.

L<Capture::Tiny> can capture the output of stdout and/or stderr, as is
L<Tie::STDOUT> (which Debug::Print uses) or some other modules like
L<Tie::STDERR> or L<IO::Capture::Stdout>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

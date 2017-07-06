package Log::ger::Layout::Pattern;

our $DATE = '2017-06-28'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Log::ger ();
use Time::HiRes qw(time);

our $caller_depth_offset = 4;

our $time_start = time();
our $time_now   = $time_start;
our $time_last  = $time_start;

my @per_message_data;

our %format_for = (
    'c' => sub { $_[1]{category} },
    'C' => sub {
        $per_message_data[0] //= [caller($Log::ger::Caller_Depth_Offset+$caller_depth_offset)];
        $per_message_data[1] //= [caller($Log::ger::Caller_Depth_Offset+$caller_depth_offset-1)];
        $per_message_data[0][0] // $per_message_data[1][0];
    },
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
        $per_message_data[0] //= [caller($Log::ger::Caller_Depth_Offset+$caller_depth_offset)];
        $per_message_data[1] //= [caller($Log::ger::Caller_Depth_Offset+$caller_depth_offset-1)];
        $per_message_data[0][1] // $per_message_data[1][1];
    },
    'H' => sub {
        require Sys::Hostname;
        Sys::Hostname::hostname();
    },
    'l' => sub {
        $per_message_data[0] ||= [caller($Log::ger::Caller_Depth_Offset+$caller_depth_offset)];
        $per_message_data[1] ||= [caller($Log::ger::Caller_Depth_Offset+$caller_depth_offset-1)];
        sprintf(
            "%s (%s:%d)",
            $per_message_data[0][3] // $per_message_data[1][3],
            $per_message_data[1][1],
            $per_message_data[1][2],
        );
    },
    'L' => sub {
        #$per_message_data[0] ||= [caller($Log::ger::Caller_Depth_Offset+$caller_depth_offset)];
        $per_message_data[1] ||= [caller($Log::ger::Caller_Depth_Offset+$caller_depth_offset-1)];
        $per_message_data[1][2];
    },
    'm' => sub { $_[0] },
    'M' => sub {
        $per_message_data[0] ||= [caller($Log::ger::Caller_Depth_Offset+$caller_depth_offset)];
        $per_message_data[1] ||= [caller($Log::ger::Caller_Depth_Offset+$caller_depth_offset-1)];
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
            my $i = $Log::ger::Caller_Depth_Offset+$caller_depth_offset-1;
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
    # test
    #'z' => sub { use DD; my $i = 0; while (my @c = caller($i++)) { dd \@c } },
    '%' => sub { '%' },
);

sub _layout {
    my $format = shift;
    #my ($msg, $init_args, $lnum, $level) = @_;

    ($time_last, $time_now) = ($time_now, time());
    @per_message_data = ();

    $format =~ s/%(.)/
        exists $format_for{$1} ? $format_for{$1}->(@_) :
        die("Unknown format '%$1'")/eg;
    $format;
}

sub get_hooks {
    my %conf = @_;

    $conf{format} or die "Please specify format";

    return {
        create_layouter => [
            __PACKAGE__, 50,
            sub {
                [sub { _layout($conf{format}, @_) }];
            }],
    };
}

1;
# ABSTRACT: Pattern layout

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Layout::Pattern - Pattern layout

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 use Log::ger::Layout 'Pattern', format => '%d (%F:%L)> %m';
 use Log::ger;

=head1 DESCRIPTION

Known placeholder in format string:

 %c Category of the logging event
 %C Fully qualified package (or class) name of the caller
 %d Current date in ISO8601 format (YYYY-MM-DD<T>hh:mm:ss) (localtime)
 %D Current date in ISO8601 format (YYYY-MM-DD<T>hh:mm:ss) (GMT)
 %F File where the logging event occurred
 %H Hostname (if Sys::Hostname is available)
 %l Fully qualified name of the calling method followed by the
    callers source the file name and line number between
    parentheses.
 %L Line number within the file where the log statement was issued
 %m The message to be logged
 %M Method or function where the logging request was issued
 %n Newline (OS-independent)
 %p Level ("priority")of the logging event
 %P pid of the current process
 %r Number of seconds elapsed from program start to logging event
 %R Number of seconds elapsed from last logging event to current
    logging event
           %T A stack trace of functions called
 %% A literal percent (%) sign

=for Pod::Coverage ^(.+)$

=head1 SEE ALSO

L<Log::ger>

Modelled after <Log::Log4perl::Layout::Pattern> but note that full compatibility
or feature parity is not a goal. See also L<Log::Log4perl::Tiny>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Log::ger::Layout::Pattern;

our $DATE = '2019-04-12'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

use Devel::Caller::Util;
use Log::ger ();
use Time::HiRes qw(time);

our $time_start = time();
our $time_now   = $time_start;
our $time_last  = $time_start;

my %per_message_data;

our %format_for = (
    'c' => sub { $_[1]{category} },
    'C' => sub { $per_message_data{caller0}[0] },
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
    'F' => sub { $per_message_data{caller0}[1] },
    'H' => sub {
        require Sys::Hostname;
        Sys::Hostname::hostname();
    },
    'l' => sub {
        sprintf(
            "%s (%s:%d)",
            $per_message_data{caller1}[3] // '',
            $per_message_data{caller0}[1],
            $per_message_data{caller0}[2],
        );
    },
    'L' => sub { $per_message_data{caller0}[2] },
    'm' => sub { $_[0] },
    'M' => sub {
        $per_message_data{caller1}[3] // '';
    },
    'n' => sub { "\n" },
    'p' => sub { $_[3] },
    'P' => sub { $$ },
    'r' => sub { sprintf("%.3f", $time_now - $time_start) },
    'R' => sub { sprintf("%.3f", $time_now - $time_last ) },
    'T' => sub {
        join(", ", map { "$_->[3] called at $_->[1] line $_->[2]" }
                 @{ $per_message_data{callers} });
    },
    # test
    #'z' => sub { use DD; my $i = 0; while (my @c = caller($i++)) { dd \@c } },
    '%' => sub { '%' },
);

sub _layout {
    my $format = shift;
    my $packages_to_ignore = shift;
    my $subroutines_to_ignore = shift;

    ($time_last, $time_now) = ($time_now, time());
    %per_message_data = ();

    my %mentioned_formats;
    while ($format =~ m/%(.)/g) {
        if (exists $format_for{$1}) {
            $mentioned_formats{$1} = 1;
        } else {
            die "Unknown format '%$1'";
        }
    }

    if ($mentioned_formats{C} ||
            $mentioned_formats{F} ||
            $mentioned_formats{L} ||
            $mentioned_formats{l}
        ) {
        $per_message_data{caller0}  =
            [Devel::Caller::Util::caller (0, 0, $packages_to_ignore, $subroutines_to_ignore)];
    }
    if ($mentioned_formats{l} ||
            $mentioned_formats{M}
        ) {
        $per_message_data{caller1}  =
            [Devel::Caller::Util::caller (1, 0, $packages_to_ignore, $subroutines_to_ignore)];
    }
    if ($mentioned_formats{T}) {
        $per_message_data{callers} =
            [Devel::Caller::Util::callers(0, 0, $packages_to_ignore, $subroutines_to_ignore)];
    }

    $format =~ s#%(.)#$format_for{$1}->(@_)#eg;
    $format;
}

sub get_hooks {
    my %conf = @_;

    $conf{format} or die "Please specify format";
    $conf{packages_to_ignore} //= [
        "Log::ger",
        "Log::ger::Layout::Pattern",
        "Try::Tiny",
    ];

    return {
        create_layouter => [
            __PACKAGE__, 50,
            sub {
                [sub { _layout($conf{format}, $conf{packages_to_ignore}, $conf{subroutines_to_ignore}, @_) }];
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

version 0.003

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

=head1 CONFIGURATION

=head2 format

=head2 packages_to_ignore

Regex or arrayref. When producing caller or stack trace information, will pass
this to L<Devel::Caller::Util>'s C<caller()> or C<callers()>.

=head2 subroutines_to_ignore

Regex or arrayref. When producing caller or stack trace information, will pass
this to L<Devel::Caller::Util>'s C<caller()> or C<callers()>.

=head1 SEE ALSO

L<Log::ger::Layout::Pattern::Multiline>

Modelled after L<Log::Log4perl::Layout::Pattern> but note that full
compatibility or feature parity is not a goal. See also L<Log::Log4perl::Tiny>.

L<Log::ger>

L<Log::ger::Layout::LTSV>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

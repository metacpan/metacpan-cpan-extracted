package Log::ger::Layout::LTSV;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-07'; # DATE
our $DIST = 'Log-ger-Layout-LTSV'; # DIST
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;

use Devel::Caller::Util;
use Log::ger ();
use Time::HiRes qw(time);

our $time_start = time();
our $time_now   = $time_start;
our $time_last  = $time_start;

sub _encode {
    my ($pkg, $msg) = @_;

    my @res;
    for my $l (sort keys %$msg) {
        my $val = $msg->{$l};
        $l =~ s/[:\t\n]+/ /g;
        $val =~ s/[\t\n]+/ /g;
        push @res, "$l:$val";
    }
    join("\t", @res);
}

sub _layout {
    my $pkg = shift;
    my ($plugin_conf, $msg0, $per_target_conf, $lnum, $level) = @_;

    ($time_last, $time_now) = ($time_now, time());
    my %per_message_data;

    my $msg;
    if (ref $msg0 eq 'HASH') {
        $msg = {%$msg0};
    } else {
        $msg = {message => $msg0};
    }

    if ($plugin_conf->{delete_fields}) {
        for my $f (@{ $plugin_conf->{delete_fields} }) {
            if (ref $f eq 'Regexp') {
                for my $k (keys %$msg) {
                    delete $msg->{$k} if $k =~ $f;
                }
            } else {
                delete $msg->{$f};
            }
        }
    }

    if (my $ff = $plugin_conf->{add_fields}) {
        for my $f (keys %$ff) {
            $msg->{$f} = $ff->{$f};
        }
    }

    if (my $ff = $plugin_conf->{add_special_fields}) {
        my %mentioned_specials;
        for my $f (keys %$ff) {
            $mentioned_specials{ $ff->{$f} }++;
        }

        if (
            $mentioned_specials{Class} ||
                $mentioned_specials{File} ||
                $mentioned_specials{Line} ||
                $mentioned_specials{Location}
            ) {
            $per_message_data{caller0} =
                [Devel::Caller::Util::caller (0, 0, $plugin_conf->{packages_to_ignore}, $plugin_conf->{subroutines_to_ignore})];
        }
        if (
            $mentioned_specials{Location} ||
                $mentioned_specials{Method}
            ) {
            $per_message_data{caller1} =
                [Devel::Caller::Util::caller (1, 0, $plugin_conf->{packages_to_ignore}, $plugin_conf->{subroutines_to_ignore})];
        }
        if ($mentioned_specials{Stack_Trace}) {
            $per_message_data{callers} =
                [Devel::Caller::Util::callers(0, 0, $plugin_conf->{packages_to_ignore}, $plugin_conf->{subroutines_to_ignore})];
        }

        for my $f (keys %$ff) {
            my $sf = $ff->{$f};
            my $val;
            if ($sf eq 'Category') {
                $val = $per_target_conf->{category};
            } elsif ($sf eq 'Class') {
                $val = $per_message_data{caller0}[0];
            } elsif ($sf eq 'Date_Local') {
                my @t = localtime($time_now);
                $val = sprintf(
                    "%04d-%02d-%02dT%02d:%02d:%02d",
                    $t[5]+1900, $t[4]+1, $t[3],
                    $t[2], $t[1], $t[0],
                );
            } elsif ($sf eq 'Date_GMT') {
                my @t = gmtime($time_now);
                $val = sprintf(
                    "%04d-%02d-%02dT%02d:%02d:%02d",
                    $t[5]+1900, $t[4]+1, $t[3],
                    $t[2], $t[1], $t[0],
                );
            } elsif ($sf eq 'File') {
                $val = $per_message_data{caller0}[1];
            } elsif ($sf eq 'Hostname') {
                require Sys::Hostname;
                $val = Sys::Hostname::hostname();
            } elsif ($sf eq 'Location') {
                $val = sprintf(
                    "%s (%s:%d)",
                    $per_message_data{caller1}[3] // '',
                    $per_message_data{caller0}[1],
                    $per_message_data{caller0}[2],
                );
            } elsif ($sf eq 'Line') {
                $val = $per_message_data{caller0}[2];
            } elsif ($sf eq 'Message') {
                $val = $msg0;
            } elsif ($sf eq 'Method') {
                $val = $per_message_data{caller1}[3] // '';
            } elsif ($sf eq 'Level') {
                $val = $level;
            } elsif ($sf eq 'PID') {
                $val = $$;
            } elsif ($sf eq 'Elapsed_Start') {
                $val = $time_now - $time_start;
            } elsif ($sf eq 'Elapsed_Last') {
                $val = $time_now - $time_last;
            } elsif ($sf eq 'Stack_Trace') {
                $val = join(", ", map { "$_->[3] called at $_->[1] line $_->[2]" }
                                @{ $per_message_data{callers} });
            } else { die "Unknown special field '$f'" }
            $msg->{$f} = $val;
        }
    }
    $pkg->_encode($msg);
}

sub _get_hooks {
    my $pkg = shift;
    my %plugin_conf = @_;

    $plugin_conf{packages_to_ignore} //= [
        "Log::ger",
        "Log::ger::Layout::LTSV",
        "Try::Tiny",
    ];

    return {
        create_layouter => [
            $pkg, # key
            50,   # priority
            sub { # hook
                my %hook_args = @_;

                my $layouter = sub { $pkg->_layout(\%plugin_conf, @_) };
                [$layouter];
            }],
    };
}

sub get_hooks {
    __PACKAGE__->_get_hooks(@_);
}

1;
# ABSTRACT: Layout log message as LTSV

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Layout::LTSV - Layout log message as LTSV

=head1 VERSION

This document describes version 0.004 of Log::ger::Layout::LTSV (from Perl distribution Log-ger-Layout-LTSV), released on 2020-03-07.

=head1 SYNOPSIS

 use Log::ger::Layout LTSV => (
     add_fields         => {key3 => 'value', key4 => 'value', ...},         # optional
     add_special_fields => {_date => 'Date_GMT', _host => 'Hostname', ...}, # optional
     delete_fields      => ['key1', 'key2', qr/some-regex/, ...],           # optional
 );
 use Log::ger;

 # if you use it together with Log::ger::Format::None:
 log_warn({key1 => 'val1', key2 => 'val2', foo => 'bar', ...);

 # otherwise, using the standard formatter:
 log_warn("blah %s", ['some', 'data']);

The final message will be something like:

 _date:2017-06-28T14:08:22	_host:example.com	foo:bar	key3:value	key4:value

or:

 _date:2017-06-28T14:08:22	_host:example.com	message:blah ["some","data"]

=head1 DESCRIPTION

This layouter allows you to log message as LTSV row. If you use
L<Log::ger::Format::None>, you can pass a hashref. Otherwise, the message will
be put in C<message> label. You can then delete keys then add additional
fields/keys (including special fields, a la L<Log::ger::Layout::Pattern>).

=for Pod::Coverage ^(.+)$

=head1 CONFIGURATION

=head2 add_fields => hash

=head2 add_special_fields => hash

Known special fields:

 Category: Category of the logging event
 Class: Fully qualified package [or class] name of the caller
 Date_Local: Current date in ISO8601 format (YYYY-MM-DD<T>hh:mm:ss) (localtime)
 Date_GMT: Current date in ISO8601 format (YYYY-MM-DD<T>hh:mm:ss) (GMT)
 File: File where the logging event occurred
 Hostname: (if Sys::Hostname is available)
 Location: Fully qualified name of the calling method followed by the
   callers source the file name and line number between parentheses.
 Line: Line number within the file where the log statement was issued
 Message: The message to be logged
 Method: Method or function where the logging request was issued
 Level: Level ("priority") of the logging event
 PID: PID of the current process
 Elapsed_Start: Number of seconds elapsed from program start to logging event
 Elapsed_Last: Number of seconds elapsed from last logging event to current
   logging event
 Stack_Trace: stack trace of functions called

Unknown special fields will cause the layouter to die.

=head2 delete_fields

=head2 packages_to_ignore

Regex or arrayref. When producing caller or stack trace information, will pass
this to L<Devel::Caller::Util>'s C<caller()> or C<callers()>.

=head2 subroutines_to_ignore

Regex or arrayref. When producing caller or stack trace information, will pass
this to L<Devel::Caller::Util>'s C<caller()> or C<callers()>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Log-ger-Layout-LTSV>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Log-ger-Layout-LTSV>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Log-ger-Layout-LTSV>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

More about LTSV format: L<http://ltsv.org>

L<Log::ger>

L<Log::ger::Layout::Pattern>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

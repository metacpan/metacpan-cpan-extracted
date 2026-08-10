package Desktop::XWindowManager::Util;

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

use Exporter qw(import);
use IPC::System::Options 'system', -log=>1;
use List::Util qw(any);
use Perinci::Sub::Util qw(gen_modified_sub);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2026-05-18'; # DATE
our $DIST = 'Desktop-XWindowManager-Util'; # DIST
our $VERSION = '0.005'; # VERSION

our @EXPORT_OK = qw(
                       list_xwm_windows
                       move_windows_to_kde_activity
               );

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities related to X Window Manager',
};

$SPEC{list_xwm_windows} = {
    v => 1.1,
    summary => "List all Windows",
    description => <<'MARKDOWN',

This utility is currently a wrapper for <prog:wmctrl>.

MARKDOWN
    args => {
        query => {
            schema => ['array*', of=>'str*'],
            pos => 0,
            slurpy => 1,
            description => <<'MARKDOWN',

Queries are matched against window titles, IDs, and KDE activity names & GUIDs
(if KDE activity names & GUIDs are requested).

MARKDOWN
            tags => ['category:filtering'],
        },
        id => {
            schema => 'str*',
            summary => 'Only list window with the specified ID',
            tags => ['category:filtering'],
        },
        kde_activity_name => {
            schema => ['array*', of=>'kdeactivity::name*'],
            summary => 'Only list window shown in one the specified KDE activity names',
            cmdline_aliases => {K=>{}},
            tags => ['category:filtering'],
        },
        current_kde_activity => {
            schema => 'bool*',
            summary => 'Only list window shown in the current KDE activity',
            cmdline_aliases => {k=>{}},
            tags => ['category:filtering'],
        },
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
        with_kde_activity => {
            summary => 'Show KDE activity GUID for each window (old name for with_kde_activity_guid)',
            schema => 'bool*',
        },
        with_kde_activity_guid => {
            summary => 'Show KDE activity GUID for each window',
            schema => 'bool*',
        },
        with_kde_activity_name => {
            summary => 'Show KDE activity name for each window',
            schema => 'bool*',
        },
    },
    deps => {
        prog => 'wmctrl',
    },
};
sub list_xwm_windows {
    my %args = @_;

    my $with_kde_activity =
        $args{with_kde_activity} ||
        $args{with_kde_activity_guid} ||
        $args{with_kde_activity_name} ||
        ($args{kde_activity_name} && @{$args{kde_activity_name}}) ||
        $args{current_kde_activity};
    my $detail = $args{detail};
    $detail //=1 if $with_kde_activity;

    my @rows;
    system({capture_stdout => \my $stdout}, "wmctrl", "-lpG");
    return [500, "Can't run wmctrl"] if $?;

    my @positive_query;
    my @negative_query;
  BUILD_QUERY: {
        for my $query (@{ $args{query} // [] }) {
            if ($query =~ /\A-(.*)/) {
                my $q = $1;
                push @negative_query, sub { $_[0] =~ /\Q$q\E/i ? 1 : 0 };
            } elsif ($query =~ m!\A/(.*)/\z!) {
                my $re = $1;
                push @positive_query, sub { $_[0] =~ /$re/i ? 1 : 0 };
            } else {
                push @positive_query, sub { $_[0] =~ /\Q$query\E/i ? 1 : 0 };
            }
        }
    } # BUILD_QUERY

    my $res_list_kact;
    if ($with_kde_activity) {
        require Desktop::KDEActivity::Util;
        $res_list_kact = Desktop::KDEActivity::Util::list_kde_activities(detail=>1);
        return [500, "Can't list KDE activities: $res_list_kact->[0] - $res_list_kact->[1]"]
            unless $res_list_kact->[0] == 200;
    }

    my $current_kde_activity;
  LINE:
    for my $line (split /^/m, $stdout) {
        my ($id, $desktop, $pid,
            $x, $y, $width, $height,
            $host, $title) = $line =~ /^(\S+)\s+(\S+)\s+(\d+)\s+
                                       (\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+
                                       (\S+)\s+(.*)/x;
        my $row = {
            id => $id,
            desktop => $desktop,
            pid => $pid,
            x => $x,
            y => $y,
            width => $width,
            height => $height,
            host => $host,
            title => $title,
        };

      GET_KDE_ACTIVITY: {
            last unless $with_kde_activity;
            my $res_get_act = get_xwm_window_kde_activity(id => $row->{id});
            if ($res_get_act->[0] != 200) {
                log_warn "Can't get KDE activity for window id %s: %d - %s", $row->{id}, $res_get_act->[0], $res_get_act->[1];
                last;
            }
            my $guids = $res_get_act->[2];
            my @guids = $guids ? (split /,/, $guids) : ();
            my $name;
            for my $row (@{ $res_list_kact->[2] }) {
                if (grep { $_ eq $row->{guid} } @guids) {
                    $name = defined($name) ?
                        (ref($name) eq 'ARRAY' ? [@$name, $row->{name}] : [$name, $row->{name}]) :
                        $row->{name};
                }
            }
            $row->{kde_activity_guid} = $guids if $args{with_kde_activity} || $args{with_kde_activity_guid};
            $row->{kde_activity_name} = $name if $args{with_kde_activity_name} || $args{kde_activity_name} || $args{current_kde_activity};
        }

      FILTER: {
          ID: {
                last unless defined $args{id};
                next LINE unless $row->{id} eq $args{id};
            } # ID

          KDE_ACTIVITY: {
                my @win_kde_activities = !defined($row->{kde_activity_name}) ? () :
                    ref($row->{kde_activity_name}) eq 'ARRAY' ? @{$row->{kde_activity_name}} :
                    ($row->{kde_activity_name});
                if ($args{current_kde_activity}) {
                    unless (defined $current_kde_activity) {
                        require Desktop::KDEActivity::Util;
                        my $res = Desktop::KDEActivity::Util::get_current_kde_activity();
                        return [500, "Can't get current KDE activity: $res->[0] - $res->[1]"]
                            unless $res->[0] == 200;
                        $current_kde_activity = $res->[2];
                    }
                    next LINE unless any { $_ eq $current_kde_activity } @win_kde_activities;
                } elsif ($args{kde_activity_name} && @{ $args{kde_activity_name} }) {
                    next LINE unless any {
                        my $k = $_;
                        any { $k eq $_ } @{ $args{kde_activity_name} };
                    } @win_kde_activities;
                }
            } # KDE_ACTIVITY

          NEGATIVE_QUERY: {
                last unless @negative_query;
                my $match = 1;
                for my $query (@negative_query) {
                    if ($query->($row->{title})) {
                        $match = 0; goto L1;
                    }
                }
              L1:
                unless ($match) {
                    log_trace "Skipping window id=%s title=<%s>: matches negative query in %s", $row->{id}, $row->{title}, $args{query};
                    next LINE;
                }
            } # NEGATIVE_QUERY

          POSITIVE_QUERY: {
                last unless @positive_query;
                my $match = 1;
                for my $query (@positive_query) {
                    if (!$query->(
                        join("|", grep {defined} ($row->{title}, $row->{kde_activity_guid}, $row->{kde_activity_name}))
                    )) {
                        $match = 0; goto L1;
                    }
                }

              L1:
                unless ($match) {
                    log_trace "Skipping window id=%s title=<%s>: does not match all positive query in %s", $row->{id}, $row->{title}, $args{query};
                    next LINE;
                }
            } # POSITIVE_QUERY
        } # FILTER

        push @rows, $row;
    } # for line

    unless ($args{detail}) {
        @rows = map { $_->{id} } @rows;
    }

    [200, "OK", \@rows];
}

$SPEC{get_xwm_window_kde_activity} = {
    v => 1.1,
    summary => "Get the KDE activity GUID(s) of a specific window",
    description => <<'MARKDOWN',

A window can be displayed in more than one KDE activities, so this utility can
return a comma-separated list of GUIDs.

MARKDOWN
    args => {
        id => {
            summary => 'Window ID, specified in hex form with 0x prefix, e.g. 0x05a0000e',
            schema => ['str*'],
            req => 1,
            pos => 0,
        },
    },
    deps => {
        all => [
            {prog => 'wmctrl'},
            {prog => 'xprop'},
        ],
    },
};
sub get_xwm_window_kde_activity {
    my %args = @_;

    my $id = $args{id} or return [400, "Please specify id"];

    system({capture_stdout => \my $stdout, capture_stderr => \my $stderr},
           "xprop", "-id", $id, "_KDE_NET_WM_ACTIVITIES");
    if ($?) {
        if ($stderr =~ /BadWindow.*invalid Window parameter/) {
            return [404, "No such window ID"];
        } else {
            return [500, "Can't successfully run xprop"];
        }
    } else {
        # sample output: _KDE_NET_WM_ACTIVITIES(STRING) = "40eabb80-2103-48af-8977-23b6e06fbcc3"
        my ($guid) = $stdout =~ /^_KDE_NET_WM_ACTIVITIES.+"([^"]+)"/;

        return [200, "OK", $guid];
    }
}

gen_modified_sub(
    output_name => 'move_windows_to_kde_activity',
    base_name => 'list_xwm_windows',
    die => 1,
    summary => 'Move matching window(s) to a specified KDE activity',
    description => <<'MARKDOWN',

Moving means the window will not be shown in any other KDE activity aside from
the specified ones.

By default, windows that are currently showing to all KDE activities are
excluded. To include them, set the `include_all_activities_windows` option.

MARKDOWN
    add_args => {
        activity_name => {
            schema => ['array*', of=> 'kdeactivity::name*'],
            cmdline_aliases => {a=>{}},
        },
        all_activities => {
            summary => 'Show window in all KDE activities instead of specific one(s)',
            schema => 'bool*',
        },
        include_all_activities_windows => {
            summary => 'Also move windows that are currently shown to all KDE activities (which are excluded by default)',
            schema => 'bool*',
            cmdline_aliases => {A=>{}},
        },
    },
    wrap_code => sub {
        my $orig = shift;
        my %args = @_;

        my $activity_names = delete $args{activity_name};
        if (defined $activity_names) {
            $activity_names = [$activity_names] unless ref $activity_names eq 'ARRAY';
        }

        require Desktop::KDEActivity::Util;
        my $res_list_act = Desktop::KDEActivity::Util::list_kde_activities(detail => 1);
        return [500, "Can't list KDE activities: $res_list_act->[0] - $res_list_act->[1]"]
            unless $res_list_act->[0] == 200;

        my @guids;
        if (defined $activity_names) {
            for my $row (@{ $res_list_act->[2] }) {
                if (grep { $_ eq $row->{name} } @$activity_names) {
                    push @guids, $row->{guid};
                }
            }
            return [404, "Can't find KDE activities named ".join(", ", @$activity_names)]
                unless @guids;
        }

        my $res_list_win = $orig->(
            %args,
            detail=>1,
            with_kde_activity_name => 1,
        );
        return [500, "Can't list windows: $res_list_win->[0] - $res_list_win->[1]"]
            unless $res_list_win->[0] == 200;

        return [404, "Can't find any matching windows"] unless @{ $res_list_win->[2] };
        for my $win (@{ $res_list_win->[2] }) {
            unless ($args{include_all_activities_windows}) {
                if (($win->{kde_activity_name} // '') eq '') {
                    # skip this window because it is displayed to all KDE activities
                    next;
                }
            }
            system "xprop", "-f", "_KDE_NET_WM_ACTIVITIES", "8s", "-id", $win->{id},
                "-set", "_KDE_NET_WM_ACTIVITIES",
                ($args{all_activities} ? "" : join(",",@guids));
        }

        [200];
    },
);

gen_modified_sub(
    output_name => 'move_windows_to_this_kde_activity',
    base_name => 'move_windows_to_kde_activity',
    die => 1,
    summary => 'Move matching window(s) to the current KDE activity',
    description => <<'MARKDOWN',

A simple wrapper for `move_windows_to_kde_activity`, where windows will be moved
to the current KDE activity.

MARKDOWN
    delete_args => [
        'activity_name',
        'all_activities',
    ],
    wrap_code => sub {
        my $orig = shift;
        my %args = @_;

        require Desktop::KDEActivity::Util;
        my $res = Desktop::KDEActivity::Util::get_current_kde_activity();
        return [500, "Can't get current KDE activity: $res->[0] - $res->[1]"]
            unless $res->[0] == 200;
        my $activity_name = $res->[2];

        $orig->(%args, activity_name => $activity_name);
    },
);

1;
# ABSTRACT: Utilities related to X Window Manager

__END__

=pod

=encoding UTF-8

=head1 NAME

Desktop::XWindowManager::Util - Utilities related to X Window Manager

=head1 VERSION

This document describes version 0.005 of Desktop::XWindowManager::Util (from Perl distribution Desktop-XWindowManager-Util), released on 2026-05-18.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes routines related to "X Window Manager".

Under the hood, it's currently a wrapper to tools like C<wmctrl>, etc.

C<wmctrl> works on EWMH-compliant X11 window managers. This means mainstream
desktop environments like KWin, Xfwm, Mutter (GNOME). It works partially or
doesn't work with minimalist window managers like dwm, suckless. It partially
works with Wayland where there is an X compatibility layer, e.g. GNOME Wayland,
KDE Plasma Wayland.

=head1 FUNCTIONS


=head2 get_xwm_window_kde_activity

Usage:

 get_xwm_window_kde_activity(%args) -> [$status_code, $reason, $payload, \%result_meta]

Get the KDE activity GUID(s) of a specific window.

A window can be displayed in more than one KDE activities, so this utility can
return a comma-separated list of GUIDs.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<id>* => I<str>

Window ID, specified in hex form with 0x prefix, e.g. 0x05a0000e.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 list_xwm_windows

Usage:

 list_xwm_windows(%args) -> [$status_code, $reason, $payload, \%result_meta]

List all Windows.

This utility is currently a wrapper for L<wmctrl>.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<current_kde_activity> => I<bool>

Only list window shown in the current KDE activity.

=item * B<detail> => I<bool>

(No description)

=item * B<id> => I<str>

Only list window with the specified ID.

=item * B<kde_activity_name> => I<array[kdeactivity::name]>

Only list window shown in one the specified KDE activity names.

=item * B<query> => I<array[str]>

Queries are matched against window titles, IDs, and KDE activity names & GUIDs
(if KDE activity names & GUIDs are requested).

=item * B<with_kde_activity> => I<bool>

Show KDE activity GUID for each window (old name for with_kde_activity_guid).

=item * B<with_kde_activity_guid> => I<bool>

Show KDE activity GUID for each window.

=item * B<with_kde_activity_name> => I<bool>

Show KDE activity name for each window.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 move_windows_to_kde_activity

Usage:

 move_windows_to_kde_activity(%args) -> [$status_code, $reason, $payload, \%result_meta]

Move matching window(s) to a specified KDE activity.

Moving means the window will not be shown in any other KDE activity aside from
the specified ones.

By default, windows that are currently showing to all KDE activities are
excluded. To include them, set the C<include_all_activities_windows> option.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<activity_name> => I<array[kdeactivity::name]>

(No description)

=item * B<all_activities> => I<bool>

Show window in all KDE activities instead of specific one(s).

=item * B<current_kde_activity> => I<bool>

Only list window shown in the current KDE activity.

=item * B<detail> => I<bool>

(No description)

=item * B<id> => I<str>

Only list window with the specified ID.

=item * B<include_all_activities_windows> => I<bool>

Also move windows that are currently shown to all KDE activities (which are excluded by default).

=item * B<kde_activity_name> => I<array[kdeactivity::name]>

Only list window shown in one the specified KDE activity names.

=item * B<query> => I<array[str]>

Queries are matched against window titles, IDs, and KDE activity names & GUIDs
(if KDE activity names & GUIDs are requested).

=item * B<with_kde_activity> => I<bool>

Show KDE activity GUID for each window (old name for with_kde_activity_guid).

=item * B<with_kde_activity_guid> => I<bool>

Show KDE activity GUID for each window.

=item * B<with_kde_activity_name> => I<bool>

Show KDE activity name for each window.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 move_windows_to_this_kde_activity

Usage:

 move_windows_to_this_kde_activity(%args) -> [$status_code, $reason, $payload, \%result_meta]

Move matching window(s) to the current KDE activity.

A simple wrapper for C<move_windows_to_kde_activity>, where windows will be moved
to the current KDE activity.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<activity_name> => I<array[kdeactivity::name]>

(No description)

=item * B<all_activities> => I<bool>

Show window in all KDE activities instead of specific one(s).

=item * B<current_kde_activity> => I<bool>

Only list window shown in the current KDE activity.

=item * B<detail> => I<bool>

(No description)

=item * B<id> => I<str>

Only list window with the specified ID.

=item * B<include_all_activities_windows> => I<bool>

Also move windows that are currently shown to all KDE activities (which are excluded by default).

=item * B<kde_activity_name> => I<array[kdeactivity::name]>

Only list window shown in one the specified KDE activity names.

=item * B<query> => I<array[str]>

Queries are matched against window titles, IDs, and KDE activity names & GUIDs
(if KDE activity names & GUIDs are requested).

=item * B<with_kde_activity> => I<bool>

Show KDE activity GUID for each window (old name for with_kde_activity_guid).

=item * B<with_kde_activity_guid> => I<bool>

Show KDE activity GUID for each window.

=item * B<with_kde_activity_name> => I<bool>

Show KDE activity name for each window.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Desktop-XWindowManager-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Desktop-XWindowManager-Util>.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords perlancar

perlancar <perlancar@gmail.com>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Desktop-XWindowManager-Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

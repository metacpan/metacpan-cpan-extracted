package Desktop::KDEActivity::Util;

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

use Exporter qw(import);
use IPC::System::Options 'system', -log=>1;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2026-03-29'; # DATE
our $DIST = 'Desktop-KDEActivity-Util'; # DIST
our $VERSION = '0.002'; # VERSION

our @EXPORT_OK = qw(
                       get_current_kde_activity
                       set_current_kde_activity
                       list_kde_activities
               );

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities related to KDE Activities',
};

sub _list_kde_activities {
    my $which = shift;
    my %args = @_;

    system({capture_stdout => \my $stdout},
           "kactivities-cli", ($which eq 'list' ? ("--list-activities") : ('--current-activity')));
    return [500, "Can't run kactivities-cli"] if $?;
    my @rows;

    for my $line (split /^/m, $stdout) {
        my ($status, $guid, $name, $icon) = $line =~ /^\[(.+?)\] ([0-9a-f-]+) (.+?) \((.*?)\)/;
        push @rows, {
            is_running => ($status =~ /RUNNING|CURRENT/ ? 1:0),
            is_current => ($status =~ /CURRENT/ ? 1:0),
            guid => $guid,
            name => $name,
            icon => $icon,
        };
    }

    unless ($args{detail}) {
        @rows = map { $_->{name} } @rows;
    }

    return [200, "OK", \@rows];
}

$SPEC{list_kde_activities} = {
    v => 1.1,
    summary => "List all known KDE activities",
    args => {
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
    },
    deps => {
        prog => 'kactivities-cli',
    },
};
sub list_kde_activities {
    _list_kde_activities('list', @_);
}

$SPEC{get_current_kde_activity} = {
    v => 1.1,
    summary => "Return the name of the current KDE activity",
    args => {
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
        guid => {
            summary => 'Return the GUID instead of the name',
            schema => 'bool*',
        },
        name => {
            summary => 'Return the name instead of the GUID (the default behavior)',
            schema => 'bool*',
            default => 1,
        },
    },
    deps => {
        prog => 'kactivities-cli',
    },
    args_rels => {
        choose_one => [qw/guid name/],
    },
};
sub get_current_kde_activity {
    my %args = @_;
    my $detail = delete($args{detail});
    my $name = delete($args{name}) // 1;
    my $guid = delete($args{guid});

    my $res = _list_kde_activities('current', %args, detail=>1);

    return $res unless $res->[0] == 200;
    if ($detail) { [200, "OK", $res->[2][0]] }
    elsif ($guid) { [200, "OK", $res->[2][0]{guid}] }
    else { [200, "OK", $res->[2][0]{name}] }
}

my $_comp_kde_activity_name = sub {
    require Complete::Util;

    my %args = @_;
    my $word = $args{word};

    my $res = list_kde_activities(detail => 1);
    return unless $res->[0] == 200;

    Complete::Util::complete_array_elem(word => $word, array=>[ map { $_->{name} } @{$res->[2] }]);
};

$SPEC{set_current_kde_activity} = {
    v => 1.1,
    summary => 'Set KDE current activity',
    description => <<'MARKDOWN',

Features:
- Specifying activity by name (kactivities-cli wants GUID)
- Tab completion

MARKDOWN
    args => {
        name => {
            schema => 'str*',
            req => 1,
            pos => 0,
            completion => $_comp_kde_activity_name,
        },
        # TODO: guid as alternative way to specify the activity
    },
    deps => {
        prog => 'qdbus',
    },
};
sub set_current_kde_activity {
    my %args = @_;
    defined(my $name = $args{name}) or return [400, "Please specify name"];

    my $res = list_kde_activities(detail => 1);
    return $res unless $res->[0] == 200;

    my $guid;
    for my $row (@{ $res->[2] }) {
        do { $guid = $row->{guid}; last } if $row->{name} eq $name;
    }
    return [404, "Cannot find activity named '$name'"] unless $guid;

    system({capture_stdout => \my $dummy}, "qdbus", "org.kde.ActivityManager", "/ActivityManager/Activities", "SetCurrentActivity", $guid);
    return [500, "Can't run qdbus"] if $?;

    [200];
}

1;
# ABSTRACT: Utilities related to KDE Activities

__END__

=pod

=encoding UTF-8

=head1 NAME

Desktop::KDEActivity::Util - Utilities related to KDE Activities

=head1 VERSION

This document describes version 0.002 of Desktop::KDEActivity::Util (from Perl distribution Desktop-KDEActivity-Util), released on 2026-03-29.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 get_current_kde_activity

Usage:

 get_current_kde_activity(%args) -> [$status_code, $reason, $payload, \%result_meta]

Return the name of the current KDE activity.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

(No description)

=item * B<guid> => I<bool>

Return the GUID instead of the name.

=item * B<name> => I<bool> (default: 1)

Return the name instead of the GUID (the default behavior).


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 list_kde_activities

Usage:

 list_kde_activities(%args) -> [$status_code, $reason, $payload, \%result_meta]

List all known KDE activities.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 set_current_kde_activity

Usage:

 set_current_kde_activity(%args) -> [$status_code, $reason, $payload, \%result_meta]

Set KDE current activity.

Features:
- Specifying activity by name (kactivities-cli wants GUID)
- Tab completion

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<name>* => I<str>

(No description)


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

Please visit the project's homepage at L<https://metacpan.org/release/Desktop-KDEActivity-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Desktop-KDEActivity-Util>.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Desktop-KDEActivity-Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

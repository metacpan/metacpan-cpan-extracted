package Firefox::Util::Profile;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Exporter 'import';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-04-16'; # DATE
our $DIST = 'Firefox-Util-Profile'; # DIST
our $VERSION = '0.006'; # VERSION

our @EXPORT_OK = qw(list_firefox_profiles);

our %SPEC;

# TODO: allow selecting local Firefox installation

$SPEC{list_firefox_profiles} = {
    v => 1.1,
    summary => 'List available Firefox profiles',
    description => <<'MARKDOWN',

This utility will read ~/.mozilla/firefox/profiles.ini (or
%APPDATA%\\Mozilla\\Firefox\\profiles.ini on Windows) and extracts the list of
profiles.

MARKDOWN
    args => {
        detail => {
            schema => 'bool',
            cmdline_aliases => {l=>{}},
        },
    },
};
sub list_firefox_profiles {
    require Config::IOD::INI::Reader;
    require Sort::Sub;

    my %args = @_;

    my @ff_dirs  = $^O eq 'MSWin32' ?
        ("$ENV{APPDATA}/Mozilla/Firefox") :
        ("$ENV{HOME}/.mozilla/firefox", "$ENV{HOME}/snap/firefox/common/.mozilla/firefox");
    my $ff_dir;
    for my $dir (@ff_dirs) {
        if (-d $dir) { $ff_dir = $dir; last }
    }
    return [412, "Cannot find firefox directory (tried ".join(", ", @ff_dirs).")"]
        unless defined $ff_dir;

    my $ini_path = "$ff_dir/profiles.ini";
    unless (-f $ini_path) {
        return [412, "Cannot find $ini_path"];
    }

    my @rows;
    my $hoh = Config::IOD::INI::Reader->new->read_file($ini_path);
    my $naturally = Sort::Sub::get_sorter('naturally');
  SECTION:
    for my $section (sort $naturally keys %$hoh) {
        my $href = $hoh->{$section};
        if ($section =~ /\AProfile/) {
            my $path;
            if (defined($path = $href->{Path})) {
                $path = "$ff_dir/$path" if $href->{IsRelative};
                push @rows, {
                    name => $href->{Name} // $section,
                    path => $path,
                    ini_section => $section,
                };
            } else {
                log_warn "$ini_path: No Path parameter for section $section, section ignored";
                next SECTION;
            }
        }
        # XXX add info: which sections are default in which installation
        # ([Install...] sections)
    }

    unless ($args{detail}) {
        @rows = map { $_->{name} } @rows;
    }

    [200, "OK", \@rows];
}

$SPEC{get_firefox_profile_dir} = {
    v => 1.1,
    summary => 'Given a Firefox profile name, return its directory',
    description => <<'MARKDOWN',

Return undef if Firefox profile is unknown.

MARKDOWN
    args_as => 'array',
    args => {
        profile => {
            schema => 'firefox::profile_name*',
            cmdline_aliases => {l=>{}},
            req => 1,
            pos => 0,
        },
    },
    result_naked => 1,
};
sub get_firefox_profile_dir {
    my $profile = shift;

    return unless defined $profile;
    my $res = list_firefox_profiles(detail=>1);
    unless ($res->[0] == 200) {
        log_warn "Can't list Firefox profile: $res->[0] - $res->[1]";
        return;
    };

    for (@{ $res->[2] }) {
        return $_->{path} if $_->{name} eq $profile;
    }
    return;
}

1;
# ABSTRACT: Given a Firefox profile name, return its directory

__END__

=pod

=encoding UTF-8

=head1 NAME

Firefox::Util::Profile - Given a Firefox profile name, return its directory

=head1 VERSION

This document describes version 0.006 of Firefox::Util::Profile (from Perl distribution Firefox-Util-Profile), released on 2025-04-16.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 get_firefox_profile_dir

Usage:

 get_firefox_profile_dir($profile) -> any

Given a Firefox profile name, return its directory.

Return undef if Firefox profile is unknown.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$profile>* => I<firefox::profile_name>

(No description)


=back

Return value:  (any)



=head2 list_firefox_profiles

Usage:

 list_firefox_profiles(%args) -> [$status_code, $reason, $payload, \%result_meta]

List available Firefox profiles.

This utility will read ~/.mozilla/firefox/profiles.ini (or
%APPDATA%\Mozilla\Firefox\profiles.ini on Windows) and extracts the list of
profiles.

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

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Firefox-Util-Profile>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Firefox-Util-Profile>.

=head1 SEE ALSO

Other C<Firefox::Util::*> modules.

L<Chrome::Util::Profile>

L<Vivaldi::Util::Profile>

L<Opera::Util::Profile>

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

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Firefox-Util-Profile>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

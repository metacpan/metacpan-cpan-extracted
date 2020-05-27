package Firefox::Util::Profile;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-24'; # DATE
our $DIST = 'Firefox-Util-Profile'; # DIST
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Exporter 'import';
our @EXPORT_OK = qw(list_firefox_profiles);

our %SPEC;

$SPEC{list_firefox_profiles} = {
    v => 1.1,
    summary => 'List available Firefox profiles',
    description => <<'_',

This utility will read ~/.mozilla/firefox/profiles.ini and extracts the list of
profiles.

_
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

    my $ff_dir   = "$ENV{HOME}/.mozilla/firefox";
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
    description => <<'_',

Return undef if Firefox profile is unknown.

_
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

This document describes version 0.004 of Firefox::Util::Profile (from Perl distribution Firefox-Util-Profile), released on 2020-05-24.

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


=back

Return value:  (any)



=head2 list_firefox_profiles

Usage:

 list_firefox_profiles(%args) -> [status, msg, payload, meta]

List available Firefox profiles.

This utility will read ~/.mozilla/firefox/profiles.ini and extracts the list of
profiles.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Firefox-Util-Profile>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Firefox-Util-Profile>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Firefox-Util-Profile>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Other C<Firefox::Util::*> modules.

L<Chrome::Util::Profile>

L<Vivaldi::Util::Profile>

L<Opera::Util::Profile>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

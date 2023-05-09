package Dist::Zilla::Plugin::TableData;

use 5.014;
use strict;
use warnings;

use Moose;
use namespace::autoclean;

use Data::Dmp;
use Require::Hook::Source::DzilBuild;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-02-10'; # DATE
our $DIST = 'Dist-Zilla-Plugin-TableData'; # DIST
our $VERSION = '0.002'; # VERSION

with (
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [':InstallModules'],
    },
    #'Dist::Zilla::Role::RequireFromBuild',
);

sub munge_files {
    my $self = shift;

    local @INC = (Require::Hook::Source::DzilBuild->new(zilla => $self->zilla, die=>1, debug=>1), @INC);

    my %seen_mods;
    for my $file (@{ $self->found_files }) {
        next unless $file->name =~ m!\Alib/((TableData/.+)\.pm)\z!;

        my $package_pm = $1;
        my $package = $2; $package =~ s!/!::!g;

        my $content = $file->content;

        # Add statistics to %STATS variable
      CREATE_STATS:
        {
            require $package_pm;
            no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict
            my $stats = \%{"$package\::STATS"};
            last if keys %$stats; # module creates its own stats, skip
            my $no_stats = ${"$package\::NO_STATS"};
            last if $no_stats; # module does not want stats, skip

            my $td = $package->new;

            my %stats = (
                num_rows => 0,
                num_columns => 0,
            );
            $stats{num_rows} = $td->get_row_count;
            $stats{num_columns} = $td->get_column_count;

            $content =~ s{^(#\s*STATS)$}{"our \%STATS = ".dmp(%stats)."; " . $1}em
                or die "Can't replace #STATS for ".$file->name.", make sure you put the #STATS placeholder in modules";
            $self->log(["replacing #STATS for %s", $file->name]);

            $file->content($content);
        }
    } # foreach file
    return;
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Plugin to use when building TableData::* distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::TableData - Plugin to use when building TableData::* distribution

=head1 VERSION

This document describes version 0.002 of Dist::Zilla::Plugin::TableData (from Perl distribution Dist-Zilla-Plugin-TableData), released on 2023-02-10.

=head1 SYNOPSIS

In F<dist.ini>:

 [TableData]

=head1 DESCRIPTION

This plugin is to be used when building C<TableData::*> distribution. Currently
it does the following:

=over

=item * Replace C<# STATS> placeholder (which must exist) with table data statistics

=back

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-TableData>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-TableData>.

=head1 SEE ALSO

L<TableData>

L<Pod::Weaver::Plugin::TableData>

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

This software is copyright (c) 2023, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-TableData>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

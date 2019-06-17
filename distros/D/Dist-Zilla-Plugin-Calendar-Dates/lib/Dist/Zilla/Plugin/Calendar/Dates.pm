package Dist::Zilla::Plugin::Calendar::Dates;

our $DATE = '2019-06-08'; # DATE
our $VERSION = '0.100'; # VERSION

use 5.010001;
use strict;
use warnings;

use Moose;
use namespace::autoclean;

use DateTime;
use List::Util qw(min max);

with (
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [':InstallModules'],
    },
);

sub munge_files {
    no strict 'refs';
    my $self = shift;

    local @INC = ("lib", @INC);

    #my $cur_year = (localtime)[5]+1900;

    for my $file (@{ $self->found_files }) {
        next unless $file->name =~ m!\Alib/((Calendar/Dates/.+)\.pm)\z!;

        my $package_pm = $1;
        my $package = $2; $package =~ s!/!::!g;

        #my $content = $file->content;

        require $package_pm;

        # check that entries are valid
        {
            require $package_pm;
            my $min_year = $package->get_min_year;
            my $max_year = $package->get_max_year;

            die "Invalid min_year, please return 0-9999"
                unless defined $min_year && $min_year >= 0 && $min_year <= 9999;
            die "Invalid max_year, please return 0-9999"
                unless defined $max_year && $max_year >= 0 && $max_year <= 9999;
            die "max_year must be >= min_year"
                unless $max_year >= $min_year;

            my ($check_year1, $check_year2);
            if ($max_year - $min_year <= 100) {
                $check_year1 = $min_year;
                $check_year2 = $max_year;
            } else {
                $check_year1 = max($min_year, $max_year-100);
                $check_year2 = min($max_year, $min_year+100);
            }

          YEAR:
            for my $year ($check_year1 .. $check_year2) {
                my $entries;
                eval { $entries = $package->get_entries($year) };
                do { warn "get_entries($year) died: $@, skipped year"; next YEAR } if $@;

                for my $i (0..$#{$entries}) {
                    my $e = $entries->[$i];

                    defined $e->{date} or die "entries[$i] ($year) doesn't have date";
                    $e->{date} =~ m!\A(\d{4})-(\d{2})-(\d{2})(?:T(\d{2}):(\d{2})(?:/(\d{2}):(\d{2}))?)?\z!a or die "entries[$i] ($year) date has invalid syntax '$e->{date}', please use YYYY-MM-DD or YYYY-MM-DDTHH:MM or YYYY-MM-DDTHH:MM/HH:MM";

                    my ($y, $m, $d, $H1, $M1, $H2, $M2) = ($1, $2, $3, $4, $5, $6, $7);

                    eval { my $dt = DateTime->new(year=>$y, month=>$m, day=>$d) };
                    $@ and die "entries[$i] ($year) has invalid date ($e->{date}): $@";

                    defined $e->{year}   or die "entries[$i] ($year) doesn't have year";
                    $e->{year} == $year  or die "entries[$i] ($year) year ($e->{year}) is not $year";
                    $e->{year} == $y     or die "entries[$i] ($year) year ($e->{year}) is not equal to date's year ($y)";

                    defined $e->{month}  or die "entries[$i] ($year) doesn't have month";
                    $e->{month} == $m    or die "entries[$i] ($year) month ($e->{month}) is not equal to date's month ($m)";

                    defined $e->{day}    or die "entries[$i] ($year) doesn't have day";
                    $e->{day} == $d      or die "entries[$i] ($year) day ($e->{day}) is not equal to date's day ($d)";
                }
            } # YEAR
        }

    } # foreach file
    return;
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Plugin to use when building Calendar::Dates::* distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Calendar::Dates - Plugin to use when building Calendar::Dates::* distribution

=head1 VERSION

This document describes version 0.100 of Dist::Zilla::Plugin::Calendar::Dates (from Perl distribution Dist-Zilla-Plugin-Calendar-Dates), released on 2019-06-08.

=head1 SYNOPSIS

In F<dist.ini>:

 [Calendar::Dates]

=head1 DESCRIPTION

This plugin is to be used when building C<Calendar::Dates::*> distribution.
Currently it does the following:

=over

=item * Check that entries are valid

=item * Check that get_min_year() and get_max_year() return sensible values

=back

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-Calendar-Dates>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-Calendar-Dates>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Calendar-Dates>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Calendar::Dates>

L<Pod::Weaver::Plugin::Calendar::Dates>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

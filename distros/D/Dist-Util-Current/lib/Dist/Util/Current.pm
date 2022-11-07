package Dist::Util::Current;

use strict;
use warnings;
use Log::ger;

use Exporter 'import';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-11-07'; # DATE
our $DIST = 'Dist-Util-Current'; # DIST
our $VERSION = '0.003'; # VERSION

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       my_dist
               );

sub _packlist_has_entry {
    my ($packlist, $filename, $dist) = @_;

    open my $fh, '<', $packlist or do {
        log_warn "Can't open packlist '$packlist': $!";
        return 0;
    };
    while (my $line = <$fh>) {
        chomp $line;
        if ($line eq $filename) {
            log_trace "my_dist(): Using dist from packlist %s because %s is listed in it: %s",
                $packlist, $filename, $dist;
            return 1;
        }
    }
    0;
}

sub my_dist {
    my %args = @_;

    my $filename = $args{filename};
    my $package  = $args{package};

    if (!defined($filename) || !defined($package)) {
        my @caller = caller(0);
        $package  = $caller[0] unless defined $package;
        $filename = $caller[1] unless defined $filename;
    }

  DIST_PACKAGE_VARIABLE: {
        no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict
        my $dist = ${"$package\::DIST"};
        last unless defined $dist;
        log_trace "my_dist(): Using dist from package $package\'s \$DIST: %s", $dist;
        return $dist;
    }

    my @namespace_parts = split /::/, $package;
  PACKLIST_FOR_MOD_OR_SUPERMODS: {
        require Dist::Util;
        for my $i (reverse 0..$#namespace_parts) {
            my $mod = join "::", @namespace_parts[0 .. $i];
            my $packlist = Dist::Util::packlist_for($mod);
            next unless defined $packlist;
            my $dist = $mod; $dist =~ s!::!-!g;
            return $dist if _packlist_has_entry($packlist, $filename, $dist);
        }
    }

  PACKLIST_IN_INC: {
        require Dist::Util;
        log_trace "my_dist(): Listing all distributions ...";
        my @recs = Dist::Util::list_dists(detail => 1);
        for my $rec (@recs) {
            return $rec->{dist} if _packlist_has_entry($rec->{packlist}, $filename, $rec->{dist});
        }
    }

  THIS_DIST: {
        require App::ThisDist;
        my @entries = (".");
        for (1 .. @namespace_parts) {
            push @entries, join("/", (("..") x $_));
        }
        for my $entry (@entries) {
            log_trace "my_dist(): Checking with this_dist($entry) ...";
            my $dist = App::ThisDist::this_dist($entry);
            if (defined $dist) {
                log_trace "my_dist(): Using dist from this_dist(%s): %s", $entry, $dist;
                return $dist;
            }
        }
    }

    log_trace "my_dist(): Can't guess dist for filename=%s, package=%s", $filename, $package;
    undef;
}

1;
# ABSTRACT: Guess the current Perl distribution name

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Util::Current - Guess the current Perl distribution name

=head1 VERSION

This document describes version 0.003 of Dist::Util::Current (from Perl distribution Dist-Util-Current), released on 2022-11-07.

=head1 SYNOPSIS

 use Dist::Util::Current qw(my_dist);

 my $dist = my_dist();

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 my_dist

Usage:

 my_dist(%opts) => STR|HASH

Guess the current distribution (the Perl distribution associated with the source
code) using one of several ways.

Options:

=over

=item * filename

String. The path to source code file. If unspecified, will use file name
retrieved from C<caller(0)>.

=item * package

String. The caller's package. If unspecified, will use package name retrieved
from C<caller(0)>.

=back

How the function works:

=over

=item 1. $DIST

If the caller's package defines a package variable C<$DIST>, will return this.

=item 2. F<.packlist> for module or supermodules

Will check F<.packlist> for module or supermodules. For example, if module is
L<Algorithm::Backoff::Constant> then will try to check for F<.packlist> for
C<Algorithm::Backoff::Constant>, C<Algorithm::Backoff>, and C<Algorithm>.

For each found F<.packlist> will read its contents and check whether the
F<filename> is listed. If yes, then we've found the distribution name and return
it.

=item 3. F<.packlist> in C<@INC>

Will check F<.packlist> in directories listed in C<@INC>. Will use
L<Dist::Util>'s C<list_dists()> for this.

For each found F<.packlist> will read its contents and check whether the
F<filename> is listed. If yes, then we've found the distribution name and return
it.

=item 4. Try C<this_dist()> against current directory and several levels up

Will guess using L<App::ThisDist>'s C<this_dist()> against the current
directory and several levels up.

=back

If all of the above fails, we return undef.

TODO: Query the OS's package manager.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Util-Current>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Util-Current>.

=head1 SEE ALSO

L<App::ThisDist>

L<Dist::Util>

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

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Util-Current>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

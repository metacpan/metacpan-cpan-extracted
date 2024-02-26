package File::Util::Rename;

use 5.010001;
use strict;
use warnings;

use Exporter 'import';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-02-12'; # DATE
our $DIST = 'File-Util-Rename'; # DIST
our $VERSION = '0.002'; # VERSION

our @EXPORT_OK = qw(
                       rename_noclobber
               );

sub rename_noclobber {
    my $opts = ref $_[0] eq 'HASH' ? shift : {};
    $opts->{pattern} //= " (%02d)";

    my ($from, $to) = @_;
    my $ext; $to =~ s/(\.\w+)\z// and $ext = $1;

    my $i = 0;
    my $to_final;
    while (1) {
        if ($i) {
            my $suffix = sprintf $opts->{pattern}, $i;
            $to_final = $ext ? "$to$suffix$ext" : "$to$suffix";
        } else {
            $to_final = $to;
        }
        lstat $to_final;
        last unless -e _;
        $i++;
    }
    rename $from, $to_final;
}

1;
# ABSTRACT: Utilities related to renaming files

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Util::Rename - Utilities related to renaming files

=head1 VERSION

This document describes version 0.002 of File::Util::Rename (from Perl distribution File-Util-Rename), released on 2024-02-12.

=head1 SYNOPSIS

 use File::Util::Rename qw(
     rename_noclobber
 );

 rename_noclobber "foo.txt", "bar.txt"; # will rename to "bar (01).txt" etc if "bar.txt" exists

=head1 DESCRIPTION

=head2 rename_noclobber

Usage:

 rename_noclobber( [ \%opts , ] $from, $to );

Known options:

=over

=item * pattern

Str. Defaults to " (%02d)".

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/File-Util-Rename>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-File-Util-Rename>.

=head1 SEE ALSO

L<File::Copy::NoClobber>

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=File-Util-Rename>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

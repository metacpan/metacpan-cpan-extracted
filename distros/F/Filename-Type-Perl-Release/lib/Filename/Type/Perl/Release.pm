package Filename::Type::Perl::Release;

use 5.010001;
use strict;
use warnings;

use Exporter 'import';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-12-21'; # DATE
our $DIST = 'Filename-Type-Perl-Release'; # DIST
our $VERSION = '0.002'; # VERSION

our @EXPORT_OK = qw(check_perl_release_filename);

our %SPEC;

$SPEC{check_perl_release_filename} = {
    v => 1.1,
    summary => 'Check whether filename looks like a perl module release archive, e.g. a CPAN release tarball',
    description => <<'MARKDOWN',


MARKDOWN
    args => {
        filename => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
    },
    result_naked => 1,
    result => {
        schema => ['any*', of=>['bool*', 'hash*']],
        description => <<'MARKDOWN',

Return false if not detected like a perl module release archive. Otherwise
return a hash of information, which contains these keys: `distribution`,
`module`, `version`.

MARKDOWN
    },
};
sub check_perl_release_filename {
    require Filename::Archive;

    my %args = @_;

    my $filename = $args{filename};

    my $cares = Filename::Archive::check_archive_filename(filename=>$filename, ci=>1);
    return 0 unless $cares;

    $cares->{filename_without_suffix} =~
        /\A
         (\w+(?:-\w+)*)
         -v?(\d+(?:\.\d+){0,}(_\d+|-TRIAL)?)
         \z/ix
             or return 0;
    my ($dist, $ver) = ($1, $2);
    (my $mod = $dist) =~ s/-/::/g;
    {distribution => $dist, module=>$mod, version=>$ver, archive_suffix=>$cares->{archive_suffix}};
}

1;
# ABSTRACT: Check whether filename looks like a perl module release archive, e.g. a CPAN release tarball

__END__

=pod

=encoding UTF-8

=head1 NAME

Filename::Type::Perl::Release - Check whether filename looks like a perl module release archive, e.g. a CPAN release tarball

=head1 VERSION

This document describes version 0.002 of Filename::Type::Perl::Release (from Perl distribution Filename-Type-Perl-Release), released on 2024-12-21.

=head1 SYNOPSIS

 use Filename::Type::Perl::Release qw(check_perl_release_filename);
 my $res = check_perl_release_filename(filename => "Foo-Bar-1.000.tar.gz");
 if ($res) {
     printf "File looks like a perl module release archive: dist=%s, version=%s)\n",
         $res->{distribution},
         $res->{version};
 } else {
     print "File does not look like a perl module release archive\n";
 }

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 check_perl_release_filename

Usage:

 check_perl_release_filename(%args) -> bool|hash

Check whether filename looks like a perl module release archive, e.g. a CPAN release tarball.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<filename>* => I<str>

(No description)


=back

Return value:  (bool|hash)


Return false if not detected like a perl module release archive. Otherwise
return a hash of information, which contains these keys: C<distribution>,
C<module>, C<version>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Filename-Type-Perl-Release>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Filename-Type-Perl-Release>.

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Filename-Type-Perl-Release>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

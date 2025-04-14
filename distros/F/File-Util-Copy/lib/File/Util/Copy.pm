package File::Util::Copy;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Exporter 'import';
use File::Copy ();

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-11-22'; # DATE
our $DIST = 'File-Util-Copy'; # DIST
our $VERSION = '0.002'; # VERSION

our @EXPORT_OK = qw(
                       copy_noclobber
                       copy_warnclobber
               );

sub copy_noclobber {
    my $opts = ref $_[0] eq 'HASH' ? shift : {};
    $opts->{pattern} //= " (%02d)";

    my ($from, $to) = @_;
    my $ext; $to =~ s/(\.\w+)\z// and $ext = $1;

    # XXX handle when to is a filehandle ref/blob, which File::Copy supports

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
    File::Copy::copy($from, $to_final);
}

sub copy_warnclobber {
    my $opts = ref $_[0] eq 'HASH' ? shift : {};
    $opts->{log} //= 0;

    my ($from, $to) = @_;

    # XXX handle when to is a filehandle ref/blob, which File::Copy supports
    if (-e $to) {
        if ($opts->{log}) {
            log_warn "copy_warnclobber(`$from`, `$to`): Target already exists, renaming anyway ...";
        } else {
            warn "copy_warnclobber(`$from`, `$to`): Target already exists, renaming anyway ...\n";
        }
    }

    File::Copy::copy($from, $to);
}

1;
# ABSTRACT: Utilities related to copying files

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Util::Copy - Utilities related to copying files

=head1 VERSION

This document describes version 0.002 of File::Util::Copy (from Perl distribution File-Util-Copy), released on 2024-11-22.

=head1 SYNOPSIS

 use File::Util::Copy qw(
     copy_noclobber
     copy_warnclobber
 );

 copy_noclobber "foo.txt", "bar.txt"; # will copy to "bar (01).txt" if "bar.txt" exists (or "bar (02).txt" if "bar (01).txt" also exists, and so on)

 copy_warnclobber "foo.txt", "bar.txt"; # will emit a warning to stdrr if "bar.txt" exists, but copy/overwrite it anyway

=head1 DESCRIPTION

=head2 copy_noclobber

Usage:

 copy_noclobber( [ \%opts , ] $from, $to );

Known options:

=over

=item * pattern

Str. Defaults to " (%02d)".

=back

=head2 copy_warnclobber

Usage:

 copy_warnclobber( [ \%opts , ] $from, $to );

Known options:

=over

=item * log

Bool. If set to true, will log using L<Log::ger> instead of printing warning to
stderr.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/File-Util-Copy>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-File-Util-Copy>.

=head1 SEE ALSO

L<File::Copy::NoClobber> also has a non-clobber version of copy()

L<File::Util::Rename>'s C<rename_noclobber()>, C<rename_warnclobber()>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=File-Util-Copy>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

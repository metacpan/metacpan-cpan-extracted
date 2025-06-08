package Filename::Type::Backup;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-12-20'; # DATE
our $DIST = 'Filename-Type-Backup'; # DIST
our $VERSION = '0.040'; # VERSION

use Exporter qw(import);
our @EXPORT_OK = qw(check_backup_filename);

our %SPEC;

our %SUFFIXES = (
    '~'     => 1,
    '.bak'  => 1,
    '.old'  => 1,
    '.orig' => 1, # patch
    '.rej'  => 1, # patch
    '.swp'  => 1,
    # XXX % (from /etc/mime.types)
    # XXX sik? (from /etc/mime.types)
    # XXX .dpkg*
    # XXX .rpm*
);

$SPEC{check_backup_filename} = {
    v => 1.1,
    summary => 'Check whether filename indicates being a backup file',
    description => <<'MARKDOWN',


MARKDOWN
    args => {
        filename => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
        # XXX recurse?
        ci => {
            summary => 'Whether to match case-insensitively',
            schema  => 'bool',
            default => 1,
        },
    },
    result_naked => 1,
    result => {
        schema => ['any*', of=>['bool*', 'hash*']],
        description => <<'MARKDOWN',

Return false if not detected as backup name. Otherwise return a hash, which may
contain these keys: `original_filename`. In the future there will be extra
information returned, e.g. editor name (if filename indicates backup from
certain backup program), date (if filename contains date information), and so
on.

MARKDOWN
    },
};
sub check_backup_filename {
    my %args = @_;

    my $filename = $args{filename};
    my $orig_filename;

    if ($filename =~ /\A#(.+)#\z/) {
        $orig_filename = $1;
        goto RETURN;
    }

    $filename =~ /(~|\.\w+)\z/ or return 0;
    my $ci = $args{ci} // 1;

    my $suffix = $1;

    my $spec;
    if ($ci) {
        my $suffix_lc = lc($suffix);
        for (keys %SUFFIXES) {
            if (lc($_) eq $suffix_lc) {
                $spec = $SUFFIXES{$_};
                last;
            }
        }
    } else {
        $spec = $SUFFIXES{$suffix};
    }
    return 0 unless $spec;

    ($orig_filename = $filename) =~ s/\Q$suffix\E\z//;

  RETURN:
    return {
        original_filename => $orig_filename,
    };
}

1;
# ABSTRACT: Check whether filename indicates being a backup file

__END__

=pod

=encoding UTF-8

=head1 NAME

Filename::Type::Backup - Check whether filename indicates being a backup file

=head1 VERSION

This document describes version 0.040 of Filename::Type::Backup (from Perl distribution Filename-Type-Backup), released on 2024-12-20.

=head1 SYNOPSIS

 use Filename::Type::Backup qw(check_backup_filename);
 my $res = check_backup_filename(filename => "foo.txt~");
 if ($res) {
     printf "Filename indicates a backup, original name: %s\n",
         $res->{original_filename};
 } else {
     print "Filename does not indicate a backup\n";
 }

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 check_backup_filename

Usage:

 check_backup_filename(%args) -> bool|hash

Check whether filename indicates being a backup file.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<ci> => I<bool> (default: 1)

Whether to match case-insensitively.

=item * B<filename>* => I<str>

(No description)


=back

Return value:  (bool|hash)


Return false if not detected as backup name. Otherwise return a hash, which may
contain these keys: C<original_filename>. In the future there will be extra
information returned, e.g. editor name (if filename indicates backup from
certain backup program), date (if filename contains date information), and so
on.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Filename-Type-Backup>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Filename-Type-Backup>.

=head1 SEE ALSO

L<Filename::Type::Archive>

L<Filename::Type::Compressed>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Filename-Type-Backup>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

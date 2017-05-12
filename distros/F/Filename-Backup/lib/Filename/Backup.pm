package Filename::Backup;

our $DATE = '2016-10-19'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA       = qw(Exporter);
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
    description => <<'_',


_
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
        description => <<'_',

Return false if not detected as backup name. Otherwise return a hash, which may
contain these keys: `original_filename`. In the future there will be extra
information returned, e.g. editor name (if filename indicates backup from
certain backup program), date (if filename contains date information), and so
on.

_
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

Filename::Backup - Check whether filename indicates being a backup file

=head1 VERSION

This document describes version 0.03 of Filename::Backup (from Perl distribution Filename-Backup), released on 2016-10-19.

=head1 SYNOPSIS

 use Filename::Backup qw(check_backup_filename);
 my $res = check_backup_filename(filename => "foo.txt~");
 if ($res) {
     printf "Filename indicates a backup, original name: %s\n",
         $res->{original_filename};
 } else {
     print "Filename does not indicate a backup\n";
 }

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 check_backup_filename(%args) -> bool|hash

Check whether filename indicates being a backup file.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<ci> => I<bool> (default: 1)

Whether to match case-insensitively.

=item * B<filename>* => I<str>

=back

Return value:  (bool|hash)


Return false if not detected as backup name. Otherwise return a hash, which may
contain these keys: C<original_filename>. In the future there will be extra
information returned, e.g. editor name (if filename indicates backup from
certain backup program), date (if filename contains date information), and so
on.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Filename-Backup>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Filename-Backup>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Filename-Backup>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Filename::Archive>

L<Filename::Compressed>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

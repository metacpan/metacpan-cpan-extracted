package Filename::Archive;

our $DATE = '2015-09-03'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(check_archive_filename);
#list_archive_suffixes

# XXX multi-part archive?

our %SUFFIXES = (
    '.zip' => {name=>'Zip'},
    '.rar' => {name=>'RAR'},
    '.tar' => {name=>'tar'},
    # XXX 7zip
    # XXX older/less popular: ARJ, lha, zoo
    # XXX windows: cab
    # XXX zip-based archives: war, etc
    # XXX tar-based archives: linux packages
);

our %ARCHIVES = (
    Zip => {
        # all programs mentioned here must accept filename(s) as arguments.
        # preferably CLI. XXX specify capabilities (password-protection, unix
        # permission, etc). XXX specify how to create (with password, etc). XXX
        # specify how to extract.
        archiver_programs => [
            {name => 'zip', opts => ''},
        ],
        extractor_programs => [
            {name => 'zip', opts => ''},
            {name => 'unzip', opts => ''},
        ],
    },
    RAR => {
    },
    tar => {
    },
);

our %SPEC;

$SPEC{check_archive_filename} = {
    v => 1.1,
    summary => 'Check whether filename indicates being an archive file',
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

Return false if no archive suffixes detected. Otherwise return a hash of
information, which contains these keys: `archive_name`, `archive_suffix`,
`compressor_info`.

_
    },
};
sub check_archive_filename {
    require Filename::Compressed;

    my %args = @_;

    my $filename = $args{filename};
    my $ci = $args{ci} // 1;

    my @compressor_info;
    while (1) {
        my $res = Filename::Compressed::check_compressed_filename(
            filename => $filename, ci => $ci);
        if ($res) {
            push @compressor_info, $res;
            $filename = $res->{uncompressed_filename};
            next;
        } else {
            last;
        }
    }

    $filename =~ /(\.\w+)\z/ or return 0;
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

    return {
        archive_name       => $spec->{name},
        archive_suffix     => $suffix,
        (compressor_info    => \@compressor_info) x !!@compressor_info,
    };
}

1;
# ABSTRACT: Check whether filename indicates being an archive file

__END__

=pod

=encoding UTF-8

=head1 NAME

Filename::Archive - Check whether filename indicates being an archive file

=head1 VERSION

This document describes version 0.02 of Filename::Archive (from Perl distribution Filename-Archive), released on 2015-09-03.

=head1 SYNOPSIS

 use Filename::Archive qw(check_archive_filename);
 my $res = check_archive_filename(filename => "foo.tar.gz");
 if ($res) {
     printf "File is an archive (type: %s, compressed: %s)\n",
         $res->{archive_name},
         $res->{compressor_info} ? "yes":"no";
 } else {
     print "File is not an archive\n";
 }

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 check_archive_filename(%args) -> bool|hash

Check whether filename indicates being an archive file.

Arguments ('*' denotes required arguments):

=over 4

=item * B<ci> => I<bool> (default: 1)

Whether to match case-insensitively.

=item * B<filename>* => I<str>

=back

Return value:  (bool|hash)


Return false if no archive suffixes detected. Otherwise return a hash of
information, which contains these keys: C<archive_name>, C<archive_suffix>,
C<compressor_info>.

=head1 SEE ALSO

L<Filename::Compressed>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Filename-Archive>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Filename-Archive>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Filename-Archive>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

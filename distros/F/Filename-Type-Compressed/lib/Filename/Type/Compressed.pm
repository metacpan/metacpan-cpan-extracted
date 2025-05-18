package Filename::Type::Compressed;

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-12-20'; # DATE
our $DIST = 'Filename-Type-Compressed'; # DIST
our $VERSION = '0.051'; # VERSION

our @EXPORT_OK = qw(check_compressed_filename);
#list_compressor_suffixes

our %SUFFIXES = (
    '.Z'   => {name=>'NCompress'},
    '.gz'  => {name=>'Gzip'},
    '.bz2' => {name=>'Bzip2'},
    '.xz'  => {name=>'XZ'},
    '.lz'  => {name=>'LZ'},
    '.lzma'=> {name=>'LZMA'},
    '.zst' => {name=>'Zstandard'},
    '.br'  => {name=>'Brotli'},
);

our %COMPRESSORS = (
    NCompress => {
        # all programs mentioned here must accept filename(s) as arguments.
        # preferably CLI.
        compressor_programs => [
            {name => 'compress', opts => ''},
        ],
        decompressor_programs => [
            {name => 'uncompress', opts => ''},
        ],
    },
    Gzip => {
        compressor_programs => [
            {name => 'gzip', opts => ''},
        ],
        decompressor_programs => [
            {name => 'gzip', opts => '-d'},
            {name => 'gunzip', opts => ''},
        ],
    },
    Bzip2 => {
        compressor_programs => [
            {name => 'bzip2', opts => ''},
        ],
        decompressor_programs => [
            {name => 'bzip2', opts => '-d'},
            {name => 'bunzip2', opts => ''},
        ],
    },
    XZ => {
        compressor_programs => [
            {name => 'xz', opts => ''},
        ],
        decompressor_programs => [
            {name => 'xz', opts => '-d'},
            {name => 'unxz', opts => ''},
        ],
    },
    Zstandard => {
        compressor_programs => [
            {name => 'zstd', opts => ''},
        ],
        decompressor_programs => [
            {name => 'zstd', opts => '-d'},
            {name => 'unzstd', opts => ''},
        ],
    },
    Brotli => {
        compressor_programs => [
        ],
        decompressor_programs => [
        ],
    },
    LZ => {
        compressor_programs => [
        ],
        decompressor_programs => [
        ],
    },
    LZMA => {
        compressor_programs => [
            {name => 'lzma', opts => ''},
        ],
        decompressor_programs => [
            {name => 'lzma', opts => '-d'},
            {name => 'unlzma', opts => ''},
        ],
    },
);

our %SPEC;

$SPEC{check_compressed_filename} = {
    v => 1.1,
    summary => 'Check whether filename indicates being compressed',
    description => <<'_',


_
    args => {
        filename => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
        # recurse?
        ignore_case => {
            summary => 'Whether to match case-insensitively',
            schema  => 'bool',
            default => 1,
        },
    },
    result_naked => 1,
    result => {
        schema => ['any*', of=>['bool*', 'hash*']],
        description => <<'_',

Return false if no compressor suffixes detected. Otherwise return a hash of
information, which contains these keys: `compressor_name`, `compressor_suffix`,
`uncompressed_filename`.

_
    },
    examples => [
        {
            args => {filename=>'foo.bar'},
        },
        {
            args => {filename=>'baz.xz'},
        },
        {
            args => {filename=>'qux.Bz2'},
        },
    ],
};
sub check_compressed_filename {
    my %args = @_;

    my $filename = $args{filename};
    $filename =~ /(\.\w+)\z/ or return 0;
    my $ci = $args{ignore_case} // 1;

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

    (my $ufilename = $filename) =~ s/\.\w+\z//;

    return {
        compressor_name       => $spec->{name},
        compressor_suffix     => $suffix,
        uncompressed_filename => $ufilename,
    };
}

1;
# ABSTRACT: Check whether filename indicates being compressed

__END__

=pod

=encoding UTF-8

=head1 NAME

Filename::Type::Compressed - Check whether filename indicates being compressed

=head1 VERSION

This document describes version 0.051 of Filename::Type::Compressed (from Perl distribution Filename-Type-Compressed), released on 2024-12-20.

=head1 SYNOPSIS

 use Filename::Type::Compressed qw(check_compressed_filename);
 my $res = check_compressed_filename(filename => "foo.txt.gz");
 if ($res) {
     printf "File is compressed with %s, uncompressed name: %s\n",
         $res->{compressor_name},
         $res->{uncompressed_filename};
 } else {
     print "File is not compressed\n";
 }

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 check_compressed_filename

Usage:

 check_compressed_filename(%args) -> bool|hash

Check whether filename indicates being compressed.

Examples:

=over

=item * Example #1:

 check_compressed_filename(filename => "foo.bar"); # -> 0

=item * Example #2:

 check_compressed_filename(filename => "baz.xz");

Result:

 {
   compressor_name       => "XZ",
   compressor_suffix     => ".xz",
   uncompressed_filename => "baz",
 }

=item * Example #3:

 check_compressed_filename(filename => "qux.Bz2");

Result:

 {
   compressor_name       => "Bzip2",
   compressor_suffix     => ".Bz2",
   uncompressed_filename => "qux",
 }

=back

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<filename>* => I<str>

(No description)

=item * B<ignore_case> => I<bool> (default: 1)

Whether to match case-insensitively.


=back

Return value:  (bool|hash)


Return false if no compressor suffixes detected. Otherwise return a hash of
information, which contains these keys: C<compressor_name>, C<compressor_suffix>,
C<uncompressed_filename>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Filename-Type-Compressed>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Filename-Type-Compressed>.

=head1 SEE ALSO

L<Filename::Type::Archive>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Filename-Type-Compressed>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

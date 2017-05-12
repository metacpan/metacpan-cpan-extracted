package Filename::Compressed;

our $DATE = '2015-09-03'; # DATE
our $VERSION = '0.04'; # VERSION

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(check_compressed_filename);
#list_compressor_suffixes

our %SUFFIXES = (
    '.Z'   => {name=>'NCompress'},
    '.gz'  => {name=>'Gzip'},
    '.bz2' => {name=>'Bzip2'},
    '.xz'  => {name=>'XZ'},
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

Return false if no compressor suffixes detected. Otherwise return a hash of
information, which contains these keys: `compressor_name`, `compressor_suffix`,
`uncompressed_filename`.

_
    },
};
sub check_compressed_filename {
    my %args = @_;

    my $filename = $args{filename};
    $filename =~ /(\.\w+)\z/ or return 0;
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

Filename::Compressed - Check whether filename indicates being compressed

=head1 VERSION

This document describes version 0.04 of Filename::Compressed (from Perl distribution Filename-Compressed), released on 2015-09-03.

=head1 SYNOPSIS

 use Filename::Compressed qw(check_compressed_filename);
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


=head2 check_compressed_filename(%args) -> bool|hash

Check whether filename indicates being compressed.

Arguments ('*' denotes required arguments):

=over 4

=item * B<ci> => I<bool> (default: 1)

Whether to match case-insensitively.

=item * B<filename>* => I<str>

=back

Return value:  (bool|hash)


Return false if no compressor suffixes detected. Otherwise return a hash of
information, which contains these keys: C<compressor_name>, C<compressor_suffix>,
C<uncompressed_filename>.

=head1 SEE ALSO

L<Filename::Archive>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Filename-Compressed>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Filename-Compressed>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Filename-Compressed>

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

package File::Digest;

our $DATE = '2019-09-12'; # DATE
our $VERSION = '0.010'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Exporter qw(import);
our @EXPORT_OK = qw(digest_files);

use Perinci::Object;

our %SPEC;

my %arg_file = (
    file => {
        summary => 'Filename ("-" means stdin)',
        schema => ['filename*'],
        req => 1,
        pos => 0,
        cmdline_aliases => {f=>{}},
    },
);

my %arg_files = (
    files => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'file',
        summary => 'Array of filenames (filename "-" means stdin)',
        schema => ['array*', of=>'filename*'],
        req => 1,
        pos => 0,
        greedy => 1,
        cmdline_aliases => {f=>{}},
    },
);

my %args_algorithm = (
    algorithm => {
        schema => ['str*', in=>[qw/crc32 md5 sha1 sha224 sha256 sha384 sha512 sha512224 sha512256 Digest/]],
        default => 'md5',
        cmdline_aliases => {a=>{}},
    },
    digest_args => {
        schema => ['array*', of=>'str*', 'x.perl.coerce_rules'=>['str_comma_sep']],
        cmdline_aliases => {A=>{}},
    },
);

$SPEC{digest_file} = {
    v => 1.1,
    summary => 'Calculate digest of file',
    description => <<'_',

Return 400 status when algorithm is unknown/unsupported.

_
    args => {
        %arg_file,
        %args_algorithm,
    },
};
sub digest_file {
    my %args = @_;

    my $file = $args{file};
    my $algo = $args{algorithm} // 'md5';

    my $fh;
    if ($file eq '-') {
        $fh = \*STDIN;
    } else {
        unless (-f $file) {
            log_warn("Can't open %s: no such file", $file);
            return [404, "No such file '$file'"];
        }
        open $fh, "<", $file or do {
            log_warn("Can't open %s: %s", $file, $!);
            return [500, "Can't open '$file': $!"];
        };
    }

    if ($algo eq 'md5') {
        require Digest::MD5;
        my $ctx = Digest::MD5->new;
        $ctx->addfile($fh);
        return [200, "OK", $ctx->hexdigest];
    } elsif ($algo =~ /\Asha(512224|512256|224|256|384|512|1)\z/) {
        require Digest::SHA;
        my $ctx = Digest::SHA->new($1);
        $ctx->addfile($fh);
        return [200, "OK", $ctx->hexdigest];
    } elsif ($algo eq 'crc32') {
        require Digest::CRC;
        my $ctx = Digest::CRC->new(type=>'crc32');
        $ctx->addfile($fh);
        return [200, "OK", $ctx->hexdigest];
    } elsif ($algo eq 'Digest') {
        require Digest;
        my $ctx = Digest->new(@{ $args{digest_args} // [] });
        $ctx->addfile($fh);
        return [200, "OK", $ctx->hexdigest];
    } else {
        return [400, "Invalid/unsupported algorithm '$algo'"];
    }
}

$SPEC{digest_files} = {
    v => 1.1,
    summary => 'Calculate digests of files',
    description => <<'_',

Dies when algorithm is unsupported/unknown.

_
    args => {
        %arg_files,
        %args_algorithm,
    },
};
sub digest_files {
    my %args = @_;

    my $files = $args{files};
    my $algo  = $args{algorithm} // 'md5';

    my $envres = envresmulti();
    my @res;

    for my $file (@$files) {
        my $itemres = digest_file(file => $file, algorithm=>$algo, digest_args=>$args{digest_args});
        die $itemres->[1] if $itemres->[0] == 400;
        $envres->add_result($itemres->[0], $itemres->[1], {item_id=>$file});
        push @res, {file=>$file, digest=>$itemres->[2]} if $itemres->[0] == 200;
    }

    $envres = $envres->as_struct;
    $envres->[2] = \@res;
    $envres->[3]{'table.fields'} = [qw/file digest/];
    $envres;
}

1;
# ABSTRACT: Calculate digests of files

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Digest - Calculate digests of files

=head1 VERSION

This document describes version 0.010 of File::Digest (from Perl distribution File-Digest), released on 2019-09-12.

=head1 SYNOPSIS

 use File::Digest qw(digest_files);

 my $res = digest_files(
     files => ["file1", "file2"],
     algorithm => 'md5', # default md5, available also: crc32, sha1, sha256
 );

=head1 DESCRIPTION

This module provides some convenience when you want to use L<Digest> against
files.

=head1 FUNCTIONS


=head2 digest_file

Usage:

 digest_file(%args) -> [status, msg, payload, meta]

Calculate digest of file.

Return 400 status when algorithm is unknown/unsupported.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<algorithm> => I<str> (default: "md5")

=item * B<digest_args> => I<array[str]>

=item * B<file>* => I<filename>

Filename ("-" means stdin).

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 digest_files

Usage:

 digest_files(%args) -> [status, msg, payload, meta]

Calculate digests of files.

Dies when algorithm is unsupported/unknown.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<algorithm> => I<str> (default: "md5")

=item * B<digest_args> => I<array[str]>

=item * B<files>* => I<array[filename]>

Array of filenames (filename "-" means stdin).

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/File-Digest>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-File-Digest>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=File-Digest>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Digest>

L<xsum> from L<App::xsum> is a CLI for File::Digest. It can also check digests
stored in checksum files against the actual digests computed from the original
files.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

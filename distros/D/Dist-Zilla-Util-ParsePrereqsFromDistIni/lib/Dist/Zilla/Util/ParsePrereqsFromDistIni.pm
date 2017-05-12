package Dist::Zilla::Util::ParsePrereqsFromDistIni;

our $DATE = '2015-05-15'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(parse_prereqs_from_dist_ini);

our %SPEC;

$SPEC{parse_prereqs_from_dist_ini} = {
    v => 1.1,
    summary => "Parse prereqs from dzil's dist.ini",
    description => <<'_',

This routine tries to get prereqs solely from reading Dist::Zilla's `dist.ini`
(from Prereqs and Prereqs/* sections, as well as from OsPrereqs, see
`lint-prereqs` utility).

The downside is that the routine can't detect prereqs that are added dynamically
during dist building process, e.g. from AutoPrereqs plugin and so on. But the
upside is that this routine can be used outside dzil and/or for `dist.ini` of
other dists (not the current dist during dzil build process).

One application of this routine is in
`Dist::Zilla::Util::CombinePrereqsFromDistInis`.

_
    args_rels => {
        req_one => [qw/path src/],
    },
    args => {
        path => {
            summary => 'Path to dist.ini',
            schema => 'str*',
            'x.schema.entity' => 'filename',
        },
        src => {
            summary => 'Content of dist.ini',
            schema => 'str*',
        },
    },
    result_naked => 1,
};
sub parse_prereqs_from_dist_ini {
    require Config::IOD::Reader;

    my %args = @_;

    my $reader = Config::IOD::Reader->new(
        ignore_unknown_directive => 1,
    );

    my $confhash;
    if ($args{path}) {
        $confhash = $reader->read_file($args{path});
    } else {
        $confhash = $reader->read_string($args{src});
    }

    my $res;
    for my $section (sort keys %$confhash) {
        my ($phase, $rel);
        if ($section =~ m!\A(os)?prereqs\z!i) {
            $phase = 'runtime';
            $rel = 'requires';
        } elsif ($section =~ m!\A(?:os)?prereqs\s*/\s*(configure|build|test|runtime)(requires|recommends|suggests|conflicts)\z!i) {
            $phase = lc($1);
            $rel = lc($2);
        } else {
            next;
        }

        my $confsection = $confhash->{$section};
        for my $mod (sort keys %$confsection) {
            my $val = $confsection->{$mod};
            if ($mod eq '-phase') {
                $phase = $val;
                next;
            } elsif ($mod eq '-relationship') {
                $rel = $val;
                next;
            }
            $res->{$phase}{$rel}{$mod} = $confsection->{$mod};
        }
    }

    $res;
}

1;
# ABSTRACT: Parse prereqs from dzil's dist.ini

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Util::ParsePrereqsFromDistIni - Parse prereqs from dzil's dist.ini

=head1 VERSION

This document describes version 0.02 of Dist::Zilla::Util::ParsePrereqsFromDistIni (from Perl distribution Dist-Zilla-Util-ParsePrereqsFromDistIni), released on 2015-05-15.

=head1 SYNOPSIS

 use Dist::Zilla::Util::ParsePrereqsFromDistIni qw(parse_prereqs_from_dist_ini);

 my $prereqs = parse_prereqs_from_dist_ini(path => "dist.ini");

Sample result:

 {
   runtime => { requires => { "Config::IOD::Reader" => 0, "perl" => 5.010001 } },
 }

=head1 DESCRIPTION

This module provides C<parse_prereqs_from_dist_ini()>.

=head1 FUNCTIONS


=head2 parse_prereqs_from_dist_ini(%args) -> any

Parse prereqs from dzil's dist.ini.

This routine tries to get prereqs solely from reading Dist::Zilla's C<dist.ini>
(from Prereqs and Prereqs/* sections, as well as from OsPrereqs, see
C<lint-prereqs> utility).

The downside is that the routine can't detect prereqs that are added dynamically
during dist building process, e.g. from AutoPrereqs plugin and so on. But the
upside is that this routine can be used outside dzil and/or for C<dist.ini> of
other dists (not the current dist during dzil build process).

One application of this routine is in
C<Dist::Zilla::Util::CombinePrereqsFromDistInis>.

Arguments ('*' denotes required arguments):

=over 4

=item * B<path> => I<str>

Path to dist.ini.

=item * B<src> => I<str>

Content of dist.ini.

=back

Return value:  (any)

=head1 SEE ALSO

L<Dist::Zilla>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Util-ParsePrereqsFromDistIni>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Util-ParsePrereqsFromDistIni>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Util-ParsePrereqsFromDistIni>

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

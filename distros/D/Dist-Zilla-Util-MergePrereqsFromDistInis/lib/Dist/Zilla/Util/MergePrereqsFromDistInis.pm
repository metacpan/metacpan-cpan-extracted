package Dist::Zilla::Util::MergePrereqsFromDistInis;

our $DATE = '2015-05-15'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(merge_prereqs_from_dist_inis);

our %SPEC;

$SPEC{merge_prereqs_from_dist_inis} = {
    v => 1.1,
    summary => "Merge prereqs from several dzil dist.ini's",
    description => <<'_',

This routine tries to merge prereqs from several Dist::Zilla's `dist.ini`
files.

An application of this routine is for `Dist::Zilla::Plugin::MergeDists`.

_
    args_rels => {
        req_one => [qw/paths srcs/],
    },
    args => {
        paths => {
            summary => "Paths to dist.ini's",
            schema => ['array*', of=>'str*', min_len=>1],
            'x.schema.element_entity' => 'filename',
        },
        srcs => {
            summary => "Content of dist.ini's",
            schema => ['array*', of=>'str*', min_len=>1],
        },
    },
    result_naked => 1,
};
sub merge_prereqs_from_dist_inis {
    require Dist::Zilla::Util::ParsePrereqsFromDistIni;

    my %args = @_;

    my @prereqs_list;
    if ($args{paths}) {
        push @prereqs_list, Dist::Zilla::Util::ParsePrereqsFromDistIni::parse_prereqs_from_dist_ini(path=>$_)
            for @{$args{paths}};
    } else {
        push @prereqs_list, Dist::Zilla::Util::ParsePrereqsFromDistIni::parse_prereqs_from_dist_ini(src=>$_)
            for @{$args{srcs}};
    }

    return $prereqs_list[0] if @prereqs_list == 1;

    # merge the keys
    my $res;
    for my $prereqs (@prereqs_list) {
        for my $phase (keys %$prereqs) {
            my $phase_prereqs = $prereqs->{$phase};
            for my $rel (keys %$phase_prereqs) {
                my $mods = $phase_prereqs->{$rel};
                for my $mod (keys %$mods) {
                    $res->{$phase}{$rel}{$mod} = $mods->{$mod}
                        unless exists($res->{$phase}{$rel}{$mod}) &&
                        version->parse($res->{$phase}{$rel}{$mod}) >
                        version->parse($mods->{$mod});
                }
            }
        }
    }

    # upgrade suggests to recommends/requires
    for my $phase (keys %$res) {
        my $phase_res = $res->{$phase};
        my $suggests = $phase_res->{suggests} or next;
        for my $mod (keys %$suggests) {
            delete $suggests->{$mod} if $phase_res->{recommends}{$mod};
            delete $suggests->{$mod} if $phase_res->{requires}{$mod};
        }
    }

    # upgrade recommends to requires
    for my $phase (keys %$res) {
        my $phase_res = $res->{$phase};
        my $recommends = $phase_res->{recommends} or next;
        for my $mod (keys %$recommends) {
            delete $recommends->{$mod} if $phase_res->{requires}{$mod};
        }
    }

    $res;
}

1;
# ABSTRACT: Merge prereqs from several dzil dist.ini's

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Util::MergePrereqsFromDistInis - Merge prereqs from several dzil dist.ini's

=head1 VERSION

This document describes version 0.01 of Dist::Zilla::Util::MergePrereqsFromDistInis (from Perl distribution Dist-Zilla-Util-MergePrereqsFromDistInis), released on 2015-05-15.

=head1 SYNOPSIS

 use Dist::Zilla::Util::MergePrereqsFromDistInis qw(merge_prereqs_from_dist_inis);

 my $merged_prereqs = merge_prereqs_from_dist_inis(paths => ["../Dist1/dist.ini", "../Dist2/dist.ini"]);

=head1 DESCRIPTION

This module provides C<merge_prereqs_from_dist_inis()>.

=head1 FUNCTIONS


=head2 merge_prereqs_from_dist_inis(%args) -> any

Merge prereqs from several dzil dist.ini's.

This routine tries to merge prereqs from several Dist::Zilla's C<dist.ini>
files.

An application of this routine is for C<Dist::Zilla::Plugin::MergeDists>.

Arguments ('*' denotes required arguments):

=over 4

=item * B<paths> => I<array[str]>

Paths to dist.ini's.

=item * B<srcs> => I<array[str]>

Content of dist.ini's.

=back

Return value:  (any)

=head1 SEE ALSO

L<Dist::Zilla>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Util-MergePrereqsFromDistInis>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Util-MergePrereqsFromDistInis>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Util-MergePrereqsFromDistInis>

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

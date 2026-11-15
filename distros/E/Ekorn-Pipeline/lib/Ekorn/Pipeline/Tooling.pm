use v5.36;

package Ekorn::Pipeline::Tooling;

use Exporter qw(import);

# What each module exports, by default or on request, imported here, so
# Exporter can export it again. t/23-tooling.t checks that each tag below
# holds every name its module exports.
use Ekorn::Pipeline::Stop          qw(Stop);
use Ekorn::Pipeline::Gather        qw(gather);
use Ekorn::Pipeline::Stages::Flow  qw(:all);
use Ekorn::Pipeline::Stages::Batch qw(:all);
use Ekorn::Pipeline::Stages::Taps  qw(:all);
use Ekorn::Pipeline::Sources       qw(:all);
use Ekorn::Pipeline::Sinks         qw(:all);
use Ekorn::Pipeline::Factories     qw(:all);
use Ekorn::Pipeline::JSON          qw(:all);

our %EXPORT_TAGS = (
    core => [qw(Stop gather)],
    flow => [
        qw(take take_first take_last take_single take_if take_while),
        qw(drop drop_if    drop_while),
    ],
    batch   => [qw(batch      collect)],
    taps    => [qw(peek       count_into dump_to)],
    sources => [qw(from_array from_fh    from_file counter)],
    sinks   => [
        qw(count_items keep keep_all keep_first keep_last keep_single),
        qw(to_fh to_file),
    ],
    json  => [qw(from_json from_jsonl to_json to_jsonl)],
    words => [
        qw(pipeline stage gather source generator yield),
        qw(sink_one sink_many),
    ],
);
$EXPORT_TAGS{stages} = [map { @{ $EXPORT_TAGS{$_} } } qw(flow batch taps)];

# Every name once: gather is in both :core and :words.
our @EXPORT_OK = do {
    my %seen;
    grep { !$seen{$_}++ }
        map { @{ $EXPORT_TAGS{$_} } } qw(core stages sources sinks json words);
};
$EXPORT_TAGS{all} = [@EXPORT_OK];

1;

__END__

=encoding utf8

=head1 NAME

Ekorn::Pipeline::Tooling - Ekorn's stages, sources, sinks and words, from one module

=head1 SYNOPSIS

    use Ekorn::Pipeline;
    use Ekorn::Pipeline::Tooling qw(:all);

    my $first = Ekorn::Pipeline->new(
        take_if { m( \A ERROR )x },
        keep_first,
    )->iterator(from_file('app.log'))->();

    use Ekorn::Pipeline::Tooling qw(:stages :sinks);    # or only some
    use Ekorn::Pipeline::Tooling qw(take keep_all);     # or by name

=head1 DESCRIPTION

What a caller uses to do work with Ekorn::Pipeline is made in several
modules: stages in Ekorn::Pipeline::Stages::Flow, Batch and Taps,
sources in Ekorn::Pipeline::Sources, sinks in Ekorn::Pipeline::Sinks,
JSON's sources, sinks and stages in Ekorn::Pipeline::JSON, the words in
Ekorn::Pipeline::Factories, and C<Stop> and C<gather> in
modules of their own. This module exports all of them, by the tags
below, so there's one module to import from, and nothing to remember
about which module makes which.

Each name is the very sub its own module exports, prototype and all,
so C<take_if { ... }> and C<stage { ... }> parse as they do imported
from there. Importing a name from both does no harm.

Nothing is exported by default: ask for tags, or names, or both. An
unknown tag or name is reported by Exporter, as it is for any module.

It leaves out what's for extending the package rather than using it,
such as C<is_stage> and C<is_sink>, from L<Ekorn::Pipeline>, and
C<croakf>, from L<Ekorn::Pipeline::Errors>: import those from their
own modules. And it doesn't put the operators in force:
L<Ekorn::Pipeline::Operators> is a pragma, which puts C<|> in force
only in the scope that uses it, by name.

=head1 TAGS

=over

=item C<:core>

C<Stop>, from L<Ekorn::Pipeline::Stop>, and C<gather>, from
L<Ekorn::Pipeline::Gather>.

=item C<:flow>

Everything L<Ekorn::Pipeline::Stages::Flow> exports: C<take>,
C<take_first>, C<take_last>, C<take_single>, C<take_if>,
C<take_while>, C<drop>, C<drop_if> and C<drop_while>.

=item C<:batch>

Everything L<Ekorn::Pipeline::Stages::Batch> exports: C<batch> and
C<collect>.

=item C<:taps>

Everything L<Ekorn::Pipeline::Stages::Taps> exports: C<peek>,
C<count_into> and C<dump_to>.

=item C<:stages>

C<:flow>, C<:batch> and C<:taps>.

=item C<:sources>

Everything L<Ekorn::Pipeline::Sources> exports: C<from_array>,
C<from_fh>, C<from_file> and C<counter>.

=item C<:sinks>

Everything L<Ekorn::Pipeline::Sinks> exports: C<count_items>,
C<keep>, C<keep_all>, C<keep_first>, C<keep_last>, C<keep_single>,
C<to_fh> and C<to_file>.

=item C<:json>

Everything L<Ekorn::Pipeline::JSON> exports: C<from_json>,
C<from_jsonl>, C<to_json> and C<to_jsonl>. L<JSON> exports a
C<from_json> and a C<to_json> of its own, by default, so a module using
both imports C<:all> from only one of them.

=item C<:words>

Everything L<Ekorn::Pipeline::Factories> exports: C<pipeline>,
C<stage>, C<gather>, C<source>, C<generator> and C<yield>,
C<sink_one> and C<sink_many>.

=item C<:all>

All of the above.

=back

A tag holds every name its module exports, by default or on request.
What a tag holds is part of the interface: a name may be added to one
in a release that only adds, but is dropped or renamed only in one that
moves the middle number of the version.

=head1 SEE ALSO

L<Ekorn::Pipeline>, L<Ekorn::Pipeline::Operators>,
L<Ekorn::Pipeline::Manual::Reference>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut

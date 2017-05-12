use 5.10.0;
use warnings;

package Dist::Zilla::Plugin::Stenciller::MojoliciousTests;

# ABSTRACT: Create Mojolicious tests from text files parsed with Stenciller
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0200';

use Moose;
with 'Dist::Zilla::Role::FileGatherer';
use Stenciller;
use Types::Stenciller -types;
use Types::Standard qw/Str/;
use Types::Path::Tiny qw/AbsFile Dir Path/;
use Path::Tiny;
use Dist::Zilla::File::InMemory;
use namespace::autoclean;

has source_directory => (
    is => 'ro',
    isa => Dir,
    coerce => 1,
    default => 'examples/source',
);
has file_pattern => (
    is => 'ro',
    isa => Str,
    default => '.+\.stencil',
);
has output_directory => (
    is => 'ro',
    isa => Path,
    coerce => 1,
    default => 't',
);
has template_file => (
    is => 'ro',
    isa => AbsFile,
    lazy => 1,
    coerce => 1,
    default => sub { shift->source_directory->child('template.test')->absolute },
);

sub gather_files {
    my $self = shift;

    my $template = $self->template_file->slurp_utf8;
    my @source_files = $self->source_directory->children(qr{^@{[ $self->file_pattern ]}$});

    $self->log('Generating tests from stencils');

    foreach my $file (@source_files) {
        my $contents = Stenciller->new(filepath => $file->stringify)->transform(
            plugin_name => 'ToMojoliciousTest',
            transform_args => {
                require_in_extra => {
                    key => 'is_test',
                    value => 1,
                    default => 1
                },
            },
            constructor_args => {
                template => $self->template_file,
            },
        );

        my $new_filename = $file->basename(qr/\.[^.]+$/) . '.t';
        $self->log("Generated $new_filename");

        my $generated_file = Dist::Zilla::File::InMemory->new(
            name => path($self->output_directory, $new_filename)->stringify,
            content => $contents,
        );
        $self->add_file($generated_file);

    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Stenciller::MojoliciousTests - Create Mojolicious tests from text files parsed with Stenciller



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.10+-blue.svg" alt="Requires Perl 5.10+" />
<a href="https://travis-ci.org/Csson/p5-Dist-Zilla-Plugin-Stenciller-MojoliciousTests"><img src="https://api.travis-ci.org/Csson/p5-Dist-Zilla-Plugin-Stenciller-MojoliciousTests.svg?branch=master" alt="Travis status" /></a>
<a href="http://cpants.cpanauthors.org/dist/Dist-Zilla-Plugin-Stenciller-MojoliciousTests-0.0200"><img src="https://badgedepot.code301.com/badge/kwalitee/Dist-Zilla-Plugin-Stenciller-MojoliciousTests/0.0200" alt="Distribution kwalitee" /></a>
<a href="http://matrix.cpantesters.org/?dist=Dist-Zilla-Plugin-Stenciller-MojoliciousTests%200.0200"><img src="https://badgedepot.code301.com/badge/cpantesters/Dist-Zilla-Plugin-Stenciller-MojoliciousTests/0.0200" alt="CPAN Testers result" /></a>
<img src="https://img.shields.io/badge/coverage-98.1%-yellow.svg" alt="coverage 98.1%" />
</p>

=end html

=head1 VERSION

Version 0.0200, released 2016-03-23.

=head1 SYNOPSIS

    ; in dist.ini
    ; these are the defaults:
    [Stenciller::MojoliciousTests]
    source_directory = examples/source
    file_pattern = .+\.stencil
    template_file = examples/source/template.test
    output_directory = t

=head1 DESCRIPTION

Dist::Zilla::Plugin::Stenciller::MojoliciousTests uses L<Stenciller> and L<Stenciller::Plugin::ToMojoliciousTest> to turn
stencil files in C<source_directory> (that matches the C<file_pattern>) into
test files in C<output_directory> by applying the C<template_file>.

This L<Dist::Zilla> plugin does the C<FileGatherer> role.

=head1 ATTRIBUTES

=head2 source_directory

Path to where the stencil files are.

=head2 output_directory

Path to where the generated files are saved.

=head2 file_pattern

This is put inside a regular expression (with start and end anchors) to find stencil files in the C<source_directory>. The output files
will have the same basename, but the suffix is replaced by C<t>.

=head2 template_file

The template file should contain use statements and such. The transformed contents returned from L<Stenciller::Plugin::ToMojoliciousTest> will be placed after
the contents of C<template_file>. The template file is applied to each stencil file, so the number of generated test files is equal
to the number of stencil files.

=head1 SEE ALSO

=over 4

=item *

L<Stenciller>

=item *

L<Stenciller::Plugin::ToMojoliciousTest>

=back

=head1 SOURCE

L<https://github.com/Csson/p5-Dist-Zilla-Plugin-Stenciller-MojoliciousTests>

=head1 HOMEPAGE

L<https://metacpan.org/release/Dist-Zilla-Plugin-Stenciller-MojoliciousTests>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

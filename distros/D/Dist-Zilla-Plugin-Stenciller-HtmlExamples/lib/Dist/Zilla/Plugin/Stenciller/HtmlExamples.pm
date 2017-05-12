use 5.10.0;
use strict;
use warnings;

package Dist::Zilla::Plugin::Stenciller::HtmlExamples;

# ABSTRACT: Create Html example files from text files parsed with Stenciller
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0201';

use Moose;
with 'Dist::Zilla::Role::FileGatherer';
use Stenciller;
use Types::Standard qw/Bool Maybe Str/;
use Types::Path::Tiny qw/AbsFile Dir Path/;
use Types::Stenciller -types;
use Path::Tiny;
use Dist::Zilla::File::InMemory;
use String::Stomp;
use syntax 'qs';
use namespace::autoclean;

has '+zilla' => (
    traits => ['Documented'],
    documentation_order => 0,
);
has '+plugin_name' => (
    traits => ['Documented'],
    documentation_order => 0,
);
has '+logger' => (
    traits => ['Documented'],
    documentation_order => 0,
);

has source_directory => (
    is => 'ro',
    isa => Dir,
    coerce => 1,
    default => 'examples/source',
    traits => ['Documented'],
    documentation => 'Path to where the stencil files are.',
    documentation_order => 1,
);
has file_pattern => (
    is => 'ro',
    isa => Str,
    default => '.+\.stencil',
    traits => ['Documented'],
    documentation => stomp qs{
        This is used as a part of a regular expression (so do not use start and end anchors) to find stencil files in the C<source_directory>.
    },
    documentation_order => 3,
);
has output_directory => (
    is => 'ro',
    isa => Path,
    coerce => 1,
    default => 'examples',
    traits => ['Documented'],
    documentation => stomp qs{
        Path to where the generated files are saved.  The output files
        will have the same basename as the stencil they are based on, but with the suffix replaced by C<html>.
    },
    documentation_order => 2,
);
has template_file => (
    is => 'ro',
    isa => AbsFile,
    lazy => 1,
    coerce => 1,
    default => sub { shift->source_directory->child('template.html')->absolute },
    traits => ['Documented'],
    documentation => stomp qs{
        The template file should be an html file. The first occurence of C<[STENCILS]> will be replaced with the output from L<Stenciller::Plugin::ToHtmlPreBlock>
        for each stencil.
    },
    documentation_default => q{'template.html' in L</source_directory>},
    documentation_order => 4,
);
has separator => (
    is => 'ro',
    isa => Maybe[Str],
    traits => ['Documented'],
    documentation => q{Passed on to the L<Stenciller::Plugin::ToHtmlPreBlock> constructor.},
    documentation_order => 5,
);
has output_also_as_html => (
    is => 'ro',
    isa => Bool,
    default => 0,
    traits => ['Documented'],
    documentation => q{Passed on to the L<Stenciller::Plugin::ToHtmlPreBlock> constructor.},
    documentation_order => 6,
);

sub gather_files {
    my $self = shift;

    my $template = $self->template_file->slurp_utf8;
    my @source_files = $self->source_directory->children(qr{^@{[ $self->file_pattern ]}$});

    $self->log('Generating from stencils');

    foreach my $file (@source_files) {
        my $contents = Stenciller->new(filepath => $file->stringify)->transform(
            plugin_name => 'ToHtmlPreBlock',
            constructor_args => {
                output_also_as_html => $self->output_also_as_html,
                separator => $self->separator,
            },
            transform_args => {
                require_in_extra => {
                    key => 'is_html_example',
                    value => 1,
                    default => 1,
                },
            },
        );
        my $all_contents = $template;
        $all_contents =~ s{\[STENCILS\]}{$contents};
        my $new_filename = $file->basename(qr/\.[^.]+$/) . '.html';
        $self->log("Generated $new_filename");

        my $generated_file = Dist::Zilla::File::InMemory->new(
            name => path($self->output_directory, $new_filename)->stringify,
            content => $all_contents,
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

Dist::Zilla::Plugin::Stenciller::HtmlExamples - Create Html example files from text files parsed with Stenciller



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.10+-blue.svg" alt="Requires Perl 5.10+" />
<a href="https://travis-ci.org/Csson/p5-Dist-Zilla-Plugin-Stenciller-HtmlExamples"><img src="https://api.travis-ci.org/Csson/p5-Dist-Zilla-Plugin-Stenciller-HtmlExamples.svg?branch=master" alt="Travis status" /></a>
<a href="http://cpants.cpanauthors.org/dist/Dist-Zilla-Plugin-Stenciller-HtmlExamples-0.0201"><img src="https://badgedepot.code301.com/badge/kwalitee/Dist-Zilla-Plugin-Stenciller-HtmlExamples/0.0201" alt="Distribution kwalitee" /></a>
<a href="http://matrix.cpantesters.org/?dist=Dist-Zilla-Plugin-Stenciller-HtmlExamples%200.0201"><img src="https://badgedepot.code301.com/badge/cpantesters/Dist-Zilla-Plugin-Stenciller-HtmlExamples/0.0201" alt="CPAN Testers result" /></a>
<img src="https://img.shields.io/badge/coverage-98.5%-yellow.svg" alt="coverage 98.5%" />
</p>

=end html

=head1 VERSION

Version 0.0201, released 2016-03-23.



=head1 SYNOPSIS

    ; in dist.ini
    ; these are the defaults
    [Stenciller::HtmlExamples]
    source_directory = examples/source
    output_directory = examples
    template_file = examples/source/template.html
    file_pattern = .+\.stencil
    output_also_as_html = 0

=head1 DESCRIPTION

Dist::Zilla::Plugin::Stenciller::HtmlExamples uses L<Stenciller> and L<Stenciller::Plugin::ToHtmlPreBlock> to turn
stencil files in C<source_directory> (that matches the C<file_pattern>) into
html example files in C<output_directory> by applying the C<template_file>.

This L<Dist::Zilla> plugin does the C<FileGatherer> role.

=head1 ATTRIBUTES


=head2 source_directory

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Path::Tiny#Dir">Dir</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>examples/source</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>Path to where the stencil files are.</p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Path::Tiny#Dir">Dir</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>examples/source</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>Path to where the stencil files are.</p>

=end markdown

=head2 output_directory

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Path::Tiny#Path">Path</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>examples</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>Path to where the generated files are saved.  The output files
will have the same basename as the stencil they are based on, but with the suffix replaced by C<html>.</p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Path::Tiny#Path">Path</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>examples</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>Path to where the generated files are saved.  The output files
will have the same basename as the stencil they are based on, but with the suffix replaced by C<html>.</p>

=end markdown

=head2 file_pattern

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Str">Str</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>.+\.stencil</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>This is used as a part of a regular expression (so do not use start and end anchors) to find stencil files in the C<source_directory>.</p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Str">Str</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>.+\.stencil</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>This is used as a part of a regular expression (so do not use start and end anchors) to find stencil files in the C<source_directory>.</p>

=end markdown

=head2 template_file

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Path::Tiny#AbsFile">AbsFile</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>&#39;template.html&#39; in <a href="#source_directory">&quot;source_directory&quot;</a></code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>The template file should be an html file. The first occurence of C<[STENCILS]> will be replaced with the output from L<Stenciller::Plugin::ToHtmlPreBlock>
for each stencil.</p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Path::Tiny#AbsFile">AbsFile</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>&#39;template.html&#39; in <a href="#source_directory">&quot;source_directory&quot;</a></code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>The template file should be an html file. The first occurence of C<[STENCILS]> will be replaced with the output from L<Stenciller::Plugin::ToHtmlPreBlock>
for each stencil.</p>

=end markdown

=head2 separator

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Maybe">Maybe</a> [ <a href="https://metacpan.org/pod/Types::Standard#Str">Str</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>Passed on to the L<Stenciller::Plugin::ToHtmlPreBlock> constructor.</p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Maybe">Maybe</a> [ <a href="https://metacpan.org/pod/Types::Standard#Str">Str</a> ]</td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional</td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>Passed on to the L<Stenciller::Plugin::ToHtmlPreBlock> constructor.</p>

=end markdown

=head2 output_also_as_html

=begin HTML

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Bool">Bool</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>0</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>Passed on to the L<Stenciller::Plugin::ToHtmlPreBlock> constructor.</p>

=end HTML

=begin markdown

<table cellpadding="0" cellspacing="0">
<tr>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Bool">Bool</a></td>
    <td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>0</code></td>
    <td style="padding-left: 6px; padding-right: 6px; white-space: nowrap;">read-only</td>
</tr>
</table>

<p>Passed on to the L<Stenciller::Plugin::ToHtmlPreBlock> constructor.</p>

=end markdown

=head1 SEE ALSO

=over 4

=item *

L<Stenciller>

=item *

L<Stenciller::Plugin::ToHtmlPreBlock>

=back

=head1 SOURCE

L<https://github.com/Csson/p5-Dist-Zilla-Plugin-Stenciller-HtmlExamples>

=head1 HOMEPAGE

L<https://metacpan.org/release/Dist-Zilla-Plugin-Stenciller-HtmlExamples>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

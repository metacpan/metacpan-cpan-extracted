package Dist::Zilla::Plugin::Test::CreateFromMojoTemplates;

use strict;
use 5.10.1;

our $VERSION = '0.0701'; # VERSION
# ABSTRACT: Create Mojolicious tests from a custom template format (deprecated)

use Moose;
use File::Find::Rule;
use namespace::autoclean;
use Path::Tiny;
use MojoX::CustomTemplateFileParser;

use Dist::Zilla::File::InMemory;
with 'Dist::Zilla::Role::FileGatherer';

has directory => (
    is => 'ro',
    isa => 'Str',
    default => sub { 'examples/source/' },
);
has filepattern => (
    is => 'ro',
    isa => 'Str',
    default => sub { '^\w+-\d+\.mojo$' },
);

sub gather_files {
    my $self = shift;
    my $arg = shift;

    my $test_template_path = (File::Find::Rule->file->name('template.test')->in($self->directory))[0];
    my $test_template = path($test_template_path)->slurp;

    my @paths = File::Find::Rule->file->name(qr/@{[ $self->filepattern ]}/)->in($self->directory);
    foreach my $path (@paths) {

        my $contents = MojoX::CustomTemplateFileParser->new(path => path($path)->absolute->canonpath, output => ['Test'])->to_test;
        my $filename = path($path)->basename(qr{\.[^.]+});

        my $file = Dist::Zilla::File::InMemory->new(
            name => "t/$filename.t",
            content => $test_template . $contents,
        );
        $self->add_file($file);

    }

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Test::CreateFromMojoTemplates - Create Mojolicious tests from a custom template format (deprecated)



=begin HTML

<p><img src="https://img.shields.io/badge/perl-5.10.1+-brightgreen.svg" alt="Requires Perl 5.10.1+" /> <a href="https://travis-ci.org/Csson/p5-dist-zilla-plugin-test-createfrommojotemplate"><img src="https://api.travis-ci.org/Csson/p5-dist-zilla-plugin-test-createfrommojotemplate.svg?branch=master" alt="Travis status" /></a> </p>

=end HTML


=begin markdown

![Requires Perl 5.10.1+](https://img.shields.io/badge/perl-5.10.1+-brightgreen.svg) [![Travis status](https://api.travis-ci.org/Csson/p5-dist-zilla-plugin-test-createfrommojotemplate.svg?branch=master)](https://travis-ci.org/Csson/p5-dist-zilla-plugin-test-createfrommojotemplate) 

=end markdown

=head1 VERSION

Version 0.0701, released 2016-01-25.

=head1 SYNOPSIS

  ; In dist.ini
  [Test::CreateFromMojoTemplates]
  directory = examples/source
  filepattern = ^\w+-\d+\.mojo$

=head1 DESCRIPTION

B<Deprecated>. See L<Dist::Zilla::Plugin::Stenciller::Mojolicious> instead.

Dist::Zilla::Plugin::Test::CreateFromMojoTemplates creates tests by parsing a custom file format
containg Mojolicious templates and the expected rendering. See L<MojoX::CustomTemplateFileParser> for details.

It looks for files in a given C<directory> (by default C<examples/source>) that matches C<filepattern> (by default C<^\w+-\d+\.mojo$>).

If you have many files you can also create a C<template.test> (currently hardcoded) file. Its content will be placed at the top of all created test files.

=head1 SOURCE

L<https://github.com/Csson/p5-dist-zilla-plugin-test-createfrommojotemplate>

=head1 HOMEPAGE

L<https://metacpan.org/release/Dist-Zilla-Plugin-Test-CreateFromMojoTemplates>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

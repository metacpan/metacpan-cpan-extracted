package Dist::Zilla::Plugin::InsertExample::FromMojoTemplates;

use strict;
use warnings;
use 5.10.1;

our $VERSION = '0.0301'; # VERSION
# ABSTRACT: Creates POD examples from a custom template format (deprecated)

use File::Find::Rule;
use MojoX::CustomTemplateFileParser;
use Moose;
use namespace::autoclean;
use Path::Tiny;
use Dist::Zilla::File::InMemory;

with ('Dist::Zilla::Role::FileMunger', 'Dist::Zilla::Role::FileGatherer');
with 'Dist::Zilla::Role::FileFinderUser' => {
    default_finders => [':InstallModules', ':ExecFiles'],
};

has directory => (
    is => 'ro',
    isa => 'Str',
    default => sub { 'examples/source' },
);
has filepattern => (
    is => 'ro',
    default => sub { qr/\w+-\d+\.mojo/ },
);
has make_examples => (
    is => 'ro',
    isa => 'Bool',
    default => sub { 1 },
);

has example_directory => (
    is => 'ro',
    isa => 'Str',
    default => sub { 'examples' },
);

sub gather_files {
    my $self = shift;
    my $arg = shift;

    return if !$self->make_examples;
    my $html_template_path = (File::Find::Rule->file->name('template.html')->in($self->directory))[0];
    my $html_template = path($html_template_path)->slurp;

    my @paths = File::Find::Rule->file->name(qr/@{[ $self->filepattern ]}/)->in($self->directory);
    foreach my $path (@paths) {
        my $contents = MojoX::CustomTemplateFileParser->new(path => path($path)->absolute->canonpath, output => ['Html'])->to_html;
        $contents = $html_template =~ s{\[EXAMPLES\]}{$contents}r;
        my $filename = path($path)->basename(qr{\.[^.]+});

        my $file = Dist::Zilla::File::InMemory->new(
            name => ''.path($self->example_directory)->child("$filename.html"),
            content => $contents,
        );
        $self->add_file($file);

    }

    return;
}


sub munge_files {
    my $self = shift;
    $self->munge_file($_) for @{ $self->found_files };
}

sub munge_file {
    my $self = shift;
    my $file = shift;

    my $content = $file->content;
    my $re = $self->filepattern;
    if($content =~ m{# \s* EXAMPLE: \s* ($re):(.*)}xm) {
        my $linere = qr{^\s*#\s*EXAMPLE:\s*([^:]+):(.*)$};
        my @lines = grep { m{$linere} } split /\n/ => $content;

        my $newcontent = $content;

        LINE:
        foreach my $line (@lines) {
            $line =~ m{$linere};

            my $filename = $1;

            my $what = $2;
            $what =~ s{ }{}g;
            $what =~ s{,,+}{,}g;

            my @configs = split m/,/ => $what;
            my @wanted = ();
            my @unwanted = ();
            my $all = 0;
            my $want_all_examples = 0;

            CONFIG:
            foreach my $config (@configs) {
                if($config eq 'examples') {
                    $want_all_examples = 1;
                }
                elsif($config eq 'all') {
                    $all = 1;
                }
                elsif($config =~ m{^ (!)? (\d+) (?:-(\d+))? }x) {
                    my $exclude = defined $1 ? 1 : 0;
                    my $first = $2;
                    my $second = $3 || $first;

                    map { push @wanted   => $_ } ($first..$second) if !$exclude;
                    map { push @unwanted => $_ } ($first..$second) if $exclude;
                }
            }

            my $parser = MojoX::CustomTemplateFileParser->new( path => path($self->directory)->child($filename)->absolute->canonpath, output => ['Pod'] );
            my $testcount = $parser->test_count;
            @wanted = (1..$testcount) if $all || $want_all_examples;

            my %unwanted;
            $unwanted{ $_ } = 1 for @unwanted;
            @wanted = grep { !exists $unwanted{ $_ } } @wanted;

            my $tomunge = '';
            foreach my $test (@wanted) {
                $tomunge .= $parser->to_pod($test, $want_all_examples);
            }

            my $success = $newcontent =~ s{$line}{$tomunge};

        }

        if($newcontent ne $content) {
            $file->content($newcontent);
        }

    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::InsertExample::FromMojoTemplates - Creates POD examples from a custom template format (deprecated)



=begin HTML

<p><img src="https://img.shields.io/badge/perl-5.10.1+-brightgreen.svg" alt="Requires Perl 5.10.1+" /> <a href="https://travis-ci.org/Csson/p5-Dist-Zilla-Plugin-InsertExample-FromMojoTemplates"><img src="https://api.travis-ci.org/Csson/p5-Dist-Zilla-Plugin-InsertExample-FromMojoTemplates.svg?branch=master" alt="Travis status" /></a> </p>

=end HTML


=begin markdown

![Requires Perl 5.10.1+](https://img.shields.io/badge/perl-5.10.1+-brightgreen.svg) [![Travis status](https://api.travis-ci.org/Csson/p5-Dist-Zilla-Plugin-InsertExample-FromMojoTemplates.svg?branch=master)](https://travis-ci.org/Csson/p5-Dist-Zilla-Plugin-InsertExample-FromMojoTemplates) 

=end markdown

=head1 VERSION

Version 0.0301, released 2016-01-25.

=head1 SYNOPSIS

  ; In dist.ini
  [InsertExample::FromMojoTemplates]
  directory = examples/source
  filepattern = ^\w+-\d+\.mojo$

=head1 DESCRIPTION

B<Deprecated>. See L<Pod::Elemental::Transformer::Stenciller> instead.

Dist::Zilla::Plugin::InsertExample::FromMojoTemplates inserts examples from L<MojoX::CustomTemplateFileParser> type files into POD.
Together with L<Dist::Zilla::Plugin::Test::CreateFromMojo> this produces examples in POD from the same source that creates the tests.
The purpose is to help develop tag helpers for L<Mojolicious>.

=head2 Attributes

B<C<directory>>

Default: C<examples/source>

Where DZP::IE::FMT should look for source files.

B<C<filepattern>>

Default: C<^\w+-\d+\.mojo$>

Look for files that matches a certain pattern.

B<C<make_examples>>

Default: C<1>

If true, will create html files in the chosen directory.

B<C<example_directory>>

Default: C<examples>

The directory for html files.

=head2 USAGE

Source files looks like this:

   ==test example 1==
    --t--
        %= link_to 'The example 3' => ['http://www.perl.org/']
    --t--
    --e--
        <a href="http://www.perl.org/">Perl</a>
    --e--

This is a test block. One file can have many test blocks.

In your pod:

    # EXAMPLE: filename.mojo:1, 3-30, !5, !22-26

    # EXAMPLE: filename.mojo:all

    # EXAMPLE: filename.mojo:examples

B<C<all>>

Adds all examples in the source file. C<all> can be used by itself or combined with exclusion commands.

B<C<1>>

Adds example number C<3>. The test number is sequential. Looping tests count as one. You can add a number as in the example to make it easier to follow.

B<C<3-30>>

Add examples numbered C<5> through C<30>.

B<C<!5>>

Excludes example C<5> from the previous range.

B<C<!22-26>>

Excludes examples numbered C<22-26> from the previous range. If an example has been excluded it can't be included later. Exclusions are final.

B<C<examples>>

Includes all tests marked C<==test example==> in the source file. Exclusion works as with C<all>.

=head1 SEE ALSO

The successor to this module is L<Pod::Elemental::Transformer::Stenciller>.

=head1 SOURCE

L<https://github.com/Csson/p5-Dist-Zilla-Plugin-InsertExample-FromMojoTemplates>

=head1 HOMEPAGE

L<https://metacpan.org/release/Dist-Zilla-Plugin-InsertExample-FromMojoTemplates>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

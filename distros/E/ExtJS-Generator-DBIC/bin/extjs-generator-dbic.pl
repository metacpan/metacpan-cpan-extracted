#!/usr/bin/env perl

# ABSTRACT: commandline script to use ExtJS-Generator-DBIC
use strict;
use warnings;
use ExtJS::Generator::DBIC::Model;
use Path::Class;

{
    package
        ExtJS::Generator::DBIC::Options;
    use strict;
    use warnings;
    use Moo;
    use MooX::Options;

    option 'schemaname' => (
        is       => 'ro',
        format   => 's',
        short    => 's',
        required => 1,
        doc      => 'DBIx::Class schema name',
    );
    option 'appname' => (
        is       => 'ro',
        format   => 's',
        short    => 'a',
        required => 1,
        doc      => 'ExtJS application name',
    );

    option 'model_namespace' => (
        is     => 'ro',
        format => 's',
        short  => 'mn',
        doc    => 'ExtJS model namespace',
    );

    option 'model_baseclass' => (
        is     => 'ro',
        format => 's',
        short  => 'mb',
        doc    => 'ExtJS model baseclass',
    );

    option 'model_args' => (
        is     => 'ro',
        format => 'json',
        short  => 'ma',
        doc    => 'ExtJS model arguments',
    );

    option 'directory' => (
        is       => 'ro',
        format   => 's',
        short    => 'd',
        required => 1,
        doc      => 'output directory for the generated ExtJS classes',
    );

    1;
}

my $opt = ExtJS::Generator::DBIC::Options->new_with_options;

my $generator = ExtJS::Generator::DBIC::Model->new(
    schemaname => $opt->schemaname,
    appname    => $opt->appname,

    ( defined $opt->model_namespace )
    ? ( model_namespace => $opt->model_namespace )
    : (),

    ( defined $opt->model_baseclass )
    ? ( model_baseclass => $opt->model_baseclass )
    : (),

    ( defined $opt->model_args && ref $opt->model_args eq 'HASH' )
    ? ( model_args => $opt->model_args )
    : (),
);

$generator->extjs_all_to_file($opt->directory);

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtJS::Generator::DBIC::Options - commandline script to use ExtJS-Generator-DBIC

=head1 VERSION

version 0.004

=head1 AUTHOR

Alexander Hartmaier <abraxxa@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Alexander Hartmaier.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
